package contentstore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const equipmentPrimitivesCapability = "EQUIPMENT_PRIMITIVES_CA4"

func (s Store) EquipmentPrimitivesActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil equipment-primitives queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, equipmentPrimitivesCapability)
	return summary.Activation.RevisionID, good, err
}

func (s Store) EquipmentPrimitivesRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid equipment-primitives revision")
	}
	var raw string
	if err := s.Queryer.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, equipmentPrimitivesCapability)
}

func (Store) EquipmentPrimitiveTx(ctx context.Context, q tx.Queryer, revision string, itemID int64) (character.EquipmentPrimitive, error) {
	if q == nil || len(revision) != 64 || itemID <= 0 {
		return character.EquipmentPrimitive{}, errors.New("content store: invalid equipment primitive lookup")
	}
	out := character.EquipmentPrimitive{ItemID: character.EquipmentTemplateID(itemID)}
	if err := q.QueryRow(ctx, contentqueries.ReadEquipmentPrimitive, revision, itemID).Scan(&out.SourceItemType, &out.RequiredLevel, &out.ComposeMana); err != nil {
		return character.EquipmentPrimitive{}, err
	}
	if err := out.Validate(); err != nil {
		return character.EquipmentPrimitive{}, err
	}
	return out, nil
}

func (Store) EquipmentRecipeEdgesTx(ctx context.Context, q tx.Queryer, revision string, parentItemID int64) ([]character.EquipmentRecipeEdge, error) {
	if q == nil || len(revision) != 64 || parentItemID <= 0 {
		return nil, errors.New("content store: invalid equipment recipe lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadEquipmentRecipeEdges, revision, parentItemID).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		Ordinal         int64 `json:"ordinal"`
		ComponentItemID int64 `json:"component_item_id"`
		ComponentCount  int64 `json:"component_count"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]character.EquipmentRecipeEdge, 0, len(rows))
	for i, row := range rows {
		// Source ordinals are preserved exactly and expected to be dense from one
		// in the CA4-1 compiler artifact. Duplicate component ids remain legal.
		if row.Ordinal != int64(i+1) {
			return nil, errors.New("content store: non-canonical equipment recipe ordinal")
		}
		edge := character.EquipmentRecipeEdge{
			ParentItemID:    character.EquipmentTemplateID(parentItemID),
			Ordinal:         row.Ordinal,
			ComponentItemID: character.EquipmentTemplateID(row.ComponentItemID),
			ComponentCount:  row.ComponentCount,
		}
		if err := edge.Validate(); err != nil {
			return nil, err
		}
		out = append(out, edge)
	}
	return out, nil
}
