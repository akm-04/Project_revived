package march

import (
	"context"
	"math"
	"sort"
	"strconv"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	scaleLevel = iota
	scaleColor
	scaleStar
)

// scaledHero is one copied opponent row plus its owner reference and the scale
// currently chosen for it. Rows stay copies; the stored defense is never read
// for writing and the owner's heroes are never changed.
type scaledHero struct {
	row   map[string]any
	ref   character.HeroRef
	level int64
	star  int64
	color int64
}

// scaleEnemy brings a copied opponent snapshot within the stage's force
// tolerance by stepping level first, then colour, then star down to the source
// table floors. It never scales up and never leaves the stored force behind.
func (s Mode) scaleEnemy(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, enemy *d.Enemy, target float64) error {
	if enemy.Robot != 0 || enemy.Player <= 0 || target <= 0 {
		return nil
	}
	policy := v.catalog.Policy
	limit := target * (1 + float64(policy.RivalForceTolerance)/10000)
	if float64(enemy.Force) <= limit {
		return nil
	}
	heroes, err := s.scaledHeroes(enemy)
	if err != nil {
		return err
	}
	if len(heroes) == 0 {
		return nil
	}
	for _, field := range []int{scaleLevel, scaleColor, scaleStar} {
		floor := scaleFloor(policy, field)
		if err = s.fitScale(c, sc, a, v, heroes, field, floor, limit); err != nil {
			return err
		}
	}
	total := int64(0)
	for i := range heroes {
		h := &heroes[i]
		force, err := s.scaledForce(c, sc, a, v.revision, h.ref, h.level, h.star, h.color)
		if err != nil {
			return err
		}
		h.row["lev"], h.row["star"], h.row["color"], h.row["force"] = h.level, h.star, h.color, force
		total += force
	}
	enemy.Force = total
	return nil
}

func (s Mode) scaledHeroes(enemy *d.Enemy) ([]scaledHero, error) {
	keys := make([]int64, 0, len(enemy.Heroes))
	for key := range enemy.Heroes {
		id, err := strconv.ParseInt(key, 10, 64)
		if err != nil || id <= 0 {
			return nil, d.ErrUnavailable
		}
		keys = append(keys, id)
	}
	sort.Slice(keys, func(i, j int) bool { return keys[i] < keys[j] })
	heroes := make([]scaledHero, 0, len(keys))
	for _, key := range keys {
		row := enemy.Heroes[strconv.FormatInt(key, 10)]
		partner := number(row["source_partner_id"])
		if partner <= 0 {
			return nil, d.ErrUnavailable
		}
		heroes = append(heroes, scaledHero{
			row:   row,
			ref:   character.HeroRef{PlayerID: identity.PlayerID(enemy.Player), PartnerID: partner},
			level: number(row["lev"]),
			star:  number(row["star"]),
			color: number(row["color"]),
		})
	}
	return heroes, nil
}

// fitScale binary-searches the largest common value at or below every hero's
// current value that keeps the copied team's canonical force within limit.
func (s Mode) fitScale(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, heroes []scaledHero, field int, floor int64, limit float64) error {
	high := scaleValue(heroes, field)
	if high <= floor {
		applyScale(heroes, field, high)
		return nil
	}
	low, best := floor, floor
	for low <= high {
		middle := (low + high) / 2
		force, err := s.scaledTeamForce(c, sc, a, v, heroes, field, middle)
		if err != nil {
			return err
		}
		if float64(force) <= limit {
			best = middle
			low = middle + 1
			continue
		}
		high = middle - 1
	}
	applyScale(heroes, field, best)
	return nil
}

func applyScale(heroes []scaledHero, field int, value int64) {
	for i := range heroes {
		switch field {
		case scaleLevel:
			heroes[i].level = value
		case scaleColor:
			heroes[i].color = value
		case scaleStar:
			heroes[i].star = value
		}
	}
}

func (s Mode) scaledTeamForce(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, heroes []scaledHero, field int, value int64) (int64, error) {
	total := int64(0)
	for i := range heroes {
		h := &heroes[i]
		level, star, color := h.level, h.star, h.color
		switch field {
		case scaleLevel:
			level = value
		case scaleColor:
			color = value
		case scaleStar:
			star = value
		}
		force, err := s.scaledForce(c, sc, a, v.revision, h.ref, level, star, color)
		if err != nil {
			return 0, err
		}
		total += force
	}
	return total, nil
}

func (s Mode) scaledForce(c context.Context, sc gen.TimedScope, a identity.ActorContext, revision string, ref character.HeroRef, level, star, color int64) (int64, error) {
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, sc.Operation.DecisionAt())
	if err != nil {
		return 0, err
	}
	kind := publicstats.Self
	if ref.PlayerID != a.PlayerID {
		kind = publicstats.Foreign
	}
	result, err := s.Stats.ScaledHeroTx(c, scope, ref, publicstats.View{Kind: kind, Viewer: a.PlayerID}, level, star, color)
	if err != nil {
		return 0, err
	}
	value := math.Round(result.Stats.Force)
	if math.IsNaN(value) || math.IsInf(value, 0) || value < 0 || value > 100000000000 {
		return 0, d.ErrUnavailable
	}
	return int64(value), nil
}

func scaleValue(heroes []scaledHero, field int) int64 {
	value := int64(math.MaxInt64)
	for i := range heroes {
		current := heroes[i].star
		if field == scaleLevel {
			current = heroes[i].level
		}
		if field == scaleColor {
			current = heroes[i].color
		}
		if current < value {
			value = current
		}
	}
	return value
}

func scaleFloor(policy d.Policy, field int) int64 {
	switch field {
	case scaleLevel:
		return policy.RivalScaleMinLevel
	case scaleColor:
		return policy.RivalScaleMinColor
	default:
		return policy.RivalScaleMinStar
	}
}
