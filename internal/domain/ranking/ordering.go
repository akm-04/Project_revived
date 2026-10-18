// Package ranking contains versioned private-server ordering rules. It does not
// own scores, timestamps, cohorts, snapshots, RNG or reward/title settlement.
package ranking

import (
	"errors"
	"sort"
	"time"
)

const (
	MonotonicFirstReach = "MONOTONIC_PROGRESS_FIRST_REACH_V1"
	CurrentFirstReach   = "CURRENT_STAT_FIRST_REACH_V1"
	CurrentObserved     = "CURRENT_STAT_OBSERVED_V1"
	StableID            = "STABLE_SUBJECT_ID_ASC"
	PersistedLottery    = "PERSISTED_LOTTERY_PRIORITY_ASC"
)

var ErrOrdering = errors.New("ranking: incomplete or incompatible ordering basis")

// Scope is explicit even for a global board. Cohort identifies the selected
// population (including any server grouping), never an inferred default.
type Scope struct {
	Kind     string
	ServerID int64
	Cohort   string
}

func (s Scope) valid() bool {
	return s.Cohort != "" && ((s.Kind == "SERVER" && s.ServerID > 0) || (s.Kind == "GLOBAL" && s.ServerID == 0))
}

type Profile struct {
	ID, PolicyVersion, Generation, TieBreak string
	Scope                                   Scope
	ObservedAt                              time.Time
}
type Entry struct {
	SubjectID, Score int64
	ScoreSince       time.Time
	// Basis equals the named profile. First-reach profiles cannot consume a
	// bootstrapped observation timestamp under an achievement-time label.
	Basis, PolicyVersion, Generation string
	Scope                            Scope
	// The owning durable snapshot must retain this optional random draw. A
	// comparator must never flip coins pairwise, which could create rank cycles.
	LotteryPriority *uint64
}

func Order(p Profile, entries []Entry) ([]Entry, error) {
	if !p.Scope.valid() || p.PolicyVersion == "" || p.Generation == "" || p.ObservedAt.IsZero() || (p.ID != MonotonicFirstReach && p.ID != CurrentFirstReach && p.ID != CurrentObserved) || (p.TieBreak != StableID && p.TieBreak != PersistedLottery) {
		return nil, ErrOrdering
	}
	seen := map[int64]bool{}
	out := append([]Entry{}, entries...)
	for _, v := range out {
		if v.SubjectID <= 0 || v.Score < 0 || v.Score > 9007199254740991 || v.ScoreSince.IsZero() || v.ScoreSince.After(p.ObservedAt) || v.Basis != p.ID || v.PolicyVersion != p.PolicyVersion || v.Generation != p.Generation || v.Scope != p.Scope || seen[v.SubjectID] || (p.TieBreak == PersistedLottery && v.LotteryPriority == nil) {
			return nil, ErrOrdering
		}
		seen[v.SubjectID] = true
	}
	sort.Slice(out, func(i, j int) bool {
		a, b := out[i], out[j]
		if a.Score != b.Score {
			return a.Score > b.Score
		}
		if !a.ScoreSince.Equal(b.ScoreSince) {
			return a.ScoreSince.Before(b.ScoreSince)
		}
		if p.TieBreak == PersistedLottery && *a.LotteryPriority != *b.LotteryPriority {
			return *a.LotteryPriority < *b.LotteryPriority
		}
		return a.SubjectID < b.SubjectID
	})
	return out, nil
}
