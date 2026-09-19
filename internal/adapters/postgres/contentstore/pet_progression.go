package contentstore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Store) PetProgressionActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Pet progression queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, "PET_PROGRESSION_CA3")
	return summary.Activation.RevisionID, good, err
}

func (s Store) PetProgressionRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Pet progression revision")
	}
	var raw string
	if err := s.Queryer.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, "PET_PROGRESSION_CA3")
}

func (Store) PetProgressionTemplateTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) (apppet.ProgressionTemplate, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return apppet.ProgressionTemplate{}, errors.New("content store: invalid Pet progression template lookup")
	}
	out := apppet.ProgressionTemplate{TableID: tableID}
	if err := q.QueryRow(ctx, contentqueries.ReadPetProgressionTemplate, revision, tableID).Scan(&out.StoneItemID); err != nil {
		return apppet.ProgressionTemplate{}, err
	}
	if err := out.Validate(); err != nil {
		return apppet.ProgressionTemplate{}, err
	}
	return out, nil
}

func (Store) PetSkillSlotsTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) ([]apppet.SkillSlotDefinition, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return nil, errors.New("content store: invalid Pet skill-slot lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadPetSkillSlots, revision, tableID).Scan(&raw); err != nil {
		return nil, err
	}
	var out []apppet.SkillSlotDefinition
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	if len(out) != 5 {
		return nil, errors.New("content store: incomplete Pet source-skill slots")
	}
	for i, row := range out {
		if row.Slot != int64(i+1) || row.Validate() != nil {
			return nil, errors.New("content store: invalid Pet source-skill slots")
		}
	}
	return out, nil
}

func (Store) PetExpItemTx(ctx context.Context, q tx.Queryer, revision string, itemID int64) (int64, error) {
	if q == nil || len(revision) != 64 || itemID <= 0 {
		return 0, errors.New("content store: invalid Pet EXP item lookup")
	}
	var v int64
	if err := q.QueryRow(ctx, contentqueries.ReadPetExpItem, revision, itemID).Scan(&v); err != nil {
		return 0, err
	}
	if v <= 0 {
		return 0, errors.New("content store: invalid Pet EXP item value")
	}
	return v, nil
}

func (Store) PetExpPolicyTx(ctx context.Context, q tx.Queryer, revision string, maxLevel int64) ([]apppet.ExpThreshold, error) {
	if q == nil || len(revision) != 64 || maxLevel < 1 || maxLevel > 100 {
		return nil, errors.New("content store: invalid Pet EXP policy lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadPetExpPolicy, revision, maxLevel).Scan(&raw); err != nil {
		return nil, err
	}
	var out []apppet.ExpThreshold
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	if err := apppet.ValidateExpThresholds(out, maxLevel); err != nil {
		return nil, err
	}
	return out, nil
}

func (Store) PetSkillBookCostTx(ctx context.Context, q tx.Queryer, revision string, effectiveLevel int64) (int64, error) {
	if q == nil || len(revision) != 64 || effectiveLevel < 1 || effectiveLevel > 130 {
		return 0, errors.New("content store: invalid Pet Skill Book lookup")
	}
	var v int64
	if err := q.QueryRow(ctx, contentqueries.ReadPetSkillBookCost, revision, effectiveLevel).Scan(&v); err != nil {
		return 0, err
	}
	if v <= 0 {
		return 0, errors.New("content store: invalid Pet Skill Book cost")
	}
	return v, nil
}

func (Store) PetSkillSlotPolicyTx(ctx context.Context, q tx.Queryer, revision string, slot int64) (apppet.SkillSlotPolicy, error) {
	if q == nil || len(revision) != 64 || slot < 1 || slot > 5 {
		return apppet.SkillSlotPolicy{}, errors.New("content store: invalid Pet skill-slot policy lookup")
	}
	var out apppet.SkillSlotPolicy
	if err := q.QueryRow(ctx, contentqueries.ReadPetSkillSlotPolicy, revision, slot).Scan(&out.EffectiveOffset, &out.MinColor, &out.RequiresAwakened); err != nil {
		return apppet.SkillSlotPolicy{}, err
	}
	if err := out.Validate(slot); err != nil {
		return apppet.SkillSlotPolicy{}, err
	}
	return out, nil
}

func (Store) PetEvolutionCostTx(ctx context.Context, q tx.Queryer, revision string, targetStar int64) (int64, error) {
	if q == nil || len(revision) != 64 || targetStar < 2 || targetStar > 5 {
		return 0, errors.New("content store: invalid Pet evolution lookup")
	}
	var v int64
	if err := q.QueryRow(ctx, contentqueries.ReadPetEvolutionCost, revision, targetStar).Scan(&v); err != nil {
		return 0, err
	}
	if v <= 0 {
		return 0, errors.New("content store: invalid Pet evolution cost")
	}
	return v, nil
}

func (Store) PetProgressionPolicyTx(ctx context.Context, q tx.Queryer, revision string) (apppet.ProgressionPolicy, error) {
	if q == nil || len(revision) != 64 {
		return apppet.ProgressionPolicy{}, errors.New("content store: invalid Pet progression policy lookup")
	}
	var out apppet.ProgressionPolicy
	if err := q.QueryRow(ctx, contentqueries.ReadPetProgressionPolicy, revision).Scan(&out.SkillBookItemID); err != nil {
		return apppet.ProgressionPolicy{}, err
	}
	if err := out.Validate(); err != nil {
		return apppet.ProgressionPolicy{}, err
	}
	return out, nil
}

func (Store) CharacterMaxLevelTx(ctx context.Context, q tx.Queryer, revision string, playerLevel int64) (int64, error) {
	if q == nil || len(revision) != 64 || playerLevel <= 0 {
		return 0, errors.New("content store: invalid character max-level lookup")
	}
	var v int64
	if err := q.QueryRow(ctx, contentqueries.ReadHeroMaxLevelForPlayerLevel, revision, playerLevel).Scan(&v); err != nil {
		return 0, err
	}
	if v <= 0 || v > 100 {
		return 0, errors.New("content store: invalid character max level")
	}
	return v, nil
}
