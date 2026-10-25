package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const summonCapability = "SUMMON_GACHA_I9_3E"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var summonCatalogs sync.Map

// SummonCatalogTx reads only the caller-pinned immutable revision.
func (s Store) SummonCatalogTx(ctx context.Context, q tx.Queryer, revision string) (summon.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return summon.Catalog{}, summon.ErrUnavailable
	}
	if cached, ok := summonCatalogs.Load(revision); ok {
		return cached.(summon.Catalog), nil
	}
	var out summon.Catalog
	e := readModeCatalog(ctx, q, revision, summonCapability, "content_summon_catalogs", "summon_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return summon.Catalog{}, summon.ErrUnavailable
	}
	if e != nil {
		return summon.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return summon.Catalog{}, e
	}
	summonCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertSummon(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_summon_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.SummonJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifySummonSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_summon_catalogs WHERE revision_id=$1`
