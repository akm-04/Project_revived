package elementequipment

import (
	"context"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	elem "gxb.local/backend/v2/internal/domain/elementequipment"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"strconv"
	"time"
)

func (s Service) eligible(ctx context.Context, q tx.Queryer, p identity.PlayerID, id int64, rev string, at time.Time, op operation.Context) (bool, error) {
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, p, id)
	if e != nil {
		return false, e
	}
	if at.Before(h.UpdatedAt) {
		return false, ErrStale
	}
	if e = h.ValidatePersistent(); e != nil {
		return false, e
	}
	k, e := s.Content.HeroKindTx(ctx, q, rev, h.TableID)
	if e != nil {
		return false, e
	}
	level, e := s.Values.ReadProgressionTx(ctx, q, p)
	if e != nil {
		return false, e
	}
	if e = level.Validate(); e != nil {
		return false, e
	}
	if at.Before(level.UpdatedAt) {
		return false, ErrStale
	}
	rule, e := s.Content.ResolveProgressionPolicyTx(ctx, q, rev)
	if e != nil {
		return false, e
	}
	if e = rule.Validate(); e != nil {
		return false, e
	}
	if e = rule.ValidateState(level); e != nil {
		return false, elem.ErrUnqualified
	}
	if level.Level < rule.MaxLevel() {
		return false, nil
	}
	switch k {
	case character.NormalHero:
		if s.MaxHeroColor == nil {
			return false, ErrUnavailable
		}
		revision, ok := op.Policies.Get("element_max_hero_color")
		if !ok || revision != s.MaxHeroColor.MaxHeroColorPolicyRevision() {
			return false, ErrProof
		}
		max, e := s.MaxHeroColor.MaxHeroColorTx(ctx, q, p, op)
		if e != nil {
			return false, e
		}
		if max < 16 {
			return false, ErrUnavailable
		}
		if h.Color != 16 {
			return false, nil
		}
		for slot := int64(1); slot <= 6; slot++ {
			pos, e := s.Content.HeroEquipmentPositionTx(ctx, q, rev, h.TableID, h.Color, slot)
			if e != nil {
				return false, e
			}
			if e = pos.Validate(); e != nil {
				return false, e
			}
			if pos.OrdinaryEligible && h.Equipment[slot-1] == 0 {
				return false, nil
			}
		}
	case character.SuperHero:
		for i := range h.Equipment {
			if h.Equipment[i] < 21 {
				return false, nil
			}
			pos, e := s.Content.SuperEquipmentPositionTx(ctx, q, rev, h.TableID, int64(i+1))
			if e != nil {
				return false, e
			}
			if !pos.ItemID.Valid() {
				return false, elem.ErrUnqualified
			}
		}
	default:
		return false, elem.ErrUnqualified
	}
	return true, nil
}
func validateHeroFacts(f elem.HeroFacts, c elem.Catalog, h character.Hero) error {
	if e := f.Validate(c); e != nil {
		return e
	}
	ids := []int64{}
	for _, id := range f.Slots {
		if id > 0 {
			ids = append(ids, id)
		}
	}
	for id := range f.Backup {
		ids = append(ids, id)
	}
	for _, id := range ids {
		r, ok := c.Item(id)
		if !ok || (r.Partner > 0 && r.Partner != h.OriginTableID) {
			return elem.ErrUnqualified
		}
	}
	return nil
}
func material(m map[int64]int64) i5.MaterialCost {
	ids := []int64{}
	for id := range m {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	out := i5.MaterialCost{}
	for _, id := range ids {
		out.Stacks = append(out.Stacks, i5.StackMaterialCost{ItemID: id, Amount: m[id]})
	}
	return out
}
func lines(m map[int64]int64) []grant.Line {
	ids := []int64{}
	for id := range m {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	out := []grant.Line{}
	for _, id := range ids {
		out = append(out, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: m[id]})
	}
	return out
}
func (s Service) apply(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission) (map[string]any, error) {
	root, e := s.Owner.ReadRootTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	if d.DecisionAt.Before(root.UpdatedAt) {
		return nil, ErrStale
	}
	cat, e := s.Content.ElementCatalogTx(ctx, t, d.ContentRevision)
	if e != nil {
		return nil, e
	}
	if e = root.Facts.Validate(cat); e != nil {
		return nil, e
	}
	cmd := d.Command
	var f elem.HeroRoot
	var h character.Hero
	if cmd.PartnerID > 0 {
		h, e = s.Heroes.ReadHeroByPartnerIDTx(ctx, t, a.PlayerID, cmd.PartnerID)
		if e != nil {
			return nil, e
		}
		f, e = s.Owner.ReadHeroTx(ctx, t, a.PlayerID, cmd.PartnerID)
		if e != nil {
			return nil, e
		}
		if d.DecisionAt.Before(f.UpdatedAt) || d.DecisionAt.Before(h.UpdatedAt) {
			return nil, ErrStale
		}
		if e = validateHeroFacts(f.Facts, cat, h); e != nil {
			return nil, e
		}
	}
	if cmd.Family == Equip || cmd.Family == Enhance {
		eligible, e := s.eligible(ctx, t, a.PlayerID, cmd.PartnerID, d.ContentRevision, d.DecisionAt, d.Operation)
		if e != nil {
			return nil, e
		}
		if !eligible {
			return nil, elem.ErrInvalid
		}
	}
	st := f.Facts.Clone()
	cost := map[int64]int64{}
	refund := map[int64]int64{}
	item, ok := cat.Item(cmd.EquipID)
	if cmd.Family != Unload && !ok {
		return nil, elem.ErrInvalid
	}
	switch cmd.Family {
	case Equip:
		if (cmd.Position == 1 && item.Type == 1) || (cmd.Position > 1 && item.Type != 1) || (item.Partner > 0 && item.Partner != h.OriginTableID) {
			return nil, elem.ErrInvalid
		}
		for _, id := range st.Slots {
			if id == cmd.EquipID {
				return nil, elem.ErrInvalid
			}
		}
		lev, bound := st.Backup[cmd.EquipID]
		if bound {
			delete(st.Backup, cmd.EquipID)
		} else {
			cost[item.ItemID] = 1
		}
		i := cmd.Position - 1
		if old := st.Slots[i]; old > 0 {
			st.Backup[old] = st.Levels[i]
		}
		st.Slots[i] = cmd.EquipID
		st.Levels[i] = lev
	case Enhance:
		lev, found := st.Level(cmd.EquipID)
		if !found || lev >= 10 {
			return nil, elem.ErrInvalid
		}
		cost, e = cat.Materials(lev, item.Type, false)
		if e != nil {
			return nil, e
		}
		changed := false
		for i, id := range st.Slots {
			if id == cmd.EquipID {
				st.Levels[i]++
				changed = true
			}
		}
		if !changed {
			st.Backup[cmd.EquipID] = lev + 1
		}
	case Unload:
		i := cmd.Position - 1
		id := st.Slots[i]
		if id <= 0 {
			return nil, elem.ErrInvalid
		}
		st.Backup[id] = st.Levels[i]
		st.Slots[i] = 0
		st.Levels[i] = 0
	case DestroyBound:
		lev, found := st.Level(cmd.EquipID)
		if !found {
			return nil, elem.ErrInvalid
		}
		refund, e = cat.Materials(lev, item.Type, true)
		if e != nil {
			return nil, e
		}
		delete(st.Backup, cmd.EquipID)
		for i, id := range st.Slots {
			if id == cmd.EquipID {
				st.Slots[i] = 0
				st.Levels[i] = 0
			}
		}
	case DestroyBackpack:
		cost[item.ItemID] = 1
		refund, e = cat.Materials(0, item.Type, true)
		if e != nil {
			return nil, e
		}
	default:
		return nil, elem.ErrInvalid
	}
	if cmd.PartnerID > 0 {
		if e = validateHeroFacts(st, cat, h); e != nil {
			return nil, e
		}
	}
	op := d.Operation
	op.StartedAt = d.DecisionAt
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "elementequipment", Operation: cmd.Family, BusinessKey: strconv.FormatInt(int64(a.PlayerID), 10) + ":" + strconv.FormatInt(cmd.PartnerID, 10) + ":" + strconv.FormatInt(cmd.EquipID, 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: lines(refund)}
	// All effects are deterministic. Close the existing I5 plan before any canonical Element write.
	if len(cost) > 0 && len(refund) > 0 {
		p, e := s.Exchange.PrepareMaterialExchangeTx(ctx, t, a, i5.MaterialExchangeRequest{Cost: material(cost), Restoration: plan, AllowOverflowMail: true}, op)
		if e != nil {
			return nil, e
		}
		if _, e = s.Exchange.ApplyMaterialExchangeTx(ctx, t, p); e != nil {
			return nil, e
		}
	} else if len(cost) > 0 {
		p, e := s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, material(cost), op)
		if e != nil {
			return nil, e
		}
		if _, e = s.Costs.ApplyMaterialDebitTx(ctx, t, p); e != nil {
			return nil, e
		}
	} else if len(refund) > 0 {
		if _, e = s.Grants.SettleGrantTx(ctx, t, a, plan, op, i5.GrantTxOptions{AllowOverflowMail: true}); e != nil {
			return nil, e
		}
	}
	body := map[string]any{}
	if cmd.PartnerID > 0 {
		old := f.Version
		f.Facts = st
		f.Version++
		f.UpdatedAt = d.DecisionAt
		if e = s.Owner.SaveHeroTx(ctx, t, f, old); e != nil {
			return nil, e
		}
		body = st.Pipe()
	}
	old := root.Version
	root.Version++
	root.UpdatedAt = d.DecisionAt
	if e = s.Owner.SaveRootTx(ctx, t, root, old); e != nil {
		return nil, e
	}
	return body, nil
}
