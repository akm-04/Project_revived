package godstrial

import (
	"context"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	cd "gxb.local/backend/v2/internal/domain/combat"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/modes"
	spirit "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func (s Mode) BeginAuto(c context.Context, a identity.ActorContext, campaign, times int64, op operation.Context) (map[string]any, error) {
	if campaign <= 0 || times < 1 || times > 10 {
		return nil, d.ErrInvalid
	}
	request := struct{ Campaign, Times int64 }{campaign, times}
	return s.run(c, a, "auto-start", request, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		if r.Auto != nil {
			if r.Auto.Campaign == campaign && r.Auto.Times == times {
				return r.Base(), nil
			}
			return nil, d.ErrRefused
		}
		stage, e := s.admit(v, r, campaign, modes.Day(sc.Operation.DecisionAt()), true)
		if e != nil {
			return nil, e
		}
		if times > v.catalog.AutoLimit || r.Sequence >= spirit.MaxID {
			return nil, d.ErrRefused
		}
		r.Sequence++
		id := fmt.Sprintf("%d:%d", a.PlayerID, r.Sequence)
		stream := cd.NewStream(sc.Operation.Operation().Derive("godstrial.auto-drop/v1", 0))
		lines := []grant.Line{}
		for i := int64(0); i < times; i++ {
			lines = append(lines, v.catalog.Lines(v.catalog.Drop(stage.RepeatBox, stream))...)
		}
		if _, e = s.Energy.DebitTemporalTx(c, sc.Tx, a.PlayerID, "spirit_energy", stage.WinCost*times, sc.Operation.Operation()); e != nil {
			return nil, e
		}
		start := sc.Operation.DecisionAt().Unix()
		r.Auto = &d.Auto{ID: id, Revision: v.revision, Provider: s.Spirit.ProviderRevision(), Campaign: campaign, Times: times, Start: start, Due: start + times*v.catalog.AutoMinutes*60, Lines: lines}
		r.LastAuto = nil
		return r.Base(), nil
	})
}
func (s Mode) CollectAuto(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "auto-collect", struct{}{}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		p := r.Auto
		if p == nil {
			if r.LastAuto != nil {
				return r.LastAuto, nil
			}
			return nil, d.ErrRefused
		}
		if sc.Operation.DecisionAt().Unix() < p.Due {
			return nil, d.ErrRefused
		}
		if e := s.Mail.LockMailNamespaceCounterTx(c, sc.Tx, a.PlayerID, mail.Normal); e != nil {
			return nil, e
		}
		var e error
		c, e = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if e != nil {
			return nil, e
		}
		items, spirits, e := s.reward(c, sc, a, p.Revision, p.Provider, p.ID, p.Lines)
		if e != nil {
			return nil, e
		}
		if r.Wins[p.Campaign] > spirit.MaxID-p.Times {
			return nil, d.ErrUnavailable
		}
		r.Wins[p.Campaign] += p.Times
		if e = s.record(c, sc, a, p.ID, p.Times); e != nil {
			return nil, e
		}
		awards := []map[string]any{}
		for _, i := range items {
			awards = append(awards, map[string]any{"table_id": i["item_id"], "item_num": i["item_num"]})
		}
		r.Auto = nil
		out := map[string]any{"awards": awards, "spirit_awards": spirits, "base_info": r.Base()}
		r.LastAuto = out
		return out, nil
	})
}
