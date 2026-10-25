package campaign

import (
	"context"
	"errors"
	daily "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type DailyConsumption interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID, int64) (map[int64]int64, error)
	BuyTrialTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, int64, int64, operation.Context, time.Time) error
}

func (s Mode) trialBuys(c context.Context, q tx.Queryer, p identity.PlayerID, day int64) (map[int64]int64, error) {
	if s.Daily == nil {
		return nil, d.ErrUnavailable
	}
	buys, err := s.Daily.ReadTx(c, q, p, day)
	if errors.Is(err, daily.ErrRefused) {
		return nil, d.ErrRefused
	}
	return buys, err
}
func (v view) groupOpen(g d.TrialGroup) bool {
	if g.ID >= 40 {
		return v.cloudOpen
	}
	return v.trialOpen
}
func (s Mode) admit(c context.Context, q tx.Queryer, p identity.PlayerID, v view, r d.Record, kind, id, level int64) (d.Node, error) {
	g, trial := v.catalog.Group(kind)
	if !trial {
		return v.catalog.Admit(r.Progress, kind, id, level, v.day, v.superOpen)
	}
	buys, err := s.trialBuys(c, q, p, v.day)
	if err != nil {
		return d.Node{}, err
	}
	return v.catalog.AdmitTrial(r.Progress, kind, id, level, v.day, buys[g.ConsumeID], v.groupOpen(g))
}
func (s Mode) trialProjection(c context.Context, q tx.Queryer, p identity.PlayerID, v view, r d.Record) (map[string]any, error) {
	buys, err := s.trialBuys(c, q, p, v.day)
	if err != nil {
		return nil, err
	}
	trials, challenges, trNodes, chNodes := []any{}, []any{}, []any{}, []any{}
	for _, g := range v.catalog.TrialGroups {
		if g.NextID != 0 && !g.Scheduled(v.catalog, v.day) {
			continue
		}
		row := v.catalog.TrialRow(r.Progress, g, v.day, buys[g.ConsumeID], v.groupOpen(g))
		rows := []any{}
		for _, id := range g.Nodes {
			rows = append(rows, map[string]any{"campaign_id": id, "star": r.Progress.State(id).Star})
		}
		if g.NextID == 0 {
			trials = append(trials, row)
			trNodes = append(trNodes, rows...)
		} else {
			challenges = append(challenges, row)
			chNodes = append(chNodes, rows...)
		}
	}
	return map[string]any{"trial_info": map[string]any{"trials": trials, "campaigns": trNodes}, "challenge_info": map[string]any{"challenges": challenges, "campaigns": chNodes}}, nil
}

// TrialWorld is shared by115 and MID1, avoiding the lobby's empty placeholder.
func (s Mode) TrialWorld(c context.Context, q tx.Queryer, p identity.PlayerID, revision string, at time.Time) (map[string]any, error) {
	v, err := s.read(c, q, p, revision, at)
	if err != nil {
		return nil, err
	}
	r, err := s.Store.ReadTx(c, q, p)
	if err != nil {
		return nil, err
	}
	return s.trialProjection(c, q, p, v, r)
}

// TrialLoad answers115 or the123 prophecy forecast.28 reads the actual purchase owner.
func (s Mode) TrialLoad(c context.Context, a identity.ActorContext, mid uint16, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	revision, _ := op.Policies.Get("content")
	_, _, err = s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		v, e := s.read(c, sc.Tx, a.PlayerID, revision, sc.Operation.DecisionAt())
		if e != nil {
			return e
		}
		if mid == 28 {
			buys, e := s.trialBuys(c, sc.Tx, a.PlayerID, v.day)
			if e != nil {
				return e
			}
			out = map[string]any{"buy_times": daily.Pipe(buys)}
			return nil
		}
		r, e := s.Store.ReadTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if mid == 123 {
			g, ok := v.catalog.Group(v.catalog.Prophecy(v.day))
			if !ok {
				return d.ErrUnavailable
			}
			out = map[string]any{"challenges": []any{v.catalog.TrialRow(r.Progress, g, v.day, 0, v.groupOpen(g))}}
			return nil
		}
		out, e = s.trialProjection(c, sc.Tx, a.PlayerID, v, r)
		return e
	})
	return out, err
}
func (s Mode) BuyTrial(c context.Context, a identity.ActorContext, id int64, op operation.Context) (map[string]any, error) {
	return s.purchase(c, a, "trial-purchase", id, op, func(c context.Context, sc gen.TimedScope, v view, r d.Record, level int64, _ i5.PrivilegeSnapshot) (map[string]any, error) {
		var group d.TrialGroup
		for _, g := range v.catalog.TrialGroups {
			if g.ConsumeID == id && id >= 3 {
				group = g
				break
			}
		}
		if group.ID == 0 {
			return nil, d.ErrRefused
		}
		first, ok := v.catalog.Node(group.Nodes[0])
		if !ok {
			return nil, d.ErrUnavailable
		}
		if !v.groupOpen(group) || !group.Scheduled(v.catalog, v.day) || level < first.OpenLevel {
			return nil, d.ErrRefused
		}
		var rule d.DailyConsume
		for _, v := range v.catalog.DailyConsumes {
			if v.ID == id {
				rule = v
				break
			}
		}
		if s.Daily == nil {
			return nil, d.ErrUnavailable
		}
		err := s.Daily.BuyTrialTx(c, sc.Tx, a.PlayerID, id, v.day, rule.Cost, rule.Limit, rule.Value, sc.Operation.Operation(), sc.Operation.DecisionAt())
		if errors.Is(err, daily.ErrRefused) {
			return nil, d.ErrRefused
		}
		if err != nil {
			return nil, purchaseError(err)
		}
		return map[string]any{}, nil
	})
}

func (s Mode) functionOpen(c context.Context, q tx.Queryer, p identity.PlayerID, id int64, at time.Time) (bool, error) {
	fact, eligible, err := s.Functions.ReadFunctionEligibilityTx(c, q, p, id)
	return eligible && fact.FunctionID == id && !at.Before(fact.EligibleAt), err
}
