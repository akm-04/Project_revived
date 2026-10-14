package bookskill

import (
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"math/big"
	"strconv"
	"time"
)

var ErrUnqualified = errors.New("book: unqualified facts")
var ErrInvalid = errors.New("book: invalid transition")
var ErrStaleTime = errors.New("book: stale observation time")

const PolicyID = "C2D_V1_BUILDING_SEEDS_AND_JOB_REFUNDS_V1"

type BookBuildingRule struct {
	Type, Level, Duration, RequiresType, RequiresLevel, CutTime, UpperLimit int64
	Resources                                                               map[string]int64
	Attributes                                                              [3]string
}
type BookRule struct {
	ID, Star, Type, Piece, PieceCount, SkillPage int64
	Skills                                       []int64
}
type BookSkillRule struct {
	ID, Book, Partner, CostClass, AttrID, ActionType int64
	Value                                            string
	Times, Prerequisites                             []int64
}
type BookCostRule struct {
	Level, Class int64
	Resources    map[string]int64
	Pages        int64
}

type Catalog struct {
	Buildings map[[2]int64]BookBuildingRule
	Books     map[int64]BookRule
	Skills    map[int64]BookSkillRule
	Costs     map[[2]int64]BookCostRule
}
type Cost struct {
	Scalars map[string]int64
	Stacks  map[int64]int64
}

func EmptyCost() Cost { return Cost{map[string]int64{}, map[int64]int64{}} }

type Job struct {
	Occurrence, Revision      string
	StartedAt                 time.Time
	Duration, Target, Subject int64
	Cost                      Cost
}
type Building struct {
	Level  int64
	Job    *Job
	Recent bool
}
type State struct {
	Buildings   map[int64]Building
	Skills      map[int64]int64
	Research    *Job
	RecentSkill int64
}

func Seed() State {
	return State{Buildings: map[int64]Building{1: {Level: 1}, 3: {Level: 1}, 4: {Level: 1}}, Skills: map[int64]int64{}}
}
func (s State) Clone() State {
	raw, _ := json.Marshal(s)
	var out State
	_ = json.Unmarshal(raw, &out)
	return out
}
func (c Catalog) Validate() error {
	if len(c.Buildings) == 0 || len(c.Books) == 0 || len(c.Skills) == 0 || len(c.Costs) == 0 {
		return ErrUnqualified
	}
	for k, r := range c.Buildings {
		if k != [2]int64{r.Type, r.Level} || r.Level < 1 || r.Duration < 0 || r.CutTime < 0 {
			return ErrUnqualified
		}
		for _, v := range r.Resources {
			if v < 0 {
				return ErrUnqualified
			}
		}
	}
	for id, b := range c.Books {
		if id != b.ID || b.Star < 1 || b.Star > 6 || (b.Type != 1 && b.Type != 2) || len(b.Skills) == 0 {
			return ErrUnqualified
		}
		for _, sid := range b.Skills {
			r, ok := c.Skills[sid]
			if !ok || r.Book != id {
				return ErrUnqualified
			}
		}
	}
	for id, r := range c.Skills {
		b, ok := c.Books[r.Book]
		if !ok || r.ID != id || r.Partner <= 0 || len(r.Times) != int(b.Star) || r.CostClass < 1 || r.CostClass > 4 {
			return ErrUnqualified
		}
		for _, sid := range r.Prerequisites {
			if _, ok := c.Skills[sid]; !ok {
				return ErrUnqualified
			}
		}
	}
	return nil
}
func validJob(j *Job) bool {
	return j == nil || (j.Occurrence != "" && len(j.Revision) == 64 && !j.StartedAt.IsZero() && j.Duration >= 0 && j.Target > 0 && j.Subject > 0)
}
func (s State) Validate(c Catalog) error {
	if s.Buildings == nil || s.Skills == nil || len(s.Buildings) != 3 || !validJob(s.Research) {
		return ErrUnqualified
	}
	for _, t := range []int64{1, 3, 4} {
		b, ok := s.Buildings[t]
		if !ok || b.Level < 1 || !validJob(b.Job) {
			return ErrUnqualified
		}
		if _, ok = c.Buildings[[2]int64{t, b.Level}]; !ok {
			return ErrUnqualified
		}
		if b.Job != nil && (b.Job.Subject != t || b.Job.Target != b.Level+1) {
			return ErrUnqualified
		}
	}
	for id, lev := range s.Skills {
		r, ok := c.Skills[id]
		if !ok || lev < 1 || lev > c.Books[r.Book].Star {
			return ErrUnqualified
		}
	}
	if s.Research != nil {
		r, ok := c.Skills[s.Research.Subject]
		if !ok || s.Research.Target != s.Skills[r.ID]+1 || s.Research.Target > c.Books[r.Book].Star {
			return ErrUnqualified
		}
	}
	return nil
}
func Remaining(j *Job, at time.Time) (int64, error) {
	if j == nil {
		return 0, ErrInvalid
	}
	if at.Before(j.StartedAt) {
		return 0, ErrStaleTime
	}
	elapsed := at.Unix() - j.StartedAt.Unix()
	if elapsed >= j.Duration {
		return 0, nil
	}
	return j.Duration - elapsed, nil
}

// Apply due owner intents; time is captured by the caller. No value changes at completion.
func (s *State) Settle(at time.Time) (bool, error) {
	changed := false
	for t, b := range s.Buildings {
		if b.Job == nil {
			continue
		}
		left, e := Remaining(b.Job, at)
		if e != nil {
			return false, e
		}
		if left == 0 {
			b.Level = b.Job.Target
			b.Job = nil
			b.Recent = true
			s.Buildings[t] = b
			changed = true
		}
	}
	if s.Research != nil {
		left, e := Remaining(s.Research, at)
		if e != nil {
			return false, e
		}
		if left == 0 {
			s.Skills[s.Research.Subject] = s.Research.Target
			s.RecentSkill = s.Research.Subject
			s.Research = nil
			changed = true
		}
	}
	return changed, nil
}
func SpeedCost(left int64) int64 {
	if left <= 0 {
		return 0
	}
	if left < 14400 {
		return (left + 71) / 72
	}
	if left < 43200 {
		return 200 + (left-14400+143)/144
	}
	return 400 + (left-43200+431)/432
}
func Refund(j *Job, left int64) (Cost, error) {
	o := EmptyCost()
	if j == nil || left <= 0 || left > j.Duration || j.Duration <= 0 {
		return o, ErrInvalid
	}
	for k, n := range j.Cost.Scalars {
		a := new(big.Int).Mul(big.NewInt(n), big.NewInt(left))
		a.Quo(a, big.NewInt(j.Duration))
		if !a.IsInt64() {
			return o, ErrUnqualified
		}
		if a.Int64() > 0 {
			o.Scalars[k] = a.Int64()
		}
	}
	for k, n := range j.Cost.Stacks {
		o.Stacks[k] = n
	}
	return o, nil
}
func (c Catalog) ResearchPlan(s State, id int64) (int64, Cost, error) {
	r, ok := c.Skills[id]
	cost := EmptyCost()
	if !ok {
		return 0, cost, ErrInvalid
	}
	b := c.Books[r.Book]
	target := s.Skills[id] + 1
	if target > b.Star || s.Buildings[1].Level < b.Star || s.Buildings[1].Job != nil {
		return 0, cost, ErrInvalid
	}
	for _, p := range r.Prerequisites {
		if s.Skills[p] < target {
			return 0, cost, ErrInvalid
		}
	}
	rule, ok := c.Costs[[2]int64{r.CostClass, target}]
	if !ok {
		return 0, cost, ErrUnqualified
	}
	for k, n := range rule.Resources {
		if n > 0 {
			cost.Scalars[k] = n
		}
	}
	if rule.Pages > 0 {
		if b.SkillPage <= 0 {
			return 0, cost, ErrUnqualified
		}
		cost.Stacks[b.SkillPage] = rule.Pages
	}
	cut := c.Buildings[[2]int64{1, s.Buildings[1].Level}].CutTime
	duration := r.Times[target-1] - cut
	if duration < 0 {
		duration = 0
	}
	return duration, cost, nil
}
func (c Catalog) BuildingPlan(s State, t int64) (int64, Cost, error) {
	if t == 1 && s.Research != nil {
		return 0, EmptyCost(), ErrInvalid
	}
	b, ok := s.Buildings[t]
	o := EmptyCost()
	if !ok || b.Job != nil || b.Recent {
		return 0, o, ErrInvalid
	}
	r, ok := c.Buildings[[2]int64{t, b.Level}]
	if !ok {
		return 0, o, ErrUnqualified
	}
	if _, ok = c.Buildings[[2]int64{t, b.Level + 1}]; !ok {
		return 0, o, ErrInvalid
	}
	if s.Buildings[r.RequiresType].Level < r.RequiresLevel {
		return 0, o, ErrInvalid
	}
	for k, n := range r.Resources {
		if n > 0 {
			o.Scalars[k] = n
		}
	}
	return r.Duration, o, nil
}
func BuildingWire(b Building) map[string]any {
	start, need := int64(0), int64(0)
	recent := 0
	if b.Job != nil {
		start = b.Job.StartedAt.Unix()
		need = b.Job.Duration
	}
	if b.Recent {
		recent = 1
	}
	return map[string]any{"lev": b.Level, "start_time": start, "need_time": need, "new_evolve": recent}
}
func CabinetWire(s State) map[string]any {
	start, need, skill := int64(0), int64(0), int64(0)
	if s.Research != nil {
		start = s.Research.StartedAt.Unix()
		need = s.Research.Duration
		skill = s.Research.Subject
	}
	return map[string]any{"cur_learn_skill": skill, "need_time": need, "start_time": start, "recent_complete_skill": s.RecentSkill}
}
func BookWire(c Catalog, s State, id int64, complete bool) map[string]any {
	o := map[string]any{}
	for _, sid := range c.Books[id].Skills {
		lev := s.Skills[sid]
		if complete || lev > 0 {
			o[strconv.FormatInt(sid, 10)] = map[string]any{"lev": lev}
		}
	}
	return o
}

type Root struct {
	Player               identity.PlayerID
	Version              int64
	Revision             string
	Facts                State
	CreatedAt, UpdatedAt time.Time
}
