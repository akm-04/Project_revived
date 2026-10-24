package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const topFloorCapability = "TOP_FLOOR_MODE_I7C5B"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var topFloorCatalogs sync.Map

// TopFloorCatalogTx reads only the caller-pinned immutable revision.
func (s Store) TopFloorCatalogTx(ctx context.Context, q tx.Queryer, revision string) (topfloor.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return topfloor.Catalog{}, topfloor.ErrUnavailable
	}
	if cached, ok := topFloorCatalogs.Load(revision); ok {
		return cached.(topfloor.Catalog), nil
	}
	var out topfloor.Catalog
	e := readModeCatalog(ctx, q, revision, topFloorCapability, "content_top_floor_catalogs", "top_floor_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return topfloor.Catalog{}, topfloor.ErrUnavailable
	}
	if e != nil {
		return topfloor.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return topfloor.Catalog{}, e
	}
	topFloorCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertTopFloor(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_top_floor_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.TopFloorJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyTopFloorSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_top_floor_catalogs WHERE revision_id=$1`
