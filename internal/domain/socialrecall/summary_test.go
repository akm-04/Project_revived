package socialrecall

import (
	"errors"
	"slices"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func playerID(value int64) identity.PlayerID {
	return identity.PlayerID(value)
}

func completedTarget(t *testing.T, caller, target int64, baseline, current Baseline) CompletedTarget {
	t.Helper()
	task, err := NewTask(
		playerID(caller), playerID(target), 1, testOperation(t),
		testStart, 3*24*time.Hour, baseline,
	)
	if err != nil {
		t.Fatal(err)
	}
	completed, done, err := task.Complete(testStart.Add(time.Hour))
	if err != nil || !done {
		t.Fatalf("task did not complete: %v %v", done, err)
	}
	return CompletedTarget{Task: completed, Current: current}
}

func TestCompletionSummaryMaximaAndBaselineThresholds(t *testing.T) {
	completed := []CompletedTarget{
		completedTarget(t, 100001, 100002, Baseline{AcademyLevel: 90, OwnedHeroCount: 5, ChargeTotal: 100}, Baseline{AcademyLevel: 120, OwnedHeroCount: 6, ChargeTotal: 600}),
		completedTarget(t, 100001, 100003, Baseline{AcademyLevel: 91, OwnedHeroCount: 5, ChargeTotal: 100}, Baseline{AcademyLevel: 200, OwnedHeroCount: 7, ChargeTotal: 1000}),
		completedTarget(t, 100001, 100004, Baseline{AcademyLevel: 51, OwnedHeroCount: 8, ChargeTotal: 100}, Baseline{AcademyLevel: 60, OwnedHeroCount: 20, ChargeTotal: 400}),
		completedTarget(t, 100001, 100005, Baseline{AcademyLevel: 50, OwnedHeroCount: 8, ChargeTotal: 100}, Baseline{AcademyLevel: 55, OwnedHeroCount: 100, ChargeTotal: 500}),
	}
	summary, err := SummarizeCompleted(100001, 1, completed)
	if err != nil {
		t.Fatal(err)
	}
	if summary.CompletedTargets != 4 {
		t.Fatalf("completed target count wrong: %d", summary.CompletedTargets)
	}
	if summary.AcademyLevel != 120 {
		t.Fatalf("academy maximum wrong: %d", summary.AcademyLevel)
	}
	if summary.OwnedHeroCount != 12 {
		t.Fatalf("owned maximum must not sum and must ignore baseline at 50: %d", summary.OwnedHeroCount)
	}
	if summary.ChargeTotal != 900 {
		t.Fatalf("charge maximum wrong: %d", summary.ChargeTotal)
	}
}

func TestCompletionSummaryDecreasesNeverNegative(t *testing.T) {
	completed := []CompletedTarget{
		completedTarget(t, 100001, 100002, Baseline{AcademyLevel: 90, OwnedHeroCount: 10, ChargeTotal: 900}, Baseline{AcademyLevel: 80, OwnedHeroCount: 3, ChargeTotal: 100}),
		completedTarget(t, 100001, 100003, Baseline{AcademyLevel: 51, OwnedHeroCount: 10, ChargeTotal: 900}, Baseline{AcademyLevel: 0, OwnedHeroCount: 4, ChargeTotal: 0}),
	}
	summary, err := SummarizeCompleted(100001, 1, completed)
	if err != nil {
		t.Fatal(err)
	}
	if summary.AcademyLevel != 80 || summary.OwnedHeroCount != 0 || summary.ChargeTotal != 0 {
		t.Fatalf("decrease produced progress: %+v", summary)
	}
}

func TestCompletionSummaryRejectsInvalidTargets(t *testing.T) {
	valid := completedTarget(t, 100001, 100002, validBaseline(), validBaseline())

	duplicate := completedTarget(t, 100001, 100002, validBaseline(), validBaseline())
	if _, err := SummarizeCompleted(100001, 1, []CompletedTarget{valid, duplicate}); !errors.Is(err, ErrFacts) {
		t.Fatalf("duplicate target accepted: %v", err)
	}

	foreign := completedTarget(t, 100003, 100004, validBaseline(), validBaseline())
	if _, err := SummarizeCompleted(100001, 1, []CompletedTarget{foreign}); !errors.Is(err, ErrFacts) {
		t.Fatalf("cross-caller task accepted: %v", err)
	}

	foreignServer, err := NewTask(playerID(200001), playerID(200002), 2, testOperation(t), testStart, time.Hour, validBaseline())
	if err != nil {
		t.Fatal(err)
	}
	foreignServer, done, err := foreignServer.Complete(testStart.Add(time.Minute))
	if err != nil || !done {
		t.Fatalf("foreign server task did not complete: %v %v", done, err)
	}
	if _, err := SummarizeCompleted(200001, 1, []CompletedTarget{{Task: foreignServer, Current: validBaseline()}}); !errors.Is(err, ErrFacts) {
		t.Fatalf("cross-server task accepted: %v", err)
	}

	active, err := NewTask(playerID(100001), playerID(100003), 1, testOperation(t), testStart, time.Hour, validBaseline())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := SummarizeCompleted(100001, 1, []CompletedTarget{{Task: active, Current: validBaseline()}}); !errors.Is(err, ErrFacts) {
		t.Fatalf("non-completed task accepted: %v", err)
	}

	negative := valid
	negative.Current.ChargeTotal = -1
	if _, err := SummarizeCompleted(100001, 1, []CompletedTarget{negative}); !errors.Is(err, ErrBaseline) {
		t.Fatalf("negative current facts accepted: %v", err)
	}
}

func TestClaimableByCategoryGroupsBeforeThresholds(t *testing.T) {
	summary := CompletionSummary{CompletedTargets: 3, AcademyLevel: 95, OwnedHeroCount: 20, ChargeTotal: 250}
	groups := []MilestoneCategory{
		{Category: CategoryCompletedTargets, Milestones: []Milestone{{ID: 100001, Threshold: 2}, {ID: 100002, Threshold: 4}}},
		{Category: CategoryAcademyLevel, Milestones: []Milestone{{ID: 100005, Threshold: 95}, {ID: 100006, Threshold: 100}}},
		{Category: CategoryOwnedHeroCount, Milestones: []Milestone{{ID: 100007, Threshold: 10}}},
		{Category: CategoryCharge, Milestones: []Milestone{{ID: 100011, Threshold: 200}, {ID: 100012, Threshold: 300}}},
	}
	claimed := map[int64]struct{}{100007: {}}
	claimable, err := ClaimableByCategory(groups, claimed, summary)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(claimable, []int64{100001, 100005, 100011}) {
		t.Fatalf("category claim planning wrong: %v", claimable)
	}

	duplicate := append(slices.Clone(groups), MilestoneCategory{Category: CategoryCharge, Milestones: []Milestone{{ID: 100011, Threshold: 200}}})
	if _, err := ClaimableByCategory(duplicate, nil, summary); !errors.Is(err, ErrMilestones) {
		t.Fatalf("duplicate milestone across categories accepted: %v", err)
	}
	if _, err := ClaimableByCategory([]MilestoneCategory{{Category: 99, Milestones: []Milestone{{ID: 1, Threshold: 1}}}}, nil, summary); !errors.Is(err, ErrMilestones) {
		t.Fatalf("unknown category accepted: %v", err)
	}
}
