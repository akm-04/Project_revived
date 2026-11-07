package characterstore

import (
	"context"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/identity"
)

// HeroLevelReader is the CharacterHero-owned typed read for invitation mission
// type 3 (highest currently owned battle girl level). It reads only the canonical
// hero root and roster on the caller's coherent snapshot.
type HeroLevelReader struct {
	Store Store
}

func (r HeroLevelReader) ReadHeroLevelsTx(c context.Context, sc ca.CoherentReadScope, pid identity.PlayerID) (ca.HeroLevelPopulation, error) {
	out := ca.HeroLevelPopulation{PlayerID: pid, Revision: sc.ContentRevision, ObservedAt: sc.ObservedAt}
	if sc.Validate() != nil || !pid.Valid() {
		return out, ca.ErrInvalidCoherentReadScope
	}
	pin, ok := sc.Operation.Policies.Get("content")
	if !ok || pin != sc.ContentRevision {
		return out, ca.ErrInvalidCoherentReadScope
	}
	q := sc.Queryer()
	root, err := r.Store.ReadRootTx(c, q, pid)
	if err != nil {
		return out, err
	}
	if root.Validate() != nil || root.PlayerID != pid || root.UpdatedAt.After(sc.ObservedAt) {
		return out, ca.ErrInvalidCoherentReadScope
	}
	out.RootVersion = root.StateVersion
	heroes, err := r.Store.ListHeroesTx(c, q, pid)
	if err != nil {
		return out, err
	}
	for _, hero := range heroes {
		if hero.ValidatePersistent() != nil || hero.PlayerID != pid || hero.CreatedAt.After(hero.UpdatedAt) || hero.UpdatedAt.After(sc.ObservedAt) || hero.Level < 1 {
			return ca.HeroLevelPopulation{}, ca.ErrInvalidCoherentReadScope
		}
		out.OwnedCount++
		if hero.Level > out.HighestLevel {
			out.HighestLevel = hero.Level
		}
	}
	return out, nil
}

var _ ca.HeroLevelReader = HeroLevelReader{}
