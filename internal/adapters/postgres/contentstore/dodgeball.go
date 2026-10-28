package contentstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
)

var dodgeballCatalogs sync.Map

func (store Store) DodgeballCatalogTx(ctx context.Context, query tx.Queryer, revision string) (dodgeball.Catalog, error) {
	if query == nil || len(revision) != 64 {
		return dodgeball.Catalog{}, dodgeball.ErrUnavailable
	}
	return memoCatalog(&dodgeballCatalogs, revision, func() (dodgeball.Catalog, error) {
		var catalog dodgeball.Catalog
		err := readModeCatalog(ctx, query, revision, "DODGEBALL_I9_6B", "content_dodgeball_catalogs", "dodgeball_catalog.json", &catalog)
		if errors.Is(err, errModeCatalog) {
			return catalog, dodgeball.ErrUnavailable
		}
		if err != nil {
			return catalog, err
		}
		return catalog, catalog.Validate()
	})
}
func (Store) InsertDodgeball(ctx context.Context, transaction tx.Tx, bundle registry.Bundle) (int64, error) {
	result, err := transaction.Exec(ctx, `INSERT INTO content_dodgeball_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, bundle.RevisionID(), string(bundle.DodgeballJSON()))
	if err != nil {
		return 0, err
	}
	return result.RowsAffected(), nil
}

const verifyDodgeballSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_dodgeball_catalogs WHERE revision_id=$1`
