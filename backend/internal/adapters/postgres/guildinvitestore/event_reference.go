package guildinvitestore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) FindMarkerForEventTx(c context.Context, q tx.Queryer, event int64) (ids.UUID, error) {
	if q == nil || event < 1 {
		return ids.UUID{}, gi.ErrEvidence
	}
	var raw string
	e := q.QueryRow(c, `SELECT marker_id::text FROM guild_invite_projection_markers WHERE event_id=$1`, event).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return ids.UUID{}, nil
	}
	if e != nil {
		return ids.UUID{}, e
	}
	return ids.ParseUUID(raw)
}
