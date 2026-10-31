package topfloor

import (
	"context"

	"gxb.local/backend/v2/internal/application/combat"
	cd "gxb.local/backend/v2/internal/domain/combat"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AdventureRobot is a robot team offered to Adventure 10004 when no Arena
// player sits inside the Adventure section.
type AdventureRobot struct {
	Heroes []combat.Participant
}

// AdventureRobotTx freezes one Top Floor robot team as TEMPLATE actors. It
// writes nothing and returns false when the ordinal addresses no team.
func (s Service) AdventureRobotTx(c context.Context, q tx.Queryer, ordinal uint64) (AdventureRobot, bool, error) {
	_, catalog, err := s.catalogTx(c, q)
	if err != nil {
		return AdventureRobot{}, false, err
	}
	teamID := 1 + int64(ordinal%uint64(d.RobotTeams))
	team, ok := catalog.Team(teamID)
	if !ok {
		return AdventureRobot{}, false, nil
	}
	heroes := make([]combat.Participant, 0, len(team.Heroes))
	for _, id := range team.Heroes {
		params, ok := catalog.RobotHeroParams(id)
		if !ok {
			return AdventureRobot{}, false, d.ErrUnavailable
		}
		heroes = append(heroes, combat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: params["partner_id"].(int64), TemplateParams: params})
	}
	return AdventureRobot{Heroes: heroes}, true, nil
}
