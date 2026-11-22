package operatorstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const selectBulk = `SELECT semantic_key,module_command,selector,player_ids::text,player_count,player_ids_sha256,payload::text,principal,reason,processed,applied,refused,state,failed_reason,last_error,created_at,updated_at,finished_at FROM operator_bulk_targets`

func scanBulk(row tx.Row) (*operatorgrant.BulkTarget, error) {
	var target operatorgrant.BulkTarget
	var idsRaw, payloadRaw string
	var failedReason *string
	if err := row.Scan(&target.SemanticKey, &target.ModuleCommand, &target.Selector, &idsRaw, &target.PlayerCount, &target.PlayerIDsSHA256, &payloadRaw, &target.Principal, &target.Reason, &target.Processed, &target.Applied, &target.Refused, &target.State, &failedReason, &target.LastError, &target.CreatedAt, &target.UpdatedAt, &target.FinishedAt); err != nil {
		return nil, err
	}
	if err := json.Unmarshal([]byte(idsRaw), &target.PlayerIDs); err != nil {
		return nil, err
	}
	if failedReason != nil {
		target.FailedReason = *failedReason
	}
	target.Payload = json.RawMessage(payloadRaw)
	return &target, nil
}

func (Store) InsertBulkTx(ctx context.Context, transaction tx.Tx, target operatorgrant.BulkTarget) error {
	if transaction == nil || target.SemanticKey == "" || len(target.PlayerIDs) != target.PlayerCount {
		return errInvalid
	}
	ids, err := json.Marshal(target.PlayerIDs)
	if err != nil {
		return err
	}
	_, err = transaction.Exec(ctx, `INSERT INTO operator_bulk_targets(semantic_key,module_command,selector,player_ids,player_count,player_ids_sha256,payload,principal,reason,processed,applied,refused,state,created_at,updated_at)
VALUES($1,$2,$3,$4::jsonb,$5,$6,$7::jsonb,$8,$9,$10,$11,$12,$13,$14,$14)`,
		target.SemanticKey, target.ModuleCommand, target.Selector, string(ids), target.PlayerCount, target.PlayerIDsSHA256, string(target.Payload), target.Principal, target.Reason, target.Processed, target.Applied, target.Refused, target.State, target.CreatedAt.UTC())
	return err
}

func (Store) ReadBulkTx(ctx context.Context, query tx.Queryer, semanticKey string) (*operatorgrant.BulkTarget, error) {
	if query == nil || semanticKey == "" {
		return nil, errInvalid
	}
	target, err := scanBulk(query.QueryRow(ctx, selectBulk+` WHERE semantic_key=$1`, semanticKey))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	return target, err
}

func (Store) ListPendingBulkTx(ctx context.Context, query tx.Queryer, limit int) ([]operatorgrant.BulkTarget, error) {
	if query == nil || limit < 1 {
		return nil, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(row),'[]'::jsonb)::text FROM (
SELECT jsonb_build_object('semantic_key',semantic_key,'module_command',module_command,'selector',selector,'player_ids',player_ids,'player_count',player_count,'player_ids_sha256',player_ids_sha256,'payload',payload,'principal',principal,'reason',reason,'processed',processed,'applied',applied,'refused',refused,'state',state,'failed_reason',failed_reason,'last_error',last_error,'created_at',created_at,'updated_at',updated_at,'finished_at',finished_at) AS row
FROM operator_bulk_targets WHERE state='PENDING' ORDER BY created_at, semantic_key LIMIT $1) pending`, limit).Scan(&raw); err != nil {
		return nil, err
	}
	var wire []struct {
		SemanticKey     string          `json:"semantic_key"`
		ModuleCommand   string          `json:"module_command"`
		Selector        string          `json:"selector"`
		PlayerIDs       []int64         `json:"player_ids"`
		PlayerCount     int             `json:"player_count"`
		PlayerIDsSHA256 string          `json:"player_ids_sha256"`
		Payload         json.RawMessage `json:"payload"`
		Principal       string          `json:"principal"`
		Reason          string          `json:"reason"`
		Processed       int             `json:"processed"`
		Applied         int             `json:"applied"`
		Refused         int             `json:"refused"`
		State           string          `json:"state"`
		FailedReason    *string         `json:"failed_reason"`
		LastError       string          `json:"last_error"`
		CreatedAt       time.Time       `json:"created_at"`
		UpdatedAt       time.Time       `json:"updated_at"`
		FinishedAt      *time.Time      `json:"finished_at"`
	}
	if err := json.Unmarshal([]byte(raw), &wire); err != nil {
		return nil, err
	}
	out := make([]operatorgrant.BulkTarget, 0, len(wire))
	for _, row := range wire {
		failedReason := ""
		if row.FailedReason != nil {
			failedReason = *row.FailedReason
		}
		out = append(out, operatorgrant.BulkTarget{SemanticKey: row.SemanticKey, ModuleCommand: row.ModuleCommand, Selector: row.Selector, PlayerIDs: row.PlayerIDs, PlayerCount: row.PlayerCount, PlayerIDsSHA256: row.PlayerIDsSHA256, Payload: row.Payload, Principal: row.Principal, Reason: row.Reason, Processed: row.Processed, Applied: row.Applied, Refused: row.Refused, State: row.State, FailedReason: failedReason, LastError: row.LastError, CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt, FinishedAt: row.FinishedAt})
	}
	return out, nil
}

// SaveBulkProgressTx keeps the counters monotone: a concurrent or resumed run
// can never move them backwards, and DONE and FAILED are terminal.
func (Store) SaveBulkProgressTx(ctx context.Context, transaction tx.Tx, semanticKey string, processed, applied, refused int, state, failedReason, lastError string, at time.Time) error {
	if transaction == nil || semanticKey == "" || processed < 0 || applied < 0 || refused < 0 || at.IsZero() || !operatorgrant.ValidBulkState(state) || (state == operatorgrant.StateFailed) != (failedReason != "") {
		return errInvalid
	}
	_, err := transaction.Exec(ctx, `UPDATE operator_bulk_targets
SET processed=GREATEST(processed,$2::integer), applied=GREATEST(applied,$3::integer), refused=GREATEST(refused,$4::integer), state=$5::text, failed_reason=NULLIF($7::text,''), last_error=$8::text, updated_at=$6::timestamptz,
    finished_at=CASE WHEN $5::text IN ('DONE','FAILED') THEN $6::timestamptz ELSE NULL END
WHERE semantic_key=$1 AND state NOT IN ('DONE','FAILED')`, semanticKey, processed, applied, refused, state, at.UTC(), failedReason, lastError)
	return err
}

var _ operatorgrant.BulkStore = Store{}
