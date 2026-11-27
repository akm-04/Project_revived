package oneonone

import (
	"context"
	"encoding/json"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const operatorResetOperation = "operator-reset"

type operatorResetFingerprint struct {
	PlayerID int64
	Counter  string
}

// ResetOperatorOneOnOne restarts the player's try period: today's purchases are
// zero and the tries are back to the daily allowance. The owner's own rollover
// computes the fresh period; a player without a row is a no-op.
func (s Service) ResetOperatorOneOnOne(ctx context.Context, admin i5.AdminOperator, playerID identity.PlayerID, key string, op operation.Context) error {
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
		Domain:      "one-on-one",
		Operation:   operatorResetOperation,
		SemanticKey: admin.ID + ":" + key,
	}
	fingerprint, err := receipt.FingerprintRequest(operatorResetFingerprint{PlayerID: int64(playerID), Counter: "one_on_one"})
	if err != nil {
		return err
	}
	resolver := timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: identity, Fingerprint: fingerprint}}
	_, _, err = s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), resolver, func(txctx context.Context, scope gen.TimedScope) error {
		if prior, found, err := s.Receipts.FindTx(txctx, scope.Tx, identity); err != nil {
			return err
		} else if found {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identity}
			}
			return nil
		}
		_, catalog, err := s.catalogTx(txctx, scope.Tx)
		if err != nil {
			return err
		}
		at := scope.Operation.DecisionAt()
		player, _, found, err := s.Store.ReadPlayerTx(txctx, scope.Tx, playerID, true)
		if err != nil {
			return err
		}
		if found {
			next := player
			// Marking the stored try day stale makes the owner's own rollover
			// restart the period even when it already is today.
			next.TriesDay = d.TriesDay(at) - 1
			next = catalog.Rolled(next, at)
			next.StateVersion, next.UpdatedAt = player.StateVersion+1, at
			if err = s.Store.SavePlayerTx(txctx, scope.Tx, next, player.StateVersion, d.Totals{}); err != nil {
				return err
			}
		}
		return s.putOperatorResetReceipt(txctx, scope.Tx, scope.Operation, identity, fingerprint, "one_on_one")
	})
	return err
}

func (s Service) putOperatorResetReceipt(ctx context.Context, t tx.Tx, op gen.TimedOperation, identity receipt.Identity, fingerprint [32]byte, counter string) error {
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
