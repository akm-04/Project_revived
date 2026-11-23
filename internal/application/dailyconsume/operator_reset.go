package dailyconsume

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	operatorResetDailyBuysDomain    = "daily-consumption"
	operatorResetDailyBuysOperation = "operator-reset"
	operatorResetPolicyVersion      = "operator-reset-v1"
)

type operatorResetFingerprint struct {
	PlayerID int64
	Counter  string
}

// ResetOperatorDailyBuys clears every daily consumption counter of the current
// game day, including ids 1..10 and the named buy counters. The row lock is the
// version guard; a player without a counter row is a no-op, never a created row.
func (s Service) ResetOperatorDailyBuys(ctx context.Context, admin i5.AdminOperator, playerID identity.PlayerID, key string, op operation.Context) error {
	if err := admin.Validate(); err != nil {
		return err
	}
	if s.Store == nil || s.Runner.DB == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return errors.New("daily consumption: operator reset unavailable")
	}
	if !playerID.Valid() || key == "" || op.StartedAt.IsZero() {
		return errors.New("daily consumption: invalid operator reset")
	}
	receiptIdentity := receipt.Identity{
		OwnerKind:   "player",
		OwnerKey:    strconv.FormatInt(int64(playerID), 10),
		Domain:      operatorResetDailyBuysDomain,
		Operation:   operatorResetDailyBuysOperation,
		SemanticKey: admin.ID + ":" + key,
	}
	fingerprint, err := receipt.FingerprintRequest(operatorResetFingerprint{PlayerID: int64(playerID), Counter: "daily_buys"})
	if err != nil {
		return err
	}
	now := op.StartedAt.UTC()
	day := modes.Day(now)
	resolver := receipt.Resolver{Reader: s.ReceiptRead, Identity: receiptIdentity, Fingerprint: fingerprint}
	_, err = s.Runner.Run(ctx, op, operatorResetProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, resolver, func(txctx context.Context, scope tx.Scope) error {
		if prior, found, err := s.Receipts.FindTx(txctx, scope.Tx, receiptIdentity); err != nil {
			return err
		} else if found {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: receiptIdentity}
			}
			return nil
		}
		counts, err := s.Store.ReadTx(txctx, scope.Tx, playerID)
		if err != nil {
			return err
		}
		if len(counts) > 0 {
			locked, err := s.Store.LockTx(txctx, scope.Tx, playerID, now)
			if err != nil {
				return err
			}
			changed := false
			for counterID, counter := range locked {
				if counter.Period > day {
					continue
				}
				next := modes.Counter{Period: day}
				if next == counter {
					continue
				}
				locked[counterID] = next
				changed = true
			}
			if changed {
				if err = s.Store.SaveTx(txctx, scope.Tx, playerID, locked, now); err != nil {
					return err
				}
			}
		}
		created, err := receipt.New(op, receiptIdentity, "I11A_OPERATOR_RESET", "gxb.operator.reset-counter.v1", json.RawMessage(`{"counter":"daily_buys"}`), fingerprint)
		if err != nil {
			return err
		}
		created.PolicyVersion = operatorResetPolicyVersion
		_, err = s.Receipts.PutTx(txctx, scope.Tx, created)
		return err
	})
	return err
}

func operatorResetProfile() tx.Profile {
	return tx.Profile{Name: "operator-reset-daily-buys", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 20 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 30 * time.Second}
}
