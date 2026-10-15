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
