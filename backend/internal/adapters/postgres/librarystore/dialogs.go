package librarystore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadDialogTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID, dialogID int64) (library.DialogFact, bool, error) {
	var f library.DialogFact
	if q == nil || !pid.Valid() || partnerID <= 0 || dialogID <= 0 {
		return f, false, library.ErrInvalidFacts
	}
	var player int64
	var isRead, isAwarded bool
	e := q.QueryRow(ctx, `SELECT player_id,partner_id,dialog_id,is_read,is_awarded,select_id,updated_at FROM player_library_dialogs WHERE player_id=$1 AND partner_id=$2 AND dialog_id=$3`, int64(pid), partnerID, dialogID).Scan(&player, &f.PartnerID, &f.DialogID, &isRead, &isAwarded, &f.SelectID, &f.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return library.DialogFact{}, false, nil
	}
	if e != nil {
		return library.DialogFact{}, false, e
	}
	f.PlayerID = identity.PlayerID(player)
	f.IsRead, f.IsAwarded = isRead, isAwarded
	f.UpdatedAt = f.UpdatedAt.UTC()
	if e = f.Validate(); e != nil {
		return library.DialogFact{}, false, e
	}
	return f, true, nil
}
