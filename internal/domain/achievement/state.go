package achievement

import (
	"encoding/hex"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"time"
)

const Policy = "C4B_MARRIED_POPULATION_TIER_FACTS_V1"
const SelectedID int64 = 100014

var ErrUnavailable = errors.New("achievement: unavailable history or producer")
var ErrConflict = errors.New("achievement: conflicting fact or coherent scope")

func RevisionValid(s string) bool {
	b, e := hex.DecodeString(s)
	return e == nil && len(b) == 32 && hex.EncodeToString(b) == s
}

type Root struct {
	PlayerID             identity.PlayerID
	ContentRevision      string
	PolicyID             string
	Progress             int64
	CompleteTimes        [3]*time.Time
	StateVersion         int64
	CreatedAt, UpdatedAt time.Time
}

func NewRoot(pid identity.PlayerID, rev string, at time.Time) (Root, error) {
	r := Root{PlayerID: pid, ContentRevision: rev, PolicyID: Policy, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
	return r, r.Validate()
}
func (r Root) Validate() error {
	if !r.PlayerID.Valid() || !RevisionValid(r.ContentRevision) || r.PolicyID != Policy || r.Progress < 0 || r.Progress > 9007199254740991 || r.StateVersion < 1 || r.CreatedAt.Unix() <= 0 || r.UpdatedAt.Before(r.CreatedAt) {
		return ErrConflict
	}
	for i, n := range [3]int64{1, 10, 20} {
		t := r.CompleteTimes[i]
		if (t != nil) != (r.Progress >= n) {
			return ErrConflict
		}
		if t != nil && (t.Unix() <= 0 || t.Before(r.CreatedAt) || t.After(r.UpdatedAt) || i > 0 && r.CompleteTimes[i-1].After(*t)) {
			return ErrConflict
		}
	}
	return nil
}

// ObservePopulation reuses I5's pure objective reducer; Achievement remains the
// sole persistence owner. No I5 stock-family rows or award claims are created.
func (r Root) ObservePopulation(c Catalog, n int64, at time.Time) (Root, bool, error) {
	if r.Validate() != nil || c.Validate() != nil || n < 1 || n > 9007199254740991 || at.Before(r.UpdatedAt) {
		return Root{}, false, ErrConflict
	}
	old := r.Progress
	times := r.CompleteTimes
	for j, target := range c.Rows[13].Thresholds {
		inst := objective.Instance{PlayerID: r.PlayerID, ProgramID: Policy, ObjectiveID: int64(j + 1), DefinitionRevision: Policy, ContentRevision: r.ContentRevision, Progress: r.Progress, CompletedAt: times[j], ClaimState: objective.Unclaimed, StateVersion: r.StateVersion}
		def := objective.Definition{ProgramID: Policy, ObjectiveID: int64(j + 1), DefinitionRevision: Policy, Strategy: objective.HighWaterFromCanonicalState, AcceptedFactKind: "MARRIED_HERO_POPULATION", Target: target}
		fact := objective.Fact{PlayerID: r.PlayerID, SourceDomain: "Library", SourceBusinessKey: "validated-prepared-source-transition", Kind: def.AcceptedFactKind, Value: n}
		v, _, e := objective.ApplyFact(inst, def, fact, at)
		if e != nil {
			return Root{}, false, e
		}
		r.CompleteTimes[j] = v.CompletedAt
	}
	if n > old {
		r.Progress = n
		r.StateVersion++
		r.UpdatedAt = at.UTC()
	}
	return r, n > old, r.Validate()
}

type Definition struct {
	ID         int64    `json:"id"`
	Thresholds [3]int64 `json:"thresholds"`
	Points     [3]int64 `json:"points"`
	Daily      int      `json:"daily"`
	Hidden     int      `json:"hidden"`
	Stamp      int      `json:"stamp"`
}
type Catalog struct {
	SchemaVersion int          `json:"schema_version"`
	PolicyID      string       `json:"policy_id"`
	SelectedID    int64        `json:"selected_id"`
	Rows          []Definition `json:"rows"`
}

func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C4B_MARRIED_POPULATION_TIER_FACTS_V1" || c.SelectedID != 100014 || len(c.Rows) != 33 {
		return errors.New("achievement catalog profile")
	}
	for i, r := range c.Rows {
		if r.ID != 100001+int64(i) || r.Daily < 0 || r.Daily > 1 || r.Hidden < 0 || r.Hidden > 1 || r.Stamp < 0 || r.Stamp > 1 {
			return errors.New("achievement source row")
		}
		for j, v := range r.Thresholds {
			if v < 1 || j > 0 && v <= r.Thresholds[j-1] || r.Points[j] <= 0 {
				return errors.New("achievement tier")
			}
		}
	}
	if c.Rows[13].Thresholds != [3]int64{1, 10, 20} || c.Rows[13].Daily != 0 {
		return errors.New("achievement selected profile")
	}
	return nil
}

// Scoped I7C-5B/5C/5D amendments: streak producers. Tiers are never revoked.
// 100001 Top Floor Challenger: consecutive daily 21:00 snapshots in the top 3 (3/6/10).
// 100002 1 on 1 Dominator: consecutive Sunday 22:00 snapshots with server rank <= 3 (1/2/3 weeks).
// 100028 1 on 1 Smash 'em all: a running attack-match win streak (5/15/30).
// 100003 Arena Skilled Master: a running ranked Arena attack win streak (5/15/30).
const (
	TopFloorStreakID int64 = 100001
	WeeklyStreakID   int64 = 100002
	WinStreakID      int64 = 100028
	ArenaStreakID    int64 = 100003
	LeagueDaysID     int64 = 100032
	StreakTopRank    int64 = 3
)

type streakProfile struct {
	policy     string
	thresholds [3]int64
	// step is the distance between consecutive periods; 0 counts directly.
	step int64
}

var streakProfiles = map[int64]streakProfile{
	LeagueDaysID:     {"C5F_LEAGUE_TOP5_DAYS_V2", [3]int64{1, 3, 7}, 0},
	TopFloorStreakID: {"C5B_TOP_FLOOR_CHALLENGER_STREAK_V1", [3]int64{3, 6, 10}, 1},
	WeeklyStreakID:   {"C5C_ONE_ON_ONE_DOMINATOR_STREAK_V1", [3]int64{1, 2, 3}, 7},
	WinStreakID:      {"C5C_ONE_ON_ONE_WIN_STREAK_V1", [3]int64{5, 15, 30}, 0},
	ArenaStreakID:    {"C5D_ARENA_WIN_STREAK_V1", [3]int64{5, 15, 30}, 0},
}

func StreakPolicy(id int64) string { return streakProfiles[id].policy }

type Streak struct {
	PlayerID             identity.PlayerID
	AchievementID        int64
	ContentRevision      string
	Current              int64
	LastDay              *int64
	CompleteTimes        [3]*time.Time
	StateVersion         int64
	CreatedAt, UpdatedAt time.Time
}

func NewStreak(pid identity.PlayerID, id int64, rev string, at time.Time) (Streak, error) {
	s := Streak{PlayerID: pid, AchievementID: id, ContentRevision: rev, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
	return s, s.Validate()
}

func (s Streak) Validate() error {
	profile, known := streakProfiles[s.AchievementID]
	periodic := profile.step > 0
	if !known || !s.PlayerID.Valid() || !RevisionValid(s.ContentRevision) || s.Current < 0 || periodic && s.Current > 0 && s.LastDay == nil || !periodic && s.LastDay != nil ||
		s.StateVersion < 1 || s.CreatedAt.Unix() <= 0 || s.UpdatedAt.Before(s.CreatedAt) {
		return ErrConflict
	}
	for i, t := range s.CompleteTimes {
		if t != nil && (t.Before(s.CreatedAt) || t.After(s.UpdatedAt) || i > 0 && s.CompleteTimes[i-1] == nil) {
			return ErrConflict
		}
	}
	return nil
}

func (s Streak) profile(c Catalog, at time.Time) (streakProfile, error) {
	profile := streakProfiles[s.AchievementID]
	index := s.AchievementID - c.Rows[0].ID
	if s.Validate() != nil || c.Validate() != nil || index < 0 || index >= int64(len(c.Rows)) || c.Rows[index].Thresholds != profile.thresholds || at.Before(s.UpdatedAt) {
		return profile, ErrConflict
	}
	return profile, nil
}

func (s Streak) advance(profile streakProfile, next int64, at time.Time) Streak {
	stamp := at.UTC()
	for i, target := range profile.thresholds {
		if s.CompleteTimes[i] == nil && next >= target {
			s.CompleteTimes[i] = &stamp
		}
	}
	s.Current = next
	s.StateVersion++
	s.UpdatedAt = stamp
	return s
}

// ObserveDay applies one settled period (a day number); a period at or before
// the last observed one is a no-op.
func (s Streak) ObserveDay(c Catalog, day int64, top bool, at time.Time) (Streak, bool, error) {
	profile, err := s.profile(c, at)
	if err != nil || profile.step == 0 {
		return Streak{}, false, ErrConflict
	}
	if s.LastDay != nil && day <= *s.LastDay {
		return s, false, nil
	}
	next := int64(0)
	if top {
		next = 1
		if s.LastDay != nil && *s.LastDay == day-profile.step {
			next = s.Current + 1
		}
	}
	s = s.advance(profile, next, at)
	s.LastDay = &day
	return s, true, s.Validate()
}

// ObserveCount records a counted streak's current value.
func (s Streak) ObserveCount(c Catalog, count int64, at time.Time) (Streak, bool, error) {
	profile, err := s.profile(c, at)
	if err != nil || profile.step != 0 || count < 0 {
		return Streak{}, false, ErrConflict
	}
	if count == s.Current {
		return s, false, nil
	}
	s = s.advance(profile, count, at)
	return s, true, s.Validate()
}
