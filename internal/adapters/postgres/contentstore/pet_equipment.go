package contentstore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const petEquipmentCapability = "PET_EQUIPMENT_CA4_4A"

// PetEquipmentActive reports the current immutable revision only when it
// explicitly advertises the CA4-4A Pet equipment topology capability.
func (s Store) PetEquipmentActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Pet equipment queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, petEquipmentCapability)
	return summary.Activation.RevisionID, good, err
}

// PetEquipmentRevision verifies the capability on the exact caller-pinned
// immutable revision. It never silently follows a later activation.
func (s Store) PetEquipmentRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil {
		return false, errors.New("content store: invalid Pet equipment revision")
	}
	return (Store{}).PetEquipmentRevisionTx(ctx, s.Queryer, revision)
}

// PetEquipmentRevisionTx verifies the exact revision through the caller-owned
// transaction/queryer so later CA8 composition never escapes its coherent read
// snapshot merely to re-check capability.
func (Store) PetEquipmentRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	if q == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Pet equipment revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, petEquipmentCapability)
}

func (s Store) PetEquipmentPosition(ctx context.Context, revision string, petTableID, color, slot int64) (character.PetEquipmentPosition, error) {
	if s.Queryer == nil {
		return character.PetEquipmentPosition{}, errors.New("content store: nil Pet equipment queryer")
	}
	return (Store{}).PetEquipmentPositionTx(ctx, s.Queryer, revision, petTableID, color, slot)
}

func (Store) PetEquipmentPositionTx(ctx context.Context, q tx.Queryer, revision string, petTableID, color, slot int64) (character.PetEquipmentPosition, error) {
	if q == nil || len(revision) != 64 || petTableID <= 0 || color < 1 || color > 16 || slot < 1 || slot > character.PetEquipmentSlotCount {
		return character.PetEquipmentPosition{}, errors.New("content store: invalid Pet equipment lookup")
	}
	out := character.PetEquipmentPosition{PetTableID: petTableID, Color: color, Slot: slot}
	var itemID int64
	var classification string
	if err := q.QueryRow(ctx, contentqueries.ReadPetEquipmentPosition, revision, petTableID, color, slot).Scan(&itemID, &classification); err != nil {
		return character.PetEquipmentPosition{}, err
	}
	out.ItemID = character.EquipmentTemplateID(itemID)
	out.Classification = character.PetEquipmentClassification(classification)
	if err := out.Validate(); err != nil {
		return character.PetEquipmentPosition{}, err
	}
	return out, nil
}

// EquipmentCompatibilityExpPolicyTx exposes the stock partnerExp threshold
// curve through a family-neutral, revision-qualified content port. The data is
// intentionally backed by the single existing gxb_content_hero_exp authority;
// it is not copied into Pet-owned state or a second content table.
func (Store) EquipmentCompatibilityExpPolicyTx(ctx context.Context, q tx.Queryer, revision string, maxLevel int64) ([]character.EquipmentCompatibilityExpThreshold, error) {
	if q == nil || len(revision) != 64 || maxLevel <= 0 || maxLevel > 100 {
		return nil, errors.New("content store: invalid equipment compatibility EXP lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadEquipmentCompatibilityExpPolicy, revision, maxLevel).Scan(&raw); err != nil {
		return nil, err
	}
	var out []character.EquipmentCompatibilityExpThreshold
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	if err := character.ValidateEquipmentCompatibilityExpThresholds(out, maxLevel); err != nil {
		return nil, err
	}
	return out, nil
}

// PetTemplateAwakenedTx exposes the immutable CA3 Pet-template awakened flag
// to CA4-4A without inventing a second Awakening state owner.
func (Store) PetTemplateAwakenedTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) (bool, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return false, errors.New("content store: invalid Pet awakened-template lookup")
	}
	var awakened bool
	if err := q.QueryRow(ctx, contentqueries.ReadPetTemplateAwakened, revision, tableID).Scan(&awakened); err != nil {
		return false, err
	}
	return awakened, nil
}
