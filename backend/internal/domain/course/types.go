package course

import (
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"strconv"
	"time"
)

var (
	ErrInvalid     = errors.New("course: invalid transition")
	ErrUnqualified = errors.New("course: unqualified input")
	ErrStaleTime   = errors.New("course: stale decision")
)

const RootLockRank = 520
const HeroLockRank = 530

type Catalog struct {
	SchemaVersion                                         int                            `json:"schema_version"`
	PolicyID                                              string                         `json:"policy_id"`
	OverflowPolicyID                                      string                         `json:"overflow_policy_id"`
	Tables                                                map[string][]map[string]string `json:"tables"`
	Duration, ForgetCost, SpeedHalfHour, MaxEXP, LogLimit int64
	Tickets                                               map[int64]int64
	BookEXP                                               map[int64]int64
	Capacity                                              map[int64]int64
	Thresholds                                            []int64
	Refunds                                               map[int64]map[int64]int64
	Slots                                                 [6]bool
}

func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C2E_V1_COURSE_PROGRESS_AND_SEEDS_V1" || c.OverflowPolicyID != "C2E_V1_WHOLE_BOOK_PROFICIENCY_V1" || len(c.Tables["book"]) != 48 || len(c.Tables["class"]) != 12 || len(c.Tables["subject"]) != 4 || len(c.Thresholds) != 6 || c.Duration != 28800 || c.ForgetCost != 200 || c.SpeedHalfHour != 15 || c.MaxEXP != 1680 || c.LogLimit != 30 || len(c.Tickets) != 48 || len(c.BookEXP) != 4 || len(c.Capacity) != 16 {
		return ErrUnqualified
	}
	return nil
}
func (c Catalog) Has(id int64) bool { _, ok := c.Tickets[id]; return ok }
func (c Catalog) Metadata(id int64) map[string]string {
	for _, r := range c.Tables["book"] {
		if r["id"] == strconv.FormatInt(id, 10) {
			out := map[string]string{}
			for k, v := range r {
				out[k] = v
			}
			return out
		}
	}
	return nil
}
func (c Catalog) Quality(exp int64) int64 {
	q := int64(1)
	for i, n := range c.Thresholds {
		if exp >= n {
			q = int64(i + 1)
		}
	}
	return q
}

type Record struct {
	ID       int64 `json:"id"`
	Progress int64 `json:"progress"`
	Quality  int64 `json:"quality"`
	Skill    int64 `json:"add_skill"`
	EXP      int64 `json:"exp"`
}
type HeroFacts struct {
	Courses []Record `json:"courses"`
}

func SeedHero() HeroFacts { return HeroFacts{Courses: []Record{}} }
func (h HeroFacts) Clone() HeroFacts {
	out := SeedHero()
	out.Courses = append(out.Courses, h.Courses...)
	return out
}
func (h HeroFacts) Validate(c Catalog) error {
	ids := map[int64]bool{}
	slots := map[int64]bool{}
	if h.Courses == nil {
		return ErrUnqualified
	}
	for _, r := range h.Courses {
		if !c.Has(r.ID) || ids[r.ID] || r.Progress < 0 || r.Progress > 100 || r.EXP < 0 || r.EXP > c.MaxEXP || r.Quality != c.Quality(r.EXP) || r.Skill < 0 || r.Skill > 6 || r.Skill > 0 && (!c.Slots[r.Skill-1] || r.Progress != 100 || slots[r.Skill]) || r.Progress < 100 && r.EXP != 0 {
			return ErrUnqualified
		}
		ids[r.ID] = true
		if r.Skill > 0 {
			slots[r.Skill] = true
		}
	}
	return nil
}
func (h HeroFacts) Index(id int64) int {
	for i, r := range h.Courses {
		if r.ID == id {
			return i
		}
	}
	return -1
}

type Job struct {
	Occurrence, Revision string
	StartedAt            time.Time
	Duration             int64
	CourseID             int64
}
type Attendance struct {
	PartnerID int64 `json:"partner_id"`
	EnterAt   time.Time
	Job       *Job
}
type Log struct {
	PartnerID int64 `json:"partner_id"`
	CourseID  int64 `json:"course_id"`
	Kind      int64 `json:"log_id"`
	At        int64 `json:"time"`
	Param     int64 `json:"param"`
}
type State struct {
	Attendance map[int64]Attendance
	Logs       []Log
}

func Seed() State { return State{Attendance: map[int64]Attendance{}, Logs: []Log{}} }
func (s State) Clone() State {
	b, _ := json.Marshal(s)
	var out State
	_ = json.Unmarshal(b, &out)
	return out
}
func (s State) Validate(c Catalog) error {
	if s.Attendance == nil || s.Logs == nil || len(s.Logs) > int(c.LogLimit) {
		return ErrUnqualified
	}
	for p, a := range s.Attendance {
		if p <= 0 || p != a.PartnerID || a.EnterAt.IsZero() {
			return ErrUnqualified
		}
		if a.Job != nil && (a.Job.Occurrence == "" || len(a.Job.Revision) != 64 || a.Job.Duration != c.Duration || !c.Has(a.Job.CourseID) || a.Job.StartedAt.Before(a.EnterAt)) {
			return ErrUnqualified
		}
	}
	for _, l := range s.Logs {
		if l.PartnerID <= 0 || l.Kind < 1 || l.Kind > 6 || l.At <= 0 || ((l.Kind == 2 || l.Kind == 3 || l.Kind == 4 || l.Kind == 6) && !c.Has(l.CourseID)) {
			return ErrUnqualified
		}
	}
	return nil
}
func (s *State) Log(c Catalog, p, id, kind, param int64, at time.Time) {
	s.Logs = append([]Log{{p, id, kind, at.Unix(), param}}, s.Logs...)
	if len(s.Logs) > int(c.LogLimit) {
		s.Logs = s.Logs[:c.LogLimit]
	}
}
func Remaining(j *Job, at time.Time) (int64, error) {
	if j == nil {
		return 0, ErrInvalid
	}
	if at.Before(j.StartedAt) {
		return 0, ErrStaleTime
	}
	n := j.Duration - int64(at.Sub(j.StartedAt)/time.Second)
	if n < 0 {
		n = 0
	}
	return n, nil
}
func (s *State) Finish(c Catalog, p int64, h *HeroFacts, at time.Time) (bool, error) {
	a, ok := s.Attendance[p]
	if !ok || a.Job == nil {
		return false, ErrInvalid
	}
	if at.Before(a.Job.StartedAt) {
		return false, ErrStaleTime
	}
	i := h.Index(a.Job.CourseID)
	if i < 0 {
		return false, ErrUnqualified
	}
	old := h.Courses[i].Progress
	n := old + 20
	if n > 100 {
		n = 100
	}
	h.Courses[i].Progress = n
	s.Log(c, p, a.Job.CourseID, 3, n-old, at)
	if n == 100 && old < 100 {
		s.Log(c, p, a.Job.CourseID, 4, 0, at)
	}
	delete(s.Attendance, p)
	return true, nil
}
func (s *State) Settle(c Catalog, p int64, h *HeroFacts, at time.Time) (bool, error) {
	a, ok := s.Attendance[p]
	if !ok || a.Job == nil {
		return false, nil
	}
	left, e := Remaining(a.Job, at)
	if e != nil {
		return false, e
	}
	if left > 0 {
		return false, nil
	}
	return s.Finish(c, p, h, a.Job.StartedAt.Add(time.Duration(a.Job.Duration)*time.Second))
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

func RecordWire(r Record) map[string]any {
	return map[string]any{"progress": r.Progress, "quality": r.Quality, "add_skill": r.Skill, "exp": r.EXP}
}
func HeroWire(h HeroFacts) map[string]any {
	out := map[string]any{}
	for _, r := range h.Courses {
		out[strconv.FormatInt(r.ID, 10)] = RecordWire(r)
	}
	return out
}
