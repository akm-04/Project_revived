package contentstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) SignInCatalogTx(c context.Context, q tx.Queryer, revision string) (objective.SignCatalog, error) {
	if q == nil || len(revision) != 64 {
		return objective.SignCatalog{}, errors.New("sign-in content revision required")
	}
	var raw string
	if err := q.QueryRow(c, `SELECT payload::text FROM content_monthly_signin_catalogs WHERE revision_id=$1`, revision).Scan(&raw); err != nil {
		return objective.SignCatalog{}, err
	}
	var out objective.SignCatalog
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return out, err
	}
	return out, out.Validate()
}
