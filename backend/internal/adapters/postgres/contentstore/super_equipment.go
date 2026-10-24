package contentstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const superEquipmentCapability = "SUPER_EQUIPMENT_CA4_5"

// SuperEquipmentRevision verifies the immutable CA4-5 capability on the exact
// revision pinned by the caller. It never falls forward to a newer revision.
func (s Store) SuperEquipmentRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil {
		return false, errors.New("content store: nil Super equipment revision queryer")
	}
	return (Store{}).SuperEquipmentRevisionTx(ctx, s.Queryer, revision)
}

// SuperEquipmentRevisionTx verifies CA4-5 capability through the caller-owned
// Queryer so CA8 composition cannot escape its coherent transaction snapshot.
func (Store) SuperEquipmentRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	if q == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Super equipment revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, superEquipmentCapability)
}

func (Store) SuperEquipmentPositionTx(ctx context.Context, q tx.Queryer, revision string, heroTableID, slot int64) (character.SuperEquipmentPosition, error) {
	if q == nil || len(revision) != 64 || heroTableID <= 0 || slot < 1 || slot > character.HeroEquipmentSlotCount {
		return character.SuperEquipmentPosition{}, errors.New("content store: invalid Super equipment lookup")
	}
	out := character.SuperEquipmentPosition{HeroTableID: heroTableID, Slot: slot}
	var itemID int64
	if err := q.QueryRow(ctx, contentqueries.ReadSuperEquipmentPosition, revision, heroTableID, slot).Scan(&itemID); err != nil {
		return character.SuperEquipmentPosition{}, err
	}
	out.ItemID = character.EquipmentTemplateID(itemID)
	if err := out.Validate(); err != nil {
		return character.SuperEquipmentPosition{}, err
	}
	return out, nil
}

func (Store) SuperEquipmentCapTx(ctx context.Context, q tx.Queryer, revision string, star int64) (character.SuperEquipmentEnhancementCap, error) {
	if q == nil || len(revision) != 64 || star < 1 || star > 10 {
		return character.SuperEquipmentEnhancementCap{}, errors.New("content store: invalid Super equipment cap lookup")
	}
	out := character.SuperEquipmentEnhancementCap{Star: star}
	if err := q.QueryRow(ctx, contentqueries.ReadSuperEquipmentCap, revision, star).Scan(&out.MaxEnhancement, &out.EffectiveClientReachable); err != nil {
		return character.SuperEquipmentEnhancementCap{}, err
	}
	if err := out.Validate(); err != nil {
		return character.SuperEquipmentEnhancementCap{}, err
	}
	return out, nil
}

func (Store) SuperEquipmentTierTx(ctx context.Context, q tx.Queryer, revision string, tier int64) (character.SuperEquipmentEnhancementTier, error) {
	if q == nil || len(revision) != 64 || tier < 1 || tier > 6 {
		return character.SuperEquipmentEnhancementTier{}, errors.New("content store: invalid Super equipment tier lookup")
	}
	out := character.SuperEquipmentEnhancementTier{Tier: tier}
	if err := q.QueryRow(ctx, contentqueries.ReadSuperEquipmentTier, revision, tier).Scan(&out.MinStar, &out.DuplicateCount, &out.EffectiveClientReachable); err != nil {
		return character.SuperEquipmentEnhancementTier{}, err
	}
	if err := out.Validate(); err != nil {
		return character.SuperEquipmentEnhancementTier{}, err
	}
	return out, nil
}
