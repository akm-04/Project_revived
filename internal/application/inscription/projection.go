package inscription

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	ins "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/changes"
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
	Root              ins.Root
	Catalog           ins.Catalog
	PopulationVersion int64
	Alive             map[int64]bool
	ObservedAt        time.Time
	ContentRevision   string
}
type HeroInputs struct {
	Inputs        Inputs
	Hero          character.Hero
	FacetVersion  int64
	Applied       ins.HeroFacts
	Items         []ins.Item
	CompleteSuits []int64
}

// Caller supplies one RR/Serializable query scope with its pinned content/time.
func (s Service) InscriptionInputsTx(ctx context.Context, q tx.Queryer, scope InputScope) (Inputs, error) {
	v, _, e := s.inputsTx(ctx, q, scope)
	return v, e
}

func (s Service) inputsTx(ctx context.Context, q tx.Queryer, scope InputScope) (Inputs, []character.Hero, error) {
	v, e := s.rootInputsTx(ctx, q, scope)
	if e != nil {
		return v, nil, e
	}
	hs, e := s.Heroes.ListHeroesTx(ctx, q, scope.Player)
	if e != nil {
		return v, nil, e
	}
	alive := map[int64]bool{}
	for _, h := range hs {
		if e = h.ValidatePersistent(); e != nil {
			return v, nil, e
		}
		alive[h.PartnerID] = true
	}
	v.Alive = alive
	return v, hs, nil
}

// rootInputsTx reads the player inscription root and catalog without the roster.
func (s Service) rootInputsTx(ctx context.Context, q tx.Queryer, scope InputScope) (Inputs, error) {
	var out Inputs
	if q == nil || !scope.Player.Valid() || len(scope.ContentRevision) != 64 || scope.ObservedAt.IsZero() {
		return out, ins.ErrUnqualified
	}
	r, e := s.Owner.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	if gen.EffectiveObservation(scope.ObservedAt, r.UpdatedAt).Before(r.UpdatedAt) {
		return out, ErrStale
	}
	c, e := s.Content.InscriptionCatalogTx(ctx, q, scope.ContentRevision)
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
	if gen.EffectiveObservation(scope.ObservedAt, pop.UpdatedAt).Before(pop.UpdatedAt) {
		return out, ErrStale
	}
	return Inputs{r, c, pop.StateVersion, map[int64]bool{}, scope.ObservedAt, scope.ContentRevision}, nil
}

// heroInputsTx reads the roster only for the shared validation path; a single
// Hero projection reads that Hero alone and checks it in the caller.
func (s Service) heroInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, partner int64) (Inputs, error) {
	v, e := s.rootInputsTx(ctx, q, scope)
	if e != nil {
		return v, e
	}
	v.Alive = map[int64]bool{partner: true}
	return v, nil
}

// CompleteSuitCountTx counts completed inscription suits over the whole roster
// with one owner roster read instead of one projection per Hero.
func (s Service) CompleteSuitCountTx(ctx context.Context, q tx.Queryer, scope InputScope) (int64, error) {
	v, roster, e := s.inputsTx(ctx, q, scope)
	if e != nil {
		return 0, e
	}
	facts, e := s.Owner.ListHeroesTx(ctx, q, scope.Player)
	if e != nil {
		return 0, e
	}
	byPartner := make(map[int64]ins.HeroRoot, len(facts))
	for _, f := range facts {
		byPartner[f.PartnerID] = f
	}
	tableIDs := make([]int64, 0, len(roster))
	for _, h := range roster {
		tableIDs = append(tableIDs, h.TableID)
	}
	kinds, e := s.Content.HeroKindsTx(ctx, q, scope.ContentRevision, tableIDs)
	if e != nil {
		return 0, e
	}
	total := int64(0)
	for _, h := range roster {
		f, ok := byPartner[h.PartnerID]
		if !ok {
			return 0, ins.ErrUnqualified
		}
		observedAt := gen.EffectiveObservation(scope.ObservedAt, f.UpdatedAt, h.UpdatedAt)
		if observedAt.Before(f.UpdatedAt) || observedAt.Before(h.UpdatedAt) {
			return 0, ErrStale
		}
		if e = f.Facts.Validate(v.Catalog); e != nil {
			return 0, e
		}
		if _, ok = kinds[h.TableID]; !ok {
			return 0, ins.ErrUnqualified
		}
		total += int64(len(f.Facts.Suits(v.Catalog)))
	}
	return total, nil
}
func (s Service) HeroInscriptionInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, id int64) (HeroInputs, error) {
	var out HeroInputs
	v, e := s.heroInputsTx(ctx, q, scope, id)
	if e != nil {
		return out, e
	}
	if !v.Alive[id] {
		return out, ErrRetired
	}
	h, found, e := s.Heroes.FindHeroByPartnerIDTx(ctx, q, scope.Player, id)
	if e != nil {
		return out, e
	}
	if !found {
		return out, ErrRetired
	}
	f, e := s.Owner.ReadHeroTx(ctx, q, scope.Player, id)
	if e != nil {
		return out, e
	}
	observedAt := gen.EffectiveObservation(scope.ObservedAt, f.UpdatedAt, h.UpdatedAt)
	if observedAt.Before(f.UpdatedAt) || observedAt.Before(h.UpdatedAt) {
		return out, ErrStale
	}
	if e = f.Facts.Validate(v.Catalog); e != nil {
		return out, e
	}
	h.Kind, e = s.Content.HeroKindTx(ctx, q, scope.ContentRevision, h.TableID)
	if e != nil {
		return out, e
	}
	if h.Kind != character.NormalHero && h.Kind != character.SuperHero {
		return out, ins.ErrUnqualified
	}
	out = HeroInputs{Inputs: v, Hero: h, FacetVersion: f.Version, Applied: f.Facts, Items: []ins.Item{}, CompleteSuits: f.Facts.Suits(v.Catalog)}
	for _, id := range f.Facts.Wire() {
		it, ok := v.Catalog.Item(id)
		if !ok {
			return out, ins.ErrUnqualified
		}
		out.Items = append(out.Items, it)
	}
	return out, nil
}
func (s Service) OverlayRosterTx(ctx context.Context, q tx.Queryer, a identity.ActorContext, rev string, at time.Time, body map[string]any) error {
	on, e := s.Content.InscriptionInputsRevisionTx(ctx, q, rev)
	if e != nil || !on {
		return e
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return ins.ErrUnqualified
	}
	for key, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			return ins.ErrUnqualified
		}
		id, e := strconv.ParseInt(key, 10, 64)
		if e != nil {
			return e
		}
		v, e := s.HeroInscriptionInputsTx(ctx, q, InputScope{a.PlayerID, rev, at}, id)
		if e != nil {
			return e
		}
		row["inscript_items"] = v.Applied.Wire()
	}
	return nil
}

// Response projects current absolute balances and current applied state in one
// fresh coherent scope. Historical receipt values never overwrite newer facts.
func (s Service) Response(ctx context.Context, a identity.ActorContext, r Result, op operation.Context) (map[string]any, error) {
	raw, e := json.Marshal(r.Body)
	if e != nil {
		return nil, e
	}
	var out map[string]any
	if e = json.Unmarshal(raw, &out); e != nil {
		return nil, e
	}
	if out == nil {
		out = map[string]any{}
	}
	bound, e := s.Timed.Binder.Bind(ctx, op)
	if e != nil {
		return nil, e
	}
	res, e := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, bound.DecisionAt()); e != nil {
			return e
		}
		for _, key := range []string{"mana", "crystal", "degree_cer", "graduate_cer", "patent_cer"} {
			b, ok, e := s.Values.ReadScalarTx(ctx, sc.Tx, a.PlayerID, key)
			if e != nil {
				return e
			}
			amount := int64(0)
			switch {
			case !ok && (key == "mana" || key == "crystal"):
				continue
			case ok:
				if e = b.Validate(); e != nil {
					return e
				}
				amount = b.Amount
			}
			// SelfPlayer.lua:201-203 defaults an absent certificate field to 0.
			changes.Balance(ctx, key, amount)
		}
		if r.Command.Family == Insert || r.Command.Family == Remove {
			f, e := s.Owner.ReadHeroTx(ctx, sc.Tx, a.PlayerID, r.Command.PartnerID)
			if e != nil {
				return e
			}
			out["inscript_items"] = f.Facts.Wire()
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

// CoherentHeroInputsTx is the selected downstream provider seam. It preserves
// the inherited CA8 Runner-witnessed isolation, revision and operation/time scope.
func (s Service) CoherentHeroInputsTx(ctx context.Context, scope characterasset.CoherentReadScope, ref character.HeroRef) (HeroInputs, error) {
	if e := scope.Validate(); e != nil {
		return HeroInputs{}, e
	}
	if ref.Validate() != nil {
		return HeroInputs{}, ins.ErrInvalid
	}
	pin, ok := scope.Operation.Policies.Get("content")
	if !ok || pin != scope.ContentRevision {
		return HeroInputs{}, ins.ErrUnqualified
	}
	return s.HeroInscriptionInputsTx(ctx, scope.Queryer(), InputScope{Player: ref.PlayerID, ContentRevision: scope.ContentRevision, ObservedAt: scope.ObservedAt}, ref.PartnerID)
}
