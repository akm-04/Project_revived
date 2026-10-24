package spirit

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/identity"
	"math/big"
	"strings"
	"time"
	"unicode/utf8"
)

type Instance struct {
	ID         int64         `json:"spirit_id"`
	TemplateID int64         `json:"table_id"`
	Star       int64         `json:"star"`
	Level      int64         `json:"lev"`
	EXP        int64         `json:"exp"`
	Main       int64         `json:"main"`
	MainValue  json.Number   `json:"main_attr_value"`
	Sub        []int64       `json:"sub"`
	SubValues  []json.Number `json:"sub_attr_value"`
	BirthSub   []int64       `json:"birth_sub"`
	Locked     bool          `json:"locked"`
	Policy     string        `json:"policy"`
}
type Program struct {
	ID    int64    `json:"id"`
	Name  string   `json:"name"`
	Slots [6]int64 `json:"slots"`
}
type State struct {
	Policy        string             `json:"policy"`
	NextID        int64              `json:"next_id"`
	NextProgramID int64              `json:"next_program_id"`
	Instances     map[int64]Instance `json:"instances"`
	Programs      map[int64]Program  `json:"programs"`
}
type HeroFacts struct {
	Policy string   `json:"policy"`
	Slots  [6]int64 `json:"slots"`
}
type Root struct {
	Player               identity.PlayerID
	Version              int64
	Revision             string
	Facts                State
	CreatedAt, UpdatedAt time.Time
}
type HeroRoot struct {
	Player               identity.PlayerID
	PartnerID, Version   int64
	Facts                HeroFacts
	CreatedAt, UpdatedAt time.Time
}

func Seed() State {
	return State{Policy: SeedPolicy, NextID: 1, NextProgramID: 1, Instances: map[int64]Instance{}, Programs: map[int64]Program{}}
}
func SeedHero() HeroFacts { return HeroFacts{Policy: SeedPolicy} }
func Num(r *big.Rat) (json.Number, error) {
	d := new(big.Int).Set(r.Denom())
	two, five := 0, 0
	zero := big.NewInt(0)
	for new(big.Int).Mod(d, big.NewInt(2)).Cmp(zero) == 0 {
		d.Div(d, big.NewInt(2))
		two++
	}
	for new(big.Int).Mod(d, big.NewInt(5)).Cmp(zero) == 0 {
		d.Div(d, big.NewInt(5))
		five++
	}
	if d.Cmp(big.NewInt(1)) != 0 {
		return "", ErrUnqualified
	}
	if five > two {
		two = five
	}
	s := r.FloatString(two)
	if strings.Contains(s, ".") {
		s = strings.TrimRight(strings.TrimRight(s, "0"), ".")
	}
	return json.Number(s), nil
}
func mainValue(m Model, sel, level int64) (json.Number, error) {
	if sel < 1 || sel > int64(len(m.Main)) {
		return "", ErrInvalid
	}
	b, e := Rat(m.MainBase[sel-1])
	if e != nil {
		return "", e
	}
	step, e := Rat(m.MainStep[sel-1])
	if e != nil {
		return "", e
	}
	return Num(new(big.Rat).Add(b, new(big.Rat).Mul(step, big.NewRat(level, 1))))
}
func (x Instance) Validate(c Catalog) error {
	m, _, e := c.ModelFor(x.TemplateID)
	if e != nil {
		return e
	}
	if x.ID <= 0 || x.ID > MaxID || x.Star != m.Star || x.Policy != ReconstructionPolicy || x.Sub == nil || x.SubValues == nil || x.BirthSub == nil || len(x.Sub) != len(x.SubValues) || len(x.Sub) > int(m.SubNum) || len(x.BirthSub) > len(x.Sub) {
		return ErrUnqualified
	}
	lev, e := c.Level(x.Star, x.EXP)
	if e != nil || lev != x.Level {
		return ErrUnqualified
	}
	want, e := mainValue(m, x.Main, x.Level)
	if e != nil {
		return e
	}
	a, e := Rat(x.MainValue.String())
	b, _ := Rat(want.String())
	if e != nil || a.Cmp(b) != 0 {
		return ErrUnqualified
	}
	seen := map[int64]bool{}
	improvements := int64(0)
	for i, sel := range x.Sub {
		if sel < 1 || sel > int64(len(m.Sub)) || seen[sel] {
			return ErrUnqualified
		}
		seen[sel] = true
		v, e := Rat(x.SubValues[i].String())
		if e != nil {
			return e
		}
		base, _ := Rat(m.SubBase[sel-1])
		step, _ := Rat(m.SubStep[sel-1])
		diff := new(big.Rat).Sub(v, base)
		if diff.Sign() < 0 {
			return ErrUnqualified
		}
		if step.Sign() == 0 {
			if diff.Sign() != 0 {
				return ErrUnqualified
			}
		} else {
			q := new(big.Rat).Quo(diff, step)
			if !q.IsInt() || !q.Num().IsInt64() {
				return ErrUnqualified
			}
			improvements += q.Num().Int64()
		}
	}
	born := map[int64]bool{}
	for _, sel := range x.BirthSub {
		if !seen[sel] || born[sel] {
			return ErrUnqualified
		}
		born[sel] = true
	}
	if len(x.BirthSub) >= len(m.Rates) || m.Rates[len(x.BirthSub)] <= 0 || improvements+int64(len(x.Sub)-len(x.BirthSub)) != x.Level/3 {
		return ErrUnqualified
	}
	return nil
}
func (x Instance) Clone() Instance {
	x.Sub = append([]int64{}, x.Sub...)
	x.SubValues = append([]json.Number{}, x.SubValues...)
	x.BirthSub = append([]int64{}, x.BirthSub...)
	return x
}
func (x Instance) Wire(c Catalog, equipped, refs int64) (map[string]any, error) {
	if e := x.Validate(c); e != nil {
		return nil, e
	}
	m, _, _ := c.ModelFor(x.TemplateID)
	attrs := []int64{}
	for _, s := range x.Sub {
		attrs = append(attrs, m.Sub[s-1])
	}
	locked := int64(0)
	if x.Locked {
		locked = 1
	}
	return map[string]any{"spirit_id": x.ID, "table_id": x.TemplateID, "star": x.Star, "lev": x.Level, "exp": x.EXP, "main": x.Main, "main_attr": m.Main[x.Main-1], "main_attr_value": x.MainValue, "sub": x.Sub, "sub_attr": attrs, "sub_attr_value": x.SubValues, "is_lock": locked, "is_equip": equipped, "collo_count": refs}, nil
}
func (s State) Clone() State {
	o := s
	o.Instances = map[int64]Instance{}
	for id, x := range s.Instances {
		o.Instances[id] = x.Clone()
	}
	o.Programs = map[int64]Program{}
	for id, p := range s.Programs {
		o.Programs[id] = p
	}
	return o
}
func ValidName(s string) bool {
	return utf8.ValidString(s) && utf8.RuneCountInString(s) >= 1 && utf8.RuneCountInString(s) <= 10 && strings.TrimSpace(s) != ""
}
func (s State) ValidateSlots(c Catalog, slots [6]int64, nonempty bool) error {
	seen := map[int64]bool{}
	for i, id := range slots {
		if id == 0 {
			continue
		}
		x, ok := s.Instances[id]
		if !ok || seen[id] {
			return ErrUnqualified
		}
		m, _, e := c.ModelFor(x.TemplateID)
		if e != nil || m.Position != int64(i+1) {
			return ErrUnqualified
		}
		seen[id] = true
	}
	if nonempty && len(seen) == 0 {
		return ErrInvalid
	}
	return nil
}
func (s State) Validate(c Catalog) error {
	if s.Policy != SeedPolicy || s.NextID < 1 || s.NextID > MaxID || s.NextProgramID < 1 || s.NextProgramID > MaxID || s.Instances == nil || s.Programs == nil || len(s.Programs) > int(c.ProgramLimit) {
		return ErrUnqualified
	}
	for id, x := range s.Instances {
		if id != x.ID || id >= s.NextID {
			return ErrUnqualified
		}
		if e := x.Validate(c); e != nil {
			return e
		}
	}
	names := map[string]bool{}
	for id, p := range s.Programs {
		if id <= 0 || p.ID != id || id >= s.NextProgramID || !ValidName(p.Name) || names[p.Name] {
			return ErrUnqualified
		}
		names[p.Name] = true
		if e := s.ValidateSlots(c, p.Slots, true); e != nil {
			return e
		}
	}
	return nil
}
func (s State) ReferenceCount(id int64) int64 {
	var n int64
	for _, p := range s.Programs {
		for _, v := range p.Slots {
			if v == id {
				n++
			}
		}
	}
	return n
}
func (h HeroFacts) Validate(c Catalog, s State) error {
	if h.Policy != SeedPolicy {
		return ErrUnqualified
	}
	return s.ValidateSlots(c, h.Slots, false)
}
func (s State) ValidateBindings(c Catalog, facets []HeroRoot) (map[int64]int64, error) {
	out := map[int64]int64{}
	seenHeroes := map[int64]bool{}
	for _, h := range facets {
		if !h.Player.Valid() || h.PartnerID <= 0 || h.Version <= 0 || seenHeroes[h.PartnerID] {
			return nil, ErrUnqualified
		}
		seenHeroes[h.PartnerID] = true
		if e := h.Facts.Validate(c, s); e != nil {
			return nil, e
		}
		for _, id := range h.Facts.Slots {
			if id > 0 {
				if out[id] > 0 {
					return nil, ErrUnqualified
				}
				out[id] = h.PartnerID
			}
		}
	}
	return out, nil
}
