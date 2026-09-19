package contentstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const petPromotionRestorationCapability = "PET_PROMOTION_RESTORATION_CA4_4B"

func (s Store) PetPromotionRestorationActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Pet promotion restoration queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	m, err := registry.DecodeManifestStrict(summary.ManifestJSON)
	if err != nil {
		return "", false, err
	}
	for _, capability := range m.EnabledCapabilities {
		if capability == petPromotionRestorationCapability {
			return m.RevisionID, true, nil
		}
	}
	return m.RevisionID, false, nil
}

func (s Store) PetPromotionRestorationRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Pet promotion restoration revision")
	}
	var raw string
	if err := s.Queryer.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, petPromotionRestorationCapability)
}

func (Store) PetPromotionRestorationEligibilityTx(ctx context.Context, q tx.Queryer, revision string, itemID character.EquipmentTemplateID) (character.PetPromotionRestorationEligibility, error) {
	if q == nil || len(revision) != 64 || !itemID.Valid() {
		return character.PetPromotionRestorationEligibility{}, errors.New("content store: invalid Pet promotion restoration eligibility lookup")
	}
	out := character.PetPromotionRestorationEligibility{ItemID: itemID}
	if err := q.QueryRow(ctx, contentqueries.ReadPetPromotionRestorationEquipment, revision, int64(itemID)).Scan(&out.SourceQuality); err != nil {
		return character.PetPromotionRestorationEligibility{}, err
	}
	if err := out.Validate(); err != nil {
		return character.PetPromotionRestorationEligibility{}, err
	}
	return out, nil
}
