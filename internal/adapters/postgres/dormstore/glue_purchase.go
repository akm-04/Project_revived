package dormstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadGluePurchasesTx(ctx context.Context, query tx.Queryer, player identity.PlayerID) (dorm.GluePurchases, bool, error) {
	var purchases dorm.GluePurchases
	err := query.QueryRow(ctx, `SELECT player_id,game_day,purchase_count,state_version,updated_at FROM player_dorm_glue_purchases WHERE player_id=$1`, int64(player)).Scan((*int64)(&purchases.Player), &purchases.GameDay, &purchases.Count, &purchases.StateVersion, &purchases.UpdatedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return dorm.GluePurchases{}, false, nil
	}
	if err != nil {
		return dorm.GluePurchases{}, false, err
	}
	return purchases, true, purchases.Validate()
}

// Writes share the existing Dorm root lock; the optional counter adds no rank.
func (Store) SaveGluePurchasesTx(ctx context.Context, transaction tx.Tx, purchases dorm.GluePurchases, previousVersion int64) error {
	if purchases.Validate() != nil || previousVersion < 0 || purchases.StateVersion != previousVersion+1 {
		return dorm.ErrInvalidFacts
	}
	statement := `INSERT INTO player_dorm_glue_purchases(player_id,game_day,purchase_count,state_version,updated_at) VALUES($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING`
	arguments := []any{int64(purchases.Player), purchases.GameDay, purchases.Count, purchases.StateVersion, purchases.UpdatedAt}
	if previousVersion > 0 {
		statement = `UPDATE player_dorm_glue_purchases SET game_day=$2,purchase_count=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND state_version=$6`
		arguments = append(arguments, previousVersion)
	}
	result, err := transaction.Exec(ctx, statement, arguments...)
	if err != nil {
		return err
	}
	return one(result, "glue purchase counter")
}
