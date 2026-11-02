package godstrial

import (
	"context"
	"encoding/json"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

const policyID = "I9_GODS_TRIAL_PRIVATE_POLICY_V1"

type view struct {
	catalog  d.Catalog
	revision string
	level    int64
	count    int64
}

func profile() tx.Profile {
	return tx.Profile{Name: "gods-trial", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 90 * time.Second}
}
func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}
func (s Mode) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if s.Fresh == nil || s.Store == nil || s.Content == nil || s.Fence == nil || s.Functions == nil || s.Heroes == nil || s.HeroLocks == nil || s.Pets == nil || s.Combat == nil || s.Rules == nil || s.Values == nil || s.Energy == nil || s.Spirit == nil || s.Progression == nil || s.Mail == nil || s.Facts == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return op, d.ErrUnavailable
	}
	if _, ok := op.Policies.Get("content"); ok {
		return op, nil
	}
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return op, e
	}
	refs := append(op.Policies.Refs(), policy.Ref{Name: "content", Version: rev})
	op.Policies, e = policy.NewSet(refs...)
	return op, e
}
func (s Mode) run(c context.Context, a identity.ActorContext, name string, request any, formation []int64, pet int64, op operation.Context, apply func(context.Context, gen.TimedScope, view, *d.State) (map[string]any, error)) (map[string]any, error) {
	op, e := s.pin(c, op)
	if e != nil {
		return nil, e
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(a.PlayerID), Domain: "godstrial", Operation: name, SemanticKey: op.ID.String()}
	fp, e := receipt.FingerprintRequest(request)
	if e != nil {
		return nil, e
	}
	var out map[string]any
	_, res, e := s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		gate, ok, e := s.Functions.ReadFunctionEligibilityTx(c, sc.Tx, a.PlayerID, 99)
		if e != nil {
			return e
		}
		if !ok || at.Before(gate.EligibleAt) {
			return d.ErrRefused
		}
		prior, ok, e := s.Receipts.FindTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if ok {
			if prior.RequestFingerprint != fp {
				return &receipt.ConflictError{Identity: id}
			}
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		// SERIALIZABLE retries a concurrent replacement of the pre-read participant set.
		old, _, e := s.Store.ReadTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		selected := append([]int64{}, formation...)
		selectedPet := pet
		if name == "result" && old.Fight != nil {
			selected = append([]int64{}, old.Fight.Formation...)
			selectedPet = old.Fight.Pet
		}
		if len(selected) > 0 {
			if e = s.Heroes.LockStoryRosterTx(c, sc.Tx, a.PlayerID); e != nil {
				return e
			}
			sort.Slice(selected, func(i, j int) bool { return selected[i] < selected[j] })
			for i, h := range selected {
				if h == 0 {
					continue
				}
				if h < 0 || i > 0 && h == selected[i-1] {
					return d.ErrInvalid
				}
				if _, e = s.HeroLocks.LockHeroByPartnerIDTx(c, sc.Tx, a.PlayerID, h); e != nil {
					return e
				}
			}
		}
		if selectedPet > 0 {
			if e = s.Pets.LockCampaignPetTx(c, sc.Tx, a.PlayerID, selectedPet); e != nil {
				return e
			}
		}
		count, e := s.Spirit.LockTrialInventoryTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		state, e := s.Store.LockTx(c, sc.Tx, a.PlayerID, at)
		if e != nil {
			return e
		}
		if e = state.Normalize(at.Unix()); e != nil {
			return e
		}
		if state.Server != 0 && state.Server != int64(a.LogicalServerID) {
			return d.ErrRefused
		}
		state.Server = int64(a.LogicalServerID)
		state.Player = int64(a.PlayerID)
		rev, _ := op.Policies.Get("content")
		catalog, e := s.Content.GodsTrialCatalogTx(c, sc.Tx, rev)
		if e != nil {
			return e
		}
		progression, e := s.Progression.ReadProgressionTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		v := view{catalog, rev, progression.Level, count}
		out, e = apply(c, sc, v, &state)
		if e != nil {
			return e
		}

		balance, funcs := changes.Recorded(c)
		if len(balance) > 0 {
			out["economy_"] = balance
		}
		if len(funcs) > 0 {
			out["new_funcs_"] = funcs
		}
		for k, val := range changes.RecordedMissions(c) {
			out[k] = val
		}
		if e = s.Store.SaveTx(c, sc.Tx, a.PlayerID, state, at); e != nil {
			return e
		}
		raw, e := json.Marshal(out)
		if e != nil {
			return e
		}
		rec, e := receipt.New(sc.Operation.Operation(), id, "I9_6A_GODS_TRIAL", "gxb.godstrial.result.v1", raw, fp)
		if e != nil {
			return e
		}
		rec.PolicyVersion, rec.ActorAccountUID, rec.ContextID = policyID, string(a.AccountUID), a.ContextID.UUID()
		_, e = s.Receipts.PutTx(c, sc.Tx, rec)
		return e
	})
	if e == nil && res.Reconciled {
		rec, ok := res.Evidence.(receipt.Receipt)
		if !ok {
			return nil, d.ErrUnavailable
		}
		e = json.Unmarshal(rec.ResultPayload, &out)
	}
	return out, e
}
