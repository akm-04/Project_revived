package contentstore

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const heroFumoCapability = "HERO_FUMO_CA4_3A"

func (s Store) HeroFumoActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Hero Fumo queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	m, err := registry.DecodeManifestStrict(summary.ManifestJSON)
	if err != nil {
		return "", false, err
	}
	for _, c := range m.EnabledCapabilities {
		if c == heroFumoCapability {
			return m.RevisionID, true, nil
		}
	}
	return m.RevisionID, false, nil
}

func (s Store) HeroFumoRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil {
		return false, errors.New("content store: nil Hero Fumo revision queryer")
	}
	return (Store{}).HeroFumoRevisionTx(ctx, s.Queryer, revision)
}

func (Store) HeroFumoRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	if q == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Hero Fumo revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, heroFumoCapability)
}

func (s Store) HeroFumoTarget(ctx context.Context, revision string, itemID character.EquipmentTemplateID) (character.HeroFumoTarget, error) {
	if s.Queryer == nil {
		return character.HeroFumoTarget{}, errors.New("content store: nil Hero Fumo queryer")
	}
	return (Store{}).HeroFumoTargetTx(ctx, s.Queryer, revision, itemID)
}

func (Store) HeroFumoTargetTx(ctx context.Context, q tx.Queryer, revision string, itemID character.EquipmentTemplateID) (character.HeroFumoTarget, error) {
	if q == nil || len(revision) != 64 || !itemID.Valid() {
		return character.HeroFumoTarget{}, errors.New("content store: invalid Hero Fumo target lookup")
	}
	var thresholdsRaw, stagesRaw string
	out := character.HeroFumoTarget{ItemID: itemID}
	if err := q.QueryRow(ctx, contentqueries.ReadHeroFumoTarget, revision, int64(itemID)).Scan(&thresholdsRaw, &out.TotalCap, &out.ManaPerFumo, &stagesRaw); err != nil {
		return character.HeroFumoTarget{}, err
	}
	if err := json.Unmarshal([]byte(thresholdsRaw), &out.ThresholdIncrements); err != nil {
		return character.HeroFumoTarget{}, err
	}
	var rawStages []map[string]string
	if err := json.Unmarshal([]byte(stagesRaw), &rawStages); err != nil {
		return character.HeroFumoTarget{}, err
	}
	out.StageDeltaByAttr = make([]map[int64]string, len(rawStages))
	for i, m := range rawStages {
		out.StageDeltaByAttr[i] = make(map[int64]string, len(m))
		for k, v := range m {
			id, err := strconv.ParseInt(k, 10, 64)
			if err != nil || id <= 0 {
				return character.HeroFumoTarget{}, errors.New("content store: invalid Hero Fumo attribute id")
			}
			out.StageDeltaByAttr[i][id] = v
		}
	}
	if err := out.Validate(); err != nil {
		return character.HeroFumoTarget{}, err
	}
	return out, nil
}

func (Store) HeroFumoMaterialTx(ctx context.Context, q tx.Queryer, revision string, itemID character.EquipmentTemplateID) (character.HeroFumoMaterial, error) {
	if q == nil || len(revision) != 64 || !itemID.Valid() {
		return character.HeroFumoMaterial{}, errors.New("content store: invalid Hero Fumo material lookup")
	}
	out := character.HeroFumoMaterial{ItemID: itemID}
	if err := q.QueryRow(ctx, contentqueries.ReadHeroFumoMaterial, revision, int64(itemID)).Scan(&out.ItemType, &out.Moneng); err != nil {
		return character.HeroFumoMaterial{}, err
	}
	if err := out.Validate(); err != nil {
		return character.HeroFumoMaterial{}, err
	}
	return out, nil
}
