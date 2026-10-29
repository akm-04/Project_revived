package topfloorstore

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) ReadTaskFightTx(requestContext context.Context, query tx.Queryer, id ids.UUID, lock bool) (domain.TaskModeFight, bool, error) {
	statement := `SELECT payload::text FROM top_floor_task_fights WHERE attempt_id=$1`
	if lock {
		statement += ` FOR UPDATE`
	}
	var fight domain.TaskModeFight
	found, err := readJSON(requestContext, query, statement, &fight, id.String())
	if err != nil || !found {
		return fight, found, err
	}
	return fight, true, fight.Validate()
}
func (Store) LatestTaskFightTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID) (domain.TaskModeFight, bool, error) {
	var fight domain.TaskModeFight
	found, err := readJSON(requestContext, query, `SELECT payload::text FROM top_floor_task_fights WHERE challenger_id=$1 ORDER BY started_at DESC,attempt_id LIMIT 1`, &fight, int64(player))
	if err != nil || !found {
		return fight, found, err
	}
	return fight, true, fight.Validate()
}
func (Store) OpenTaskFightsTx(requestContext context.Context, query tx.Queryer, before time.Time, limit int) ([]domain.TaskModeFight, error) {
	var fights []domain.TaskModeFight
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(payload),'[]'::jsonb)::text FROM (SELECT payload FROM top_floor_task_fights WHERE status='STARTED' AND started_at<$1 ORDER BY started_at LIMIT $2) pending`, &fights, before, limit)
	return fights, err
}
func (Store) InsertTaskFightTx(requestContext context.Context, transaction tx.Tx, fight domain.TaskModeFight) error {
	if transaction == nil || fight.Validate() != nil || fight.Fight.Status != domain.StatusStarted || fight.Fight.StateVersion != 1 {
		return domain.ErrConflict
	}
	payload, err := json.Marshal(fight)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_fights(attempt_id,challenger_id,logical_server_id,period_number,started_at,status,state_version,payload)VALUES($1,$2,$3,$4,$5,'STARTED',1,$6::jsonb)`, fight.Fight.AttemptID.String(), int64(fight.Fight.Challenger), int64(fight.Fight.Server), fight.PeriodNumber, fight.Fight.StartedAt, string(payload)))
}
func (Store) FinishTaskFightTx(requestContext context.Context, transaction tx.Tx, fight domain.TaskModeFight, previous int64) error {
	if transaction == nil || fight.Validate() != nil || fight.Fight.Status == domain.StatusStarted || fight.Fight.StateVersion != previous+1 {
		return domain.ErrConflict
	}
	payload, err := json.Marshal(fight)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `UPDATE top_floor_task_fights SET status=$3,state_version=$4,payload=$5::jsonb WHERE attempt_id=$1 AND state_version=$2 AND status='STARTED'`, fight.Fight.AttemptID.String(), previous, fight.Fight.Status, fight.Fight.StateVersion, string(payload)))
}
func (Store) TaskPreferenceTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID, mode int64) (domain.TaskModeDefense, bool, error) {
	var defense domain.TaskModeDefense
	found, err := readJSON(requestContext, query, `SELECT payload::text FROM top_floor_task_preferences WHERE player_id=$1 AND mode=$2`, &defense, int64(player), mode)
	return defense, found, err
}
func (Store) SaveTaskPreferenceTx(requestContext context.Context, transaction tx.Tx, player identity.PlayerID, mode int64, defense domain.TaskModeDefense) error {
	payload, err := json.Marshal(defense)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_preferences(player_id,mode,payload) VALUES($1,$2,$3::jsonb)ON CONFLICT(player_id,mode)DO UPDATE SET payload=EXCLUDED.payload`, int64(player), mode, string(payload)))
}
func (Store) InsertTaskRecordTx(requestContext context.Context, transaction tx.Tx, record domain.TaskModeRecord, limit int64) error {
	payload, err := json.Marshal(record)
	if err != nil {
		return err
	}
	if err = one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_records(owner_player_id,attempt_id,payload)VALUES($1,$2,$3::jsonb)`, int64(record.Record.Owner), record.Record.AttemptID.String(), string(payload))); err != nil {
		return err
	}
	_, err = transaction.Exec(requestContext, `DELETE FROM top_floor_task_records WHERE owner_player_id=$1 AND record_id NOT IN (SELECT record_id FROM top_floor_task_records WHERE owner_player_id=$1 ORDER BY record_id DESC LIMIT $2)`, int64(record.Record.Owner), limit)
	return err
}
func (Store) TaskRecordsTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID) ([]domain.TaskModeRecord, error) {
	var records []domain.TaskModeRecord
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(payload||jsonb_build_object('Record',(payload->'Record')||jsonb_build_object('ID',record_id)) ORDER BY record_id DESC),'[]'::jsonb)::text FROM top_floor_task_records WHERE owner_player_id=$1`, &records, int64(player))
	return records, err
}
func (Store) TaskRecordTx(requestContext context.Context, query tx.Queryer, id int64) (domain.TaskModeRecord, bool, error) {
	var record domain.TaskModeRecord
	found, err := readJSON(requestContext, query, `SELECT (payload||jsonb_build_object('Record',(payload->'Record')||jsonb_build_object('ID',record_id)))::text FROM top_floor_task_records WHERE record_id=$1`, &record, id)
	return record, found, err
}
func (Store) TaskPeriodsTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID) ([]int64, error) {
	var periods []int64
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(period_number ORDER BY period_number),'[]'::jsonb)::text FROM top_floor_task_periods WHERE logical_server_id=$1`, &periods, int64(server))
	return periods, err
}
func (Store) InsertTaskDayTx(requestContext context.Context, transaction tx.Tx, day domain.TaskModeDay) error {
	payload, err := json.Marshal(day)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_days(logical_server_id,period_number,day,payload)VALUES($1,$2,$3,$4::jsonb)`, int64(day.Settlement.Server), day.PeriodNumber, day.Settlement.Day, string(payload)))
}

func (Store) TaskDueServersTx(requestContext context.Context, query tx.Queryer, at time.Time) ([]identity.LogicalServerID, error) {
	var servers []identity.LogicalServerID
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(logical_server_id),'[]'::jsonb)::text FROM (SELECT DISTINCT logical_server_id FROM top_floor_task_periods WHERE settled_day < LEAST($1, (((ends_at AT TIME ZONE 'Asia/Shanghai') - make_interval(secs => $2) - interval '1 microsecond')::date - DATE '1970-01-01'))) servers`, &servers, (domain.TaskModeCatalog{}).Calendar().LatestCutoffDay(at), (domain.TaskModeCatalog{}).Calendar().CutoffSeconds)
	return servers, err
}
