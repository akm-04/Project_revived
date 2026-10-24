package i5

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrStackAdjustmentOverflowRequiresGrant = errors.New("positive stack adjustment overflow requires Grant settlement")

type StackOwnerAdjustmentResult struct {
	ReceiptID       string `json:"receipt_id"`
	ItemID          int64  `json:"item_id"`
	Delta           int64  `json:"delta"`
	BeforeQuantity  int64  `json:"before_quantity"`
	AfterQuantity   int64  `json:"after_quantity"`
	Deleted         bool   `json:"deleted"`
	ContentRevision string `json:"content_revision"`
}

// AdjustStack is the canonical signed stack-owner command. It is deliberately
// separate from positive-only Grant settlement: consumption has its own
// semantic identity and receipt, so delete/recreate races never use row
// existence as replay proof.
func (s Service) AdjustStack(ctx context.Context, actor identity.ActorContext, source grant.SourceIdentity, itemID, delta int64, op operation.Context) (StackOwnerAdjustmentResult, error) {
	if err := s.validate(); err != nil {
		return StackOwnerAdjustmentResult{}, err
	}
	if !actor.PlayerID.Valid() || itemID <= 0 || op.StartedAt.IsZero() {
		return StackOwnerAdjustmentResult{}, errors.New("invalid stack adjustment command")
	}
	if err := source.Validate(); err != nil {
		return StackOwnerAdjustmentResult{}, err
	}
	semantic := source.SemanticKey() + ":" + strconv.FormatInt(itemID, 10)
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "stack", Operation: "adjust", SemanticKey: semantic}
	fp, err := receipt.FingerprintRequest(map[string]any{"source": source, "item_id": itemID, "delta": delta})
	if err != nil {
		return StackOwnerAdjustmentResult{}, err
	}
	boundOp := op
	var out StackOwnerAdjustmentResult
	resolver := receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, resolver, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Store.FenceActorTx(txctx, scope.Tx, actor, op.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			return decodeStackAdjustmentReceipt(prior, &out)
		}
		prepared, err := s.bindActiveContentTx(txctx, scope.Tx, boundOp)
		if err != nil {
			return err
		}
		boundOp = prepared
		revision, err := requireContentRevision(boundOp)
		if err != nil {
			return err
		}
		policy, err := s.Content.ResolveResourceTx(txctx, scope.Tx, revision, grant.Line{Kind: grant.StackItem, ItemID: itemID, Amount: 1})
		if err != nil || policy.Stack == nil {
			if err == nil {
				err = economy.ErrUnknownResource
			}
			return err
		}
		// D01/frozen R5 lock order: owner 700 before stack 722.
		if err := s.Store.LockEconomyOwnerTx(txctx, scope.Tx, actor.PlayerID); err != nil {
			return err
		}
		state, exists, err := s.Store.LockStackTx(txctx, scope.Tx, actor.PlayerID, itemID, op.StartedAt.UTC())
		if err != nil {
			return err
		}
		before := int64(0)
		if exists {
			before = state.Quantity
		} else {
			if delta < 0 {
				return economy.ErrInsufficientBalance
			}
			state = economy.StackState{PlayerID: actor.PlayerID, ItemID: itemID, Quantity: 0, StateVersion: 1, AcquiredAt: op.StartedAt.UTC(), UpdatedAt: op.StartedAt.UTC()}
		}
		planned := economy.StackCreditResult{State: state}
		if delta != 0 {
			planned, err = state.PlanAdjustment(delta, *policy.Stack, op.StartedAt.UTC())
			if err != nil {
				return err
			}
			if delta > 0 && planned.Overflow > 0 {
				return ErrStackAdjustmentOverflowRequiresGrant
			}
		}
		after := planned.State.Quantity
		deleted := exists && delta != 0 && after == 0
		switch {
		case deleted:
			if err := s.Store.DeleteStackTx(txctx, scope.Tx, planned.State); err != nil {
				return err
			}
		case delta != 0 && after > 0:
			if err := s.Store.SaveStackTx(txctx, scope.Tx, planned.State, exists); err != nil {
				return err
			}
		}
		rr, err := receipt.New(boundOp, id, "I5_STACK_ADJUST", "gxb.i5.stack-adjust.v1", json.RawMessage(`{"pending":true}`), fp)
		if err != nil {
			return err
		}
		out = StackOwnerAdjustmentResult{ReceiptID: rr.ID.String(), ItemID: itemID, Delta: delta, BeforeQuantity: before, AfterQuantity: after, Deleted: deleted, ContentRevision: revision}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		rr.ResultPayload = raw
		rr.PolicyVersion = source.PolicyVersion
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		put, err := s.Receipts.PutTx(txctx, scope.Tx, rr)
		if err != nil {
			return err
		}
		if !put.Inserted {
			return decodeStackAdjustmentReceipt(put.Receipt, &out)
		}
		return nil
	})
	if err != nil {
		return StackOwnerAdjustmentResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := decodeStackAdjustmentReceipt(r, &out); err != nil {
				return StackOwnerAdjustmentResult{}, err
			}
		}
	}
	return out, nil
}

func decodeStackAdjustmentReceipt(r receipt.Receipt, out *StackOwnerAdjustmentResult) error {
	if r.ResultSchema != "gxb.i5.stack-adjust.v1" {
		return fmt.Errorf("unsupported stack adjustment receipt schema %q", r.ResultSchema)
	}
	return json.Unmarshal(r.ResultPayload, out)
}
