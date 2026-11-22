package operatorstore

import (
	"context"
	"encoding/json"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const listCommands = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'semantic_key',semantic_key,'module_command',module_command,'payload_sha256',payload_sha256,
	'principal',principal,'role',role,'scope',scope,'reason',reason,'state',state,
	'result',result_json,'created_at',created_at,'finished_at',finished_at)
	ORDER BY created_at DESC, semantic_key DESC),'[]'::jsonb)::text
FROM (
	SELECT semantic_key,module_command,payload_sha256,principal,role,scope,reason,state,result_json,created_at,finished_at
	FROM operator_commands
	WHERE ($1::timestamptz IS NULL OR created_at >= $1)
	  AND ($2::timestamptz IS NULL OR created_at <= $2)
	  AND ($3 = '' OR module_command = $3)
	  AND ($4 = '' OR principal = $4)
	  AND ($5 = '' OR semantic_key = $5)
	  AND ($6::timestamptz IS NULL OR (created_at, semantic_key) < ($6::timestamptz, $7))
	ORDER BY created_at DESC, semantic_key DESC
	LIMIT $8
) page`

// ListCommandsTx returns at most filter.Limit audit rows, newest first.
func (Store) ListCommandsTx(ctx context.Context, query tx.Queryer, filter operator.AuditFilter) ([]operator.Record, error) {
	if query == nil {
		return nil, errInvalid
	}
	var cursorAt *time.Time
	cursorKey := ""
	if filter.Cursor != nil {
		at := filter.Cursor.CreatedAt.UTC()
		cursorAt, cursorKey = &at, filter.Cursor.SemanticKey
	}
	var raw string
	if err := query.QueryRow(ctx, listCommands, filter.From, filter.To, filter.Module, filter.Principal, filter.SemanticKey, cursorAt, cursorKey, filter.Limit).Scan(&raw); err != nil {
		return nil, err
	}
	var records []operator.Record
	if err := json.Unmarshal([]byte(raw), &records); err != nil {
		return nil, err
	}
	return records, nil
}

// GooseVersionTx reads the highest applied goose migration.
func (Store) GooseVersionTx(ctx context.Context, query tx.Queryer) (int64, error) {
	if query == nil {
		return 0, errInvalid
	}
	var version int64
	if err := query.QueryRow(ctx, `SELECT COALESCE(max(version_id),0) FROM goose_db_version WHERE is_applied`).Scan(&version); err != nil {
		return 0, err
	}
	return version, nil
}
