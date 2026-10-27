package petcampaign

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"strings"
	"time"
)

func locator(a identity.ActorContext, practice bool) cd.Locator {
	kind := "petcampaign"
	if practice {
		kind += "-practice"
	}
	return cd.Locator{DomainKind: kind, AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprint(a.PlayerID)}
}
func (s Mode) Load(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "load", struct{}{}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		return r.Projection(v.catalog), nil
	})
}

// Detail822 never grants the due preview it projects.
func (s Mode) Detail(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "detail", struct{}{}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		out := r.Normal()
		if r.Sweep != nil && sc.Operation.DecisionAt().Unix() >= r.Sweep.Due {
			out["awards"] = r.Sweep.Awards
		}
		return out, nil
	})
}
func award(f d.Floor, first, vip bool) ([]grant.Line, []map[string]any) {
	lines := []grant.Line{}
	rows := []map[string]any{}
	for _, i := range f.Award(first, vip) {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: i.ID, Amount: i.Count})
		rows = append(rows, map[string]any{"table_id": i.ID, "item_num": i.Count})
	}
	if f.Mana > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: f.Mana})
		rows = append(rows, map[string]any{"table_id": int64(-1), "item_num": f.Mana, "mana": f.Mana})
	}
	return lines, rows
}
func (s Mode) freezeMaterial(c context.Context, sc gen.TimedScope, a identity.ActorContext, floors []d.Floor) (json.RawMessage, error) {
	routes := []i5.PetMaterialRoute{}
	for _, f := range floors {
		for _, m := range f.Materials {
			routes = append(routes, i5.PetMaterialRoute{Mission: m.Mission, Item: m.Item, Count: m.Count})
		}
	}
	drop, e := s.Awakening.FreezeAwakeningPetMaterialTx(c, sc.Tx, a.PlayerID, routes)
	if e != nil || drop == nil {
		return nil, e
	}
	return json.Marshal(drop)
}
func (s Mode) settle(c context.Context, sc gen.TimedScope, a identity.ActorContext, revision, key string, lines []grant.Line, rows []map[string]any, material json.RawMessage, fact bool) ([]map[string]any, error) {
	c, e := s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
	if e != nil {
		return nil, fmt.Errorf("pet reward prepare objectives: %w", e)
	}
	lines = append([]grant.Line{}, lines...)
	rows = append([]map[string]any{}, rows...)
	if len(material) > 0 && !bytes.Equal(bytes.TrimSpace(material), []byte("null")) {
		var drop objective.AwakeFrozenDrop
		if e = json.Unmarshal(material, &drop); e != nil {
			return nil, fmt.Errorf("pet reward decode material: %w", e)
		}
		ok, e := s.Awakening.CheckAwakeningPetMaterialTx(c, sc.Tx, a.PlayerID, drop)
		if e != nil {
			return nil, fmt.Errorf("pet reward validate material: %w", e)
		}
		if ok {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: drop.ItemID, Amount: drop.Count})
			rows = append(rows, map[string]any{"table_id": drop.ItemID, "item_num": drop.Count})
		}
	}
	if fact {
		if e = s.Facts.RecordTx(c, sc.Tx, sc.Operation.Operation(), objective.Fact{PlayerID: a.PlayerID, SourceDomain: "petcampaign", SourceBusinessKey: key, Kind: "SKY_CITY_BATTLE", Delta: 1}); e != nil {
			return nil, fmt.Errorf("pet reward record fact: %w", e)
		}
	}
	if len(lines) > 0 {
		op := sc.Operation.Operation()
		refs := op.Policies.Refs()
		for i := range refs {
			if refs[i].Name == "content" {
				refs[i].Version = revision
			}
		}
		var e error
		op.Policies, e = policy.NewSet(refs...)
		pinned := op
		if e != nil {
			return nil, fmt.Errorf("pet reward pin reward revision: %w", e)
		}
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "petcampaign", Operation: "reward", BusinessKey: key, Occurrence: key, PolicyVersion: policyID}, Lines: lines}
		if _, e = s.Values.SettleGrantTx(c, sc.Tx, a, plan, pinned, i5.GrantTxOptions{AllowOverflowMail: true}); e != nil {
			return nil, fmt.Errorf("pet reward grant reward: %w", e)
		}
	}
	return rows, nil
}
func (s Mode) debit(c context.Context, sc gen.TimedScope, a identity.ActorContext, key string, n int64, item bool) error {
	if n <= 0 {
		return nil
	}
	cost := i5.MaterialCost{}
	if item {
		id, e := strconv.ParseInt(key, 10, 64)
		if e != nil {
			return e
		}
		cost.Stacks = []i5.StackMaterialCost{{ItemID: id, Amount: n}}
	} else {
		cost.Scalars = []i5.ScalarMaterialCost{{ResourceKey: key, Amount: n}}
	}
	_, e := s.Costs.DebitMaterialCostTx(c, sc.Tx, a.PlayerID, cost, sc.Operation.Operation())
	return e
}
func (s Mode) Start(c context.Context, a identity.ActorContext, q Fight, op operation.Context) (map[string]any, error) {
	if q.Campaign <= 0 || q.Pet < 0 || len(q.Formation) < 1 || len(q.Formation) > 5 {
		return nil, d.ErrInvalid
	}
	positive := 0
	for _, h := range q.Formation {
		if h < 0 || h > 9007199254740991 {
			return nil, d.ErrInvalid
		}
		if h > 0 {
			positive++
		}
	}
	if positive == 0 {
		return nil, d.ErrInvalid
	}
	return s.run(c, a, "start", q, q.Formation, q.Pet, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		f, ok := v.catalog.ByID(q.Campaign)
		if !ok || r.Sweep != nil {
			return nil, d.ErrRefused
		}
		if f.Type == 1 && (q.Practice || f.Number != r.Current+1) || f.Type == 2 && (r.Max < 100 || !q.Practice && f.Number > r.EliteMax+1) {
			return nil, d.ErrRefused
		}
		if r.Sequence >= 9007199254740991 {
			return nil, d.ErrUnavailable
		}
		r.Sequence++
		id := fmt.Sprintf("%d:%d", a.PlayerID, r.Sequence)
		at := sc.Operation.DecisionAt()
		scope, e := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, v.revision, at)
		if e != nil {
			return nil, e
		}
		waves, e := cb.MonsterWaves(s.Rules, f.Fight)
		if e != nil {
			return nil, e
		}
		battle := cb.BattleRequest{CampaignType: 23, BattleID: f.Fight, Formation: append([]int64{}, q.Formation...), WavesB: waves}
		for _, h := range q.Formation {
			if h == 0 {
				continue
			}
			battle.TeamA = append(battle.TeamA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: h})
		}
		if q.Pet > 0 {
			battle.PetsA = []cb.Participant{{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: q.Pet}}
		}
		trust := cd.ClientSummaryAttested
		if q.Practice {
			trust = cd.PracticeNoValue
		}
		fp, e := receipt.FingerprintRequest(struct {
			ID      string
			Request Fight
		}{id, q})
		if e != nil {
			return nil, e
		}
		if _, e = s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: locator(a, q.Practice), GenerationRef: id, StartFingerprint: fmt.Sprintf("%x", fp), ResultDeadline: at.Add(time.Hour), Battle: battle, TrustProfile: trust, Replay: cd.ReplaySpec{Response: cd.ReplayOK}}); e != nil {
			return nil, e
		}
		if q.Practice {
			if e = s.debit(c, sc, a, "mana", v.catalog.PracticeMana, false); e != nil {
				return nil, e
			}
			ids := []string{}
			for _, h := range q.Formation {
				ids = append(ids, fmt.Sprint(h))
			}
			r.TestFormation[f.Number] = strings.Join(ids, "|") + "@" + fmt.Sprint(q.Pet)
			return map[string]any{}, nil
		}
		if f.Type == 2 {
			if e = s.debit(c, sc, a, fmt.Sprint(v.catalog.Ticket), 1, true); e != nil {
				return nil, e
			}
		}
		first := f.Type == 1 && f.Number > r.Max || f.Type == 2 && f.Number > r.EliteMax
		lines, rows := award(f, first, v.vip)
		material, e := s.freezeMaterial(c, sc, a, []d.Floor{f})
		if e != nil {
			return nil, e
		}
		r.Fight = &d.Fight{ID: id, Revision: v.revision, Kind: f.Type, Floor: f.Number, Pet: q.Pet, Deadline: at.Add(time.Hour).Unix(), Formation: append([]int64{}, q.Formation...), Lines: lines, Awards: rows, Material: material}
		r.LastResult = nil
		return map[string]any{}, nil
	})
}
func (s Mode) Result(c context.Context, a identity.ActorContext, q Result, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "result", q, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		if q.Kind < 1 || q.Kind > 2 || q.Floor < 1 || q.Pet < 0 {
			return nil, d.ErrInvalid
		}
		p := r.Fight
		if p == nil {
			if r.LastResult != nil && r.LastResultKind == q.Kind && r.LastResultFloor == q.Floor && (!q.HasPet || r.LastResultPet == q.Pet) && q.Win {
				return r.LastResult, nil
			}
			return nil, d.ErrRefused
		}
		if p.Kind != q.Kind || p.Floor != q.Floor || q.HasPet && p.Pet != q.Pet {
			return nil, d.ErrRefused
		}
		judged, e := s.Combat.AttestSummaryTx(c, sc.Tx, cb.SummaryRequest{Locator: locator(a, false), GenerationRef: p.ID, TerminalKind: "PET_CAMPAIGN_RESULT", At: sc.Operation.DecisionAt(), Policy: cd.SummaryPolicy{ID: "I9_PET_CAMPAIGN_SUMMARY_V1", Version: 1, OmitParticipantEcho: true}, Summary: cd.Summary{Win: q.Win}})
		if e != nil {
			return nil, e
		}
		if judged.Drained || judged.Attestation.Verdict == cd.VerdictRejected {
			r.Fight = nil
			return map[string]any{"error_code": int64(1)}, nil
		}
		out := map[string]any{"awards": []map[string]any{}, "now_floor": r.Current, "max_floor": r.Max}
		if q.Win {
			unlock := q.Kind == 1 && q.Floor == 100 && r.Max < 100
			if e = r.Win(q.Kind, q.Floor, sc.Operation.DecisionAt().Unix()); e != nil {
				return nil, e
			}
			if unlock {
				p.Lines = append(p.Lines, grant.Line{Kind: grant.StackItem, ItemID: v.catalog.Ticket, Amount: v.catalog.UnlockTickets})
			}
			rows, e := s.settle(c, sc, a, p.Revision, p.ID, p.Lines, p.Awards, p.Material, true)
			if e != nil {
				return nil, e
			}
			info := r.Projection(v.catalog)
			if unlock {
				info["super"].(map[string]any)["awards"] = []map[string]any{{"table_id": v.catalog.Ticket, "item_num": v.catalog.UnlockTickets}}
			}
			now, max := r.Current, r.Max
			if q.Kind == 2 {
				now, max = r.Selected, r.EliteMax
			}
			out = map[string]any{"awards": rows, "now_floor": now, "max_floor": max, "info": info}
		}
		r.Fight = nil
		if q.Win {
			r.LastResult = out
			r.LastResultKind = q.Kind
			r.LastResultFloor = q.Floor
			r.LastResultPet = p.Pet
		}
		return out, nil
	})
}
