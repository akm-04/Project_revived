package contentstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) AwakeningCatalogTx(c context.Context, q tx.Queryer, revision string) (objective.AwakeCatalog, error) {
	var out objective.AwakeCatalog
	if q == nil || len(revision) != 64 {
		return out, errors.New("awakening content revision required")
	}
	var raw string
	if e := q.QueryRow(c, `SELECT payload::text FROM content_awakening_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return out, e
	}
	if e := json.Unmarshal([]byte(raw), &out); e != nil {
		return out, e
	}
	return out, out.Validate()
}
