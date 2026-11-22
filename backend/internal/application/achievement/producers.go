package achievement

import (
	"context"
	"time"

	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ObserveFantasyTx is the I9-11E C2/C3 settlement attachment: one player's
// settled board position and best hurt for one Fantasy campaign. Facts are
// inserted once per campaign (ON CONFLICT DO NOTHING) and progress is their
// bounded row count; a settlement retry changes nothing.
func (s Service) ObserveFantasyTx(c context.Context, t tx.Tx, revision string, player identity.PlayerID, campaignID, occurrenceDay, rank, hurt int64, at time.Time) error {
	if t == nil || s.Store == nil || s.Content == nil || !player.Valid() || campaignID < 1 || occurrenceDay < 1 || rank < 1 || hurt < 0 || at.Unix() <= 0 {
		return d.ErrUnavailable
	}
	facts := []struct {
		id        int64
		qualified bool
	}{
		{id: d.FantasyTopRankID, qualified: rank <= d.FantasyTopRank},
		{id: d.FantasyDamageID, qualified: hurt >= d.FantasyDamageThreshold},
	}
	qualified := false
	for _, fact := range facts {
		qualified = qualified || fact.qualified
	}
	if !qualified {
		return nil
	}
	catalog, e := s.Content.AchievementCatalogTx(c, t, revision)
	if e != nil {
		return e
	}
	if e = s.ensureRootTx(c, t, player, revision, at); e != nil {
		return e
	}
	for _, fact := range facts {
		if !fact.qualified {
			continue
		}
		if _, e := s.Store.PutBossFactTx(c, t, player, fact.id, campaignID, occurrenceDay, at); e != nil {
			return e
		}
		count, e := s.Store.CountBossFactsTx(c, t, player, fact.id)
		if e != nil {
			return e
		}
		if e = s.observePlayerTx(c, t, fact.id, player, revision, at, func(current d.Streak) (d.Streak, bool, error) {
			return current.ObserveCount(catalog, count, at)
		}); e != nil {
			return e
		}
	}
	return nil
}

// ObserveMediumTenPullTx is the I9-11E C6 producer: the high-water best single
// medium "buy 10" girl count. A lower later pull never lowers progress.
func (s Service) ObserveMediumTenPullTx(c context.Context, t tx.Tx, player identity.PlayerID, revision string, girls int64, at time.Time) error {
	if t == nil || s.Store == nil || s.Content == nil || !player.Valid() || girls < 0 || girls > 10 || at.Unix() <= 0 {
		return d.ErrUnavailable
	}
	catalog, e := s.Content.AchievementCatalogTx(c, t, revision)
	if e != nil {
		return e
	}
	if e = s.ensureRootTx(c, t, player, revision, at); e != nil {
		return e
	}
	return s.observePlayerTx(c, t, d.MediumTenPullID, player, revision, at, func(current d.Streak) (d.Streak, bool, error) {
		return current.ObserveHighWater(catalog, girls, at)
	})
}

// ObserveShopPurchaseTx is the 11C C15 port: one accepted shop purchase
// request increments today's 100011 counter inside the shop's settling
// transaction. Reads, refusals and receipt replays never reach it.
func (s Service) ObserveShopPurchaseTx(c context.Context, t tx.Tx, player identity.PlayerID, revision string, at time.Time) error {
	if t == nil || s.Store == nil || s.Content == nil || !player.Valid() || !d.RevisionValid(revision) || at.Unix() <= 0 {
		return d.ErrUnavailable
	}
	catalog, e := s.Content.AchievementCatalogTx(c, t, revision)
	if e != nil {
		return e
	}
	if e = s.ensureRootTx(c, t, player, revision, at); e != nil {
		return e
	}
	count, e := s.Store.IncrementDailyCountTx(c, t, player, d.GreatCustomerID, modes.Day(at))
	if e != nil {
		return e
	}
	return s.observePlayerTx(c, t, d.GreatCustomerID, player, revision, at, func(current d.Streak) (d.Streak, bool, error) {
		return current.ObserveDailyCount(catalog, count, at)
	})
}

// ensureRootTx gives a legacy character its achievement root at the first fact,
// as the owned-state observation does (C4F_LEGACY_STATE_BACKFILL_V1); without it
// observePlayerTx would drop the fact for a player who never loaded 1302.
func (s Service) ensureRootTx(c context.Context, t tx.Tx, player identity.PlayerID, revision string, at time.Time) error {
	_, tracked, err := s.Store.ReadRootTx(c, t, player, true)
	if err != nil || tracked {
		return err
	}
	return s.Store.InitFreshTx(c, t, player, revision, at)
}
