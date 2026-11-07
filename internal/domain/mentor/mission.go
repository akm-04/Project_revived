package mentor

import (
	"errors"
	"sort"
	"time"
)

const (
	MissionTypeMentor  int64 = 1
	MissionTypeStudent int64 = 2
)

const (
	CategoryGraduated      int64 = 1
	CategoryStudentLevel   int64 = 2
	CategoryStudentBG      int64 = 3
	CategoryBond           int64 = 4
	CategoryJoinClass      int64 = 5
	CategoryOwnLevel       int64 = 6
	CategoryGraduationTest int64 = 7
)

var ErrMission = errors.New("mentor: invalid mission catalog")

// Mission is one teacher_mission source row. Category is server-side only.
type Mission struct {
	ID        int64
	GiftID    int64
	Type      int64
	Category  int64
	Condition int64
	Level     int64
	IsHide    int64
}

func (mission Mission) Validate() error {
	if mission.ID <= 0 || mission.GiftID <= 0 || mission.Condition < 0 || mission.Level < 0 || mission.IsHide != 0 && mission.IsHide != 1 {
		return ErrMission
	}
	validMentor := mission.Type == MissionTypeMentor && mission.Category >= CategoryGraduated && mission.Category <= CategoryBond
	validStudent := mission.Type == MissionTypeStudent && mission.Category >= CategoryJoinClass && mission.Category <= CategoryGraduationTest
	if !validMentor && !validStudent {
		return ErrMission
	}
	return nil
}

// MissionFacts are the owner-supplied high-water facts for one player. They
// never regress, so missions survive the student leaving or graduating.
type MissionFacts struct {
	Graduated            int64
	HighestStudentLevel  int64
	HighestStudentBGs    int64
	HighestBond          int64
	JoinedClass          bool
	OwnLevel             int64
	GraduationTestPassed bool
}

// MissionState is one reply row. Awarded is durable claim state, not progress.
type MissionState struct {
	Mission   Mission
	Progress  int64
	Complete  bool
	Awarded   bool
	AwardedAt *time.Time
}

// ResolveMissions derives the visible list for one mission type. Hidden rows
// are never emitted or grantable (the client filters them itself).
func ResolveMissions(missions []Mission, missionType int64, facts MissionFacts) ([]MissionState, error) {
	if missionType != MissionTypeMentor && missionType != MissionTypeStudent {
		return nil, ErrMission
	}
	out := make([]MissionState, 0, len(missions))
	for _, mission := range missions {
		if mission.Validate() != nil || mission.Type != missionType || mission.IsHide != 0 {
			continue
		}
		progress := facts.progressFor(mission.Category)
		if progress < 0 {
			return nil, ErrMission
		}
		out = append(out, MissionState{Mission: mission, Progress: progress, Complete: progress >= mission.Condition})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Mission.ID < out[j].Mission.ID })
	return out, nil
}

func (facts MissionFacts) progressFor(category int64) int64 {
	switch category {
	case CategoryGraduated:
		return facts.Graduated
	case CategoryStudentLevel:
		return facts.HighestStudentLevel
	case CategoryStudentBG:
		return facts.HighestStudentBGs
	case CategoryBond:
		return facts.HighestBond
	case CategoryJoinClass:
		if facts.JoinedClass {
			return 1
		}
		return 0
	case CategoryOwnLevel:
		return facts.OwnLevel
	case CategoryGraduationTest:
		if facts.GraduationTestPassed {
			return 1
		}
		return 0
	default:
		return -1
	}
}

// MissionsForCategories returns the visible missions whose progress must move
// when a category fact advances.
func MissionsForCategories(missions []Mission, missionType, category int64) []Mission {
	out := make([]Mission, 0)
	for _, mission := range missions {
		if mission.Validate() == nil && mission.Type == missionType && mission.Category == category && mission.IsHide == 0 {
			out = append(out, mission)
		}
	}
	return out
}

// AcceptableApplication reports whether the request would be accepted now.
// It does not read the clock: the caller supplies the authoritative instant.
func AcceptableApplication(rules Rules, at time.Time) error {
	if rules.Validate() != nil || at.IsZero() {
		return ErrTime
	}
	return nil
}

// UnderDailyLimit reports whether one more application is allowed in the
// direction whose stored counter is count.
func UnderDailyLimit(rules Rules, count int64) bool {
	return count >= 0 && count < rules.ApplicationDaily
}

// BreakCooldownActive reports whether the player broke recently enough that a
// new relation is still refused. Only the raiser is punished.
func BreakCooldownActive(rules Rules, brokeAt *time.Time, at time.Time) bool {
	if brokeAt == nil || at.IsZero() || rules.BreakCooldown <= 0 {
		return false
	}
	return at.Before(brokeAt.Add(rules.BreakCooldown))
}

// TerminateAllowed reports whether the relation is old enough to end.
func TerminateAllowed(rules Rules, acceptedAt, at time.Time) bool {
	if at.IsZero() || acceptedAt.IsZero() {
		return false
	}
	return !at.Before(acceptedAt.Add(rules.MinimumRelationAge))
}

// ApplyIntimacy adds the daily bond amount once per day key, clamped to the cap.
func ApplyIntimacy(current, daily, cap int64, lastDay, today string) (int64, bool) {
	if current < 0 || daily <= 0 || cap <= 0 || lastDay == today {
		return current, false
	}
	next := current + daily
	if next > cap {
		next = cap
	}
	return next, next != current
}

// AdvanceHighWater keeps a stored mission progress from regressing.
func AdvanceHighWater(current, candidate int64) int64 {
	if candidate > current {
		return candidate
	}
	return current
}
