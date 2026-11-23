package illusion

import (
	"context"
	"encoding/json"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const operatorResetOperation = "operator-reset"

// Player ids are allocated per logical server from server*100000+1.
const operatorResetPlayerIDsPerServer int64 = 100000

type operatorResetFingerprint struct {
	PlayerID int64
	Counter  string
}

// ResetOperatorIllusion restarts the player's Illusion period with the owner's
// own daily rollover, so today's bought count is zero. A player without a row
// is a no-op, never a created row.
func (s Mode) ResetOperatorIllusion(ctx context.Context, admin i5.AdminOperator, playerID identity.PlayerID, key string, op operation.Context) error {
	if err := admin.Validate(); err != nil {
		return err
	}
	if s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil || s.Store == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return d.ErrUnavailable
	}
	if !playerID.Valid() || key == "" || op.StartedAt.IsZero() {
		return d.ErrInvalid
	}
	identity := receipt.Identity{
		OwnerKind:   "player",
		OwnerKey:    strconv.FormatInt(int64(playerID), 10),
		Domain:      "illusion",
		Operation:   operatorResetOperation,
		SemanticKey: admin.ID + ":" + key,
	}
	fingerprint, err := receipt.FingerprintRequest(operatorResetFingerprint{PlayerID: int64(playerID), Counter: "illusion"})
	if err != nil {
		return err
	}
	resolver := timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: identity, Fingerprint: fingerprint}}
	_, _, err = s.Timed.Run(ctx, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), resolver, func(txctx context.Context, scope gen.TimedScope) error {
		if prior, found, err := s.Receipts.FindTx(txctx, scope.Tx, identity); err != nil {
			return err
		} else if found {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identity}
			}
			return nil
		}
		at := scope.Operation.DecisionAt()
		if _, found, err := s.Store.ReadPlayerTx(txctx, scope.Tx, playerID); err != nil {
			return err
		} else if found {
			player, err := s.Store.LockPlayerTx(txctx, scope.Tx, int64(playerID)/operatorResetPlayerIDsPerServer, playerID, at)
			if err != nil {
				return err
			}
			day := modes.Day(at)
			// Marking the stored day stale makes the owner's own rollover
			// restart the period even when it already is today.
			player.Day = day - 1
			player.Reset(day)
			if err = s.Store.SavePlayerTx(txctx, scope.Tx, player, at); err != nil {
				return err
			}
		}
		return s.putOperatorResetReceipt(txctx, scope.Tx, scope.Operation, identity, fingerprint, "illusion")
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
