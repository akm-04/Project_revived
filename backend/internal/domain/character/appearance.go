package character

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const DefaultIllusionSkinID int64 = -1

// HeroSkinEntitlement is Hero-owned appearance authority. ExpiresAt=nil means
// permanent ownership; a non-nil UTC instant is a timed entitlement. Expiry is
// qualified at the operation decision instant and does not require a timer write.
type HeroSkinEntitlement struct {
	PlayerID  identity.PlayerID
	PartnerID int64
	ModelID   int64
	ExpiresAt *time.Time
}

func (e HeroSkinEntitlement) Validate() error {
	if !e.PlayerID.Valid() || e.PartnerID <= 0 || e.ModelID <= 0 {
		return errors.New("character appearance: invalid Hero skin entitlement")
	}
	if e.ExpiresAt != nil && e.ExpiresAt.IsZero() {
		return errors.New("character appearance: invalid Hero skin expiry")
	}
	return nil
}

func (e HeroSkinEntitlement) EffectiveAt(at time.Time) bool {
	if e.Validate() != nil || at.IsZero() {
		return false
	}
	return e.ExpiresAt == nil || !at.UTC().After(e.ExpiresAt.UTC())
}

// HeroLIVEEntitlement is durable paid type-2 LIVE state. Type-1/Vow automatic
// dynamic cards are immutable content behaviour and never materialize here.
type HeroLIVEEntitlement struct {
	PlayerID  identity.PlayerID
	PartnerID int64
	ModelID   int64
	IsShow    bool
}

func (e HeroLIVEEntitlement) Validate() error {
	if !e.PlayerID.Valid() || e.PartnerID <= 0 || e.ModelID <= 0 {
		return errors.New("character appearance: invalid Hero LIVE entitlement")
	}
	return nil
}

// PetStyleEntitlement is Pet-owned current home-style ownership. StyleItemID is
// the durable display identity; content qualifies it against Pet origin family.
type PetStyleEntitlement struct {
	PlayerID    identity.PlayerID
	PetID       int64
	StyleItemID int64
}

func (e PetStyleEntitlement) Validate() error {
	if !e.PlayerID.Valid() || e.PetID <= 0 || e.StyleItemID <= 0 {
		return errors.New("character appearance: invalid Pet style entitlement")
	}
	return nil
}
