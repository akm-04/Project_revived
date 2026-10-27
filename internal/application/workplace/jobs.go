package workplace

import (
	"context"
	"encoding/hex"
	"fmt"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

func (s Mode) Dispatch(c context.Context, a identity.ActorContext, q Dispatch, op operation.Context) (map[string]any, error) {
	if q.Team < 1 || q.Team > 6 || q.Job <= 0 || q.SP < 0 || len(q.Partners) < 1 || len(q.Partners) > 23 {
		return nil, d.ErrInvalid
	}
	q.Partners = append([]int64{}, q.Partners...)
	sort.Slice(q.Partners, func(i, j int) bool { return q.Partners[i] < q.Partners[j] })
	fp, err := receipt.FingerprintRequest(q)
	if err != nil {
		return nil, err
	}
	fingerprint := hex.EncodeToString(fp[:])
	return s.run(c, a, "dispatch", q, q.Partners, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		if old := r.Slots[q.Team]; old != nil {
			if old.Fingerprint != fingerprint {
				return nil, d.ErrRefused
			}
			return team(v, r, q.Team), nil
		}
		location, ok := v.catalog.Location(q.Team)
		if !ok {
			return nil, d.ErrInvalid
		}
		job, ok := v.catalog.Job(q.Job)
		if !ok {
			return nil, d.ErrInvalid
		}
		if !v.eligible[q.Job] {
			return nil, d.ErrRefused
		}
		workers := []d.Worker{}
		for _, id := range q.Partners {
			h := v.locked[id]
			crew, ok := v.catalog.Girl(h.OriginTableID)
			if !ok || crew.Location != q.Team || r.Busy(id) {
				return nil, d.ErrRefused
			}
			force, err := s.force(c, sc, a, h.Ref(), v.revision)
			if err != nil {
				return nil, err
			}
			workers = append(workers, d.Worker{PartnerID: id, BaseID: h.OriginTableID, Level: h.Level, Star: h.Star, Color: h.Color, Trait: crew.Trait, Power: force})
		}
		quote, err := d.Calculate(location, job, workers, v.catalog.VIP[v.vip], v.catalog.Formula)
		if err != nil {
			return nil, err
		}
		if quote.SP != q.SP {
			return nil, d.ErrInvalid
		}
		if r.Sequence >= 9007199254740991 {
			return nil, d.ErrUnavailable
		}
		r.Sequence++
		o := &d.Occurrence{ID: fmt.Sprintf("%d:%d:%d", a.PlayerID, q.Team, r.Sequence), Team: q.Team, Job: q.Job, Revision: v.revision, PolicySHA: v.catalog.PolicySHA, Start: sc.Operation.DecisionAt().Unix(), Quote: quote, Workers: workers, Fingerprint: fingerprint, PartnersInfo: []map[string]any{}}
		rng := cd.NewStream(sc.Operation.Operation().Derive("workplace.job-reward/v1", uint64(r.Sequence)))
		normal := map[string]any{"award_type": job.Product, "item_num": quote.Quantity, "award_time": o.Start + quote.Seconds}
		o.Award = map[string]any{"normal_award": normal, "externa_crystal_award": int64(0), "chest_award": map[string]any{}, "battle_award": map[string]any{}}
		if quote.Quantity > 0 {
			switch job.Product {
			case 1, 4, 5:
				key := map[int64]string{1: "mana", 4: "magic_dust", 5: "magic_liquid"}[job.Product]
				o.Lines = append(o.Lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: quote.Quantity})
			case 3:
				counts := map[int64]int64{}
				for i := int64(0); i < quote.Quantity; i++ {
					counts[v.catalog.Scrolls[rng.Uniform(uint64(len(v.catalog.Scrolls)))]]++
				}
				items := []map[string]any{}
				ids := []int64{}
				for id := range counts {
					ids = append(ids, id)
				}
				sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
				for _, id := range ids {
					items = append(items, map[string]any{"item_id": id, "item_num": counts[id]})
					o.Lines = append(o.Lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: counts[id]})
				}
				normal["items"] = items
			default:
				id := v.catalog.ItemProducts[job.Product]
				if id <= 0 {
					return nil, d.ErrUnavailable
				}
				normal["item_id"] = id
				o.Lines = append(o.Lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: quote.Quantity})
			}
		}
		if !r.BonusUsed && r.BonusLocation == q.Team {
			rate := v.catalog.VIP[v.vip]
			amount := r.BonusBase * rate.Numerator / rate.Denominator
			o.Award["externa_crystal_award"] = amount
			if amount > 0 {
				o.Lines = append(o.Lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: amount})
			}
			r.BonusUsed = true
		}
		if quote.ChestPercent > int64(rng.Uniform(100)) && len(job.Chests) > 0 {
			reward := job.Chests[rng.Uniform(uint64(len(job.Chests)))]
			o.Award["chest_award"] = map[string]any{"item_id": reward[0], "item_num": reward[1], "award_time": o.Start + quote.Seconds}
			o.Lines = append(o.Lines, grant.Line{Kind: grant.StackItem, ItemID: reward[0], Amount: reward[1]})
		}
		if quote.RivalPercent > int64(rng.Uniform(100)) && len(job.Chests) > 0 {
			o.RivalReward = job.Chests[rng.Uniform(uint64(len(job.Chests)))]
			crew := append([]d.Worker{}, workers...)
			sort.SliceStable(crew, func(i, j int) bool { return crew[i].Power > crew[j].Power })
			if len(crew) > v.catalog.Policy.MaxCombatCrew {
				crew = crew[:v.catalog.Policy.MaxCombatCrew]
			}
			allies := []cb.Participant{}
			level := int64(0)
			for _, w := range crew {
				allies = append(allies, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: a.PlayerID, Identity: w.PartnerID})
				level += w.Level
				row, err := s.HeroWire(v.locked[w.PartnerID])
				if err != nil {
					return nil, err
				}
				o.PartnersInfo = append(o.PartnersInfo, row)
			}
			enemies, err := s.Opponents.WorkplaceOpponentTx(c, sc.Tx, level/int64(len(crew)))
			if err != nil {
				return nil, err
			}
			scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, v.revision, sc.Operation.DecisionAt())
			if err != nil {
				return nil, err
			}
			started, err := s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: locator(a, q.Team), GenerationRef: o.ID, StartFingerprint: fingerprint, ResultDeadline: sc.Operation.DecisionAt().Add(time.Duration(v.catalog.Policy.AttemptLifetime) * time.Second), Battle: cb.BattleRequest{CampaignType: v.catalog.Policy.CampaignType, BattleID: v.catalog.Policy.BattleID, TeamA: allies, WavesB: [][]cb.Participant{enemies}}})
			if err != nil {
				return nil, err
			}
			o.Attempt = started.Attempt.ID.String()
		}
		c, err = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if err != nil {
			return nil, err
		}
		if _, err = s.Values.WorkplaceSPTx(c, sc.Tx, a.PlayerID, ownerOp(sc)); err != nil {
			return nil, err
		}
		if quote.SP > 0 {
			if _, err = s.Values.DebitTemporalTx(c, sc.Tx, a.PlayerID, i5.WorkplaceSPKey, quote.SP, ownerOp(sc)); err != nil {
				return nil, err
			}
		}
		if err = s.Facts.RecordTx(c, sc.Tx, sc.Operation.Operation(), objective.Fact{PlayerID: a.PlayerID, SourceDomain: "workplace", SourceBusinessKey: o.ID, Kind: "WORKPLACE_TEAM_SENT", Delta: 1}); err != nil {
			return nil, err
		}
		r.Slots[q.Team] = o
		r.Selections[q.Team] = q.Partners
		return team(v, r, q.Team), nil
	})
}
func locator(a identity.ActorContext, team int64) cd.Locator {
	return cd.Locator{DomainKind: "WORKPLACE_JOB_RIVAL", AuthorityScope: fmt.Sprintf("server:%d", a.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d:team:%d", a.PlayerID, team)}
}
