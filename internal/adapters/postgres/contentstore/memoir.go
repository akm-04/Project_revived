package contentstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
)

var memoirCatalogs sync.Map

func (store Store) MemoirCatalogTx(ctx context.Context, query tx.Queryer, revision string) (memoir.Catalog, error) {
	if query == nil || len(revision) != 64 {
		return memoir.Catalog{}, memoir.ErrUnavailable
	}
	return memoCatalog(&memoirCatalogs, revision, func() (memoir.Catalog, error) {
		var catalog memoir.Catalog
		err := readModeCatalog(ctx, query, revision, "MEMOIR_I9_6C", "content_memoir_catalogs", "memoir_catalog.json", &catalog)
		if errors.Is(err, errModeCatalog) {
			return catalog, memoir.ErrUnavailable
		}
		if err != nil {
			return catalog, err
		}
		return catalog, catalog.Validate()
	})
}
func (Store) InsertMemoir(ctx context.Context, transaction tx.Tx, bundle registry.Bundle) (int64, error) {
	result, err := transaction.Exec(ctx, `INSERT INTO content_memoir_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, bundle.RevisionID(), string(bundle.MemoirJSON()))
	if err != nil {
		return 0, err
	}
	return result.RowsAffected(), nil
}

const verifyMemoirSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_memoir_catalogs WHERE revision_id=$1`
