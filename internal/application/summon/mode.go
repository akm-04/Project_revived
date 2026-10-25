// Package summon composes Vending (I9_GACHA_V1): LOAD_SUMMON_INFO (56, also
// MID1 detail["56"]), SUMMON_HERO (50, classic and SX), Magic (70, 71) and the
// Vows scroll exchange (306). Lock order: actor fence 315, hero root 400,
// summon row, I5 700+; loads take no lock.
package summon

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Mode struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Content     Content
	Fence       Fence
	Heroes      Heroes
	HeroWire    func(character.Hero) (map[string]any, error)
	Grants      Grants
	Costs       i5.TxMaterialCostDebiter
	Facts       Facts
	Privileges  i5.PrivilegeSnapshotProvider
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}

type Store interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.State, bool, error)
	LockTx(context.Context, tx.Tx, identity.PlayerID, d.State, time.Time) (d.State, error)
	SaveTx(context.Context, tx.Tx, identity.PlayerID, d.State, time.Time) error
	TuningTx(context.Context, tx.Queryer) (d.Tuning, bool, error)
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	SummonCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

// Heroes is Character's partner acquisition; a nil admission proof means the
// origin was already owned and nothing was created (D116).
type Heroes interface {
	LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error
	OwnsOriginTx(context.Context, tx.Tx, identity.PlayerID, int64) (bool, error)
	AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error)
}

type Facts interface {
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

// SummonKind is one fact per pulled slot (task_req 17, I9-MISSION-SUMMON-FACT).
const SummonKind = "SUMMON"

type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

// Pull is a 50 request.
type Pull struct {
	Type  int64
	Index int64
}

func ModeProfile() tx.Profile {
	return tx.Profile{Name: "summon", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

func (s Mode) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil &&
		s.Heroes != nil && s.HeroWire != nil && s.Grants != nil && s.Costs != nil && s.Facts != nil && s.Privileges != nil && s.Receipts != nil && s.ReceiptRead != nil
}

func (s Mode) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if !s.ready() {
		return op, d.ErrUnavailable
	}
	if _, bound := op.Policies.Get("content"); bound {
		return op, nil
	}
	revision, err := s.Content.ActiveRevision(c, s.Fresh)
	if err != nil {
		return op, err
	}
	op.Policies, err = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	return op, err
}

// Info is the 56 body: free times are the last free pull (0 = ready) and the featured calendar of the GMT+8 day.
func (s Mode) Info(c context.Context, q tx.Queryer, pid identity.PlayerID, revision string, at time.Time) (map[string]any, error) {
	catalog, err := s.catalog(c, q, revision)
	if err != nil {
		return nil, err
	}
	day := modes.Day(at)
	state, found, err := s.Store.ReadTx(c, q, pid)
	if err != nil {
		return nil, err
	}
	if !found {
		state = catalog.NewState(day)
	}
	return info(&catalog, catalog.Refresh(state, day), day), nil
}

// catalog is the pinned revision under the operator overlay. A rejected
// overlay is logged and the source policy serves, so a bad edit never stops Vending.
func (s Mode) catalog(c context.Context, q tx.Queryer, revision string) (d.Catalog, error) {
	catalog, err := s.Content.SummonCatalogTx(c, q, revision)
	if err != nil {
		return catalog, err
	}
	tuning, found, err := s.Store.TuningTx(c, q)
	if err != nil || !found {
		return catalog, err
	}
	tuned, err := catalog.Tune(tuning)
	if err != nil {
		log.Printf("summon: operator tuning v%d rejected, source policy serves: %v", tuning.Version, err)
		return catalog, nil
	}
	return tuned, nil
}

func info(catalog *d.Catalog, s d.State, day int64) map[string]any {
	rotation := catalog.Rotation(day)
	out := map[string]any{
		"mana_free_time": s.ManaFreeTime, "crystal_free_time": s.CrystalFreeTime, "mana_free_num": s.ManaFreeNum,
		"main_ids": rotation.Main, "second_ids": rotation.Second, "partner_id": rotation.Partner,
		"mana_id": catalog.Policy.Display.ManaID, "pet_id": rotation.Pet,
	}
	if s.MagicTarget > 0 {
		out["directional_show_id"] = s.MagicTarget
	}
	return out
}

// Load answers 56.
func (s Mode) Load(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	revision, _ := op.Policies.Get("content")
	var out map[string]any
	_, _, err = s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		out, err = s.Info(c, sc.Tx, a.PlayerID, revision, sc.Operation.DecisionAt())
		return err
	})
	return out, err
}

func (Mode) Name() string     { return "i9-3e.summon-info" }
func (Mode) Claims() []string { return []string{"56"} }

// OverlayMID1 writes detail["56"], replacing the inert lobby shape.
func (s Mode) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	if q == nil || s.Content == nil || s.Store == nil {
		return d.ErrUnavailable
	}
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return err
	}
	body, err := s.Info(c, q, a.PlayerID, revision, at)
	if err != nil {
		return err
	}
	detail["56"] = body
	return nil
}

// sxType is SummonType.Stone; its summon_index selects main_ids[index-1] as the hotspot.
const sxType = 4

// Summon answers 50 for the classic buttons (Small, Medium, tickets) and SX.
func (s Mode) Summon(c context.Context, a identity.ActorContext, q Pull, op operation.Context) (map[string]any, error) {
	return s.purchase(c, a, "classic", q, op, func(c context.Context, sc gen.TimedScope, v view, state d.State) (map[string]any, d.State, error) {
		if q.Type == sxType {
			return s.sx(c, sc, a, v, state, q.Index)
		}
		b, ok := v.catalog.Button(q.Type, q.Index)
		if !ok || b.Family == d.Magic {
			return nil, state, d.ErrInvalid
		}
		now := sc.Operation.DecisionAt()
		state, err := v.catalog.Admit(b, state, now.Unix(), v.day)
		if err != nil {
			return nil, state, err
		}
		current := sc.Operation.Operation()
		if err = s.debit(c, sc, a.PlayerID, b); err != nil {
			return nil, state, err
		}
		firstSmall := state.Counters[d.Small] < 1
		slots, state, err := v.catalog.Draw(b, state, v.catalog.Rotation(v.day).Partner, cd.NewStream(current.Derive("summon.classic/v1", 0)))
		if err != nil {
			return nil, state, err
		}
		out := map[string]any{}
		itemID, amount := v.catalog.Juice(b)
		if firstSmall && state.Counters[d.Small] >= 1 {
			itemID, amount = v.catalog.Reward.ItemID, v.catalog.Reward.ItemNum
		}
		if out["result"], err = s.deliver(c, sc, a, v, slots, reward(itemID, amount, out)); err != nil {
			return nil, state, err
		}
		out["summon_info"] = info(&v.catalog, state, v.day)
		return out, state, nil
	})
}

// sx is a type 4 purchase: VIP gate, crystal, five static items and the dynamic slot (V1 sx_private_v2).
func (s Mode) sx(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, state d.State, selector int64) (map[string]any, d.State, error) {
	b, ok := v.catalog.Button(sxType, 1)
	main := v.catalog.Rotation(v.day).Main
	if !ok || selector < 1 || selector > int64(len(main)) {
		return nil, state, d.ErrInvalid
	}
	snapshot, err := s.Privileges.SnapshotTx(c, sc.Tx, a.PlayerID, sc.Operation.DecisionAt())
	if err != nil {
		return nil, state, err
	}
	if snapshot.VIPLevel < v.catalog.Policy.SX.VIPMin {
		return nil, state, fmt.Errorf("%w: SX needs VIP %d", d.ErrRefused, v.catalog.Policy.SX.VIPMin)
	}
	if err = s.debit(c, sc, a.PlayerID, b); err != nil {
		return nil, state, err
	}
	slots, state := v.catalog.DrawSX(state, main[selector-1], cd.NewStream(sc.Operation.Operation().Derive("summon.sx/v1", 0)))
	out := map[string]any{}
	itemID, amount := v.catalog.Juice(b)
	if out["result"], err = s.deliver(c, sc, a, v, slots, reward(itemID, amount, out)); err != nil {
		return nil, state, err
	}
	out["summon_info"] = info(&v.catalog, state, v.day)
	return out, state, nil
}

// reward answers the purchase's juice (D155) in out["reward"] and returns its grant; a zero amount pays nothing.
func reward(itemID, amount int64, out map[string]any) []grant.Line {
	if itemID <= 0 || amount <= 0 {
		return nil
	}
	out["reward"] = map[string]any{"item_id": itemID, "item_num": amount}
	return []grant.Line{{Kind: grant.StackItem, ItemID: itemID, Amount: amount}}
}

// deliver materializes the slots, settles their items with extra and records one SUMMON fact per slot.
func (s Mode) deliver(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, slots []d.Slot, extra []grant.Line) ([]any, error) {
	rows, lines, err := s.materialize(c, sc, a.PlayerID, &v.catalog, v.revision, slots)
	if err != nil {
		return nil, err
	}
	if err = s.settle(c, sc, a, "classic", append(lines, extra...)); err != nil {
		return nil, err
	}
	return rows, s.recordPull(c, sc, a, slots)
}

// recordPull is the purchase's one SUMMON fact (G9) in the settling transaction.
func (s Mode) recordPull(c context.Context, sc gen.TimedScope, a identity.ActorContext, slots []d.Slot) error {
	current := sc.Operation.Operation()
	return s.Facts.RecordTx(c, sc.Tx, current, objective.Fact{PlayerID: a.PlayerID, SourceDomain: "summon", SourceBusinessKey: current.ID.String(), Kind: SummonKind, Delta: int64(len(slots))})
}

// MagicPull is a 70 request: summon_time 1 or 10 for the stored Magic target partner_id.
type MagicPull struct {
	Times  int64
	Target int64
}

// magicType is the summon.lua row of Magic; summon_time 1 is index 1, 10 is index 2.
const magicType = 33

// Magic answers 70: byproduct items in result, the target's fragments in stick_items.
func (s Mode) Magic(c context.Context, a identity.ActorContext, q MagicPull, op operation.Context) (map[string]any, error) {
	return s.purchase(c, a, "magic", q, op, func(c context.Context, sc gen.TimedScope, v view, state d.State) (map[string]any, d.State, error) {
		index := map[int64]int64{1: 1, 10: 2}[q.Times]
		b, known := v.catalog.Button(magicType, index)
		stone, target := v.catalog.MagicFragment(q.Target)
		if !known || !target {
			return nil, state, d.ErrInvalid
		}
		if state.MagicTarget != q.Target {
			return nil, state, fmt.Errorf("%w: Magic target is not the stored one", d.ErrRefused)
		}
		if err := s.requireOwned(c, sc, a.PlayerID, q.Target); err != nil {
			return nil, state, err
		}
		if err := s.debit(c, sc, a.PlayerID, b); err != nil {
			return nil, state, err
		}
		slots, fragments := v.catalog.DrawMagic(b, cd.NewStream(sc.Operation.Operation().Derive("summon.magic/v1", 0)))
		rows, lines, err := s.materialize(c, sc, a.PlayerID, &v.catalog, v.revision, slots)
		if err != nil {
			return nil, state, err
		}
		out := map[string]any{"result": rows, "stick_items": []any{map[string]any{"item_id": stone, "item_num": fragments}}}
		itemID, amount := v.catalog.Juice(b)
		lines = append(append(lines, grant.Line{Kind: grant.StackItem, ItemID: stone, Amount: fragments}), reward(itemID, amount, out)...)
		if err = s.settle(c, sc, a, "magic", lines); err != nil {
			return nil, state, err
		}
		return out, state, s.recordPull(c, sc, a, slots)
	})
}

// SwitchMagic answers 71: the Magic target must be an owned Magic list hero.
func (s Mode) SwitchMagic(c context.Context, a identity.ActorContext, target int64, op operation.Context) (map[string]any, error) {
	return s.purchase(c, a, "magic-target", target, op, func(c context.Context, sc gen.TimedScope, v view, state d.State) (map[string]any, d.State, error) {
		if _, ok := v.catalog.MagicFragment(target); !ok {
			return nil, state, d.ErrInvalid
		}
		if err := s.requireOwned(c, sc, a.PlayerID, target); err != nil {
			return nil, state, err
		}
		state.MagicTarget = target
		return map[string]any{"partner_id": target}, state, nil
	})
}

func (s Mode) requireOwned(c context.Context, sc gen.TimedScope, pid identity.PlayerID, origin int64) error {
	owned, err := s.Heroes.OwnsOriginTx(c, sc.Tx, pid, origin)
	if err == nil && !owned {
		err = fmt.Errorf("%w: hero %d not owned", d.ErrRefused, origin)
	}
	return err
}

// VowsExchange is a 306 request.
type VowsExchange struct {
	TableID int64
	Times   int64
}

// maxVowsTimes bounds one exchange well inside int64 essence arithmetic.
const maxVowsTimes = 100000

// ExchangeVows answers 306: essence for scrolls of a Vows hero.
func (s Mode) ExchangeVows(c context.Context, a identity.ActorContext, q VowsExchange, op operation.Context) (map[string]any, error) {
	return s.purchase(c, a, "vows-exchange", q, op, func(c context.Context, sc gen.TimedScope, v view, state d.State) (map[string]any, d.State, error) {
		scroll, ok := v.catalog.VowsScroll(q.TableID)
		if !ok || q.Times < 1 || q.Times > maxVowsTimes {
			return nil, state, d.ErrInvalid
		}
		cost := i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: v.catalog.Vows.EssenceItemID, Amount: v.catalog.Vows.ScrollCost * q.Times}}}
		if _, err := s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, cost, sc.Operation.Operation()); err != nil {
			return nil, state, purchaseError(err)
		}
		if err := s.settle(c, sc, a, "vows-exchange", []grant.Line{{Kind: grant.StackItem, ItemID: scroll, Amount: q.Times}}); err != nil {
			return nil, state, err
		}
		return map[string]any{"awards": []any{map[string]any{"table_id": scroll, "item_num": q.Times}}}, state, nil
	})
}

func (s Mode) debit(c context.Context, sc gen.TimedScope, pid identity.PlayerID, b d.Button) error {
	cost := i5.MaterialCost{}
	if b.Mana > 0 {
		cost.Scalars = append(cost.Scalars, i5.ScalarMaterialCost{ResourceKey: "mana", Amount: b.Mana})
	}
	if b.Crystal > 0 {
		cost.Scalars = append(cost.Scalars, i5.ScalarMaterialCost{ResourceKey: "crystal", Amount: b.Crystal})
	}
	if b.ItemID > 0 {
		cost.Stacks = []i5.StackMaterialCost{{ItemID: b.ItemID, Amount: b.ItemNum}}
	}
	if len(cost.Scalars) == 0 && len(cost.Stacks) == 0 {
		return nil
	}
	_, err := s.Costs.DebitMaterialCostTx(c, sc.Tx, pid, cost, sc.Operation.Operation())
	return purchaseError(err)
}

// materialize creates new heroes in slot order; an owned hero (also one
// created earlier in the same pull) becomes its stone fragments (to_stone).
func (s Mode) materialize(c context.Context, sc gen.TimedScope, pid identity.PlayerID, catalog *d.Catalog, revision string, slots []d.Slot) ([]any, []grant.Line, error) {
	rows, lines := make([]any, 0, len(slots)), []grant.Line{}
	for _, slot := range slots {
		if slot.Kind == d.ItemKind {
			rows = append(rows, map[string]any{"table_id": slot.ItemID, "item_num": slot.ItemNum})
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: slot.ItemID, Amount: slot.ItemNum})
			continue
		}
		h, admission, err := s.Heroes.AwardStoryPartnerTx(c, sc.Tx, pid, slot.ItemID, revision, sc.Operation.Operation())
		if err != nil {
			return nil, nil, err
		}
		if admission == nil {
			stone, err := catalog.Fragments(slot.ItemID)
			if err != nil {
				return nil, nil, err
			}
			rows = append(rows, map[string]any{"table_id": stone[0], "item_num": stone[1], "to_stone": true})
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: stone[0], Amount: stone[1]})
			continue
		}
		row, err := s.HeroWire(h)
		if err != nil {
			return nil, nil, err
		}
		row["is_partner"] = true
		rows = append(rows, row)
	}
	return rows, lines, nil
}

func (s Mode) settle(c context.Context, sc gen.TimedScope, a identity.ActorContext, name string, lines []grant.Line) error {
	if len(lines) == 0 {
		return nil
	}
	current := sc.Operation.Operation()
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "summon", Operation: name, BusinessKey: "summon:" + name + ":" + current.ID.String(), Occurrence: current.ID.String(), PolicyVersion: d.PolicyID}, Lines: lines}
	_, err := s.Grants.SettleGrantTx(c, sc.Tx, a, plan, current, i5.GrantTxOptions{})
	return err
}

func purchaseError(err error) error {
	if errors.Is(err, economy.ErrInsufficientBalance) || errors.Is(err, economy.ErrUnknownResource) {
		return fmt.Errorf("%w: cost unavailable", d.ErrRefused)
	}
	return err
}

type view struct {
	catalog  d.Catalog
	revision string
	day      int64
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

// purchase binds admission, costs, heroes, state and the reply to one receipt;
// a retried or unknown COMMIT replays the stored reply without drawing again.
func (s Mode) purchase(c context.Context, a identity.ActorContext, name string, request any, op operation.Context, apply func(context.Context, gen.TimedScope, view, d.State) (map[string]any, d.State, error)) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "summon", Operation: name, SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	_, result, err := s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.Serializable}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		if err := s.Heroes.LockStoryRosterTx(c, sc.Tx, a.PlayerID); err != nil {
			return err
		}
		revision, _ := op.Policies.Get("content")
		catalog, err := s.catalog(c, sc.Tx, revision)
		if err != nil {
			return err
		}
		v := view{catalog: catalog, revision: revision, day: modes.Day(at)}
		state, err := s.Store.LockTx(c, sc.Tx, a.PlayerID, catalog.NewState(v.day), at)
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
		out, state, err = apply(c, sc, v, state)
		if err != nil {
			return err
		}
		if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, state, at); err != nil {
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
		r, err := receipt.New(sc.Operation.Operation(), id, "I9_3E_SUMMON", "gxb.summon.pull.v1", raw, fingerprint)
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
