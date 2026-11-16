// Package playerdatastore executes the generated player restore plan for the
// I11A export command. It keeps rows as whole-row jsonb, never as store payloads.
package playerdatastore

import (
	"context"
	"encoding/json"
	"fmt"

	"gxb.local/backend/v2/internal/application/playerdata"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

var _ playerdata.Reader = Store{}

func (Store) GooseVersion(ctx context.Context, query tx.Queryer) (int64, error) {
	var version int64
	if err := query.QueryRow(ctx, `SELECT COALESCE(max(version_id),0) FROM goose_db_version WHERE is_applied`).Scan(&version); err != nil {
		return 0, err
	}
	return version, nil
}

// SelectRows returns the plan selection's rows in a stable order. Ordering by
// the canonical row JSON keeps two exports of unchanged state byte-equal.
func (Store) SelectRows(ctx context.Context, query tx.Queryer, selection string, playerID int64) ([]json.RawMessage, error) {
	var raw string
	sql := `SELECT COALESCE(jsonb_agg(to_jsonb(entry) ORDER BY to_jsonb(entry)::text),'[]'::jsonb)::text FROM (` + selection + `) entry`
	if err := query.QueryRow(ctx, sql, playerArgument(selection, playerID)).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []json.RawMessage
	// payload: not a stored player payload (the whole exported row set)
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, fmt.Errorf("decode exported rows: %w", err)
	}
	if rows == nil {
		rows = []json.RawMessage{}
	}
	return rows, nil
}
