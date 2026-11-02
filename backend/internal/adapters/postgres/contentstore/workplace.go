package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const workplaceCapability = "WORKPLACE_I9_5B"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var workplaceCatalogs sync.Map

// WorkplaceCatalogTx reads only the caller-pinned immutable revision.
func (s Store) WorkplaceCatalogTx(ctx context.Context, q tx.Queryer, revision string) (workplace.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return workplace.Catalog{}, workplace.ErrUnavailable
	}
	if cached, ok := workplaceCatalogs.Load(revision); ok {
		return cached.(workplace.Catalog), nil
	}
	var out workplace.Catalog
	e := readModeCatalog(ctx, q, revision, workplaceCapability, "content_workplace_catalogs", "workplace_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return workplace.Catalog{}, workplace.ErrUnavailable
	}
	if e != nil {
		return workplace.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return workplace.Catalog{}, e
	}
	workplaceCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertWorkplace(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_workplace_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.WorkplaceJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyWorkplaceSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_workplace_catalogs WHERE revision_id=$1`
