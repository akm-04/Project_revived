package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const conquerModeCapability = "CONQUER_MODE_I7C5E"

var conquerModeCatalogs sync.Map

// ConquerModeCatalogTx reads only the caller-pinned immutable revision.
func (s Store) ConquerModeCatalogTx(ctx context.Context, q tx.Queryer, revision string) (conquerschool.ModeCatalog, error) {
	if q == nil || len(revision) != 64 {
		return conquerschool.ModeCatalog{}, conquerschool.ErrUnavailable
	}
	if cached, ok := conquerModeCatalogs.Load(revision); ok {
		return cached.(conquerschool.ModeCatalog), nil
	}
	var out conquerschool.ModeCatalog
	e := readModeCatalog(ctx, q, revision, conquerModeCapability, "content_conquer_mode_catalogs", "conquer_mode_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return conquerschool.ModeCatalog{}, conquerschool.ErrUnavailable
	}
	if e != nil {
		return conquerschool.ModeCatalog{}, e
	}
	if e = out.Validate(); e != nil {
		return conquerschool.ModeCatalog{}, e
	}
	conquerModeCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertConquerMode(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_conquer_mode_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.ConquerModeJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyConquerModeSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_conquer_mode_catalogs WHERE revision_id=$1`
