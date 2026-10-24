package inscription

import (
	"context"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	ins "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sort"
	"strconv"
	"time"
)

func (s Service) eligible(ctx context.Context, q tx.Queryer, p identity.PlayerID, id int64, rev string, at time.Time) (bool, error) {
	e, err := s.Eligibility.InscriptionEligibilityTx(ctx, q, p, id, rev, at)
	if err != nil {
		return false, err
	}
	pop, err := s.Heroes.ReadRootTx(ctx, q, p)
	if err != nil {
		return false, err
	}
	h, err := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, p, id)
	if err != nil {
		return false, err
	}
	if at.Before(h.UpdatedAt) || at.Before(pop.UpdatedAt) {
		return false, ErrStale
	}
	kind, err := s.Content.HeroKindTx(ctx, q, rev, h.TableID)
	if err != nil {
		return false, err
	}
	if !e.Qualified || e.ProviderRevision == "" || e.Player != p || e.PartnerID != id || e.PopulationVersion != pop.StateVersion || e.HeroVersion != h.StateVersion || e.ContentRevision != rev || !e.ObservedAt.Equal(at) || e.Kind != kind || e.Level != h.Level || e.RawStage < 0 || e.RawStage > 3 {
		return false, ins.ErrUnqualified
	}
	return (kind == character.NormalHero || kind == character.SuperHero) && e.RawStage == 3 && e.Level >= 100, nil
}
func (s Service) globalEligibility(ctx context.Context, q tx.Queryer, p identity.PlayerID, rev string, at time.Time) error {
	hs, e := s.Heroes.ListHeroesTx(ctx, q, p)
	if e != nil {
		return e
	}
	for _, h := range hs {
		ok, e := s.eligible(ctx, q, p, h.PartnerID, rev, at)
		if e != nil {
			return e
		}
		if ok {
			return nil
		}
	}
	return ins.ErrInvalid
}
func (s Service) apply(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission) (map[string]any, error) {
	cmd, at := d.Command, d.DecisionAt
	r, e := s.Owner.ReadRootTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	if at.Before(r.UpdatedAt) {
		return nil, ErrStale
	}
	c, e := s.Content.InscriptionCatalogTx(ctx, t, d.ContentRevision)
	if e != nil {
		return nil, e
	}
	if e = r.Facts.Validate(c); e != nil {
		return nil, e
	}
	before := r.Facts.Clone()
	st := before.Clone()
	var f ins.HeroRoot
	if cmd.PartnerID > 0 {
		f, e = s.Owner.ReadHeroTx(ctx, t, a.PlayerID, cmd.PartnerID)
		if e != nil {
			return nil, e
		}
		if at.Before(f.UpdatedAt) {
			return nil, ErrStale
		}
		if e = f.Facts.Validate(c); e != nil {
			return nil, e
		}
	}
	oldHero := f.Facts
	if cmd.Family == Make || cmd.Family == Rebuild {
		if e = s.globalEligibility(ctx, t, a.PlayerID, d.ContentRevision, at); e != nil {
			return nil, e
		}
	}
	if cmd.Family == Insert {
		ok, e := s.eligible(ctx, t, a.PlayerID, cmd.PartnerID, d.ContentRevision, at)
		if e != nil {
			return nil, e
		}
		if !ok {
			return nil, ins.ErrInvalid
		}
	}
	xs, e := s.Values.ListStacksTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	stock := map[int64]int64{}
	for _, x := range xs {
		if e = x.Validate(); e != nil {
			return nil, e
		}
		stock[x.ItemID] = x.Quantity
	}
	cost := i5.MaterialCost{}
	support := []grant.Line{}
	credits := []grant.Line{}
	body := map[string]any{}
	scalarCost := func(k string, n int64) {
		if n > 0 {
			cost.Scalars = append(cost.Scalars, i5.ScalarMaterialCost{ResourceKey: k, Amount: n})
		}
	}
	stackCost := func(id, n int64) {
		if n > 0 {
			cost.Stacks = append(cost.Stacks, i5.StackMaterialCost{ItemID: id, Amount: n})
		}
	}
	stackCredit := func(id, n int64) {
		if id > 0 && n > 0 {
			l := grant.Line{Kind: grant.StackItem, ItemID: id, Amount: n}
			support = append(support, l)
			credits = append(credits, l)
		}
	}
	var family ins.Family
	var randomLane string
	switch cmd.Family {
	case Make:
		var ok bool
		family, ok = c.Family(cmd.FamilyID)
		if !ok || family.Special != 0 || ins.Certificate(family.Certificate) == "" {
			return nil, ins.ErrInvalid
		}
		scalarCost(ins.Certificate(family.Certificate), family.Compound)
		stackCost(family.Heart, family.Hearts)
		randomLane = "forge"
		for _, id := range c.Support(family) {
			support = append(support, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: 1})
		}
	case Rebuild:
		it, ok := c.Item(cmd.ItemID)
		if !ok {
			return nil, ins.ErrInvalid
		}
		family, ok = c.Family(it.Family)
		if !ok || family.Special != 0 || stock[cmd.ItemID] < 1 {
			return nil, ins.ErrInvalid
		}
		if cmd.CostType == 1 {
			scalarCost("crystal", family.Crystal*cmd.Amount)
		} else {
			scalarCost("mana", family.Mana*cmd.Amount)
		}
		randomLane = "reforge"
	case Insert:
		it, ok := c.Item(cmd.ItemID)
		if !ok || it.Position < 1 || it.Position > 3 {
			return nil, ins.ErrInvalid
		}
		old := f.Facts.Slots[it.Position-1]
		if old != cmd.ReplaceID || old == cmd.ItemID {
			return nil, ins.ErrInvalid
		}
		stackCost(cmd.ItemID, 1)
		stackCredit(old, 1)
		f.Facts.Slots[it.Position-1] = cmd.ItemID
	case Remove:
		it, ok := c.Item(cmd.ItemID)
		if !ok || it.Position < 1 || it.Position > 3 || f.Facts.Slots[it.Position-1] != cmd.ItemID {
			return nil, ins.ErrInvalid
		}
		scalarCost("crystal", c.RemoveCost())
		stackCredit(cmd.ItemID, 1)
		f.Facts.Slots[it.Position-1] = 0
	case Resolve:
		it, ok := c.Item(cmd.ItemID)
		if !ok {
			return nil, ins.ErrInvalid
		}
		fam, _ := c.Family(it.Family)
		k := ins.Certificate(fam.ResolveCertificate)
		if k == "" || fam.Resolve <= 0 {
			return nil, ins.ErrUnqualified
		}
		stackCost(cmd.ItemID, cmd.Amount)
		l := grant.Line{Kind: grant.ScalarCurrency, ResourceKey: k, Amount: fam.Resolve * cmd.Amount}
		support = append(support, l)
		credits = append(credits, l)
	case Save:
		p := st.Pending
		if p == nil {
			return nil, ins.ErrInvalid
		}
		valid := false
		for _, id := range p.Candidates {
			valid = valid || id == cmd.ItemID
		}
		if !valid {
			return nil, ins.ErrInvalid
		}
		// Frozen pending remains bound to its exact revision/policy. No reroll during Save.
		if p.Revision != d.ContentRevision || p.Policy != ins.Policy {
			return nil, ins.ErrUnqualified
		}
		if stock[p.Source] < 1 {
			st.Pending = nil
			body["_rejected"] = "stale rebuild source"
			break
		}
		stackCost(p.Source, 1)
		stackCredit(cmd.ItemID, 1)
		body["rebuild_items"] = []map[string]any{{"table_id": cmd.ItemID, "item_num": int64(1)}}
		st.Pending = nil
	case Abandon:
		st.Pending = nil
	case Exchange:
		totals := map[string]int64{}
		ids := []int64{}
		for id := range c.Exchange() {
			ids = append(ids, id)
		}
		sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
		for _, id := range ids {
			n := stock[id]
			if n == 0 {
				continue
			}
			if n < 0 || n > 999 {
				return nil, ins.ErrUnqualified
			}
			v := c.Exchange()[id]
			if v[1] <= 0 {
				return nil, ins.ErrUnqualified
			}
			stackCost(id, n)
			totals[ins.Certificate(v[0])] += n * v[1]
		}
		changes := []map[string]int64{}
		keys := []string{}
		for k := range totals {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			l := grant.Line{Kind: grant.ScalarCurrency, ResourceKey: k, Amount: totals[k]}
			support = append(support, l)
			credits = append(credits, l)
			currency := map[string]int64{"degree_cer": 19, "graduate_cer": 20, "patent_cer": 21}[k]
			changes = append(changes, map[string]int64{"currency": currency, "change": totals[k]})
		}
		if len(changes) > 0 {
			body["currency_change"] = changes
		}
	default:
		return nil, ins.ErrInvalid
	}
	var prepared *i5.PreparedInscriptionValue
	valueop := d.Operation
	valueop.StartedAt = at
	if len(cost.Scalars)+len(cost.Stacks)+len(support) > 0 {
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "inscription", Operation: cmd.Family, BusinessKey: strconv.FormatInt(int64(a.PlayerID), 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: support}
		prepared, e = s.ValuePlans.PrepareInscriptionValueTx(ctx, t, a, i5.InscriptionValueRequest{Cost: cost, Support: plan}, valueop)
		if e != nil {
			return nil, e
		}
	}
	if randomLane != "" {
		// Preparation above validates affordability and the complete value lock union before draws.
		draws := []int64{}
		misses := st.ForgeMisses
		exclude := int64(0)
		n := int64(1)
		if randomLane == "reforge" {
			misses = st.ReforgeMisses
			exclude = cmd.ItemID
			n = cmd.Amount
		}
		for i := int64(0); i < n; i++ {
			id, next, e := c.Draw(family, randomLane, misses, exclude, d.Operation, uint64(i))
			if e != nil {
				return nil, e
			}
			draws = append(draws, id)
			misses = next
		}
		body["inscript_items"] = draws
		if randomLane == "forge" {
			st.ForgeMisses = misses
			credits = []grant.Line{{Kind: grant.StackItem, ItemID: draws[0], Amount: 1}}
		} else {
			st.ReforgeMisses = misses
			st.Generation++
			st.Pending = &ins.Pending{Source: cmd.ItemID, Candidates: draws, Generation: st.Generation, Revision: d.ContentRevision, Policy: ins.Policy, Operation: d.Operation.ID.String(), Entropy: d.Operation.EntropySeed, CreatedAt: at}
		}
	}
	if prepared != nil {
		if _, e = s.ValuePlans.ApplyInscriptionValueTx(ctx, t, prepared, credits); e != nil {
			return nil, e
		}
	}
	if e = st.Validate(c); e != nil {
		return nil, e
	}
	if e = f.Facts.Validate(c); e != nil {
		return nil, e
	}
	if !reflect.DeepEqual(before, st) {
		old := r.Version
		r.Version++
		r.Facts = st
		r.UpdatedAt = at
		if e = s.Owner.SaveRootTx(ctx, t, r, old); e != nil {
			return nil, e
		}
	}
	if cmd.PartnerID > 0 && !reflect.DeepEqual(oldHero, f.Facts) {
		old := f.Version
		f.Version++
		f.UpdatedAt = at
		if e = s.Owner.SaveHeroTx(ctx, t, f, old); e != nil {
			return nil, e
		}
	}
	if cmd.Family == Insert || cmd.Family == Remove {
		body["inscript_items"] = f.Facts.Wire()
	}
	return body, nil
}
