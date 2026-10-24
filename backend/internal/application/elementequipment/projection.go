package elementequipment

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	elem "gxb.local/backend/v2/internal/domain/elementequipment"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"strconv"
	"time"
)

type InputScope struct {
	Player          identity.PlayerID
	ContentRevision string
	ObservedAt      time.Time
}
type HeroInputs struct {
	Root               elem.Root
	Hero               character.Hero
	Facet              elem.HeroRoot
	Catalog            elem.Catalog
	PopulationVersion  int64
	ObservedAt         time.Time
	ContentRevision    string
	Active             []elem.Item
	Backup             []elem.Item
	Contributions      map[int64]elem.Contribution
	ExclusiveBookCount int64
}

func (s Service) HeroElementInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, id int64) (HeroInputs, error) {
	var out HeroInputs
	if s.Owner == nil || s.Heroes == nil || s.Content == nil || q == nil || !scope.Player.Valid() || len(scope.ContentRevision) != 64 || scope.ObservedAt.IsZero() || id <= 0 {
		return out, elem.ErrUnqualified
	}
	r, e := s.Owner.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	c, e := s.Content.ElementCatalogTx(ctx, q, scope.ContentRevision)
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
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, scope.Player, id)
	if e != nil {
		return out, e
	}
	if e = h.ValidatePersistent(); e != nil {
		return out, e
	}
	f, e := s.Owner.ReadHeroTx(ctx, q, scope.Player, id)
	if e != nil {
		return out, e
	}
	for _, at := range []time.Time{r.UpdatedAt, pop.UpdatedAt, h.UpdatedAt, f.UpdatedAt} {
		if scope.ObservedAt.Before(at) {
			return out, ErrStale
		}
	}
	if e = validateHeroFacts(f.Facts, c, h); e != nil {
		return out, e
	}
	h.Kind, e = s.Content.HeroKindTx(ctx, q, scope.ContentRevision, h.TableID)
	if e != nil {
		return out, e
	}
	if h.Kind != character.NormalHero && h.Kind != character.SuperHero {
		return out, elem.ErrUnqualified
	}
	out = HeroInputs{Root: r, Hero: h, Facet: f, Catalog: c, PopulationVersion: pop.StateVersion, ObservedAt: scope.ObservedAt, ContentRevision: scope.ContentRevision, Active: []elem.Item{}, Backup: []elem.Item{}}
	needBooks := false
	for _, id := range f.Facts.Slots {
		if id > 0 {
			item, _ := c.Item(id)
			out.Active = append(out.Active, item)
			if h.Kind == character.NormalHero && item.ItemID == 20001453 && (h.TableID == 10001144 || h.TableID == 11001144) {
				needBooks = true
			}
		}
	}
	for id := range f.Facts.Backup {
		item, _ := c.Item(id)
		out.Backup = append(out.Backup, item)
	}
	sort.Slice(out.Backup, func(i, j int) bool { return out.Backup[i].ID < out.Backup[j].ID })
	if needBooks {
		if s.Values == nil {
			return out, ErrUnavailable
		}
		stacks, e := s.Values.ListStacksTx(ctx, q, scope.Player)
		if e != nil {
			return out, e
		}
		for _, v := range stacks {
			if e = v.Validate(); e != nil {
				return out, e
			}
			if scope.ObservedAt.Before(v.UpdatedAt) {
				return out, ErrStale
			}
			if v.ItemID >= 50000001 && v.ItemID <= 50000025 && v.Quantity > 0 {
				out.ExclusiveBookCount++
			}
		}
	}
	out.Contributions, e = c.Evaluate(f.Facts, h.Kind == character.NormalHero, h.TableID, out.ExclusiveBookCount)
	return out, e
}
func (s Service) CoherentHeroInputsTx(ctx context.Context, scope characterasset.CoherentReadScope, ref character.HeroRef) (HeroInputs, error) {
	if e := scope.Validate(); e != nil {
		return HeroInputs{}, e
	}
	if ref.Validate() != nil {
		return HeroInputs{}, elem.ErrInvalid
	}
	pin, ok := scope.Operation.Policies.Get("content")
	if !ok || pin != scope.ContentRevision {
		return HeroInputs{}, elem.ErrUnqualified
	}
	return s.HeroElementInputsTx(ctx, scope.Queryer(), InputScope{ref.PlayerID, scope.ContentRevision, scope.ObservedAt}, ref.PartnerID)
}
func (s Service) OverlayRosterTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, rev string, at time.Time, body map[string]any) error {
	on, e := s.Content.ElementInputsRevisionTx(ctx, q, rev)
	if e != nil || !on {
		return e
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return elem.ErrUnqualified
	}
	for key, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			return elem.ErrUnqualified
		}
		id, e := strconv.ParseInt(key, 10, 64)
		if e != nil {
			return e
		}
		v, e := s.HeroElementInputsTx(ctx, q, InputScope{a.PlayerID, rev, at}, id)
		if e != nil {
			return e
		}
		for k, x := range v.Facet.Facts.Wire() {
			row[k] = x
		}
	}
	return nil
}

// Current callback state is re-read coherently; a retained receipt cannot overwrite newer slots/levels.
func (s Service) Response(ctx context.Context, a identity.ActorContext, r Result, op operation.Context) (map[string]any, error) {
	out := map[string]any{}
	bound, e := s.Timed.Binder.Bind(ctx, op)
	if e != nil {
		return nil, e
	}
	res, e := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, bound.DecisionAt()); e != nil {
			return e
		}
		if r.Command.PartnerID > 0 {
			v, e := s.HeroElementInputsTx(ctx, sc.Tx, InputScope{a.PlayerID, r.ContentRevision, bound.DecisionAt()}, r.Command.PartnerID)
			if e != nil {
				return e
			}
			out = v.Facet.Facts.Pipe()
		}
		return nil
	})
	if e != nil {
		return nil, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return out, nil
}
