package arena

import (
	"context"
	"slices"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AdventureDefense is one Arena player's saved defense offered to Adventure
// 10004. Its heroes are Arena-owned rows read here, never by Adventure.
type AdventureDefense struct {
	PlayerID identity.PlayerID
	Heroes   []int64
	PetID    int64
}

// AdventureOpponentTx is the C7 read: Arena standings within the Adventure
// section around the caller's stars. It changes no Arena state.
func (s Service) AdventureOpponentTx(c context.Context, q tx.Queryer, self identity.PlayerID, section int64, ordinal uint64) (AdventureDefense, bool, error) {
	if _, _, err := s.catalogTx(c, q); err != nil {
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
	return AdventureDefense{PlayerID: picked.PlayerID, Heroes: append([]int64(nil), defense.Defense.Heroes...), PetID: defense.Defense.Pet}, true, nil
}
