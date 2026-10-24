package characterasset

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	PracticeFamilyHero = "HERO"
	PracticeFamilyPet  = "PET"

	PracticeReducerHeroAdditive       = "HERO_ADDITIVE"
	PracticeReducerPetSourceOverwrite = "PET_SOURCE_ORDER_OVERWRITE"
)

// PracticeContribution is the immutable/materialized CA6 observation consumed
// by later stat-snapshot orchestration. It carries applied owner state plus the
// exact immutable Practice revision used to derive source-qualified bonuses;
// it does not decide battle participation, mode policy, or final merge order.
type PracticeContribution struct {
	Family          string
	OwnerID         int64
	TableID         int64
	StateVersion    int64
	ContentRevision string
	Applied         character.PracticeAttrs
	Reducer         string
	Contributions   []PracticeContributionEntry
}

type PracticeContributionEntry struct {
	AttrType int64
	Value    int64
}

func validRevisionID(s string) bool {
	if len(s) != 64 {
		return false
	}
	for _, r := range s {
		if !((r >= '0' && r <= '9') || (r >= 'a' && r <= 'f')) {
			return false
		}
	}
	return true
}

func (p PracticeContribution) Validate() error {
	if p.OwnerID <= 0 || p.TableID <= 0 || p.StateVersion <= 0 || !validRevisionID(p.ContentRevision) || p.Applied.Validate() != nil {
		return errors.New("character asset: invalid Practice contribution identity")
	}
	switch p.Family {
	case PracticeFamilyHero:
		if p.Reducer != PracticeReducerHeroAdditive {
			return errors.New("character asset: invalid Hero Practice reducer")
		}
	case PracticeFamilyPet:
		if p.Reducer != PracticeReducerPetSourceOverwrite {
			return errors.New("character asset: invalid Pet Practice reducer")
		}
	default:
		return errors.New("character asset: invalid Practice contribution family")
	}
	var prior int64
	for i, row := range p.Contributions {
		if row.AttrType <= 0 || row.Value <= 0 || (i > 0 && row.AttrType <= prior) {
			return errors.New("character asset: invalid Practice contribution rows")
		}
		prior = row.AttrType
	}
	return nil
}

// These owner-qualified read interfaces deliberately require the caller's
// Queryer and exact content revision. They are observation seams only: the
// owning Hero/Pet packages retain all durable Practice authority.
type HeroPracticeContributionProvider interface {
	HeroPracticeContributionTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (PracticeContribution, error)
}

type PetPracticeContributionProvider interface {
	PetPracticeContributionTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (PracticeContribution, error)
}
