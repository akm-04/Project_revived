// Package socialrecall owns the pure friend-recall task state machine and
// start/claim planning. Every eligibility fact, source limit and duration is
// supplied by the application owner; this package performs no I/O.
package socialrecall

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
)

var (
	ErrInvalid        = errors.New("social recall: invalid task")
	ErrSelfTarget     = errors.New("social recall: caller cannot recall self")
	ErrServerMismatch = errors.New("social recall: identity outside logical server")
	ErrTime           = errors.New("social recall: invalid time")
	ErrDuration       = errors.New("social recall: invalid duration")
	ErrBaseline       = errors.New("social recall: negative baseline")
	ErrLimits         = errors.New("social recall: invalid limits")
	ErrFacts          = errors.New("social recall: invalid start facts")
	ErrMilestones     = errors.New("social recall: invalid milestones")
)

type Status string

const (
	StatusActive    Status = "ACTIVE"
	StatusCompleted Status = "COMPLETED"
	StatusExpired   Status = "EXPIRED"
)

type Baseline struct {
	AcademyLevel   int64
	OwnedHeroCount int64
	ChargeTotal    int64
}

func (b Baseline) Validate() error {
	if b.AcademyLevel < 0 || b.OwnedHeroCount < 0 || b.ChargeTotal < 0 {
		return ErrBaseline
	}
	return nil
}

type Task struct {
	Caller          identity.PlayerID
	Target          identity.PlayerID
	LogicalServerID identity.LogicalServerID
	OperationID     ids.UUID
	StartedAt       time.Time
	ExpiresAt       time.Time
	Status          Status
	CompletedAt     *time.Time
	Baseline        Baseline
}

func NewTask(caller, target identity.PlayerID, server identity.LogicalServerID, operationID ids.UUID, startedAt time.Time, duration time.Duration, baseline Baseline) (Task, error) {
	started, ok := canonicalTime(startedAt)
	if !ok {
		return Task{}, ErrTime
	}
	if duration <= 0 {
		return Task{}, ErrDuration
	}
	expiresAt := started.Add(duration)
	if !expiresAt.After(started) || expiresAt.Sub(started) != duration {
		return Task{}, ErrDuration
	}
	task := Task{
		Caller:          caller,
		Target:          target,
		LogicalServerID: server,
		OperationID:     operationID,
		StartedAt:       started,
		ExpiresAt:       expiresAt,
		Status:          StatusActive,
		Baseline:        baseline,
	}
	if err := task.Validate(); err != nil {
		return Task{}, err
	}
	return task, nil
}

func (t Task) Validate() error {
	if !t.Caller.Valid() || !t.Target.Valid() {
		return ErrInvalid
	}
	if t.Caller == t.Target {
		return ErrSelfTarget
	}
	if !t.LogicalServerID.Valid() {
		return ErrInvalid
	}
	if logicalserver.PlayerRegion(t.Caller) != t.LogicalServerID || logicalserver.PlayerRegion(t.Target) != t.LogicalServerID {
		return ErrServerMismatch
	}
	if t.OperationID.IsZero() {
		return ErrInvalid
	}
	if !validTime(t.StartedAt) || !validTime(t.ExpiresAt) {
		return ErrTime
	}
	if !t.ExpiresAt.After(t.StartedAt) {
		return ErrDuration
	}
	if err := t.Baseline.Validate(); err != nil {
		return err
	}
	switch t.Status {
	case StatusActive:
		if t.CompletedAt != nil {
			return ErrInvalid
		}
	case StatusCompleted:
		if t.CompletedAt == nil || !validTime(*t.CompletedAt) || t.CompletedAt.Before(t.StartedAt) || !t.CompletedAt.Before(t.ExpiresAt) {
			return ErrInvalid
		}
	case StatusExpired:
		if t.CompletedAt != nil {
			return ErrInvalid
		}
	default:
		return ErrInvalid
	}
	return nil
}

func (t Task) Complete(loginAt time.Time) (Task, bool, error) {
	if err := t.Validate(); err != nil {
		return t, false, err
	}
	completedAt, ok := canonicalTime(loginAt)
	if !ok {
		return t, false, ErrTime
	}
	if t.Status != StatusActive || completedAt.Before(t.StartedAt) || !completedAt.Before(t.ExpiresAt) {
		return t, false, nil
	}
	t.Status = StatusCompleted
	t.CompletedAt = &completedAt
	return t, true, nil
}

func (t Task) Expire(at time.Time) (Task, bool, error) {
	if err := t.Validate(); err != nil {
		return t, false, err
	}
	expiredAt, ok := canonicalTime(at)
	if !ok {
		return t, false, ErrTime
	}
	if t.Status != StatusActive || expiredAt.Before(t.ExpiresAt) {
		return t, false, nil
	}
	t.Status = StatusExpired
	return t, true, nil
}

type Limits struct {
	RequiredOffline time.Duration
	MaxActiveTasks  int
}

func (l Limits) Validate() error {
	if l.RequiredOffline <= 0 || l.MaxActiveTasks < 1 {
		return ErrLimits
	}
	return nil
}

type StartFacts struct {
	Caller           identity.PlayerID
	Target           identity.PlayerID
	LogicalServerID  identity.LogicalServerID
	IsFriend         bool
	TargetAvailable  bool
	TargetReserved   bool
	AlreadyCompleted bool
	OfflineSince     time.Time
}

func CanStart(facts StartFacts, activeTasks int, limits Limits, at time.Time) (bool, error) {
	if err := limits.Validate(); err != nil {
		return false, err
	}
	if !facts.Caller.Valid() || !facts.Target.Valid() || !facts.LogicalServerID.Valid() {
		return false, ErrFacts
	}
	if facts.Caller == facts.Target {
		return false, ErrSelfTarget
	}
	if logicalserver.PlayerRegion(facts.Caller) != facts.LogicalServerID || logicalserver.PlayerRegion(facts.Target) != facts.LogicalServerID {
		return false, ErrServerMismatch
	}
	observedAt, ok := canonicalTime(at)
	if !ok {
		return false, ErrTime
	}
	offlineSince, ok := canonicalTime(facts.OfflineSince)
	if !ok || offlineSince.After(observedAt) || activeTasks < 0 {
		return false, ErrFacts
	}
	if !facts.IsFriend || !facts.TargetAvailable || facts.TargetReserved || facts.AlreadyCompleted || activeTasks >= limits.MaxActiveTasks {
		return false, nil
	}
	return observedAt.Sub(offlineSince) > limits.RequiredOffline, nil
}

type Milestone struct {
	ID        int64
	Threshold int64
}

func Claimable(milestones []Milestone, claimed map[int64]struct{}, achieved int64) ([]int64, error) {
	if achieved < 0 {
		return nil, ErrMilestones
	}
	seen := make(map[int64]struct{}, len(milestones))
	var claimable []int64
	for _, milestone := range milestones {
		if milestone.ID <= 0 || milestone.Threshold < 0 {
			return nil, ErrMilestones
		}
		if _, duplicate := seen[milestone.ID]; duplicate {
			return nil, ErrMilestones
		}
		seen[milestone.ID] = struct{}{}
		if _, done := claimed[milestone.ID]; done || achieved < milestone.Threshold {
			continue
		}
		claimable = append(claimable, milestone.ID)
	}
	return claimable, nil
}

func canonicalTime(value time.Time) (time.Time, bool) {
	if value.IsZero() {
		return time.Time{}, false
	}
	return value.UTC(), true
}

func validTime(value time.Time) bool {
	return !value.IsZero() && value.Location() == time.UTC
}
