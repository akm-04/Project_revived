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

// ErrOvertaken is an observation whose decision time is older than the stored
// row. A producer that raced a newer accepted command must be refused as stale
// state, not reported as corruption.
var ErrOvertaken = errors.New("achievement: observation overtaken by a newer fact")

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
	// The domain layer cannot import the application helper (I0 import matrix),
	// so the effective observation is computed locally for this read guard.
	observedAt := at
	if r.UpdatedAt.After(observedAt) {
		observedAt = r.UpdatedAt
	}
	if r.Validate() != nil || c.Validate() != nil || n < 1 || n > 9007199254740991 || observedAt.Before(r.UpdatedAt) {
		return Root{}, false, ErrConflict
	}
	old := r.Progress
	times := r.CompleteTimes
	for j, target := range c.Rows[13].Thresholds {
		inst := objective.Instance{PlayerID: r.PlayerID, ProgramID: Policy, ObjectiveID: int64(j + 1), DefinitionRevision: Policy, ContentRevision: r.ContentRevision, Progress: r.Progress, CompletedAt: times[j], ClaimState: objective.Unclaimed, StateVersion: r.StateVersion}
		def := objective.Definition{ProgramID: Policy, ObjectiveID: int64(j + 1), DefinitionRevision: Policy, Strategy: objective.HighWaterFromCanonicalState, AcceptedFactKind: "MARRIED_HERO_POPULATION", Target: target}
		fact := objective.Fact{PlayerID: r.PlayerID, SourceDomain: "Library", SourceBusinessKey: "validated-prepared-source-transition", Kind: def.AcceptedFactKind, Value: n}
		v, _, e := objective.ApplyFact(inst, def, fact, observedAt)
		if e != nil {
			return Root{}, false, e
		}
		r.CompleteTimes[j] = v.CompletedAt
	}
	if n > old {
		r.Progress = n
		r.StateVersion++
		r.UpdatedAt = observedAt.UTC()
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
type Level struct {
	ID             int64      `json:"id"`
	PointCondition int64      `json:"point_condition"`
	Items          [][2]int64 `json:"items"`
}
type Catalog struct {
	SchemaVersion int          `json:"schema_version"`
	PolicyID      string       `json:"policy_id"`
	SelectedID    int64        `json:"selected_id"`
	Rows          []Definition `json:"rows"`
	Levels        []Level      `json:"levels,omitempty"`
}

func (c Catalog) Validate() error {
	levelsPresent := c.SchemaVersion == 2 && len(c.Levels) == 10 || c.SchemaVersion == 1 && len(c.Levels) == 0
	if !levelsPresent || c.PolicyID != "C4B_MARRIED_POPULATION_TIER_FACTS_V1" || c.SelectedID != 100014 || len(c.Rows) != 33 {
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
	for i, l := range c.Levels {
		if l.ID != int64(i+1) || i == 0 && (l.PointCondition != 0 || len(l.Items) != 0) || i > 0 && (l.PointCondition <= c.Levels[i-1].PointCondition || len(l.Items) == 0) {
			return errors.New("achievement level")
		}
		for _, item := range l.Items {
			if item[0] <= 0 || item[1] <= 0 {
				return errors.New("achievement level item")
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
	// FactCountPolicy covers the I9-11E facts whose producer settles a bounded
	// count inside its own transaction; it is not an owner-value read.
	FactCountPolicy = "I9_11E_ACHIEVEMENT_FACT_V1"
)

type streakProfile struct {
	policy     string
	thresholds [3]int64
	// step is the distance between consecutive periods; 0 counts directly.
	step int64
}

var streakProfiles = map[int64]streakProfile{
	LeagueDaysID:        {"C5F_LEAGUE_TOP5_DAYS_V2", [3]int64{1, 3, 7}, 0},
	GuildDamageID:       {OwnedStatePolicy, [3]int64{100, 500, 1000}, 0},
	SkyTowerID:          {OwnedStatePolicy, [3]int64{50, 80, 100}, 0},
	CampaignStarsID:     {OwnedStatePolicy, [3]int64{100, 600, 1200}, 0},
	SchoolStoriesID:     {OwnedStatePolicy, [3]int64{1, 15, 30}, 0},
	GraduatedStudentsID: {OwnedStatePolicy, [3]int64{1, 3, 5}, 0},
	MemoirFloorsID:      {OwnedStatePolicy, [3]int64{1, 2, 3}, 0},
	OccultChaptersID:    {OwnedStatePolicy, [3]int64{1, 3, 5}, 0},
	TitanID:             {OwnedStatePolicy, [3]int64{1, 5, 10}, 0},
	NormalHeroesID:      {OwnedStatePolicy, [3]int64{10, 50, 150}, 0},
	AwakenedHeroesID:    {OwnedStatePolicy, [3]int64{1, 30, 50}, 0},
	SkinsID:             {OwnedStatePolicy, [3]int64{1, 10, 20}, 0},
	PetsID:              {OwnedStatePolicy, [3]int64{2, 8, 15}, 0},
	TextbooksID:         {OwnedStatePolicy, [3]int64{1, 15, 30}, 0},
	RegionsID:           {OwnedStatePolicy, [3]int64{1, 3, 5}, 0},
	SubjectsID:          {OwnedStatePolicy, [3]int64{50, 200, 500}, 0},
	SuitsID:             {OwnedStatePolicy, [3]int64{1, 15, 30}, 0},
	RoomsID:             {OwnedStatePolicy, [3]int64{5, 10, 15}, 0},
	ExpandedRoomsID:     {OwnedStatePolicy, [3]int64{5, 10, 15}, 0},
	// achievement.lua rows 100006/100007/100012: 1/3/6 bosses, 1/3/6 bosses,
	// 3/4/5 girls in one "buy 10".
	FantasyTopRankID: {FactCountPolicy, [3]int64{1, 3, 6}, 0},
	FantasyDamageID:  {FactCountPolicy, [3]int64{1, 3, 6}, 0},
	// 100011 is day-scoped: progress falls with a new day's first count; its
	// thresholds come from the catalog row, not this profile.
	GreatCustomerID:  {FactCountPolicy, [3]int64{}, 0},
	MediumTenPullID:  {FactCountPolicy, [3]int64{3, 4, 5}, 0},
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
	if s.Validate() != nil || c.Validate() != nil || index < 0 || index >= int64(len(c.Rows)) {
		return profile, ErrConflict
	}
	observedAt := at
	if s.UpdatedAt.After(observedAt) {
		observedAt = s.UpdatedAt
	}
	if observedAt.Before(s.UpdatedAt) {
		return profile, ErrOvertaken
	}
	if s.AchievementID != GreatCustomerID && c.Rows[index].Thresholds != profile.thresholds {
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
	if err != nil {
		return Streak{}, false, err
	}
	if profile.step == 0 {
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

// ObserveHighWater records the best counted value ever seen; a lower later
// observation leaves both progress and earned tiers alone.
func (s Streak) ObserveHighWater(c Catalog, count int64, at time.Time) (Streak, bool, error) {
	profile, err := s.profile(c, at)
	if err != nil {
		return Streak{}, false, err
	}
	if profile.step != 0 || count < 0 {
		return Streak{}, false, ErrConflict
	}
	if count <= s.Current {
		return s, false, nil
	}
	s = s.advance(profile, count, s.effectiveObservation(at))
	return s, true, s.Validate()
}

// ObserveDailyCount records today's day-scoped count. Progress may fall when a
// new day restarts the count; earned tiers are never cleared. The targets are
// the pinned catalog row's thresholds, never constants.
func (s Streak) ObserveDailyCount(c Catalog, count int64, at time.Time) (Streak, bool, error) {
	profile, err := s.profile(c, at)
	if err != nil {
		return Streak{}, false, err
	}
	if profile.step != 0 || count < 0 {
		return Streak{}, false, ErrConflict
	}
	if count == s.Current {
		return s, false, nil
	}
	profile.thresholds = c.Rows[s.AchievementID-c.Rows[0].ID].Thresholds
	s = s.advance(profile, count, s.effectiveObservation(at))
	return s, true, s.Validate()
}

// effectiveObservation keeps a writer's timestamps monotone after a clock
// rollback (the application helper is not importable from the domain layer).
func (s Streak) effectiveObservation(at time.Time) time.Time {
	observedAt := at
	if s.UpdatedAt.After(observedAt) {
		observedAt = s.UpdatedAt
	}
	if s.CreatedAt.After(observedAt) {
		observedAt = s.CreatedAt
	}
	return observedAt
}

// ObserveCount records a counted streak's current value.
func (s Streak) ObserveCount(c Catalog, count int64, at time.Time) (Streak, bool, error) {
	profile, err := s.profile(c, at)
	if err != nil {
		return Streak{}, false, err
	}
	if profile.step != 0 || count < 0 {
		return Streak{}, false, ErrConflict
	}
	if count == s.Current {
		return s, false, nil
	}
	s = s.advance(profile, count, s.effectiveObservation(at))
	return s, true, s.Validate()
}
