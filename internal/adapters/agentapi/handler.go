// Package agentapi is the gxb-operator agent's local HTTP surface
// (I11A_1_PLAN "Agent decisions"): loopback callers, bearer session on every
// route but setup/login, 1 MiB bodies (the backend command cap minus envelope
// headroom on the command route for ota.register_build), backend refusals passed
// through unchanged.
package agentapi

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
	"gxb.local/backend/v2/internal/application/operatormedia"
	"gxb.local/backend/v2/internal/foundation/jsonbody"
)

const (
	setupPath          = "/agent/v1/setup"
	loginPath          = "/agent/v1/login"
	logoutPath         = "/agent/v1/logout"
	passwordPath       = "/agent/v1/password"
	backendStartPath   = "/agent/v1/backend/start"
	backendStopPath    = "/agent/v1/backend/stop"
	backendRestartPath = "/agent/v1/backend/restart"
	backendStatusPath  = "/agent/v1/backend/status"
	commandPrefix      = "/agent/v1/commands/"
	readPrefix         = "/agent/v1/reads/"
	publishPath        = "/agent/v1/ota/publish"
	withdrawPath       = "/agent/v1/ota/withdraw"
	buildPath          = "/agent/v1/ota/build"
	operationPrefix    = "/agent/v1/ops/"
	logTailPath        = "/agent/v1/log/tail"
	modulesPath        = "/agent/v1/modules"
	resPrefix          = "/agent/v1/res/"
	backupPrefix       = "/agent/v1/backup/"
	terminalOpenPath   = "/agent/v1/terminal/open"
	terminalPrefix     = "/agent/v1/terminal/"

	maxBodyBytes = 1 << 20
	// The agent re-marshals a command into a larger envelope, so it accepts
	// this much less than the backend cap and every accepted body still fits.
	commandEnvelopeHeadroomBytes = 64 << 10
	maxCommandBodyBytes          = operator.MaxCommandBodyBytes - commandEnvelopeHeadroomBytes
	defaultTail                  = 50
	maxTailLines                 = 1000
	exchangeBodyCaptureLimit     = 64 << 10
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
	Dashboard   operatoragent.Dashboard
	ToolLog     *operatoragent.ToolLog
	// Logs answers the local log sources and the logs.clear command; the client
	// source is forwarded to the backend read.
	Logs *operatoragent.LogService
	// Settings answers the agent.settings read and writes agent.json and the
	// backend env file locally (G22).
	Settings *operatoragent.SettingsService
	// Files lists local folders and files for the GUI path picker (G7h).
	Files *operatoragent.FileBrowser
	// Pings answers the dashboard.pings read from the agent's sampler (G37).
	Pings *operatoragent.PingSampler
	// Media stores notice pictures on this machine and answers their public URL
	// (G41).
	Media *operatormedia.Service
	// OTARoot holds settings.json, whose res_path the GUI picture route reads.
	OTARoot string
	// Listen is the exact host:port the agent listens on; every route refuses
	// any other Host header (a browser must not reach the loopback API).
	Listen string
	// Guard serializes every backend lifecycle action across routes.
	Guard *operatoragent.BackendGuard
	// Terminal runs the operator's shells (G42); nil disables the feature.
	Terminal *operatoragent.TerminalService
}

type sessionReply struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

type passwordRequest struct {
	Password string `json:"password"`
}

type passwordChangeRequest struct {
	Current string `json:"current"`
	New     string `json:"new"`
}

type closedRequest struct {
	Closed bool `json:"closed"`
}

type commandRequest struct {
	Reason           string          `json:"reason"`
	SemanticKey      string          `json:"semantic_key"`
	ExpectedRevision *int64          `json:"expected_revision,omitempty"`
	Payload          json.RawMessage `json:"payload"`
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
	Name   string `json:"name"`
	Pin    bool   `json:"pin"`
}

type backupPinRequest struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type backupIDRequest struct {
	ID string `json:"id"`
}

type backupReasonRequest struct {
	Reason string `json:"reason"`
}

type backupRestoreRequest struct {
	ID     string `json:"id"`
	Reason string `json:"reason"`
}

type backupPathRequest struct {
	Path string `json:"path"`
}

// ServeHTTP records one tool log line per API exchange (C5: route, masked
// params, status, error code, duration) and then dispatches.
func (handler Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	exchange := &exchangeRecorder{ResponseWriter: writer}
	startedAt := time.Now()
	capture := startBodyCapture(request)
	handler.serve(exchange, request)
	handler.recordExchange(request, exchange, exchangeParams(request, capture), time.Since(startedAt))
}

func (handler Handler) serve(writer http.ResponseWriter, request *http.Request) {
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
	case request.URL.Path == passwordPath && request.Method == http.MethodPost:
		handler.servePasswordChange(writer, request)
	case request.URL.Path == backendStartPath && request.Method == http.MethodPost:
		handler.serveBackendStart(writer, request)
	case request.URL.Path == backendStopPath && request.Method == http.MethodPost:
		handler.serveBackendStop(writer)
	case request.URL.Path == backendRestartPath && request.Method == http.MethodPost:
		handler.serveBackendRestart(writer, request)
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
	case strings.HasPrefix(request.URL.Path, mediaPrefix):
		handler.serveMedia(writer, request)
	case strings.HasPrefix(request.URL.Path, backupPrefix):
		handler.serveBackup(writer, request, strings.TrimPrefix(request.URL.Path, backupPrefix))
	case request.URL.Path == terminalOpenPath && request.Method == http.MethodPost:
		handler.serveTerminalOpen(writer, request)
	case strings.HasPrefix(request.URL.Path, terminalPrefix):
		handler.serveTerminalRoute(writer, request, strings.TrimPrefix(request.URL.Path, terminalPrefix))
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

// authorized also checks the password generation, so a change or an offline
// reset refuses every token minted before it.
func (handler Handler) authorized(token string) bool {
	if token == "" {
		return false
	}
	generation, err := handler.Credentials.Generation()
	if err != nil {
		return false
	}
	return handler.Sessions.Authorize(token, generation)
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
	generation, err := handler.Credentials.Generation()
	if err != nil {
		handler.writeAgentError(writer, "login", err)
		return
	}
	token, expiresAt, err := handler.Sessions.Login(generation)
	if err != nil {
		handler.writeAgentError(writer, "login", err)
		return
	}
	handler.record("login", "session", "ok", map[string]any{"expires_at": expiresAt})
	writeJSON(writer, http.StatusOK, sessionReply{Token: token, ExpiresAt: expiresAt})
}

// servePasswordChange replaces the root password and, through the new
// generation, ends every live session on its next request (design A.1).
func (handler Handler) servePasswordChange(writer http.ResponseWriter, request *http.Request) {
	var body passwordChangeRequest
	if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	if err := handler.Credentials.ChangePassword(body.Current, body.New); err != nil {
		handler.writeAgentError(writer, "account.password", err)
		return
	}
	handler.record("account", "password changed", "ok", nil)
	writeJSON(writer, http.StatusOK, map[string]string{"state": "password changed"})
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

// serveBackendRestart stops and starts the backend as one guarded operation
// (G34). A failure after the stop answers a refusal that says the backend is
// now stopped.
func (handler Handler) serveBackendRestart(writer http.ResponseWriter, request *http.Request) {
	var body closedRequest
	if err := decodeOptionalBody(writer, request, &body); err != nil {
		handler.writeBodyError(writer, err)
		return
	}
	if !handler.Guard.TryLock() {
		handler.writeAgentError(writer, "backend.restart", operatoragent.Refuse(operatoragent.CodeBackendBusy, "a backend operation is already running"))
		return
	}
	defer handler.Guard.Unlock()
	if err := operatoragent.RestartBackend(handler.Backend, handler.Tokens, body.Closed); err != nil {
		handler.writeAgentError(writer, "backend.restart", err)
		return
	}
	status := handler.Backend.Status()
	handler.record("backend.restart", "restart", "ok", status)
	writeJSON(writer, http.StatusOK, status)
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
	if name == "logs.clear" && handler.Logs != nil {
		handler.serveLogsClear(writer, request, body)
		return
	}
	if name == "agent.settings.set" {
		handler.serveAgentSettingsSet(writer, body)
		return
	}
	if name == "server.url.set" {
		handler.serveServerURLSet(writer, body)
		return
	}
	if name == "server.public_urls.set" {
		handler.servePublicURLsSet(writer, body)
		return
	}
	response, err := handler.Operator.Command(request.Context(), operatoragent.OperatorRequest{
		Name: name,
		Envelope: operator.Envelope{
			Principal:        "root",
			Role:             operator.RoleRoot,
			Scope:            "global",
			Reason:           body.Reason,
			SemanticKey:      body.SemanticKey,
			ExpectedRevision: body.ExpectedRevision,
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
	if name == "dashboard.summary" {
		handler.serveDashboard(writer, request)
		return
	}
	if name == "dashboard.pings" {
		handler.servePings(writer)
		return
	}
	if name == "logs.tail" || name == "logs.search" {
		handler.serveLogRead(writer, request, name)
		return
	}
	if name == "agent.settings" {
		handler.serveAgentSettings(writer)
		return
	}
	if name == "agent.fs.list" {
		handler.serveFileList(writer, request)
		return
	}
	if name == "agent.cli.usage" {
		handler.serveCLIUsage(writer)
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

// serveDashboard answers the agent-composed dashboard read; it folds several
// backend reads and the process state, so it never forwards one read.
func (handler Handler) serveDashboard(writer http.ResponseWriter, request *http.Request) {
	summary := handler.Dashboard.Summary(request.Context())
	handler.record("dashboard.summary", "read", "ok", map[string]any{"servers": len(summary.Servers), "events": len(summary.Events)})
	writeJSON(writer, http.StatusOK, summary)
}

// servePings answers the sampler's in-memory history; the sampler belongs to
// the agent process, so the read never forwards.
func (handler Handler) servePings(writer http.ResponseWriter) {
	if handler.Pings == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the ping sampler is not configured")
		return
	}
	report := handler.Pings.Read()
	handler.record("dashboard.pings", "read", "ok", map[string]any{"targets": len(report.Targets)})
	writeJSON(writer, http.StatusOK, report)
}

// serveAgentSettings answers the agent's own settings read; agent.json and the
// backend env file belong to the agent, so the read never forwards.
func (handler Handler) serveAgentSettings(writer http.ResponseWriter) {
	if handler.Settings == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the agent settings are not configured")
		return
	}
	values, err := handler.Settings.Values()
	if err != nil {
		handler.writeAgentError(writer, "agent.settings", err)
		return
	}
	handler.record("agent.settings", "read", "ok", nil)
	writeJSON(writer, http.StatusOK, values)
}

// serveCLIUsage answers the operator CLI help the Terminal page prints and its
// Commands panel lists. It is the same text the CLI help command prints.
func (handler Handler) serveCLIUsage(writer http.ResponseWriter) {
	usage := operatoragent.CLIHelp()
	handler.record("agent.cli.usage", "read", "ok", map[string]any{"commands": len(usage.Commands)})
	writeJSON(writer, http.StatusOK, usage)
}

// serveFileList answers the path picker's folder listing; it never forwards,
// because only the agent's own machine has the folders the GUI shows (G7h).
func (handler Handler) serveFileList(writer http.ResponseWriter, request *http.Request) {
	if handler.Files == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the file browser is not configured")
		return
	}
	values := request.URL.Query()
	showFiles, err := parseShowFiles(values.Get("show_files"))
	if err != nil {
		handler.writeAgentError(writer, "agent.fs.list", err)
		return
	}
	listing, err := handler.Files.List(operatoragent.FileListRequest{Path: values.Get("path"), ShowFiles: showFiles})
	if err != nil {
		handler.writeAgentError(writer, "agent.fs.list", err)
		return
	}
	handler.record("agent.fs.list", "read", "ok", map[string]any{"entries": len(listing.Entries)})
	writeJSON(writer, http.StatusOK, listing)
}

func parseShowFiles(text string) (bool, error) {
	if text == "" {
		return false, nil
	}
	value, err := strconv.ParseBool(text)
	if err != nil {
		return false, operatoragent.Refuse(operatoragent.CodeBodyInvalid, "show_files must be true or false")
	}
	return value, nil
}

// serveAgentSettingsSet writes the agent.json paths; a refused value keeps the
// old file (F1).
func (handler Handler) serveAgentSettingsSet(writer http.ResponseWriter, body commandRequest) {
	if handler.Settings == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the agent settings are not configured")
		return
	}
	var change operatoragent.AgentSettingsChange
	if err := decodeCommandPayload(body.Payload, &change); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, err.Error())
		return
	}
	reply, err := handler.Settings.SetAgent(change)
	if err != nil {
		handler.writeAgentError(writer, "agent.settings.set", err)
		return
	}
	handler.record("agent.settings.set", "settings", "ok", nil)
	writeJSON(writer, http.StatusOK, reply)
}

// serveServerURLSet writes the public engine URL into the backend env file.
func (handler Handler) serveServerURLSet(writer http.ResponseWriter, body commandRequest) {
	if handler.Settings == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the agent settings are not configured")
		return
	}
	var change struct {
		URL string `json:"url"`
	}
	if err := decodeCommandPayload(body.Payload, &change); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, err.Error())
		return
	}
	reply, err := handler.Settings.SetServerURL(change.URL)
	if err != nil {
		handler.writeAgentError(writer, "server.url.set", err)
		return
	}
	handler.record("server.url.set", "settings", "ok", nil)
	writeJSON(writer, http.StatusOK, reply)
}

// servePublicURLsSet stores the role-keyed SDK, game API and assets URLs; an
// unknown role or a non-http(s) value is a 409 refusal.
func (handler Handler) servePublicURLsSet(writer http.ResponseWriter, body commandRequest) {
	if handler.Settings == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the agent settings are not configured")
		return
	}
	var change struct {
		PublicURLs map[string]string `json:"public_urls"`
		SDK        string            `json:"sdk"`
		API        string            `json:"api"`
		Assets     string            `json:"assets"`
	}
	if err := decodeCommandPayload(body.Payload, &change); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, err.Error())
		return
	}
	// The Server page sends the role-keyed map; the registry-driven Advanced
	// form sends the three flat fields. Both reach the same validation.
	values := change.PublicURLs
	if values == nil {
		values = map[string]string{}
	}
	for role, value := range map[string]string{
		operatoragent.PublicRoleSDK:    change.SDK,
		operatoragent.PublicRoleAPI:    change.API,
		operatoragent.PublicRoleAssets: change.Assets,
	} {
		if value != "" {
			values[role] = value
		}
	}
	reply, err := handler.Settings.SetPublicURLs(values)
	if err != nil {
		handler.writeAgentError(writer, "server.public_urls.set", err)
		return
	}
	handler.record("server.public_urls.set", "settings", "ok", nil)
	writeJSON(writer, http.StatusOK, reply)
}

// decodeCommandPayload decodes one typed local command payload strictly, so a
// typo never silently changes a setting.
func decodeCommandPayload(payload json.RawMessage, target any) error {
	if len(payload) == 0 {
		return errors.New("the payload is required")
	}
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return errors.New("the payload does not match the command")
	}
	return endOfBody(decoder)
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
	if handler.Logs == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the log sources are not configured")
		return
	}
	result, err := handler.Logs.Tail(request.Context(), operatoragent.LogSourceTool, "", "", requestedTail(request))
	if err != nil {
		handler.writeAgentError(writer, "log.tail", err)
		return
	}
	lines := make([]string, 0, len(result.Lines))
	for _, line := range result.Lines {
		lines = append(lines, line.Text)
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

// serveLogRead answers logs.tail and logs.search from the agent's own files;
// the client source is forwarded to the backend journal read.
func (handler Handler) serveLogRead(writer http.ResponseWriter, request *http.Request, name string) {
	if handler.Logs == nil {
		writeRefusal(writer, http.StatusServiceUnavailable, operatoragent.CodeFailed, "the log sources are not configured")
		return
	}
	values := request.URL.Query()
	limit, err := parseLogLimit(values.Get("limit"))
	if err != nil {
		handler.writeAgentError(writer, name, err)
		return
	}
	var result any
	if name == "logs.tail" {
		result, err = handler.Logs.Tail(request.Context(), values.Get("source"), values.Get("after_cursor"), values.Get("level"), limit)
	} else {
		result, err = handler.Logs.Search(request.Context(), values.Get("source"), values.Get("player"), values.Get("from"), values.Get("to"), values.Get("level"), limit)
	}
	if err != nil {
		handler.writeAgentError(writer, name, err)
		return
	}
	handler.record(name, "read", "ok", nil)
	writeJSON(writer, http.StatusOK, result)
}

func parseLogLimit(text string) (int, error) {
	if text == "" {
		return 0, nil
	}
	value, err := strconv.Atoi(text)
	if err != nil || value < 1 || value > operatoragent.MaxLogTailLimit {
		return 0, operatoragent.Refuse(operatoragent.CodeLogQueryInvalid, fmt.Sprintf("limit must be between 1 and %d", operatoragent.MaxLogTailLimit))
	}
	return value, nil
}

// serveLogsClear runs logs.clear locally. The client source is one typed
// backend command, so the clear is audited on the bus like every state change.
func (handler Handler) serveLogsClear(writer http.ResponseWriter, request *http.Request, body commandRequest) {
	var clear operatoragent.LogClearRequest
	if err := json.Unmarshal(body.Payload, &clear); err != nil {
		writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "the payload is not a logs.clear payload")
		return
	}
	if clear.Source == operatoragent.LogSourceClient {
		handler.forwardLogsClear(writer, request, body, clear)
		return
	}
	result, err := handler.Logs.ClearFiles(clear)
	if err != nil {
		handler.writeAgentError(writer, "logs.clear", err)
		return
	}
	handler.record("logs.clear", "clear", "ok", map[string]any{"source": result.Source, "scope": result.Scope, "removed_files": result.RemovedFiles})
	writeJSON(writer, http.StatusOK, result)
}

func (handler Handler) forwardLogsClear(writer http.ResponseWriter, request *http.Request, body commandRequest, clear operatoragent.LogClearRequest) {
	uid, playerID := clear.UID, clear.PlayerID
	if clear.Scope == "player" && clear.Player != "" {
		resolvedUID, resolvedPlayerID, err := handler.Logs.ResolvePlayer(request.Context(), clear.Player)
		if err != nil {
			handler.writeAgentError(writer, "logs.clear", err)
			return
		}
		uid, playerID = resolvedUID, resolvedPlayerID
	}
	payload, err := json.Marshal(map[string]any{
		"source":     operatoragent.LogSourceClient,
		"scope":      clear.Scope,
		"uid":        uid,
		"player_id":  playerID,
		"older_than": clear.OlderThan,
	})
	if err != nil {
		handler.writeAgentError(writer, "logs.clear", err)
		return
	}
	response, err := handler.Operator.Command(request.Context(), operatoragent.OperatorRequest{
		Name: "logs.clear",
		Envelope: operator.Envelope{
			Principal:   "root",
			Role:        operator.RoleRoot,
			Scope:       "global",
			Reason:      body.Reason,
			SemanticKey: body.SemanticKey,
		},
		Payload: payload,
	})
	if err != nil {
		handler.writeAgentError(writer, "logs.clear", err)
		return
	}
	handler.record("logs.clear", "command", outcomeWord(response.Status), map[string]any{"status": response.Status})
	writeBackend(writer, response)
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
		if handler.Operator != nil {
			// The list must still answer while the backend is down, so the
			// version read is a short best effort.
			versionContext, cancel := context.WithTimeout(request.Context(), 2*time.Second)
			if version, versionErr := handler.Operator.Version(versionContext); versionErr == nil {
				migration := version.Migration
				list.BackendMigration = &migration
			}
			cancel()
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
		operation, err := handler.Backup.Snapshot(request.Context(), operatoragent.SnapshotOptions{Kind: kind, Reason: body.Reason, Name: body.Name, Pinned: body.Pin})
		if err != nil {
			handler.record("backup.snapshot", "snapshot", "failed", map[string]any{"operation_id": operation.ID, "failed_step": operation.FailedStep})
			handler.writeAgentError(writer, "backup.snapshot", err)
			return
		}
		handler.record("backup.snapshot", "snapshot", "ok", map[string]any{"operation_id": operation.ID})
		writeJSON(writer, http.StatusOK, operation)
	case action == "path" && request.Method == http.MethodGet:
		writeJSON(writer, http.StatusOK, handler.Backup.Settings())
	case action == "path" && request.Method == http.MethodPost:
		var body backupPathRequest
		if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
			handler.writeBodyError(writer, err)
			return
		}
		list, err := handler.Backup.SetPath(body.Path)
		if err != nil {
			handler.writeAgentError(writer, "backup.path", err)
			return
		}
		handler.record("backup.path", "set", "ok", map[string]any{"directory": list.Directory})
		writeJSON(writer, http.StatusOK, list)
	case action == "delete" && request.Method == http.MethodPost:
		var body backupRestoreRequest
		if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
			handler.writeBodyError(writer, err)
			return
		}
		if body.ID == "" || body.Reason == "" {
			writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "id and reason are required")
			return
		}
		manifest, err := handler.Backup.Delete(body.ID, body.Reason)
		if err != nil {
			handler.writeAgentError(writer, "backup.delete", err)
			return
		}
		handler.record("backup.delete", "delete", "ok", map[string]any{"id": manifest.ID})
		writeJSON(writer, http.StatusOK, manifest)
	case action == "pin" && request.Method == http.MethodPost:
		var body backupPinRequest
		if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
			handler.writeBodyError(writer, err)
			return
		}
		if body.ID == "" || body.Name == "" {
			writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "id and name are required")
			return
		}
		manifest, err := handler.Backup.Pin(body.ID, body.Name)
		if err != nil {
			handler.writeAgentError(writer, "backup.pin", err)
			return
		}
		handler.record("backup.pin", "pin", "ok", map[string]any{"id": manifest.ID})
		writeJSON(writer, http.StatusOK, manifest)
	case action == "unpin" && request.Method == http.MethodPost:
		var body backupIDRequest
		if err := decodeBody(writer, request, maxBodyBytes, &body); err != nil {
			handler.writeBodyError(writer, err)
			return
		}
		if body.ID == "" {
			writeRefusal(writer, http.StatusConflict, operatoragent.CodeBodyInvalid, "id is required")
			return
		}
		manifest, err := handler.Backup.Unpin(body.ID)
		if err != nil {
			handler.writeAgentError(writer, "backup.unpin", err)
			return
		}
		handler.record("backup.unpin", "unpin", "ok", map[string]any{"id": manifest.ID})
		writeJSON(writer, http.StatusOK, manifest)
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

// exchangeRoute is one agent API route. The coverage test walks this table and
// proves every route writes a tool log line (C5).
type exchangeRoute struct {
	Name   string
	Method string
	Sample string
	Match  func(string) bool
}

func exactPath(path string) func(string) bool {
	return func(candidate string) bool { return candidate == path }
}

func prefixPath(prefix string) func(string) bool {
	return func(candidate string) bool { return strings.HasPrefix(candidate, prefix) }
}

var exchangeRoutes = []exchangeRoute{
	{Name: "setup", Method: http.MethodPost, Sample: setupPath, Match: exactPath(setupPath)},
	{Name: "login", Method: http.MethodPost, Sample: loginPath, Match: exactPath(loginPath)},
	{Name: "logout", Method: http.MethodPost, Sample: logoutPath, Match: exactPath(logoutPath)},
	{Name: "backend.start", Method: http.MethodPost, Sample: backendStartPath, Match: exactPath(backendStartPath)},
	{Name: "backend.stop", Method: http.MethodPost, Sample: backendStopPath, Match: exactPath(backendStopPath)},
	{Name: "backend.restart", Method: http.MethodPost, Sample: backendRestartPath, Match: exactPath(backendRestartPath)},
	{Name: "backend.status", Method: http.MethodGet, Sample: backendStatusPath, Match: exactPath(backendStatusPath)},
	{Name: "command", Method: http.MethodPost, Sample: commandPrefix + "ota.publish", Match: prefixPath(commandPrefix)},
	{Name: "read", Method: http.MethodGet, Sample: readPrefix + "player.find", Match: prefixPath(readPrefix)},
	{Name: "ota.publish", Method: http.MethodPost, Sample: publishPath, Match: exactPath(publishPath)},
	{Name: "ota.withdraw", Method: http.MethodPost, Sample: withdrawPath, Match: exactPath(withdrawPath)},
	{Name: "ota.build", Method: http.MethodPost, Sample: buildPath, Match: exactPath(buildPath)},
	{Name: "operation", Method: http.MethodGet, Sample: operationPrefix + "0123456789abcdef0123456789abcdef", Match: prefixPath(operationPrefix)},
	{Name: "log.tail", Method: http.MethodGet, Sample: logTailPath, Match: exactPath(logTailPath)},
	{Name: "modules", Method: http.MethodGet, Sample: modulesPath, Match: exactPath(modulesPath)},
	{Name: "media.import_url", Method: http.MethodPost, Sample: mediaImportPath, Match: exactPath(mediaImportPath)},
	{Name: "media.upload", Method: http.MethodPost, Sample: mediaUploadPath, Match: exactPath(mediaUploadPath)},
	{Name: "media.list", Method: http.MethodGet, Sample: mediaListPath, Match: exactPath(mediaListPath)},
	{Name: "media.file", Method: http.MethodGet, Sample: mediaFilePrefix + "0123456789abcdef.png", Match: prefixPath(mediaFilePrefix)},
	{Name: "terminal.open", Method: http.MethodPost, Sample: terminalOpenPath, Match: exactPath(terminalOpenPath)},
	{Name: "terminal", Method: http.MethodGet, Sample: terminalPrefix + terminalSampleID + "/stream", Match: prefixPath(terminalPrefix)},
	{Name: "terminal", Method: http.MethodPost, Sample: terminalPrefix + terminalSampleID + "/input", Match: prefixPath(terminalPrefix)},
}

const terminalSampleID = "0000000000000000000000000000000000000000000000000000000000000000"

// exchangeRouteName names the exchange for the tool log.
func exchangeRouteName(method, path string) string {
	for _, route := range exchangeRoutes {
		if route.Method == method && route.Match(path) {
			return route.Name
		}
	}
	return "unknown"
}

// exchangeRecorder captures the status and a bounded response body for the
// tool log while streaming the real reply through.
type exchangeRecorder struct {
	http.ResponseWriter
	status int
	body   bytes.Buffer
}

func (recorder *exchangeRecorder) WriteHeader(status int) {
	if recorder.status != 0 {
		return
	}
	recorder.status = status
	recorder.ResponseWriter.WriteHeader(status)
}

func (recorder *exchangeRecorder) Write(data []byte) (int, error) {
	if recorder.status == 0 {
		recorder.WriteHeader(http.StatusOK)
	}
	if remaining := exchangeBodyCaptureLimit - recorder.body.Len(); remaining > 0 {
		if len(data) < remaining {
			remaining = len(data)
		}
		recorder.body.Write(data[:remaining])
	}
	return recorder.ResponseWriter.Write(data)
}

// Flush streams a terminal event at once; the recorder still sees the status.
func (recorder *exchangeRecorder) Flush() {
	if flusher, ok := recorder.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
}

// bodyCapture records the first bytes of a POST body as the route reads them,
// so the tool log gets masked params without buffering the whole command cap.
type bodyCapture struct {
	buffer    bytes.Buffer
	truncated bool
}

func (capture *bodyCapture) Write(data []byte) (int, error) {
	if remaining := exchangeBodyCaptureLimit - capture.buffer.Len(); remaining > 0 {
		if len(data) <= remaining {
			capture.buffer.Write(data)
		} else {
			capture.buffer.Write(data[:remaining])
			capture.truncated = true
		}
	} else if len(data) > 0 {
		capture.truncated = true
	}
	return len(data), nil
}

type teeReadCloser struct {
	io.Reader
	closer io.Closer
}

func (reader teeReadCloser) Close() error { return reader.closer.Close() }

// credentialPaths carry passwords under field names the key masking cannot
// know (current, new), so their bodies never reach the tool log. The picture
// upload carries bytes, not log parameters, and is skipped for the same reason.
var credentialPaths = map[string]bool{setupPath: true, loginPath: true, passwordPath: true, mediaUploadPath: true}

// sensitiveBodyPath names the POST bodies that must never reach the tool log:
// the credential routes and the terminal password and keystrokes.
func sensitiveBodyPath(path string) bool {
	if credentialPaths[path] {
		return true
	}
	return path == terminalOpenPath || (strings.HasPrefix(path, terminalPrefix) && strings.HasSuffix(path, "/input"))
}

// startBodyCapture tees a POST body into the bounded capture. The route still
// sees every byte and every size cap still applies.
func startBodyCapture(request *http.Request) *bodyCapture {
	capture := &bodyCapture{}
	if request.Method == http.MethodPost && request.Body != nil && !sensitiveBodyPath(request.URL.Path) {
		request.Body = teeReadCloser{Reader: io.TeeReader(request.Body, capture), closer: request.Body}
	}
	return capture
}

// exchangeParams is the masked detail the tool log keeps: the query string and
// the parsed JSON body when the capture holds it whole.
func exchangeParams(request *http.Request, capture *bodyCapture) any {
	params := map[string]any{}
	if len(request.URL.Query()) > 0 {
		params["query"] = request.URL.Query()
	}
	if capture != nil && capture.buffer.Len() > 0 {
		var decoded any
		if capture.truncated {
			params["body_truncated"] = true
			params["body_bytes"] = capture.buffer.Len()
		} else if json.Unmarshal(capture.buffer.Bytes(), &decoded) == nil {
			params["body"] = decoded
		} else {
			params["body_bytes"] = capture.buffer.Len()
		}
	}
	return params
}

// recordExchange writes the one line every API route leaves (C5). Static GUI
// and picture responses are not API exchanges and would flood the log.
func (handler Handler) recordExchange(request *http.Request, exchange *exchangeRecorder, params any, elapsed time.Duration) {
	if handler.ToolLog == nil {
		return
	}
	path := request.URL.Path
	if path == "/" || strings.HasPrefix(path, "/gui/") || strings.HasPrefix(path, resPrefix) {
		return
	}
	status := exchange.status
	if status == 0 {
		status = http.StatusOK
	}
	detail := map[string]any{
		"method":      request.Method,
		"path":        path,
		"status":      status,
		"duration_ms": elapsed.Milliseconds(),
		"params":      operatoragent.MaskValue(params),
	}
	if code := responseErrorCode(exchange.body.Bytes()); code != "" {
		detail["error_code"] = code
	}
	handler.ToolLog.Write(exchangeRouteName(request.Method, path), "exchange", exchangeOutcome(status), detail)
}

func exchangeOutcome(status int) string {
	switch {
	case status >= 500:
		return "failed"
	case status >= 400:
		return "refused"
	default:
		return "ok"
	}
}

func responseErrorCode(body []byte) string {
	var reply struct {
		ErrorCode any `json:"error_code"`
		Code      any `json:"code"`
	}
	if json.Unmarshal(body, &reply) != nil {
		return ""
	}
	if text, ok := reply.ErrorCode.(string); ok {
		return text
	}
	if text, ok := reply.Code.(string); ok {
		return text
	}
	return ""
}
