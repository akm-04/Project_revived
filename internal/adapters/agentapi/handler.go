// Package agentapi is the gxb-operator agent's local HTTP surface
// (I11A_1_PLAN "Agent decisions"): loopback callers, bearer session on every
// route but setup/login, 1 MiB bodies, backend refusals passed through
// unchanged.
package agentapi

import (
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

const (
	setupPath         = "/agent/v1/setup"
	loginPath         = "/agent/v1/login"
	logoutPath        = "/agent/v1/logout"
	backendStartPath  = "/agent/v1/backend/start"
	backendStopPath   = "/agent/v1/backend/stop"
	backendStatusPath = "/agent/v1/backend/status"
	commandPrefix     = "/agent/v1/commands/"
	readPrefix        = "/agent/v1/reads/"
	publishPath       = "/agent/v1/ota/publish"
	withdrawPath      = "/agent/v1/ota/withdraw"
	operationPrefix   = "/agent/v1/ops/"
	logTailPath       = "/agent/v1/log/tail"

	maxBodyBytes  = 1 << 20
	defaultTail   = 50
	maxTailLines  = 1000
	tailByteLimit = 256 << 10
)

// Handler serves the agent API. All fields are composed by cmd/gxb-operator.
type Handler struct {
	Credentials *operatoragent.Credentials
	Sessions    *operatoragent.Sessions
	Backend     operatoragent.BackendControl
	Operator    operatoragent.OperatorClient
	Tokens      *operatoragent.TokenHolder
	Maintenance operatoragent.Maintenance
	Operations  *operatoragent.Operations
	ToolLog     *operatoragent.ToolLog
	ToolLogPath string
}

type sessionReply struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

type passwordRequest struct {
	Password string `json:"password"`
}

type closedRequest struct {
	Closed bool `json:"closed"`
}

type commandRequest struct {
	Reason      string          `json:"reason"`
	SemanticKey string          `json:"semantic_key"`
	Payload     json.RawMessage `json:"payload"`
}

type maintenanceRequest struct {
	Version     string `json:"version"`
	Reason      string `json:"reason"`
	SemanticKey string `json:"semantic_key"`
}

func (handler Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if !loopback(request.RemoteAddr) {
		writeRefusal(writer, http.StatusUnauthorized, operatoragent.CodeUnauthorized, "the agent API is loopback only")
		return
	}
	switch {
	case request.URL.Path == setupPath && request.Method == http.MethodPost:
		handler.serveSetup(writer, request)
		return
	case !handler.Credentials.Exists():
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeSetupRequired, "run gxb-operator setup first")
		return
	case request.URL.Path == setupPath:
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeAlreadySetUp, "the agent is already set up")
		return
	case request.URL.Path == loginPath && request.Method == http.MethodPost:
		handler.serveLogin(writer, request)
		return
	}
	token := bearer(request)
	if !handler.authorized(token) {
		writeRefusal(writer, http.StatusUnauthorized, operatoragent.CodeUnauthorized, "agent session token required")
		return
	}
	switch {
	case request.URL.Path == logoutPath && request.Method == http.MethodPost:
		handler.Sessions.Logout(token)
		handler.record("logout", "session", "ok", nil)
		writeJSON(writer, http.StatusOK, map[string]string{"state": "logged out"})
	case request.URL.Path == backendStartPath && request.Method == http.MethodPost:
		handler.serveBackendStart(writer, request)
	case request.URL.Path == backendStopPath && request.Method == http.MethodPost:
		handler.serveBackendStop(writer)
	case request.URL.Path == backendStatusPath && request.Method == http.MethodGet:
		status := handler.Backend.Status()
		handler.record("backend.status", "status", "ok", status)
		writeJSON(writer, http.StatusOK, status)
	case strings.HasPrefix(request.URL.Path, commandPrefix) && request.Method == http.MethodPost:
		handler.serveCommand(writer, request, strings.TrimPrefix(request.URL.Path, commandPrefix))
	case strings.HasPrefix(request.URL.Path, readPrefix) && request.Method == http.MethodGet:
		handler.serveRead(writer, request, strings.TrimPrefix(request.URL.Path, readPrefix))
	case request.URL.Path == publishPath && request.Method == http.MethodPost:
		handler.serveMaintenance(writer, request, true)
	case request.URL.Path == withdrawPath && request.Method == http.MethodPost:
		handler.serveMaintenance(writer, request, false)
	case strings.HasPrefix(request.URL.Path, operationPrefix) && request.Method == http.MethodGet:
		handler.serveOperation(writer, strings.TrimPrefix(request.URL.Path, operationPrefix))
	case request.URL.Path == logTailPath && request.Method == http.MethodGet:
		handler.serveLogTail(writer, request)
	default:
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such agent route")
	}
}

func bearer(request *http.Request) string {
	presented, found := strings.CutPrefix(request.Header.Get("Authorization"), "Bearer ")
	if !found {
		return ""
	}
	return presented
}

func (handler Handler) authorized(token string) bool {
	return token != "" && handler.Sessions.Authorize(token)
}

func (handler Handler) serveSetup(writer http.ResponseWriter, request *http.Request) {
	if handler.Credentials.Exists() {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeAlreadySetUp, "the agent is already set up")
		return
	}
	var body passwordRequest
	if err := decodeBody(writer, request, &body); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, err.Error())
		return
	}
	if err := handler.Credentials.Setup(body.Password); err != nil {
		handler.writeAgentError(writer, "setup", err)
		return
	}
	handler.record("setup", "credentials", "ok", nil)
	writeJSON(writer, http.StatusOK, map[string]string{"state": "set up"})
}

func (handler Handler) serveLogin(writer http.ResponseWriter, request *http.Request) {
	var body passwordRequest
	if err := decodeBody(writer, request, &body); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, err.Error())
		return
	}
	if err := handler.Credentials.Verify(body.Password); err != nil {
		handler.writeAgentError(writer, "login", err)
		return
	}
	token, expiresAt, err := handler.Sessions.Login()
	if err != nil {
		handler.writeAgentError(writer, "login", err)
		return
	}
	handler.record("login", "session", "ok", map[string]any{"expires_at": expiresAt})
	writeJSON(writer, http.StatusOK, sessionReply{Token: token, ExpiresAt: expiresAt})
}

func (handler Handler) serveBackendStart(writer http.ResponseWriter, request *http.Request) {
	var body closedRequest
	if err := decodeOptionalBody(writer, request, &body); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, err.Error())
		return
	}
	if err := operatoragent.StartBackend(handler.Backend, handler.Tokens, body.Closed); err != nil {
		handler.writeAgentError(writer, "backend.start", err)
		return
	}
	status := handler.Backend.Status()
	handler.record("backend.start", "start", "ok", status)
	writeJSON(writer, http.StatusOK, status)
}

func (handler Handler) serveBackendStop(writer http.ResponseWriter) {
	if err := handler.Backend.Stop(); err != nil {
		handler.writeAgentError(writer, "backend.stop", err)
		return
	}
	handler.record("backend.stop", "stop", "ok", nil)
	writeJSON(writer, http.StatusOK, map[string]string{"state": "stopped"})
}

func (handler Handler) serveCommand(writer http.ResponseWriter, request *http.Request, name string) {
	var body commandRequest
	if err := decodeBody(writer, request, &body); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, err.Error())
		return
	}
	if name == "" || body.Reason == "" || body.SemanticKey == "" {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "command, reason and semantic_key are required")
		return
	}
	response, err := handler.Operator.Command(request.Context(), operatoragent.OperatorRequest{
		Name: name,
		Envelope: operator.Envelope{
			Principal:   "root",
			Role:        operator.RoleRoot,
			Scope:       "global",
			Reason:      body.Reason,
			SemanticKey: body.SemanticKey,
		},
		Payload: body.Payload,
	})
	if err != nil {
		handler.writeAgentError(writer, name, err)
		return
	}
	handler.record(name, "command", outcomeWord(response.Status), map[string]any{"status": response.Status})
	writeBackend(writer, response)
}

func (handler Handler) serveRead(writer http.ResponseWriter, request *http.Request, name string) {
	if name == "" {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "read name is required")
		return
	}
	response, err := handler.Operator.Read(request.Context(), name, request.URL.RawQuery)
	if err != nil {
		handler.writeAgentError(writer, name, err)
		return
	}
	handler.record(name, "read", outcomeWord(response.Status), map[string]any{"status": response.Status})
	writeBackend(writer, response)
}

func (handler Handler) serveMaintenance(writer http.ResponseWriter, request *http.Request, publish bool) {
	var body maintenanceRequest
	if err := decodeBody(writer, request, &body); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, err.Error())
		return
	}
	if body.Version == "" || body.Reason == "" || body.SemanticKey == "" {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "version, reason and semantic_key are required")
		return
	}
	run := handler.Maintenance.Publish
	action := "ota.publish"
	if !publish {
		run = handler.Maintenance.Withdraw
		action = "ota.withdraw"
	}
	operation, err := run(request.Context(), body.Version, body.Reason, body.SemanticKey)
	if err != nil {
		handler.record(action, "maintenance", "failed", map[string]any{"operation_id": operation.ID, "failed_step": operation.FailedStep, "error": err.Error()})
		handler.writeAgentError(writer, action, err)
		return
	}
	handler.record(action, "maintenance", "ok", map[string]any{"operation_id": operation.ID})
	writeJSON(writer, http.StatusOK, operation)
}

func (handler Handler) serveOperation(writer http.ResponseWriter, id string) {
	operation, err := handler.Operations.Status(id)
	if err != nil {
		var refusal *operatoragent.Refusal
		if errors.As(err, &refusal) && refusal.Code == operatoragent.CodeOperationUnknown {
			writeRefusal(writer, http.StatusNotFound, refusal.Code, refusal.Message)
			return
		}
		handler.writeAgentError(writer, "op.status", err)
		return
	}
	handler.record("op.status", "status", "ok", map[string]any{"operation_id": id})
	writeJSON(writer, http.StatusOK, operation)
}

func (handler Handler) serveLogTail(writer http.ResponseWriter, request *http.Request) {
	lines, err := tailLines(handler.ToolLogPath, requestedTail(request))
	if err != nil {
		handler.writeAgentError(writer, "log.tail", err)
		return
	}
	handler.record("log.tail", "tail", "ok", map[string]any{"lines": len(lines)})
	writeJSON(writer, http.StatusOK, map[string]any{"lines": lines})
}

func requestedTail(request *http.Request) int {
	value := request.URL.Query().Get("n")
	if value == "" {
		return defaultTail
	}
	var count int
	if parsed, err := strconv.Atoi(value); err != nil || parsed <= 0 {
		return defaultTail
	} else {
		count = parsed
	}
	if count > maxTailLines {
		return maxTailLines
	}
	return count
}

// tailLines reads the last n lines of a file without loading a whole large log:
// it reads at most the final 256 KiB.
//
// shortcut: log tail sees the last 256 KiB, upgrade when tool logs outgrow it.
func tailLines(path string, count int) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return nil, err
	}
	size := info.Size()
	start := size - tailByteLimit
	if start < 0 {
		start = 0
	}
	if _, err := file.Seek(start, io.SeekStart); err != nil {
		return nil, err
	}
	contents, err := io.ReadAll(io.LimitReader(file, tailByteLimit))
	if err != nil {
		return nil, err
	}
	text := strings.TrimRight(string(contents), "\n")
	if text == "" {
		return []string{}, nil
	}
	all := strings.Split(text, "\n")
	if start > 0 && len(all) > 0 {
		all = all[1:]
	}
	if len(all) > count {
		all = all[len(all)-count:]
	}
	return all, nil
}

func decodeBody(writer http.ResponseWriter, request *http.Request, target any) error {
	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, maxBodyBytes))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return errors.New("the body is not the expected JSON object")
	}
	return nil
}

func decodeOptionalBody(writer http.ResponseWriter, request *http.Request, target any) error {
	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, maxBodyBytes))
	decoder.DisallowUnknownFields()
	err := decoder.Decode(target)
	if errors.Is(err, io.EOF) {
		return nil
	}
	if err != nil {
		return errors.New("the body is not the expected JSON object")
	}
	return nil
}

func loopback(remoteAddress string) bool {
	host, _, err := net.SplitHostPort(remoteAddress)
	if err != nil {
		return false
	}
	address := net.ParseIP(host)
	return address != nil && address.IsLoopback()
}

func writeJSON(writer http.ResponseWriter, status int, body any) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(body)
}

func writeRefusal(writer http.ResponseWriter, status int, code, message string) {
	writeJSON(writer, status, operatoragent.Refusal{Code: code, Message: message})
}

func writeBackend(writer http.ResponseWriter, response operatoragent.BackendResponse) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(response.Status)
	_, _ = writer.Write(response.Body)
}

func outcomeWord(status int) string {
	if status >= 200 && status < 300 {
		return "ok"
	}
	return "refused"
}

func (handler Handler) writeAgentError(writer http.ResponseWriter, action string, err error) {
	var backendRefusal *operatoragent.BackendRefusal
	if errors.As(err, &backendRefusal) {
		handler.record(action, "error", "refused", map[string]any{"status": backendRefusal.Status})
		writeBackend(writer, operatoragent.BackendResponse{Status: backendRefusal.Status, Body: backendRefusal.Body})
		return
	}
	var refusal *operatoragent.Refusal
	if errors.As(err, &refusal) {
		handler.record(action, "error", "refused", map[string]any{"error_code": refusal.Code})
		writeRefusal(writer, http.StatusConflict, refusal.Code, refusal.Message)
		return
	}
	handler.record(action, "error", "failed", map[string]any{"error": err.Error()})
	writeRefusal(writer, http.StatusInternalServerError, operatoragent.CodeFailed, "the agent action failed")
}

func (handler Handler) record(op, step, outcome string, detail any) {
	if handler.ToolLog == nil {
		return
	}
	handler.ToolLog.Write(op, step, outcome, detail)
}
