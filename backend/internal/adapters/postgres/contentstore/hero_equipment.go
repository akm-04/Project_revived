package contentstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const heroEquipmentCapability = "HERO_EQUIPMENT_CA4_2"

// HeroEquipmentActive reports the current immutable revision only when it
// explicitly advertises the CA4-2 Normal-Hero slot-mapping capability.
func (s Store) HeroEquipmentActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Hero equipment queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, heroEquipmentCapability)
	return summary.Activation.RevisionID, good, err
}

// HeroEquipmentRevision verifies the capability on an exact immutable
// revision. Callers that already pinned content must never silently switch to
// today's active revision.
func (s Store) HeroEquipmentRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil {
		return false, errors.New("content store: nil Hero equipment revision queryer")
	}
	return (Store{}).HeroEquipmentRevisionTx(ctx, s.Queryer, revision)
}

func (Store) HeroEquipmentRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	if q == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Hero equipment revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, heroEquipmentCapability)
}

// HeroEquipmentPositionTx resolves the exact Normal-Hero source mapping. A
// zero ItemID is meaningful source content and is returned rather than treated
// as absence.
func (s Store) HeroEquipmentPosition(ctx context.Context, revision string, heroTableID, color, slot int64) (character.HeroEquipmentPosition, error) {
	if s.Queryer == nil {
		return character.HeroEquipmentPosition{}, errors.New("content store: nil Hero equipment queryer")
	}
	return (Store{}).HeroEquipmentPositionTx(ctx, s.Queryer, revision, heroTableID, color, slot)
}

func (Store) HeroEquipmentPositionTx(ctx context.Context, q tx.Queryer, revision string, heroTableID, color, slot int64) (character.HeroEquipmentPosition, error) {
	if q == nil || len(revision) != 64 || heroTableID <= 0 || color < 1 || color > 16 || slot < 1 || slot > character.HeroEquipmentSlotCount {
		return character.HeroEquipmentPosition{}, errors.New("content store: invalid Hero equipment lookup")
	}
	out := character.HeroEquipmentPosition{HeroTableID: heroTableID, Color: color, Slot: slot}
	var itemID int64
	if err := q.QueryRow(ctx, contentqueries.ReadHeroEquipmentPosition, revision, heroTableID, color, slot).Scan(&itemID, &out.OrdinaryEligible); err != nil {
		return character.HeroEquipmentPosition{}, err
	}
	out.ItemID = character.EquipmentTemplateID(itemID)
	if err := out.Validate(); err != nil {
		return character.HeroEquipmentPosition{}, err
	}
	return out, nil
}
