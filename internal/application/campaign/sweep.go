package campaign

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Sweep struct {
	CampaignID int64
	Type       int64
	Count      int64
	Kind       int64
}

type Reset struct {
	CampaignID int64
	Type       int64
}

func (s Mode) Sweep(c context.Context, a identity.ActorContext, q Sweep, op operation.Context) (map[string]any, error) {
	return s.purchase(c, a, "sweep", q, op, func(c context.Context, sc gen.TimedScope, v view, r d.Record, level int64, privilege i5.PrivilegeSnapshot) (map[string]any, error) {
		n, err := v.catalog.Admit(r.Progress, q.Type, q.CampaignID, level, v.day, v.superOpen)
		if err != nil {
			return nil, err
		}
		next, err := v.catalog.Sweep(r.Progress, n, q.Count, q.Kind, v.day, privilege.VIPLevel, privilege.MonthlyPrivilegeActive)
		if err != nil {
			return nil, err
		}
		current := sc.Operation.Operation()
		if err = s.debit(c, sc, a.PlayerID, n.EnergyCost*q.Count); err != nil {
			return nil, err
		}
		cost := i5.MaterialCost{}
		if q.Kind == 1 {
			cost.Stacks = []i5.StackMaterialCost{{ItemID: v.catalog.SweepCardItemID, Amount: q.Count}}
		} else {
			cost.Scalars = []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: q.Count * v.catalog.PrivatePolicy.SweepCrystalPerCard}}
		}
		if _, err = s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, cost, current); err != nil {
			return nil, purchaseError(err)
		}
		progress, err := s.Progression.ReadProgressionTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return nil, err
		}
		rule, err := s.Content.ResolveProgressionPolicyTx(c, sc.Tx, v.revision)
		if err != nil {
			return nil, err
		}
		exp, err := v.catalog.SweepEXP(n, q.Count, progress, rule)
		if err != nil {
			return nil, err
		}
		items, economys := make([][]d.Item, 0, q.Count), make([]any, 0, q.Count)
		lines := []grant.Line{{Kind: grant.PlayerExp, Amount: exp}, {Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: n.ManaGain * q.Count}}
		for i := int64(0); i < q.Count; i++ {
			row := []d.Item{}
			for _, award := range n.SweepReward {
				row = append(row, d.Item{ItemID: award[0], Num: award[1]})
			}
			row = append(row, v.catalog.Drop(n.RepeatBox, cd.NewStream(current.Derive("campaign.drop.sweep/v1", uint64(i))))...)
			items = append(items, row)
			economys = append(economys, map[string]any{"exp": n.EnergyCost, "mana": n.ManaGain})
			for _, item := range row {
				if item.Num > 0 {
					lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item.ItemID, Amount: item.Num})
				}
			}
		}
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "campaign", Operation: "sweep", BusinessKey: "campaign:sweep:" + current.ID.String(), Occurrence: current.ID.String(), PolicyVersion: d.PolicyID}, Lines: lines}
		if _, err = s.Grants.SettleGrantTx(c, sc.Tx, a, plan, current, i5.GrantTxOptions{}); err != nil {
			return nil, err
		}
		kind := NormalWinKind
		if n.Type == d.Super {
			kind = SuperWinKind
		}
		for i := int64(0); i < q.Count; i++ {
			if err = s.Facts.RecordTx(c, sc.Tx, current, objective.Fact{PlayerID: a.PlayerID, SourceDomain: "campaign", SourceBusinessKey: fmt.Sprintf("%s/%d", current.ID, i), Kind: kind, Delta: 1}); err != nil {
				return nil, err
			}
		}
		r.Progress = next
		if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, []int64{n.ID}, sc.Operation.DecisionAt()); err != nil {
			return nil, err
		}
		return map[string]any{"items": items, "economys": economys, "additional": []any{}, "campaign": v.catalog.Row(next, n.ID, v.day)}, nil
	})
}

func (s Mode) Reset(c context.Context, a identity.ActorContext, q Reset, op operation.Context) (map[string]any, error) {
	if q.Type != d.Super {
		return nil, d.ErrInvalid
	}
	return s.purchase(c, a, "reset", q, op, func(c context.Context, sc gen.TimedScope, v view, r d.Record, level int64, privilege i5.PrivilegeSnapshot) (map[string]any, error) {
		next, price, err := v.catalog.Reset(r.Progress, q.CampaignID, level, v.day, privilege.VIPLevel, v.superOpen, privilege.MonthlyPrivilegeActive)
		if err != nil {
			return nil, err
		}
		if price > 0 {
			if _, err = s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: price}}}, sc.Operation.Operation()); err != nil {
				return nil, purchaseError(err)
			}
		}
		r.Progress = next
		if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, []int64{q.CampaignID}, sc.Operation.DecisionAt()); err != nil {
			return nil, err
		}
		return v.catalog.Row(next, q.CampaignID, v.day), nil
	})
}

func purchaseError(err error) error {
	if errors.Is(err, economy.ErrInsufficientBalance) || errors.Is(err, economy.ErrUnknownResource) {
		return fmt.Errorf("%w: cost unavailable", d.ErrRefused)
	}
	return err
}

// purchase binds admission, costs, state and final projection to one receipt;
// its fresh-writer resolver proves an unknown COMMIT without granting again.
func (s Mode) purchase(c context.Context, a identity.ActorContext, name string, request any, op operation.Context, apply func(context.Context, gen.TimedScope, view, d.Record, int64, i5.PrivilegeSnapshot) (map[string]any, error)) (map[string]any, error) {
	if s.Privileges == nil || s.Costs == nil || s.Progression == nil {
		return nil, d.ErrUnavailable
	}
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "campaign", Operation: name, SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	_, result, err := s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		record, err := s.Store.LockTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return err
		}
		stored, found, err := s.Receipts.FindTx(c, sc.Tx, id)
		if err != nil {
			return err
		}
		if found {
			if stored.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: id}
			}
			return json.Unmarshal(stored.ResultPayload, &out)
		}
		revision, _ := op.Policies.Get("content")
		v, err := s.read(c, sc.Tx, a.PlayerID, revision, at)
		if err != nil {
			return err
		}
		privilege, err := s.Privileges.SnapshotTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return err
		}
		progress, err := s.Progression.ReadProgressionTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		out, err = apply(c, sc, v, record, progress.Level, privilege)
		if err != nil {
			return err
		}
		balances, functions := changes.Recorded(c)
		out["economy_"] = balances
		if len(functions) > 0 {
			out["new_funcs_"] = functions
		}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		r, err := receipt.New(sc.Operation.Operation(), id, "I9_3B_CAMPAIGN", "gxb.campaign.purchase.v1", raw, fingerprint)
		if err != nil {
			return err
		}
		r.PolicyVersion, r.ActorAccountUID, r.ContextID = d.PolicyID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, r)
		return err
	})
	if err == nil && result.Reconciled {
		stored, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, d.ErrUnavailable
		}
		err = json.Unmarshal(stored.ResultPayload, &out)
	}
	return out, err
}
