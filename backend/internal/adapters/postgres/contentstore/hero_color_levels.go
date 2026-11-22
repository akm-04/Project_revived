package contentstore

import (
	"context"
	"encoding/json"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	marchdomain "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Immutable revisions keep one derived table per revision.
var heroColorLevels sync.Map

// HeroColorLevelsTx derives each Normal-Hero template's cumulative colour level
// table from its ordinary equipment positions and the equipment required
// levels. The read is pinned to the caller's revision.
func (s Store) HeroColorLevelsTx(ctx context.Context, q tx.Queryer, revision string) (map[int64]marchdomain.HeroColorLevels, error) {
	if q == nil || len(revision) != 64 {
		return nil, errors.New("content store: invalid Hero colour level lookup")
	}
	good, err := storedCapability(ctx, q, revision, heroEquipmentCapability)
	if err != nil {
		return nil, err
	}
	if !good {
		return nil, errors.New("content store: Hero equipment capability inactive")
	}
	return memoCatalog(&heroColorLevels, revision, func() (map[int64]marchdomain.HeroColorLevels, error) {
		return heroColorLevelsTx(ctx, q, revision)
	})
}

func heroColorLevelsTx(ctx context.Context, q tx.Queryer, revision string) (map[int64]marchdomain.HeroColorLevels, error) {
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadHeroColorRequiredLevels, revision).Scan(&raw); err != nil {
		return nil, err
	}
	var rows [][3]int64
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	requiredByTable := map[int64]map[int64]int64{}
	for _, row := range rows {
		tableID, color, required := row[0], row[1], row[2]
		if tableID <= 0 || color < 1 || color > 16 || required < 0 || required > 100 {
			return nil, errors.New("content store: invalid Hero colour level row")
		}
		byColor := requiredByTable[tableID]
		if byColor == nil {
			byColor = map[int64]int64{}
			requiredByTable[tableID] = byColor
		}
		byColor[color] = required
	}
	out := make(map[int64]marchdomain.HeroColorLevels, len(requiredByTable))
	for tableID, byColor := range requiredByTable {
		levels, err := marchdomain.HeroColorLevelsFromColorRequiredLevels(byColor)
		if err != nil {
			return nil, err
		}
		out[tableID] = levels
	}
	return out, nil
}
