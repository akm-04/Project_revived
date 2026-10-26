package march

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"strconv"
)

func (s Mode) Advance(c context.Context, a identity.ActorContext, q Fight, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "advance", q, q.Formation, op, func(c context.Context, sc gen.TimedScope, v view, r *d.Run) (map[string]any, error) {
		if v.level < 65 || r.HasFight || r.Advanced || r.Passed != 0 || r.Pending != "" {
			return nil, d.ErrRefused
		}
		if err := s.admitFormation(c, sc, a, *r, q.Formation, true); err != nil {
			return nil, err
		}
		locked, _ := c.Value(lockedHeroesKey{}).(map[int64]character.Hero)
		recommended := map[int64]bool{}
		for _, id := range r.Recommend {
			recommended[id] = true
		}
		power := int64(0)
		for _, id := range q.Formation {
			if id == 0 {
				continue
			}
			force, err := s.force(c, sc, a, character.HeroRef{PlayerID: a.PlayerID, PartnerID: id}, v.revision)
			if err != nil {
				return nil, err
			}
			if recommended[locked[id].OriginTableID] {
				force *= 2
			}
			power += force
		}
		rng := cd.NewStream(sc.Operation.Operation().Derive("march.advance/v1", 0))
		count, err := v.catalog.SweepCount(v.level, power, rng)
		if err != nil {
			return nil, err
		}
		c, err = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
		if err != nil {
			return nil, err
		}
		all, drinks := []any{}, []int64{}
		for stage := int64(1); stage <= count; stage++ {
			r.Won = true
			pending := s.freezeReward(v, *r, sc, stage)
			awards, err := s.awards(c, sc, a, v, "advance/"+strconv.FormatInt(stage, 10), pending)
			if err != nil {
				return nil, err
			}
			r.Rewards[strconv.FormatInt(stage, 10)] = awards
			if err = r.AdvanceChest(stage); err != nil {
				return nil, err
			}
			all = append(all, awards)
			drinks = append(drinks, v.catalog.Policy.Reagents)
		}
		for _, id := range q.Formation {
			if id > 0 {
				r.Heroes[strconv.FormatInt(id, 10)] = d.Status{Hero: id, Player: int64(a.PlayerID), Health: 2}
			}
		}
		r.Drinks += count * v.catalog.Policy.Reagents
		r.Advanced = true
		r.HasFight = true
		r.Version++
		if err = s.Facts.RecordTx(c, sc.Tx, sc.Operation.Operation(), objective.Fact{PlayerID: a.PlayerID, SourceDomain: "march", SourceBusinessKey: r.Occurrence + "/advance", Kind: "MARCH_FINISHED", Delta: count}); err != nil {
			return nil, err
		}
		return map[string]any{"map_info": r.Projection()["map_info"], "hero_status": r.Projection()["hero_status"], "award": all, "economy": []any{}, "power_drink": drinks}, nil
	})
}
