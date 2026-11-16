package topfloorstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadTaskFightTx(requestContext context.Context, query tx.Queryer, id ids.UUID, lock bool) (domain.TaskModeFight, bool, error) {
	statement := `SELECT payload::text,payload_version FROM top_floor_task_fights WHERE attempt_id=$1`
	if lock {
		statement += ` FOR UPDATE`
	}
	return readTaskFight(requestContext, query, statement, id.String())
}
func (Store) LatestTaskFightTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID) (domain.TaskModeFight, bool, error) {
	return readTaskFight(requestContext, query, `SELECT payload::text,payload_version FROM top_floor_task_fights WHERE challenger_id=$1 ORDER BY started_at DESC,attempt_id LIMIT 1`, int64(player))
}
func (Store) OpenTaskFightsTx(requestContext context.Context, query tx.Queryer, before time.Time, limit int) ([]domain.TaskModeFight, error) {
	if query == nil {
		return nil, domain.ErrUnavailable
	}
	var rows []struct {
		Payload json.RawMessage `json:"payload"`
		Version int16           `json:"version"`
	}
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(jsonb_build_object('payload',payload,'version',payload_version) ORDER BY started_at),'[]'::jsonb)::text FROM (SELECT payload,payload_version,started_at FROM top_floor_task_fights WHERE status='STARTED' AND started_at<$1 ORDER BY started_at LIMIT $2) pending`, &rows, before, limit)
	if err != nil {
		return nil, err
	}
	fights := make([]domain.TaskModeFight, 0, len(rows))
	for _, row := range rows {
		var fight domain.TaskModeFight
		if err := payload.Decode("top_floor_task_fights", row.Version, row.Payload, &fight); err != nil {
			return nil, err
		}
		fights = append(fights, fight)
	}
	return fights, nil
}
func readTaskFight(requestContext context.Context, query tx.Queryer, statement string, args ...any) (domain.TaskModeFight, bool, error) {
	if query == nil {
		return domain.TaskModeFight{}, false, domain.ErrUnavailable
	}
	var raw *string
	var version int16
	err := query.QueryRow(requestContext, statement, args...).Scan(&raw, &version)
	if errors.Is(err, kernelstore.ErrNoRows) || (err == nil && raw == nil) {
		return domain.TaskModeFight{}, false, nil
	}
	if err != nil {
		return domain.TaskModeFight{}, false, err
	}
	var fight domain.TaskModeFight
	if err := payload.Decode("top_floor_task_fights", version, []byte(*raw), &fight); err != nil {
		return domain.TaskModeFight{}, false, err
	}
	return fight, true, fight.Validate()
}
func (Store) InsertTaskFightTx(requestContext context.Context, transaction tx.Tx, fight domain.TaskModeFight) error {
	if transaction == nil || fight.Validate() != nil || fight.Fight.Status != domain.StatusStarted || fight.Fight.StateVersion != 1 {
		return domain.ErrConflict
	}
	encoded, version, err := payload.Encode(fight)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_fights(attempt_id,challenger_id,logical_server_id,period_number,started_at,status,state_version,payload,payload_version)VALUES($1,$2,$3,$4,$5,'STARTED',1,$6::jsonb,$7)`, fight.Fight.AttemptID.String(), int64(fight.Fight.Challenger), int64(fight.Fight.Server), fight.PeriodNumber, fight.Fight.StartedAt, string(encoded), version))
}
func (Store) FinishTaskFightTx(requestContext context.Context, transaction tx.Tx, fight domain.TaskModeFight, previous int64) error {
	if transaction == nil || fight.Validate() != nil || fight.Fight.Status == domain.StatusStarted || fight.Fight.StateVersion != previous+1 {
		return domain.ErrConflict
	}
	encoded, version, err := payload.Encode(fight)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `UPDATE top_floor_task_fights SET status=$3,state_version=$4,payload=$5::jsonb,payload_version=$6 WHERE attempt_id=$1 AND state_version=$2 AND status='STARTED'`, fight.Fight.AttemptID.String(), previous, fight.Fight.Status, fight.Fight.StateVersion, string(encoded), version))
}
func (Store) TaskPreferenceTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID, mode int64) (domain.TaskModeDefense, bool, error) {
	if query == nil {
		return domain.TaskModeDefense{}, false, domain.ErrUnavailable
	}
	var raw *string
	var version int16
	err := query.QueryRow(requestContext, `SELECT payload::text,payload_version FROM top_floor_task_preferences WHERE player_id=$1 AND mode=$2`, int64(player), mode).Scan(&raw, &version)
	if errors.Is(err, kernelstore.ErrNoRows) || (err == nil && raw == nil) {
		return domain.TaskModeDefense{}, false, nil
	}
	if err != nil {
		return domain.TaskModeDefense{}, false, err
	}
	var defense domain.TaskModeDefense
	if err := payload.Decode("top_floor_task_preferences", version, []byte(*raw), &defense); err != nil {
		return domain.TaskModeDefense{}, false, err
	}
	return defense, true, nil
}
func (Store) SaveTaskPreferenceTx(requestContext context.Context, transaction tx.Tx, player identity.PlayerID, mode int64, defense domain.TaskModeDefense) error {
	encoded, version, err := payload.Encode(defense)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_preferences(player_id,mode,payload,payload_version) VALUES($1,$2,$3::jsonb,$4)ON CONFLICT(player_id,mode)DO UPDATE SET payload=EXCLUDED.payload,payload_version=EXCLUDED.payload_version`, int64(player), mode, string(encoded), version))
}
func (Store) InsertTaskRecordTx(requestContext context.Context, transaction tx.Tx, record domain.TaskModeRecord, limit int64) error {
	encoded, version, err := payload.Encode(record)
	if err != nil {
		return err
	}
	if err = one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_records(owner_player_id,attempt_id,payload,payload_version)VALUES($1,$2,$3::jsonb,$4)`, int64(record.Record.Owner), record.Record.AttemptID.String(), string(encoded), version)); err != nil {
		return err
	}
	_, err = transaction.Exec(requestContext, `DELETE FROM top_floor_task_records WHERE owner_player_id=$1 AND record_id NOT IN (SELECT record_id FROM top_floor_task_records WHERE owner_player_id=$1 ORDER BY record_id DESC LIMIT $2)`, int64(record.Record.Owner), limit)
	return err
}
func (Store) TaskRecordsTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID) ([]domain.TaskModeRecord, error) {
	if query == nil {
		return nil, domain.ErrUnavailable
	}
	var rows []struct {
		Payload json.RawMessage `json:"payload"`
		Version int16           `json:"version"`
	}
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(jsonb_build_object('payload',payload||jsonb_build_object('Record',(payload->'Record')||jsonb_build_object('ID',record_id)),'version',payload_version) ORDER BY record_id DESC),'[]'::jsonb)::text FROM top_floor_task_records WHERE owner_player_id=$1`, &rows, int64(player))
	if err != nil {
		return nil, err
	}
	records := make([]domain.TaskModeRecord, 0, len(rows))
	for _, row := range rows {
		var record domain.TaskModeRecord
		if err := payload.Decode("top_floor_task_records", row.Version, row.Payload, &record); err != nil {
			return nil, err
		}
		records = append(records, record)
	}
	return records, nil
}
func (Store) TaskRecordTx(requestContext context.Context, query tx.Queryer, id int64) (domain.TaskModeRecord, bool, error) {
	if query == nil {
		return domain.TaskModeRecord{}, false, domain.ErrUnavailable
	}
	var raw *string
	var version int16
	err := query.QueryRow(requestContext, `SELECT (payload||jsonb_build_object('Record',(payload->'Record')||jsonb_build_object('ID',record_id)))::text,payload_version FROM top_floor_task_records WHERE record_id=$1`, id).Scan(&raw, &version)
	if errors.Is(err, kernelstore.ErrNoRows) || (err == nil && raw == nil) {
		return domain.TaskModeRecord{}, false, nil
	}
	if err != nil {
		return domain.TaskModeRecord{}, false, err
	}
	var record domain.TaskModeRecord
	if err := payload.Decode("top_floor_task_records", version, []byte(*raw), &record); err != nil {
		return domain.TaskModeRecord{}, false, err
	}
	return record, true, nil
}
func (Store) TaskPeriodsTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID) ([]int64, error) {
	var periods []int64
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(period_number ORDER BY period_number),'[]'::jsonb)::text FROM top_floor_task_periods WHERE logical_server_id=$1`, &periods, int64(server))
	return periods, err
}
func (Store) InsertTaskDayTx(requestContext context.Context, transaction tx.Tx, day domain.TaskModeDay) error {
	encoded, err := json.Marshal(day)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_days(logical_server_id,period_number,day,payload)VALUES($1,$2,$3,$4::jsonb)`, int64(day.Settlement.Server), day.PeriodNumber, day.Settlement.Day, string(encoded)))
}

func (Store) TaskDueServersTx(requestContext context.Context, query tx.Queryer, at time.Time) ([]identity.LogicalServerID, error) {
	var servers []identity.LogicalServerID
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(logical_server_id),'[]'::jsonb)::text FROM (SELECT DISTINCT logical_server_id FROM top_floor_task_periods WHERE settled_day < LEAST($1, (((ends_at AT TIME ZONE 'Asia/Shanghai') - make_interval(secs => $2) - interval '1 microsecond')::date - DATE '1970-01-01'))) servers`, &servers, (domain.TaskModeCatalog{}).Calendar().LatestCutoffDay(at), (domain.TaskModeCatalog{}).Calendar().CutoffSeconds)
	return servers, err
}
