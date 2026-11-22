package topfloorstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadTaskPlayerTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID, period domain.TaskModePeriod, lock bool) (domain.TaskModePlayer, bool, error) {
	if !player.Valid() || period.Validate() != nil || int64(player)/domain.RegionStride != int64(period.Ladder.Server) {
		return domain.TaskModePlayer{}, false, domain.ErrInvalid
	}
	statement := `SELECT payload::text,payload_version FROM top_floor_task_players WHERE player_id=$1 AND logical_server_id=$2 AND period_number=$3`
	if lock {
		statement += ` FOR UPDATE`
	}
	if query == nil {
		return domain.TaskModePlayer{}, false, domain.ErrUnavailable
	}
	var raw *string
	var version int16
	err := query.QueryRow(requestContext, statement, int64(player), int64(period.Ladder.Server), period.Rotation.Number).Scan(&raw, &version)
	if errors.Is(err, kernelstore.ErrNoRows) || (err == nil && raw == nil) {
		return domain.TaskModePlayer{}, false, nil
	}
	if err != nil {
		return domain.TaskModePlayer{}, false, err
	}
	var result domain.TaskModePlayer
	if err := payload.Decode("top_floor_task_players", version, []byte(*raw), &result); err != nil {
		return domain.TaskModePlayer{}, false, err
	}
	return result, true, result.Validate(period)
}

func (Store) InsertTaskPlayerTx(requestContext context.Context, transaction tx.Tx, player domain.TaskModePlayer, period domain.TaskModePeriod) error {
	if transaction == nil || player.Validate(period) != nil || player.Player.StateVersion != 1 {
		return domain.ErrConflict
	}
	encoded, version, err := payload.Encode(player)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_players(player_id,logical_server_id,period_number,payload,state_version,payload_version) VALUES($1,$2,$3,$4::jsonb,1,$5)`,
		int64(player.Player.PlayerID), int64(player.Player.Server), player.PeriodNumber, string(encoded), version))
}

func (Store) SaveTaskPlayerTx(requestContext context.Context, transaction tx.Tx, player domain.TaskModePlayer, period domain.TaskModePeriod, previousVersion int64) error {
	if transaction == nil || player.Validate(period) != nil || player.Player.StateVersion != previousVersion+1 {
		return domain.ErrConflict
	}
	encoded, version, err := payload.Encode(player)
	if err != nil {
		return err
	}
	return one(transaction.Exec(requestContext, `UPDATE top_floor_task_players SET payload=$4::jsonb,state_version=$5,payload_version=$7 WHERE player_id=$1 AND period_number=$2 AND state_version=$3 AND logical_server_id=$6`,
		int64(player.Player.PlayerID), player.PeriodNumber, previousVersion, string(encoded), player.Player.StateVersion, int64(player.Player.Server), version))
}
