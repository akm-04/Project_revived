package librarylocal

import (
	"context"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ObserveBattleTx records one battle that reached a first server-settled
// result for every distinct partner id that the caller passes and the player
// owns. The caller guarantees a first settlement (receipt replays and reads
// never call it) and passes only the player's own fighting heroes.
//
// Lock order: this runs after the producing mode's ranks, the I5 suffix and
// the Achievement observation (Rank620, achievement/service.go:110), so the
// counter row lock is the last planned lock of the settlement transaction,
// taken in ascending partner id order. The crossed milestone rows are then
// written through RecordHeroLogTx, which also emits the Girls Log wakeup.
func (s Service) ObserveBattleTx(ctx context.Context, t tx.Tx, player identity.PlayerID, partnerIDs []int64, at time.Time) error {
	if t == nil || s.Heroes == nil || s.Library == nil || !player.Valid() || at.IsZero() {
		return lib.ErrUnqualified
	}
	distinct := make(map[int64]bool, len(partnerIDs))
	for _, partnerID := range partnerIDs {
		distinct[partnerID] = true
	}
	heroes, e := s.Heroes.ListHeroesTx(ctx, t, player)
	if e != nil {
		return e
	}
	owned := make(map[int64]bool, len(heroes))
	for _, hero := range heroes {
		owned[hero.PartnerID] = true
	}
	partners := make([]int64, 0, len(distinct))
	for partnerID := range distinct {
		if owned[partnerID] {
			partners = append(partners, partnerID)
		}
	}
	sort.Slice(partners, func(i, j int) bool { return partners[i] < partners[j] })
	for _, partnerID := range partners {
		previous, e := s.Library.BumpHeroBattleCountTx(ctx, t, player, partnerID)
		if e != nil {
			return e
		}
		for _, logID := range lib.BattleLogIDsCrossed(previous, previous+1) {
			if e = s.RecordHeroLogTx(ctx, t, lib.HeroLogFact{PlayerID: player, PartnerID: partnerID, LogID: logID, OccurredAt: at}); e != nil {
				return e
			}
		}
	}
	return nil
}
