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

func manifestHasCapability(raw []byte, revision, capability string) (bool, error) {
	m, err := registry.DecodeManifestStrict(raw)
	if err != nil {
		return false, err
	}
	if m.RevisionID != revision {
		return false, errors.New("content store: Hero progression manifest revision mismatch")
	}
	for _, c := range m.EnabledCapabilities {
		if c == capability {
			return true, nil
		}
	}
	return false, nil
}

// HeroProgressionActive reports the current immutable revision only when it
// explicitly advertises the CA2-2 capability. CA2-1-only revisions remain valid
// for roster/sort operations but are intentionally insufficient here.
func (s Store) HeroProgressionActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Hero progression queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, "HERO_PROGRESSION_CA2")
	return summary.Activation.RevisionID, good, err
}

// HeroProgressionRevision verifies capability on an exact immutable revision;
// it never silently switches an already-bound operation to today's activation.
func (s Store) HeroProgressionRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Hero progression revision")
	}
	var raw string
	if err := s.Queryer.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, "HERO_PROGRESSION_CA2")
}

func (Store) HeroExpItemTx(ctx context.Context, q tx.Queryer, revision string, itemID int64) (int64, error) {
	if q == nil || len(revision) != 64 || itemID <= 0 {
		return 0, errors.New("content store: invalid Hero EXP item lookup")
	}
	var v int64
	if err := q.QueryRow(ctx, contentqueries.ReadHeroExpItem, revision, itemID).Scan(&v); err != nil {
		return 0, err
	}
	if v <= 0 {
		return 0, errors.New("content store: invalid Hero EXP item value")
	}
	return v, nil
}

func (Store) HeroMaxLevelTx(ctx context.Context, q tx.Queryer, revision string, playerLevel int64) (int64, error) {
	return (Store{}).CharacterMaxLevelTx(ctx, q, revision, playerLevel)
}

func (Store) HeroExpPolicyTx(ctx context.Context, q tx.Queryer, revision string, maxLevel int64) ([]character.HeroExpThreshold, error) {
	if q == nil || len(revision) != 64 || maxLevel <= 0 || maxLevel > 100 {
		return nil, errors.New("content store: invalid Hero EXP policy lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadHeroExpPolicy, revision, maxLevel).Scan(&raw); err != nil {
		return nil, err
	}
	var out []character.HeroExpThreshold
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	if int64(len(out)) != maxLevel {
		return nil, errors.New("content store: incomplete Hero EXP policy")
	}
	var prev int64 = -1
	for i, x := range out {
		if x.Level != int64(i+1) || x.TotalExp < 0 || x.TotalExp < prev {
			return nil, errors.New("content store: invalid Hero EXP policy")
		}
		prev = x.TotalExp
	}
	return out, nil
}

func (Store) HeroTemplateProgressionTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) (character.HeroTemplateProgression, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return character.HeroTemplateProgression{}, errors.New("content store: invalid Hero template progression lookup")
	}
	var raw string
	var out character.HeroTemplateProgression
	if err := q.QueryRow(ctx, contentqueries.ReadHeroTemplateProgression, revision, tableID).Scan(&raw, &out.OriginTableID, &out.FragmentItemID, &out.InitialStar); err != nil {
		return character.HeroTemplateProgression{}, err
	}
	out.Kind = character.HeroKind(raw)
	if (out.Kind != character.NormalHero && out.Kind != character.SuperHero) || out.OriginTableID <= 0 || out.FragmentItemID < 0 || out.InitialStar < 1 || out.InitialStar > character.MaxHeroStar {
		return character.HeroTemplateProgression{}, errors.New("content store: invalid Hero template progression")
	}
	return out, nil
}

func (Store) HeroNormalEvolutionTx(ctx context.Context, q tx.Queryer, revision string, targetStar int64) (character.HeroEvolutionPolicy, error) {
	if q == nil || len(revision) != 64 || targetStar < 2 || targetStar > 5 {
		return character.HeroEvolutionPolicy{}, errors.New("content store: invalid Normal Hero evolution lookup")
	}
	var out character.HeroEvolutionPolicy
	if err := q.QueryRow(ctx, contentqueries.ReadHeroNormalEvolution, revision, targetStar).Scan(&out.FragmentCount, &out.Mana); err != nil {
		return character.HeroEvolutionPolicy{}, err
	}
	if out.FragmentCount < 0 || out.Mana < 0 {
		return character.HeroEvolutionPolicy{}, errors.New("content store: invalid Normal Hero evolution policy")
	}
	out.Effective = true
	return out, nil
}

func (Store) HeroSuperEvolutionTx(ctx context.Context, q tx.Queryer, revision string, targetStar int64) (character.HeroEvolutionPolicy, error) {
	if q == nil || len(revision) != 64 || targetStar < 2 || targetStar > character.MaxHeroStar {
		return character.HeroEvolutionPolicy{}, errors.New("content store: invalid Super Hero evolution lookup")
	}
	var out character.HeroEvolutionPolicy
	if err := q.QueryRow(ctx, contentqueries.ReadHeroSuperEvolution, revision, targetStar).Scan(&out.FragmentCount, &out.Mana, &out.NeedHeroNum, &out.Effective); err != nil {
		return character.HeroEvolutionPolicy{}, err
	}
	if out.FragmentCount < 0 || out.Mana < 0 || out.NeedHeroNum < 0 || !out.Effective {
		return character.HeroEvolutionPolicy{}, errors.New("content store: invalid/inactive Super Hero evolution policy")
	}
	return out, nil
}

func (Store) HeroSuperPrerequisitesTx(ctx context.Context, q tx.Queryer, revision string, superTableID int64) ([]int64, error) {
	if q == nil || len(revision) != 64 || superTableID <= 0 {
		return nil, errors.New("content store: invalid Super Hero prerequisite lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadHeroSuperPrerequisites, revision, superTableID).Scan(&raw); err != nil {
		return nil, err
	}
	var out []int64
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	if len(out) != 5 {
		return nil, errors.New("content store: invalid Super Hero prerequisite count")
	}
	seen := map[int64]struct{}{}
	for _, id := range out {
		if id <= 0 {
			return nil, errors.New("content store: invalid Super Hero prerequisite")
		}
		if _, ok := seen[id]; ok {
			return nil, errors.New("content store: duplicate Super Hero prerequisite")
		}
		seen[id] = struct{}{}
	}
	return out, nil
}

func (s Store) HeroPieceMappings(ctx context.Context, revision string) ([]character.HeroPieceMapping, error) {
	if s.Queryer == nil || len(revision) != 64 {
		return nil, errors.New("content store: invalid Hero piece mapping lookup")
	}
	var raw string
	if err := s.Queryer.QueryRow(ctx, contentqueries.ReadHeroPieceMappings, revision).Scan(&raw); err != nil {
		return nil, err
	}
	var out []character.HeroPieceMapping
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	if len(out) != 291 {
		return nil, errors.New("content store: incomplete Hero piece mapping")
	}
	seenItem, seenOrigin := map[int64]struct{}{}, map[int64]struct{}{}
	for _, x := range out {
		if x.ItemID <= 0 || x.OriginTableID <= 0 {
			return nil, errors.New("content store: invalid Hero piece mapping")
		}
		if _, ok := seenItem[x.ItemID]; ok {
			return nil, errors.New("content store: duplicate Hero piece item")
		}
		if _, ok := seenOrigin[x.OriginTableID]; ok {
			return nil, errors.New("content store: duplicate Hero piece origin")
		}
		seenItem[x.ItemID], seenOrigin[x.OriginTableID] = struct{}{}, struct{}{}
	}
	return out, nil
}

func (Store) HeroAcquisitionByItemTx(ctx context.Context, q tx.Queryer, revision string, itemID int64) (character.HeroAcquisitionTemplate, error) {
	if q == nil || len(revision) != 64 || itemID <= 0 {
		return character.HeroAcquisitionTemplate{}, errors.New("content store: invalid Hero acquisition item lookup")
	}
	var out character.HeroAcquisitionTemplate
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadHeroAcquisitionByItem, revision, itemID).Scan(&out.TableID, &out.OriginTableID, &raw, &out.InitialStar, &out.FragmentItemID); err != nil {
		return character.HeroAcquisitionTemplate{}, err
	}
	out.Kind = character.HeroKind(raw)
	if out.TableID <= 0 || out.OriginTableID != out.TableID || (out.Kind != character.NormalHero && out.Kind != character.SuperHero) || out.InitialStar < 1 || out.InitialStar > character.MaxHeroStar || out.FragmentItemID < 0 {
		return character.HeroAcquisitionTemplate{}, errors.New("content store: invalid Hero acquisition mapping")
	}
	return out, nil
}

func (Store) HeroNormalSummonTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) (character.HeroNormalSummonPolicy, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return character.HeroNormalSummonPolicy{}, errors.New("content store: invalid Hero summon lookup")
	}
	var out character.HeroNormalSummonPolicy
	var kind = character.NormalHero
	out.Template.Kind = kind
	if err := q.QueryRow(ctx, contentqueries.ReadHeroNormalSummon, revision, tableID).Scan(&out.Template.TableID, &out.Template.OriginTableID, &out.Template.InitialStar, &out.Template.FragmentItemID, &out.FragmentCount, &out.Mana); err != nil {
		return character.HeroNormalSummonPolicy{}, err
	}
	if out.Template.TableID <= 0 || out.Template.OriginTableID != out.Template.TableID || out.Template.InitialStar < 1 || out.Template.InitialStar > 5 || out.Template.FragmentItemID <= 0 || out.FragmentCount <= 0 || out.Mana <= 0 {
		return character.HeroNormalSummonPolicy{}, errors.New("content store: invalid Hero summon policy")
	}
	return out, nil
}

func (Store) HeroVowsRequiredLevelTx(ctx context.Context, q tx.Queryer, revision string) (int64, error) {
	if q == nil || len(revision) != 64 {
		return 0, errors.New("content store: invalid Vows level lookup")
	}
	var level int64
	if err := q.QueryRow(ctx, contentqueries.ReadHeroVowsRequiredLevel, revision).Scan(&level); err != nil {
		return 0, err
	}
	if level <= 0 {
		return 0, errors.New("content store: invalid Vows required level")
	}
	return level, nil
}
