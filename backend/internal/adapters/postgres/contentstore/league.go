package contentstore

import (
	"context"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const leagueCapability = "CHAMPIONS_LEAGUE_I7C5F"

var leagueCatalogs sync.Map

// LeagueCatalogTx reads only the caller-pinned immutable revision.
func (s Store) LeagueCatalogTx(ctx context.Context, q tx.Queryer, revision string) (championsleague.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return championsleague.Catalog{}, championsleague.ErrUnavailable
	}
	if cached, ok := leagueCatalogs.Load(revision); ok {
		return cached.(championsleague.Catalog), nil
	}
	var out championsleague.Catalog
	e := readModeCatalog(ctx, q, revision, leagueCapability, "content_league_catalogs", "league_catalog.json", &out)
	if errors.Is(e, errModeCatalog) {
		return championsleague.Catalog{}, championsleague.ErrUnavailable
	}
	if e != nil {
		return championsleague.Catalog{}, e
	}
	if e = out.Validate(); e != nil {
		return championsleague.Catalog{}, e
	}
	leagueCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertLeague(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_league_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.LeagueJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyLeagueSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_league_catalogs WHERE revision_id=$1`
