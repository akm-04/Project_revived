package march

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"strconv"
)

func (s Mode) Result(c context.Context, a identity.ActorContext, q Result, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "result", q, q.Report.Formation, op, func(c context.Context, sc gen.TimedScope, v view, r *d.Run) (map[string]any, error) {
		if !q.Report.Finite() {
			return nil, d.ErrInvalid
		}
		if r.Pending == "" {
			if len(r.LastResult) == 0 {
				return map[string]any{"error_code": 1}, nil
			}
			out := map[string]any{}
			if err := json.Unmarshal(r.LastResult, &out); err != nil {
				return nil, err
			}
			out["error_code"] = cd.FightExistCode
			return out, nil
		}
		if len(q.Report.Formation) == 0 {
			q.Report.Formation = append([]int64{}, r.Formation...)
		}
		if !sameFormation(q.Report.Formation, r.Formation) || q.CostDrink < 0 || q.CostDrink > r.Drinks {
			return nil, d.ErrRefused
		}
		attested, err := s.Combat.AttestReportTx(c, sc.Tx, appcombat.ReportRequest{Locator: locator(a), GenerationRef: r.Pending, TerminalKind: "MARCH_RESULT", At: sc.Operation.DecisionAt(), Policy: reportPolicy, Report: q.Report})
		if err != nil {
			return nil, err
		}
		if attested.Drained {
			r.Pending = ""
			return map[string]any{"error_code": 1}, nil
		}
		if attested.Attestation.Verdict == cd.VerdictRejected {
			r.Pending = ""
			return map[string]any{"error_code": 1}, nil
		}
		if err = r.ApplyReport(q.Report, q.CostDrink); err != nil {
			return nil, err
		}
		if q.Report.Win {
			if r.Rewards == nil {
				r.Rewards = map[string][]any{}
			}
			r.Rewards[strconv.FormatInt(r.NextStage(), 10)] = s.freezeReward(v, *r, sc, r.NextStage())
		}
		c, err = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if err != nil {
			return nil, err
		}
		if err = s.Facts.RecordTx(c, sc.Tx, sc.Operation.Operation(), objective.Fact{PlayerID: a.PlayerID, SourceDomain: "march", SourceBusinessKey: attested.Attempt.ID.String(), Kind: "MARCH_FINISHED", Delta: 1}); err != nil {
			return nil, err
		}
		out := r.Projection()
		out["win"] = q.Report.Win
		out["enemy_status"] = r.Enemies[r.Passed].Rows()
		if q.Report.Win {
			out["reward"] = r.Rewards[strconv.FormatInt(r.NextStage(), 10)]
		}
		r.LastResult, err = json.Marshal(out)
		return out, err
	})
}
func (s Mode) freezeReward(v view, r d.Run, sc gen.TimedScope, stage int64) []any {
	rng := cd.NewStream(sc.Operation.Operation().Derive("march.stage-reward/v1", uint64(stage)))
	rows := []any{}
	for _, item := range v.catalog.Draw(false, r.LifetimeChests+1, rng) {
		rows = append(rows, map[string]any{"table_id": item[0], "item_num": item[1]})
	}
	mana := float64(v.level*v.catalog.Policy.ManaPerLevel) * v.catalog.Factors("expedition_mana_param")[stage-1]
	mana *= float64(9500+rng.Uniform(1001)) / 10000
	rows = append(rows, map[string]any{"table_id": int64(-1), "mana": true, "item_num": int64(mana)}, map[string]any{"table_id": int64(-1), "march_coin": true, "item_num": v.catalog.Policy.MarchCoin})
	return rows
}
func (s Mode) Chest(c context.Context, a identity.ActorContext, stage int64, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "chest", stage, nil, op, func(c context.Context, sc gen.TimedScope, v view, r *d.Run) (map[string]any, error) {
		if !r.Won || stage != r.NextStage() {
			return nil, d.ErrRefused
		}
		key := strconv.FormatInt(stage, 10)
		rows, ok := r.Rewards[key]
		if !ok {
			return nil, d.ErrUnavailable
		}
		c, err := s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if err != nil {
			return nil, err
		}
		awards, err := s.awards(c, sc, a, v, "stage/"+key, rows)
		if err != nil {
			return nil, err
		}
		if err = r.AdvanceChest(stage); err != nil {
			return nil, err
		}
		// onUpdateMarch_ merges the actual item/hero rewards before the popup.
		out := map[string]any{"map_info": r.Projection()["map_info"], "hero_status": map[string]any{}, "rewards": awards}
		return out, nil
	})
}
func (s Mode) Extra(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "extra", struct{}{}, nil, op, func(c context.Context, sc gen.TimedScope, v view, r *d.Run) (map[string]any, error) {
		if r.Cleared() < 9 || r.Extra {
			return nil, d.ErrRefused
		}
		c, err := s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if err != nil {
			return nil, err
		}
		_, err = s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: 50}}}, sc.Operation.Operation())
		if errors.Is(err, economy.ErrInsufficientBalance) {
			return nil, d.ErrRefused
		}
		if err != nil {
			return nil, err
		}
		rng := cd.NewStream(sc.Operation.Operation().Derive("march.extra-reward/v1", 0))
		rows := []any{}
		for _, item := range v.catalog.Draw(true, 0, rng) {
			rows = append(rows, map[string]any{"table_id": item[0], "item_num": item[1]})
		}
		awards, err := s.awards(c, sc, a, v, "extra", rows)
		if err != nil {
			return nil, err
		}
		r.Extra = true
		r.Version++
		return map[string]any{"map_info": r.Projection()["map_info"], "hero_status": map[string]any{}, "rewards": awards}, nil
	})
}
func (s Mode) awards(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, name string, rows []any) ([]any, error) {
	catalog, err := s.Content.SummonCatalogTx(c, sc.Tx, v.revision)
	if err != nil {
		return nil, err
	}
	out, lines := []any{}, []grant.Line{}
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			return nil, d.ErrUnavailable
		}
		n := number(row["item_num"])
		if n <= 0 {
			continue
		}
		scalar := ""
		if row["mana"] == true {
			scalar = "mana"
		}
		if row["march_coin"] == true {
			scalar = "march_coin"
		}
		if scalar != "" {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: scalar, Amount: n})
			out = append(out, row)
			continue
		}
		id := number(row["table_id"])
		if _, hero := catalog.Hero(id); hero {
			if n != 1 {
				return nil, d.ErrInvalid
			}
			h, admission, err := s.Heroes.AwardStoryPartnerTx(c, sc.Tx, a.PlayerID, id, v.revision, sc.Operation.Operation())
			if err != nil {
				return nil, err
			}
			if admission == nil {
				stone, err := catalog.Fragments(id)
				if err != nil {
					return nil, err
				}
				id, n = stone[0], stone[1]
				out = append(out, map[string]any{"table_id": id, "item_num": n, "is_partner": false, "to_stone": true})
			} else {
				wire, err := s.HeroWire(h)
				if err != nil {
					return nil, err
				}
				wire["is_partner"] = true
				out = append(out, wire)
				continue
			}
		} else {
			out = append(out, map[string]any{"table_id": id, "item_num": n, "is_partner": false})
		}
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: n})
	}
	if len(lines) > 0 {
		op := sc.Operation.Operation()
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "march", Operation: name, BusinessKey: fmt.Sprintf("march:%s:%s", op.ID.String(), name), Occurrence: op.ID.String(), PolicyVersion: d.PolicyID}, Lines: lines}
		if _, err = s.Grants.SettleGrantTx(c, sc.Tx, a, plan, op, i5.GrantTxOptions{AllowOverflowMail: true}); err != nil {
			return nil, err
		}
	}
	return out, nil
}
