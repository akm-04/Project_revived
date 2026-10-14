package course

import (
	"context"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sort"
	"strconv"
	"time"
)

func (s Service) eligibility(ctx context.Context, q tx.Queryer, rev string, h character.Hero, c course.Catalog) ([6]bool, error) {
	var out [6]bool
	kind, e := s.Content.HeroKindTx(ctx, q, rev, h.TableID)
	if e != nil {
		return out, e
	}
	if kind != character.NormalHero && kind != character.SuperHero {
		return out, course.ErrInvalid
	}
	cat, e := s.Content.HeroSkillCatalogTx(ctx, q, rev, h.TableID)
	if e != nil {
		return out, e
	}
	ids, e := cat.ResolveRawIDs(h)
	if e != nil {
		return out, e
	}
	for i, id := range ids {
		out[i] = c.Slots[i] && id > 0
	}
	return out, nil
}
func (s Service) apply(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission) (map[string]any, error) {
	at := d.DecisionAt
	cmd := d.Command
	r, e := s.Owner.ReadRootTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	f, e := s.Owner.ReadHeroTx(ctx, t, a.PlayerID, cmd.PartnerID)
	if e != nil {
		return nil, e
	}
	if at.Before(r.UpdatedAt) || at.Before(f.UpdatedAt) {
		return nil, ErrStale
	}
	c, e := s.Content.CourseCatalogTx(ctx, t, d.ContentRevision)
	if e != nil {
		return nil, e
	}
	if e = c.Validate(); e != nil {
		return nil, e
	}
	if e = r.Facts.Validate(c); e != nil {
		return nil, e
	}
	if e = f.Facts.Validate(c); e != nil {
		return nil, e
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, t, a.PlayerID, cmd.PartnerID)
	if e != nil {
		return nil, e
	}
	slots, e := s.eligibility(ctx, t, d.ContentRevision, h, c)
	if e != nil {
		return nil, e
	}
	values, e := s.Values.LockCoursePlayerStateTx(ctx, t, a.PlayerID, at)
	if e != nil {
		return nil, e
	}
	if values.Function == nil {
		return nil, course.ErrInvalid
	}
	cap, ok := c.Capacity[d.Privileges.VIPLevel]
	if !ok || d.Privileges.ProviderRevision == "" {
		return nil, course.ErrUnqualified
	}
	beforeR := r.Facts.Clone()
	beforeH := f.Facts.Clone()
	st := r.Facts.Clone()
	facts := f.Facts.Clone()
	due, e := st.Settle(c, cmd.PartnerID, &facts, at)
	if e != nil {
		return nil, e
	}
	cost := i5.MaterialCost{}
	returns := []any{}
	body := map[string]any{}
	valueop := d.Operation
	valueop.StartedAt = at
	enroll := func() error {
		if !c.Has(cmd.CourseID) {
			return course.ErrInvalid
		}
		if facts.Index(cmd.CourseID) >= 0 {
			return nil
		}
		n := 0
		for _, on := range slots {
			if on {
				n++
			}
		}
		if len(facts.Courses) >= n {
			return course.ErrInvalid
		}
		facts.Courses = append(facts.Courses, course.Record{ID: cmd.CourseID, Quality: 1})
		cost.Stacks = append(cost.Stacks, i5.StackMaterialCost{ItemID: c.Tickets[cmd.CourseID], Amount: 1})
		return nil
	}
	enter := func() error {
		if _, ok := st.Attendance[cmd.PartnerID]; ok {
			return nil
		}
		if int64(len(st.Attendance)) >= cap {
			return course.ErrInvalid
		}
		st.Attendance[cmd.PartnerID] = course.Attendance{PartnerID: cmd.PartnerID, EnterAt: at}
		st.Log(c, cmd.PartnerID, 0, 1, 0, at)
		return nil
	}
	switch cmd.Family {
	case Apply:
		if e = enroll(); e != nil {
			return nil, e
		}
	case Collect:
	case Enter:
		if e = enter(); e != nil {
			return nil, e
		}
	case Study, Continue:
		if row, ok := st.Attendance[cmd.PartnerID]; ok && row.Job != nil {
			if row.Job.CourseID != cmd.CourseID {
				return nil, course.ErrInvalid
			}
			break
		}
		if cmd.Family == Continue && facts.Index(cmd.CourseID) < 0 {
			return nil, course.ErrInvalid
		}
		if e = enroll(); e != nil {
			return nil, e
		}
		i := facts.Index(cmd.CourseID)
		if facts.Courses[i].Progress >= 100 {
			return nil, course.ErrInvalid
		}
		if e = enter(); e != nil {
			return nil, e
		}
		row := st.Attendance[cmd.PartnerID]
		row.Job = &course.Job{Occurrence: d.Operation.ID.String(), Revision: d.ContentRevision, StartedAt: at, Duration: c.Duration, CourseID: cmd.CourseID}
		st.Attendance[cmd.PartnerID] = row
		st.Log(c, cmd.PartnerID, cmd.CourseID, 2, 0, at)
	case Speed:
		row, ok := st.Attendance[cmd.PartnerID]
		if !ok || row.Job == nil {
			if !due {
				return nil, course.ErrInvalid
			}
			break
		}
		if row.Job.CourseID != cmd.CourseID {
			return nil, course.ErrInvalid
		}
		left, e := course.Remaining(row.Job, at)
		if e != nil {
			return nil, e
		}
		n := c.SpeedHalfHour * ((left + 1799) / 1800)
		if n > 0 {
			cost.Scalars = append(cost.Scalars, i5.ScalarMaterialCost{ResourceKey: "crystal", Amount: n})
		}
		if _, e = st.Finish(c, cmd.PartnerID, &facts, at); e != nil {
			return nil, e
		}
	case Bind:
		i := facts.Index(cmd.CourseID)
		if i < 0 || facts.Courses[i].Progress != 100 || !slots[cmd.SkillID-1] {
			return nil, course.ErrInvalid
		}
		for j := range facts.Courses {
			if facts.Courses[j].Skill == cmd.SkillID {
				facts.Courses[j].Skill = 0
			}
		}
		facts.Courses[i].Skill = cmd.SkillID
	case Leave:
		if row, ok := st.Attendance[cmd.PartnerID]; ok {
			if row.Job != nil {
				return nil, course.ErrInvalid
			}
			delete(st.Attendance, cmd.PartnerID)
			st.Log(c, cmd.PartnerID, 0, 5, 0, at)
		}
	case Cancel:
		if row, ok := st.Attendance[cmd.PartnerID]; ok {
			if row.Job != nil {
				st.Log(c, cmd.PartnerID, row.Job.CourseID, 6, 0, at)
			} else {
				st.Log(c, cmd.PartnerID, 0, 5, 0, at)
			}
			delete(st.Attendance, cmd.PartnerID)
		}
	case Proficiency:
		i := facts.Index(cmd.CourseID)
		amount, ok := c.BookEXP[cmd.ItemID]
		if i < 0 || facts.Courses[i].Progress != 100 || facts.Courses[i].EXP >= c.MaxEXP || !ok || amount <= 0 || cmd.Amount < 1 || cmd.Amount > 999 || cmd.Total < cmd.Amount {
			return nil, course.ErrInvalid
		}
		xs, e := s.Values.ListStacksTx(ctx, t, a.PlayerID)
		if e != nil {
			return nil, e
		}
		current := int64(0)
		for _, x := range xs {
			if x.ItemID == cmd.ItemID {
				if e = x.Validate(); e != nil {
					return nil, e
				}
				current = x.Quantity
			}
		}
		if current != cmd.Total {
			return nil, course.ErrInvalid
		}
		cost.Stacks = append(cost.Stacks, i5.StackMaterialCost{ItemID: cmd.ItemID, Amount: cmd.Amount})
		n := facts.Courses[i].EXP + amount*cmd.Amount
		if n > c.MaxEXP {
			n = c.MaxEXP
		}
		facts.Courses[i].EXP = n
		facts.Courses[i].Quality = c.Quality(n)
		body["item_id"] = cmd.ItemID
		body["total_num"] = current - cmd.Amount
	case Forget:
		i := facts.Index(cmd.CourseID)
		if i < 0 {
			break
		}
		refund, ok := c.Refunds[facts.Courses[i].Quality]
		if !ok {
			return nil, course.ErrUnqualified
		}
		cost.Scalars = append(cost.Scalars, i5.ScalarMaterialCost{ResourceKey: "crystal", Amount: c.ForgetCost})
		ids := []int64{}
		for id := range refund {
			ids = append(ids, id)
		}
		sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
		lines := []grant.Line{}
		for _, id := range ids {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: refund[id]})
		}
		if len(lines) > 0 {
			plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "course", Operation: "forget-refund", BusinessKey: strconv.FormatInt(int64(a.PlayerID), 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: lines}
			p, e := s.Exchange.PrepareMaterialExchangeTx(ctx, t, a, i5.MaterialExchangeRequest{Cost: cost, Restoration: plan, AllowOverflowMail: true}, valueop)
			if e != nil {
				return nil, e
			}
			r, e := s.Exchange.ApplyMaterialExchangeTx(ctx, t, p)
			if e != nil {
				return nil, e
			}
			for _, x := range r.Restoration.Awards {
				returns = append(returns, map[string]any{"item_id": x.TableID, "item_num": x.ItemNum})
			}
			cost = i5.MaterialCost{}
		}
		facts.Courses = append(facts.Courses[:i], facts.Courses[i+1:]...)
		if row, ok := st.Attendance[cmd.PartnerID]; ok && row.Job != nil && row.Job.CourseID == cmd.CourseID {
			st.Log(c, cmd.PartnerID, cmd.CourseID, 6, 0, at)
			delete(st.Attendance, cmd.PartnerID)
		}
	default:
		return nil, course.ErrUnqualified
	}
	if len(cost.Scalars)+len(cost.Stacks) > 0 {
		prepared, e := s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, cost, valueop)
		if e != nil {
			return nil, e
		}
		_, e = s.Costs.ApplyMaterialDebitTx(ctx, t, prepared)
		if e != nil {
			return nil, e
		}
	}
	if e = st.Validate(c); e != nil {
		return nil, e
	}
	if e = facts.Validate(c); e != nil {
		return nil, e
	}
	if !reflect.DeepEqual(beforeR, st) {
		old := r.Version
		r.Version++
		r.Facts = st
		r.UpdatedAt = at
		if e = s.Owner.SaveRootTx(ctx, t, r, old); e != nil {
			return nil, e
		}
	}
	if !reflect.DeepEqual(beforeH, facts) {
		old := f.Version
		f.Version++
		f.Facts = facts
		f.UpdatedAt = at
		if e = s.Owner.SaveHeroTx(ctx, t, f, old); e != nil {
			return nil, e
		}
	}
	body["partner_courses"] = course.HeroWire(facts)
	body["study_infos"] = attendanceWire(st, c)
	body["is_has_gift"] = 0
	if i := facts.Index(cmd.CourseID); i >= 0 {
		body["course_info"] = course.RecordWire(facts.Courses[i])
	}
	if cmd.Family == Forget {
		body["return_items"] = returns
	}
	for _, key := range []string{"crystal"} {
		bal, ok, e := s.Values.ReadScalarTx(ctx, t, a.PlayerID, key)
		if e != nil {
			return nil, e
		}
		if ok {
			if e = bal.Validate(); e != nil {
				return nil, e
			}
			body[key] = bal.Amount
		}
	}
	return body, nil
}
func attendanceWire(st course.State, c course.Catalog) []map[string]any {
	out := []map[string]any{}
	ps := []int64{}
	for p := range st.Attendance {
		ps = append(ps, p)
	}
	sort.Slice(ps, func(i, j int) bool {
		a, b := st.Attendance[ps[i]], st.Attendance[ps[j]]
		if a.EnterAt.Equal(b.EnterAt) {
			return ps[i] < ps[j]
		}
		return a.EnterAt.Before(b.EnterAt)
	})
	for _, p := range ps {
		a := st.Attendance[p]
		id, start, need := int64(0), int64(0), c.Duration
		if a.Job != nil {
			id, start, need = a.Job.CourseID, a.Job.StartedAt.Unix(), a.Job.Duration
		}
		out = append(out, map[string]any{"partner_id": p, "course_id": id, "enter_time": a.EnterAt.Unix(), "start_time": start, "need_time": need})
	}
	return out
}
func logWire(st course.State, alive map[int64]bool) []course.Log {
	out := []course.Log{}
	for _, x := range st.Logs {
		if alive[x.PartnerID] {
			out = append(out, x)
		}
	}
	return out
}

var _ = time.Second
