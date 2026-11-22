// Package operatorstore owns operator_commands (migration 00184), the operator
// command idempotency ledger and audit log.
package operatorstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var errInvalid = errors.New("operator store: invalid input")

type Store struct{}

const selectRecord = "SELECT semantic_key,module_command,payload_sha256,principal,role,scope,reason,state,COALESCE(result_json::text,''),created_at,finished_at FROM operator_commands WHERE semantic_key=$1"

func scanRecord(row tx.Row) (*operator.Record, error) {
	var record operator.Record
	var result string
	if err := row.Scan(&record.SemanticKey, &record.ModuleCommand, &record.PayloadSHA256, &record.Principal, &record.Role, &record.Scope, &record.Reason, &record.State, &result, &record.CreatedAt, &record.FinishedAt); err != nil {
		return nil, err
	}
	if result != "" {
		record.Result = json.RawMessage(result)
	}
	return &record, nil
}

func (Store) ClaimTx(ctx context.Context, transaction tx.Tx, command operator.Command, at time.Time) (*operator.Record, error) {
	if transaction == nil || command.Envelope.SemanticKey == "" || at.IsZero() {
		return nil, errInvalid
	}
	envelope := command.Envelope
	effect, err := transaction.Exec(ctx, "INSERT INTO operator_commands(semantic_key,module_command,payload_sha256,principal,role,scope,reason,state,created_at) VALUES($1,$2,$3,$4,$5,$6,$7,'ACCEPTED',$8) ON CONFLICT(semantic_key) DO NOTHING",
		envelope.SemanticKey, command.ModuleCommand, command.PayloadSHA256, envelope.Principal, envelope.Role, envelope.Scope, envelope.Reason, at.UTC())
	if err != nil {
		return nil, err
	}
	if effect != nil && effect.RowsAffected() == 1 {
		return nil, nil
	}
	return scanRecord(transaction.QueryRow(ctx, selectRecord+" FOR UPDATE", envelope.SemanticKey))
}

func (Store) RetryFailedTx(ctx context.Context, transaction tx.Tx, semanticKey string) error {
	if transaction == nil || semanticKey == "" {
		return errInvalid
	}
	effect, err := transaction.Exec(ctx, "UPDATE operator_commands SET state='ACCEPTED',result_json=NULL,finished_at=NULL WHERE semantic_key=$1 AND state='FAILED'", semanticKey)
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("operator store: no FAILED row to retry")
	}
	return nil
}

func (Store) FinishTx(ctx context.Context, transaction tx.Tx, semanticKey, state string, result json.RawMessage, at time.Time) error {
	finished := state == operator.StateApplied || state == operator.StateRefused || state == operator.StateFailed
	if transaction == nil || semanticKey == "" || !finished || at.IsZero() || !json.Valid(result) {
		return errInvalid
	}
	effect, err := transaction.Exec(ctx, "UPDATE operator_commands SET state=$2,result_json=$3::jsonb,finished_at=$4 WHERE semantic_key=$1 AND state='ACCEPTED'", semanticKey, state, string(result), at.UTC())
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("operator store: command row is not ACCEPTED")
	}
	return nil
}

func (Store) ReadTx(ctx context.Context, query tx.Queryer, semanticKey string) (*operator.Record, error) {
	if query == nil || semanticKey == "" {
		return nil, errInvalid
	}
	record, err := scanRecord(query.QueryRow(ctx, selectRecord, semanticKey))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	return record, err
}
