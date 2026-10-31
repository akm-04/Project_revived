package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const occultCapability = "OCCULT_I9_8C"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var occultCatalogs sync.Map

// OccultCatalogTx reads only the caller-pinned immutable revision.
func (s Store) OccultCatalogTx(ctx context.Context, q tx.Queryer, revision string) (occult.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return occult.Catalog{}, occult.ErrUnavailable
	}
	if cached, ok := occultCatalogs.Load(revision); ok {
		return cached.(occult.Catalog), nil
	}
	var out occult.Catalog
	e := readModeCatalog(ctx, q, revision, occultCapability, "content_occult_catalogs", "occult_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return occult.Catalog{}, occult.ErrUnavailable
	}
	if e != nil {
		return occult.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return occult.Catalog{}, e
	}
	occultCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertOccult(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_occult_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.OccultJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyOccultSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_occult_catalogs WHERE revision_id=$1`
