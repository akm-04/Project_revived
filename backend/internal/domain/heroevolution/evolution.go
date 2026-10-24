// Package heroevolution supplies CharacterHero's applied stone-evolution facet.
// Blood awakening, ordinary star evolution and final combat stats are separate.
package heroevolution

import (
	"errors"
	"math"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const LifecyclePolicy = "C2I_V1_STONE_LIFECYCLE_V2"

var ErrInvalid = errors.New("hero evolution: invalid command or state")
var ErrUnqualified = errors.New("hero evolution: unqualified input")
var ErrStaleTime = errors.New("hero evolution: stale time")

type Stage struct {
	ID, Level, Star, Limit int64
	Attrs, Coefficients    []int64
}
type HeroTemplate struct {
	ID, StoneID, TicketType int64
	Kind                    string
}
type Catalog struct {
	stages  []Stage
	heroes  map[int64]HeroTemplate
	tickets map[int64][]int64
}

func number(v string) (int64, error) {
	n, e := strconv.ParseInt(v, 10, 64)
	if e != nil || n < 0 || strconv.FormatInt(n, 10) != v {
		return 0, ErrUnqualified
	}
	return n, nil
}
func numbers(v string) ([]int64, error) {
	var out []int64
	for _, v := range strings.Split(v, "|") {
		n, e := number(v)
		if e != nil || n == 0 {
			return nil, ErrUnqualified
		}
		out = append(out, n)
	}
	return out, nil
}

// NewCatalog validates detached rows from the pinned, hash-checked Content owner.
func NewCatalog(schema int, policy string, rows map[string][]map[string]string) (Catalog, error) {
	c := Catalog{heroes: map[int64]HeroTemplate{}, tickets: map[int64][]int64{}}
	if schema != 1 || policy != "C2I_STONE_SOURCE_V1" || len(rows["stages"]) != 3 || len(rows["tickets"]) != 2 || len(rows["heroes"]) != 569 {
		return c, ErrUnqualified
	}
	for i, r := range rows["stages"] {
		var s Stage
		var e error
		for key, dst := range map[string]*int64{"id": &s.ID, "level": &s.Level, "star": &s.Star, "limit_num": &s.Limit} {
			*dst, e = number(r[key])
			if e != nil || *dst == 0 {
				return Catalog{}, ErrUnqualified
			}
		}
		if s.ID != int64(i+1) || s.Star > 8 {
			return Catalog{}, ErrUnqualified
		}
		s.Attrs, e = numbers(r["attrs"])
		if e != nil {
			return Catalog{}, e
		}
		s.Coefficients, e = numbers(r["attrs_num"])
		if e != nil || len(s.Attrs) != len(s.Coefficients) {
			return Catalog{}, ErrUnqualified
		}
		seen := map[int64]bool{}
		for j, a := range s.Attrs {
			if seen[a] || s.Coefficients[j] > math.MaxInt64/s.Limit {
				return Catalog{}, ErrUnqualified
			}
			seen[a] = true
		}
		c.stages = append(c.stages, s)
	}
	for _, r := range rows["tickets"] {
		id, e := number(r["id"])
		if e != nil || id < 1 || id > 2 || c.tickets[id] != nil {
			return Catalog{}, ErrUnqualified
		}
		items, e := numbers(r["stone_ticket_items"])
		if e != nil {
			return Catalog{}, e
		}
		c.tickets[id] = items
	}
	for _, r := range rows["heroes"] {
		h := HeroTemplate{Kind: r["kind"]}
		var e error
		for key, dst := range map[string]*int64{"id": &h.ID, "stone_id": &h.StoneID, "stone_ticket": &h.TicketType} {
			*dst, e = number(r[key])
			if e != nil {
				return Catalog{}, e
			}
		}
		if h.ID < 1 || h.StoneID < 1 || (h.Kind != "NORMAL" && h.Kind != "SUPER") || h.TicketType > 2 {
			return Catalog{}, ErrUnqualified
		}
		if _, ok := c.heroes[h.ID]; ok {
			return Catalog{}, ErrUnqualified
		}
		c.heroes[h.ID] = h
	}
	return c, nil
}

func (c Catalog) Stage(id int64) (Stage, bool) {
	if id < 1 || id > int64(len(c.stages)) {
		return Stage{}, false
	}
	s := c.stages[id-1]
	s.Attrs = append([]int64(nil), s.Attrs...)
	s.Coefficients = append([]int64(nil), s.Coefficients...)
	return s, true
}
func (c Catalog) Hero(id int64) (HeroTemplate, bool) { h, ok := c.heroes[id]; return h, ok }

type Facts struct {
	Stage  int64            `json:"evo_stage"`
	Points map[string]int64 `json:"evo_attr_points"`
}

// Seed is the explicit preservation policy, never a read-side missing-row default.
func Seed() Facts { return Facts{Stage: 1, Points: map[string]int64{}} }
func (f Facts) Clone() Facts {
	out := Facts{Stage: f.Stage, Points: map[string]int64{}}
	for k, v := range f.Points {
		out.Points[k] = v
	}
	return out
}
func (f Facts) Wire() map[string]any {
	copy := f.Clone()
	return map[string]any{"evo_stage": copy.Stage, "evo_attr_points": copy.Points}
}
func (f Facts) Validate(c Catalog) error {
	s, ok := c.Stage(f.Stage)
	if !ok || f.Points == nil {
		return ErrUnqualified
	}
	for key, n := range f.Points {
		a, e := number(key)
		if e != nil || a == 0 || n < 0 || n > s.Limit {
			return ErrUnqualified
		}
		found := false
		for _, id := range s.Attrs {
			if id == a {
				found = true
			}
		}
		if !found {
			return ErrUnqualified
		}
	}
	return nil
}
func (c Catalog) Allocate(f Facts, template, level, star, attr, amount, item int64) (Facts, error) {
	if e := f.Validate(c); e != nil {
		return Facts{}, e
	}
	s, _ := c.Stage(f.Stage)
	h, ok := c.Hero(template)
	if !ok || amount <= 0 || level < s.Level || star < s.Star || amount > s.Limit {
		return Facts{}, ErrInvalid
	}
	found := false
	for _, a := range s.Attrs {
		if a == attr {
			found = true
		}
	}
	if !found {
		return Facts{}, ErrInvalid
	}
	allowed := item == h.StoneID && item > 0
	for _, id := range c.tickets[h.TicketType] {
		if item == id {
			allowed = true
		}
	}
	key := strconv.FormatInt(attr, 10)
	if !allowed || amount > s.Limit-f.Points[key] {
		return Facts{}, ErrInvalid
	}
	out := f.Clone()
	out.Points[key] += amount
	return out, nil
}
func (c Catalog) Advance(f Facts, template, level, star int64) (Facts, error) {
	if e := f.Validate(c); e != nil {
		return Facts{}, e
	}
	s, _ := c.Stage(f.Stage)
	next, ok := c.Stage(f.Stage + 1)
	if _, found := c.Hero(template); !found || !ok || level < next.Level || star < next.Star {
		return Facts{}, ErrInvalid
	}
	for _, a := range s.Attrs {
		if f.Points[strconv.FormatInt(a, 10)] != s.Limit {
			return Facts{}, ErrInvalid
		}
	}
	return Facts{Stage: next.ID, Points: map[string]int64{}}, nil
}

// Evaluate follows StoneEvolutionTable's positional cumulative rule exactly.
func (c Catalog) Evaluate(f Facts) (map[int64]int64, error) {
	if e := f.Validate(c); e != nil {
		return nil, e
	}
	out := map[int64]int64{}
	current, _ := c.Stage(f.Stage)
	for pos, attr := range current.Attrs {
		var sum int64
		for stage := int64(1); stage <= f.Stage; stage++ {
			s, _ := c.Stage(stage)
			if pos >= len(s.Coefficients) {
				return nil, ErrUnqualified
			}
			n := s.Limit
			if stage == f.Stage {
				n = f.Points[strconv.FormatInt(attr, 10)]
			}
			v := n * s.Coefficients[pos]
			if sum > math.MaxInt64-v {
				return nil, ErrUnqualified
			}
			sum += v
		}
		out[attr] = sum
	}
	return out, nil
}

// Facet is intrinsic CharacterHero state; it survives retirement as provenance.
type Facet struct {
	Player               identity.PlayerID
	PartnerID, Version   int64
	PolicyID             string
	Facts                Facts
	CreatedAt, UpdatedAt time.Time
}

func (f Facet) Validate(c Catalog) error {
	if !f.Player.Valid() || f.PartnerID < 1 || f.Version < 1 || f.PolicyID != LifecyclePolicy || f.CreatedAt.IsZero() || f.UpdatedAt.Before(f.CreatedAt) {
		return ErrUnqualified
	}
	return f.Facts.Validate(c)
}
