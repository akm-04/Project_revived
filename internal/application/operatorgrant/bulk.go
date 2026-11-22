package operatorgrant

import (
	"context"
	"errors"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var errMailExpired = errors.New("mail fixed expiry passed before delivery")

const (
	DefaultBatchSize  = 200
	DefaultBatchesRun = 5
	DefaultPending    = 10
)

// Applier settles pending operator bulk targets. Each recipient is a separate
// owner grant with the command key plus recipient as its business key, so a
// retry or a crash after a partial batch never doubles an entitlement; the
// stored counters are the resume cursor.
type Applier struct {
	Runner        tx.Runner
	Operations    operation.Factory
	Store         BulkStore
	Grants        GrantOwner
	Mail          MailOwner
	Catalogue     operatorcatalog.Document
	LineCap       int64
	PolicyVersion string
	BatchSize     int
	BatchesPerRun int
	PendingLimit  int
}

// ApplyPending settles every pending target up to the configured batch budget
// and reports how many targets reached DONE.
func (applier Applier) ApplyPending(ctx context.Context) (int, error) {
	if applier.Runner.DB == nil || applier.Store == nil {
		return 0, errors.New("operator bulk applier dependencies unavailable")
	}
	current, err := applier.Operations.New(policy.Set{})
	if err != nil {
		return 0, err
	}
	var pending []BulkTarget
	_, err = applier.Runner.Run(ctx, current, bulkProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := applier.Store.ListPendingBulkTx(ctx, scope.Tx, applier.pendingLimit())
		if readErr == nil {
			pending = loaded
		}
		return readErr
	})
	if err != nil {
		return 0, err
	}
	finished := 0
	for _, target := range pending {
		if ctx.Err() != nil {
			return finished, ctx.Err()
		}
		done, applyErr := applier.applyOne(ctx, target)
		if applyErr != nil {
			return finished, applyErr
		}
		if done {
			finished++
		}
	}
	return finished, nil
}

func (applier Applier) applyOne(ctx context.Context, target BulkTarget) (bool, error) {
	admin := appi5.AdminOperator{ID: target.Principal, ReasonCode: target.Reason}
	apply, permanent, err := applier.recipientAction(target, admin)
	if err != nil {
		return applier.finish(target, err)
	}
	cursor := target.Processed
	if cursor > len(target.PlayerIDs) {
		cursor = len(target.PlayerIDs)
	}
	op, err := applier.Operations.New(policy.Set{})
	if err != nil {
		return false, err
	}
	applied, refused := target.Applied, target.Refused
	for round := 0; round < applier.batchesPerRun(); round++ {
		if cursor >= len(target.PlayerIDs) {
			if err := applier.save(ctx, target.SemanticKey, cursor, applied, refused, StateDone, "", ""); err != nil {
				return false, err
			}
			return true, nil
		}
		end := min(cursor+applier.batchSize(), len(target.PlayerIDs))
		for ; cursor < end; cursor++ {
			playerID := target.PlayerIDs[cursor]
			recipientErr := apply(ctx, op, identity.PlayerID(playerID), recipientKey(target.SemanticKey, playerID))
			if recipientErr != nil && !permanent(recipientErr) {
				// Never count a transient fault as refused: keep the cursor on this
				// recipient and let the River job retry it with the same key. The
				// cursor write must survive a cancelled operation context.
				if err := applier.save(context.WithoutCancel(ctx), target.SemanticKey, cursor, applied, refused, StatePending, "", recipientErr.Error()); err != nil {
					return false, err
				}
				return false, recipientErr
			}
			if recipientErr != nil {
				refused++
			} else {
				applied++
			}
			if ctx.Err() != nil {
				return false, applier.save(context.WithoutCancel(ctx), target.SemanticKey, cursor, applied, refused, StatePending, "", "")
			}
		}
		state := StatePending
		if cursor >= len(target.PlayerIDs) {
			state = StateDone
		}
		if err := applier.save(ctx, target.SemanticKey, cursor, applied, refused, state, "", ""); err != nil {
			return false, err
		}
		if state == StateDone {
			return true, nil
		}
	}
	return false, nil
}

// recipientAction decodes and validates the frozen payload once and returns
// the per-recipient call plus its permanent-refusal classifier.
func (applier Applier) recipientAction(target BulkTarget, admin appi5.AdminOperator) (func(context.Context, operation.Context, identity.PlayerID, string) error, func(error) bool, error) {
	switch target.ModuleCommand {
	case CommandGrantItems:
		var payload grantPayload
		if err := decodePayload(target.Payload, &payload); err != nil {
			return nil, nil, err
		}
		lines, err := validateLines(applier.Catalogue, applier.LineCap, payload.Lines)
		if err != nil {
			return nil, nil, err
		}
		if applier.Grants == nil {
			return nil, nil, errors.New("operator bulk grant owner unavailable")
		}
		policyVersion := applier.PolicyVersion
		if policyVersion == "" {
			policyVersion = PolicyVersion
		}
		apply := func(ctx context.Context, op operation.Context, playerID identity.PlayerID, key string) error {
			_, err := applier.Grants.AdminGrant(ctx, admin, playerID, key, policyVersion, lines, op)
			return err
		}
		return apply, appi5.IsPermanentGrantRefusal, nil
	case CommandMailSend:
		if applier.Mail == nil {
			return nil, nil, errors.New("operator bulk mail owner unavailable")
		}
		var payload mailPayload
		if err := decodePayload(target.Payload, &payload); err != nil {
			return nil, nil, err
		}
		delivery, err := buildMailDelivery(applier.Catalogue, applier.LineCap, payload, target.CreatedAt)
		if err != nil {
			return nil, nil, err
		}
		apply := func(ctx context.Context, op operation.Context, playerID identity.PlayerID, key string) error {
			if delivery.Expires != nil && !delivery.Expires.After(op.StartedAt.UTC()) {
				return errMailExpired
			}
			_, err := applier.Mail.AdminSendMail(ctx, admin, playerID, mail.Normal, key, delivery.Title, delivery.Sender, delivery.Body, MailPolicyVersion, delivery.Lines, delivery.Expires, delivery.AfterRead, op)
			return err
		}
		return apply, func(err error) bool { return errors.Is(err, errMailExpired) }, nil
	default:
		return nil, nil, errors.New("unsupported operator bulk command")
	}
}

// finish records a target whose frozen payload no longer decodes or validates
// as FAILED with the reason, instead of pretending every recipient refused.
func (applier Applier) finish(target BulkTarget, cause error) (bool, error) {
	if err := applier.save(context.Background(), target.SemanticKey, target.Processed, target.Applied, target.Refused, StateFailed, cause.Error(), ""); err != nil {
		return false, err
	}
	return true, nil
}

func (applier Applier) save(ctx context.Context, semanticKey string, processed, applied, refused int, state, failedReason, lastError string) error {
	current, err := applier.Operations.New(policy.Set{})
	if err != nil {
		return err
	}
	at := time.Now().UTC()
	_, err = applier.Runner.Run(ctx, current, bulkProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3}, nil, func(ctx context.Context, scope tx.Scope) error {
		return applier.Store.SaveBulkProgressTx(ctx, scope.Tx, semanticKey, processed, applied, refused, state, failedReason, lastError, at)
	})
	return err
}

func (applier Applier) batchSize() int {
	if applier.BatchSize <= 0 {
		return DefaultBatchSize
	}
	return applier.BatchSize
}

func (applier Applier) batchesPerRun() int {
	if applier.BatchesPerRun <= 0 {
		return DefaultBatchesRun
	}
	return applier.BatchesPerRun
}

func (applier Applier) pendingLimit() int {
	if applier.PendingLimit <= 0 {
		return DefaultPending
	}
	return applier.PendingLimit
}

func bulkProfile() tx.Profile {
	return tx.Profile{Name: "operator-bulk-apply", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 20 * time.Second, TransactionTimeout: 60 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 120 * time.Second}
}
