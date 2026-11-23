package summon

import (
	"context"
	"encoding/json"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const operatorResetOperation = "operator-reset"

type operatorResetFingerprint struct {
	PlayerID int64
	Counter  string
}

// ResetOperatorSummonFree restarts the free Vending period: today's free mana
// summons are refilled and the crystal free timer is ready now. A player
// without a row is a no-op, never a created row.
func (s Mode) ResetOperatorSummonFree(ctx context.Context, admin i5.AdminOperator, playerID identity.PlayerID, key string, op operation.Context) error {
	if err := admin.Validate(); err != nil {
		return err
	}
	if s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil || s.Store == nil || s.Content == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return d.ErrUnavailable
	}
	if !playerID.Valid() || key == "" || op.StartedAt.IsZero() {
		return d.ErrInvalid
	}
	identity := receipt.Identity{
		OwnerKind:   "player",
		OwnerKey:    strconv.FormatInt(int64(playerID), 10),
		Domain:      "summon",
		Operation:   operatorResetOperation,
		SemanticKey: admin.ID + ":" + key,
	}
	fingerprint, err := receipt.FingerprintRequest(operatorResetFingerprint{PlayerID: int64(playerID), Counter: "summon_free"})
	if err != nil {
		return err
	}
	resolver := timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: identity, Fingerprint: fingerprint}}
	_, _, err = s.Timed.Run(ctx, op, ModeProfile(), tx.Options{Isolation: tx.Serializable}, retry(), resolver, func(txctx context.Context, scope gen.TimedScope) error {
		if prior, found, err := s.Receipts.FindTx(txctx, scope.Tx, identity); err != nil {
			return err
		} else if found {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identity}
			}
			return nil
		}
		revision, err := s.Content.ActiveRevision(txctx, scope.Tx)
		if err != nil {
			return err
		}
		catalog, err := s.catalog(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		at := scope.Operation.DecisionAt()
		state, found, err := s.Store.ReadTx(txctx, scope.Tx, playerID)
		if err != nil {
			return err
		}
		if found {
			locked, err := s.Store.LockTx(txctx, scope.Tx, playerID, state, at)
			if err != nil {
				return err
			}
			day := modes.Day(at)
			next := locked
			// Marking the stored day stale makes the owner's own refresh refill
			// the free count even when the day already matches.
			next.ManaFreeDay = day - 1
			next = catalog.Refresh(next, day)
			next.CrystalFreeTime = 0
			if err = s.Store.SaveTx(txctx, scope.Tx, playerID, next, at); err != nil {
				return err
			}
		}
		return s.putOperatorResetReceipt(txctx, scope.Tx, scope.Operation, identity, fingerprint, "summon_free")
	})
	return err
}

func (s Mode) putOperatorResetReceipt(ctx context.Context, t tx.Tx, op gen.TimedOperation, identity receipt.Identity, fingerprint [32]byte, counter string) error {
	payload, err := json.Marshal(map[string]string{"counter": counter})
	if err != nil {
		return err
	}
	created, err := receipt.New(op.Operation(), identity, "I11A_OPERATOR_RESET", "gxb.operator.reset-counter.v1", payload, fingerprint)
	if err != nil {
		return err
	}
	created.PolicyVersion = "operator-reset-v1"
	_, err = s.Receipts.PutTx(ctx, t, created)
	return err
}
