package i5store

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadScalarDailyFloorTx(ctx context.Context, query tx.Queryer, player identity.PlayerID, key string) (economy.ScalarDailyFloor, bool, error) {
	var anchor economy.ScalarDailyFloor
	err := query.QueryRow(ctx, `SELECT player_id,resource_key,game_day,state_version,updated_at FROM player_scalar_daily_floors WHERE player_id=$1 AND resource_key=$2`, int64(player), key).Scan((*int64)(&anchor.PlayerID), &anchor.ResourceKey, &anchor.GameDay, &anchor.StateVersion, &anchor.UpdatedAt)
	if noRows(err) {
		return economy.ScalarDailyFloor{}, false, nil
	}
	if err != nil {
		return economy.ScalarDailyFloor{}, false, err
	}
	if err = anchor.Validate(); err != nil {
		return economy.ScalarDailyFloor{}, false, err
	}
	return anchor, true, nil
}
func (Store) SaveScalarDailyFloorTx(ctx context.Context, transaction tx.Tx, anchor economy.ScalarDailyFloor, previousVersion int64) error {
	if err := anchor.Validate(); err != nil {
		return err
	}
	if previousVersion < 0 || anchor.StateVersion != previousVersion+1 {
		return economy.ErrInvalidDailyFloor
	}
	statement := `INSERT INTO player_scalar_daily_floors(player_id,resource_key,game_day,state_version,updated_at)VALUES($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING`
	arguments := []any{int64(anchor.PlayerID), anchor.ResourceKey, anchor.GameDay, anchor.StateVersion, anchor.UpdatedAt}
	if previousVersion > 0 {
		statement = `UPDATE player_scalar_daily_floors SET game_day=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND resource_key=$2 AND state_version=$6`
		arguments = append(arguments, previousVersion)
	}
	result, err := transaction.Exec(ctx, statement, arguments...)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return errors.New("I5 scalar daily floor version conflict")
	}
	return nil
}
