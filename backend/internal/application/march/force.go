package march

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"math"
)

func (s Mode) force(c context.Context, sc gen.TimedScope, a identity.ActorContext, ref character.HeroRef, revision string, frozen frozenTeam) (int64, error) {
	owner, err := s.frozenOwner(c, sc, a, ref, revision, frozen)
	if err != nil {
		return 0, err
	}
	level, star, color := owner.Base()
	result, err := owner.Evaluate(level, star, color)
	if err != nil {
		return 0, err
	}
	value := math.Round(result.Stats.Force)
	if math.IsNaN(value) || math.IsInf(value, 0) || value < 0 || value > 100000000000 {
		return 0, d.ErrUnavailable
	}
	return int64(value), nil
}
