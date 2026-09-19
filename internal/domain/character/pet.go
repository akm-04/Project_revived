package character

import (
	"errors"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const (
	PetRootLockRank     = 420
	PetInstanceLockRank = 430
	MaxPetStar          = 5
)

type PetRoot struct {
	PlayerID           identity.PlayerID
	NextPetID          int64
	FirstFreeHatchUsed bool
	StateVersion       int64
	CreatedAt          time.Time
	UpdatedAt          time.Time
}

func (r PetRoot) Validate() error {
	if !r.PlayerID.Valid() || r.NextPetID <= 0 || r.StateVersion <= 0 || r.CreatedAt.IsZero() || r.UpdatedAt.IsZero() {
		return errors.New("character pet: invalid root")
	}
	return nil
}

type PetSkillLevels [5]int64

func DefaultPetSkillLevels() PetSkillLevels {
	return PetSkillLevels{1, 1, 1, 1, 1}
}

func (s PetSkillLevels) Validate() error {
	for _, v := range s {
		if v < 1 {
			return errors.New("character pet: invalid raw skill level")
		}
	}
	return nil
}

type Pet struct {
	PlayerID                identity.PlayerID
	PetID                   int64
	TableID                 int64
	OriginTableID           int64
	Star                    int64
	Level                   int64
	Exp                     int64
	Color                   int64
	Equipment               PetEquipmentSlots
	Fumo                    PetFumoSlots
	Practice                PracticeAttrs
	Skills                  PetSkillLevels
	Birthday                int64
	IsShow                  bool
	CreationContentRevision string
	StateVersion            int64
	CreatedAt               time.Time
	UpdatedAt               time.Time
}

func (p Pet) ValidatePersistent() error {
	if !p.PlayerID.Valid() || p.PetID <= 0 || p.TableID <= 0 || p.OriginTableID <= 0 || p.Star < 1 || p.Star > MaxPetStar || p.Level < 1 || p.Exp < 0 || p.Color < 1 || p.Color > 16 || p.Equipment.Validate() != nil || p.Fumo.Validate() != nil || p.Skills.Validate() != nil || p.Birthday < 0 || p.Practice.Validate() != nil || p.StateVersion <= 0 || p.CreatedAt.IsZero() || p.UpdatedAt.IsZero() {
		return errors.New("character pet: invalid pet")
	}
	if len(p.CreationContentRevision) != 64 || strings.ToLower(p.CreationContentRevision) != p.CreationContentRevision {
		return errors.New("character pet: invalid content revision")
	}
	return nil
}

// PetRef is the stable owner-scoped identity seam later domains may retain.
// It deliberately carries no mutable gameplay fields.
type PetRef struct {
	PlayerID identity.PlayerID
	PetID    int64
}

func (r PetRef) Validate() error {
	if !r.PlayerID.Valid() || r.PetID <= 0 {
		return errors.New("character pet: invalid reference")
	}
	return nil
}

// PetSummary is the minimum source-qualified public/reference view. Mode-specific
// projections may select or extend it without exposing the private Pet record.
type PetSummary struct {
	TableID int64
	Star    int64
	Color   int64
}

func (s PetSummary) Validate() error {
	if s.TableID <= 0 || s.Star < 1 || s.Star > MaxPetStar || s.Color < 1 || s.Color > 16 {
		return errors.New("character pet: invalid summary")
	}
	return nil
}

func (p Pet) Ref() PetRef { return PetRef{PlayerID: p.PlayerID, PetID: p.PetID} }
func (p Pet) Summary() PetSummary {
	return PetSummary{TableID: p.TableID, Star: p.Star, Color: p.Color}
}
