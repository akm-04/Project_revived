// Package characterasset contains shared cross-family Character Asset contracts. Durable
// Hero/Pet/Super mechanics remain in their owning family application packages.
package characterasset

import (
	"context"
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrEquipmentPrimitivesInactive = errors.New("CA4-1 equipment primitives content capability inactive")

// EquipmentContent is the one immutable content-revision seam shared by later
// CA4 family stages. Family mapping/reachability policies are intentionally not
// part of CA4-1.
type EquipmentContent interface {
	EquipmentPrimitivesActive(context.Context) (string, bool, error)
	EquipmentPrimitivesRevision(context.Context, string) (bool, error)
	EquipmentPrimitiveTx(context.Context, tx.Queryer, string, int64) (character.EquipmentPrimitive, error)
	EquipmentRecipeEdgesTx(context.Context, tx.Queryer, string, int64) ([]character.EquipmentRecipeEdge, error)
}

// PlayerProgressionMaxHeroColorProvider is a typed borrowed dependency. CA4
// does not own max_color and may not hard-code the corroborative V1 value.
type PlayerProgressionMaxHeroColorProvider interface {
	MaxHeroColorTx(context.Context, tx.Queryer, identity.PlayerID, operation.Context) (int64, error)
}

// RestorationOwner identifies the durable Character transition for future
// policy modifiers without exposing Character persistence to Activity.
type RestorationOwner struct {
	Family     string
	InstanceID int64
	FromColor  int64
	ToColor    int64
}

func (o RestorationOwner) Validate() error {
	if (o.Family != "HERO" && o.Family != "PET") || o.InstanceID <= 0 || o.FromColor < 1 || o.ToColor != o.FromColor+1 {
		return errors.New("character asset: invalid restoration transition")
	}
	return nil
}

// RestorationModifier is an extension seam only. Base CA4 source policy is
// computed by the owning family; later Activity may multiply/transform the
// already-qualified lines without taking Character ownership.
type RestorationModifier interface {
	ModifyRestoration(context.Context, tx.Queryer, RestorationOwner, []grant.Line, operation.Context) ([]grant.Line, error)
}

// IdentityRestorationModifier is the no-Activity/default implementation.
type IdentityRestorationModifier struct{}

func (IdentityRestorationModifier) ModifyRestoration(_ context.Context, _ tx.Queryer, owner RestorationOwner, lines []grant.Line, _ operation.Context) ([]grant.Line, error) {
	if err := owner.Validate(); err != nil {
		return nil, err
	}
	out := append([]grant.Line(nil), lines...)
	for _, line := range out {
		if line.Kind != grant.StackItem || line.Validate() != nil {
			return nil, errors.New("character asset: restoration modifier received non-stack line")
		}
	}
	return out, nil
}

// HeroPromotionRestorationSource and PetPromotionRestorationSource derive the
// nested I5 entitlement identity from durable instance lineage + one-way color
// transition. MID/request UUID/state version/content revision are deliberately
// excluded from semantic identity; policy version remains receipt evidence.
func HeroPromotionRestorationSource(partnerID, fromColor, toColor int64, policyVersion string) (grant.SourceIdentity, error) {
	return promotionRestorationSource("character.hero", "partner", partnerID, fromColor, toColor, policyVersion)
}

func PetPromotionRestorationSource(petID, fromColor, toColor int64, policyVersion string) (grant.SourceIdentity, error) {
	return promotionRestorationSource("character.pet", "pet", petID, fromColor, toColor, policyVersion)
}

func promotionRestorationSource(domain, key string, id, fromColor, toColor int64, policyVersion string) (grant.SourceIdentity, error) {
	if id <= 0 || fromColor < 1 || toColor != fromColor+1 || policyVersion == "" {
		return grant.SourceIdentity{}, errors.New("character asset: invalid promotion restoration identity")
	}
	out := grant.SourceIdentity{
		Domain:        domain,
		Operation:     "promotion-restore",
		BusinessKey:   fmt.Sprintf("%s:%d", key, id),
		Occurrence:    fmt.Sprintf("color:%d->%d", fromColor, toColor),
		PolicyVersion: policyVersion,
	}
	return out, out.Validate()
}

// RawEquipmentState is a family-qualified immutable observation contract for
// later CA8/BATTLE_STAT_PROVIDER materialization. It is not the final battle
// snapshot and intentionally carries no equip-time content revision.
type RawEquipmentState struct {
	Family       string
	OwnerID      int64
	StateVersion int64
	Slots        []RawEquipmentSlot
	SpiritRefs   []character.SpiritRef
}

type RawEquipmentSlot struct {
	Slot        int64
	TemplateID  character.EquipmentTemplateID
	RawFumo     int64
	Enhancement int64
}

func (s RawEquipmentState) Validate() error {
	if (s.Family != "HERO" && s.Family != "PET" && s.Family != "SUPER") || s.OwnerID <= 0 || s.StateVersion <= 0 {
		return errors.New("character asset: invalid raw equipment state")
	}
	seen := map[int64]struct{}{}
	for _, slot := range s.Slots {
		if slot.Slot <= 0 || slot.RawFumo < 0 || slot.Enhancement < 0 {
			return errors.New("character asset: invalid raw equipment slot")
		}
		if _, ok := seen[slot.Slot]; ok {
			return errors.New("character asset: duplicate raw equipment slot")
		}
		seen[slot.Slot] = struct{}{}
		if slot.TemplateID < 0 {
			return errors.New("character asset: invalid equipment template id")
		}
	}
	for _, ref := range s.SpiritRefs {
		if err := ref.Validate(); err != nil {
			return err
		}
	}
	return nil
}

const AppearanceContentCapability = "CHARACTER_APPEARANCE_CA7"

type AppearanceSkinDefinition struct {
	ModelID           int64
	HeroOriginTableID int64
	SkinSkillID       int64
}

func (d AppearanceSkinDefinition) Validate() error {
	if d.ModelID <= 0 || d.HeroOriginTableID <= 0 || d.SkinSkillID < 0 {
		return errors.New("character asset: invalid appearance skin definition")
	}
	return nil
}

type AppearanceSkinItemDefinition struct {
	ItemID            int64
	ModelID           int64
	HeroOriginTableID int64
	DurationSeconds   int64
}

func (d AppearanceSkinItemDefinition) Validate() error {
	if d.ItemID <= 0 || d.ModelID <= 0 || d.HeroOriginTableID <= 0 || d.DurationSeconds < 0 {
		return errors.New("character asset: invalid appearance skin item definition")
	}
	return nil
}

type AppearanceLIVEDefinition struct {
	ModelID             int64
	HeroOriginTableID   int64
	CrystalCost         int64
	ActivationItemID    int64
	ActivationItemCount int64
}

func (d AppearanceLIVEDefinition) Validate() error {
	if d.ModelID <= 0 || d.HeroOriginTableID <= 0 || d.CrystalCost <= 0 || d.ActivationItemID <= 0 || d.ActivationItemCount <= 0 {
		return errors.New("character asset: invalid appearance LIVE definition")
	}
	return nil
}

type AppearancePetStyleDefinition struct {
	StyleItemID      int64
	PetOriginTableID int64
}

func (d AppearancePetStyleDefinition) Validate() error {
	if d.StyleItemID <= 0 || d.PetOriginTableID <= 0 {
		return errors.New("character asset: invalid appearance Pet-style definition")
	}
	return nil
}

// AppearanceContent is the revision-scoped immutable CA7 content seam shared by
// Hero and Pet owners. It exposes content facts only; mutation ownership remains
// with the owning Hero/Pet application service.
type AppearanceContent interface {
	AppearanceActive(context.Context) (string, bool, error)
	AppearanceRevision(context.Context, string) (bool, error)
	AppearanceRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	AppearanceSkin(context.Context, string, int64) (AppearanceSkinDefinition, bool, error)
	AppearanceSkinTx(context.Context, tx.Queryer, string, int64) (AppearanceSkinDefinition, bool, error)
	AppearanceSkinItem(context.Context, string, int64) (AppearanceSkinItemDefinition, bool, error)
	AppearanceSkinItemTx(context.Context, tx.Queryer, string, int64) (AppearanceSkinItemDefinition, bool, error)
	AppearanceLIVE(context.Context, string, int64) (AppearanceLIVEDefinition, bool, error)
	AppearanceLIVETx(context.Context, tx.Queryer, string, int64) (AppearanceLIVEDefinition, bool, error)
	AppearancePetStyle(context.Context, string, int64) (AppearancePetStyleDefinition, bool, error)
	AppearancePetStyleTx(context.Context, tx.Queryer, string, int64) (AppearancePetStyleDefinition, bool, error)
}
