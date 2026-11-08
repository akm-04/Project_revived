package topfloor

import (
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

// SelectPresetDefense returns the owned D511 heroes in preset order, choosing the highest-level copy and then the lowest partner id.
func SelectPresetDefense(heroes []character.Hero, owner identity.PlayerID) ([]character.Hero, error) {
	for _, hero := range heroes {
		if hero.PlayerID != owner || hero.ValidatePersistent() != nil {
			return nil, ErrConflict
		}
	}

	selected := make([]character.Hero, 0, len(PresetDefenseGirls))
	for _, presetTableID := range PresetDefenseGirls {
		var best character.Hero
		for _, hero := range heroes {
			if hero.OriginTableID != presetTableID {
				continue
			}
			if hero.Level > best.Level || (hero.Level == best.Level && (best.PartnerID == 0 || hero.PartnerID < best.PartnerID)) {
				best = hero
			}
		}
		if best.PartnerID > 0 {
			selected = append(selected, best)
		}
	}
	return selected, nil
}
