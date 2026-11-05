package arena

import (
	"context"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AdventureDefense is one Arena player's saved defense offered to Adventure
// 10004, already resolved for Combat at the caller's decision instant. Arena
// owns the roster read and hands over typed participants, never raw table ids.
type AdventureDefense struct {
	PlayerID identity.PlayerID
	Heroes   []combat.Participant
	Pets     []combat.Participant
}

// AdventureOpponentTx is the C7 read: Arena standings within the Adventure
// section around the caller's stars. It changes no Arena state.
func (s Service) AdventureOpponentTx(c context.Context, q tx.Queryer, self identity.PlayerID, section int64, ordinal uint64, at time.Time) (AdventureDefense, bool, error) {
	_, catalog, err := s.catalogTx(c, q)
	if err != nil {
		return AdventureDefense{}, false, err
	}
	player, found, err := s.Store.ReadPlayerTx(c, q, self, false)
	if err != nil || !found {
		return AdventureDefense{}, false, err
	}
	standings, err := s.Store.StandingsTx(c, q, player.Season)
	if err != nil {
		return AdventureDefense{}, false, err
	}
	candidates := slices.DeleteFunc(slices.Clone(standings), func(standing d.Standing) bool {
		if standing.PlayerID == self || !standing.Defended {
			return true
		}
		difference := standing.Star - player.Star
		return difference < -section || difference > section
	})
	if len(candidates) == 0 {
		return AdventureDefense{}, false, nil
	}
	picked := candidates[ordinal%uint64(len(candidates))]
	defense, found, err := s.Store.ReadPlayerTx(c, q, picked.PlayerID, false)
	if err != nil || !found || len(defense.Defense.Heroes) == 0 {
		return AdventureDefense{}, false, err
	}
	templates, err := s.templates(c, q)
	if err != nil {
		return AdventureDefense{}, false, err
	}
	rolled := catalog.Rolled(defense, at)
	heroes, err := s.participants(c, q, rolled, defense.PlayerID, cd.OwnedForeign, rolled.Lineup(rolled.Defense.Heroes, templates.Base), templates, at)
	if err != nil {
		return AdventureDefense{}, false, err
	}
	pets, err := s.pet(c, q, defense.PlayerID, cd.OwnedForeign, rolled.Defense.Pet, at, false)
	if err != nil {
		return AdventureDefense{}, false, err
	}
	return AdventureDefense{PlayerID: defense.PlayerID, Heroes: heroes, Pets: pets}, true, nil
}
