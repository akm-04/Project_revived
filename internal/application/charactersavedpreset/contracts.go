package charactersavedpreset

import (
	"context"
	"errors"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrRootMissing       = errors.New("saved preset: root missing")
	ErrStaleVersion      = errors.New("saved preset: stale state version")
	ErrImportQuarantined = errors.New("saved preset: legacy aggregate quarantined")
	ErrImportConflict    = errors.New("saved preset: target already contains different state")
)

type Store interface {
	ReadSavedPresetAggregateTx(context.Context, tx.Queryer, identity.PlayerID) (character.SavedPresetAggregate, error)
	LockSavedPresetRootTx(context.Context, tx.Tx, identity.PlayerID) (character.SavedPresetRoot, error)
	ReplaceSavedPresetAggregateTx(context.Context, tx.Tx, character.SavedPresetAggregate, int64) error
	EnsureSavedPresetRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (bool, error)
}

type WireProjection struct {
	SaveTeam     string
	SaveTeamName string
	SavePet      string
}

func ProjectWire(a character.SavedPresetAggregate) (WireProjection, error) {
	if err := a.Validate(); err != nil {
		return WireProjection{}, err
	}
	if len(a.Lanes) == 0 {
		return WireProjection{}, nil
	}
	teams := make([]string, len(a.Lanes))
	names := make([]string, len(a.Lanes))
	pets := make([]string, len(a.Lanes))
	for i, lane := range a.Lanes {
		heroes := make([]string, len(lane.Heroes))
		for j, ref := range lane.Heroes {
			heroes[j] = strconv.FormatInt(ref.PartnerID, 10)
		}
		teams[i] = strings.Join(heroes, "|")
		names[i] = lane.Name
		if lane.Pet == nil {
			pets[i] = "0"
		} else {
			pets[i] = strconv.FormatInt(lane.Pet.PetID, 10)
		}
	}
	return WireProjection{
		SaveTeam:     strings.Join(teams, ":"),
		SaveTeamName: strings.Join(names, "|||"),
		SavePet:      strings.Join(pets, "|"),
	}, nil
}

// ReferenceOwners collects the CA5-1 typed owners used by migration and later
// mutation stages. CA5 itself never queries Hero/Pet tables directly.
type ReferenceOwners struct {
	Heroes characterasset.HeroReferenceOwner
	Pets   characterasset.PetReferenceOwner
}

// ReferenceSet is a pure, actor-scoped enumeration of the external Character
// identities retained by a saved-preset aggregate. It carries no lock or
// mutation behavior; CA5-3 uses it to plan old∪desired locks before mutation.
type ReferenceSet struct {
	Heroes []character.HeroRef
	Pets   []character.PetRef
}

func CollectReferences(lanes []character.SavedPresetLane) ReferenceSet {
	hseen := map[character.HeroRef]struct{}{}
	pseen := map[character.PetRef]struct{}{}
	out := ReferenceSet{}
	for _, lane := range lanes {
		for _, ref := range lane.Heroes {
			if _, ok := hseen[ref]; !ok {
				hseen[ref] = struct{}{}
				out.Heroes = append(out.Heroes, ref)
			}
		}
		if lane.Pet != nil {
			if _, ok := pseen[*lane.Pet]; !ok {
				pseen[*lane.Pet] = struct{}{}
				out.Pets = append(out.Pets, *lane.Pet)
			}
		}
	}
	return out
}

func UnionReferences(a, b ReferenceSet) ReferenceSet {
	out := ReferenceSet{}
	hseen := map[character.HeroRef]struct{}{}
	pseen := map[character.PetRef]struct{}{}
	for _, set := range []ReferenceSet{a, b} {
		for _, ref := range set.Heroes {
			if _, ok := hseen[ref]; !ok {
				hseen[ref] = struct{}{}
				out.Heroes = append(out.Heroes, ref)
			}
		}
		for _, ref := range set.Pets {
			if _, ok := pseen[ref]; !ok {
				pseen[ref] = struct{}{}
				out.Pets = append(out.Pets, ref)
			}
		}
	}
	return out
}

// Covers returns true only when every reference observed by the locked reread
// was already part of the preflight plan. CA5-3 must abort/retry on false.
func (s ReferenceSet) Covers(observed ReferenceSet) bool {
	h := map[character.HeroRef]struct{}{}
	p := map[character.PetRef]struct{}{}
	for _, ref := range s.Heroes {
		h[ref] = struct{}{}
	}
	for _, ref := range s.Pets {
		p[ref] = struct{}{}
	}
	for _, ref := range observed.Heroes {
		if _, ok := h[ref]; !ok {
			return false
		}
	}
	for _, ref := range observed.Pets {
		if _, ok := p[ref]; !ok {
			return false
		}
	}
	return true
}
