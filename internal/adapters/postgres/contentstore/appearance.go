package contentstore

import (
	"context"
	"database/sql"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Store) AppearanceActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil appearance queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, characterasset.AppearanceContentCapability)
	return summary.Activation.RevisionID, good, err
}

func (s Store) AppearanceRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil {
		return false, errors.New("content store: nil appearance revision queryer")
	}
	return (Store{}).AppearanceRevisionTx(ctx, s.Queryer, revision)
}

func (Store) AppearanceRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	if q == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid appearance revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, characterasset.AppearanceContentCapability)
}

func (s Store) AppearanceSkin(ctx context.Context, revision string, modelID int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	if s.Queryer == nil {
		return characterasset.AppearanceSkinDefinition{}, false, errors.New("content store: nil appearance skin queryer")
	}
	return (Store{}).AppearanceSkinTx(ctx, s.Queryer, revision, modelID)
}

func (Store) AppearanceSkinTx(ctx context.Context, q tx.Queryer, revision string, modelID int64) (characterasset.AppearanceSkinDefinition, bool, error) {
	if q == nil || len(revision) != 64 || modelID <= 0 {
		return characterasset.AppearanceSkinDefinition{}, false, errors.New("content store: invalid appearance skin lookup")
	}
	out := characterasset.AppearanceSkinDefinition{ModelID: modelID}
	if err := q.QueryRow(ctx, contentqueries.ReadAppearanceSkinDefinition, revision, modelID).Scan(&out.HeroOriginTableID, &out.SkinSkillID); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return characterasset.AppearanceSkinDefinition{}, false, nil
		}
		return characterasset.AppearanceSkinDefinition{}, false, err
	}
	if err := out.Validate(); err != nil {
		return characterasset.AppearanceSkinDefinition{}, false, err
	}
	return out, true, nil
}

func (s Store) AppearanceSkinItem(ctx context.Context, revision string, itemID int64) (characterasset.AppearanceSkinItemDefinition, bool, error) {
	if s.Queryer == nil {
		return characterasset.AppearanceSkinItemDefinition{}, false, errors.New("content store: nil appearance skin item queryer")
	}
	return (Store{}).AppearanceSkinItemTx(ctx, s.Queryer, revision, itemID)
}

func (Store) AppearanceSkinItemTx(ctx context.Context, q tx.Queryer, revision string, itemID int64) (characterasset.AppearanceSkinItemDefinition, bool, error) {
	if q == nil || len(revision) != 64 || itemID <= 0 {
		return characterasset.AppearanceSkinItemDefinition{}, false, errors.New("content store: invalid appearance skin item lookup")
	}
	out := characterasset.AppearanceSkinItemDefinition{ItemID: itemID}
	var duration sql.NullInt64
	if err := q.QueryRow(ctx, contentqueries.ReadAppearanceSkinItem, revision, itemID).Scan(&out.ModelID, &out.HeroOriginTableID, &duration); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return characterasset.AppearanceSkinItemDefinition{}, false, nil
		}
		return characterasset.AppearanceSkinItemDefinition{}, false, err
	}
	if duration.Valid {
		out.DurationSeconds = duration.Int64
	}
	if err := out.Validate(); err != nil {
		return characterasset.AppearanceSkinItemDefinition{}, false, err
	}
	return out, true, nil
}

func (s Store) AppearanceLIVE(ctx context.Context, revision string, modelID int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	if s.Queryer == nil {
		return characterasset.AppearanceLIVEDefinition{}, false, errors.New("content store: nil appearance LIVE queryer")
	}
	return (Store{}).AppearanceLIVETx(ctx, s.Queryer, revision, modelID)
}

func (Store) AppearanceLIVETx(ctx context.Context, q tx.Queryer, revision string, modelID int64) (characterasset.AppearanceLIVEDefinition, bool, error) {
	if q == nil || len(revision) != 64 || modelID <= 0 {
		return characterasset.AppearanceLIVEDefinition{}, false, errors.New("content store: invalid appearance LIVE lookup")
	}
	out := characterasset.AppearanceLIVEDefinition{ModelID: modelID}
	if err := q.QueryRow(ctx, contentqueries.ReadAppearanceLIVE, revision, modelID).Scan(&out.HeroOriginTableID, &out.CrystalCost, &out.ActivationItemID, &out.ActivationItemCount); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return characterasset.AppearanceLIVEDefinition{}, false, nil
		}
		return characterasset.AppearanceLIVEDefinition{}, false, err
	}
	if err := out.Validate(); err != nil {
		return characterasset.AppearanceLIVEDefinition{}, false, err
	}
	return out, true, nil
}

func (s Store) AppearancePetStyle(ctx context.Context, revision string, styleItemID int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	if s.Queryer == nil {
		return characterasset.AppearancePetStyleDefinition{}, false, errors.New("content store: nil appearance Pet-style queryer")
	}
	return (Store{}).AppearancePetStyleTx(ctx, s.Queryer, revision, styleItemID)
}

func (Store) AppearancePetStyleTx(ctx context.Context, q tx.Queryer, revision string, styleItemID int64) (characterasset.AppearancePetStyleDefinition, bool, error) {
	if q == nil || len(revision) != 64 || styleItemID <= 0 {
		return characterasset.AppearancePetStyleDefinition{}, false, errors.New("content store: invalid appearance Pet-style lookup")
	}
	out := characterasset.AppearancePetStyleDefinition{StyleItemID: styleItemID}
	if err := q.QueryRow(ctx, contentqueries.ReadAppearancePetStyle, revision, styleItemID).Scan(&out.PetOriginTableID); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return characterasset.AppearancePetStyleDefinition{}, false, nil
		}
		return characterasset.AppearancePetStyleDefinition{}, false, err
	}
	if err := out.Validate(); err != nil {
		return characterasset.AppearancePetStyleDefinition{}, false, err
	}
	return out, true, nil
}
