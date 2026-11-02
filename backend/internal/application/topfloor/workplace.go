package topfloor

import (
	"context"
	"encoding/json"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// WorkplaceOpponentTx copies one existing source robot; no ladder/player state changes.
func (s Service) WorkplaceOpponentTx(c context.Context, q tx.Queryer, level int64) ([]appcombat.Participant, error) {
	_, cat, err := s.catalogTx(c, q)
	if err != nil {
		return nil, err
	}
	best := -1
	distance := int64(1 << 62)
	for i, t := range cat.Robots {
		d := t.Level - level
		if d < 0 {
			d = -d
		}
		if d < distance {
			best, distance = i, d
		}
	}
	if best < 0 {
		return nil, cd.ErrProviderUnavailable
	}
	out := []appcombat.Participant{}
	for i, id := range cat.Robots[best].Heroes {
		params, ok := cat.RobotHeroParams(id)
		if !ok {
			return nil, cd.ErrProviderUnavailable
		}
		raw, err := json.Marshal(params)
		if err != nil {
			return nil, err
		}
		copy := map[string]any{}
		if err = json.Unmarshal(raw, &copy); err != nil {
			return nil, err
		}
		local := int64(i + 1)
		copy["player_id"], copy["partner_id"] = int64(0), local
		// Robot populate params are table-shaped; retain canonical template and local actor identity.
		if copy["table_id"] == nil {
			return nil, cd.ErrProviderUnavailable
		}
		out = append(out, appcombat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: local, TemplateParams: copy})
	}
	return out, nil
}
