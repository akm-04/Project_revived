// Package statrules evaluates the explicitly scoped current-client numerical rules.
// It does not qualify owner observations, public projections, or combat inputs.
package statrules

import (
	"encoding/json"
	"errors"
	"math"
	"strconv"
	"strings"
)

const PolicyID = "C3A_SRC64_MATERIALIZED_STAT_V1"

var ErrUnqualified = errors.New("stat rules: unavailable or invalid materialized input")

type Expr struct {
	Op    string  `json:"op"`
	Value float64 `json:"value,omitempty"`
	Name  string  `json:"name,omitempty"`
	Args  []Expr  `json:"args,omitempty"`
}
type ModelRules struct {
	Rules           map[string][]Expr `json:"rules"`
	Force           map[string]Expr   `json:"force"`
	BasicForceLimit int               `json:"basic_force_limit"`
}
type Template struct {
	Model      string      `json:"model"`
	ID         int64       `json:"id"`
	HeroType   int         `json:"hero_type"`
	Initial    []float64   `json:"initial"`
	Growth     [][]float64 `json:"growth"`
	InitPower  float64     `json:"init_power"`
	SlotSkills []int64     `json:"slot_skills"`
	BuffSkill  []int64     `json:"buff_skill"`
}
type Catalog struct {
	SchemaVersion int                   `json:"schema_version"`
	PolicyID      string                `json:"policy_id"`
	Models        map[string]ModelRules `json:"models"`
	Constants     map[string]float64    `json:"constants"`
	Templates     []Template            `json:"templates"`
	Attributes    []map[string]string   `json:"attributes"`
	Skills        []map[string]string   `json:"skills"`
	Buffs         []map[string]string   `json:"buffs"`
	AdapterScope  string                `json:"adapter_scope"`
}

func finite(v float64) bool {
	return !math.IsNaN(v) && !math.IsInf(v, 0) && math.Abs(v) <= 9007199254740991
}
func exprOK(e Expr, depth int) bool {
	if depth > 128 || !finite(e.Value) {
		return false
	}
	n := len(e.Args)
	switch e.Op {
	case "number":
		return n == 0 && e.Name == ""
	case "add", "sub", "mul", "div":
		if n != 2 {
			return false
		}
	case "call":
		if e.Name == "" || n > 1 || ((e.Name == "floor" || e.Name == "ceil") && n != 1) {
			return false
		}
	default:
		return false
	}
	for _, a := range e.Args {
		if !exprOK(a, depth+1) {
			return false
		}
	}
	return true
}
func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != PolicyID || c.AdapterScope != "STAT_ONLY_NO_ORIGINAL_SERVER_OR_COMBAT_PARITY" || len(c.Models) != 3 || len(c.Templates) != 623 || len(c.Attributes) != 49 {
		return ErrUnqualified
	}
	seen := map[int64]bool{}
	for _, t := range c.Templates {
		if seen[t.ID] || t.ID <= 0 || len(t.Initial) != 49 || len(t.Growth) < 5 || (t.Model != "Pet" && (t.HeroType < 1 || t.HeroType > 3)) || (t.Model == "Pet" && t.HeroType != 0) {
			return ErrUnqualified
		}
		seen[t.ID] = true
		if _, ok := c.Models[t.Model]; !ok {
			return ErrUnqualified
		}
		for _, v := range t.Initial {
			if !finite(v) {
				return ErrUnqualified
			}
		}
		for _, row := range t.Growth {
			if len(row) != 3 {
				return ErrUnqualified
			}
			for _, v := range row {
				if !finite(v) {
					return ErrUnqualified
				}
			}
		}
	}
	for _, name := range []string{"NormalHero", "SuperHero", "Pet"} {
		m, ok := c.Models[name]
		if !ok || len(m.Rules["getTotalAttr"]) != 49 || len(m.Rules["getZhandouli"]) != 49 {
			return ErrUnqualified
		}
		for _, xs := range m.Rules {
			if len(xs) != 49 {
				return ErrUnqualified
			}
			for _, e := range xs {
				if !exprOK(e, 0) {
					return ErrUnqualified
				}
			}
		}
		for _, e := range m.Force {
			if !exprOK(e, 0) {
				return ErrUnqualified
			}
		}
		limit := 49
		if name == "Pet" {
			limit = 22
		}
		if m.BasicForceLimit != limit {
			return ErrUnqualified
		}
	}
	return nil
}

// Engine retains a private copy; changing a decoded catalog cannot change an engine.
type Engine struct {
	catalog   Catalog
	revision  string
	templates map[int64]Template
	scores    [49]float64
	leaves    map[string]bool
}

func NewEngine(revision string, c Catalog) (*Engine, error) {
	if !hash(revision) || c.Validate() != nil {
		return nil, ErrUnqualified
	}
	b, err := json.Marshal(c)
	if err != nil {
		return nil, err
	}
	var own Catalog
	if json.Unmarshal(b, &own) != nil {
		return nil, ErrUnqualified
	}
	e := &Engine{catalog: own, revision: revision, templates: map[int64]Template{}}
	for _, t := range own.Templates {
		e.templates[t.ID] = t
	}
	seen := map[int]bool{}
	for _, r := range own.Attributes {
		id, er := strconv.Atoi(r["id"])
		rawScore := r["power_param"]
		if rawScore == "" {
			rawScore = "0"
		}
		v, err := strconv.ParseFloat(rawScore, 64)
		if er != nil || err != nil || id < 1 || id > 49 || seen[id] || !finite(v) {
			return nil, ErrUnqualified
		}
		seen[id] = true
		e.scores[id-1] = v
	}
	e.leaves = map[string]bool{}
	for name, m := range own.Models {
		var walk func(Expr)
		walk = func(v Expr) {
			if v.Op == "call" {
				_, rule := m.Rules[v.Name]
				_, force := m.Force[v.Name]
				special := map[string]bool{"getColor": true, "getHeroType": true, "getInitialAttr": true, "attrScore": true, "getBaseGrowth": true, "getGrowAttr": true, "getBasicForce": true, "ceil": true, "floor": true}
				if !rule && !force && !special[v.Name] {
					e.leaves[name+"/"+v.Name] = true
				}
			}
			for _, a := range v.Args {
				walk(a)
			}
		}
		for _, xs := range m.Rules {
			for _, x := range xs {
				walk(x)
			}
		}
		for _, x := range m.Force {
			walk(x)
		}
		if name != "Pet" {
			for _, key := range []string{"getFavorAttrGrowth", "getHouseAttrGrowthByType", "getBookShelfAttr"} {
				e.leaves[name+"/"+key] = true
			}
		} else {
			e.leaves[name+"/getEquipFumoAttr"] = true
		}
	}
	return e, nil
}
func hash(s string) bool {
	if len(s) != 64 {
		return false
	}
	for _, r := range s {
		if !strings.ContainsRune("0123456789abcdef", r) {
			return false
		}
	}
	return true
}

// FlatBuff reproduces model BUFF_SELF's flat contribution after its canonical
// skill owner has selected the effective skill/buff and level. Percent init is
// deliberately excluded by those source methods. No battle Buff behavior is run.
func (e *Engine) FlatBuff(id int64, level float64) (int, float64, error) {
	if e == nil || id <= 0 || level <= 0 || !finite(level) {
		return 0, 0, ErrUnqualified
	}
	for _, r := range e.catalog.Buffs {
		if r["id"] != strconv.FormatInt(id, 10) {
			continue
		}
		a, err := strconv.Atoi(r["attr"])
		if err != nil || a < 0 || a > 49 {
			return 0, 0, ErrUnqualified
		}
		read := func(s string) (float64, error) {
			if s == "" {
				return 0, nil
			}
			if i := strings.Index(s, "p"); i >= 0 {
				v, er := strconv.ParseFloat(s[:i], 64)
				return v / 10000, er
			}
			return strconv.ParseFloat(s, 64)
		}
		init, er := read(r["init"])
		step, er2 := read(r["step"])
		if er != nil || er2 != nil {
			return 0, 0, ErrUnqualified
		}
		if strings.Contains(r["init"], "p") {
			return a, 0, nil
		}
		v := init + level*step
		if !finite(v) {
			return 0, 0, ErrUnqualified
		}
		return a, v, nil
	}
	return 0, 0, ErrUnqualified
}
