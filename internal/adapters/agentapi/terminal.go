package agentapi

import (
	"encoding/base64"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

const terminalHeartbeat = 15 * time.Second

const (
	terminalMinimumColumns = 1
	terminalMaximumColumns = 1000
	terminalMinimumRows    = 1
	terminalMaximumRows    = 500
)

type terminalOpenRequest struct {
	Password string `json:"password"`
}

type terminalInputRequest struct {
	Data string `json:"data"`
}

type terminalResizeRequest struct {
	Columns int `json:"cols"`
	Rows    int `json:"rows"`
}

// serveTerminalRoute dispatches one /agent/v1/terminal/<id>/<action> request.
func (handler Handler) serveTerminalRoute(writer http.ResponseWriter, request *http.Request, path string) {
	id, action, valid := splitTerminalPath(path)
	if !valid {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such agent route")
		return
	}
	switch {
	case action == "stream" && request.Method == http.MethodGet:
		handler.serveTerminalStream(writer, request, id)
	case action == "input" && request.Method == http.MethodPost:
		handler.serveTerminalInput(writer, request, id)
	case action == "resize" && request.Method == http.MethodPost:
		handler.serveTerminalResize(writer, request, id)
	case action == "close" && request.Method == http.MethodPost:
		handler.serveTerminalClose(writer, request, id)
	default:
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such agent route")
	}
}

func splitTerminalPath(path string) (string, string, bool) {
	id, action, found := strings.Cut(path, "/")
	if !found || id == "" || action == "" || strings.Contains(action, "/") {
		return "", "", false
	}
	return id, action, true
}

// serveTerminalOpen starts one shell after a fresh password check, and only
// while the agent listens on loopback (G42).
func (handler Handler) serveTerminalOpen(writer http.ResponseWriter, request *http.Request) {
	if handler.Terminal == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the terminal is not configured")
		return
	}
	var body terminalOpenRequest
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	if !operatoragent.ListenIsLoopback(handler.Listen) {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeTerminalDisabled, "the terminal is available only when the agent listens on a loopback address")
		return
	}
	if err := handler.Credentials.Verify(body.Password); err != nil {
		handler.writeAgentError(writer, "terminal.open", err)
		return
	}
	opened, err := handler.Terminal.Open(bearer(request), handler.Listen)
	if err != nil {
		handler.writeAgentError(writer, "terminal.open", err)
		return
	}
	writeJSON(writer, http.StatusOK, opened)
}

func (handler Handler) serveTerminalInput(writer http.ResponseWriter, request *http.Request, id string) {
	if handler.Terminal == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the terminal is not configured")
		return
	}
	var body terminalInputRequest
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	data, err := base64.StdEncoding.DecodeString(body.Data)
	if err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "data must be base64")
		return
	}
	if err := handler.Terminal.WriteInput(bearer(request), id, data); err != nil {
		handler.writeAgentError(writer, "terminal.input", err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]string{"state": "written"})
}

func (handler Handler) serveTerminalResize(writer http.ResponseWriter, request *http.Request, id string) {
	if handler.Terminal == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the terminal is not configured")
		return
	}
	var body terminalResizeRequest
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	if body.Columns < terminalMinimumColumns || body.Columns > terminalMaximumColumns ||
		body.Rows < terminalMinimumRows || body.Rows > terminalMaximumRows {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, fmt.Sprintf("cols must be %d..%d and rows %d..%d", terminalMinimumColumns, terminalMaximumColumns, terminalMinimumRows, terminalMaximumRows))
		return
	}
	if err := handler.Terminal.Resize(bearer(request), id, uint16(body.Columns), uint16(body.Rows)); err != nil {
		handler.writeAgentError(writer, "terminal.resize", err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]string{"state": "resized"})
}

func (handler Handler) serveTerminalClose(writer http.ResponseWriter, request *http.Request, id string) {
	if handler.Terminal == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the terminal is not configured")
		return
	}
	var body struct{}
	if err := decodeOptionalBody(writer, request, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	if err := handler.Terminal.Close(bearer(request), id); err != nil {
		handler.writeAgentError(writer, "terminal.close", err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]string{"state": "closed"})
}

// serveTerminalStream writes the pseudo terminal output as server-sent events,
// one base64 chunk per event, with a keepalive comment between chunks (G42).
func (handler Handler) serveTerminalStream(writer http.ResponseWriter, request *http.Request, id string) {
	if handler.Terminal == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the terminal is not configured")
		return
	}
	attachment, err := handler.Terminal.Attach(bearer(request), id)
	if err != nil {
		handler.writeAgentError(writer, "terminal.stream", err)
		return
	}
	defer attachment.Release()
	flusher, _ := writer.(http.Flusher)
	writer.Header().Set("Content-Type", "text/event-stream")
	writer.Header().Set("Cache-Control", "no-store")
	writer.Header().Set("X-Accel-Buffering", "no")
	writer.WriteHeader(http.StatusOK)
	if flusher != nil {
		flusher.Flush()
	}
	heartbeat := time.NewTicker(terminalHeartbeat)
	defer heartbeat.Stop()
	for {
		select {
		case <-request.Context().Done():
			return
		case <-attachment.Done():
			return
		case <-heartbeat.C:
			if _, err := io.WriteString(writer, ": keepalive\n\n"); err != nil {
				return
			}
			if flusher != nil {
				flusher.Flush()
			}
		case chunk := <-attachment.Chunks:
			if _, err := fmt.Fprintf(writer, "data: %s\n\n", base64.StdEncoding.EncodeToString(chunk)); err != nil {
				return
			}
			if flusher != nil {
				flusher.Flush()
			}
		}
	}
}
