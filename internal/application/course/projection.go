package course

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"time"
)

type InputScope struct {
	Player          identity.PlayerID
	ContentRevision string
	ObservedAt      time.Time
}
type Inputs struct {
	Root              course.Root
	Catalog           course.Catalog
	PopulationVersion int64
	Alive             map[int64]bool
	ObservedAt        time.Time
	ContentRevision   string
}
type HeroInputs struct {
	Inputs             Inputs
	Hero               character.Hero
	FacetVersion       int64
	Stored, Applied    course.HeroFacts
	MaterializationDue bool
	Eligibility        [6]bool
	AppliedCourses     []course.Record
}

func (s Service) CourseInputsTx(ctx context.Context, q tx.Queryer, scope InputScope) (Inputs, error) {
	var out Inputs
	if q == nil || !scope.Player.Valid() || len(scope.ContentRevision) != 64 || scope.ObservedAt.IsZero() {
		return out, course.ErrUnqualified
	}
	r, e := s.Owner.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(r.UpdatedAt) {
		return out, ErrStale
	}
	c, e := s.Content.CourseCatalogTx(ctx, q, scope.ContentRevision)
	if e != nil {
		return out, e
	}
	if e = r.Facts.Validate(c); e != nil {
		return out, e
	}
	pop, e := s.Heroes.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	heroes, e := s.Heroes.ListHeroesTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	alive := map[int64]bool{}
	for _, h := range heroes {
		if e = h.ValidatePersistent(); e != nil {
			return out, e
		}
		alive[h.PartnerID] = true
	}
	for p := range r.Facts.Attendance {
		if !alive[p] {
			return out, course.ErrUnqualified
		}
	}
	return Inputs{Root: r, Catalog: c, PopulationVersion: pop.StateVersion, Alive: alive, ObservedAt: scope.ObservedAt, ContentRevision: scope.ContentRevision}, nil
}
func (s Service) HeroCourseInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, partner int64) (HeroInputs, error) {
	var out HeroInputs
	v, e := s.CourseInputsTx(ctx, q, scope)
	if e != nil {
		return out, e
	}
	if !v.Alive[partner] {
		return out, ErrRetired
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, scope.Player, partner)
	if e != nil {
		return out, e
	}
	f, e := s.Owner.ReadHeroTx(ctx, q, scope.Player, partner)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(f.UpdatedAt) {
		return out, ErrStale
	}
	if e = f.Facts.Validate(v.Catalog); e != nil {
		return out, e
	}
	kind, e := s.Content.HeroKindTx(ctx, q, scope.ContentRevision, h.TableID)
	if e != nil {
		return out, e
	}
	h.Kind = kind
	out = HeroInputs{Inputs: v, Hero: h, FacetVersion: f.Version, Stored: f.Facts.Clone(), Applied: f.Facts.Clone(), AppliedCourses: []course.Record{}}
	if kind != character.NormalHero && kind != character.SuperHero {
		return out, course.ErrUnqualified
	}
	out.Eligibility, e = s.eligibility(ctx, q, scope.ContentRevision, h, v.Catalog)
	if e != nil {
		return out, e
	}
	st := v.Root.Facts.Clone()
	out.MaterializationDue, e = st.Settle(v.Catalog, partner, &out.Applied, scope.ObservedAt)
	if e != nil {
		return out, e
	}
	n := 0
	for _, on := range out.Eligibility {
		if on {
			n++
		}
	}
	if len(out.Applied.Courses) > n {
		return out, course.ErrUnqualified
	}
	for _, r := range out.Applied.Courses {
		if r.Skill > 0 {
			if !out.Eligibility[r.Skill-1] {
				return out, course.ErrUnqualified
			}
			out.AppliedCourses = append(out.AppliedCourses, r)
		}
	}
	return out, nil
}
func (s Service) RoomWireTx(ctx context.Context, q tx.Queryer, scope InputScope) (map[string]any, error) {
	v, e := s.CourseInputsTx(ctx, q, scope)
	if e != nil {
		return nil, e
	}
	return map[string]any{"study_infos": attendanceWire(v.Root.Facts, v.Catalog), "log_infos": logWire(v.Root.Facts, v.Alive), "is_has_gift": int64(0)}, nil
}
func (s Service) Read(ctx context.Context, a identity.ActorContext, mid uint16, op operation.Context) (map[string]any, error) {
	if !s.complete() || (mid != 2130 && mid != 2137 && mid != 2139) {
		return nil, ErrUnavailable
	}
	rev, on, e := s.Content.CourseInputsActive(ctx)
	if e != nil {
		return nil, e
	}
	if !on {
		return nil, ErrUnavailable
	}
	var out map[string]any
	_, r, e := s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc gen.TimedScope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, sc.Operation.DecisionAt()); e != nil {
			return e
		}
		var e error
		out, e = s.RoomWireTx(ctx, sc.Tx, InputScope{a.PlayerID, rev, sc.Operation.DecisionAt()})
		return e
	})
	if e != nil {
		return nil, e
	}
	if r.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return out, nil
}
func (s Service) OverlayRosterTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, rev string, at time.Time, body map[string]any) error {
	on, e := s.Content.CourseInputsRevisionTx(ctx, q, rev)
	if e != nil || !on {
		return e
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return course.ErrUnqualified
	}
	for key, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			return course.ErrUnqualified
		}
		partner, e := strconv.ParseInt(key, 10, 64)
		if e != nil {
			return e
		}
		v, e := s.HeroCourseInputsTx(ctx, q, InputScope{a.PlayerID, rev, at}, partner)
		if e != nil {
			return e
		}
		arrays := map[string][]int64{"courses": {}, "courses_progress": {}, "courses_skill": {}, "courses_quality": {}, "courses_exp": {}}
		for _, r := range v.Applied.Courses {
			arrays["courses"] = append(arrays["courses"], r.ID)
			arrays["courses_progress"] = append(arrays["courses_progress"], r.Progress)
			arrays["courses_skill"] = append(arrays["courses_skill"], r.Skill)
			arrays["courses_quality"] = append(arrays["courses_quality"], r.Quality)
			arrays["courses_exp"] = append(arrays["courses_exp"], r.EXP)
		}
		for k, v := range arrays {
			row[k] = v
		}
	}
	return nil
}
