package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const adventureCapability = "ADVENTURE_I9_8D"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var adventureCatalogs sync.Map

// AdventureCatalogTx reads only the caller-pinned immutable revision.
func (s Store) AdventureCatalogTx(ctx context.Context, q tx.Queryer, revision string) (adventure.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return adventure.Catalog{}, adventure.ErrUnavailable
	}
	if cached, ok := adventureCatalogs.Load(revision); ok {
		return cached.(adventure.Catalog), nil
	}
	var out adventure.Catalog
	e := readModeCatalog(ctx, q, revision, adventureCapability, "content_adventure_catalogs", "adventure_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return adventure.Catalog{}, adventure.ErrUnavailable
	}
	if e != nil {
		return adventure.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return adventure.Catalog{}, e
	}
	adventureCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertAdventure(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_adventure_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.AdventureJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyAdventureSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_adventure_catalogs WHERE revision_id=$1`
