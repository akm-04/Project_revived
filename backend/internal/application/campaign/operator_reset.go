package campaign

import (
	"context"
	"encoding/json"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const campaignOperatorResetOperation = "operator-reset"

type campaignResetFingerprint struct {
	PlayerID int64
	Counter  string
}

// ResetOperatorCampaignDaily clears the current game day's wins and elite
// resets of every played node and the trial wins of every trial group. A
// player without a campaign row is a no-op, never a created row.
func (s Mode) ResetOperatorCampaignDaily(ctx context.Context, admin i5.AdminOperator, playerID identity.PlayerID, key string, op operation.Context) error {
	if err := admin.Validate(); err != nil {
		return err
	}
	if s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil || s.Store == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return d.ErrUnavailable
	}
	if !playerID.Valid() || key == "" || op.StartedAt.IsZero() {
		return d.ErrInvalid
	}
	receiptIdentity := receipt.Identity{
		OwnerKind:   "player",
		OwnerKey:    strconv.FormatInt(int64(playerID), 10),
		Domain:      "campaign",
		Operation:   campaignOperatorResetOperation,
		SemanticKey: admin.ID + ":" + key,
	}
	fingerprint, err := receipt.FingerprintRequest(campaignResetFingerprint{PlayerID: int64(playerID), Counter: "campaign_daily"})
	if err != nil {
		return err
	}
	resolver := timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: receiptIdentity, Fingerprint: fingerprint}}
	_, _, err = s.Timed.Run(ctx, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), resolver, func(txctx context.Context, scope gen.TimedScope) error {
		if prior, found, err := s.Receipts.FindTx(txctx, scope.Tx, receiptIdentity); err != nil {
			return err
		} else if found {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: receiptIdentity}
			}
			return nil
		}
		at := scope.Operation.DecisionAt()
		day := modes.Day(at)
		existing, err := s.Store.ReadTx(txctx, scope.Tx, playerID)
		if err != nil {
			return err
		}
		if existing.StateVersion > 0 {
			record, err := s.Store.LockTx(txctx, scope.Tx, playerID, at)
			if err != nil {
				return err
			}
			changed := make([]int64, 0, len(record.Progress.Nodes))
			for nodeID, state := range record.Progress.Nodes {
				updated := state
				if updated.Wins.Period == day && updated.Wins.Used != 0 {
					updated.Wins = modes.Counter{Period: day}
				}
				if updated.Resets.Period == day && updated.Resets.Used != 0 {
					updated.Resets = modes.Counter{Period: day}
				}
				if updated.Wins == state.Wins && updated.Resets == state.Resets {
					continue
				}
				record.Progress.Nodes[nodeID] = updated
				changed = append(changed, nodeID)
			}
			trialsChanged := false
			for kind, counter := range record.Progress.TrialWins {
				if counter.Period != day || counter.Used == 0 {
					continue
				}
				record.Progress.TrialWins[kind] = modes.Counter{Period: day}
				trialsChanged = true
			}
			if len(changed) > 0 || trialsChanged {
				if err = s.Store.SaveTx(txctx, scope.Tx, playerID, record, changed, at); err != nil {
					return err
				}
			}
		}
		created, err := receipt.New(scope.Operation.Operation(), receiptIdentity, "I11A_OPERATOR_RESET", "gxb.operator.reset-counter.v1", json.RawMessage(`{"counter":"campaign_daily"}`), fingerprint)
		if err != nil {
			return err
		}
		created.PolicyVersion = "operator-reset-v1"
		_, err = s.Receipts.PutTx(txctx, scope.Tx, created)
		return err
	})
	return err
}
