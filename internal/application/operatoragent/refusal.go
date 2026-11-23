package operatoragent

import "fmt"

const (
	CodeSetupRequired        = "AGENT_SETUP_REQUIRED"
	CodeAlreadySetUp         = "AGENT_ALREADY_SET_UP"
	CodeLoginRefused         = "AGENT_LOGIN_REFUSED"
	CodeUnauthorized         = "AGENT_UNAUTHORIZED"
	CodePasswordTooShort     = "AGENT_PASSWORD_TOO_SHORT"
	CodePasswordSame         = "AGENT_PASSWORD_SAME"
	CodeForbidden            = "AGENT_FORBIDDEN"
	CodeBodyInvalid          = "AGENT_BODY_INVALID"
	CodeBodyTooLarge         = "AGENT_BODY_TOO_LARGE"
	CodeNotFound             = "AGENT_NOT_FOUND"
	CodeOperationRunning     = "AGENT_OP_RUNNING"
	CodeOperationUnknown     = "AGENT_OP_UNKNOWN"
	CodeBackendUnavailable   = "AGENT_BACKEND_UNAVAILABLE"
	CodeBackendRunning       = "AGENT_BACKEND_RUNNING"
	CodeBackendBusy          = "AGENT_BACKEND_BUSY"
	CodeBackendRestartFailed = "AGENT_BACKEND_RESTART_FAILED"
	CodeFailed               = "AGENT_FAILED"

	// operator settings refusals (G22): a refused value keeps the old one (F1).
	CodeSettingsInvalid     = "AGENT_SETTINGS_INVALID"
	CodeSettingsUnavailable = "AGENT_SETTINGS_UNAVAILABLE"
	CodeServerURLInvalid    = "AGENT_SERVER_URL_INVALID"

	// file browser refusals (G7h): the path picker lists names only, so a
	// missing, unreadable or non-folder path is a permanent refusal.
	CodePathUnreadable = "AGENT_PATH_UNREADABLE"
	CodePathNotFolder  = "AGENT_PATH_NOT_FOLDER"

	// log console refusals (C1-C4).
	CodeLogSourceInvalid      = "AGENT_LOG_SOURCE_INVALID"
	CodeLogLevelInvalid       = "AGENT_LOG_LEVEL_INVALID"
	CodeLogQueryInvalid       = "AGENT_LOG_QUERY_INVALID"
	CodeLogCursorInvalid      = "AGENT_LOG_CURSOR_INVALID"
	CodeLogScopeInvalid       = "AGENT_LOG_SCOPE_INVALID"
	CodeLogToolProtected      = "AGENT_LOG_TOOL_PROTECTED"
	CodeLogPlayerUnknown      = "AGENT_LOG_PLAYER_UNKNOWN"
	CodeLogPlayerAmbiguous    = "AGENT_LOG_PLAYER_AMBIGUOUS"
	CodeLogBackendUnavailable = "AGENT_LOG_BACKEND_UNAVAILABLE"

	// ota build refusals: one stable code per otabuild refusal kind (L4c).
	CodeVersionExists                = "AGENT_VERSION_EXISTS"
	CodeBuildLaneInvalid             = "AGENT_BUILD_LANE_INVALID"
	CodeBuildVersionInvalid          = "AGENT_BUILD_VERSION_INVALID"
	CodeBuildInputInvalid            = "AGENT_BUILD_INPUT_INVALID"
	CodeBuildEmpty                   = "AGENT_BUILD_EMPTY"
	CodeBuildDuplicatePath           = "AGENT_BUILD_DUPLICATE_PATH"
	CodeBuildForbiddenFile           = "AGENT_BUILD_FORBIDDEN_FILE"
	CodeBuildOriginMismatch          = "AGENT_BUILD_ORIGIN_MISMATCH"
	CodeBuildOriginsMissing          = "AGENT_BUILD_ORIGINS_MISSING"
	CodeBuildAbiMismatch             = "AGENT_BUILD_ABI_MISMATCH"
	CodeBuildStockMismatch           = "AGENT_BUILD_STOCK_MISMATCH"
	CodeBuildPatchKind               = "AGENT_BUILD_PATCH_KIND"
	CodeBuildPatchInvalid            = "AGENT_BUILD_PATCH_INVALID"
	CodeBuildPatchAnchor             = "AGENT_BUILD_PATCH_ANCHOR"
	CodeBuildVolumeLimit             = "AGENT_BUILD_VOLUME_LIMIT"
	CodeBuildTargetExists            = "AGENT_BUILD_TARGET_EXISTS"
	CodeBuildCatalogInvalid          = "AGENT_BUILD_CATALOG_INVALID"
	CodeBuildResPathMissing          = "AGENT_BUILD_RES_PATH_MISSING"
	CodeBuildRecoveredResPathMissing = "AGENT_BUILD_RECOVERED_RES_PATH_MISSING"
	CodeBuildNoExactAssets           = "AGENT_BUILD_NO_EXACT_ASSETS"
	CodeBuildAssetCollision          = "AGENT_BUILD_ASSET_COLLISION"
	CodeBuildConfig                  = "AGENT_BUILD_CONFIG"
	CodeBuildIO                      = "AGENT_BUILD_IO"
	CodeBuildNoAssetsRelease         = "AGENT_BUILD_NO_ASSETS_RELEASE"
	// CodeBuildVersionNotNext refuses a supplied version that is not the lane's
	// next last-component increment (OPERATOR_GUI_V2 G14).
	CodeBuildVersionNotNext = "AGENT_BUILD_VERSION_NOT_NEXT"
	// CodeBuildRollbackRequired refuses a number below the lane's active release
	// until the request acknowledges the rollback (T6, owner answer 5).
	CodeBuildRollbackRequired = "AGENT_BUILD_ROLLBACK_REQUIRED"
	// CodeBuildNoBaseline refuses an automatic next version when the lane has no
	// built or active release to increment.
	CodeBuildNoBaseline = "AGENT_BUILD_NO_BASELINE"

	// backup refusals (B1-B7): a permanent backup refusal is 409 with one of
	// these codes; a tool failure is the temporary CodeBackupToolFailed.
	CodeBackupKindInvalid     = "AGENT_BACKUP_KIND_INVALID"
	CodeBackupUnknown         = "AGENT_BACKUP_UNKNOWN"
	CodeBackupDamaged         = "AGENT_BACKUP_DAMAGED"
	CodeBackupNameInvalid     = "AGENT_BACKUP_NAME_INVALID"
	CodeBackupMigrationTooNew = "AGENT_BACKUP_MIGRATION_TOO_NEW"
	CodeBackupDSNMissing      = "AGENT_BACKUP_DSN_MISSING"
	CodeBackupDSNInvalid      = "AGENT_BACKUP_DSN_INVALID"
	CodeBackupToolsMissing    = "AGENT_BACKUP_TOOLS_MISSING"
	CodeBackupRestoreRefused  = "AGENT_BACKUP_RESTORE_REFUSED"
	CodeBackupToolFailed      = "AGENT_BACKUP_TOOL_FAILED"
	CodeBackupFailed          = "AGENT_BACKUP_FAILED"

	// terminal refusals (G42): the shell exists only while the agent listens on
	// loopback and only for an authenticated session (G42).
	CodeTerminalDisabled    = "AGENT_TERMINAL_DISABLED"
	CodeTerminalLimit       = "AGENT_TERMINAL_LIMIT"
	CodeTerminalExists      = "AGENT_TERMINAL_EXISTS"
	CodeTerminalUnknown     = "AGENT_TERMINAL_UNKNOWN"
	CodeTerminalUnsupported = "AGENT_TERMINAL_UNSUPPORTED"
	CodeTerminalStartFailed = "AGENT_TERMINAL_START_FAILED"
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
