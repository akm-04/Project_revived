package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const marchCapability = "CHAMPION_MARCH_I9_5A"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var marchCatalogs sync.Map

// MarchCatalogTx reads only the caller-pinned immutable revision.
func (s Store) MarchCatalogTx(ctx context.Context, q tx.Queryer, revision string) (march.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return march.Catalog{}, march.ErrUnavailable
	}
	if cached, ok := marchCatalogs.Load(revision); ok {
		return cached.(march.Catalog), nil
	}
	var out march.Catalog
	e := readModeCatalog(ctx, q, revision, marchCapability, "content_march_catalogs", "march_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return march.Catalog{}, march.ErrUnavailable
	}
	if e != nil {
		return march.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return march.Catalog{}, e
	}
	marchCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertMarch(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_march_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.MarchJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyMarchSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_march_catalogs WHERE revision_id=$1`
