package contentstore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroOriginCatalogTx reads only Content-owned immutable root templates. It
// neither discovers a current revision nor reads a player's roster or capacity.
func (Store) HeroOriginCatalogTx(c context.Context, q tx.Queryer, revision string) ([]int64, error) {
	if q == nil || len(revision) != 64 {
		return nil, errors.New("content: invalid Hero origin catalog scope")
	}
	var raw string
	if e := q.QueryRow(c, contentqueries.ReadHeroOriginCatalog, revision).Scan(&raw); e != nil {
		return nil, e
	}
	var out []int64
	if e := json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	if len(out) == 0 {
		return nil, errors.New("content: unavailable Hero origin catalog")
	}
	for i, id := range out {
		if id <= 0 || id > 9007199254740991 || i > 0 && id <= out[i-1] {
			return nil, errors.New("content: malformed Hero origin catalog")
		}
	}
	return out, nil
}
