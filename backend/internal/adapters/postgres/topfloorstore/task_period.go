package topfloorstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadTaskPeriodTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID, number int64, lock bool) (domain.TaskModePeriod, bool, error) {
	if query == nil || !server.Valid() || number < 1 {
		return domain.TaskModePeriod{}, false, domain.ErrInvalid
	}
	statement := `SELECT content_revision,mode,submode,starts_at,ends_at,size,settled_day,state_version,created_at,updated_at FROM top_floor_task_periods WHERE logical_server_id=$1 AND period_number=$2`
	if lock {
		statement += ` FOR UPDATE`
	}
	period := domain.TaskModePeriod{}
	period.Ladder.Server, period.Rotation.Number = server, number
	err := query.QueryRow(requestContext, statement, int64(server), number).Scan(&period.Ladder.ContentRevision, &period.Rotation.Mode, &period.Rotation.Submode,
		&period.Rotation.StartsAt, &period.Rotation.EndsAt, &period.Ladder.Size, &period.Ladder.SettledDay, &period.Ladder.StateVersion, &period.Ladder.CreatedAt, &period.Ladder.UpdatedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return domain.TaskModePeriod{}, false, nil
	}
	if err != nil {
		return domain.TaskModePeriod{}, false, err
	}
	return period, true, period.Validate()
}

func (Store) CreateTaskPeriodTx(requestContext context.Context, transaction tx.Tx, period domain.TaskModePeriod) error {
	if transaction == nil || period.Validate() != nil || period.Ladder.Size != domain.RobotTeams || period.Ladder.StateVersion != 1 {
		return domain.ErrConflict
	}
	ladder, rotation := period.Ladder, period.Rotation
	err := one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_periods(logical_server_id,period_number,content_revision,mode,submode,starts_at,ends_at,size,settled_day,state_version,created_at,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,1,$10,$10)`,
		int64(ladder.Server), rotation.Number, ladder.ContentRevision, rotation.Mode, rotation.Submode, rotation.StartsAt, rotation.EndsAt, ladder.Size, ladder.SettledDay, ladder.CreatedAt))
	if err != nil {
		return err
	}
	result, err := transaction.Exec(requestContext, `INSERT INTO top_floor_task_ranks(logical_server_id,period_number,rank,robot_team) SELECT $1,$2,rank,$3+1-rank FROM generate_series(1,$3::bigint) rank`, int64(ladder.Server), rotation.Number, int64(domain.RobotTeams))
	if err != nil {
		return err
	}
	if result.RowsAffected() != domain.RobotTeams {
		return domain.ErrConflict
	}
	return nil
}

func (Store) SaveTaskPeriodTx(requestContext context.Context, transaction tx.Tx, period domain.TaskModePeriod, previousVersion int64) error {
	if transaction == nil || period.Validate() != nil || period.Ladder.StateVersion != previousVersion+1 {
		return domain.ErrConflict
	}
	ladder, rotation := period.Ladder, period.Rotation
	return one(transaction.Exec(requestContext, `UPDATE top_floor_task_periods SET size=$4,settled_day=$5,state_version=$6,updated_at=$7 WHERE logical_server_id=$1 AND period_number=$2 AND state_version=$3 AND content_revision=$8 AND mode=$9 AND submode=$10 AND starts_at=$11 AND ends_at=$12 AND created_at=$13`,
		int64(ladder.Server), rotation.Number, previousVersion, ladder.Size, ladder.SettledDay, ladder.StateVersion, ladder.UpdatedAt,
		ladder.ContentRevision, rotation.Mode, rotation.Submode, rotation.StartsAt, rotation.EndsAt, ladder.CreatedAt))
}

func (Store) TaskRangeTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID, period, first, last int64) ([]domain.Ranked, error) {
	if !server.Valid() || period < 1 || first < 1 || last < first {
		return nil, domain.ErrInvalid
	}
	var rows []rankedRow
	_, err := readJSON(requestContext, query, `SELECT `+rankedAgg+` FROM top_floor_task_ranks WHERE logical_server_id=$1 AND period_number=$2 AND rank BETWEEN $3 AND $4`, &rows, int64(server), period, first, last)
	if err != nil {
		return nil, err
	}
	return toRanked(rows)
}

func (Store) TaskRankOfTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID, period int64, occupant domain.Occupant) (int64, bool, error) {
	if query == nil || !server.Valid() || period < 1 || !occupant.Valid() {
		return 0, false, domain.ErrInvalid
	}
	var rank int64
	err := query.QueryRow(requestContext, `SELECT rank FROM top_floor_task_ranks WHERE logical_server_id=$1 AND period_number=$2 AND COALESCE(robot_team,0)=$3 AND COALESCE(player_id,0)=$4`, int64(server), period, occupant.Robot, int64(occupant.Player)).Scan(&rank)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0, false, nil
	}
	return rank, err == nil, err
}

func (Store) AppendTaskPlayerTx(requestContext context.Context, transaction tx.Tx, server identity.LogicalServerID, period, rank int64, player identity.PlayerID) error {
	if transaction == nil || !server.Valid() || period < 1 || rank <= domain.RobotTeams || !player.Valid() || int64(player)/domain.RegionStride != int64(server) {
		return domain.ErrInvalid
	}
	return one(transaction.Exec(requestContext, `INSERT INTO top_floor_task_ranks(logical_server_id,period_number,rank,player_id) VALUES($1,$2,$3,$4)`, int64(server), period, rank, int64(player)))
}

func (Store) SwapTaskRanksTx(requestContext context.Context, transaction tx.Tx, server identity.LogicalServerID, period int64, challenger, defender domain.Ranked) error {
	if transaction == nil || !server.Valid() || period < 1 || challenger.Rank < 1 || defender.Rank < 1 || challenger.Rank == defender.Rank || !challenger.Occupant.Valid() || !defender.Occupant.Valid() {
		return domain.ErrInvalid
	}
	for _, move := range [][2]domain.Ranked{{challenger, defender}, {defender, challenger}} {
		from, to := move[0], move[1]
		var robot, player any
		if to.Occupant.IsRobot() {
			robot = to.Occupant.Robot
		} else {
			player = int64(to.Occupant.Player)
		}
		err := one(transaction.Exec(requestContext, `UPDATE top_floor_task_ranks SET robot_team=$4,player_id=$5 WHERE logical_server_id=$1 AND period_number=$2 AND rank=$3 AND COALESCE(robot_team,0)=$6 AND COALESCE(player_id,0)=$7`,
			int64(server), period, from.Rank, robot, player, from.Occupant.Robot, int64(from.Occupant.Player)))
		if err != nil {
			return err
		}
	}
	return nil
}
