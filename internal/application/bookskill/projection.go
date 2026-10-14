package bookskill

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"strconv"
	"time"
)

type InputScope struct {
	Player          identity.PlayerID
	ContentRevision string
	ObservedAt      time.Time
}
type Inputs struct {
	Root               book.Root
	Stored, Applied    book.State
	MaterializationDue bool
	OwnerVersion       int64
	ContentRevision    string
	ObservedAt         time.Time
	Catalog            book.Catalog
}

// Canonical accepted finite-job intents determine due effects. Pure snapshots
// evaluate that same owner transition on a clone; they do not write, charge or
// discover clocks/revisions. Stored facts and due materialization stay explicit.
func (s Service) BookInputsTx(ctx context.Context, q tx.Queryer, scope InputScope) (Inputs, error) {
	var out Inputs
	if q == nil || !scope.Player.Valid() || len(scope.ContentRevision) != 64 || scope.ObservedAt.IsZero() {
		return out, book.ErrUnqualified
	}
	root, e := s.Owner.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(root.UpdatedAt) {
		return out, book.ErrStaleTime
	}
	c, e := s.Content.BookCatalogTx(ctx, q, scope.ContentRevision)
	if e != nil {
		return out, e
	}
	if e = root.Facts.Validate(c); e != nil {
		return out, e
	}
	applied := root.Facts.Clone()
	due, e := applied.Settle(scope.ObservedAt)
	if e != nil {
		return out, e
	}
	return Inputs{Root: root, Stored: root.Facts.Clone(), Applied: applied, MaterializationDue: due, OwnerVersion: root.Version, ContentRevision: scope.ContentRevision, ObservedAt: scope.ObservedAt, Catalog: c}, nil
}

type HeroInputs struct {
	Inputs            Inputs
	Hero              character.Hero
	PopulationVersion int64
	Skills            map[int64]int64
	SkillRules        map[int64]book.BookSkillRule
	Bookshelf         book.BookBuildingRule
}

func (s Service) HeroBookInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, ref character.HeroRef) (HeroInputs, error) {
	var out HeroInputs
	if ref.Validate() != nil || scope.Player != ref.PlayerID || s.Heroes == nil {
		return out, book.ErrUnqualified
	}
	r, e := s.Heroes.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, scope.Player, ref.PartnerID)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(r.UpdatedAt) || scope.ObservedAt.Before(h.UpdatedAt) {
		return out, book.ErrStaleTime
	}
	v, e := s.BookInputsTx(ctx, q, scope)
	if e != nil {
		return out, e
	}
	out = HeroInputs{Inputs: v, Hero: h, PopulationVersion: r.StateVersion, Skills: map[int64]int64{}, SkillRules: map[int64]book.BookSkillRule{}, Bookshelf: v.Catalog.Buildings[[2]int64{4, v.Applied.Buildings[4].Level}]}
	for id, lev := range v.Applied.Skills {
		rule := v.Catalog.Skills[id]
		if rule.Partner == h.OriginTableID {
			out.Skills[id] = lev
			out.SkillRules[id] = rule
		}
	}
	return out, nil
}
func (s Service) BookshelfInputsTx(ctx context.Context, q tx.Queryer, scope InputScope) (Inputs, error) {
	return s.BookInputsTx(ctx, q, scope)
}
func (s Service) buildingsWire(ctx context.Context, q tx.Queryer, scope InputScope) (map[string]any, error) {
	v, e := s.BookInputsTx(ctx, q, scope)
	if e != nil {
		return nil, e
	}
	bs := map[string]any{}
	for t := int64(1); t <= 7; t++ {
		b, ok := v.Applied.Buildings[t]
		if ok {
			bs[strconv.FormatInt(t, 10)] = book.BuildingWire(b)
		} else {
			bs[strconv.FormatInt(t, 10)] = map[string]any{"lev": int64(1), "need_time": int64(0), "start_time": int64(0), "new_evolve": int64(0)}
		}
	}
	body := map[string]any{"building_list": bs, "cabinet_info": book.CabinetWire(v.Applied), "desk_info": map[string]any{"is_making": 0, "make_need_time": 0, "make_start_time": 0, "make_item": 0}, "pet_cabin_info": map[string]any{"is_making": 0, "make_need_time": 0, "make_start_time": 0, "make_item": 0, "pet_id": 0}}
	wallet, e := s.wallet(ctx, q, scope.Player)
	if e != nil {
		return nil, e
	}
	for k, v := range wallet {
		body[k] = v
	}
	return body, nil
}
func (s Service) Read(ctx context.Context, a identity.ActorContext, mid uint16, op operation.Context) (map[string]any, error) {
	if !s.complete() || (mid != 1056 && mid != 1059) {
		return nil, ErrUnavailable
	}
	rev, on, e := s.Content.BookInputsActive(ctx)
	if e != nil {
		return nil, e
	}
	if !on {
		return nil, ErrUnavailable
	}
	var body map[string]any
	_, result, e := s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, nil, func(ctx context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.lockPlan(ctx, sc.Tx, a, Command{}, at); e != nil {
			return e
		}
		r, e := s.Owner.ReadRootTx(ctx, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if at.Before(r.UpdatedAt) {
			return ErrStale
		}
		c, e := s.Content.BookCatalogTx(ctx, sc.Tx, rev)
		if e != nil {
			return e
		}
		if e = r.Facts.Validate(c); e != nil {
			return e
		}
		before := r.Facts.Clone()
		if _, e = r.Facts.Settle(at); e != nil {
			return e
		}
		if !reflect.DeepEqual(before, r.Facts) {
			old := r.Version
			r.Version++
			r.UpdatedAt = at
			if e = s.Owner.SaveRootTx(ctx, sc.Tx, r, old); e != nil {
				return e
			}
		}
		scope := InputScope{a.PlayerID, rev, at}
		if mid == 1056 {
			body, e = s.buildingsWire(ctx, sc.Tx, scope)
			return e
		}
		books := map[string]any{}
		for id := range c.Books {
			books[strconv.FormatInt(id, 10)] = book.BookWire(c, r.Facts, id, false)
		}
		body = map[string]any{"book_info": books, "cabinet_info": book.CabinetWire(r.Facts)}
		wallet, e := s.wallet(ctx, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		for k, v := range wallet {
			body[k] = v
		}
		return nil
	})
	if e != nil {
		return nil, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}
func (s Service) OverlayRosterTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, rev string, at time.Time, body map[string]any) error {
	on, e := s.Content.BookInputsRevisionTx(ctx, q, rev)
	if e != nil || !on {
		return e
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return book.ErrUnqualified
	}
	for key, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			return book.ErrUnqualified
		}
		id, parseErr := strconv.ParseInt(key, 10, 64)
		if parseErr != nil {
			return book.ErrUnqualified
		}
		v, e := s.HeroBookInputsTx(ctx, q, InputScope{a.PlayerID, rev, at}, character.HeroRef{PlayerID: a.PlayerID, PartnerID: id})
		if e != nil {
			return e
		}
		skills := map[string]int64{}
		for sid, lev := range v.Skills {
			skills[strconv.FormatInt(sid, 10)] = lev
		}
		row["skill_book_info"] = skills
		row["book_shelf_lev"] = v.Bookshelf.Level
	}
	return nil
}

func (s Service) BuildingsWireTx(ctx context.Context, q tx.Queryer, scope InputScope) (map[string]any, error) {
	return s.buildingsWire(ctx, q, scope)
}
