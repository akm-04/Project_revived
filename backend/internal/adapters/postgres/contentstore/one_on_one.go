package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const oneOnOneCapability = "ONE_ON_ONE_MODE_I7C5C"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var oneOnOneCatalogs sync.Map

// OneOnOneCatalogTx reads only the caller-pinned immutable revision.
func (s Store) OneOnOneCatalogTx(ctx context.Context, q tx.Queryer, revision string) (oneonone.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return oneonone.Catalog{}, oneonone.ErrUnavailable
	}
	if cached, ok := oneOnOneCatalogs.Load(revision); ok {
		return cached.(oneonone.Catalog), nil
	}
	var out oneonone.Catalog
	e := readModeCatalog(ctx, q, revision, oneOnOneCapability, "content_one_on_one_catalogs", "one_on_one_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return oneonone.Catalog{}, oneonone.ErrUnavailable
	}
	if e != nil {
		return oneonone.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return oneonone.Catalog{}, e
	}
	oneOnOneCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertOneOnOne(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_one_on_one_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.OneOnOneJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyOneOnOneSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_one_on_one_catalogs WHERE revision_id=$1`
