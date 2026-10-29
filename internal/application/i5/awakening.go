package i5

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) awakeningAvailable() error {
	if s.Awakening == nil || s.Awakening.Store == nil || s.Awakening.Content == nil || s.Awakening.Heroes == nil || s.Awakening.Pets == nil {
		return errors.New("awakening runtime unavailable")
	}
	return nil
}

func awakeOwner(d objective.AwakeDefinition, heroes []AwakeningHero, pets []character.Pet) int64 {
	if d.Stage != 1 {
		return 0
	}
	if d.Type == 3 {
		for _, p := range pets {
			if p.TableID == d.Before && p.Level >= 90 && p.IsShow {
				return p.PetID
			}
		}
		return 0
	}
	for _, h := range heroes {
		if h.Hero.TableID != d.Before || h.Hero.Kind != character.NormalHero {
			continue
		}
		if d.Type == 1 && h.Hero.Level >= 90 {
			return h.Hero.PartnerID
		}
		if d.Type == 2 && h.Hero.Level >= 100 && h.Hero.Color >= 15 && h.Raw != nil && h.Raw.RawStage == 0 && h.Raw.Validate() == nil {
			return h.Hero.PartnerID
		}
	}
	return 0
}

func (s Service) awakeningProjection(ctx context.Context, q tx.Queryer, pid identity.PlayerID, revision string, root objective.AwakeRoot) (map[string]any, error) {
	c, e := s.Awakening.Content.AwakeningCatalogTx(ctx, q, revision)
	if e != nil {
		return nil, e
	}
	heroes, e := s.Awakening.Heroes.AwakeningHeroesTx(ctx, q, pid, revision)
	if e != nil {
		return nil, e
	}
	pets, e := s.Awakening.Pets.AwakeningPetsTx(ctx, q, pid)
	if e != nil {
		return nil, e
	}
	rows := []map[string]any{}
	body := map[string]any{}
	for kind := int64(1); kind <= 3; kind++ {
		family := []map[string]any{}
		a := root.Active[kind-1]
		for _, d := range c.Definitions {
			if d.Type == kind && d.Stage == 1 && awakeOwner(d, heroes, pets) > 0 && (a.Mission == 0 || a.OwnerID != awakeOwner(d, heroes, pets)) {
				family = append(family, (objective.AwakeInstance{Mission: d.ID, Type: kind}).Wire(false))
			}
		}
		if a.Mission > 0 {
			pinned, e := s.Awakening.Content.AwakeningCatalogTx(ctx, q, a.Revision)
			if e != nil {
				return nil, e
			}
			d, ok := pinned.Definition(a.Mission)
			if !ok || d.Type != kind {
				return nil, objective.ErrAwakeningRefused
			}
			family = append(family, a.Wire(true))
		}
		slices.SortFunc(family, func(a, b map[string]any) int {
			x, y := a["table_id"].(int64), b["table_id"].(int64)
			if x < y {
				return -1
			}
			if x > y {
				return 1
			}
			return 0
		})
		body[objective.AwakeChannel(kind)] = family
		rows = append(rows, family...)
	}
	body["mission_list"] = rows
	if e := s.awakeningRedmarksTx(ctx, q, pid, revision, body); e != nil {
		return nil, e
	}
	return body, nil
}

func (s Service) ReadAwakening(ctx context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	if e := s.awakeningAvailable(); e != nil {
		return nil, e
	}
	timed, e := s.missionOperation(ctx, op)
	if e != nil {
		return nil, e
	}
	scope, e := missionScope(actor.PlayerID, timed)
	if e != nil {
		return nil, e
	}
	var body map[string]any
	_, e = s.Runner.Run(ctx, timed.Operation(), s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, tr tx.Scope) error {
		if e := s.Store.FenceActorTx(ctx, tr.Tx, actor, scope.DecisionAt); e != nil {
			return e
		}
		root, e := s.Awakening.Store.ReadAwakeningTx(ctx, tr.Tx, actor.PlayerID)
		if e != nil {
			return e
		}
		body, e = s.awakeningProjection(ctx, tr.Tx, actor.PlayerID, scope.ContentRevision, root)
		return e
	})
	return body, e
}

type awakeningResult struct {
	Body  map[string]any `json:"body"`
	Grant *GrantResult   `json:"grant,omitempty"`
}

func decodeAwakeningReceipt(r receipt.Receipt, id receipt.Identity, fp [32]byte, out *awakeningResult) error {
	if r.Validate() != nil || r.Identity != id || r.RequestFingerprint != fp || r.OperationClass != "I5_OBJECTIVE" || r.ResultSchema != "gxb.i5.awakening.v1" {
		return errors.New("invalid awakening receipt")
	}
	if e := json.Unmarshal(r.ResultPayload, out); e != nil {
		return e
	}
	if out.Body == nil {
		return errors.New("empty awakening receipt")
	}
	return nil
}

// ChangeAwakening owns the lifecycle receipt; Character and I5 mutations share its transaction.
func (s Service) ChangeAwakening(ctx context.Context, actor identity.ActorContext, action string, id, kind int64, op operation.Context) (map[string]any, error) {
	if e := s.awakeningAvailable(); e != nil {
		return nil, e
	}
	if action != "open" && action != "cancel" && action != "claim" && action != "wish" || action != "wish" && (id <= 0 || kind < 1 || kind > 3) {
		return nil, objective.ErrAwakeningRefused
	}
	timed, e := s.missionOperation(ctx, op)
	if e != nil {
		return nil, e
	}
	scope, e := missionScope(actor.PlayerID, timed)
	if e != nil {
		return nil, e
	}
	rid := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "objective", Operation: "awakening-" + action, SemanticKey: op.ID.String()}
	fp, e := receipt.FingerprintRequest(map[string]any{"action": action, "id": id, "kind": kind})
	if e != nil {
		return nil, e
	}
	var out awakeningResult
	replay := false
	result, e := s.Runner.Run(ctx, timed.Operation(), s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: rid, Fingerprint: fp}, func(ctx context.Context, tr tx.Scope) error {
		if e := s.Store.FenceActorTx(ctx, tr.Tx, actor, scope.DecisionAt); e != nil {
			return e
		}
		if prior, ok, e := s.Receipts.FindTx(ctx, tr.Tx, rid); e != nil {
			return e
		} else if ok {
			if prior.RequestFingerprint != fp {
				return &receipt.ConflictError{Identity: rid}
			}
			replay = true
			return decodeAwakeningReceipt(prior, rid, fp, &out)
		}
		heroes := []AwakeningHero{}
		pets := []character.Pet{}
		// Each family locks only the Character owner it can mutate; actor fencing serializes the player.
		if kind != 3 {
			heroes, e = s.Awakening.Heroes.LockAwakeningHeroesTx(ctx, tr.Tx, actor.PlayerID, scope.ContentRevision)
			if e != nil {
				return e
			}
		}
		if kind == 3 {
			pets, e = s.Awakening.Pets.LockAwakeningPetsTx(ctx, tr.Tx, actor.PlayerID)
			if e != nil {
				return e
			}
		}
		root, e := s.Awakening.Store.LockAwakeningTx(ctx, tr.Tx, actor.PlayerID)
		if e != nil {
			return e
		}
		if err := s.PrepareCharacterFunctionsTx(ctx, tr.Tx, actor.PlayerID); err != nil {
			return err
		}
		old := root.Version
		revision := scope.ContentRevision
		if action == "wish" {
			kind = 1
			id = root.Active[0].Mission
		}
		if kind < 1 || kind > 3 {
			return objective.ErrAwakeningRefused
		}
		active := root.Active[kind-1]
		if active.Mission > 0 {
			revision = active.Revision
		}
		c, e := s.Awakening.Content.AwakeningCatalogTx(ctx, tr.Tx, revision)
		if e != nil {
			return e
		}
		d, ok := c.Definition(id)
		if !ok || d.Type != kind {
			return objective.ErrAwakeningRefused
		}
		pinned, e := bindContentRevisionForSign(timed.Operation(), revision)
		if e != nil {
			return e
		}
		// A new transport operation may replay a terminal transition, but never an older generation after reopen.
		if action == "cancel" && active.Mission == 0 || action == "claim" && active.Mission != id {
			if body, ok, e := root.Replay(action, kind, id); e != nil {
				return e
			} else if ok && (active.Mission == 0 || active.Generation == root.Replays[fmt.Sprintf("%s:%d", action, kind)].Generation) {
				out.Body = body
				return s.putAwakeningReceipt(ctx, tr.Tx, actor, timed.Operation(), rid, fp, out)
			}
		}
		var a objective.AwakeInstance
		body := map[string]any{}
		switch action {
		case "open":
			if active.Mission == id {
				a = active
				body[objective.AwakeChannel(kind)] = []map[string]any{a.Wire(true)}
				out.Body = body
				return s.putAwakeningReceipt(ctx, tr.Tx, actor, timed.Operation(), rid, fp, out)
			}
			owner := awakeOwner(d, heroes, pets)
			if owner == 0 {
				return objective.ErrAwakeningRefused
			}
			a, e = root.Open(d, owner, revision)
			if e != nil {
				return e
			}
			collected := false
			if kind == 1 {
				for _, h := range heroes {
					if h.Hero.PartnerID == owner {
						collected, e = s.Awakening.Heroes.HasAwakeningHeroEquipmentTx(ctx, tr.Tx, h.Hero, d, revision)
						break
					}
				}
			}
			if kind == 3 {
				for _, p := range pets {
					if p.PetID == owner {
						collected, e = s.Awakening.Pets.HasAwakeningPetEquipmentTx(ctx, tr.Tx, p, d, revision)
						break
					}
				}
			}
			if e != nil {
				return e
			}
			if collected {
				if e = root.Complete(kind, id, a.Generation, d.Target); e != nil {
					return e
				}
				a = root.Active[kind-1]
			}
			if kind == 2 {
				if e = s.applyAwakeningHero(ctx, tr.Tx, heroes, d, a, action, pinned, scope.DecisionAt, body); e != nil {
					return e
				}
			}
			body[objective.AwakeChannel(kind)] = []map[string]any{a.Wire(true)}
		case "cancel":
			a, e = root.Cancel(kind, id)
			if e != nil {
				return e
			}
			if kind == 2 {
				if e = s.applyAwakeningHero(ctx, tr.Tx, heroes, d, a, action, pinned, scope.DecisionAt, body); e != nil {
					return e
				}
			}
			if e = s.deleteAwakeningItems(ctx, tr.Tx, actor.PlayerID, d.DeleteItems, pinned); e != nil {
				return e
			}
			body[objective.AwakeChannel(kind)] = []map[string]any{a.Wire(false)}
		case "claim":
			var next objective.AwakeInstance
			a, next, e = root.Claim(c, kind, id)
			if e != nil {
				return e
			}
			if kind == 2 || kind == 1 && d.Stage == 2 {
				if e = s.applyAwakeningHero(ctx, tr.Tx, heroes, d, a, action, pinned, scope.DecisionAt, body); e != nil {
					return e
				}
			}
			if kind == 3 && d.Stage == 2 {
				found := false
				for _, p := range pets {
					if p.PetID == a.OwnerID {
						found = true
						if e = s.Awakening.Pets.FinishAwakeningPetLockedTx(ctx, tr.Tx, p, d, revision, pinned, scope.DecisionAt); e != nil {
							return e
						}
						break
					}
				}
				if !found {
					return objective.ErrAwakeningRefused
				}
			}
			row := a.Wire(true)
			row["is_reward"] = int64(1)
			rows := []map[string]any{row}
			if next.Mission > 0 {
				rows = append(rows, next.Wire(true))
			}
			body[objective.AwakeChannel(kind)] = rows
			body["awards"] = []any{}
		case "wish":
			a, e = root.Current(1, id)
			if e != nil || !c.WishAllowed(d) || a.Complete {
				return objective.ErrAwakeningRefused
			}
			plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "objective", Operation: "awakening-wish", BusinessKey: fmt.Sprint(a.Generation), Occurrence: op.ID.String(), PolicyVersion: objective.AwakeningContract}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: d.Material, Amount: 1}}}
			prepared, e := s.PrepareMaterialExchangeTx(ctx, tr.Tx, actor, MaterialExchangeRequest{Cost: MaterialCost{Stacks: []StackMaterialCost{{ItemID: c.WishItem, Amount: 1}}}, Restoration: plan}, pinned)
			if e != nil {
				return e
			}
			exchanged, e := s.ApplyMaterialExchangeTx(ctx, tr.Tx, prepared)
			if e != nil {
				return e
			}
			out.Grant = &exchanged.Restoration
			body["item_id"] = d.Material
			body["item_num"] = int64(1)
		}
		if action != "wish" {
			if e = root.Remember(action, a, body); e != nil {
				return e
			}
			root.Version++
			if e = s.Awakening.Store.SaveAwakeningTx(ctx, tr.Tx, actor.PlayerID, root, old); e != nil {
				return e
			}
		}
		out.Body = body
		if _, err := s.OpenCharacterFunctionsTx(ctx, tr.Tx, actor.PlayerID, scope.ContentRevision, scope.DecisionAt); err != nil {
			return err
		}
		return s.putAwakeningReceipt(ctx, tr.Tx, actor, timed.Operation(), rid, fp, out)
	})
	if e != nil {
		if action == "wish" && errors.Is(e, economy.ErrInsufficientBalance) {
			return nil, objective.ErrAwakeningRefused
		}
		return nil, e
	}
	if result.Reconciled {
		record, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, errors.New("awakening recovery evidence missing")
		}
		if e = decodeAwakeningReceipt(record, rid, fp, &out); e != nil {
			return nil, e
		}
		replay = true
	}
	if out.Grant != nil {
		p, e := s.projectSettlement(ctx, actor, []GrantResult{*out.Grant}, op, replay)
		if e != nil {
			return nil, e
		}
		if len(p.Economy) > 0 {
			out.Body["economy_"] = p.Economy
		}
		if len(p.NewFunctionIDs) > 0 {
			out.Body["new_funcs_"] = p.NewFunctionIDs
		}
	}
	return out.Body, nil
}

func (s Service) putAwakeningReceipt(ctx context.Context, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, out awakeningResult) error {
	revision, e := requireContentRevision(op)
	if e != nil {
		return e
	}
	if e = s.awakeningRedmarksTx(ctx, t, actor.PlayerID, revision, out.Body); e != nil {
		return e
	}
	raw, e := json.Marshal(out)
	if e != nil {
		return e
	}
	r, e := receipt.New(op, id, "I5_OBJECTIVE", "gxb.i5.awakening.v1", raw, fp)
	if e != nil {
		return e
	}
	r.ActorAccountUID, r.ContextID = string(actor.AccountUID), actor.ContextID.UUID()
	_, e = s.Receipts.PutTx(ctx, t, r)
	return e
}

func (s Service) applyAwakeningHero(ctx context.Context, t tx.Tx, heroes []AwakeningHero, d objective.AwakeDefinition, a objective.AwakeInstance, action string, op operation.Context, at time.Time, body map[string]any) error {
	for _, h := range heroes {
		if h.Hero.PartnerID == a.OwnerID {
			next, e := s.Awakening.Heroes.ApplyAwakeningHeroLockedTx(ctx, t, h, d, a, action, op, at)
			if e != nil {
				return e
			}
			if d.Type == 2 {
				body["twice_awake_stage_"] = map[string]any{"table_id": next.Hero.TableID, "stage": next.Raw.RawStage}
			}
			return nil
		}
	}
	return objective.ErrAwakeningRefused
}

func (s Service) deleteAwakeningItems(ctx context.Context, t tx.Tx, pid identity.PlayerID, items []int64, op operation.Context) error {
	if len(items) == 0 {
		return nil
	}
	if s.Awakening.Stacks == nil || s.Awakening.Costs == nil {
		return errors.New("awakening material owner unavailable")
	}
	stacks, e := s.Awakening.Stacks.ListStacksTx(ctx, t, pid)
	if e != nil {
		return e
	}
	cost := MaterialCost{}
	seen := map[int64]bool{}
	for _, st := range stacks {
		if st.Quantity > 0 && slices.Contains(items, st.ItemID) && !seen[st.ItemID] {
			cost.Stacks = append(cost.Stacks, StackMaterialCost{ItemID: st.ItemID, Amount: st.Quantity})
			seen[st.ItemID] = true
		}
	}
	if len(cost.Stacks) == 0 {
		return nil
	}
	slices.SortFunc(cost.Stacks, func(a, b StackMaterialCost) int {
		if a.ItemID < b.ItemID {
			return -1
		}
		if a.ItemID > b.ItemID {
			return 1
		}
		return 0
	})
	_, e = s.Awakening.Costs.DebitMaterialCostTx(ctx, t, pid, cost, op)
	return e
}

type AwakeningBootstrap struct{ Owner Service }

func (AwakeningBootstrap) Name() string     { return "i5.awakening" }
func (AwakeningBootstrap) Claims() []string { return []string{"2561"} }
func (b AwakeningBootstrap) ReconcileCharacterLogin(ctx context.Context, t tx.Tx, actor identity.ActorContext, op operation.Context, at time.Time) error {
	if e := b.Owner.awakeningAvailable(); e != nil {
		return e
	}
	if _, err := b.Owner.Awakening.Store.LockAwakeningTx(ctx, t, actor.PlayerID); err != nil {
		return err
	}
	if err := b.Owner.PrepareCharacterFunctionsTx(ctx, t, actor.PlayerID); err != nil {
		return err
	}
	revision, err := b.Owner.Content.ActiveRevision(ctx, t)
	if err != nil {
		return err
	}
	_, err = b.Owner.OpenCharacterFunctionsTx(ctx, t, actor.PlayerID, revision, at)
	return err
}
func (b AwakeningBootstrap) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	rev, e := b.Owner.Content.ActiveRevision(ctx, q)
	if e != nil {
		return e
	}
	root, e := b.Owner.Awakening.Store.ReadAwakeningTx(ctx, q, actor.PlayerID)
	if e != nil {
		return e
	}
	body, e := b.Owner.awakeningProjection(ctx, q, actor.PlayerID, rev, root)
	if e != nil {
		return e
	}
	detail["2561"] = body
	return nil
}

func (s Service) ClaimAwakening(ctx context.Context, actor identity.ActorContext, id int64, op operation.Context) (map[string]any, bool, error) {
	if e := s.awakeningAvailable(); e != nil {
		return nil, false, e
	}
	if s.MissionFresh == nil {
		return nil, false, errors.New("awakening routing query unavailable")
	}
	revision, e := s.Content.ActiveRevision(ctx, s.MissionFresh)
	if e != nil {
		return nil, false, e
	}
	c, e := s.Awakening.Content.AwakeningCatalogTx(ctx, s.MissionFresh, revision)
	if e != nil {
		return nil, false, e
	}
	d, ok := c.Definition(id)
	if !ok {
		root, e := s.Awakening.Store.ReadAwakeningTx(ctx, s.MissionFresh, actor.PlayerID)
		if e != nil {
			return nil, false, e
		}
		for _, a := range root.Active {
			if a.Mission == id {
				d = objective.AwakeDefinition{ID: id, Type: a.Type}
				ok = true
				break
			}
		}
	}
	if !ok {
		return nil, false, nil
	}
	body, e := s.ChangeAwakening(ctx, actor, "claim", id, d.Type, op)
	return body, true, e
}
