package spirit

import (
	"errors"
	"math/big"
	"strconv"
	"strings"
)

var ErrInvalid = errors.New("spirit: invalid transition")
var ErrUnqualified = errors.New("spirit: unqualified owner or content")
var ErrUnavailable = errors.New("spirit: required policy unavailable")

const SourcePolicy = "C2H_SPIRIT_SOURCE_V1"
const SeedPolicy = "C2H_EMPTY_PRESERVATION_SEED_V1"
const ReconstructionPolicy = "C2H_V1_PRESERVATION_ROLL_V1"
const RootLockRank = 580
const HeroLockRank = 590
const MaxID = int64(9007199254740991)

type Model struct {
	ID, Star, Position, SubNum, BaseEXP  int64
	Main, MainP, Sub, SubP, Rates        []int64
	MainBase, MainStep, SubBase, SubStep []string
}
type Template struct{ ID, Model, Suit int64 }
type Suit struct {
	ID, Attr    int64
	Value       string
	IsP         bool
	Description string
}
type Catalog struct {
	Policy                                      string
	Models                                      map[int64]Model
	Templates                                   map[int64]Template
	Suits                                       map[int64]Suit
	Strength                                    map[int64][]int64
	Transfer, GoldRate                          string
	FunctionLevel, ProgramLimit, TrialSoftLimit int64
}

func ints(s string) []int64 {
	out := []int64{}
	if s == "" {
		return out
	}
	for _, v := range strings.Split(s, "|") {
		n, e := strconv.ParseInt(v, 10, 64)
		if e != nil {
			return nil
		}
		out = append(out, n)
	}
	return out
}
func number(s string) int64 { n, _ := strconv.ParseInt(s, 10, 64); return n }
func Rat(s string) (*big.Rat, error) {
	v, ok := new(big.Rat).SetString(s)
	if !ok {
		return nil, ErrUnqualified
	}
	return v, nil
}
func NewCatalog(schema int, policy string, tables map[string][]map[string]string) (Catalog, error) {
	c := Catalog{Policy: policy, Models: map[int64]Model{}, Templates: map[int64]Template{}, Suits: map[int64]Suit{}, Strength: map[int64][]int64{}}
	if schema != 1 || policy != SourcePolicy {
		return c, ErrUnqualified
	}
	for _, r := range tables["models"] {
		m := Model{ID: number(r["id"]), Star: number(r["star"]), Position: number(r["pos"]), SubNum: number(r["sub_num"]), BaseEXP: number(r["exp"]), Main: ints(r["main"]), MainP: ints(r["main_is_p"]), Sub: ints(r["sub"]), SubP: ints(r["sub_is_p"]), Rates: ints(r["sub_num_rate"]), MainBase: strings.Split(r["main_value"], "|"), MainStep: strings.Split(r["main_strth"], "|"), SubBase: strings.Split(r["sub_value"], "|"), SubStep: strings.Split(r["sub_strth"], "|")}
		if _, ok := c.Models[m.ID]; ok {
			return c, ErrUnqualified
		}
		c.Models[m.ID] = m
	}
	itemtypes := map[int64]int64{}
	for _, r := range tables["items"] {
		itemtypes[number(r["id"])] = number(r["type"])
	}
	for _, r := range tables["equipment"] {
		t := Template{number(r["item_id"]), number(r["model_id"]), number(r["from"])}
		if _, ok := c.Templates[t.ID]; ok || itemtypes[t.ID] != 24 {
			return c, ErrUnqualified
		}
		c.Templates[t.ID] = t
	}
	for _, r := range tables["suits"] {
		s := Suit{number(r["id"]), number(r["attr_2"]), r["attr_2_value"], r["is_p"] == "1", r["attr_4_desc"]}
		if _, ok := c.Suits[s.ID]; ok {
			return c, ErrUnqualified
		}
		c.Suits[s.ID] = s
	}
	for _, r := range tables["strengthen"] {
		star, l := number(r["star"]), number(r["lv"])
		if star < 1 || star > 6 || l < 1 || l > 15 {
			return c, ErrUnqualified
		}
		if c.Strength[star] == nil {
			c.Strength[star] = make([]int64, 15)
		}
		if c.Strength[star][l-1] != 0 {
			return c, ErrUnqualified
		}
		c.Strength[star][l-1] = number(r["exp"])
	}
	for _, r := range tables["misc"] {
		switch r["key"] {
		case "spirit_strth_exp_rate":
			c.Transfer = r["value"]
		case "spirit_strth_gold_rate":
			c.GoldRate = r["value"]
		case "spirit_num_limit":
			c.TrialSoftLimit = number(r["value"])
		case "spirit_program_limit":
			c.ProgramLimit = number(r["value"])
		}
	}
	for _, r := range tables["function"] {
		if r["id"] == "99" && r["level"] == "1|60" {
			c.FunctionLevel = 60
		}
	}
	return c, c.Validate()
}
func (c Catalog) Validate() error {
	if c.Policy != SourcePolicy || len(c.Models) != 54 || len(c.Templates) != 378 || len(c.Suits) != 11 || len(c.Strength) != 6 || c.Transfer != "0.6" || c.GoldRate != "25" || c.FunctionLevel != 60 || c.ProgramLimit != 20 || c.TrialSoftLimit != 2000 {
		return ErrUnqualified
	}
	for id, m := range c.Models {
		if id <= 0 || m.ID != id || m.Star < 1 || m.Star > 6 || m.Position < 1 || m.Position > 6 || m.BaseEXP <= 0 || len(m.Main) == 0 || len(m.Main) != len(m.MainP) || len(m.Main) != len(m.MainBase) || len(m.Main) != len(m.MainStep) || m.SubNum < 2 || m.SubNum > 4 || len(m.Rates) != int(m.SubNum+1) || len(m.Sub) != len(m.SubP) || len(m.Sub) != len(m.SubBase) || len(m.Sub) != len(m.SubStep) {
			return ErrUnqualified
		}
		seen := map[int64]bool{}
		for i, a := range m.Sub {
			if a <= 0 || a > 49 || seen[a] || m.SubP[i] < 0 || m.SubP[i] > 1 {
				return ErrUnqualified
			}
			seen[a] = true
		}
		for i, a := range m.Main {
			if a <= 0 || a > 49 || m.MainP[i] < 0 || m.MainP[i] > 1 {
				return ErrUnqualified
			}
		}
		sum := int64(0)
		for _, w := range m.Rates {
			if w < 0 || w > 10000 {
				return ErrUnqualified
			}
			sum += w
		}
		if sum <= 0 {
			return ErrUnqualified
		}
		for _, list := range [][]string{m.MainBase, m.MainStep, m.SubBase, m.SubStep} {
			for _, s := range list {
				v, e := Rat(s)
				if e != nil || v.Sign() < 0 {
					return ErrUnqualified
				}
			}
		}
	}
	for id, t := range c.Templates {
		_, m := c.Models[t.Model]
		_, s := c.Suits[t.Suit]
		if id != t.ID || id <= 0 || id > MaxID || !m || !s {
			return ErrUnqualified
		}
	}
	for star, a := range c.Strength {
		if star < 1 || star > 6 || len(a) != 15 {
			return ErrUnqualified
		}
		for _, v := range a {
			if v <= 0 || v > MaxID/15 {
				return ErrUnqualified
			}
		}
	}
	for id, s := range c.Suits {
		if id != s.ID || s.Attr <= 0 || s.Attr > 49 {
			return ErrUnqualified
		}
		if _, e := Rat(s.Value); e != nil {
			return e
		}
	}
	return nil
}
func (c Catalog) ModelFor(id int64) (Model, Template, error) {
	t, ok := c.Templates[id]
	if !ok {
		return Model{}, t, ErrInvalid
	}
	m, ok := c.Models[t.Model]
	if !ok {
		return m, t, ErrUnqualified
	}
	return m, t, nil
}
func (c Catalog) Level(star, exp int64) (int64, error) {
	a, ok := c.Strength[star]
	if !ok || exp < 0 {
		return 0, ErrInvalid
	}
	sum, lev := int64(0), int64(0)
	for i, n := range a {
		sum += n
		if exp >= sum {
			lev = int64(i + 1)
		}
	}
	if exp > sum {
		return 0, ErrUnqualified
	}
	return lev, nil
}
func (c Catalog) MaxEXP(star int64) (int64, error) {
	a, ok := c.Strength[star]
	if !ok {
		return 0, ErrUnqualified
	}
	n := int64(0)
	for _, v := range a {
		n += v
	}
	return n, nil
}
