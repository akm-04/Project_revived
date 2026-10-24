package heroevolution

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	evo "gxb.local/backend/v2/internal/domain/heroevolution"
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
type HeroInputs struct {
	Hero              character.Hero
	Facet             evo.Facet
	PopulationVersion int64
	ContentRevision   string
	ObservedAt        time.Time
	Contributions     map[int64]int64
}

func (s Service) HeroEvolutionInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, id int64) (HeroInputs, error) {
	var out HeroInputs
	if q == nil || s.Heroes == nil || s.Owner == nil || s.Content == nil || !scope.Player.Valid() || id <= 0 || len(scope.ContentRevision) != 64 || scope.ObservedAt.IsZero() {
		return out, evo.ErrUnqualified
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
	if h.PlayerID != scope.Player || h.PartnerID != id || pop.PlayerID != scope.Player {
		return out, evo.ErrUnqualified
	}
	f, e := s.Owner.ReadHeroTx(ctx, q, scope.Player, id)
	if e != nil {
		return out, e
	}
	c, e := s.Content.EvolutionCatalogTx(ctx, q, scope.ContentRevision)
	if e != nil {
		return out, e
	}
	if e = f.Validate(c); e != nil {
		return out, e
	}
	if f.Player != scope.Player || f.PartnerID != id {
		return out, evo.ErrUnqualified
	}
	for _, at := range []time.Time{h.UpdatedAt, pop.UpdatedAt, f.UpdatedAt} {
		if scope.ObservedAt.Before(at) {
			return out, ErrStale
		}
	}
	h.Kind, e = s.Content.HeroKindTx(ctx, q, scope.ContentRevision, h.TableID)
	if e != nil {
		return out, e
	}
	if e = h.Validate(); e != nil {
		return out, e
	}
	template, ok := c.Hero(h.TableID)
	if !ok || template.Kind != string(h.Kind) {
		return out, evo.ErrUnqualified
	}
	attrs, e := c.Evaluate(f.Facts)
	if e != nil {
		return out, e
	}
	f.Facts = f.Facts.Clone()
	return HeroInputs{Hero: h, Facet: f, PopulationVersion: pop.StateVersion, ContentRevision: scope.ContentRevision, ObservedAt: scope.ObservedAt, Contributions: attrs}, nil
}
func (s Service) CoherentHeroInputsTx(ctx context.Context, scope characterasset.CoherentReadScope, ref character.HeroRef) (HeroInputs, error) {
	if e := scope.Validate(); e != nil {
		return HeroInputs{}, e
	}
	if ref.Validate() != nil {
		return HeroInputs{}, evo.ErrInvalid
	}
	pin, ok := scope.Operation.Policies.Get("content")
	if !ok || pin != scope.ContentRevision {
		return HeroInputs{}, evo.ErrUnqualified
	}
	return s.HeroEvolutionInputsTx(ctx, scope.Queryer(), InputScope{Player: ref.PlayerID, ContentRevision: scope.ContentRevision, ObservedAt: scope.ObservedAt}, ref.PartnerID)
}
func (s Service) OverlayRosterTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, rev string, at time.Time, body map[string]any) error {
	if s.Content == nil {
		return ErrUnavailable
	}
	on, e := s.Content.EvolutionInputsRevisionTx(ctx, q, rev)
	if e != nil || !on {
		return e
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return evo.ErrUnqualified
	}
	for key, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			return evo.ErrUnqualified
		}
		id, e := strconv.ParseInt(key, 10, 64)
		if e != nil {
			return e
		}
		v, e := s.HeroEvolutionInputsTx(ctx, q, InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: at}, id)
		if e != nil {
			return e
		}
		for k, x := range v.Facet.Facts.Wire() {
			row[k] = x
		}
	}
	return nil
}

// A historical receipt acknowledges the known effect; its callback always reads
// current facts so an old stage cannot overwrite later committed allocations.
func (s Service) Response(ctx context.Context, a identity.ActorContext, r Result, op operation.Context) (map[string]any, error) {
	var out map[string]any
	bound, e := s.Timed.Binder.Bind(ctx, op)
	if e != nil {
		return nil, e
	}
	res, e := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, bound.DecisionAt()); e != nil {
			return e
		}
		v, e := s.HeroEvolutionInputsTx(ctx, sc.Tx, InputScope{Player: a.PlayerID, ContentRevision: r.ContentRevision, ObservedAt: bound.DecisionAt()}, r.Command.PartnerID)
		if e != nil {
			return e
		}
		out = map[string]any{"evo_info": v.Facet.Facts.Wire()}
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
