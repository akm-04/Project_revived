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
	"sort"
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
	if e = s.validateFacts(ctx, q, root.Facts, c, scope.ContentRevision); e != nil {
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
func (s Service) LockHeroSkillCapTx(ctx context.Context, t tx.Tx, player identity.PlayerID, revision string, observedAt time.Time, ref character.HeroRef) (int64, error) {
	if t == nil || player != ref.PlayerID || ref.Validate() != nil || s.Owner == nil {
		return 0, book.ErrUnqualified
	}
	if _, err := s.Owner.LockRootTx(ctx, t, player); err != nil {
		return 0, err
	}
	inputs, err := s.HeroBookInputsTx(ctx, t, InputScope{Player: player, ContentRevision: revision, ObservedAt: observedAt}, ref)
	if err != nil {
		return 0, err
	}
	return inputs.Bookshelf.UpperLimit, nil
}

func (s Service) BookshelfInputsTx(ctx context.Context, q tx.Queryer, scope InputScope) (Inputs, error) {
	return s.BookInputsTx(ctx, q, scope)
}
func (s Service) buildingsWire(ctx context.Context, q tx.Queryer, scope InputScope) (map[string]any, error) {
	if s.MakeInfo == nil {
		return nil, ErrUnavailable
	}
	v, e := s.BookInputsTx(ctx, q, scope)
	if e != nil {
		return nil, e
	}
	return s.buildingsWireFrom(ctx, q, scope, v.Applied)
}

func (s Service) buildingsWireFrom(ctx context.Context, q tx.Queryer, scope InputScope, applied book.State) (map[string]any, error) {
	if s.MakeInfo == nil {
		return nil, ErrUnavailable
	}
	desk, pet, e := s.MakeInfo.MakeInfoTx(ctx, q, scope.Player, scope.ObservedAt)
	if e != nil {
		return nil, e
	}
	bs := map[string]any{}
	for t := int64(1); t <= 7; t++ {
		b, ok := applied.Buildings[t]
		if ok {
			bs[strconv.FormatInt(t, 10)] = book.BuildingWire(b)
		} else {
			bs[strconv.FormatInt(t, 10)] = map[string]any{"lev": int64(1), "need_time": int64(0), "start_time": int64(0), "new_evolve": int64(0)}
		}
	}
	body := map[string]any{"building_list": bs, "cabinet_info": book.CabinetWire(applied), "desk_info": desk, "pet_cabin_info": pet}
	wallet, e := s.wallet(ctx, q, scope.Player)
	if e != nil {
		return nil, e
	}
	for k, v := range wallet {
		body[k] = v
	}
	return body, nil
}

// Read hydrates MID 1056/1059. A read-only repeatable-read snapshot settles a
// clone first: an idle poll takes no lock and writes nothing. Only a due settle
// falls through to the serializable owner path that persists it.
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
	due := false
	_, result, e := s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc gen.TimedScope) error {
		if err := s.fenceActor(ctx, sc.Tx, a, sc.Operation.DecisionAt()); err != nil {
			return err
		}
		body, due, e = s.readSnapshot(ctx, sc.Tx, a.PlayerID, mid, rev, sc.Operation.DecisionAt())
		return e
	})
	if e != nil {
		return nil, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	if !due {
		return body, nil
	}
	return s.settledRead(ctx, a, mid, op, rev)
}

func (s Service) readSnapshot(ctx context.Context, q tx.Queryer, player identity.PlayerID, mid uint16, rev string, at time.Time) (map[string]any, bool, error) {
	r, e := s.Owner.ReadRootTx(ctx, q, player)
	if e != nil {
		return nil, false, e
	}
	if at.Before(r.UpdatedAt) {
		return nil, false, ErrStale
	}
	c, e := s.Content.BookCatalogTx(ctx, q, rev)
	if e != nil {
		return nil, false, e
	}
	if e = s.validateFacts(ctx, q, r.Facts, c, rev); e != nil {
		return nil, false, e
	}
	applied := r.Facts.Clone()
	due, e := applied.Settle(at)
	if e != nil {
		return nil, false, e
	}
	if due {
		return nil, true, nil
	}
	body, e := s.readBody(ctx, q, player, mid, rev, applied, c, at)
	return body, false, e
}

func (s Service) settledRead(ctx context.Context, a identity.ActorContext, mid uint16, op operation.Context, rev string) (map[string]any, error) {
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
		if e = s.validateFacts(ctx, sc.Tx, r.Facts, c, rev); e != nil {
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
		body, e = s.readBody(ctx, sc.Tx, a.PlayerID, mid, rev, r.Facts, c, at)
		return e
	})
	if e != nil {
		return nil, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return body, nil
}

func (s Service) readBody(ctx context.Context, q tx.Queryer, player identity.PlayerID, mid uint16, rev string, facts book.State, catalog book.Catalog, at time.Time) (map[string]any, error) {
	if mid == 1056 {
		return s.buildingsWireFrom(ctx, q, InputScope{Player: player, ContentRevision: rev, ObservedAt: at}, facts)
	}
	books := map[string]any{}
	for id := range catalog.Books {
		books[strconv.FormatInt(id, 10)] = book.BookWire(catalog, facts, id, false)
	}
	body := map[string]any{"book_info": books, "cabinet_info": book.CabinetWire(facts)}
	wallet, e := s.wallet(ctx, q, player)
	if e != nil {
		return nil, e
	}
	for k, v := range wallet {
		body[k] = v
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

// TitleProgressTx is the Bookshelf title progress: the applied level of book
// building 4 (EventCentreBuildingType.BOOKSHELF), which never decreases.
func (s Service) TitleProgressTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, revision string, at time.Time) (int64, int64, error) {
	inputs, e := s.BookInputsTx(ctx, q, InputScope{Player: player, ContentRevision: revision, ObservedAt: at})
	if e != nil {
		return 0, 0, e
	}
	return inputs.Applied.Buildings[4].Level, inputs.OwnerVersion, nil
}

func (s Service) validateFacts(ctx context.Context, query tx.Queryer, facts book.State, caller book.Catalog, revision string) error {
	if len(facts.Buildings) > 7 {
		return book.ErrUnqualified
	}
	revisions := map[string]bool{}
	for kind, building := range facts.Buildings {
		if !book.ExtensionBuilding(kind) {
			continue
		}
		if !book.ValidCatalogRevision(building.CatalogRevision) {
			return book.ErrUnqualified
		}
		revisions[building.CatalogRevision] = true
		if building.Job != nil {
			if !book.ValidCatalogRevision(building.Job.Revision) {
				return book.ErrUnqualified
			}
			revisions[building.Job.Revision] = true
		}
	}
	keys := make([]string, 0, len(revisions))
	for key := range revisions {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	pinned := map[string]book.Catalog{}
	for _, key := range keys {
		if key == revision {
			pinned[key] = caller
			continue
		}
		catalog, err := s.Content.BookCatalogTx(ctx, query, key)
		if err != nil {
			return err
		}
		if err := catalog.Validate(); err != nil {
			return err
		}
		pinned[key] = catalog
	}
	return facts.ValidateWithCatalogs(caller, pinned)
}
