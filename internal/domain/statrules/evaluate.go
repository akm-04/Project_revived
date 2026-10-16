package statrules

import (
	"fmt"
	"math"
	"time"
)

// Observation is an already materialized numeric value. Reference binds its
// upstream evidence; this type cannot certify that evidence or genuine absence.
// Attribute0 is only for scalar methods. Missing values always fail closed.
type Observation struct {
	Reference string
	Values    map[int]float64
}
type Snapshot struct {
	Model                         string
	TemplateID                    int64
	Level, Star, Color            int
	ActorReference, ObservationID string
	ContentRevision, PolicyID     string
	ObservedAt                    time.Time
	Inputs                        map[string]Observation
}
type Result struct {
	Model, ActorReference, ObservationID, ContentRevision, PolicyID string
	ObservedAt                                                      time.Time
	Total                                                           [49]float64
	WithoutBook                                                     *[49]float64
	Force                                                           float64
	PetInitialLabel, PetAddedLabel                                  *[49]float64
}
type evaluation struct {
	e     *Engine
	s     Snapshot
	t     Template
	m     ModelRules
	steps int
}

func (e *Engine) Evaluate(s Snapshot) (Result, error) {
	var out Result
	if e == nil || s.Model == "" || s.ActorReference == "" || s.ObservationID == "" || s.ObservedAt.IsZero() || s.ContentRevision != e.revision || s.PolicyID != PolicyID || s.Level < 1 || s.Level > 1000000 || s.Color < 1 || s.Color > 1000000 {
		return out, ErrUnqualified
	}
	t, ok := e.templates[s.TemplateID]
	if !ok || t.Model != s.Model || s.Star < 1 || s.Star > len(t.Growth) {
		return out, ErrUnqualified
	}
	m := e.catalog.Models[s.Model]
	x := evaluation{e: e, s: s, t: t, m: m}
	for name, o := range s.Inputs {
		if !e.leaves[s.Model+"/"+name] || o.Reference == "" || len(o.Values) == 0 {
			return out, ErrUnqualified
		}
		for a, v := range o.Values {
			if a < 0 || a > 49 || !finite(v) {
				return out, ErrUnqualified
			}
		}
	}
	out = Result{Model: s.Model, ActorReference: s.ActorReference, ObservationID: s.ObservationID, ContentRevision: s.ContentRevision, PolicyID: s.PolicyID, ObservedAt: s.ObservedAt}
	if s.Model != "Pet" {
		out.WithoutBook = &[49]float64{}
	} else {
		out.PetInitialLabel = &[49]float64{}
		out.PetAddedLabel = &[49]float64{}
	}
	for a := 1; a <= 49; a++ {
		v, err := x.call("getTotalAttr", a, 0)
		if err != nil {
			return Result{}, err
		}
		out.Total[a-1] = v
		if out.WithoutBook != nil {
			v, err = x.call("getTotalAttrWithOutBook", a, 0)
			if err != nil {
				return Result{}, err
			}
			out.WithoutBook[a-1] = v
		} else {
			sum := 0.0
			initial := v
			for _, name := range []string{"getEquipFumoAttr", "getEquipAttr", "getSkillAttr", "getSkill2Attr", "getTotalPracticeAttr"} {
				z, er := x.call(name, a, 0)
				if er != nil {
					return Result{}, er
				}
				sum += z
				initial -= z
			}
			out.PetInitialLabel[a-1] = math.Ceil(math.Max(0, initial))
			out.PetAddedLabel[a-1] = math.Ceil(sum)
		}
	}
	force, err := x.call("getZhandouli", 1, 0)
	if err != nil {
		return Result{}, err
	}
	out.Force = force
	return out, nil
}
func (x *evaluation) leaf(name string, a int) (float64, error) {
	o, ok := x.s.Inputs[name]
	if !ok || o.Reference == "" {
		return 0, fmt.Errorf("%w: %s[%d]", ErrUnqualified, name, a)
	}
	v, ok := o.Values[a]
	if !ok || !finite(v) {
		return 0, fmt.Errorf("%w: %s[%d]", ErrUnqualified, name, a)
	}
	return v, nil
}
func (x *evaluation) call(name string, a, depth int) (float64, error) {
	if depth > 128 || a < 0 || a > 49 {
		return 0, ErrUnqualified
	}
	switch name {
	case "getColor":
		return float64(x.s.Color), nil
	case "getHeroType":
		return float64(x.t.HeroType), nil
	case "getInitialAttr":
		if a < 1 {
			return 0, ErrUnqualified
		}
		return x.t.Initial[a-1], nil
	case "attrScore":
		if a < 1 {
			return 0, ErrUnqualified
		}
		return x.e.scores[a-1], nil
	case "getBaseGrowth":
		if a < 1 || a > 3 {
			return 0, ErrUnqualified
		}
		return float64(x.s.Level) * x.t.Growth[x.s.Star-1][a-1], nil
	case "getGrowAttr":
		base, err := x.call("getBaseGrowth", a, depth+1)
		if err != nil {
			return 0, err
		}
		favor, err := x.leaf("getFavorAttrGrowth", 0)
		if err != nil {
			return 0, err
		}
		house, err := x.leaf("getHouseAttrGrowthByType", a)
		if err != nil {
			return 0, err
		}
		book, err := x.leaf("getBookShelfAttr", a)
		if err != nil {
			return 0, err
		}
		v := base*(1+favor+house) + book
		if !finite(v) {
			return 0, ErrUnqualified
		}
		return v, nil
	case "getBasicForce":
		sum := 0.0
		for i := 1; i <= x.m.BasicForceLimit; i++ {
			v := x.t.Initial[i-1]
			if i <= 3 {
				growth := "getGrowAttr"
				if x.s.Model == "Pet" {
					growth = "getBaseGrowth"
				}
				g, er := x.call(growth, i, depth+1)
				if er != nil {
					return 0, er
				}
				promotion := x.e.catalog.Constants["JINJIE_ATTR_RATE"] * float64(x.s.Color-1) / 2 * float64(x.s.Color)
				v = g + promotion + v
			}
			sum += v * x.e.scores[i-1]
		}
		if !finite(sum) {
			return 0, ErrUnqualified
		}
		return sum, nil
	}
	if xs, ok := x.m.Rules[name]; ok {
		if a == 0 {
			a = 1
		}
		return x.eval(xs[a-1], depth+1)
	}
	if v, ok := x.m.Force[name]; ok {
		return x.eval(v, depth+1)
	}
	return x.leaf(name, a)
}
func (x *evaluation) eval(e Expr, depth int) (float64, error) {
	x.steps++
	if depth > 128 || x.steps > 2000000 {
		return 0, ErrUnqualified
	}
	args := make([]float64, len(e.Args))
	for i, a := range e.Args {
		v, err := x.eval(a, depth+1)
		if err != nil {
			return 0, err
		}
		args[i] = v
	}
	v := e.Value
	switch e.Op {
	case "number":
	case "add":
		v = args[0] + args[1]
	case "sub":
		v = args[0] - args[1]
	case "mul":
		v = args[0] * args[1]
	case "div":
		if args[1] == 0 {
			return 0, ErrUnqualified
		}
		v = args[0] / args[1]
	case "call":
		switch e.Name {
		case "floor":
			v = math.Floor(args[0])
		case "ceil":
			v = math.Ceil(args[0])
		default:
			a := 0
			if len(args) == 1 {
				if args[0] != math.Trunc(args[0]) {
					return 0, ErrUnqualified
				}
				a = int(args[0])
			}
			return x.call(e.Name, a, depth+1)
		}
	default:
		return 0, ErrUnqualified
	}
	if !finite(v) {
		return 0, ErrUnqualified
	}
	return v, nil
}
