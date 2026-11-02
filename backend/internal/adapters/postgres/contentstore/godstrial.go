package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const godstrialCapability = "GODS_TRIAL_I9_6A"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var godstrialCatalogs sync.Map

// GodsTrialCatalogTx reads only the caller-pinned immutable revision.
func (s Store) GodsTrialCatalogTx(ctx context.Context, q tx.Queryer, revision string) (godstrial.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return godstrial.Catalog{}, godstrial.ErrUnavailable
	}
	if cached, ok := godstrialCatalogs.Load(revision); ok {
		return cached.(godstrial.Catalog), nil
	}
	var out godstrial.Catalog
	e := readModeCatalog(ctx, q, revision, godstrialCapability, "content_gods_trial_catalogs", "gods_trial_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return godstrial.Catalog{}, godstrial.ErrUnavailable
	}
	if e != nil {
		return godstrial.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return godstrial.Catalog{}, e
	}
	godstrialCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertGodsTrial(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_gods_trial_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.GodsTrialJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyGodsTrialSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_gods_trial_catalogs WHERE revision_id=$1`
