package i5store

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadSpiritFunctionEligibilityTx(c context.Context, q tx.Queryer, p identity.PlayerID) (player.FunctionEligibility, bool, error) {
	e := player.FunctionEligibility{PlayerID: p}
	err := q.QueryRow(c, `SELECT function_id,content_revision,source_fact_key,eligible_at FROM player_function_eligibility WHERE player_id=$1 AND function_id=99`, int64(p)).Scan(&e.FunctionID, &e.ContentRevision, &e.SourceFactKey, &e.EligibleAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return e, false, nil
	}
	return e, err == nil, err
}

// ReadFunctionEligibilityTx reads one durable function eligibility fact.
func (Store) ReadFunctionEligibilityTx(c context.Context, q tx.Queryer, p identity.PlayerID, function int64) (player.FunctionEligibility, bool, error) {
	e := player.FunctionEligibility{PlayerID: p}
	err := q.QueryRow(c, `SELECT function_id,content_revision,source_fact_key,eligible_at FROM player_function_eligibility WHERE player_id=$1 AND function_id=$2`, int64(p), function).Scan(&e.FunctionID, &e.ContentRevision, &e.SourceFactKey, &e.EligibleAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return e, false, nil
	}
	return e, err == nil, err
}

// ReadFunctionUnlockTx reads one durable function unlock fact.
func (Store) ReadFunctionUnlockTx(c context.Context, q tx.Queryer, p identity.PlayerID, function int64) (player.FunctionUnlock, bool, error) {
	unlock := player.FunctionUnlock{PlayerID: p}
	if q == nil || !p.Valid() || function <= 0 {
		return unlock, false, errors.New("invalid function unlock read")
	}
	err := q.QueryRow(c, `SELECT function_id,opened_at,source_fact_key,state_version FROM player_function_unlocks WHERE player_id=$1 AND function_id=$2`, int64(p), function).Scan(&unlock.FunctionID, &unlock.OpenedAt, &unlock.SourceFactKey, &unlock.StateVersion)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return unlock, false, nil
	}
	if err != nil {
		return unlock, false, err
	}
	unlock.OpenedAt = unlock.OpenedAt.UTC()
	if unlock.Validate() != nil {
		return unlock, false, errors.New("invalid function unlock fact")
	}
	return unlock, true, nil
}
