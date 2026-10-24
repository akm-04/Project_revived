package inscription

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	ins "gxb.local/backend/v2/internal/domain/inscription"
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
	var out Inputs
	if q == nil || !scope.Player.Valid() || len(scope.ContentRevision) != 64 || scope.ObservedAt.IsZero() {
		return out, ins.ErrUnqualified
	}
	r, e := s.Owner.ReadRootTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(r.UpdatedAt) {
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
	if scope.ObservedAt.Before(pop.UpdatedAt) {
		return out, ErrStale
	}
	hs, e := s.Heroes.ListHeroesTx(ctx, q, scope.Player)
	if e != nil {
		return out, e
	}
	alive := map[int64]bool{}
	for _, h := range hs {
		if e = h.ValidatePersistent(); e != nil {
			return out, e
		}
		alive[h.PartnerID] = true
	}
	return Inputs{r, c, pop.StateVersion, alive, scope.ObservedAt, scope.ContentRevision}, nil
}
func (s Service) HeroInscriptionInputsTx(ctx context.Context, q tx.Queryer, scope InputScope, id int64) (HeroInputs, error) {
	var out HeroInputs
	v, e := s.InscriptionInputsTx(ctx, q, scope)
	if e != nil {
		return out, e
	}
	if !v.Alive[id] {
		return out, ErrRetired
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, scope.Player, id)
	if e != nil {
		return out, e
	}
	f, e := s.Owner.ReadHeroTx(ctx, q, scope.Player, id)
	if e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(f.UpdatedAt) || scope.ObservedAt.Before(h.UpdatedAt) {
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
		values := map[string]any{}
		for _, key := range []string{"mana", "crystal", "degree_cer", "graduate_cer", "patent_cer"} {
			b, ok, e := s.Values.ReadScalarTx(ctx, sc.Tx, a.PlayerID, key)
			if e != nil {
				return e
			}
			if !ok {
				if key == "mana" || key == "crystal" {
					continue
				}
				return ins.ErrUnqualified
			}
			if e = b.Validate(); e != nil {
				return e
			}
			values[key] = b.Amount
		}
		out["economy_"] = values
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
