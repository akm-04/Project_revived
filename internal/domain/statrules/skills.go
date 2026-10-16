package statrules

import (
	"strconv"
	"strings"
)

// EffectiveSkill is selected by the canonical skill owner, after color, awake,
// special-instance choices and SKILL_EXTRA reconciliation. It is not raw wire.
type EffectiveSkill struct {
	Slot  int
	ID    int64
	Level float64
}

// SkillNumbers computes source flat BUFF_SELF and independent skill force.
// Awake/twice flags are materialized Character facts; this helper cannot produce them.
func (e *Engine) SkillNumbers(model string, templateID int64, skills []EffectiveSkill, awake, twice bool) ([49]float64, float64, error) {
	var attrs [49]float64
	if e == nil {
		return attrs, 0, ErrUnqualified
	}
	t, ok := e.templates[templateID]
	if !ok || t.Model != model {
		return attrs, 0, ErrUnqualified
	}
	force := t.InitPower
	if model == "Pet" {
		force = 0
	}
	seen := map[int]bool{}
	levels := map[int64]float64{}
	rows := map[int64]map[string]string{}
	for _, r := range e.catalog.Skills {
		id, _ := strconv.ParseInt(r["id"], 10, 64)
		rows[id] = r
	}
	for _, s := range skills {
		limit := 6
		if model == "Pet" {
			limit = 5
		}
		if s.Slot < 1 || s.Slot > limit || seen[s.Slot] || s.ID < 0 || s.Level < 0 || !finite(s.Level) {
			return attrs, 0, ErrUnqualified
		}
		seen[s.Slot] = true
		if s.ID == 0 || s.Level == 0 {
			continue
		}
		_, ok := rows[s.ID]
		if !ok {
			return attrs, 0, ErrUnqualified
		}
		levels[s.ID] = s.Level
		if model != "Pet" {
			if s.Slot == 5 && !awake || s.Slot == 6 && !twice {
				delete(levels, s.ID)
				continue
			}
			if len(t.SlotSkills) != 6 || t.SlotSkills[s.Slot-1] <= 0 {
				continue
			}
			rate := 4.0
			if s.Slot >= 5 {
				rate = 4.5
			}
			force += rate * s.Level
		} else {
			read := func(v string) (float64, error) {
				if v == "" {
					return 0, nil
				}
				return strconv.ParseFloat(v, 64)
			}
			ini, er := read(rows[t.SlotSkills[s.Slot-1]]["init_power"])
			step, er2 := read(rows[t.SlotSkills[s.Slot-1]]["step_power"])
			if er != nil || er2 != nil {
				return attrs, 0, ErrUnqualified
			}
			force += ini + step*s.Level
		}
	}
	for _, id := range t.BuffSkill {
		lev := levels[id]
		if lev <= 0 {
			continue
		}
		r, ok := rows[id]
		if !ok {
			return attrs, 0, ErrUnqualified
		}
		if r["skill_type"] != "5" {
			continue
		}
		for _, s := range strings.Split(r["buffs"], "|") {
			if s == "" {
				continue
			}
			bid, er := strconv.ParseInt(s, 10, 64)
			if er != nil {
				return attrs, 0, ErrUnqualified
			}
			a, v, er := e.FlatBuff(bid, lev)
			if er != nil {
				return attrs, 0, er
			}
			if a > 0 {
				attrs[a-1] += v
				if !finite(attrs[a-1]) {
					return attrs, 0, ErrUnqualified
				}
			}
		}
	}
	if !finite(force) {
		return attrs, 0, ErrUnqualified
	}
	return attrs, force, nil
}
