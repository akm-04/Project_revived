package librarylocal

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// recordDialogueLogsTx writes the type-7 milestones reached by the hero's
// awarded dialog count. Inserts are once-only, so a replay is harmless.
func (s Service) recordDialogueLogsTx(ctx context.Context, t tx.Tx, player identity.PlayerID, partnerID int64, at time.Time) error {
	rows, e := s.Library.ListDialogsTx(ctx, t, player)
	if e != nil {
		return e
	}
	count := int64(0)
	for _, row := range rows {
		if row.PartnerID == partnerID && row.IsAwarded {
			count++
		}
	}
	for _, logID := range lib.DialogueLogIDsReached(0, count) {
		if _, e = s.Library.InsertHeroLogTx(ctx, t, lib.HeroLogFact{PlayerID: player, PartnerID: partnerID, LogID: logID, OccurredAt: at}); e != nil {
			return e
		}
	}
	return nil
}
