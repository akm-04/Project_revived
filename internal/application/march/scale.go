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
	row         map[string]any
	evaluate    func(level, star, color int64) (publicstats.Result, error)
	levels      d.HeroColorLevels
	levelsKnown bool
	level       int64
	star        int64
	color       int64
}

// frozenTeam caches one owner read per opponent hero for the whole candidate
// generation; every stage and every binary-search probe reuses it.
type frozenTeam map[character.HeroRef]*publicstats.FrozenHero

// frozenOwner reads one owner's canonical inputs once per opponent hero and
// reuses them for the candidate force and every scaling probe.
func (s Mode) frozenOwner(c context.Context, sc gen.TimedScope, a identity.ActorContext, ref character.HeroRef, revision string, frozen frozenTeam) (*publicstats.FrozenHero, error) {
	if owner, ok := frozen[ref]; ok {
		return owner, nil
	}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, sc.Operation.DecisionAt())
	if err != nil {
		return nil, err
	}
	kind := publicstats.Self
	if ref.PlayerID != a.PlayerID {
		kind = publicstats.Foreign
	}
	owner, err := s.Stats.FreezeHeroTx(c, scope, ref, publicstats.View{Kind: kind, Viewer: a.PlayerID})
	if err != nil {
		return nil, err
	}
	frozen[ref] = owner
	return owner, nil
}

// scaleEnemy brings a copied opponent snapshot within the stage's force
// tolerance by stepping level first, then colour, then star down to the source
// table floors. It never scales up and never leaves the stored force behind.
func (s Mode) scaleEnemy(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, enemy *d.Enemy, target float64, frozen frozenTeam) error {
	if enemy.Robot != 0 || enemy.Player <= 0 || target <= 0 {
		return nil
	}
	policy := v.catalog.Policy
	limit := target * (1 + float64(policy.RivalForceTolerance)/10000)
	if float64(enemy.Force) <= limit {
		return nil
	}
	heroes, err := s.scaledHeroes(c, sc, a, v, enemy, frozen)
	if err != nil {
		return err
	}
	if len(heroes) == 0 {
		return nil
	}
	if err = s.fitCoherentTeam(heroes, policy, limit); err != nil {
		return err
	}
	total := int64(0)
	for i := range heroes {
		h := &heroes[i]
		result, err := h.evaluate(h.level, h.star, h.color)
		if err != nil {
			return err
		}
		force := math.Round(result.Stats.Force)
		if math.IsNaN(force) || math.IsInf(force, 0) || force < 0 || force > 100000000000 {
			return d.ErrUnavailable
		}
		h.row["lev"], h.row["star"], h.row["color"], h.row["force"] = h.level, h.star, h.color, int64(force)
		total += int64(force)
	}
	enemy.Force = total
	return nil
}

func (s Mode) scaledHeroes(c context.Context, sc gen.TimedScope, a identity.ActorContext, v view, enemy *d.Enemy, frozen frozenTeam) ([]scaledHero, error) {
	levels, err := s.heroColorLevels(c, sc.Tx, v)
	if err != nil {
		return nil, err
	}
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
		tableID := number(row["table_id"])
		if tableID <= 0 {
			return nil, d.ErrUnavailable
		}
		color := number(row["color"])
		if color < 1 || color > 16 {
			return nil, d.ErrUnavailable
		}
		heroLevels, known := levels[tableID]
		if color > 1 && !known {
			return nil, d.ErrUnavailable
		}
		ref := character.HeroRef{PlayerID: identity.PlayerID(enemy.Player), PartnerID: partner}
		owner, err := s.frozenOwner(c, sc, a, ref, v.revision, frozen)
		if err != nil {
			return nil, err
		}
		heroes = append(heroes, scaledHero{
			row:         row,
			evaluate:    owner.Evaluate,
			levels:      heroLevels,
			levelsKnown: known,
			level:       number(row["lev"]),
			star:        number(row["star"]),
			color:       color,
		})
	}
	return heroes, nil
}

// fitCoherentTeam fits the copied team to the stage limit and then clamps its
// colours to combinations a real girl can hold. The colour clamp runs after the
// level step and again after the star step; it only lowers force.
func (s Mode) fitCoherentTeam(heroes []scaledHero, policy d.Policy, limit float64) error {
	for _, field := range []int{scaleLevel, scaleColor, scaleStar} {
		if err := s.fitScale(heroes, field, scaleFloor(policy, field), limit); err != nil {
			return err
		}
		if field == scaleLevel {
			if err := clampCoherentColors(heroes, policy.RivalScaleMinColor); err != nil {
				return err
			}
		}
	}
	return clampCoherentColors(heroes, policy.RivalScaleMinColor)
}

func clampCoherentColors(heroes []scaledHero, floor int64) error {
	for i := range heroes {
		h := &heroes[i]
		if h.color <= 1 {
			continue
		}
		if !h.levelsKnown {
			return d.ErrUnavailable
		}
		color, err := d.CoherentColor(h.levels, h.level, h.color, floor)
		if err != nil {
			return err
		}
		h.color = color
	}
	return nil
}

func (s Mode) heroColorLevels(c context.Context, q tx.Queryer, v view) (map[int64]d.HeroColorLevels, error) {
	if v.colorLevels == nil {
		return nil, d.ErrUnavailable
	}
	if v.colorLevels.loaded {
		return v.colorLevels.levels, nil
	}
	levels, err := s.Content.HeroColorLevelsTx(c, q, v.revision)
	if err != nil {
		return nil, err
	}
	v.colorLevels.loaded, v.colorLevels.levels = true, levels
	return levels, nil
}

// fitScale binary-searches the largest common value at or below every hero's
// current value that keeps the copied team's canonical force within limit.
func (s Mode) fitScale(heroes []scaledHero, field int, floor int64, limit float64) error {
	high := scaleValue(heroes, field)
	if high <= floor {
		applyScale(heroes, field, high)
		return nil
	}
	low, best := floor, floor
	for low <= high {
		middle := (low + high) / 2
		force, err := scaledTeamForce(heroes, field, middle)
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

func scaledTeamForce(heroes []scaledHero, field int, value int64) (int64, error) {
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
		result, err := h.evaluate(level, star, color)
		if err != nil {
			return 0, err
		}
		force := math.Round(result.Stats.Force)
		if math.IsNaN(force) || math.IsInf(force, 0) || force < 0 || force > 100000000000 {
			return 0, d.ErrUnavailable
		}
		total += int64(force)
	}
	return total, nil
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
