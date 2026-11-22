// Package agentapi is the gxb-operator agent's local HTTP surface
// (I11A_1_PLAN "Agent decisions"): loopback callers, bearer session on every
// route but setup/login, 1 MiB bodies (the backend command cap minus envelope
// headroom on the command route for ota.register_build), backend refusals passed
// through unchanged.
package agentapi

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
	"gxb.local/backend/v2/internal/foundation/jsonbody"
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
	buildPath         = "/agent/v1/ota/build"
	operationPrefix   = "/agent/v1/ops/"
	logTailPath       = "/agent/v1/log/tail"
	modulesPath       = "/agent/v1/modules"
	resPrefix         = "/agent/v1/res/"
	backupPrefix      = "/agent/v1/backup/"

	maxBodyBytes = 1 << 20
	// The agent re-marshals a command into a larger envelope, so it accepts
	// this much less than the backend cap and every accepted body still fits.
	commandEnvelopeHeadroomBytes = 64 << 10
	maxCommandBodyBytes          = operator.MaxCommandBodyBytes - commandEnvelopeHeadroomBytes
	defaultTail                  = 50
	maxTailLines                 = 1000
	tailByteLimit                = 256 << 10
)

// Handler serves the agent API. All fields are composed by cmd/gxb-operator.
type Handler struct {
	Credentials *operatoragent.Credentials
	Sessions    *operatoragent.Sessions
	Backend     operatoragent.BackendControl
	Operator    operatoragent.OperatorClient
	Tokens      *operatoragent.TokenHolder
	Maintenance operatoragent.Maintenance
	Backup      *operatoragent.BackupService
	Operations  *operatoragent.Operations
	Build       operatoragent.OTAOperationStarter
	Modules     operatoragent.ModuleLister
	ToolLog     *operatoragent.ToolLog
	ToolLogPath string
	// OTARoot holds settings.json, whose res_path the GUI picture route reads.
	OTARoot string
	// Listen is the exact host:port the agent listens on; every route refuses
	// any other Host header (a browser must not reach the loopback API).
	Listen string
	// Guard serializes every backend lifecycle action across routes.
	Guard *operatoragent.BackendGuard
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

type buildRequest struct {
	Lane        string `json:"lane"`
	Version     string `json:"version"`
	Rollback    bool   `json:"rollback"`
	LazyRefresh bool   `json:"lazy_refresh"`
	Reason      string `json:"reason"`
	SemanticKey string `json:"semantic_key"`
}

type backupSnapshotRequest struct {
	Kind   string `json:"kind"`
	Reason string `json:"reason"`
}

type backupReasonRequest struct {
	Reason string `json:"reason"`
}

type backupRestoreRequest struct {
	ID     string `json:"id"`
	Reason string `json:"reason"`
}

func (handler Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if !handler.allowed(writer, request) {
		return
	}
	if !loopback(request.RemoteAddr) {
		writeRefusal(writer, http.StatusUnauthorized, operatoragent.CodeUnauthorized, "the agent API is loopback only")
		return
	}
	switch {
	case request.URL.Path == "/" || strings.HasPrefix(request.URL.Path, "/gui/"):
		handler.serveGUI(writer, request)
		return
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
	case request.URL.Path == buildPath && request.Method == http.MethodPost:
		handler.serveBuild(writer, request)
	case strings.HasPrefix(request.URL.Path, operationPrefix) && request.Method == http.MethodGet:
		handler.serveOperation(writer, strings.TrimPrefix(request.URL.Path, operationPrefix))
	case request.URL.Path == logTailPath && request.Method == http.MethodGet:
		handler.serveLogTail(writer, request)
	case request.URL.Path == modulesPath && request.Method == http.MethodGet:
		handler.serveModules(writer, request)
	case strings.HasPrefix(request.URL.Path, resPrefix) && request.Method == http.MethodGet:
		handler.serveRes(writer, request)
	case strings.HasPrefix(request.URL.Path, backupPrefix):
		handler.serveBackup(writer, request, strings.TrimPrefix(request.URL.Path, backupPrefix))
	default:
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such agent route")
	}
}

// allowed is the browser boundary: the request must name the configured
// listen address exactly, carry no foreign Origin, and POST application/json.
// The GUI is served by this process, so its own origin is the one exception;
// any other page still cannot drive the loopback API.
func (handler Handler) allowed(writer http.ResponseWriter, request *http.Request) bool {
	if request.Host != handler.Listen {
		writeRefusal(writer, http.StatusForbidden, operatoragent.CodeForbidden, "the agent API answers only its configured address")
		return false
	}
	origins := request.Header.Values("Origin")
	if len(origins) > 1 || (len(origins) == 1 && origins[0] != "http://"+handler.Listen) {
		writeRefusal(writer, http.StatusForbidden, operatoragent.CodeForbidden, "the agent API refuses foreign browser origins")
		return false
	}
	if request.Method == http.MethodPost {
		mediaType, _, err := mime.ParseMediaType(request.Header.Get("Content-Type"))
		if err != nil || mediaType != "application/json" {
			writeRefusal(writer, http.StatusUnsupportedMediaType, operatoragent.CodeBodyInvalid, "POST bodies must be application/json")
			return false
		}
	}
	return true
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
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
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
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
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
		handler.writeBodyError(writer, err)
		return
	}
	if !handler.Guard.TryLock() {
		handler.writeAgentError(writer, "backend.start", operatoragent.Refuse(operatoragent.CodeBackendBusy, "a backend operation is already running"))
		return
	}
	defer handler.Guard.Unlock()
	if err := operatoragent.StartBackend(handler.Backend, handler.Tokens, body.Closed); err != nil {
		handler.writeAgentError(writer, "backend.start", err)
		return
	}
	status := handler.Backend.Status()
	handler.record("backend.start", "start", "ok", status)
	writeJSON(writer, http.StatusOK, status)
}

func (handler Handler) serveBackendStop(writer http.ResponseWriter) {
	if !handler.Guard.TryLock() {
		handler.writeAgentError(writer, "backend.stop", operatoragent.Refuse(operatoragent.CodeBackendBusy, "a backend operation is already running"))
		return
	}
	defer handler.Guard.Unlock()
	if err := handler.Backend.Stop(); err != nil {
		handler.writeAgentError(writer, "backend.stop", err)
		return
	}
	handler.record("backend.stop", "stop", "ok", nil)
	writeJSON(writer, http.StatusOK, map[string]string{"state": "stopped"})
}

func (handler Handler) serveCommand(writer http.ResponseWriter, request *http.Request, name string) {
	var body commandRequest
	if err := decodeBody(writer, request, maxCommandBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
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
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
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

// serveBuild starts the ota build long operation in the background and answers
// 202 with its id; the CLI polls op status (I11A_1_PLAN "L4c decisions").
func (handler Handler) serveBuild(writer http.ResponseWriter, request *http.Request) {
	var body buildRequest
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	if handler.Build == nil {
		handler.writeAgentError(writer, "ota.build", operatoragent.Refuse(operatoragent.CodeFailed, "the agent build is not configured"))
		return
	}
	// The operation outlives the HTTP request that started it.
	operation, err := handler.Build.Start(context.WithoutCancel(request.Context()), operatoragent.BuildRequest{
		Lane:        body.Lane,
		Version:     body.Version,
		Rollback:    body.Rollback,
		LazyRefresh: body.LazyRefresh,
		Reason:      body.Reason,
		SemanticKey: body.SemanticKey,
	})
	if err != nil {
		handler.writeAgentError(writer, "ota.build", err)
		return
	}
	handler.record("ota.build", "start", "ok", map[string]any{"operation_id": operation.ID})
	writeJSON(writer, http.StatusAccepted, map[string]string{"operation_id": operation.ID})
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

// serveModules answers the backend's module list merged with the agent's own,
// so the GUI and CLI see one registry (I11A_ARCHITECTURE_V1 section 2).
func (handler Handler) serveModules(writer http.ResponseWriter, request *http.Request) {
	if handler.Modules == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeBackendUnavailable, "the module registry is not configured")
		return
	}
	modules := handler.Modules.List(request.Context())
	handler.record("modules", "list", "ok", map[string]any{"modules": len(modules.Modules)})
	writeJSON(writer, http.StatusOK, modules)
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

// serveBackup runs the backup commands in the agent (B1-B7), so they work
// while the backend or database is down.
func (handler Handler) serveBackup(writer http.ResponseWriter, request *http.Request, action string) {
	if handler.Backup == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeBackupToolsMissing, "the backup service is not configured")
		return
	}
	switch {
	case action == "list" && request.Method == http.MethodGet:
		list, err := handler.Backup.List(request.Context())
		if err != nil {
			handler.writeAgentError(writer, "backup.list", err)
			return
		}
		handler.record("backup.list", "list", "ok", map[string]any{"backups": len(list.Backups)})
		writeJSON(writer, http.StatusOK, list)
	case action == "snapshot" && request.Method == http.MethodPost:
		var body backupSnapshotRequest
		if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
			handler.writeBodyError(writer, err)
			return
		}
		if body.Reason == "" {
			writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "reason is required")
			return
		}
		kind := body.Kind
		if kind == "" {
			kind = operatoragent.BackupKindManual
		}
		operation, err := handler.Backup.Snapshot(request.Context(), kind, body.Reason)
		if err != nil {
			handler.record("backup.snapshot", "snapshot", "failed", map[string]any{"operation_id": operation.ID, "failed_step": operation.FailedStep})
			handler.writeAgentError(writer, "backup.snapshot", err)
			return
		}
		handler.record("backup.snapshot", "snapshot", "ok", map[string]any{"operation_id": operation.ID})
		writeJSON(writer, http.StatusOK, operation)
	case action == "prune" && request.Method == http.MethodPost:
		var body backupReasonRequest
		if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
			handler.writeBodyError(writer, err)
			return
		}
		if body.Reason == "" {
			writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "reason is required")
			return
		}
		operation, err := handler.Backup.Prune(request.Context())
		if err != nil {
			handler.record("backup.prune", "prune", "failed", map[string]any{"operation_id": operation.ID, "failed_step": operation.FailedStep})
			handler.writeAgentError(writer, "backup.prune", err)
			return
		}
		handler.record("backup.prune", "prune", "ok", map[string]any{"operation_id": operation.ID})
		writeJSON(writer, http.StatusOK, operation)
	case action == "restore" && request.Method == http.MethodPost:
		var body backupRestoreRequest
		if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
			handler.writeBodyError(writer, err)
			return
		}
		if body.ID == "" || body.Reason == "" {
			writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "id and reason are required")
			return
		}
		operation, err := handler.Backup.Restore(request.Context(), body.ID, body.Reason)
		if err != nil {
			handler.record("backup.restore", "restore", "failed", map[string]any{"operation_id": operation.ID, "failed_step": operation.FailedStep})
			handler.writeAgentError(writer, "backup.restore", err)
			return
		}
		handler.record("backup.restore", "restore", "ok", map[string]any{"operation_id": operation.ID})
		writeJSON(writer, http.StatusOK, operation)
	case action == "update-backend" && request.Method == http.MethodPost:
		var body backupReasonRequest
		if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
			handler.writeBodyError(writer, err)
			return
		}
		if body.Reason == "" {
			writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "reason is required")
			return
		}
		operation, err := handler.Backup.UpdateBackend(request.Context(), body.Reason)
		if err != nil {
			handler.record("backup.update_backend", "update", "failed", map[string]any{"operation_id": operation.ID, "failed_step": operation.FailedStep})
			handler.writeAgentError(writer, "backup.update_backend", err)
			return
		}
		handler.record("backup.update_backend", "update", "ok", map[string]any{"operation_id": operation.ID})
		writeJSON(writer, http.StatusOK, operation)
	default:
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such agent route")
	}
}

func decodeBody(writer http.ResponseWriter, request *http.Request, limit int64, target any) error {
	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, limit))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			return err
		}
		return errors.New("the body is not the expected JSON object")
	}
	return endOfBody(decoder)
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
	return endOfBody(decoder)
}

// endOfBody uses the agent's one trailing-data helper; a second JSON value is
// the caller's 400, a malformed tail is the generic bad body.
func endOfBody(decoder *json.Decoder) error {
	err := jsonbody.EnsureEndOfFile(decoder)
	if err == nil || errors.Is(err, jsonbody.ErrTrailingData) {
		return err
	}
	var tooLarge *http.MaxBytesError
	if errors.As(err, &tooLarge) {
		return err
	}
	return errors.New("the body is not the expected JSON object")
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

func (handler Handler) writeBodyError(writer http.ResponseWriter, err error) {
	var tooLarge *http.MaxBytesError
	if errors.As(err, &tooLarge) {
		writeRefusal(writer, http.StatusRequestEntityTooLarge, operatoragent.CodeBodyTooLarge, "the body is too large")
		return
	}
	status := http.StatusConflict
	if errors.Is(err, jsonbody.ErrTrailingData) {
		status = http.StatusBadRequest
	}
	writeRefusal(writer, status, operatoragent.CodeBodyInvalid, err.Error())
}

func (handler Handler) writeAgentError(writer http.ResponseWriter, action string, err error) {
	var backendRefusal *operatoragent.BackendRefusal
	if errors.As(err, &backendRefusal) {
		handler.record(action, "error", "refused", map[string]any{"status": backendRefusal.Status})
		writeBackend(writer, operatoragent.BackendResponse{Status: backendRefusal.Status, Body: backendRefusal.Body})
		return
	}
	var transient *operatoragent.Transient
	if errors.As(err, &transient) {
		handler.record(action, "error", "unavailable", map[string]any{"error_code": transient.Code})
		writeRefusal(writer, http.StatusServiceUnavailable, transient.Code, transient.Message)
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
