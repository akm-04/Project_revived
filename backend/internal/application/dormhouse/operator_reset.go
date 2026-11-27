package dormhouse

import (
	"context"
	"encoding/json"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const operatorResetOperation = "operator-reset"

type operatorResetFingerprint struct {
	PlayerID int64
	Counter  string
}

type operatorResetTimedReceipt struct{ receipt.Resolver }

func (r operatorResetTimedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

// ResetOperatorDormGlue restarts the player's glue-purchase day. The owner reads
// a stale stored day as zero purchases and its schema keeps a count of at least
// one, so the reset marks the stored day stale; a missing row is a no-op.
func (s Service) ResetOperatorDormGlue(ctx context.Context, admin i5.AdminOperator, playerID identity.PlayerID, key string, op operation.Context) error {
	if err := admin.Validate(); err != nil {
		return err
	}
	if s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil || s.GluePurchases == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return ErrUnavailable
	}
	if !playerID.Valid() || key == "" || op.StartedAt.IsZero() {
		return dorm.ErrInvalidFacts
	}
	identity := receipt.Identity{
		OwnerKind:   "player",
		OwnerKey:    strconv.FormatInt(int64(playerID), 10),
		Domain:      "dorm-house",
		Operation:   operatorResetOperation,
		SemanticKey: admin.ID + ":" + key,
	}
	fingerprint, err := receipt.FingerprintRequest(operatorResetFingerprint{PlayerID: int64(playerID), Counter: "dorm_glue"})
	if err != nil {
		return err
	}
	resolver := operatorResetTimedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: identity, Fingerprint: fingerprint}}
	_, _, err = s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope gen.TimedScope) error {
		if prior, found, err := s.Receipts.FindTx(txctx, scope.Tx, identity); err != nil {
			return err
		} else if found {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identity}
			}
			return nil
		}
		at := scope.Operation.DecisionAt()
		stored, exists, err := s.GluePurchases.ReadGluePurchasesTx(txctx, scope.Tx, playerID)
		if err != nil {
			return err
		}
		if exists && stored.GameDay >= modes.Day(at) {
			next := stored
			next.GameDay = modes.Day(at) - 1
			next.StateVersion, next.UpdatedAt = stored.StateVersion+1, at
			if err = s.GluePurchases.SaveGluePurchasesTx(txctx, scope.Tx, next, stored.StateVersion); err != nil {
				return err
			}
		}
		return s.putOperatorResetReceipt(txctx, scope.Tx, scope.Operation, identity, fingerprint, "dorm_glue")
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
