// Package statinputs materializes source numeric leaves. Owner qualification is
// the application composer's responsibility; these functions grant no authority.
package statinputs

import (
	"encoding/json"
	"errors"
	rules "gxb.local/backend/v2/internal/domain/statrules"
	"math"
	"strconv"
	"strings"
)

const PolicyID = "C3B_SRC64_NUMERIC_INPUT_V1"

var ErrUnqualified = errors.New("stat inputs: unavailable or incoherent input")

type Vector [49]float64

func Number(s string) (float64, error) {
	if s == "" {
		return 0, nil
	}
	v, e := strconv.ParseFloat(s, 64)
	if e != nil || !Finite(v) {
		return 0, ErrUnqualified
	}
	return v, nil
}
func Finite(v float64) bool {
	return !math.IsNaN(v) && !math.IsInf(v, 0) && math.Abs(v) <= 9007199254740991
}
func Int(s string) (int64, error) {
	if s == "" {
		return 0, nil
	}
	v, e := strconv.ParseInt(s, 10, 64)
	if e != nil {
		return 0, ErrUnqualified
	}
	return v, nil
}
func Numbers(s string) ([]float64, error) {
	if s == "" {
		return nil, nil
	}
	out := []float64{}
	for _, s := range strings.Split(s, "|") {
		v, e := Number(s)
		if e != nil {
			return nil, e
		}
		out = append(out, v)
	}
	return out, nil
}
func Attrs(ids, values string) (Vector, error) {
	var out Vector
	a, e := Numbers(ids)
	b, e2 := Numbers(values)
	if e != nil || e2 != nil || len(a) != len(b) {
		return out, ErrUnqualified
	}
	for i, id := range a {
		if id < 1 || id > 49 || id != math.Trunc(id) {
			return Vector{}, ErrUnqualified
		}
		out[int(id)-1] = b[i]
	}
	return out, nil
}
func (v *Vector) Add(o Vector) error {
	for i, x := range o {
		v[i] += x
		if !Finite(v[i]) {
			return ErrUnqualified
		}
	}
	return nil
}
func (v Vector) Map() map[int]float64 {
	m := map[int]float64{}
	for i, x := range v {
		m[i+1] = x
	}
	return m
}

type Catalog struct {
	tables map[string]map[int64]map[string]string
}

func NewCatalog(schema int, policy string, tables map[string][]map[string]string) (Catalog, error) {
	c := Catalog{tables: map[string]map[int64]map[string]string{}}
	if schema != 1 || policy != PolicyID || len(tables) != 6 {
		return c, ErrUnqualified
	}
	for _, n := range []string{"item", "partner", "super_partner", "pet", "skill", "enhance"} {
		rs := tables[n]
		if len(rs) == 0 {
			return c, ErrUnqualified
		}
		c.tables[n] = map[int64]map[string]string{}
		for _, r := range rs {
			id, e := Int(r["id"])
			if e != nil || id <= 0 || c.tables[n][id] != nil {
				return c, ErrUnqualified
			}
			q := map[string]string{}
			for k, v := range r {
				q[k] = v
			}
			c.tables[n][id] = q
		}
	}
	return c, nil
}
func (c Catalog) Row(table string, id int64) (map[string]string, error) {
	r, ok := c.tables[table][id]
	if !ok {
		return nil, ErrUnqualified
	}
	out := map[string]string{}
	for k, v := range r {
		out[k] = v
	}
	return out, nil
}
func table(model string) string {
	switch model {
	case "NormalHero":
		return "partner"
	case "SuperHero":
		return "super_partner"
	case "Pet":
		return "pet"
	}
	return ""
}
func (c Catalog) Awake(model string, id int64) (bool, error) {
	r, e := c.Row(table(model), id)
	if e != nil {
		return false, e
	}
	v, e := Int(r["first_table_id"])
	return v > 0, e
}
func (c Catalog) Item(id int64) (Vector, error) {
	r, e := c.Row("item", id)
	if e != nil {
		return Vector{}, e
	}
	return Attrs(r["attr_ids"], r["attr_values"])
}
func (c Catalog) Enhance(level int64) (float64, error) {
	if level < 0 || level > 1000 {
		return 0, ErrUnqualified
	}
	if level == 0 {
		return 1, nil
	}
	v := 2.0
	for i := int64(1); i <= level; i++ {
		r, e := c.Row("enhance", (i+9)/10)
		if e != nil {
			return 0, e
		}
		n, e := Number(r["attr_incr_ratio"])
		if e != nil {
			return 0, e
		}
		v += n
	}
	return v, nil
}

type Slot struct{ ID, RawFumo, Enhancement int64 }

var colors = []string{"white", "green", "green1", "blue", "blue1", "blue2", "purple", "purple1", "purple2", "purple3", "purple4", "orange", "orange1", "orange2", "red", "red1"}

// Equipment uses qualified current slots. Historical color contributions are
// content-derived from canonical promotion color, never inferred equipped rows.
func (c Catalog) Equipment(model string, id int64, color int, slots []Slot) (equip, promotion, fumo Vector, err error) {
	r, e := c.Row(table(model), id)
	if e != nil || color < 1 || color > len(colors) {
		return equip, promotion, fumo, ErrUnqualified
	}
	for _, s := range slots {
		if s.ID == 0 {
			if s.RawFumo != 0 || s.Enhancement != 0 {
				return equip, promotion, fumo, ErrUnqualified
			}
			continue
		}
		v, e := c.Item(s.ID)
		if e != nil {
			return equip, promotion, fumo, e
		}
		rate := 1.0
		if model == "SuperHero" {
			rate, e = c.Enhance(s.Enhancement)
			if e != nil {
				return equip, promotion, fumo, e
			}
		} else if s.Enhancement != 0 {
			return equip, promotion, fumo, ErrUnqualified
		}
		for i := range v {
			v[i] *= rate
		}
		if e = equip.Add(v); e != nil {
			return equip, promotion, fumo, e
		}
		if model != "SuperHero" {
			v, e = c.Fumo(s.ID, s.RawFumo)
			if e != nil {
				return equip, promotion, fumo, e
			}
			if e = fumo.Add(v); e != nil {
				return equip, promotion, fumo, e
			}
		}
	}
	for col := 1; col < color; col++ {
		key := colors[col-1]
		if model == "SuperHero" {
			key = "equipment"
			if col != 1 {
				continue
			}
		}
		ids, e := Numbers(r[key])
		if e != nil {
			return equip, promotion, fumo, e
		}
		for _, f := range ids {
			if f == 0 {
				continue
			}
			if f != math.Trunc(f) {
				return equip, promotion, fumo, ErrUnqualified
			}
			it, e := c.Row("item", int64(f))
			if e != nil {
				return equip, promotion, fumo, e
			}
			if model != "Pet" && it["is_awaken_item"] == "1" {
				continue
			}
			v, e := c.Item(int64(f))
			if e != nil {
				return equip, promotion, fumo, e
			}
			if e = promotion.Add(v); e != nil {
				return equip, promotion, fumo, e
			}
		}
	}
	return
}
func (c Catalog) Fumo(id, raw int64) (Vector, error) {
	var out Vector
	if raw < 0 {
		return out, ErrUnqualified
	}
	if raw == 0 {
		return out, nil
	}
	r, e := c.Row("item", id)
	if e != nil {
		return out, e
	}
	thresholds, e := Numbers(r["fumo"])
	if e != nil || len(thresholds) == 0 {
		return out, ErrUnqualified
	}
	remaining := float64(raw)
	for i, n := range thresholds {
		if n <= 0 {
			return out, ErrUnqualified
		}
		remaining -= n
		if remaining < 0 {
			return out, nil
		}
		v, e := Attrs(r["attr_ids"], r["fumo_value"+strconv.Itoa(i+1)])
		if e != nil {
			return out, e
		}
		if e = out.Add(v); e != nil {
			return out, e
		}
	}
	if remaining > 0 {
		return out, ErrUnqualified
	}
	return out, nil
}

// Materializer keeps detached copies of both immutable catalogs.
type Materializer struct {
	Inputs    Catalog
	Rules     rules.Catalog
	Engine    *rules.Engine
	templates map[int64]rules.Template
	skills    map[int64]map[string]string
	weights   [49]float64
}

func New(rev string, c Catalog, r rules.Catalog) (*Materializer, error) {
	e, err := rules.NewEngine(rev, r)
	if err != nil {
		return nil, err
	}
	raw, err := json.Marshal(r)
	if err != nil {
		return nil, err
	}
	var own rules.Catalog
	if err = json.Unmarshal(raw, &own); err != nil {
		return nil, err
	}
	m := &Materializer{Inputs: c, Rules: own, Engine: e, templates: map[int64]rules.Template{}, skills: map[int64]map[string]string{}}
	for _, t := range own.Templates {
		m.templates[t.ID] = t
	}
	for _, r := range own.Skills {
		id, _ := Int(r["id"])
		m.skills[id] = r
	}
	for _, r := range own.Attributes {
		id, _ := Int(r["id"])
		v, err := Number(r["power_param"])
		if err != nil || id < 1 || id > 49 {
			return nil, ErrUnqualified
		}
		m.weights[id-1] = v
	}
	return m, nil
}
func (m *Materializer) Weighted(v Vector) (float64, error) {
	n := 0.0
	for i, x := range v {
		n += x * m.weights[i]
		if !Finite(n) {
			return 0, ErrUnqualified
		}
	}
	return n, nil
}
func (m *Materializer) BaseGrowth(id int64, star, level int) (Vector, error) {
	var v Vector
	t, ok := m.templates[id]
	if !ok || star < 1 || star > len(t.Growth) || level < 1 {
		return v, ErrUnqualified
	}
	for i, n := range t.Growth[star-1] {
		v[i] = n * float64(level)
	}
	return v, nil
}

type SkillState struct {
	Model               string
	TemplateID          int64
	Level, Star, Color  int
	Raw                 [6]int64
	IDs                 [6]int64
	Twice               bool
	BookshelfCap, Extra float64
}

// Skill paths deliberately differ: raw+offset force and capped+extra BUFF_SELF.
func (m *Materializer) SkillNumbers(s SkillState) (Vector, float64, error) {
	var out Vector
	t, ok := m.templates[s.TemplateID]
	if !ok || t.Model != s.Model || s.Level < 1 || s.Color < 1 || s.Star < 1 || !Finite(s.Extra) || !Finite(s.BookshelfCap) {
		return out, 0, ErrUnqualified
	}
	awake, e := m.Inputs.Awake(s.Model, s.TemplateID)
	if e != nil {
		return out, 0, e
	}
	limit := 6
	if s.Model == "Pet" {
		limit = 5
	}
	offsets := [6]int64{0, 0, 20, 40, 60, 60}
	gates := [6]int{1, 2, 4, 7, 1, 1}
	levels := [6]float64{}
	enabled := [6]bool{}
	force := t.InitPower
	if s.Model == "Pet" {
		force = 0
	}
	for i := 0; i < limit; i++ {
		if s.IDs[i] > 0 {
			if _, ok := m.skills[s.IDs[i]]; !ok {
				return out, 0, ErrUnqualified
			}
		}
		if s.Raw[i] < 0 || s.IDs[i] < 0 {
			return out, 0, ErrUnqualified
		}
		enabled[i] = (s.Model == "SuperHero" || s.Color >= gates[i]) && (i != 4 || awake) && (i != 5 || s.Twice)
		if !enabled[i] {
			continue
		}
		levels[i] = float64(s.Raw[i]) + float64(offsets[i])
		if !Finite(levels[i]) {
			return out, 0, ErrUnqualified
		}
		if t.SlotSkills[i] <= 0 || levels[i] <= 0 {
			continue
		}
		if s.Model == "Pet" {
			row, ok := m.skills[t.SlotSkills[i]]
			if !ok {
				return out, 0, ErrUnqualified
			}
			a, e := Number(row["init_power"])
			b, e2 := Number(row["step_power"])
			if e != nil || e2 != nil {
				return out, 0, ErrUnqualified
			}
			force += a + levels[i]*b
		} else {
			rate := 4.0
			if i >= 4 {
				rate = 4.5
			}
			force += levels[i] * rate
		}
	}
	row, e := m.Inputs.Row(table(s.Model), s.TemplateID)
	if e != nil {
		return out, 0, e
	}
	basic, e := Int(row["skill0"])
	if e != nil {
		return out, 0, e
	}
	for _, id := range t.BuffSkill {
		if id == 0 {
			continue
		}
		r, ok := m.skills[id]
		if !ok {
			return out, 0, ErrUnqualified
		}
		if r["skill_type"] != "5" {
			continue
		}
		lev := 0.0
		slot := -1
		gated := false
		if id == basic {
			lev = float64(s.Level)
		} else {
			for i := 0; i < limit; i++ {
				if s.IDs[i] == id {
					slot = i
					if !enabled[i] {
						gated = true
					} else {
						lev = levels[i]
					}
					break
				}
			}
		}
		if gated {
			continue
		}
		cap := float64(s.Level) + s.BookshelfCap
		if s.Model == "Pet" {
			cap = float64(s.Level)
			if slot >= 0 && slot+1 <= s.Star-1 {
				pr, e := m.Inputs.Row("skill", id)
				if e != nil {
					return out, 0, e
				}
				if pr["pet_star_type"] == "2" {
					nums, e := Numbers(pr["desc4_num_step"])
					if e != nil {
						return out, 0, e
					}
					if len(nums) > 1 && nums[1] > 0 {
						cap += nums[1]
					}
				}
			}
		}
		lev = math.Min(lev, cap)
		if s.Model != "Pet" {
			lev += s.Extra
		}
		if lev <= 0 {
			continue
		}
		for _, bid := range strings.Split(r["buffs"], "|") {
			if bid == "" {
				continue
			}
			b, e := Int(bid)
			if e != nil {
				return out, 0, e
			}
			a, v, e := m.Engine.FlatBuff(b, lev)
			if e != nil {
				return out, 0, e
			}
			if a > 0 {
				out[a-1] += v
				if !Finite(out[a-1]) {
					return out, 0, ErrUnqualified
				}
			}
		}
	}
	if !Finite(force) {
		return out, 0, ErrUnqualified
	}
	return out, force, nil
}
