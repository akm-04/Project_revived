package petcampaign

import (
	"context"
	"encoding/json"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func (s Mode) BeginSweep(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "begin-sweep", struct{}{}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		if r.Sweep != nil {
			return r.Normal(), nil
		}
		from, to, e := r.SweepInterval()
		if e != nil {
			return nil, e
		}
		if r.Sequence >= 9007199254740991 {
			return nil, d.ErrUnavailable
		}
		r.Sequence++
		at := sc.Operation.DecisionAt().Unix()
		job := &d.Sweep{ID: fmt.Sprintf("%d:sweep:%d", a.PlayerID, r.Sequence), Revision: v.revision, From: from, To: to, Start: at, Due: at + (to-from+1)*v.catalog.LayerSeconds, Lines: []grant.Line{}, Awards: []map[string]any{}}
		floors := []d.Floor{}
		for n := from; n <= to; n++ {
			f, ok := v.catalog.Floor(1, n)
			if !ok {
				return nil, d.ErrUnavailable
			}
			lines, rows := award(f, false, v.vip)
			job.Lines = append(job.Lines, lines...)
			job.Awards = append(job.Awards, rows...)
			floors = append(floors, f)
		}
		job.Material, e = s.freezeMaterial(c, sc, a, floors)
		if e != nil {
			return nil, e
		}
		r.Sweep = job
		r.SweepLeft--
		r.Fight = nil
		r.LastSweep = nil
		return r.Normal(), nil
	})
}
func (s Mode) FinishSweep(c context.Context, a identity.ActorContext, finish int64, op operation.Context) (map[string]any, error) {
	if finish < 0 {
		return nil, d.ErrInvalid
	}
	return s.run(c, a, "finish-sweep", finish, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		job := r.Sweep
		if job == nil {
			if r.LastSweep != nil {
				return r.LastSweep, nil
			}
			return nil, d.ErrRefused
		}
		frozen, e := s.Content.PetCampaignCatalogTx(c, sc.Tx, job.Revision)
		if e != nil {
			return nil, e
		}
		price := job.Cost(frozen, sc.Operation.DecisionAt().Unix())
		// Objective preparation must precede the crystal material lock.
		c, e = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if e != nil {
			return nil, e
		}
		if e = s.debit(c, sc, a, "crystal", price, false); e != nil {
			return nil, e
		}
		rows, e := s.settle(c, sc, a, job.Revision, job.ID, job.Lines, job.Awards, job.Material, true)
		if e != nil {
			return nil, e
		}
		r.Current = job.To
		r.Sweep = nil
		out := r.Normal()
		out["awards"] = rows
		r.LastSweep = out
		return out, nil
	})
}
func (s Mode) Reset(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "reset", struct{}{}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		if r.Current == 0 && r.Sweep == nil {
			return r.Normal(), nil
		}
		if e := r.Reset(); e != nil {
			return nil, e
		}
		r.LastResult = nil
		r.LastSweep = nil
		return r.Normal(), nil
	})
}
func (s Mode) EliteSweep(c context.Context, a identity.ActorContext, campaign int64, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "elite-sweep", campaign, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		f, ok := v.catalog.ByID(campaign)
		if !ok || f.Type != 2 || r.Max < 100 || f.Number > r.EliteMax || r.EliteUsed[f.Number] >= v.catalog.Raids*(1+r.EliteBuys[f.Number]) {
			return nil, d.ErrRefused
		}
		c, e := s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if e != nil {
			return nil, e
		}
		if e = s.debit(c, sc, a, fmt.Sprint(v.catalog.Ticket), 1, true); e != nil {
			return nil, e
		}
		if r.Sequence >= 9007199254740991 {
			return nil, d.ErrUnavailable
		}
		r.Sequence++
		lines, rows := award(f, false, v.vip)
		rows, e = s.settle(c, sc, a, v.revision, fmt.Sprintf("%d:elite-sweep:%d", a.PlayerID, r.Sequence), lines, rows, nil, true)
		if e != nil {
			return nil, e
		}
		r.EliteUsed[f.Number]++
		return map[string]any{"sweep_info": r.Elite(v.catalog)["sweep_info"], "awards": rows}, nil
	})
}
func (s Mode) BuyElite(c context.Context, a identity.ActorContext, floor int64, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "buy-elite", floor, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		n := r.EliteBuys[floor]
		if r.Max < 100 || floor < 1 || floor > r.EliteMax || n < 0 || n >= int64(len(v.catalog.BuyPrices)) || r.EliteUsed[floor] < v.catalog.Raids*(1+n) {
			return nil, d.ErrRefused
		}
		c, e := s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if e != nil {
			return nil, e
		}
		if e = s.debit(c, sc, a, "crystal", v.catalog.BuyPrices[n], false); e != nil {
			return nil, e
		}
		r.EliteBuys[floor]++
		body := r.Elite(v.catalog)
		return map[string]any{"buy_info": body["buy_info"], "sweep_info": body["sweep_info"]}, nil
	})
}
func (s Mode) SaveElite(c context.Context, a identity.ActorContext, floor, state int64, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "save-elite", [2]int64{floor, state}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		if r.Max < 100 || floor < 0 || floor > 19 || floor > r.EliteMax || state < 1 || state > 2 {
			return nil, d.ErrRefused
		}
		r.Selected = floor
		r.View = state
		return map[string]any{}, nil
	})
}
func (s Mode) AwakeSweep(c context.Context, a identity.ActorContext, floor int64, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "awake-sweep", floor, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		f, ok := v.catalog.Floor(1, floor)
		if !ok || r.Sweep != nil || r.SweepLeft > 0 || r.Max+1 < floor || r.AwakeUsed < 0 || r.AwakeUsed >= int64(len(v.catalog.AwakePrices)) {
			return nil, d.ErrRefused
		}
		raw, e := s.freezeMaterial(c, sc, a, []d.Floor{f})
		if e != nil {
			return nil, e
		}
		if len(raw) == 0 {
			return nil, d.ErrRefused
		}
		var drop objective.AwakeFrozenDrop
		if e = json.Unmarshal(raw, &drop); e != nil {
			return nil, e
		}
		c, e = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if e != nil {
			return nil, e
		}
		if e = s.debit(c, sc, a, "crystal", v.catalog.AwakePrices[r.AwakeUsed], false); e != nil {
			return nil, e
		}
		if r.Sequence >= 9007199254740991 {
			return nil, d.ErrUnavailable
		}
		r.Sequence++
		rows, e := s.settle(c, sc, a, v.revision, fmt.Sprintf("%d:awake-sweep:%d", a.PlayerID, r.Sequence), nil, nil, raw, false)
		if e != nil {
			return nil, e
		}
		r.AwakeUsed++
		return map[string]any{"info": map[string]any{"normal": r.Normal()}, "awards": rows}, nil
	})
}
