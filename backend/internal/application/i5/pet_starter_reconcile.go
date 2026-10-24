package i5

import (
	"context"
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type PetStarterLoginReconciler struct {
	Store   Store
	Content ContentRuntime
}

func (PetStarterLoginReconciler) Name() string { return "i5.ca3-pet-starter" }
func (r PetStarterLoginReconciler) ReconcileCharacterLogin(ctx context.Context, t tx.Tx, actor identity.ActorContext, op operation.Context) error {
	if r.Store == nil || r.Content == nil || t == nil || !actor.PlayerID.Valid() || op.StartedAt.IsZero() {
		return errors.New("i5 Pet starter reconcile unavailable")
	}
	revision, err := r.Content.ActiveRevision(ctx, t)
	if err != nil {
		return err
	}
	fp, err := r.Content.ResolveFunctionGatePolicyTx(ctx, t, revision)
	if err != nil {
		return err
	}
	var gate *FunctionGate
	for i := range fp.Gates {
		if fp.Gates[i].FunctionID == 38 {
			gate = &fp.Gates[i]
			break
		}
	}
	if gate == nil || gate.AnnouncementCapability != "PET_STARTER_CA3" {
		return nil
	}
	if gate.GateKind != "PURE_LEVEL" || gate.RequiredLevel <= 0 {
		return errors.New("i5 Pet starter gate invalid")
	}
	prog, err := r.Store.ReadProgressionTx(ctx, t, actor.PlayerID)
	if err != nil {
		return err
	}
	if prog.Level < gate.RequiredLevel {
		return nil
	}
	sp, err := r.Content.ResolvePetStarterPolicyTx(ctx, t, revision)
	if err != nil {
		return err
	}
	if sp.StarterEggItemID <= 0 {
		return errors.New("i5 Pet starter policy invalid")
	}
	rp, err := r.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.StackItem, ItemID: sp.StarterEggItemID, Amount: 1})
	if err != nil {
		return err
	}
	if rp.Stack == nil {
		return economy.ErrUnknownResource
	}
	now := op.StartedAt.UTC()
	// Canonical I5 order: owner 700 -> stack 722 -> function state 730.
	if err := r.Store.LockEconomyOwnerTx(ctx, t, actor.PlayerID); err != nil {
		return err
	}
	st, exists, err := r.Store.LockStackTx(ctx, t, actor.PlayerID, sp.StarterEggItemID, now)
	if err != nil {
		return err
	}
	functionVersion, err := r.Store.LockFunctionStateTx(ctx, t, actor.PlayerID)
	if err != nil {
		return err
	}
	e := player.FunctionEligibility{PlayerID: actor.PlayerID, FunctionID: 38, ContentRevision: revision, SourceFactKey: fmt.Sprintf("ca3:pet-starter:eligibility:%s:38", revision), EligibleAt: now}
	eligibilityInserted, err := r.Store.InsertFunctionEligibilityTx(ctx, t, e)
	if err != nil {
		return err
	}
	unlockInserted, err := r.Store.InsertFunctionUnlockTx(ctx, t, player.FunctionUnlock{PlayerID: actor.PlayerID, FunctionID: 38, OpenedAt: now, SourceFactKey: e.SourceFactKey, StateVersion: 1})
	if err != nil {
		return err
	}
	if unlockInserted {
		if !exists {
			st = economy.StackState{PlayerID: actor.PlayerID, ItemID: sp.StarterEggItemID, Quantity: 0, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
		}
		if st.Quantity == 0 {
			cr, err := st.PlanCredit(1, *rp.Stack, now)
			if err != nil {
				return err
			}
			if cr.Fit != 1 || cr.Overflow != 0 {
				return errors.New("i5 Pet starter egg cannot fit")
			}
			if err := r.Store.SaveStackTx(ctx, t, cr.State, exists); err != nil {
				return err
			}
		}
	}
	if eligibilityInserted || unlockInserted {
		if err := r.Store.AdvanceFunctionStateTx(ctx, t, actor.PlayerID, functionVersion, now); err != nil {
			return err
		}
	}
	return nil
}
