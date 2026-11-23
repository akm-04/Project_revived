package operatoragent

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"sync"

	"gxb.local/backend/v2/internal/application/operator"
)

// BackendStatus is what `backend status` reports.
type BackendStatus struct {
	Running bool   `json:"running"`
	PID     int    `json:"pid,omitempty"`
	State   string `json:"state,omitempty"`
}

// BackendControl is the agent's process-control port.
type BackendControl interface {
	Start(closed bool, token string) error
	Stop() error
	Status() BackendStatus
}

// BackendGuard admits one backend lifecycle action at a time: a start, a stop
// or a whole maintenance flow. It refuses rather than queues.
type BackendGuard struct {
	mutex sync.Mutex
}

// TryLock takes the guard when it is free.
func (guard *BackendGuard) TryLock() bool {
	return guard.mutex.TryLock()
}

// Unlock releases the guard.
func (guard *BackendGuard) Unlock() {
	guard.mutex.Unlock()
}

// OperatorRequest is one forwarded operator command.
type OperatorRequest struct {
	Name     string
	Envelope operator.Envelope
	Payload  json.RawMessage
}

// BackendResponse is a backend operator-API answer, status and body verbatim.
type BackendResponse struct {
	Status int
	Body   []byte
}

// OperatorClient is the agent's outbound operator-API port.
type OperatorClient interface {
	Command(context.Context, OperatorRequest) (BackendResponse, error)
	Read(ctx context.Context, name, query string) (BackendResponse, error)
	Version(context.Context) (operator.VersionInfo, error)
}

// Maintenance is the OTA publish/withdraw flow of I11A_OTA_RELEASE_V1 ruling
// 13: stop the game listener, apply the command, reopen. A failure leaves the
// backend closed and names the failed step in the operation record.
type Maintenance struct {
	Backend    BackendControl
	Operator   OperatorClient
	Tokens     *TokenHolder
	Operations *Operations
	Guard      *BackendGuard
}

// StartBackend mints the per-start operator token and launches the backend. The
// holder takes the new token only after the launch succeeds, so a refused start
// keeps the live per-start token in place.
func StartBackend(backend BackendControl, tokens *TokenHolder, closed bool) error {
	token, err := NewToken()
	if err != nil {
		return err
	}
	if err := backend.Start(closed, token); err != nil {
		return err
	}
	tokens.Set(token)
	return nil
}

// RestartBackend stops the backend and starts it again; the caller holds the
// busy guard for the whole pair, so no start, stop or maintenance flow
// interleaves it. A failure after the stop leaves the backend stopped and the
// refusal says so.
func RestartBackend(backend BackendControl, tokens *TokenHolder, closed bool) error {
	if err := backend.Stop(); err != nil {
		return err
	}
	if err := StartBackend(backend, tokens, closed); err != nil {
		return Refuse(CodeBackendRestartFailed, "the backend is now stopped: the restart could not start it: "+err.Error())
	}
	return nil
}

// Publish runs stop -> start closed -> status -> publish -> stop -> start open.
func (maintenance Maintenance) Publish(ctx context.Context, version, reason, semanticKey string) (Operation, error) {
	return maintenance.run(ctx, "ota.publish", version, reason, semanticKey)
}

// Withdraw runs the same maintenance window for ota.withdraw.
func (maintenance Maintenance) Withdraw(ctx context.Context, version, reason, semanticKey string) (Operation, error) {
	return maintenance.run(ctx, "ota.withdraw", version, reason, semanticKey)
}

func (maintenance Maintenance) run(ctx context.Context, command, version, reason, semanticKey string) (Operation, error) {
	if !maintenance.Guard.TryLock() {
		return Operation{}, Refuse(CodeBackendBusy, "a backend operation is already running")
	}
	defer maintenance.Guard.Unlock()

	var revision int64
	steps := []Step{
		{Name: "stop backend", Run: func(context.Context) (any, error) { return nil, maintenance.Backend.Stop() }},
		{Name: "start backend closed", Run: func(context.Context) (any, error) {
			return nil, StartBackend(maintenance.Backend, maintenance.Tokens, true)
		}},
		{Name: "read active revision", Run: func(ctx context.Context) (any, error) {
			response, err := maintenance.Operator.Read(ctx, "ota.status", "")
			if err != nil {
				return nil, err
			}
			if response.Status != 200 {
				return nil, &BackendRefusal{Status: response.Status, Body: response.Body}
			}
			var status struct {
				Revision int64 `json:"revision"`
			}
			if err := json.Unmarshal(response.Body, &status); err != nil {
				return nil, fmt.Errorf("ota.status replied no revision: %w", err)
			}
			revision = status.Revision
			return map[string]any{"revision": revision}, nil
		}},
		{Name: command, Run: func(ctx context.Context) (any, error) {
			payload, err := json.Marshal(map[string]string{"version": version})
			if err != nil {
				return nil, err
			}
			response, err := maintenance.Operator.Command(ctx, OperatorRequest{
				Name: command,
				Envelope: operator.Envelope{
					Principal:        "root",
					Role:             operator.RoleRoot,
					Scope:            "global",
					Reason:           reason,
					SemanticKey:      semanticKey,
					ExpectedRevision: &revision,
				},
				Payload: payload,
			})
			if err != nil {
				return nil, err
			}
			if response.Status < 200 || response.Status >= 300 {
				return nil, &BackendRefusal{Status: response.Status, Body: response.Body}
			}
			return json.RawMessage(response.Body), nil
		}},
		{Name: "session.logout_all", Run: func(ctx context.Context) (any, error) {
			return maintenance.logoutAll(ctx, command, version, semanticKey)
		}},
		{Name: "stop backend", Run: func(context.Context) (any, error) { return nil, maintenance.Backend.Stop() }},
		{Name: "start backend open", Run: func(context.Context) (any, error) {
			return nil, StartBackend(maintenance.Backend, maintenance.Tokens, false)
		}},
	}
	return maintenance.Operations.Run(ctx, "maintenance."+command, steps)
}

// logoutAll is the maintenance step that makes every client relogin and take
// MID 2 (I11A_1_PLAN L6 item 3). It runs only after the publish committed.
func (maintenance Maintenance) logoutAll(ctx context.Context, command, version, semanticKey string) (any, error) {
	response, err := maintenance.Operator.Command(ctx, OperatorRequest{
		Name: "session.logout_all",
		Envelope: operator.Envelope{
			Principal:   "root",
			Role:        operator.RoleRoot,
			Scope:       "global",
			Reason:      logoutAllReason(command, version),
			SemanticKey: logoutAllSemanticKey(semanticKey),
		},
		Payload: json.RawMessage(`{}`),
	})
	if err != nil {
		return nil, err
	}
	if response.Status < 200 || response.Status >= 300 {
		return nil, &BackendRefusal{Status: response.Status, Body: response.Body}
	}
	return json.RawMessage(response.Body), nil
}

func logoutAllReason(command, version string) string {
	if command == "ota.withdraw" {
		return "ota withdraw " + version
	}
	return "ota publish " + version
}

// logoutAllSemanticKey derives a stable key from the publish key, so a resend
// replays the logout instead of keying a second command (the bus keys are
// unique per command, 1-128 chars).
func logoutAllSemanticKey(semanticKey string) string {
	digest := sha256.Sum256([]byte("session.logout_all\x00" + semanticKey))
	return hex.EncodeToString(digest[:])
}
