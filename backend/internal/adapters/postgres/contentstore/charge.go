package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const chargeCapability = "COMMERCE_CHARGE_I9_10G"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var chargeCatalogs sync.Map

// ChargeCatalogTx reads only the caller-pinned immutable revision.
func (s Store) ChargeCatalogTx(ctx context.Context, q tx.Queryer, revision string) (privilege.ChargeCatalog, error) {
	if q == nil || len(revision) != 64 {
		return privilege.ChargeCatalog{}, privilege.ErrUnavailable
	}
	if cached, ok := chargeCatalogs.Load(revision); ok {
		return cached.(privilege.ChargeCatalog), nil
	}
	var out privilege.ChargeCatalog
	e := readModeCatalog(ctx, q, revision, chargeCapability, "content_charge_catalogs", "charge_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return privilege.ChargeCatalog{}, privilege.ErrUnavailable
	}
	if e != nil {
		return privilege.ChargeCatalog{}, e
	}
	if e = out.Validate(); e != nil {
		return privilege.ChargeCatalog{}, e
	}
	chargeCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertCharge(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_charge_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.ChargeJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyChargeSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_charge_catalogs WHERE revision_id=$1`
