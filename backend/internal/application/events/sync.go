package events

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domainevents "gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Sync outcomes of one shipped definition file (EA-13).
const (
	SyncDeployed  = "deployed"
	SyncUnchanged = "unchanged"
	SyncConflict  = "SYNC_CONFLICT"
	SyncInvalid   = "invalid"
)

// SyncSystemPrincipal, SyncSystemReason attribute a shipped-file deploy.
const (
	SyncSystemPrincipal = "system"
	SyncSystemReason    = "shipped definition sync"
)

// DefinitionFile is one shipped event definition file (EA-13).
type DefinitionFile struct {
	Name string
	Body []byte
}

// SyncResult is one definition file's sync outcome.
type SyncResult struct {
	File       string `json:"file"`
	ActivityID int64  `json:"activity_id,omitempty"`
	Revision   int64  `json:"revision,omitempty"`
	Outcome    string `json:"outcome"`
	Error      string `json:"error,omitempty"`
}

type reloadResult struct {
	Definitions []SyncResult `json:"definitions"`
}

func (commands Commands) reloadHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	results, err := commands.SyncFiles(ctx, scope.Tx, scope.Operation.StartedAt.UTC(), commands.Shipped)
	if err != nil {
		return nil, err
	}
	return reloadResult{Definitions: results}, nil
}

// SyncFiles deploys every file through the deploy path in the caller's
// transaction. A file's refusal is data (SYNC_CONFLICT or invalid); an
// infrastructure fault aborts so the transaction rolls back.
func (commands Commands) SyncFiles(ctx context.Context, transaction tx.Tx, at time.Time, files []DefinitionFile) ([]SyncResult, error) {
	if transaction == nil || at.IsZero() || commands.Store == nil || commands.Audit == nil || commands.Content == nil {
		return nil, ErrUnavailable
	}
	if len(files) == 0 {
		return nil, operator.Refuse(CodeDefinitionsNotComposed, "no shipped event definition files are composed", nil)
	}
	contentRevision, err := commands.Content.ActiveRevision(ctx, transaction)
	if err != nil {
		return nil, err
	}
	results := make([]SyncResult, 0, len(files))
	for _, file := range files {
		result, err := commands.syncFile(ctx, transaction, at, contentRevision, file)
		if err != nil {
			return nil, err
		}
		results = append(results, result)
	}
	return results, nil
}

func (commands Commands) syncFile(ctx context.Context, transaction tx.Tx, at time.Time, contentRevision string, file DefinitionFile) (SyncResult, error) {
	definition, err := domainevents.ParseDefinition(file.Body)
	if err != nil {
		return SyncResult{File: file.Name, Outcome: SyncInvalid, Error: err.Error()}, nil
	}
	result := SyncResult{File: file.Name, ActivityID: definition.ActivityID, Revision: definition.Revision}
	shippedSHA := fileDigest(file.Body)
	command, err := operator.NewCommand("events.definition.deploy", operator.Envelope{
		Principal: SyncSystemPrincipal, Role: operator.RoleRoot, Scope: "global", Reason: SyncSystemReason,
		SemanticKey: syncCommandKey(definition, shippedSHA, contentRevision),
	}, file.Body)
	if err != nil {
		result.Outcome, result.Error = SyncInvalid, err.Error()
		return result, nil
	}
	record, err := commands.Audit.ClaimTx(ctx, transaction, command, at)
	if err != nil {
		return SyncResult{}, err
	}
	if record != nil {
		if record.ModuleCommand != command.ModuleCommand || record.PayloadSHA256 != command.PayloadSHA256 {
			result.Outcome = SyncInvalid
			result.Error = operator.CodeKeyReused + ": this semantic key was used with another command or payload"
			return result, nil
		}
		switch record.State {
		case operator.StateApplied:
			if err := commands.Store.ClearDefinitionConflictTx(ctx, transaction, definition.ActivityID, definition.Revision); err != nil {
				return SyncResult{}, err
			}
			result.Outcome = SyncUnchanged
			return result, nil
		case operator.StateRefused:
			return commands.refusedSyncResult(ctx, transaction, at, result, shippedSHA, storedRefusal(record))
		case operator.StateFailed:
			if err := commands.Audit.RetryFailedTx(ctx, transaction, record.SemanticKey); err != nil {
				return SyncResult{}, err
			}
		}
	}
	deployed, err := commands.Deploy(ctx, transaction, command.Envelope.SemanticKey, definition, at)
	if err != nil {
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) {
			return SyncResult{}, err
		}
		finishErr := commands.finishSystemCommand(ctx, transaction, command.Envelope.SemanticKey, operator.StateRefused, refusal, at)
		if finishErr != nil {
			return SyncResult{}, finishErr
		}
		return commands.refusedSyncResult(ctx, transaction, at, result, shippedSHA, refusal)
	}
	if err := commands.finishSystemCommand(ctx, transaction, command.Envelope.SemanticKey, operator.StateApplied, deployed, at); err != nil {
		return SyncResult{}, err
	}
	if err := commands.Store.ClearDefinitionConflictTx(ctx, transaction, definition.ActivityID, definition.Revision); err != nil {
		return SyncResult{}, err
	}
	if deployed.Created {
		result.Outcome = SyncDeployed
		return result, nil
	}
	result.Outcome = SyncUnchanged
	return result, nil
}

func (commands Commands) refusedSyncResult(ctx context.Context, transaction tx.Tx, at time.Time, result SyncResult, shippedSHA string, refusal *operator.Refusal) (SyncResult, error) {
	if refusal != nil && refusal.Code == CodeRevisionExists {
		if err := commands.Store.RecordDefinitionConflictTx(ctx, transaction, result.ActivityID, result.Revision, shippedSHA, at); err != nil {
			return SyncResult{}, err
		}
		result.Outcome = SyncConflict
		return result, nil
	}
	result.Outcome = SyncInvalid
	if refusal != nil {
		result.Error = refusal.Code + ": " + refusal.Message
	}
	return result, nil
}

func (commands Commands) finishSystemCommand(ctx context.Context, transaction tx.Tx, semanticKey, state string, result any, at time.Time) error {
	encoded, err := json.Marshal(result)
	if err != nil {
		return err
	}
	return commands.Audit.FinishTx(ctx, transaction, semanticKey, state, encoded, at)
}

func storedRefusal(record *operator.Record) *operator.Refusal {
	var refusal operator.Refusal
	if err := json.Unmarshal(record.Result, &refusal); err != nil {
		return nil
	}
	return &refusal
}

func fileDigest(body []byte) string {
	digest := sha256.Sum256(body)
	return hex.EncodeToString(digest[:])
}

// syncContentRevisionLimit keeps the key inside the 128-character envelope limit
// (I11A_OPERATOR_COMMANDS_V1 ruling 2); the content revision itself is a 64-char sha.
const syncContentRevisionLimit = 16

func syncCommandKey(definition domainevents.Definition, shippedSHA, contentRevision string) string {
	return fmt.Sprintf("sync:%d:%d:%s:%s", definition.ActivityID, definition.Revision, shippedSHA, shortContentRevision(contentRevision))
}

func shortContentRevision(revision string) string {
	if len(revision) <= syncContentRevisionLimit {
		return revision
	}
	return revision[:syncContentRevisionLimit]
}

// SyncShipped deploys the embedded definition files at API start in one owner
// transaction. The caller logs the non-unchanged results and continues.
func (commands Commands) SyncShipped(ctx context.Context, runner tx.Runner, operations operation.Factory) ([]SyncResult, error) {
	if commands.Store == nil || commands.Audit == nil || runner.DB == nil || operations.Clock == nil {
		return nil, ErrUnavailable
	}
	current, err := operations.New(policy.Set{})
	if err != nil {
		return nil, err
	}
	var results []SyncResult
	_, err = runner.Run(ctx, current, syncProfile("events-definition-sync"), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, syncErr := commands.SyncFiles(ctx, scope.Tx, current.StartedAt.UTC(), commands.Shipped)
		if syncErr == nil {
			results = loaded
		}
		return syncErr
	})
	return results, err
}

func syncProfile(name string) tx.Profile {
	return tx.Profile{Name: name, AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 20 * time.Second, TransactionTimeout: 60 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 120 * time.Second}
}
