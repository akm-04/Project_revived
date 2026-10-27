package workplace

import (
	"context"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
)

func (s Mode) force(c context.Context, sc gen.TimedScope, a identity.ActorContext, ref character.HeroRef, revision string) (int64, error) {
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, sc.Operation.DecisionAt())
	if err != nil {
		return 0, err
	}
	kind := publicstats.Self
	if ref.PlayerID != a.PlayerID {
		kind = publicstats.Foreign
	}
	result, err := s.Stats.HeroTx(c, scope, ref, publicstats.View{Kind: kind, Viewer: a.PlayerID})
	if err != nil {
		return 0, err
	}
	value := math.Round(result.Stats.Force)
	if math.IsNaN(value) || math.IsInf(value, 0) || value < 0 || value > 100000000000 {
		return 0, d.ErrUnavailable
	}
	return int64(value), nil
}
