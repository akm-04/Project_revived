package character

import (
	"errors"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

type HeroKind string

const (
	NormalHero           HeroKind = "NORMAL"
	SuperHero            HeroKind = "SUPER"
	HeroRootLockRank              = 400
	HeroInstanceLockRank          = 410
	MaxSortType                   = 8191
	MaxHeroStar                   = 8
)

type HeroRoot struct {
	PlayerID      identity.PlayerID
	NextPartnerID int64
	SortType      int64
	StateVersion  int64
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

func (r HeroRoot) Validate() error {
	if !r.PlayerID.Valid() || r.NextPartnerID <= 0 || r.SortType < 0 || r.SortType > MaxSortType || r.StateVersion <= 0 || r.CreatedAt.IsZero() || r.UpdatedAt.IsZero() {
		return errors.New("character hero: invalid root")
	}
	return nil
}

// HeroRef is the stable owner-scoped identity seam later domains may retain.
// It deliberately carries no mutable gameplay fields.
type HeroRef struct {
	PlayerID  identity.PlayerID
	PartnerID int64
}

func (r HeroRef) Validate() error {
	if !r.PlayerID.Valid() || r.PartnerID <= 0 {
		return errors.New("character hero: invalid reference")
	}
	return nil
}

type Hero struct {
	PlayerID      identity.PlayerID
	PartnerID     int64
	TableID       int64
	OriginTableID int64
	// Kind is revisioned-content-derived projection metadata. It is not durable
	// player_heroes authority and must be resolved from CreationContentRevision.
	Kind                    HeroKind
	Star                    int64
	Level                   int64
	Exp                     int64
	Color                   int64
	Equipment               HeroEquipmentSlots
	Fumo                    HeroFumoSlots
	Practice                PracticeAttrs
	CurrentSkinID           int64
	IllusionSkinID          int64
	CreationContentRevision string
	IsLike                  int64
	StateVersion            int64
	CreatedAt               time.Time
	UpdatedAt               time.Time
}

func (h Hero) Ref() HeroRef { return HeroRef{PlayerID: h.PlayerID, PartnerID: h.PartnerID} }

func (h Hero) ValidatePersistent() error {
	if !h.PlayerID.Valid() || h.PartnerID <= 0 || h.TableID <= 0 || h.OriginTableID <= 0 || h.Star < 1 || h.Star > MaxHeroStar || h.Level < 1 || h.Exp < 0 || h.Color < 1 || h.Color > 16 || (h.IsLike != 0 && h.IsLike != 1) || h.CurrentSkinID < 0 || h.IllusionSkinID < -1 || h.StateVersion <= 0 || h.CreatedAt.IsZero() || h.UpdatedAt.IsZero() {
		return errors.New("character hero: invalid hero")
	}
	if err := h.Equipment.Validate(); err != nil {
		return err
	}
	if err := h.Fumo.Validate(); err != nil {
		return err
	}
	if err := h.Practice.Validate(); err != nil {
		return err
	}
	if len(h.CreationContentRevision) != 64 || strings.ToLower(h.CreationContentRevision) != h.CreationContentRevision {
		return errors.New("character hero: invalid content revision")
	}
	return nil
}

func (h Hero) Validate() error {
	if err := h.ValidatePersistent(); err != nil {
		return err
	}
	if h.Kind != NormalHero && h.Kind != SuperHero {
		return errors.New("character hero: unresolved hero kind")
	}
	return nil
}
