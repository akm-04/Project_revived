package socialrecall

import (
	"math"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

var testStart = time.Unix(1_000_000, 0).UTC()

func testOperation(t *testing.T) ids.UUID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}

func validBaseline() Baseline {
	return Baseline{AcademyLevel: 51, OwnedHeroCount: 8, ChargeTotal: 9000}
}

func newTask(t *testing.T) Task {
	t.Helper()
	task, err := NewTask(100001, 100002, 1, testOperation(t), testStart, 3*24*time.Hour, validBaseline())
	if err != nil {
		t.Fatal(err)
	}
	return task
}

func TestNewTaskRejectsInvalidInput(t *testing.T) {
	op := testOperation(t)
	baseline := validBaseline()
	cases := []struct {
		name     string
		caller   identity.PlayerID
		target   identity.PlayerID
		server   identity.LogicalServerID
		op       ids.UUID
		start    time.Time
		duration time.Duration
		baseline Baseline
	}{
		{"zero caller", 0, 100002, 1, op, testStart, time.Hour, baseline},
		{"zero target", 100001, 0, 1, op, testStart, time.Hour, baseline},
		{"self target", 100001, 100001, 1, op, testStart, time.Hour, baseline},
		{"zero server", 100001, 100002, 0, op, testStart, time.Hour, baseline},
		{"caller other server", 200001, 100002, 1, op, testStart, time.Hour, baseline},
		{"target other server", 100001, 200002, 1, op, testStart, time.Hour, baseline},
		{"zero operation", 100001, 100002, 1, ids.UUID{}, testStart, time.Hour, baseline},
		{"zero start", 100001, 100002, 1, op, time.Time{}, time.Hour, baseline},
		{"zero duration", 100001, 100002, 1, op, testStart, 0, baseline},
		{"negative duration", 100001, 100002, 1, op, testStart, -time.Hour, baseline},
		{"overflow duration", 100001, 100002, 1, op, time.Unix(int64(math.MaxInt64)-1000-62_135_596_800, 0).UTC(), time.Duration(math.MaxInt64), baseline},
		{"negative academy level", 100001, 100002, 1, op, testStart, time.Hour, Baseline{AcademyLevel: -1}},
		{"negative hero count", 100001, 100002, 1, op, testStart, time.Hour, Baseline{OwnedHeroCount: -1}},
		{"negative charge", 100001, 100002, 1, op, testStart, time.Hour, Baseline{ChargeTotal: -1}},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			if _, err := NewTask(testCase.caller, testCase.target, testCase.server, testCase.op, testCase.start, testCase.duration, testCase.baseline); err == nil {
				t.Fatal("invalid task accepted")
			}
		})
	}
}

func TestCompletionHalfOpenBoundary(t *testing.T) {
	task := newTask(t)
	expiry := task.ExpiresAt

	before, completed, err := task.Complete(task.StartedAt.Add(-time.Nanosecond))
	if err != nil || completed || before != task {
		t.Fatalf("login before start was not a no-op: %v %v", completed, err)
	}

	atStart, completed, err := task.Complete(task.StartedAt)
	if err != nil || !completed || atStart.Status != StatusCompleted || atStart.CompletedAt == nil || !atStart.CompletedAt.Equal(task.StartedAt) {
		t.Fatalf("login at start did not complete: %v %v", completed, err)
	}

	beforeExpiry, completed, err := task.Complete(expiry.Add(-time.Nanosecond))
	if err != nil || !completed || beforeExpiry.Status != StatusCompleted || !beforeExpiry.CompletedAt.Equal(expiry.Add(-time.Nanosecond)) {
		t.Fatalf("login inside window did not complete: %v %v", completed, err)
	}

	atExpiry, completed, err := task.Complete(expiry)
	if err != nil || completed || atExpiry != task {
		t.Fatalf("login at expiry completed: %v %v", completed, err)
	}
	afterExpiry, completed, err := task.Complete(expiry.Add(time.Nanosecond))
	if err != nil || completed || afterExpiry != task {
		t.Fatalf("login after expiry completed: %v %v", completed, err)
	}
}

func TestExpiryAndRetryBoundaries(t *testing.T) {
	task := newTask(t)
	expiry := task.ExpiresAt

	early, expired, err := task.Expire(expiry.Add(-time.Nanosecond))
	if err != nil || expired || early != task {
		t.Fatalf("expired before expiry: %v %v", expired, err)
	}
	exact, expired, err := task.Expire(expiry)
	if err != nil || !expired || exact.Status != StatusExpired || exact.CompletedAt != nil {
		t.Fatalf("did not expire at expiry: %v %v", expired, err)
	}
	if _, expired, err = exact.Expire(expiry.Add(time.Hour)); err != nil || expired {
		t.Fatalf("expired an expired task again: %v %v", expired, err)
	}
	if _, completed, err := exact.Complete(expiry.Add(-time.Hour)); err != nil || completed {
		t.Fatalf("completed an expired task: %v %v", completed, err)
	}

	retry, completed, err := task.Complete(task.StartedAt)
	if err != nil || !completed {
		t.Fatalf("valid completion failed: %v %v", completed, err)
	}
	again, completed, err := retry.Complete(task.StartedAt.Add(time.Hour))
	if err != nil || completed || again != retry || !again.CompletedAt.Equal(task.StartedAt) {
		t.Fatalf("completion was not idempotent and preserved: %v %v", completed, err)
	}
	if kept, expired, err := retry.Expire(expiry.Add(time.Hour)); err != nil || expired || kept != retry {
		t.Fatalf("completed task expired: %v %v", expired, err)
	}
}

func TestCanStartUsesSuppliedLimitsAndFacts(t *testing.T) {
	limits := Limits{RequiredOffline: 7 * 24 * time.Hour, MaxActiveTasks: 3}
	facts := StartFacts{
		Caller:          100001,
		Target:          100002,
		LogicalServerID: 1,
		IsFriend:        true,
		TargetAvailable: true,
		OfflineSince:    testStart.Add(-7 * 24 * time.Hour),
	}
	allowed, err := CanStart(facts, 2, limits, testStart)
	if err != nil || !allowed {
		t.Fatalf("eligible start refused: %v %v", allowed, err)
	}

	short := facts
	short.OfflineSince = testStart.Add(-7*24*time.Hour + time.Nanosecond)
	if allowed, err = CanStart(short, 2, limits, testStart); err != nil || allowed {
		t.Fatalf("short offline accepted: %v %v", allowed, err)
	}

	blocked := []StartFacts{}
	notFriend := facts
	notFriend.IsFriend = false
	blocked = append(blocked, notFriend)
	unavailable := facts
	unavailable.TargetAvailable = false
	blocked = append(blocked, unavailable)
	reserved := facts
	reserved.TargetReserved = true
	blocked = append(blocked, reserved)
	alreadyCompleted := facts
	alreadyCompleted.AlreadyCompleted = true
	blocked = append(blocked, alreadyCompleted)
	for _, facts := range blocked {
		if allowed, err := CanStart(facts, 2, limits, testStart); err != nil || allowed {
			t.Fatalf("ineligible start accepted: %v %v", allowed, err)
		}
	}

	if allowed, err = CanStart(facts, 3, limits, testStart); err != nil || allowed {
		t.Fatalf("start above cap accepted: %v %v", allowed, err)
	}

	badLimits := Limits{RequiredOffline: 0, MaxActiveTasks: 3}
	if _, err = CanStart(facts, 0, badLimits, testStart); err == nil {
		t.Fatal("zero offline requirement accepted")
	}
	badLimits = Limits{RequiredOffline: time.Hour, MaxActiveTasks: 0}
	if _, err = CanStart(facts, 0, badLimits, testStart); err == nil {
		t.Fatal("zero task cap accepted")
	}

	self := facts
	self.Target = self.Caller
	if _, err = CanStart(self, 0, limits, testStart); err == nil {
		t.Fatal("self start accepted")
	}
	foreign := facts
	foreign.Target = 200002
	if _, err = CanStart(foreign, 0, limits, testStart); err == nil {
		t.Fatal("foreign server start accepted")
	}
	futureOffline := facts
	futureOffline.OfflineSince = testStart.Add(time.Hour)
	if _, err = CanStart(futureOffline, 0, limits, testStart); err == nil {
		t.Fatal("future offline fact accepted")
	}
	if _, err = CanStart(facts, -1, limits, testStart); err == nil {
		t.Fatal("negative active count accepted")
	}
}

func TestClaimableOncePerMilestone(t *testing.T) {
	milestones := []Milestone{{ID: 1, Threshold: 1}, {ID: 2, Threshold: 3}, {ID: 3, Threshold: 5}}

	ids, err := Claimable(milestones, map[int64]struct{}{1: {}}, 3)
	if err != nil || len(ids) != 1 || ids[0] != 2 {
		t.Fatalf("claim planning wrong: %v %v", ids, err)
	}
	ids, err = Claimable(milestones, map[int64]struct{}{1: {}, 2: {}}, 3)
	if err != nil || len(ids) != 0 {
		t.Fatalf("already claimed milestone returned: %v %v", ids, err)
	}
	ids, err = Claimable(milestones, nil, 10)
	if err != nil || len(ids) != 3 {
		t.Fatalf("unclaimed milestones missing: %v %v", ids, err)
	}

	for _, malformed := range [][]Milestone{
		{{ID: 0, Threshold: 1}},
		{{ID: 1, Threshold: -1}},
		{{ID: 1, Threshold: 1}, {ID: 1, Threshold: 2}},
	} {
		if _, err := Claimable(malformed, nil, 1); err == nil {
			t.Fatalf("malformed milestones accepted: %v", malformed)
		}
	}
	if _, err := Claimable(milestones, nil, -1); err == nil {
		t.Fatal("negative achieved value accepted")
	}
}
