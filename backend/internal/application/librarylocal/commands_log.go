package librarylocal

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// recordDialogueCompletionTx counts one completed talk of the hero and writes
// the type-7 milestones it crosses. The durable counter, not the distinct
// awarded dialog rows, is the completion count, so a repeat talk counts too.
// An invalid milestone row is dropped per D1 by RecordHeroLogTx.
func (s Service) recordDialogueCompletionTx(ctx context.Context, t tx.Tx, player identity.PlayerID, partnerID int64, at time.Time) error {
	previous, e := s.Library.BumpHeroDialogueCountTx(ctx, t, player, partnerID)
	if e != nil {
		return e
	}
	for _, logID := range lib.DialogueLogIDsReached(previous, previous+1) {
		if e = s.RecordHeroLogTx(ctx, t, lib.HeroLogFact{PlayerID: player, PartnerID: partnerID, LogID: logID, OccurredAt: at}); e != nil {
			return e
		}
	}
	return nil
}
