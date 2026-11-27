// Package operatorgrant is the operator entitlement module
// (I11A_OPERATOR_COMMANDS_V1 M1/M2/M4/M8/M11, ruling 5): catalogue-checked
// grant.items and mail.send, the redeem campaign commands, the shared bulk
// target core, and the resumable per-recipient settlement job.
package operatorgrant

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"sort"
	"strconv"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	CommandGrantItems = "grant.items"
	BulkShowRead      = "operator.bulk.show"

	CodeGrantNotGrantable = "OPERATOR_GRANT_NOT_GRANTABLE"
	CodeGrantAmount       = "OPERATOR_GRANT_AMOUNT"
	CodeGrantLines        = "OPERATOR_GRANT_LINES"
	CodeGrantTarget       = "OPERATOR_GRANT_TARGET"
	CodeBulkUnknown       = "OPERATOR_BULK_UNKNOWN"

	DefaultLineCap       int64 = 1_000_000
	MaxLineCap           int64 = 2_000_000_000
	MaxLines                   = 50
	InlineRecipientLimit       = 50
	MaxRecipients              = 100_000

	PolicyVersion = "operator-grant-v1"
)

const (
	StatePending = "PENDING"
	StateDone    = "DONE"
	StateFailed  = "FAILED"
)

// ValidBulkState keeps the store and the migration's CHECK in step.
func ValidBulkState(state string) bool {
	return state == StatePending || state == StateDone || state == StateFailed
}

// BulkTarget is one operator_bulk_targets row: the recipient set frozen at
// submit and the progress of the settlement job.
type BulkTarget struct {
	SemanticKey     string
	ModuleCommand   string
	Selector        string
	PlayerIDs       []int64
	PlayerCount     int
	PlayerIDsSHA256 string
	Payload         json.RawMessage
	Principal       string
	Reason          string
	Processed       int
	Applied         int
	Refused         int
	State           string
	FailedReason    string
	LastError       string
	CreatedAt       time.Time
	UpdatedAt       time.Time
	FinishedAt      *time.Time
}

// BulkStore is the operator_bulk_targets port, implemented by the operator
// adapter.
type BulkStore interface {
	InsertBulkTx(context.Context, tx.Tx, BulkTarget) error
	ReadBulkTx(context.Context, tx.Queryer, string) (*BulkTarget, error)
	ListPendingBulkTx(context.Context, tx.Queryer, int) ([]BulkTarget, error)
	SaveBulkProgressTx(context.Context, tx.Tx, string, int, int, int, string, string, string, time.Time) error
}

// GrantOwner is the i5 admin settlement command: the job form opens its own
// transaction, the inline form reuses the bus transaction.
type GrantOwner interface {
	AdminGrant(context.Context, appi5.AdminOperator, identity.PlayerID, string, string, []grant.Line, operation.Context) (appi5.GrantResult, error)
	AdminGrantTx(context.Context, tx.Tx, appi5.AdminOperator, identity.PlayerID, string, string, []grant.Line, operation.Context) (appi5.GrantResult, error)
}

// Commands applies grant.items and operator.bulk.show on the operator bus.
type Commands struct {
	Catalogue operatorcatalog.Document
	Store     BulkStore
	Directory playerdirectory.OperatorRecipients
	Grants    GrantOwner
	LineCap   int64
}

type linePayload struct {
	ID     string `json:"id"`
	Amount int64  `json:"amount"`
}

type targetPayload struct {
	PlayerIDs []int64 `json:"player_ids,omitempty"`
	ServerID  int64   `json:"server_id,omitempty"`
	Global    bool    `json:"global,omitempty"`
}

type grantPayload struct {
	Target targetPayload `json:"target"`
	Lines  []linePayload `json:"lines"`
}

// GrantResult is the grant.items reply.
type GrantResult struct {
	Bulk        bool               `json:"bulk"`
	SemanticKey string             `json:"semantic_key"`
	PlayerCount int                `json:"player_count"`
	Applied     int                `json:"applied"`
	Refused     int                `json:"refused"`
	State       string             `json:"state"`
	Failures    []RecipientFailure `json:"failures,omitempty"`
}

// RecipientFailure is one bounded per-recipient failure line.
type RecipientFailure struct {
	PlayerID int64  `json:"player_id"`
	Error    string `json:"error"`
}

const maxReportedFailures = 20

// BulkProgress is the operator.bulk.show reply.
type BulkProgress struct {
	SemanticKey   string     `json:"semantic_key"`
	ModuleCommand string     `json:"module_command"`
	Selector      string     `json:"selector"`
	PlayerCount   int        `json:"player_count"`
	Processed     int        `json:"processed"`
	Applied       int        `json:"applied"`
	Refused       int        `json:"refused"`
	State         string     `json:"state"`
	FailedReason  string     `json:"failed_reason,omitempty"`
	LastError     string     `json:"last_error,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	FinishedAt    *time.Time `json:"finished_at"`
}

func (commands Commands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{CommandGrantItems: commands.grantHandler}
}

func (commands Commands) grantHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload grantPayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(operator.CodePayloadInvalid, err.Error(), nil)
	}
	lines, err := commands.validateLines(payload.Lines)
	if err != nil {
		return nil, err
	}
	selector, recipients, err := commands.resolveTarget(ctx, scope.Tx, payload.Target)
	if err != nil {
		return nil, err
	}
	if len(recipients) == 0 {
		return nil, operator.Refuse(CodeGrantTarget, "the target matches no players", nil)
	}
	admin := appi5.AdminOperator{ID: command.Envelope.Principal, ReasonCode: command.Envelope.Reason}
	if len(recipients) <= InlineRecipientLimit {
		return commands.applyInline(ctx, scope, admin, command.Envelope.SemanticKey, recipients, lines)
	}
	if commands.Store == nil {
		return nil, operator.ErrUnavailable
	}
	target := BulkTarget{
		SemanticKey:     command.Envelope.SemanticKey,
		ModuleCommand:   command.ModuleCommand,
		Selector:        selector,
		PlayerIDs:       recipients,
		PlayerCount:     len(recipients),
		PlayerIDsSHA256: sha256IDs(recipients),
		Payload:         append(json.RawMessage(nil), command.Payload...),
		Principal:       command.Envelope.Principal,
		Reason:          command.Envelope.Reason,
		State:           StatePending,
		CreatedAt:       scope.Operation.StartedAt.UTC(),
		UpdatedAt:       scope.Operation.StartedAt.UTC(),
	}
	if err := commands.Store.InsertBulkTx(ctx, scope.Tx, target); err != nil {
		return nil, err
	}
	return GrantResult{Bulk: true, SemanticKey: target.SemanticKey, PlayerCount: target.PlayerCount, State: StatePending}, nil
}

// BulkReadService answers operator.bulk.show as a bounded read: it runs no
// command, so it writes no audit row.
type BulkReadService struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      BulkStore
}

// Show reads one frozen target's progress.
func (service BulkReadService) Show(ctx context.Context, semanticKey string) (BulkProgress, error) {
	if service.Store == nil || service.Runner.DB == nil {
		return BulkProgress{}, operator.ErrUnavailable
	}
	if semanticKey == "" {
		return BulkProgress{}, operator.Refuse(operator.CodeReadInvalid, "semantic_key is required", nil)
	}
	var target *BulkTarget
	current, err := service.Operations.New(policy.Set{})
	if err != nil {
		return BulkProgress{}, err
	}
	_, err = service.Runner.Run(ctx, current, readBulkProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		found, readErr := service.Store.ReadBulkTx(ctx, scope.Tx, semanticKey)
		if readErr == nil {
			target = found
		}
		return readErr
	})
	if err != nil {
		return BulkProgress{}, err
	}
	if target == nil {
		return BulkProgress{}, operator.Refuse(CodeBulkUnknown, "the bulk target does not exist", map[string]string{"semantic_key": semanticKey})
	}
	return progressOf(*target), nil
}

func progressOf(target BulkTarget) BulkProgress {
	return BulkProgress{SemanticKey: target.SemanticKey, ModuleCommand: target.ModuleCommand, Selector: target.Selector, PlayerCount: target.PlayerCount, Processed: target.Processed, Applied: target.Applied, Refused: target.Refused, State: target.State, FailedReason: target.FailedReason, LastError: target.LastError, CreatedAt: target.CreatedAt, FinishedAt: target.FinishedAt}
}

func readBulkProfile() tx.Profile {
	return tx.Profile{Name: "operator-bulk-read-v1", AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 1500 * time.Millisecond, TransactionTimeout: 2 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 3 * time.Second}
}

func (commands Commands) applyInline(ctx context.Context, scope tx.Scope, admin appi5.AdminOperator, commandKey string, recipients []int64, lines []grant.Line) (GrantResult, error) {
	if commands.Grants == nil {
		return GrantResult{}, operator.ErrUnavailable
	}
	result := GrantResult{SemanticKey: commandKey, PlayerCount: len(recipients), State: operator.StateApplied}
	for index, rawID := range recipients {
		savepoint := "operator_grant_recipient_" + strconv.Itoa(index)
		if _, err := scope.Tx.Exec(ctx, "SAVEPOINT "+savepoint); err != nil {
			return GrantResult{}, err
		}
		_, grantErr := commands.Grants.AdminGrantTx(ctx, scope.Tx, admin, identity.PlayerID(rawID), recipientKey(commandKey, rawID), PolicyVersion, lines, scope.Operation)
		if grantErr == nil {
			if _, err := scope.Tx.Exec(ctx, "RELEASE SAVEPOINT "+savepoint); err != nil {
				return GrantResult{}, err
			}
			result.Applied++
			continue
		}
		if !appi5.IsPermanentGrantRefusal(grantErr) {
			// The bus rolls the whole command back and a resend with the same
			// key retries every recipient; a transient fault must not become a
			// permanent refusal.
			return GrantResult{}, grantErr
		}
		// A permanent refusal can follow earlier lines of the same recipient;
		// undo them so the recipient fails whole rather than partially.
		if _, err := scope.Tx.Exec(ctx, "ROLLBACK TO SAVEPOINT "+savepoint); err != nil {
			return GrantResult{}, err
		}
		if _, err := scope.Tx.Exec(ctx, "RELEASE SAVEPOINT "+savepoint); err != nil {
			return GrantResult{}, err
		}
		result.Refused++
		if len(result.Failures) < maxReportedFailures {
			result.Failures = append(result.Failures, RecipientFailure{PlayerID: rawID, Error: grantErr.Error()})
		}
	}
	return result, nil
}

func (commands Commands) validateLines(lines []linePayload) ([]grant.Line, error) {
	return validateLines(commands.Catalogue, commands.LineCap, lines)
}

func validateLines(catalogue operatorcatalog.Document, lineCap int64, lines []linePayload) ([]grant.Line, error) {
	if len(lines) == 0 || len(lines) > MaxLines {
		return nil, operator.Refuse(CodeGrantLines, "lines must hold one to fifty entries", map[string]int{"limit": MaxLines})
	}
	capAmount := lineCap
	if capAmount == 0 {
		capAmount = DefaultLineCap
	}
	out := make([]grant.Line, 0, len(lines))
	for index, line := range lines {
		if line.Amount <= 0 || line.Amount > capAmount {
			return nil, operator.Refuse(CodeGrantAmount, "a line amount is outside the allowed range", map[string]any{"line": index, "min": 1, "max": capAmount})
		}
		grantLine, entry, found := catalogue.GrantLine(line.ID, line.Amount)
		if !found {
			detail := map[string]any{"line": index, "id": line.ID}
			if entry != nil {
				detail["reason"] = entry.Reason
			}
			return nil, operator.Refuse(CodeGrantNotGrantable, "the id is unknown or the backend cannot grant it", detail)
		}
		out = append(out, grantLine)
	}
	return out, nil
}

func (commands Commands) resolveTarget(ctx context.Context, q tx.Queryer, target targetPayload) (string, []int64, error) {
	return resolveTarget(ctx, q, commands.Directory, target)
}

func resolveTarget(ctx context.Context, q tx.Queryer, directory playerdirectory.OperatorRecipients, target targetPayload) (string, []int64, error) {
	selector, err := target.selector()
	if err != nil {
		return "", nil, operator.Refuse(CodeGrantTarget, err.Error(), nil)
	}
	var recipients []int64
	switch selector {
	case "players":
		if len(target.PlayerIDs) == 0 || len(target.PlayerIDs) > MaxRecipients {
			return "", nil, operator.Refuse(CodeGrantTarget, "player_ids must hold one to one hundred thousand ids", nil)
		}
		recipients = target.PlayerIDs
	case "server":
		if directory == nil {
			return "", nil, operator.ErrUnavailable
		}
		ids, readErr := directory.ServerPlayerIDsTx(ctx, q, identity.LogicalServerID(target.ServerID), MaxRecipients+1)
		if readErr != nil {
			return "", nil, readErr
		}
		recipients = rawIDs(ids)
	case "global":
		if directory == nil {
			return "", nil, operator.ErrUnavailable
		}
		ids, readErr := directory.AllPlayerIDsTx(ctx, q, MaxRecipients+1)
		if readErr != nil {
			return "", nil, readErr
		}
		recipients = rawIDs(ids)
	}
	if len(recipients) > MaxRecipients {
		return "", nil, operator.Refuse(CodeGrantTarget, "the target exceeds one hundred thousand players", nil)
	}
	sorted, err := canonicalIDs(recipients)
	if err != nil {
		return "", nil, operator.Refuse(CodeGrantTarget, err.Error(), nil)
	}
	return selector, sorted, nil
}

func (target targetPayload) selector() (string, error) {
	count := 0
	selector := ""
	if len(target.PlayerIDs) > 0 {
		selector, count = "players", count+1
	}
	if target.ServerID != 0 {
		selector, count = "server", count+1
	}
	if target.Global {
		selector, count = "global", count+1
	}
	if count != 1 {
		return "", errors.New("exactly one of player_ids, server_id and global is required")
	}
	if selector == "server" && target.ServerID <= 0 {
		return "", errors.New("server_id must be a positive id")
	}
	return selector, nil
}

func canonicalIDs(ids []int64) ([]int64, error) {
	seen := make(map[int64]struct{}, len(ids))
	out := make([]int64, 0, len(ids))
	for _, id := range ids {
		player := identity.PlayerID(id)
		if !player.Valid() {
			return nil, errors.New("a player id is not valid")
		}
		if _, duplicate := seen[id]; duplicate {
			continue
		}
		seen[id] = struct{}{}
		out = append(out, id)
	}
	sort.Slice(out, func(i, j int) bool { return out[i] < out[j] })
	return out, nil
}

func rawIDs(ids []identity.PlayerID) []int64 {
	out := make([]int64, 0, len(ids))
	for _, id := range ids {
		out = append(out, int64(id))
	}
	return out
}

func sha256IDs(ids []int64) string {
	encoded := make([]byte, 0, len(ids)*12)
	for _, id := range ids {
		encoded = strconv.AppendInt(encoded, id, 10)
		encoded = append(encoded, ',')
	}
	digest := sha256.Sum256(encoded)
	return hex.EncodeToString(digest[:])
}

func recipientKey(commandKey string, playerID int64) string {
	return commandKey + ":" + strconv.FormatInt(playerID, 10)
}

func decodePayload(payload json.RawMessage, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); err == nil {
		return errors.New("trailing data after the payload")
	}
	return nil
}

// LineCapFromEnvironment validates the tunable per-line grant cap.
func LineCapFromEnvironment(value string) (int64, error) {
	if value == "" {
		return DefaultLineCap, nil
	}
	cap, err := strconv.ParseInt(value, 10, 64)
	if err != nil || cap < 1 || cap > MaxLineCap {
		return 0, errors.New("GXB_OPERATOR_GRANT_LINE_CAP must be between 1 and 2000000000")
	}
	return cap, nil
}
