package operatoragent

import "fmt"

const (
	CodeSetupRequired      = "AGENT_SETUP_REQUIRED"
	CodeAlreadySetUp       = "AGENT_ALREADY_SET_UP"
	CodeLoginRefused       = "AGENT_LOGIN_REFUSED"
	CodeUnauthorized       = "AGENT_UNAUTHORIZED"
	CodeForbidden          = "AGENT_FORBIDDEN"
	CodeBodyInvalid        = "AGENT_BODY_INVALID"
	CodeBodyTooLarge       = "AGENT_BODY_TOO_LARGE"
	CodeNotFound           = "AGENT_NOT_FOUND"
	CodeOperationRunning   = "AGENT_OP_RUNNING"
	CodeOperationUnknown   = "AGENT_OP_UNKNOWN"
	CodeBackendUnavailable = "AGENT_BACKEND_UNAVAILABLE"
	CodeBackendRunning     = "AGENT_BACKEND_RUNNING"
	CodeBackendBusy        = "AGENT_BACKEND_BUSY"
	CodeFailed             = "AGENT_FAILED"

	// ota build refusals: one stable code per otabuild refusal kind (L4c).
	CodeVersionExists        = "AGENT_VERSION_EXISTS"
	CodeBuildLaneInvalid     = "AGENT_BUILD_LANE_INVALID"
	CodeBuildVersionInvalid  = "AGENT_BUILD_VERSION_INVALID"
	CodeBuildInputInvalid    = "AGENT_BUILD_INPUT_INVALID"
	CodeBuildEmpty           = "AGENT_BUILD_EMPTY"
	CodeBuildDuplicatePath   = "AGENT_BUILD_DUPLICATE_PATH"
	CodeBuildForbiddenFile   = "AGENT_BUILD_FORBIDDEN_FILE"
	CodeBuildOriginMismatch  = "AGENT_BUILD_ORIGIN_MISMATCH"
	CodeBuildOriginsMissing  = "AGENT_BUILD_ORIGINS_MISSING"
	CodeBuildAbiMismatch     = "AGENT_BUILD_ABI_MISMATCH"
	CodeBuildStockMismatch   = "AGENT_BUILD_STOCK_MISMATCH"
	CodeBuildPatchKind       = "AGENT_BUILD_PATCH_KIND"
	CodeBuildPatchInvalid    = "AGENT_BUILD_PATCH_INVALID"
	CodeBuildPatchAnchor     = "AGENT_BUILD_PATCH_ANCHOR"
	CodeBuildVolumeLimit     = "AGENT_BUILD_VOLUME_LIMIT"
	CodeBuildTargetExists    = "AGENT_BUILD_TARGET_EXISTS"
	CodeBuildCatalogInvalid  = "AGENT_BUILD_CATALOG_INVALID"
	CodeBuildResPathMissing  = "AGENT_BUILD_RES_PATH_MISSING"
	CodeBuildNoExactAssets   = "AGENT_BUILD_NO_EXACT_ASSETS"
	CodeBuildAssetCollision  = "AGENT_BUILD_ASSET_COLLISION"
	CodeBuildConfig          = "AGENT_BUILD_CONFIG"
	CodeBuildIO              = "AGENT_BUILD_IO"
	CodeBuildNoAssetsRelease = "AGENT_BUILD_NO_ASSETS_RELEASE"
	// CodeBuildVersionNotNext refuses a supplied version that is not the lane's
	// next last-component increment (OPERATOR_GUI_V2 G14).
	CodeBuildVersionNotNext = "AGENT_BUILD_VERSION_NOT_NEXT"
	// CodeBuildNoBaseline refuses an automatic next version when the lane has no
	// built or active release to increment.
	CodeBuildNoBaseline = "AGENT_BUILD_NO_BASELINE"
)

// Refusal is a permanent agent refusal: the agent API answers 409 with Code.
type Refusal struct {
	Code    string `json:"error_code"`
	Message string `json:"message"`
}

func (refusal *Refusal) Error() string { return fmt.Sprintf("%s: %s", refusal.Code, refusal.Message) }

// Refuse builds a permanent agent refusal.
func Refuse(code, message string) *Refusal { return &Refusal{Code: code, Message: message} }

// Transient is a temporary agent fault (a read/write defect); the agent API
// answers 503 and the operator may retry (I11A_OPERATOR_COMMANDS_V1 ruling 4).
type Transient struct {
	Code    string `json:"error_code"`
	Message string `json:"message"`
}

func (transient *Transient) Error() string {
	return fmt.Sprintf("%s: %s", transient.Code, transient.Message)
}

// Temporarily builds a temporary agent fault.
func Temporarily(code, message string) *Transient { return &Transient{Code: code, Message: message} }

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
