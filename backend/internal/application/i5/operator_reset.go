package i5

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	operatorResetDomain        = "i5"
	operatorResetOccultTickets = "operator-reset-occult-tickets"
	operatorResetSkillPoints   = "operator-reset-skill-points"
	operatorResetSchema        = "gxb.operator.reset-counter.v1"
	operatorResetPolicyVersion = "operator-reset-v1"
)

type operatorResetFingerprint struct {
	PlayerID int64
	Counter  string
}

// ResetOperatorOccultTickets sets the ticket balance to the domain cap and
// keeps the energy progress toward the next ticket. A player without a ticket
// row is a no-op, never a created row.
func (s Service) ResetOperatorOccultTickets(ctx context.Context, admin AdminOperator, playerID identity.PlayerID, key string, op operation.Context) error {
	if err := admin.Validate(); err != nil {
		return err
	}
	if s.Runner.DB == nil || s.Store == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return errors.New("i5: operator reset unavailable")
	}
	if !playerID.Valid() || key == "" || op.StartedAt.IsZero() {
		return errors.New("i5: invalid operator reset")
	}
	receiptIdentity := operatorResetIdentity(admin, playerID, key, operatorResetOccultTickets)
	fingerprint, err := receipt.FingerprintRequest(operatorResetFingerprint{PlayerID: int64(playerID), Counter: "occult_tickets"})
	if err != nil {
		return err
	}
	resolver := receipt.Resolver{Reader: s.ReceiptRead, Identity: receiptIdentity, Fingerprint: fingerprint}
	_, err = s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, operatorResetRetry(), resolver, func(txctx context.Context, scope tx.Scope) error {
		if done, err := s.operatorResetSeen(txctx, scope.Tx, receiptIdentity, fingerprint); err != nil || done {
			return err
		}
		ledger, err := s.lockOccultLedgerTx(txctx, scope.Tx, playerID, op)
		if err != nil {
			return err
		}
		if ledger.tickets.exists {
			if err = s.writeOccultScalarTx(txctx, scope.Tx, playerID, OccultTicketKey, ledger.tickets, occult.TicketCap, op.StartedAt.UTC()); err != nil {
				return err
			}
		}
		return s.putOperatorResetReceipt(txctx, scope.Tx, op, receiptIdentity, fingerprint, "occult_tickets")
	})
	return err
}

// ResetOperatorSkillPoints sets the skill point balance to the player's current
// privilege cap and clears the regeneration anchor. A player without a
// skill_point row is a no-op, never a created row.
func (s Service) ResetOperatorSkillPoints(ctx context.Context, admin AdminOperator, playerID identity.PlayerID, key string, op operation.Context) error {
	if err := admin.Validate(); err != nil {
		return err
	}
	if s.Runner.DB == nil || s.Store == nil || s.Receipts == nil || s.ReceiptRead == nil || s.Privileges == nil {
		return errors.New("i5: operator reset unavailable")
	}
	if !playerID.Valid() || key == "" || op.StartedAt.IsZero() {
		return errors.New("i5: invalid operator reset")
	}
	receiptIdentity := operatorResetIdentity(admin, playerID, key, operatorResetSkillPoints)
	fingerprint, err := receipt.FingerprintRequest(operatorResetFingerprint{PlayerID: int64(playerID), Counter: "skill_points"})
	if err != nil {
		return err
	}
	resolver := receipt.Resolver{Reader: s.ReceiptRead, Identity: receiptIdentity, Fingerprint: fingerprint}
	now := op.StartedAt.UTC()
	_, err = s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, operatorResetRetry(), resolver, func(txctx context.Context, scope tx.Scope) error {
		if done, err := s.operatorResetSeen(txctx, scope.Tx, receiptIdentity, fingerprint); err != nil || done {
			return err
		}
		if err := s.Store.LockEconomyOwnerTx(txctx, scope.Tx, playerID); err != nil {
			return err
		}
		state, exists, err := s.Store.LockTemporalTx(txctx, scope.Tx, playerID, "skill_point")
		if err != nil {
			return err
		}
		if exists {
			snapshot, err := s.Privileges.SnapshotTx(txctx, scope.Tx, playerID, now)
			if err != nil {
				return err
			}
			if snapshot.ProviderRevision == "" || snapshot.SkillPointNaturalCap < 0 {
				return errors.New("i5: invalid privilege snapshot")
			}
			if state.StoredAmount != snapshot.SkillPointNaturalCap || state.RegenAnchorAt != nil {
				state.StoredAmount = snapshot.SkillPointNaturalCap
				state.RegenAnchorAt = nil
				state.StateVersion++
				state.UpdatedAt = now
				if err = state.Validate(); err != nil {
					return err
				}
				if err = s.Store.SaveTemporalTx(txctx, scope.Tx, state); err != nil {
					return err
				}
			}
		}
		return s.putOperatorResetReceipt(txctx, scope.Tx, op, receiptIdentity, fingerprint, "skill_points")
	})
	return err
}

func operatorResetIdentity(admin AdminOperator, playerID identity.PlayerID, key, operationName string) receipt.Identity {
	return receipt.Identity{
		OwnerKind:   "player",
		OwnerKey:    strconv.FormatInt(int64(playerID), 10),
		Domain:      operatorResetDomain,
		Operation:   operationName,
		SemanticKey: admin.ID + ":" + key,
	}
}

func (s Service) operatorResetSeen(ctx context.Context, q tx.Queryer, id receipt.Identity, fingerprint [32]byte) (bool, error) {
	prior, found, err := s.Receipts.FindTx(ctx, q, id)
	if err != nil || !found {
		return false, err
	}
	if prior.RequestFingerprint != fingerprint {
		return false, &receipt.ConflictError{Identity: id}
	}
	return true, nil
}

func (s Service) putOperatorResetReceipt(ctx context.Context, t tx.Tx, op operation.Context, id receipt.Identity, fingerprint [32]byte, counter string) error {
	payload, err := json.Marshal(map[string]string{"counter": counter})
	if err != nil {
		return err
	}
	created, err := receipt.New(op, id, "I11A_OPERATOR_RESET", operatorResetSchema, payload, fingerprint)
	if err != nil {
		return err
	}
	created.PolicyVersion = operatorResetPolicyVersion
	_, err = s.Receipts.PutTx(ctx, t, created)
	return err
}

func operatorResetRetry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}
}
