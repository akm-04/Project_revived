package godstrial

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Mode) Name() string     { return "GodsTrial" }
func (Mode) Claims() []string { return []string{"3101"} }
func (s Mode) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	r, _, e := s.Store.ReadTx(c, q, a.PlayerID)
	if e != nil {
		return e
	}
	detail["3101"] = r.Base()
	return nil
}
func (s Mode) Info(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "info", struct{}{}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		return r.Info(v.catalog, modes.Day(sc.Operation.DecisionAt()), v.level), nil
	})
}
func (s Mode) Detail(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "detail", struct{}{}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		return r.Base(), nil
	})
}
