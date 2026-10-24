package dormhouse

import (
	"context"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"strconv"
	"time"
)

// apply runs after the complete Character/Dorm prefix. All source/value plans
// are prepared before the first mutation; all effects and the outer receipt
// commit together. Root500 serializes every room/membership/equipment change.
func (s Service) apply(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission) (map[string]any, error) {
	c := d.Command
	at := d.DecisionAt
	catalog, e := s.Content.DormCatalogTx(ctx, t, d.ContentRevision)
	if e != nil {
		return nil, e
	}
	root, e := s.Owner.ReadRootTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	if at.Before(root.UpdatedAt) {
		return nil, ErrStale
	}
	rooms, e := s.Owner.ListRoomsTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	heroes, e := s.Heroes.ListHeroesTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	hm := map[int64]character.Hero{}
	facts := map[int64]dorm.HeroFacts{}
	for _, h := range heroes {
		rule, e := s.Content.HeroTemplateProgressionTx(ctx, t, d.ContentRevision, h.TableID)
		if e != nil {
			return nil, e
		}
		h.Kind = rule.Kind
		hm[h.PartnerID] = h
		f, e := s.Owner.ReadHeroTx(ctx, t, h.Ref())
		if e != nil {
			return nil, e
		}
		if at.Before(h.UpdatedAt) || at.Before(f.UpdatedAt) {
			return nil, ErrStale
		}
		facts[h.PartnerID] = f
	}
	for _, r := range rooms {
		for _, p := range r.Residents {
			if _, ok := hm[p]; !ok {
				return nil, ErrRetired
			}
		}
	}
	values, e := s.Values.ReadDormPlayerStateTx(ctx, t, a.PlayerID, at)
	if c.Family != Exchange {
		values, e = s.Values.LockDormPlayerStateTx(ctx, t, a.PlayerID, at)
	}
	if e != nil {
		return nil, e
	}
	if _, ok := values.Functions[71]; !ok {
		return nil, dorm.ErrUnqualified
	}
	body := map[string]any{}
	mutated := false
	room := rooms[c.HouseID]
	if c.Family != Open && c.Family != Exchange && room.ID == 0 {
		return nil, dorm.ErrInvalidFacts
	}
	if room.ID != 0 && at.Before(room.UpdatedAt) {
		return nil, ErrStale
	}
	cost := i5.MaterialCost{}
	var plan *dorm.ResidentPlan
	var opened dorm.Room
	var nextRoot dorm.Root
	var layout dorm.LayoutResult
	var equipPartner, equipItem int64
	switch c.Family {
	case Open:
		key, ok := catalog.Keys[c.ItemID]
		if !ok {
			return nil, dorm.ErrUnqualified
		}
		if _, ok = values.Functions[70+key.MainType]; !ok {
			return nil, dorm.ErrUnqualified
		}
		table, e := catalog.SelectRoom(c.ItemID, d.Operation)
		if e != nil {
			return nil, e
		}
		nextRoot, opened, e = catalog.NewRoom(root, rooms, table, c.Floor, c.Position, d.ContentRevision, at)
		if e != nil {
			return nil, e
		}
		cost.Stacks = []i5.StackMaterialCost{{ItemID: c.ItemID, Amount: 1}}
	case Save:
		layout, e = catalog.ValidateLayout(room.TableID, room.ExpansionLevel, c.Furniture)
		if e != nil {
			return nil, e
		}
		if int64(len(room.Residents)) > layout.FreeResidentCells {
			return nil, dorm.ErrInvalidLayout
		}
		// Stock is total including placed furniture. Validate the whole owner's
		// graph, replacing only this room, while sharing economy700 with reductions.
		stacks, e := s.Values.ListStacksTx(ctx, t, a.PlayerID)
		if e != nil {
			return nil, e
		}
		qty := map[int64]int64{}
		for _, x := range stacks {
			qty[x.ItemID] = x.Quantity
		}
		used := map[int64]int64{}
		for id, r := range rooms {
			v := layout
			if id != room.ID {
				v, e = catalog.ValidateLayout(r.TableID, r.ExpansionLevel, r.Layout)
				if e != nil {
					return nil, e
				}
			}
			for item, n := range v.InventoryMinimum {
				if used[item] > (1<<63-1)-n {
					return nil, dorm.ErrInvalidFacts
				}
				used[item] += n
			}
		}
		for item, n := range used {
			if qty[item] < n {
				return nil, dorm.ErrInUse
			}
		}
	case Equip:
		if room.MainType == dorm.LoungeType || len(room.Residents) != 1 {
			return nil, dorm.ErrInvalidFacts
		}
		equipPartner = room.Residents[0]
		h := hm[equipPartner]
		f := facts[equipPartner]
		if c.Index > h.Star {
			return nil, dorm.ErrInvalidFacts
		}
		if h.Color < 16 && h.Kind != character.SuperHero {
			return nil, dorm.ErrInvalidFacts
		}
		rule, ok := catalog.Equipment[h.TableID]
		if !ok {
			return nil, dorm.ErrUnqualified
		}
		equipItem = rule.Items[c.Index-1]
		lev, ok := catalog.EquipmentLevel[equipItem]
		if !ok || lev > h.Level {
			return nil, dorm.ErrInvalidFacts
		}
		if f.Equipment[c.Index-1] == 0 {
			cost.Stacks = []i5.StackMaterialCost{{ItemID: equipItem, Amount: 1}}
		}
	case Enter:
		desired := append([]int64(nil), c.Partners...)
		for _, p := range desired {
			if _, ok := hm[p]; !ok {
				return nil, ErrRetired
			}
		}
		v, e := catalog.ValidateLayout(room.TableID, room.ExpansionLevel, room.Layout)
		if e != nil {
			return nil, e
		}
		if int64(len(desired)) > v.FreeResidentCells {
			return nil, dorm.ErrInvalidLayout
		}
		rp, e := catalog.PlanResidents(rooms, c.HouseID, desired, at)
		if e != nil {
			return nil, e
		}
		plan = &rp
	case Start:
		if room.MainType != 4 || room.Pending != nil {
			return nil, dorm.ErrInvalidFacts
		}
		x, ok := catalog.Expansions[room.ExpansionLevel+1]
		if !ok {
			return nil, dorm.ErrInvalidFacts
		}
		for i, item := range x.CostItems {
			cost.Stacks = append(cost.Stacks, i5.StackMaterialCost{ItemID: item, Amount: x.CostCounts[i]})
		}
	case Finish:
		if room.Pending != nil {
			price, _, e := room.Pending.FinishPrice(at)
			if e != nil {
				return nil, e
			}
			if price > 0 {
				cost.Scalars = []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: price}}
			}
		}
	case Exchange:
		// The client explicitly lists green/blue fixed and random keys.
		key, ok := catalog.Keys[c.ItemID]
		if !ok || len(key.Templates) == 0 {
			return nil, dorm.ErrUnqualified
		}
		// Source item quality is qualified by the compiled exchange list below.
		rate, ok := catalog.ExchangeRates[c.ItemID]
		if !ok || c.Amount > (1<<63-1)/rate {
			return nil, dorm.ErrInvalidFacts
		}
		req := i5.MaterialExchangeRequest{Cost: i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: c.ItemID, Amount: c.Amount}}}, Restoration: grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "dorm-house", Operation: Exchange, BusinessKey: strconv.FormatInt(int64(a.PlayerID), 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50005167, Amount: rate * c.Amount}}}, AllowOverflowMail: true}
		op := d.Operation
		op.StartedAt = at
		p, e := s.Exchange.PrepareMaterialExchangeTx(ctx, t, a, req, op)
		if e != nil {
			return nil, e
		}
		result, e := s.Exchange.ApplyMaterialExchangeTx(ctx, t, p)
		if e != nil {
			return nil, e
		}
		return map[string]any{"awards": result.Restoration.Awards}, nil
	}
	// Prepare acquires the whole I5 suffix without writing. At this point no
	// Character, Dorm or economy mutation has happened.
	var debit *i5.PreparedMaterialDebit
	if len(cost.Stacks)+len(cost.Scalars) > 0 {
		op := d.Operation
		op.StartedAt = at
		debit, e = s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, cost, op)
		if e != nil {
			return nil, e
		}
	}
	if debit != nil {
		result, e := s.Costs.ApplyMaterialDebitTx(ctx, t, debit)
		if e != nil {
			return nil, e
		}
		for _, x := range result.Scalars {
			body[x.ResourceKey] = x.Amount
		}
	}
	touchRoom := func(r dorm.Room) error {
		old := r.StateVersion
		r.StateVersion++
		r.UpdatedAt = at
		rooms[r.ID] = r
		return s.Owner.SaveRoomTx(ctx, t, r, old)
	}
	switch c.Family {
	case Open:
		mutated = true
		if e = s.Owner.InsertRoomTx(ctx, t, opened); e != nil {
			return nil, e
		}
		rooms[opened.ID] = opened
		root = nextRoot
		room = opened
	case Save:
		if reflect.DeepEqual(room.Layout, c.Furniture) {
			break
		}
		mutated = true
		if room.MainType == dorm.LoungeType {
			if e = s.settleLounge(ctx, t, room, hm, facts, values.Level, d.ContentRevision, at, body); e != nil {
				return nil, e
			}
		}
		room.Layout = c.Furniture
		room.Comfort = layout.Comfort
		if e = touchRoom(room); e != nil {
			return nil, e
		}
		room = rooms[room.ID]
	case Equip:
		f := facts[equipPartner]
		if f.Equipment[c.Index-1] == 0 {
			mutated = true
			old := f.StateVersion
			f.StateVersion++
			f.Equipment[c.Index-1] = 1
			f.UpdatedAt = at
			if e = s.Owner.SaveHeroTx(ctx, t, f, old); e != nil {
				return nil, e
			}
			facts[equipPartner] = f
		}
	case Enter:
		mutated = len(plan.ChangedRooms) > 0
		// Settlement observes the old Lounge comfort and old membership. Apply the
		// membership plan only afterward, retaining fractions across departures.
		if len(plan.Assignments) > 0 {
			for _, r := range rooms {
				if r.MainType == dorm.LoungeType {
					if e = s.settleLounge(ctx, t, r, hm, facts, values.Level, d.ContentRevision, at, body); e != nil {
						return nil, e
					}
				}
			}
		}
		for p, destination := range plan.Assignments {
			f := facts[p]
			old := f.StateVersion
			f.StateVersion++
			f.HouseID = destination
			f.UpdatedAt = at
			f.LoungeAnchor = time.Time{}
			if destination != 0 && rooms[destination].MainType == dorm.LoungeType {
				f.LoungeAnchor = at
			}
			if e = s.Owner.SaveHeroTx(ctx, t, f, old); e != nil {
				return nil, e
			}
			facts[p] = f
		}
		changed := []any{}
		for _, id := range plan.ChangedRooms {
			r := plan.Rooms[id]
			if e = s.Owner.SaveRoomTx(ctx, t, r, rooms[id].StateVersion); e != nil {
				return nil, e
			}
			rooms[id] = r
			changed = append(changed, roomWire(r, hm, facts))
		}
		body["changed_houses"] = changed
		room = rooms[room.ID]
	case Start:
		mutated = true
		x := catalog.Expansions[room.ExpansionLevel+1]
		room.Pending = &dorm.Expansion{Occurrence: d.Operation.ID.String(), ContentRevision: d.ContentRevision, NextLevel: x.Level, DurationSeconds: x.DurationSeconds, StartedAt: at.Truncate(time.Second)}
		if e = touchRoom(room); e != nil {
			return nil, e
		}
		room = rooms[room.ID]
	case Finish:
		if room.Pending != nil {
			mutated = true
			if _, e = s.Content.DormCatalogTx(ctx, t, room.Pending.ContentRevision); e != nil {
				return nil, e
			}
			room.ExpansionLevel = room.Pending.NextLevel
			room.Pending = nil
			if e = touchRoom(room); e != nil {
				return nil, e
			}
			room = rooms[room.ID]
		}
	}
	if c.Family != Open && mutated {
		old := root.StateVersion
		root.StateVersion++
		root.UpdatedAt = at
		if e = s.Owner.SaveRootTx(ctx, t, root, old); e != nil {
			return nil, e
		}
	} else if c.Family == Open {
		if e = s.Owner.SaveRootTx(ctx, t, root, root.StateVersion-1); e != nil {
			return nil, e
		}
	}
	body["house_info"] = roomWire(room, hm, facts)
	changed := map[string]any{}
	for _, h := range heroes {
		f := facts[h.PartnerID]
		changed[strconv.FormatInt(h.PartnerID, 10)] = heroWire(f, rooms)
	}
	body["changed_heroes"] = changed
	return body, nil
}
func (s Service) settleLounge(ctx context.Context, t tx.Tx, r dorm.Room, heroes map[int64]character.Hero, facts map[int64]dorm.HeroFacts, level int64, rev string, at time.Time, body map[string]any) error {
	exp := []any{}
	for _, p := range r.Residents {
		h, ok := heroes[p]
		if !ok {
			return ErrRetired
		}
		f := facts[p]
		if f.HouseID != r.ID {
			return dorm.ErrInvalidFacts
		}
		v, e := dorm.SettleLounge(f.LoungeAnchor, at, f.LoungeFraction, r.Comfort)
		if e != nil {
			return e
		}
		next, cap, e := s.EXP.ApplyDormEXPLockedTx(ctx, t, h.Ref(), v.WholeEXP, level, rev, at)
		if e != nil {
			return e
		}
		old := f.StateVersion
		f.StateVersion++
		f.UpdatedAt = at
		f.LoungeAnchor = v.Anchor
		f.LoungeFraction = v.Fraction
		if cap {
			f.LoungeFraction = 0
		}
		if e = s.Owner.SaveHeroTx(ctx, t, f, old); e != nil {
			return e
		}
		facts[p] = f
		heroes[p] = next
		exp = append(exp, map[string]any{"partner_id": p, "exp": next.Exp})
	}
	body["exp_partners"] = exp
	return nil
}
