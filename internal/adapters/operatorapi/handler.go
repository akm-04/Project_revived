// Package operatorapi is the operator listener's HTTP edge
// (I11A_OPERATOR_COMMANDS_V1 rulings 1, 4 and 7): loopback callers with the
// per-start agent token only; every command goes through the operator bus.
package operatorapi

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"log"
	"net"
	"net/http"
	"net/url"
	"strings"

	"gxb.local/backend/v2/internal/application/operator"
)

const (
	commandPrefix = "/operator/v1/commands/"
	readPrefix    = "/operator/v1/reads/"
	versionPath   = "/operator/v1/version"
	// ota.register_build carries the release manifest: one row per shipped file, about 3 MB for the
	// full 1.631 res set. The listener is loopback-only and token-gated, so the cap only bounds a bug.
	maxRequestBody = 32 << 20

	codeUnauthorized = "OPERATOR_UNAUTHORIZED"
	codeBadRequest   = "OPERATOR_BAD_REQUEST"
	codeBodyTooLarge = "OPERATOR_BODY_TOO_LARGE"
	codeUnavailable  = "OPERATOR_UNAVAILABLE"
	codeFailed       = "OPERATOR_FAILED"
	codeUnknownRead  = "OPERATOR_UNKNOWN_READ"
)

type Executor interface {
	Execute(context.Context, operator.Command) (operator.Outcome, error)
}

// Read answers one bounded operator read; it runs no command and writes no
// audit row.
type Read func(context.Context, url.Values) (any, error)

type Handler struct {
	Bus   Executor
	Token string
	// Version answers GET /operator/v1/version (ruling 8).
	Version func(context.Context) (any, error)
	// Reads is the read registry the composition root fills.
	Reads map[string]Read
}

type request struct {
	Envelope operator.Envelope `json:"envelope"`
	Payload  json.RawMessage   `json:"payload"`
}

type reply struct {
	State    string          `json:"state"`
	Result   json.RawMessage `json:"result"`
	Replayed bool            `json:"replayed"`
}

func loopback(remoteAddress string) bool {
	host, _, err := net.SplitHostPort(remoteAddress)
	if err != nil {
		return false
	}
	address := net.ParseIP(host)
	return address != nil && address.IsLoopback()
}

func (handler Handler) authorized(request *http.Request) bool {
	presented, found := strings.CutPrefix(request.Header.Get("Authorization"), "Bearer ")
	return handler.Token != "" && found && subtle.ConstantTimeCompare([]byte(presented), []byte(handler.Token)) == 1
}

func write(writer http.ResponseWriter, status int, body any) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(body)
}

func writeError(writer http.ResponseWriter, status int, code, message string) {
	write(writer, status, operator.Refuse(code, message, nil))
}

func (handler Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if !loopback(request.RemoteAddr) || !handler.authorized(request) {
		writeError(writer, http.StatusUnauthorized, codeUnauthorized, "operator token required")
		return
	}
	if request.URL.Path == versionPath && request.Method == http.MethodGet {
		handler.serveVersion(writer, request)
		return
	}
	if name, isRead := strings.CutPrefix(request.URL.Path, readPrefix); isRead {
		if request.Method != http.MethodGet {
			writeError(writer, http.StatusNotFound, codeBadRequest, "no such operator route")
			return
		}
		handler.serveRead(writer, request, name)
		return
	}
	name, isCommand := strings.CutPrefix(request.URL.Path, commandPrefix)
	if !isCommand || request.Method != http.MethodPost {
		writeError(writer, http.StatusNotFound, codeBadRequest, "no such operator route")
		return
	}
	handler.serveCommand(writer, request, name)
}

func (handler Handler) serveVersion(writer http.ResponseWriter, request *http.Request) {
	if handler.Version == nil {
		writeError(writer, http.StatusServiceUnavailable, codeUnavailable, "version unavailable")
		return
	}
	version, err := handler.Version(request.Context())
	if err != nil {
		log.Printf("operator version: %v", err)
		writeError(writer, http.StatusServiceUnavailable, codeUnavailable, "version unavailable")
		return
	}
	write(writer, http.StatusOK, version)
}

func (handler Handler) serveRead(writer http.ResponseWriter, request *http.Request, name string) {
	read, registered := handler.Reads[name]
	if !registered {
		writeError(writer, http.StatusNotFound, codeUnknownRead, "no such operator read")
		return
	}
	result, err := read(request.Context(), request.URL.Query())
	if err == nil {
		write(writer, http.StatusOK, result)
		return
	}
	var refusal *operator.Refusal
	switch {
	case errors.As(err, &refusal):
		write(writer, http.StatusConflict, refusal)
	case errors.Is(err, operator.ErrUnavailable):
		writeError(writer, http.StatusServiceUnavailable, codeUnavailable, "operator read unavailable")
	default:
		log.Printf("operator read %s failed: %v", name, err)
		writeError(writer, http.StatusInternalServerError, codeFailed, "the read failed")
	}
}

func (handler Handler) serveCommand(writer http.ResponseWriter, httpRequest *http.Request, name string) {
	var body request
	decoder := json.NewDecoder(http.MaxBytesReader(writer, httpRequest.Body, maxRequestBody))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&body); err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			writeError(writer, http.StatusRequestEntityTooLarge, codeBodyTooLarge, "the body exceeds 32 MiB")
			return
		}
		writeError(writer, http.StatusBadRequest, codeBadRequest, "the body must be {envelope, payload}")
		return
	}
	command, err := operator.NewCommand(name, body.Envelope, body.Payload)
	if err == nil {
		var outcome operator.Outcome
		outcome, err = handler.Bus.Execute(httpRequest.Context(), command)
		if err == nil {
			handler.writeOutcome(writer, outcome)
			return
		}
	}
	var refusal *operator.Refusal
	switch {
	case errors.As(err, &refusal):
		write(writer, http.StatusConflict, refusal)
	case errors.Is(err, operator.ErrUnavailable):
		writeError(writer, http.StatusServiceUnavailable, codeUnavailable, "operator bus unavailable")
	default:
		log.Printf("operator command %s failed: %v", name, err)
		writeError(writer, http.StatusInternalServerError, codeFailed, "the command failed; operator.audit.list shows its state; send the same command again with the same key")
	}
}

// writeOutcome answers a stored REFUSED result with 409 too, so a replayed
// refusal reads the same as the first one.
func (handler Handler) writeOutcome(writer http.ResponseWriter, outcome operator.Outcome) {
	status := http.StatusOK
	if outcome.State == operator.StateRefused {
		status = http.StatusConflict
	}
	write(writer, status, reply{State: outcome.State, Result: outcome.Result, Replayed: outcome.Replayed})
}
