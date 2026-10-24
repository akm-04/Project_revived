package spirit

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

func (s Service) eligible(ctx context.Context, q tx.Queryer, p identity.PlayerID, rev string, at time.Time) (bool, error) {
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
	if e = rule.ValidateState(level); e != nil {
		return false, d.ErrUnqualified
	}
	fp, e := s.Content.ResolveFunctionGatePolicyTx(ctx, q, rev)
	if e != nil {
		return false, e
	}
	qualified := false
	for _, g := range fp.Gates {
		if g.FunctionID == 99 {
			if g.GateKind != "PURE_LEVEL" || g.RequiredLevel != 60 || g.AnnouncementCapability != "NONE" {
				return false, d.ErrUnqualified
			}
			qualified = true
		}
	}
	if !qualified {
		return false, d.ErrUnqualified
	}
	if level.Level < 60 {
		return false, nil
	}
	fact, ok, e := s.Values.ReadSpiritFunctionEligibilityTx(ctx, q, p)
	if e != nil {
		return false, e
	}
	if !ok {
		return false, d.ErrUnqualified
	}
	if fact.PlayerID != p || fact.FunctionID != 99 || len(fact.ContentRevision) != 64 || fact.SourceFactKey == "" || fact.EligibleAt.IsZero() || at.Before(fact.EligibleAt) {
		return false, d.ErrUnqualified
	}
	return true, nil
}
func (s Service) liveHero(ctx context.Context, q tx.Queryer, p identity.PlayerID, id int64, rev string, at time.Time) error {
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, p, id)
	if e != nil {
		return e
	}
	if e = h.ValidatePersistent(); e != nil {
		return e
	}
	if at.Before(h.UpdatedAt) {
		return ErrStale
	}
	k, e := s.Content.HeroKindTx(ctx, q, rev, h.TableID)
	if e != nil {
		return e
	}
	if k != character.NormalHero && k != character.SuperHero {
		return d.ErrUnqualified
	}
	return nil
}
func (s Service) apply(ctx context.Context, t tx.Tx, a identity.ActorContext, ad Admission) (map[string]any, error) {
	root, e := s.Owner.ReadRootTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	if ad.DecisionAt.Before(root.UpdatedAt) {
		return nil, ErrStale
	}
	cat, e := s.Content.SpiritCatalogTx(ctx, t, ad.ContentRevision)
	if e != nil {
		return nil, e
	}
	if e = root.Facts.Validate(cat); e != nil {
		return nil, e
	}
	fs, e := s.Owner.ListHeroFacetsTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	owners, e := root.Facts.ValidateBindings(cat, fs)
	if e != nil {
		return nil, e
	}
	cmd := ad.Command
	if cmd.Family == Enhance || cmd.Family == Save || cmd.Family == Apply || cmd.Family == Equip && cmd.SpiritID > 0 {
		ok, e := s.eligible(ctx, t, a.PlayerID, ad.ContentRevision, ad.DecisionAt)
		if e != nil {
			return nil, e
		}
		if !ok {
			return nil, d.ErrInvalid
		}
	}
	indexes := map[int64]int{}
	for i, f := range fs {
		indexes[f.PartnerID] = i
		if ad.DecisionAt.Before(f.UpdatedAt) {
			return nil, ErrStale
		}
	}
	if cmd.PartnerID > 0 {
		if e = s.liveHero(ctx, t, a.PlayerID, cmd.PartnerID, ad.ContentRevision, ad.DecisionAt); e != nil {
			return nil, e
		}
		if _, ok := indexes[cmd.PartnerID]; !ok {
			return nil, d.ErrUnqualified
		}
	}
	state := root.Facts.Clone()
	changed := map[int64]bool{}
	body := map[string]any{}
	cost := int64(0)
	switch cmd.Family {
	case Lock, Unlock:
		x, ok := state.Instances[cmd.SpiritID]
		if !ok {
			return nil, d.ErrInvalid
		}
		x.Locked = cmd.Family == Lock
		state.Instances[x.ID] = x
	case Equip:
		i := indexes[cmd.PartnerID]
		if cmd.SpiritID > 0 {
			x, ok := state.Instances[cmd.SpiritID]
			if !ok {
				return nil, d.ErrInvalid
			}
			m, _, e := cat.ModelFor(x.TemplateID)
			if e != nil {
				return nil, e
			}
			if m.Position != cmd.Position || owners[x.ID] > 0 && owners[x.ID] != cmd.PartnerID {
				return nil, d.ErrInvalid
			}
		}
		fs[i].Facts.Slots[cmd.Position-1] = cmd.SpiritID
		changed[cmd.PartnerID] = true
		body["spirit_equip"] = fs[i].Facts.Slots
	case AllOff:
		i := indexes[cmd.PartnerID]
		fs[i].Facts.Slots = [6]int64{}
		changed[cmd.PartnerID] = true
		body["spirit_equip"] = fs[i].Facts.Slots
	case Save:
		if e = state.ValidateSlots(cat, cmd.Slots, true); e != nil {
			return nil, e
		}
		id := cmd.ProgramID
		for _, p := range state.Programs {
			if p.Name == cmd.Name && p.ID != id {
				if id == 0 && p.Slots == cmd.Slots {
					body["id"] = p.ID
					return body, nil
				}
				return nil, d.ErrInvalid
			}
		}
		if id == 0 {
			if len(state.Programs) >= int(cat.ProgramLimit) || state.NextProgramID >= d.MaxID {
				return nil, d.ErrInvalid
			}
			id = state.NextProgramID
			state.NextProgramID++
		} else {
			if _, ok := state.Programs[id]; !ok {
				return nil, d.ErrInvalid
			}
		}
		state.Programs[id] = d.Program{ID: id, Name: cmd.Name, Slots: cmd.Slots}
		body["id"] = id
	case Delete:
		delete(state.Programs, cmd.ProgramID)
	case Apply:
		p, ok := state.Programs[cmd.ProgramID]
		if !ok {
			return nil, d.ErrInvalid
		}
		selected := map[int64]bool{}
		for _, id := range p.Slots {
			if id > 0 {
				selected[id] = true
			}
		}
		for i := range fs {
			if fs[i].PartnerID == cmd.PartnerID {
				continue
			}
			for j, id := range fs[i].Facts.Slots {
				if selected[id] {
					if e = s.liveHero(ctx, t, a.PlayerID, fs[i].PartnerID, ad.ContentRevision, ad.DecisionAt); e != nil {
						return nil, e
					}
					fs[i].Facts.Slots[j] = 0
					changed[fs[i].PartnerID] = true
				}
			}
		}
		fs[indexes[cmd.PartnerID]].Facts.Slots = p.Slots
		changed[cmd.PartnerID] = true
	case Enhance:
		if s.Milestones == nil {
			return nil, ErrUnavailable
		}
		roll, ok := ad.Operation.Policies.Get("spirit_roll")
		if !ok || roll != s.Milestones.Revision() || roll != d.ReconstructionPolicy {
			return nil, ErrUnavailable
		}
		target, ok := state.Instances[cmd.SpiritID]
		if !ok {
			return nil, d.ErrInvalid
		}
		fodder := []d.Instance{}
		for _, id := range cmd.SpiritIDs {
			x, ok := state.Instances[id]
			if !ok || x.Locked || owners[id] > 0 || state.ReferenceCount(id) > 0 {
				return nil, d.ErrInvalid
			}
			fodder = append(fodder, x)
		}
		var updated d.Instance
		updated, _, cost, e = cat.Enhancement(target, fodder, s.Milestones, ad.Operation)
		if e != nil {
			return nil, e
		}
		for _, id := range cmd.SpiritIDs {
			delete(state.Instances, id)
		}
		state.Instances[target.ID] = updated
		body, e = updated.Wire(cat, owners[target.ID], state.ReferenceCount(target.ID))
		if e != nil {
			return nil, e
		}
	default:
		return nil, d.ErrInvalid
	}
	if e = state.Validate(cat); e != nil {
		return nil, e
	}
	if _, e = state.ValidateBindings(cat, fs); e != nil {
		return nil, e
	}
	if cost > 0 {
		op := ad.Operation
		op.StartedAt = ad.DecisionAt
		p, e := s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "mana", Amount: cost}}}, op)
		if e != nil {
			return nil, e
		}
		if _, e = s.Costs.ApplyMaterialDebitTx(ctx, t, p); e != nil {
			return nil, e
		}
	}
	ids := []int64{}
	for id := range changed {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, id := range ids {
		f := fs[indexes[id]]
		old := f.Version
		f.Version++
		f.UpdatedAt = ad.DecisionAt
		if e = s.Owner.SaveHeroTx(ctx, t, f, old); e != nil {
			return nil, e
		}
	}
	old := root.Version
	root.Facts = state
	root.Version++
	root.UpdatedAt = ad.DecisionAt
	if e = s.Owner.SaveRootTx(ctx, t, root, old); e != nil {
		return nil, e
	}
	return body, nil
}
