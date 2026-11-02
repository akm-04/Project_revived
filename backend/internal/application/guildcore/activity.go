package guildcore

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// forfeitCampaignTx runs before the rental closure's 609b and 610.
func (s Service) forfeitCampaignTx(ctx context.Context, t tx.Tx, id guild.ID, player identity.PlayerID) error {
	if s.Campaign == nil {
		return nil
	}
	return s.Campaign.RemoveMemberTx(ctx, t, id, player)
}

func (s Service) closeCampaignTx(ctx context.Context, t tx.Tx, id guild.ID) error {
	if s.Campaign == nil {
		return nil
	}
	return s.Campaign.CloseGuildTx(ctx, t, id)
}

// closeRentalsTx runs before anything at rank 723.
func (s Service) closeRentalsTx(ctx context.Context, t tx.Tx, lender identity.PlayerID, at time.Time) error {
	if s.Rental == nil {
		return nil
	}
	return s.Rental.CloseLenderOffersTx(ctx, t, lender, at)
}

// settleDepartureActivityTx leaves the departing member's unfolded credit with
// the old guild and halves their lifetime contribution (I9_GUILD_ACTIVITY_V1 C5, C7).
// It takes rank 723, so it runs after anything else the flow locks.
func (s Service) settleDepartureActivityTx(ctx context.Context, t tx.Tx, g guild.Guild, player identity.PlayerID, at time.Time) error {
	credited, err := s.Store.FoldActivityTx(ctx, t, []identity.PlayerID{player})
	if err != nil {
		return err
	}
	if credited > 0 {
		old := g.StateVersion
		g.Vitality = guild.ActivityBalance(g.Vitality, credited)
		g.StateVersion++
		g.UpdatedAt = at
		if err := s.Store.SaveGuildTx(ctx, t, g, old); err != nil {
			return err
		}
	}
	return s.Store.ForfeitActivityLifetimeTx(ctx, t, player)
}
