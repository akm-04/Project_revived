package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const illusionCapability = "ILLUSION_I9_8B"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var illusionCatalogs sync.Map

// IllusionCatalogTx reads only the caller-pinned immutable revision.
func (s Store) IllusionCatalogTx(ctx context.Context, q tx.Queryer, revision string) (illusion.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return illusion.Catalog{}, illusion.ErrUnavailable
	}
	if cached, ok := illusionCatalogs.Load(revision); ok {
		return cached.(illusion.Catalog), nil
	}
	var out illusion.Catalog
	e := readModeCatalog(ctx, q, revision, illusionCapability, "content_illusion_catalogs", "illusion_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return illusion.Catalog{}, illusion.ErrUnavailable
	}
	if e != nil {
		return illusion.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return illusion.Catalog{}, e
	}
	illusionCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertIllusion(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_illusion_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.IllusionJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyIllusionSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_illusion_catalogs WHERE revision_id=$1`
