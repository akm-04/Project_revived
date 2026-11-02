package guildrental

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const ReferenceGuardProviderID = "i9.rental-offers"

const rentalOfferRank uint16 = 609

// GuardStore is the offer lock a removal guard revalidates under.
type GuardStore interface {
	LockRentalOfferTx(context.Context, tx.Tx, identity.PlayerID, guild.RentalKind, int64) (guild.RentalOffer, bool, error)
}

// ReferenceGuard refuses consuming or deleting a lent hero or pet (C14). It is
// actor-bound like the saved-preset and showcase guards.
type ReferenceGuard struct {
	Store    GuardStore
	PlayerID identity.PlayerID
}

func (g ReferenceGuard) ProviderID() string { return ReferenceGuardProviderID }

func (g ReferenceGuard) validate() error {
	if g.Store == nil || !g.PlayerID.Valid() {
		return characterasset.ErrInvalidReferenceGuard
	}
	return nil
}

func (g ReferenceGuard) plan(kind guild.RentalKind, unit int64) (characterasset.ReferenceGuardPlan, error) {
	key, err := lockkey.New(rentalOfferRank, "guild.rental-offer", lockkey.String(fmt.Sprintf("%d:%s:%d", int64(g.PlayerID), kind, unit)))
	if err != nil {
		return characterasset.ReferenceGuardPlan{}, characterasset.ErrInvalidReferenceGuard
	}
	return characterasset.ReferenceGuardPlan{ProviderID: ReferenceGuardProviderID, Locks: []lockkey.Key{key}}, nil
}

func (g ReferenceGuard) PreflightHeroRemovalTx(_ context.Context, _ tx.Queryer, ref character.HeroRef) (characterasset.ReferenceGuardPlan, error) {
	if err := g.validate(); err != nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ReferenceGuardPlan{}, characterasset.ErrInvalidReferenceGuard
	}
	return g.plan(guild.RentalHero, ref.PartnerID)
}

func (g ReferenceGuard) PreflightPetRemovalTx(_ context.Context, _ tx.Queryer, ref character.PetRef) (characterasset.ReferenceGuardPlan, error) {
	if err := g.validate(); err != nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ReferenceGuardPlan{}, characterasset.ErrInvalidReferenceGuard
	}
	return g.plan(guild.RentalPet, ref.PetID)
}

func (g ReferenceGuard) LockReferenceGuardKeyTx(ctx context.Context, t tx.Tx, key lockkey.Key) error {
	if err := g.validate(); err != nil || t == nil {
		return characterasset.ErrInvalidReferenceGuard
	}
	kind, unit, err := parseOfferLockKey(key, g)
	if err != nil {
		return err
	}
	_, _, err = g.Store.LockRentalOfferTx(ctx, t, g.PlayerID, kind, unit)
	return err
}

func (g ReferenceGuard) ValidateHeroRemovalLockedTx(ctx context.Context, t tx.Tx, ref character.HeroRef, plan characterasset.ReferenceGuardPlan) error {
	return g.validateLocked(ctx, t, ref.Validate() == nil && ref.PlayerID == g.PlayerID, guild.RentalHero, ref.PartnerID, plan)
}

func (g ReferenceGuard) ValidatePetRemovalLockedTx(ctx context.Context, t tx.Tx, ref character.PetRef, plan characterasset.ReferenceGuardPlan) error {
	return g.validateLocked(ctx, t, ref.Validate() == nil && ref.PlayerID == g.PlayerID, guild.RentalPet, ref.PetID, plan)
}

func (g ReferenceGuard) validateLocked(ctx context.Context, t tx.Tx, owns bool, kind guild.RentalKind, unit int64, plan characterasset.ReferenceGuardPlan) error {
	if err := g.validate(); err != nil || !owns || t == nil {
		return characterasset.ErrInvalidReferenceGuard
	}
	if err := characterasset.ValidateReferenceGuardPlan(ReferenceGuardProviderID, plan); err != nil {
		return characterasset.ErrInvalidReferenceGuard
	}
	expected, err := g.plan(kind, unit)
	if err != nil || len(plan.Locks) != 1 || lockkey.Compare(plan.Locks[0], expected.Locks[0]) != 0 {
		return characterasset.ErrInvalidReferenceGuard
	}
	_, offered, err := g.Store.LockRentalOfferTx(ctx, t, g.PlayerID, kind, unit)
	if err != nil {
		return err
	}
	if offered {
		return characterasset.ErrReferenceInUse
	}
	return nil
}

func parseOfferLockKey(key lockkey.Key, g ReferenceGuard) (guild.RentalKind, int64, error) {
	if key.DomainRank != rentalOfferRank || key.OwnerKind != "guild.rental-offer" {
		return "", 0, characterasset.ErrInvalidReferenceGuard
	}
	parts := strings.Split(string(key.Identity.Raw()), ":")
	if len(parts) != 3 {
		return "", 0, characterasset.ErrInvalidReferenceGuard
	}
	pid, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil || identity.PlayerID(pid) != g.PlayerID {
		return "", 0, characterasset.ErrInvalidReferenceGuard
	}
	kind := guild.RentalKind(parts[1])
	unit, err := strconv.ParseInt(parts[2], 10, 64)
	if err != nil || unit <= 0 || kind != guild.RentalHero && kind != guild.RentalPet {
		return "", 0, characterasset.ErrInvalidReferenceGuard
	}
	return kind, unit, nil
}

var _ characterasset.HeroRemovalGuard = ReferenceGuard{}
var _ characterasset.PetRemovalGuard = ReferenceGuard{}
