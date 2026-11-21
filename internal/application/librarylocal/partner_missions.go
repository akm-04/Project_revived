package librarylocal

import (
	"context"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ObservePartnerMissionTx advances one partner mission from the settlement
// transaction of another owner. It takes no library-root lock and writes only
// the mission row, so the caller runs it last, in ascending player id order.
// A missing Hero, a mission the Hero's favor has not unlocked, and a finished
// mission are no-ops; the caller's settlement is never refused by Library
// state. Awards stay with the claim path and notice 20 with SaveMissionTx.
func (s Service) ObservePartnerMissionTx(ctx context.Context, t tx.Tx, player identity.PlayerID, partnerID, missionID int64, at time.Time) error {
	if t == nil || s.Heroes == nil || s.Library == nil || s.Content == nil || !player.Valid() || partnerID <= 0 || at.IsZero() || !slices.Contains(lib.PartnerMissionIDs, missionID) {
		return lib.ErrUnqualified
	}
	revision, active, err := s.Content.LibraryInputsActive(ctx)
	if err != nil {
		return err
	}
	if !active {
		return nil
	}
	catalog, err := s.Content.LibraryCatalogTx(ctx, t, revision)
	if err != nil {
		return err
	}
	hero, found, err := s.Heroes.FindHeroByPartnerIDTx(ctx, t, player, partnerID)
	if err != nil {
		return err
	}
	if !found {
		return nil
	}
	if _, ok := catalog.Templates[hero.TableID]; !ok {
		return nil
	}
	facts, err := s.Library.ReadHeroTx(ctx, t, hero.Ref())
	if err != nil {
		return err
	}
	if !slices.Contains(catalog.UnlockedMissions(facts.Favor), missionID) {
		return nil
	}
	if err = s.ensureMissionSetTx(ctx, t, catalog, player, partnerID, facts.Favor, at); err != nil {
		return err
	}
	rows, err := s.Library.ListMissionsTx(ctx, t, player)
	if err != nil {
		return err
	}
	for _, row := range rows {
		if row.PartnerID != partnerID || row.MissionID != missionID {
			continue
		}
		rule, ok := catalog.Missions[missionID]
		if !ok {
			return nil
		}
		next, advanced, err := row.Advance(rule.Required, at)
		if err != nil {
			return err
		}
		if !advanced {
			return nil
		}
		return s.Library.SaveMissionTx(ctx, t, next)
	}
	return nil
}
