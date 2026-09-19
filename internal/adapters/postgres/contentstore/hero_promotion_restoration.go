package contentstore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const heroPromotionRestorationCapability = "HERO_PROMOTION_RESTORATION_CA4_3B"

func (s Store) HeroPromotionRestorationActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Hero promotion restoration queryer")
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
		if capability == heroPromotionRestorationCapability {
			return m.RevisionID, true, nil
		}
	}
	return m.RevisionID, false, nil
}

func (s Store) HeroPromotionRestorationRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Hero promotion restoration revision")
	}
	var raw string
	if err := s.Queryer.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, heroPromotionRestorationCapability)
}

func (Store) HeroPromotionRestorationEligibilityTx(ctx context.Context, q tx.Queryer, revision string, itemID character.EquipmentTemplateID) (character.HeroPromotionRestorationEligibility, error) {
	if q == nil || len(revision) != 64 || !itemID.Valid() {
		return character.HeroPromotionRestorationEligibility{}, errors.New("content store: invalid Hero promotion restoration eligibility lookup")
	}
	out := character.HeroPromotionRestorationEligibility{ItemID: itemID}
	if err := q.QueryRow(ctx, contentqueries.ReadHeroPromotionRestorationEquipment, revision, int64(itemID)).Scan(&out.SourceQuality); err != nil {
		return character.HeroPromotionRestorationEligibility{}, err
	}
	if err := out.Validate(); err != nil {
		return character.HeroPromotionRestorationEligibility{}, err
	}
	return out, nil
}

// PromotionRestorationPolicyTx exposes the globally source-qualified refund
// fractions/denominations through a family-neutral port. Storage table names
// remain historical CA4-3B names so there is still one durable content owner.
func (Store) PromotionRestorationPolicyTx(ctx context.Context, q tx.Queryer, revision string) (character.PromotionRestorationPolicy, error) {
	if q == nil || len(revision) != 64 {
		return character.PromotionRestorationPolicy{}, errors.New("content store: invalid promotion restoration policy lookup")
	}
	var fractionsRaw, denominationsRaw string
	if err := q.QueryRow(ctx, contentqueries.ReadHeroPromotionRestorationFractions, revision).Scan(&fractionsRaw); err != nil {
		return character.PromotionRestorationPolicy{}, err
	}
	if err := q.QueryRow(ctx, contentqueries.ReadHeroPromotionRestorationDenominations, revision).Scan(&denominationsRaw); err != nil {
		return character.PromotionRestorationPolicy{}, err
	}
	out := character.PromotionRestorationPolicy{}
	if err := json.Unmarshal([]byte(fractionsRaw), &out.Fractions); err != nil {
		return character.PromotionRestorationPolicy{}, err
	}
	if err := json.Unmarshal([]byte(denominationsRaw), &out.Denominations); err != nil {
		return character.PromotionRestorationPolicy{}, err
	}
	if err := out.Validate(); err != nil {
		return character.PromotionRestorationPolicy{}, err
	}
	return out, nil
}

func (s Store) HeroPromotionRestorationPolicyTx(ctx context.Context, q tx.Queryer, revision string) (character.HeroPromotionRestorationPolicy, error) {
	return s.PromotionRestorationPolicyTx(ctx, q, revision)
}
