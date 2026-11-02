package godstrial

import (
	"context"
	"encoding/json"
	"fmt"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	spirit "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func locator(a identity.ActorContext) cd.Locator {
	return cd.Locator{DomainKind: "godstrial", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprint(a.PlayerID)}
}
func formationValid(ids []int64) bool {
	if len(ids) < 1 || len(ids) > 5 {
		return false
	}
	seen := map[int64]bool{}
	for _, h := range ids {
		if h <= 0 || h > spirit.MaxID || seen[h] {
			return false
		}
		seen[h] = true
	}
	return true
}
func (s Mode) admit(v view, r *d.State, campaign int64, day int64, auto bool) (d.Stage, error) {
	stage, ok := v.catalog.Stage(campaign)
	if !ok || !r.Open(stage, day, v.level) || v.count >= v.catalog.SoftLimit || auto && r.Wins[campaign] == 0 {
		return stage, d.ErrRefused
	}
	if s.Spirit.ProviderRevision() != spirit.ReconstructionPolicy {
		return stage, d.ErrUnavailable
	}
	return stage, nil
}
func (s Mode) Start(c context.Context, a identity.ActorContext, q Fight, op operation.Context) (map[string]any, error) {
	if q.Campaign <= 0 || q.Pet < 0 || !formationValid(q.Formation) {
		return nil, d.ErrInvalid
	}
	return s.run(c, a, "start", q, q.Formation, q.Pet, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		stage, e := s.admit(v, r, q.Campaign, modes.Day(sc.Operation.DecisionAt()), false)
		if e != nil {
			return nil, e
		}
		same := d.SameFight(r.Fight, q.Campaign, q.Pet, q.Formation) && r.Fight.RentPlayer == q.RentPlayer && r.Fight.RentUnit == q.RentUnit && r.Fight.RentPetPlayer == q.RentPetPlayer && r.Fight.RentPetUnit == q.RentPetUnit && sc.Operation.DecisionAt().Unix() < r.Fight.Deadline
		id := fmt.Sprintf("%d:%d", a.PlayerID, r.Sequence+1)
		if same {
			id = r.Fight.ID
		} else {
			if r.Sequence >= spirit.MaxID {
				return nil, d.ErrUnavailable
			}
			r.Sequence++
		}
		scope, e := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, v.revision, sc.Operation.DecisionAt())
		if e != nil {
			return nil, e
		}
		waves, e := cb.MonsterWaves(s.Rules, stage.Battle)
		if e != nil {
			return nil, e
		}
		battle := cb.BattleRequest{CampaignType: 79, BattleID: stage.Battle, Formation: append([]int64{}, q.Formation...), WavesB: waves}
		for _, h := range q.Formation {
			battle.TeamA = append(battle.TeamA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: h})
		}
		if q.Pet > 0 {
			battle.PetsA = []cb.Participant{{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: a.PlayerID, Identity: q.Pet}}
		}
		if q.RentUnit > 0 && q.RentPlayer > 0 {
			battle.TeamA = append(battle.TeamA, cb.Participant{Origin: cd.Borrowed, Kind: cd.HeroActor, Player: identity.PlayerID(q.RentPlayer), Identity: q.RentUnit})
		}
		if q.RentPetUnit > 0 && q.RentPetPlayer > 0 {
			battle.PetsA = append(battle.PetsA, cb.Participant{Origin: cd.Borrowed, Kind: cd.PetActor, Player: identity.PlayerID(q.RentPetPlayer), Identity: q.RentPetUnit})
		}
		fp, e := receipt.FingerprintRequest(q)
		if e != nil {
			return nil, e
		}
		box := stage.RepeatBox
		if r.Wins[q.Campaign] == 0 {
			box = stage.FirstBox
		}
		deadline := sc.Operation.DecisionAt().Add(time.Hour)
		if same {
			deadline = time.Unix(r.Fight.Deadline, 0)
		}
		started, e := s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: locator(a), GenerationRef: id, StartFingerprint: fmt.Sprintf("%x", fp), ResultDeadline: deadline, Battle: battle, TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayFightExist, ErrorCode: cd.FightExistCode}, Package: func(stream *cd.Stream) (any, error) { return v.catalog.Lines(v.catalog.Drop(box, stream)), nil }})
		if e != nil {
			return nil, e
		}
		balance, e := s.Energy.TemporalBalanceTx(c, sc.Tx, a.PlayerID, "spirit_energy", sc.Operation.Operation())
		if e != nil {
			return nil, e
		}
		if balance < stage.WinCost {
			return nil, d.ErrRefused
		}
		if !same {
			if started.Package == nil {
				return nil, d.ErrUnavailable
			}
			var lines []grant.Line
			if e = json.Unmarshal(started.Package.Canonical, &lines); e != nil {
				return nil, e
			}
			r.Fight = &d.Fight{ID: id, Revision: v.revision, Provider: s.Spirit.ProviderRevision(), Campaign: q.Campaign, Pet: q.Pet, Deadline: deadline.Unix(), Formation: append([]int64{}, q.Formation...), RentPlayer: q.RentPlayer, RentUnit: q.RentUnit, RentPetPlayer: q.RentPetPlayer, RentPetUnit: q.RentPetUnit, Lines: lines}
			r.LastResult = nil
			r.LastFight = nil
		}
		return map[string]any{}, nil
	})
}
func copiedReplay(out map[string]any) map[string]any {
	r := map[string]any{}
	for k, v := range out {
		r[k] = v
	}
	r["error_code"] = int64(cd.FightExistCode)
	return r
}
func (s Mode) Result(c context.Context, a identity.ActorContext, q Result, op operation.Context) (map[string]any, error) {
	if q.Campaign <= 0 || q.Pet < 0 || q.Star < 0 || q.Star > 3 || !formationValid(q.Formation) {
		return nil, d.ErrInvalid
	}
	return s.run(c, a, "result", q, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		p := r.Fight
		if p == nil {
			if r.LastResult != nil && r.LastFight != nil && d.SameFight(r.LastFight, q.Campaign, q.Pet, q.Formation) && r.LastStar == q.Star {
				return copiedReplay(r.LastResult), nil
			}
			return nil, d.ErrRefused
		}
		if !d.SameFight(p, q.Campaign, q.Pet, q.Formation) {
			return nil, d.ErrRefused
		}
		judged, e := s.Combat.AttestSummaryTx(c, sc.Tx, cb.SummaryRequest{Locator: locator(a), GenerationRef: p.ID, TerminalKind: "GODS_TRIAL_RESULT", At: sc.Operation.DecisionAt(), Policy: cd.SummaryPolicy{ID: "I9_GODS_TRIAL_SUMMARY_V1", Version: 1, MaxStar: 3, WinFromStar: true}, Summary: cd.Summary{Star: q.Star, Win: q.Star > 0, Formation: q.Formation, Pet: q.Pet}})
		if e != nil {
			return nil, e
		}
		if judged.Drained || judged.Attestation.Verdict == cd.VerdictRejected {
			r.Fight = nil
			return map[string]any{"error_code": int64(cd.FightExistCode), "items": []any{}, "spirit_items": []any{}}, nil
		}
		// Overflow Mail's prefix precedes the I5 temporal suffix used by this settlement.
		if e = s.Mail.LockMailNamespaceCounterTx(c, sc.Tx, a.PlayerID, mail.Normal); e != nil {
			return nil, e
		}
		c, e = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if e != nil {
			return nil, e
		}
		frozen, e := s.Content.GodsTrialCatalogTx(c, sc.Tx, p.Revision)
		if e != nil {
			return nil, e
		}
		stage, ok := frozen.Stage(p.Campaign)
		if !ok {
			return nil, d.ErrUnavailable
		}
		cost := stage.LoseCost
		if q.Star > 0 {
			cost = stage.WinCost
		}
		if _, e = s.Energy.DebitTemporalTx(c, sc.Tx, a.PlayerID, "spirit_energy", cost, sc.Operation.Operation()); e != nil {
			return nil, e
		}
		out := map[string]any{"items": []map[string]any{}, "spirit_items": []map[string]any{}}
		if q.Star > 0 {
			ordinary, spirits, e := s.reward(c, sc, a, p.Revision, p.Provider, p.ID, p.Lines)
			if e != nil {
				return nil, e
			}
			out["items"], out["spirit_items"] = ordinary, spirits
			if r.Wins[p.Campaign] >= spirit.MaxID {
				return nil, d.ErrUnavailable
			}
			r.Wins[p.Campaign]++
			if e = s.record(c, sc, a, p.ID, 1); e != nil {
				return nil, e
			}
		}
		r.LastResult = out
		r.LastFight = p
		r.LastStar = q.Star
		r.Fight = nil
		return out, nil
	})
}
func (s Mode) record(c context.Context, sc gen.TimedScope, a identity.ActorContext, key string, n int64) error {
	return s.Facts.RecordTx(c, sc.Tx, sc.Operation.Operation(), objective.Fact{PlayerID: a.PlayerID, SourceDomain: "godstrial", SourceBusinessKey: key, Kind: "GODS_TRIAL_CLEARED", Delta: n})
}
func (s Mode) reward(c context.Context, sc gen.TimedScope, a identity.ActorContext, rev, provider, key string, lines []grant.Line) ([]map[string]any, []map[string]any, error) {
	ordinary, spirits := []map[string]any{}, []map[string]any{}
	if provider != s.Spirit.ProviderRevision() || provider != spirit.ReconstructionPolicy {
		return nil, nil, d.ErrUnavailable
	}
	if len(lines) == 0 {
		return ordinary, spirits, nil
	}
	op := sc.Operation.Operation()
	refs := op.Policies.Refs()
	for i := range refs {
		if refs[i].Name == "content" {
			refs[i].Version = rev
		}
	}
	var e error
	op.Policies, e = policy.NewSet(refs...)
	if e != nil {
		return nil, nil, e
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "godstrial", Operation: "reward", BusinessKey: key, Occurrence: key, PolicyVersion: d.PolicyID}, Lines: lines}
	got, e := s.Values.SettleGrantTx(c, sc.Tx, a, plan, op, i5.GrantTxOptions{AllowOverflowMail: true})
	if e != nil {
		return nil, nil, e
	}
	for _, l := range lines {
		if l.Kind == grant.StackItem {
			ordinary = append(ordinary, map[string]any{"item_id": l.ItemID, "item_num": l.Amount})
		}
	}
	for _, m := range got.Materializations {
		if m.ProviderID != "spirit-generated-instance" || m.ProviderRevision != provider {
			return nil, nil, d.ErrUnavailable
		}
		var payload struct {
			Awards []map[string]any `json:"spirit_awards"`
		}
		if e = json.Unmarshal(m.ResultPayload, &payload); e != nil {
			return nil, nil, e
		}
		spirits = append(spirits, payload.Awards...)
	}
	return ordinary, spirits, nil
}
