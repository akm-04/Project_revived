package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const worldBossCapability = "WORLD_BOSS_I9_8A"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var worldBossCatalogs sync.Map

// WorldBossCatalogTx reads only the caller-pinned immutable revision.
func (s Store) WorldBossCatalogTx(ctx context.Context, q tx.Queryer, revision string) (worldboss.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return worldboss.Catalog{}, worldboss.ErrUnavailable
	}
	if cached, ok := worldBossCatalogs.Load(revision); ok {
		return cached.(worldboss.Catalog), nil
	}
	var out worldboss.Catalog
	e := readModeCatalog(ctx, q, revision, worldBossCapability, "content_world_boss_catalogs", "world_boss_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return worldboss.Catalog{}, worldboss.ErrUnavailable
	}
	if e != nil {
		return worldboss.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return worldboss.Catalog{}, e
	}
	worldBossCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertWorldBoss(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_world_boss_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.WorldBossJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyWorldBossSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_world_boss_catalogs WHERE revision_id=$1`
