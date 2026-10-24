package contentstore

import (
	"context"
	"encoding/json"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const arenaCapability = "ARENA_MODE_I7C5D"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var arenaCatalogs sync.Map

// ArenaCatalogTx reads only the caller-pinned immutable revision.
func (s Store) ArenaCatalogTx(ctx context.Context, q tx.Queryer, revision string) (arena.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return arena.Catalog{}, arena.ErrUnavailable
	}
	if cached, ok := arenaCatalogs.Load(revision); ok {
		return cached.(arena.Catalog), nil
	}
	var out arena.Catalog
	e := readModeCatalog(ctx, q, revision, arenaCapability, "content_arena_catalogs", "arena_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return arena.Catalog{}, arena.ErrUnavailable
	}
	if e != nil {
		return arena.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return arena.Catalog{}, e
	}
	arenaCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertArena(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_arena_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.ArenaJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyArenaSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_arena_catalogs WHERE revision_id=$1`

var arenaTemplates sync.Map

// ArenaTemplatesTx reads the hero template lineage of the pinned revision.
func (s Store) ArenaTemplatesTx(ctx context.Context, q tx.Queryer, revision string) (arena.Templates, error) {
	if q == nil || len(revision) != 64 {
		return nil, arena.ErrUnavailable
	}
	if cached, ok := arenaTemplates.Load(revision); ok {
		return cached.(arena.Templates), nil
	}
	var raw string
	if err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_array(table_id,origin_table_id,kind='SUPER',is_awakened,initial_star) ORDER BY table_id),'[]'::jsonb)::text FROM gxb_content_hero_templates WHERE revision_id=$1`, revision).Scan(&raw); err != nil {
		return nil, err
	}
	var rows [][5]json.RawMessage
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := arena.Templates{}
	for _, r := range rows {
		var id, base, star int64
		var super, awakened bool
		for i, dst := range []any{&id, &base, &super, &awakened, &star} {
			if err := json.Unmarshal(r[i], dst); err != nil {
				return nil, err
			}
		}
		out[id] = arena.Template{Base: base, Super: super, Awakened: awakened, InitialStar: star}
	}
	if len(out) == 0 {
		return nil, arena.ErrUnavailable
	}
	arenaTemplates.Store(revision, out)
	return out, nil
}
