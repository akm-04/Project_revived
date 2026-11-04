package socialrecall

import "gxb.local/backend/v2/internal/domain/identity"

// Category is the source friend_recall type used to compare one completion
// summary value against that category's milestone thresholds.
type Category int64

const (
	CategoryCompletedTargets Category = 1
	CategoryAcademyLevel     Category = 2
	CategoryOwnedHeroCount   Category = 3
	CategoryCharge           Category = 4
)

const (
	academyLevelBaselineCeiling = 90
	ownedHeroBaselineFloor      = 50
)

// CompletedTarget pairs a durable completed task with the current facts
// observed for its target. Current uses the same Baseline shape so the
// summary subtracts only source-approved deltas.
type CompletedTarget struct {
	Task    Task
	Current Baseline
}

type CompletionSummary struct {
	CompletedTargets int64
	AcademyLevel     int64
	OwnedHeroCount   int64
	ChargeTotal      int64
}

// SummarizeCompleted reproduces the stock summaryDoneFriendsInfo maxima. Every
// maximum starts at zero so a legitimate decrease never yields negative
// progress.
func SummarizeCompleted(caller identity.PlayerID, server identity.LogicalServerID, completed []CompletedTarget) (CompletionSummary, error) {
	if !caller.Valid() || !server.Valid() {
		return CompletionSummary{}, ErrFacts
	}
	summary := CompletionSummary{CompletedTargets: int64(len(completed))}
	targets := make(map[identity.PlayerID]struct{}, len(completed))
	for _, completedTarget := range completed {
		task := completedTarget.Task
		if err := task.Validate(); err != nil {
			return CompletionSummary{}, err
		}
		if task.Status != StatusCompleted || task.Caller != caller || task.LogicalServerID != server {
			return CompletionSummary{}, ErrFacts
		}
		if err := completedTarget.Current.Validate(); err != nil {
			return CompletionSummary{}, err
		}
		if _, duplicate := targets[task.Target]; duplicate {
			return CompletionSummary{}, ErrFacts
		}
		targets[task.Target] = struct{}{}
		if task.Baseline.AcademyLevel <= academyLevelBaselineCeiling && completedTarget.Current.AcademyLevel > summary.AcademyLevel {
			summary.AcademyLevel = completedTarget.Current.AcademyLevel
		}
		if task.Baseline.AcademyLevel > ownedHeroBaselineFloor {
			ownedDelta := completedTarget.Current.OwnedHeroCount - task.Baseline.OwnedHeroCount
			if ownedDelta > summary.OwnedHeroCount {
				summary.OwnedHeroCount = ownedDelta
			}
		}
		chargeDelta := completedTarget.Current.ChargeTotal - task.Baseline.ChargeTotal
		if chargeDelta > summary.ChargeTotal {
			summary.ChargeTotal = chargeDelta
		}
	}
	return summary, nil
}

func (s CompletionSummary) Achieved(category Category) (int64, error) {
	switch category {
	case CategoryCompletedTargets:
		return s.CompletedTargets, nil
	case CategoryAcademyLevel:
		return s.AcademyLevel, nil
	case CategoryOwnedHeroCount:
		return s.OwnedHeroCount, nil
	case CategoryCharge:
		return s.ChargeTotal, nil
	default:
		return 0, ErrMilestones
	}
}

type MilestoneCategory struct {
	Category   Category
	Milestones []Milestone
}

// ClaimableByCategory groups milestones by their source category before
// applying the once-per-milestone rule, so a threshold is never compared with
// another category's summary value.
func ClaimableByCategory(groups []MilestoneCategory, claimed map[int64]struct{}, summary CompletionSummary) ([]int64, error) {
	seen := make(map[int64]struct{})
	var claimable []int64
	for _, group := range groups {
		achieved, err := summary.Achieved(group.Category)
		if err != nil {
			return nil, err
		}
		identifiers, err := Claimable(group.Milestones, claimed, achieved)
		if err != nil {
			return nil, err
		}
		for _, identifier := range identifiers {
			if _, duplicate := seen[identifier]; duplicate {
				return nil, ErrMilestones
			}
			seen[identifier] = struct{}{}
			claimable = append(claimable, identifier)
		}
	}
	return claimable, nil
}
