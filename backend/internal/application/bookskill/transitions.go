package bookskill

import (
	"context"
	i5 "gxb.local/backend/v2/internal/application/i5"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sort"
	"strconv"
)

func material(c book.Cost) i5.MaterialCost {
	o := i5.MaterialCost{}
	keys := []string{}
	for k := range c.Scalars {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		if c.Scalars[k] > 0 {
			o.Scalars = append(o.Scalars, i5.ScalarMaterialCost{ResourceKey: k, Amount: c.Scalars[k]})
		}
	}
	ids := []int64{}
	for id := range c.Stacks {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, id := range ids {
		if c.Stacks[id] > 0 {
			o.Stacks = append(o.Stacks, i5.StackMaterialCost{ItemID: id, Amount: c.Stacks[id]})
		}
	}
	return o
}
func (s Service) wallet(ctx context.Context, q tx.Queryer, p identity.PlayerID) (map[string]any, error) {
	out := map[string]any{}
	for _, key := range []string{"magic_dust", "magic_liquid", "magic_energy", "magic_exp"} {
		v, ok, e := s.Values.ReadScalarTx(ctx, q, p, key)
		if e != nil {
			return nil, e
		}
		if ok {
			if e = v.Validate(); e != nil {
				return nil, e
			}
			out[key] = v.Amount
		} else {
			out[key] = int64(0)
		}
	}
	return out, nil
}
func (s Service) stock(ctx context.Context, q tx.Queryer, p identity.PlayerID) (map[int64]int64, error) {
	xs, e := s.Values.ListStacksTx(ctx, q, p)
	if e != nil {
		return nil, e
	}
	out := map[int64]int64{}
	for _, x := range xs {
		if e = x.Validate(); e != nil {
			return nil, e
		}
		out[x.ItemID] = x.Quantity
	}
	return out, nil
}
func plan(d Admission, p identity.PlayerID, tag string, lines []grant.Line) grant.Plan {
	return grant.Plan{PlayerID: p, Source: grant.SourceIdentity{Domain: "book-skill", Operation: tag, BusinessKey: strconv.FormatInt(int64(p), 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: lines}
}
func (s Service) refund(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, cost book.Cost, op operation.Context) (map[int64]int64, error) {
	lines := []grant.Line{}
	for k, n := range cost.Scalars {
		if n > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: k, Amount: n})
		}
	}
	for id, n := range cost.Stacks {
		if n > 0 {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: n})
		}
	}
	sort.Slice(lines, func(i, j int) bool {
		if lines[i].Kind != lines[j].Kind {
			return lines[i].Kind < lines[j].Kind
		}
		if lines[i].ResourceKey != lines[j].ResourceKey {
			return lines[i].ResourceKey < lines[j].ResourceKey
		}
		return lines[i].ItemID < lines[j].ItemID
	})
	out := map[int64]int64{}
	if len(lines) == 0 {
		return out, nil
	}
	r, e := s.Grants.SettleGrantTx(ctx, t, a, plan(d, a.PlayerID, "refund", lines), op, i5.GrantTxOptions{AllowOverflowMail: true})
	if e != nil {
		return nil, e
	}
	for _, x := range r.Awards {
		if x.TableID > 0 {
			out[x.TableID] += x.ItemNum
		}
	}
	return out, nil
}
func (s Service) apply(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission) (map[string]any, error) {
	at := d.DecisionAt
	root, e := s.Owner.ReadRootTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	if at.Before(root.UpdatedAt) {
		return nil, ErrStale
	}
	c, e := s.Content.BookCatalogTx(ctx, t, d.ContentRevision)
	if e != nil {
		return nil, e
	}
	if e = root.Facts.Validate(c); e != nil {
		return nil, e
	}
	before := root.Facts.Clone()
	st := root.Facts.Clone()
	if _, e = st.Settle(at); e != nil {
		return nil, e
	}
	cmd := d.Command
	body := map[string]any{}
	cost := book.EmptyCost()
	refund := book.EmptyCost()
	valueop := d.Operation
	valueop.StartedAt = at
	switch cmd.Family {
	case Start:
		b := st.Buildings[cmd.Type]
		if b.Job == nil {
			dur, co, e := c.BuildingPlan(st, cmd.Type)
			if e != nil {
				return nil, e
			}
			cost = co
			b.Job = &book.Job{Occurrence: d.Operation.ID.String(), Revision: d.ContentRevision, StartedAt: at, Duration: dur, Target: b.Level + 1, Subject: cmd.Type, Cost: co}
			b.Recent = false
			st.Buildings[cmd.Type] = b
		}
	case Cancel:
		b := st.Buildings[cmd.Type]
		ids := []int64{}
		nums := []int64{}
		if b.Job != nil {
			left, e := book.Remaining(b.Job, at)
			if e != nil {
				return nil, e
			}
			refund, e = book.Refund(b.Job, left)
			if e != nil {
				return nil, e
			}
			b.Job = nil
			b.Recent = false
			st.Buildings[cmd.Type] = b
			resourceID := map[string]int64{"mana": 1, "magic_dust": 11, "magic_liquid": 12, "magic_energy": 13, "magic_exp": 14}
			keys := []string{}
			for k := range refund.Scalars {
				keys = append(keys, k)
			}
			sort.Slice(keys, func(i, j int) bool { return resourceID[keys[i]] < resourceID[keys[j]] })
			for _, k := range keys {
				ids = append(ids, resourceID[k])
				nums = append(nums, refund.Scalars[k])
			}
		}
		body["return_res_id"], body["return_res_num"] = ids, nums
	case Speed:
		b := st.Buildings[cmd.Type]
		if b.Job != nil {
			left, e := book.Remaining(b.Job, at)
			if e != nil {
				return nil, e
			}
			if n := book.SpeedCost(left); n > 0 {
				cost.Scalars["crystal"] = n
			}
			b.Level = b.Job.Target
			b.Job = nil
			b.Recent = true
			st.Buildings[cmd.Type] = b
		} else if !b.Recent {
			return nil, book.ErrInvalid
		}
	case Confirm:
		b := st.Buildings[cmd.Type]
		if b.Job != nil {
			return nil, book.ErrInvalid
		}
		b.Recent = false
		st.Buildings[cmd.Type] = b
	case Learn:
		if st.Research != nil {
			if st.Research.Subject != cmd.SkillID {
				return nil, book.ErrInvalid
			}
		} else {
			if st.RecentSkill != 0 {
				return nil, book.ErrInvalid
			}
			duration, co, e := c.ResearchPlan(st, cmd.SkillID)
			if e != nil {
				return nil, e
			}
			stock, e := s.stock(ctx, t, a.PlayerID)
			if e != nil {
				return nil, e
			}
			r := c.Skills[cmd.SkillID]
			if stock[r.Book] <= 0 {
				return nil, book.ErrInvalid
			}
			cost = co
			st.Research = &book.Job{Occurrence: d.Operation.ID.String(), Revision: d.ContentRevision, StartedAt: at, Duration: duration, Target: st.Skills[cmd.SkillID] + 1, Subject: cmd.SkillID, Cost: co}
		}
	case GiveUp:
		body["return_skillpage"] = int64(0)
		if st.Research != nil {
			if st.Research.Subject != cmd.SkillID {
				return nil, book.ErrInvalid
			}
			left, e := book.Remaining(st.Research, at)
			if e != nil {
				return nil, e
			}
			refund, e = book.Refund(st.Research, left)
			if e != nil {
				return nil, e
			}
			st.Research = nil
		}
	case SpeedSkill:
		if st.Research != nil {
			if st.Research.Subject != cmd.SkillID {
				return nil, book.ErrInvalid
			}
			left, e := book.Remaining(st.Research, at)
			if e != nil {
				return nil, e
			}
			if n := book.SpeedCost(left); n > 0 {
				cost.Scalars["crystal"] = n
			}
			st.Skills[cmd.SkillID] = st.Research.Target
			st.Research = nil
			st.RecentSkill = cmd.SkillID
		} else if st.RecentSkill != cmd.SkillID {
			return nil, book.ErrInvalid
		}
		r, ok := c.Skills[cmd.SkillID]
		if !ok {
			return nil, book.ErrInvalid
		}
		body["book_id"] = strconv.FormatInt(r.Book, 10)
		body["book_info"] = book.BookWire(c, st, r.Book, true)
	case ConfirmSkill:
		if st.Research != nil {
			return nil, book.ErrInvalid
		}
		st.RecentSkill = 0
	case Compose:
		b, ok := c.Books[cmd.ItemID]
		if !ok || b.Piece <= 0 || b.PieceCount <= 0 || cmd.Amount != 1 || st.Buildings[1].Level < b.Star {
			return nil, book.ErrInvalid
		}
		stock, e := s.stock(ctx, t, a.PlayerID)
		if e != nil {
			return nil, e
		}
		if stock[b.ID] > 0 {
			return nil, book.ErrInvalid
		}
		req := i5.MaterialExchangeRequest{Cost: i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: b.Piece, Amount: b.PieceCount}}}, Restoration: plan(d, a.PlayerID, "compose", []grant.Line{{Kind: grant.StackItem, ItemID: b.ID, Amount: 1}})}
		prepared, e := s.Exchange.PrepareMaterialExchangeTx(ctx, t, a, req, valueop)
		if e != nil {
			return nil, e
		}
		if _, e = s.Exchange.ApplyMaterialExchangeTx(ctx, t, prepared); e != nil {
			return nil, e
		}
	default:
		return nil, book.ErrUnqualified
	}
	// Source-qualified whole value plan closes before any canonical Book write.
	mc := material(cost)
	if len(mc.Scalars)+len(mc.Stacks) > 0 {
		p, e := s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, mc, valueop)
		if e != nil {
			return nil, e
		}
		r, e := s.Costs.ApplyMaterialDebitTx(ctx, t, p)
		if e != nil {
			return nil, e
		}
		for _, v := range r.Scalars {
			body[v.ResourceKey] = v.Amount
		}
	}
	if len(refund.Scalars)+len(refund.Stacks) > 0 {
		inline, e := s.refund(ctx, t, a, d, refund, valueop)
		if e != nil {
			return nil, e
		}
		if cmd.Family == GiveUp {
			var n int64
			for _, v := range inline {
				n += v
			}
			body["return_skillpage"] = n
		}
	}
	if _, e = st.Settle(at); e != nil {
		return nil, e
	}
	if e = st.Validate(c); e != nil {
		return nil, e
	}
	if !reflect.DeepEqual(before, st) {
		old := root.Version
		root.Version++
		root.Facts = st
		root.UpdatedAt = at
		if e = s.Owner.SaveRootTx(ctx, t, root, old); e != nil {
			return nil, e
		}
	}
	switch cmd.Family {
	case Start, Speed:
		for k, v := range book.BuildingWire(st.Buildings[cmd.Type]) {
			body[k] = v
		}
		body["type"] = cmd.Type
	case Cancel:
		body["building_info"] = book.BuildingWire(st.Buildings[cmd.Type])
	case Learn, GiveUp, SpeedSkill:
		body["cabinet_info"] = book.CabinetWire(st)
	}
	wallet, e := s.wallet(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	for k, v := range wallet {
		body[k] = v
	}
	return body, nil
}
