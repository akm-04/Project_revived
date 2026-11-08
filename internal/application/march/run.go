package march

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"sort"
	"strconv"
	"time"
)

func (s Mode) roster(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time) (map[string]any, error) {
	detail := map[string]any{}
	if err := s.Roster.OverlayMID1(c, q, a, false, at, detail); err != nil {
		return nil, err
	}
	body, ok := detail["49"].(map[string]any)
	if !ok {
		return nil, d.ErrUnavailable
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return nil, d.ErrUnavailable
	}
	return rows, nil
}

// fillStatuses adds a read-time self_list entry for every owned girl: carried
// run state for girls used in earlier stages and a fresh health-0 row for the
// rest, so the stock selector never reuses a recycled card's bars. The fresh
// entries are not saved into the run.
func (s Mode) fillStatuses(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time, out map[string]any) error {
	rows, err := s.roster(c, q, a, at)
	if err != nil {
		return err
	}
	envelope, ok := out["hero_status"].(map[string]any)
	if !ok {
		return d.ErrUnavailable
	}
	statuses, ok := envelope["self_list"].(map[string]any)
	if !ok {
		return d.ErrUnavailable
	}
	for key := range rows {
		id, err := strconv.ParseInt(key, 10, 64)
		if err != nil || id <= 0 {
			return d.ErrUnavailable
		}
		if _, carried := statuses[key]; !carried {
			statuses[key] = d.Status{Hero: id, Player: int64(a.PlayerID), Health: 0}
		}
	}
	return nil
}

func (s Mode) projectionWithStatuses(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time, r d.Run) (map[string]any, error) {
	out := r.Projection()
	if err := s.fillStatuses(c, q, a, at, out); err != nil {
		return nil, err
	}
	return out, nil
}
func (s Mode) admitFormation(c context.Context, sc gen.TimedScope, a identity.ActorContext, r d.Run, formation []int64, advanced bool) error {
	if len(formation) < 1 || len(formation) > 5 {
		return d.ErrInvalid
	}
	rows, err := s.roster(c, sc.Tx, a, sc.Operation.DecisionAt())
	if err != nil {
		return err
	}
	seen := map[int64]bool{}
	origins := map[int64]bool{}
	count := 0
	for _, id := range formation {
		if id == 0 {
			continue
		}
		if id < 0 || seen[id] {
			return d.ErrInvalid
		}
		seen[id] = true
		count++
		row, ok := rows[strconv.FormatInt(id, 10)].(map[string]any)
		if !ok || !r.Alive(id) {
			return d.ErrRefused
		}
		if advanced && number(row["lev"]) < 65 {
			return d.ErrRefused
		}
		locked, _ := c.Value(lockedHeroesKey{}).(map[int64]character.Hero)
		table := locked[id].OriginTableID
		if table <= 0 || origins[table] {
			return d.ErrRefused
		}
		origins[table] = true
	}
	if count == 0 || advanced && count != 5 {
		return d.ErrRefused
	}
	return nil
}
func (s Mode) initialize(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, r *d.Run, reset bool) error {
	candidates, err := s.Opponents.MarchCandidatesTx(c, sc.Tx, a, sc.Operation.DecisionAt(), int(v.catalog.Policy.CandidateLimit))
	if err != nil {
		return err
	}
	owned := candidates[:0]
	for _, candidate := range candidates {
		if candidate.Player != int64(a.PlayerID) {
			owned = append(owned, candidate)
		}
	}
	candidates = owned
	if len(candidates) == 0 {
		return d.ErrUnavailable
	}
	rows, err := s.roster(c, sc.Tx, a, sc.Operation.DecisionAt())
	if err != nil {
		return err
	}
	forces := []int64{}
	for key := range rows {
		id, err := strconv.ParseInt(key, 10, 64)
		if err != nil || id <= 0 {
			return d.ErrUnavailable
		}
		force, err := s.force(c, sc, a, character.HeroRef{PlayerID: a.PlayerID, PartnerID: id}, v.revision)
		if err != nil {
			return err
		}
		forces = append(forces, force)
	}
	for i := range candidates {
		e := &candidates[i]
		if e.Robot != 0 {
			continue
		}
		e.Force = 0
		for _, row := range e.Heroes {
			force, err := s.force(c, sc, a, character.HeroRef{PlayerID: identity.PlayerID(e.Player), PartnerID: number(row["source_partner_id"])}, v.revision)
			if err != nil {
				return err
			}
			e.Force += force
		}
	}
	sort.Slice(forces, func(i, j int) bool { return forces[i] > forces[j] })
	power := int64(0)
	for i, f := range forces {
		if i >= 5 {
			break
		}
		power += f
	}
	rng := cd.NewStream(sc.Operation.Operation().Derive("march.match/v1", 0))
	enemies := make([]d.Enemy, 0, d.Stages)
	for stage, factor := range v.catalog.Factors("expedition_rival_param") {
		target := float64(power) * factor
		// Prefer real defenses; a sparse cohort falls back to source robots whose
		// level is known but whose live canonical owner force does not exist.
		distance := func(e d.Enemy) float64 {
			if e.Robot == 0 {
				return math.Abs(float64(e.Force) - target)
			}
			return 1e15 + math.Abs(float64(e.Level)-float64(v.level)*factor)
		}
		sorted := append([]d.Enemy{}, candidates...)
		sort.SliceStable(sorted, func(i, j int) bool { return distance(sorted[i]) < distance(sorted[j]) })
		ties := 1
		for ties < len(sorted) && distance(sorted[ties]) == distance(sorted[0]) {
			ties++
		}
		picked := sorted[rng.Uniform(uint64(ties))]
		raw, err := json.Marshal(picked)
		if err != nil {
			return err
		}
		var enemy d.Enemy
		decoder := json.NewDecoder(bytes.NewReader(raw))
		decoder.UseNumber()
		if err = decoder.Decode(&enemy); err != nil {
			return err
		}
		for _, hero := range enemy.Heroes {
			hero["mp"] = v.catalog.Factors("expedition_init_mana")[stage]
		}
		if err = s.scaleEnemy(c, sc, a, v, &enemy, target); err != nil {
			return fmt.Errorf("scale stage %d: %w", stage+1, err)
		}
		enemies = append(enemies, enemy)
	}
	recommendation := r.Recommend
	if len(recommendation) == 0 || r.RecommendDay < v.day {
		recommendation = []int64{}
		for _, pool := range v.catalog.Recommendations {
			recommendation = append(recommendation, pool[rng.Uniform(uint64(len(pool)))])
		}
	}
	lifetime, version := r.LifetimeChests, r.Version
	*r = d.Run{Revision: v.revision, Occurrence: sc.Operation.Operation().ID.String(), ResetDay: v.day, ResetUsed: reset, DrinkDay: v.day, RecommendDay: v.day, Recommend: recommendation, Enemies: enemies, Heroes: map[string]d.Status{}, Rewards: map[string][]any{}, LifetimeChests: lifetime, Version: version + 1}
	return nil
}
