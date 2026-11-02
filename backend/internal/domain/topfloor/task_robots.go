package topfloor

import "slices"

func (catalog TaskModeCatalog) RobotFormation(normal Catalog, teamID int64, rotation TaskModeRotation) ([]RobotHero, error) {
	rule, found := catalog.Rule(rotation.Mode)
	if !found {
		return nil, ErrUnavailable
	}
	selectedCamp, validCamp := taskModeSelectedCamp(rotation.Submode)
	if !validCamp || rotation.Mode != TaskModeCamp && rotation.Submode != 0 {
		return nil, ErrInvalid
	}
	team, found := normal.Team(teamID)
	if !found {
		return nil, ErrInvalid
	}
	index := normal.robotHeroIndex()
	heroes := []RobotHero{}
	appendHero := func(hero RobotHero) error {
		camp, found := catalog.HeroCamps[hero.PartnerID]
		if !found {
			return ErrUnavailable
		}
		if slices.Contains(rule.BannedTables, hero.PartnerID) {
			return nil
		}
		if rule.ID == TaskModeCamp {
			if selectedCamp == 0 {
				selectedCamp = camp
			}
			if camp != selectedCamp {
				return nil
			}
		}
		heroes = append(heroes, hero)
		return nil
	}
	for _, identity := range team.Heroes {
		hero, found := index[identity]
		if !found {
			return nil, ErrUnavailable
		}
		if err := appendHero(hero); err != nil {
			return nil, err
		}
		if len(heroes) == rule.HeroSlots {
			return heroes, nil
		}
	}
	if len(heroes) > 0 {
		return heroes, nil
	}
	// D352: an entirely banned source team uses the first eligible source template.
	for _, hero := range normal.RobotHeroes {
		if err := appendHero(hero); err != nil {
			return nil, err
		}
		if len(heroes) > 0 {
			return heroes, nil
		}
	}
	return nil, ErrUnavailable
}
