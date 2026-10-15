package spirit

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/spirit"
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
	Root              d.Root
	Hero              character.Hero
	Facet             d.HeroRoot
	Catalog           d.Catalog
	PopulationVersion int64
	ObservedAt        time.Time
	ContentRevision   string
	Contributions     d.Inputs
	Items             [6]map[string]any
}

func (s Service) inventoryTx(ctx context.Context, q tx.Queryer, scope InputScope) (d.Root, d.Catalog, []d.HeroRoot, map[int64]int64, error) {
	var r d.Root
	var c d.Catalog
	if q == nil || !scope.Player.Valid() || len(scope.ContentRevision) != 64 || scope.ObservedAt.IsZero() {
		return r, c, nil, nil, d.ErrUnqualified
	}
	r, e := s.Owner.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return r, c, nil, nil, e
	}
	c, e = s.Content.SpiritCatalogTx(ctx, q, scope.ContentRevision)
	if e != nil {
		return r, c, nil, nil, e
	}
	if e = r.Facts.Validate(c); e != nil {
		return r, c, nil, nil, e
	}
	fs, e := s.Owner.ListHeroFacetsTx(ctx, q, scope.Player)
	if e != nil {
		return r, c, nil, nil, e
	}
	owners, e := r.Facts.ValidateBindings(c, fs)
	if e != nil {
		return r, c, nil, nil, e
	}
	if scope.ObservedAt.Before(r.UpdatedAt) {
		return r, c, nil, nil, ErrStale
	}
	for _, f := range fs {
		if scope.ObservedAt.Before(f.UpdatedAt) {
			return r, c, nil, nil, ErrStale
		}
	}
	return r, c, fs, owners, nil
}
func (s Service) InventoryTx(ctx context.Context, q tx.Queryer, scope InputScope) ([]map[string]any, error) {
	r, c, _, owners, e := s.inventoryTx(ctx, q, scope)
	if e != nil {
		return nil, e
	}
	ids := []int64{}
	for id := range r.Facts.Instances {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	out := []map[string]any{}
	for _, id := range ids {
		v, e := r.Facts.Instances[id].Wire(c, owners[id], r.Facts.ReferenceCount(id))
		if e != nil {
			return nil, e
		}
		out = append(out, v)
	}
	return out, nil
}
func (s Service) HeroSpiritInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, id int64) (HeroInputs, error) {
	var out HeroInputs
	r, c, fs, owners, e := s.inventoryTx(ctx, q, scope)
	if e != nil {
		return out, e
	}
	if e = s.liveHero(ctx, q, scope.Player, id, scope.ContentRevision, scope.ObservedAt); e != nil {
		return out, e
	}
	pop, e := s.Heroes.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(pop.UpdatedAt) {
		return out, ErrStale
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, scope.Player, id)
	if e != nil {
		return out, e
	}
	var f d.HeroRoot
	for _, v := range fs {
		if v.PartnerID == id {
			f = v
		}
	}
	if f.PartnerID == 0 {
		return out, ErrUnavailable
	}
	out = HeroInputs{Root: r, Hero: h, Facet: f, Catalog: c, PopulationVersion: pop.StateVersion, ObservedAt: scope.ObservedAt, ContentRevision: scope.ContentRevision}
	for i, id := range f.Facts.Slots {
		out.Items[i] = map[string]any{}
		if id > 0 {
			v, e := r.Facts.Instances[id].Wire(c, owners[id], r.Facts.ReferenceCount(id))
			if e != nil {
				return out, e
			}
			out.Items[i] = v
		}
	}
	out.Contributions, e = c.Evaluate(r.Facts, f.Facts.Slots)
	return out, e
}
func (s Service) CoherentHeroInputsTx(ctx context.Context, scope characterasset.CoherentReadScope, ref character.HeroRef) (HeroInputs, error) {
	if e := scope.Validate(); e != nil {
		return HeroInputs{}, e
	}
	if ref.Validate() != nil {
		return HeroInputs{}, d.ErrInvalid
	}
	pin, ok := scope.Operation.Policies.Get("content")
	if !ok || pin != scope.ContentRevision {
		return HeroInputs{}, d.ErrUnqualified
	}
	return s.HeroSpiritInputsTx(ctx, scope.Queryer(), InputScope{ref.PlayerID, scope.ContentRevision, scope.ObservedAt}, ref.PartnerID)
}
func (s Service) OverlayRosterTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, rev string, at time.Time, body map[string]any) error {
	on, e := s.Content.SpiritInputsRevisionTx(ctx, q, rev)
	if e != nil || !on {
		return e
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return d.ErrUnqualified
	}
	for key, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			return d.ErrUnqualified
		}
		id, e := strconv.ParseInt(key, 10, 64)
		if e != nil {
			return e
		}
		v, e := s.HeroSpiritInputsTx(ctx, q, InputScope{a.PlayerID, rev, at}, id)
		if e != nil {
			return e
		}
		row["spirit_equip"] = v.Facet.Facts.Slots
		row["spirit_item"] = v.Items
	}
	return nil
}
func (s Service) Programs(ctx context.Context, a identity.ActorContext, op operation.Context) ([]map[string]any, error) {
	bound, e := s.Timed.Binder.Bind(ctx, op)
	if e != nil {
		return nil, e
	}
	out := []map[string]any{}
	res, e := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, bound.DecisionAt()); e != nil {
			return e
		}
		rev, on, e := s.Content.SpiritInputsActiveTx(ctx, sc.Tx)
		if e != nil {
			return e
		}
		if !on {
			return ErrUnavailable
		}
		r, _, _, _, e := s.inventoryTx(ctx, sc.Tx, InputScope{a.PlayerID, rev, bound.DecisionAt()})
		if e != nil {
			return e
		}
		ids := []int64{}
		for id := range r.Facts.Programs {
			ids = append(ids, id)
		}
		sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
		for _, id := range ids {
			p := r.Facts.Programs[id]
			out = append(out, map[string]any{"id": id, "name": p.Name, "collocation": p.Slots})
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
		root, cat, _, owners, e := s.inventoryTx(ctx, sc.Tx, InputScope{a.PlayerID, r.ContentRevision, bound.DecisionAt()})
		if e != nil {
			return e
		}
		switch r.Command.Family {
		case Equip, AllOff:
			v, e := s.HeroSpiritInputsTx(ctx, sc.Tx, InputScope{a.PlayerID, r.ContentRevision, bound.DecisionAt()}, r.Command.PartnerID)
			if e != nil {
				return e
			}
			out["spirit_equip"] = v.Facet.Facts.Slots
		case Enhance:
			x, ok := root.Facts.Instances[r.Command.SpiritID]
			if !ok {
				return ErrUnavailable
			}
			out, e = x.Wire(cat, owners[x.ID], root.Facts.ReferenceCount(x.ID))
			return e
		case Save:
			out = r.Body
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

func (s Service) InventoryForBootstrapTx(ctx context.Context, q tx.Queryer, p identity.PlayerID, rev string, at time.Time) ([]map[string]any, error) {
	return s.InventoryTx(ctx, q, InputScope{p, rev, at})
}
