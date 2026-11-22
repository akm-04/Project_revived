package operatoragent

import "fmt"

const (
	CodeSetupRequired      = "AGENT_SETUP_REQUIRED"
	CodeAlreadySetUp       = "AGENT_ALREADY_SET_UP"
	CodeLoginRefused       = "AGENT_LOGIN_REFUSED"
	CodeUnauthorized       = "AGENT_UNAUTHORIZED"
	CodeForbidden          = "AGENT_FORBIDDEN"
	CodeBodyInvalid        = "AGENT_BODY_INVALID"
	CodeNotFound           = "AGENT_NOT_FOUND"
	CodeOperationRunning   = "AGENT_OP_RUNNING"
	CodeOperationUnknown   = "AGENT_OP_UNKNOWN"
	CodeBackendUnavailable = "AGENT_BACKEND_UNAVAILABLE"
	CodeBackendRunning     = "AGENT_BACKEND_RUNNING"
	CodeBackendBusy        = "AGENT_BACKEND_BUSY"
	CodeFailed             = "AGENT_FAILED"
)

// Refusal is a permanent agent refusal: the agent API answers 409 with Code.
type Refusal struct {
	Code    string `json:"error_code"`
	Message string `json:"message"`
}

func (refusal *Refusal) Error() string { return fmt.Sprintf("%s: %s", refusal.Code, refusal.Message) }

// Refuse builds a permanent agent refusal.
func Refuse(code, message string) *Refusal { return &Refusal{Code: code, Message: message} }

// BackendRefusal is a backend operator-API answer the agent passes through
// unchanged (I11A_OPERATOR_COMMANDS_V1 ruling 4: a refusal is 409 with its own
// body; the agent adds no meaning of its own).
type BackendRefusal struct {
	Status int
	Body   []byte
}

func (refusal *BackendRefusal) Error() string {
	return fmt.Sprintf("backend answered HTTP %d: %s", refusal.Status, string(refusal.Body))
}
