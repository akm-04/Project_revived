// Package guildrentalread adapts the existing owner reads the guild rental
// application needs: owned units and their canonical power, player level,
// owner profiles, mana and membership.
package guildrentalread

import (
	"context"
	"errors"
	"math"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/guildrental"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Stats interface {
	HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
	PetTx(context.Context, ca.CoherentReadScope, character.PetRef, publicstats.View) (publicstats.Result, error)
}

type Units struct {
	Stats   Stats
	Content interface {
		ActiveRevision(context.Context, tx.Queryer) (string, error)
	}
	Now func(context.Context, tx.Queryer) (time.Time, error)
}

// UnitTx returns the owner's unit level and the canonical power the client
// shows, read through the same publicstats path as the other owners.
func (u Units) UnitTx(c context.Context, q tx.Queryer, owner identity.PlayerID, kind guild.RentalKind, unit int64) (guildrental.Unit, bool, error) {
	if u.Stats == nil || u.Content == nil || u.Now == nil || q == nil || !owner.Valid() || unit <= 0 {
		return guildrental.Unit{}, false, guildrental.ErrUnavailable
	}
	if kind == guild.RentalHero {
		hero, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(c, q, owner, unit)
		if errors.Is(err, kernelstore.ErrNoRows) {
			return guildrental.Unit{}, false, nil
		}
		if err != nil {
			return guildrental.Unit{}, false, err
		}
		force, err := u.heroForce(c, q, character.HeroRef{PlayerID: owner, PartnerID: hero.PartnerID})
		if err != nil {
			return guildrental.Unit{}, false, err
		}
		return guildrental.Unit{Level: hero.Level, Force: force}, true, nil
	}
	pet, err := (characterstore.Store{}).ReadPetByIDTx(c, q, owner, unit)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return guildrental.Unit{}, false, nil
	}
	if err != nil {
		return guildrental.Unit{}, false, err
	}
	force, err := u.petForce(c, q, character.PetRef{PlayerID: owner, PetID: pet.PetID})
	if err != nil {
		return guildrental.Unit{}, false, err
	}
	return guildrental.Unit{Level: pet.Level, Force: force}, true, nil
}

func (u Units) heroForce(c context.Context, q tx.Queryer, ref character.HeroRef) (int64, error) {
	sc, err := u.scope(c, q)
	if err != nil {
		return 0, err
	}
	result, err := u.Stats.HeroTx(c, sc, ref, publicstats.View{Kind: publicstats.Self, Viewer: ref.PlayerID})
	if err != nil {
		return 0, err
	}
	return force(result)
}

func (u Units) petForce(c context.Context, q tx.Queryer, ref character.PetRef) (int64, error) {
	sc, err := u.scope(c, q)
	if err != nil {
		return 0, err
	}
	result, err := u.Stats.PetTx(c, sc, ref, publicstats.View{Kind: publicstats.Self, Viewer: ref.PlayerID})
	if err != nil {
		return 0, err
	}
	return force(result)
}

func (u Units) scope(c context.Context, q tx.Queryer) (ca.CoherentReadScope, error) {
	revision, err := u.Content.ActiveRevision(c, q)
	if err != nil {
		return ca.CoherentReadScope{}, err
	}
	at, err := u.Now(c, q)
	if err != nil {
		return ca.CoherentReadScope{}, err
	}
	return scope(q, revision, at)
}

func force(result publicstats.Result) (int64, error) {
	value := math.Round(result.Stats.Force)
	if math.IsNaN(value) || math.IsInf(value, 0) || value < 0 || value > 100000000000 {
		return 0, guildrental.ErrUnavailable
	}
	return int64(value), nil
}

func scope(q tx.Queryer, revision string, at time.Time) (ca.CoherentReadScope, error) {
	raw, ok := q.(tx.Tx)
	if !ok {
		return ca.CoherentReadScope{}, guildrental.ErrUnavailable
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		return ca.CoherentReadScope{}, err
	}
	op := operation.Context{ID: ids.UUID{15: 1}, StartedAt: at.UTC(), Policies: policies}
	return ca.NewCoherentReadScope(tx.Scope{Tx: raw, Operation: op, Attempt: 1, Options: tx.Options{Isolation: tx.Serializable}}, revision, at)
}

type Levels struct{}

func (Levels) LevelTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (int64, error) {
	p, err := (i5store.Store{}).ReadProgressionTx(c, q, pid)
	return p.Level, err
}

type Characters struct{}

func (Characters) HeroTx(c context.Context, q tx.Queryer, pid identity.PlayerID, partner int64) (character.Hero, bool, error) {
	h, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(c, q, pid, partner)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return character.Hero{}, false, nil
	}
	return h, err == nil, err
}

func (Characters) PetTx(c context.Context, q tx.Queryer, pid identity.PlayerID, petID int64) (character.Pet, bool, error) {
	p, err := (characterstore.Store{}).ReadPetByIDTx(c, q, pid, petID)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return character.Pet{}, false, nil
	}
	return p, err == nil, err
}

type Profiles struct{}

func (Profiles) ProfileTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return (i4store.PlayerDirectoryReader{}).ProfileTx(c, q, pid)
}

type Mana struct{}

func (Mana) BalanceTx(c context.Context, q tx.Queryer, pid identity.PlayerID, key string) (int64, bool, error) {
	b, found, err := (i5store.Store{}).ReadScalarTx(c, q, pid, key)
	return b.Amount, found, err
}
