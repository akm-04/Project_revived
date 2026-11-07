package dormstore

import (
	"context"
	"errors"
	"math"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	domain "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadSocialRoomTx(ctx context.Context, query tx.Queryer, target domain.RoomTarget) (domain.SocialRoomState, bool, error) {
	if query == nil || target.Validate() != nil {
		return domain.SocialRoomState{}, false, domain.ErrInvalidFacts
	}
	state := domain.SocialRoomState{Target: target}
	err := query.QueryRow(ctx, `SELECT house_name,is_hidden,state_version,updated_at FROM player_dorm_room_social WHERE player_id=$1 AND house_id=$2`, int64(target.Owner), target.HouseID).Scan(&state.Name, &state.Hidden, &state.StateVersion, &state.UpdatedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return domain.SocialRoomState{}, false, nil
	}
	if err != nil {
		return domain.SocialRoomState{}, false, err
	}
	state.UpdatedAt = state.UpdatedAt.UTC()
	if err := state.Validate(); err != nil {
		return domain.SocialRoomState{}, false, err
	}
	return state, true, nil
}

// The caller holds the governed Dorm root and persists its reply in this transaction.
func (Store) SaveSocialRoomTx(ctx context.Context, transaction tx.Tx, state domain.SocialRoomState, previousVersion int64) error {
	if transaction == nil || state.Validate() != nil || previousVersion < 0 || previousVersion == math.MaxInt64 || state.StateVersion != previousVersion+1 {
		return domain.ErrInvalidFacts
	}
	statement := `INSERT INTO player_dorm_room_social(player_id,house_id,house_name,is_hidden,state_version,updated_at) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT DO NOTHING`
	arguments := []any{int64(state.Target.Owner), state.Target.HouseID, state.Name, state.Hidden, state.StateVersion, state.UpdatedAt}
	if previousVersion > 0 {
		statement = `UPDATE player_dorm_room_social SET house_name=$3,is_hidden=$4,state_version=$5,updated_at=$6 WHERE player_id=$1 AND house_id=$2 AND state_version=$7 AND updated_at<=$6`
		arguments = append(arguments, previousVersion)
	}
	result, err := transaction.Exec(ctx, statement, arguments...)
	if err != nil {
		return err
	}
	if result == nil {
		return domain.ErrInvalidFacts
	}
	return one(result, "room social metadata")
}
