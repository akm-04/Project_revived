package events

import "time"

// Phase is the occurrence's state at an instant, derived from stored instants
// (I11A_EVENTS_V1 ruling 3); only settlement is a job.
type Phase string

const (
	PhaseScheduled   Phase = "SCHEDULED"
	PhaseRunning     Phase = "RUNNING"
	PhaseClaimWindow Phase = "CLAIM_WINDOW"
	PhaseEnded       Phase = "ENDED"
	PhaseArchived    Phase = "ARCHIVED"
	PhaseCancelled   Phase = "CANCELLED"
)

// Occurrence is one scheduled run of an activity revision on a logical server
// (ruling 2, EA-1). EndsAt nil means permanent.
type Occurrence struct {
	ID                  int64
	LogicalServerID     int64
	ActivityID          int64
	DefinitionRevision  int64
	StartsAt            time.Time
	EndsAt              *time.Time
	ClaimUntil          *time.Time
	Source              string
	Revision            int64
	CreatedByCommand    string
	EndedEarlyByCommand string
	CancelledByCommand  string
	CancelledAt         *time.Time
	SettledAt           *time.Time
	CreatedAt           time.Time
}

// State computes the phase from the stored instants. CANCELLED wins because a
// cancelled occurrence never runs; settlement (ARCHIVED) wins over time because
// it records that the settlement job finished.
func (occurrence Occurrence) State(now time.Time) Phase {
	if occurrence.CancelledAt != nil {
		return PhaseCancelled
	}
	if occurrence.SettledAt != nil {
		return PhaseArchived
	}
	if now.Before(occurrence.StartsAt) {
		return PhaseScheduled
	}
	if occurrence.EndsAt == nil {
		return PhaseRunning
	}
	if now.Before(*occurrence.EndsAt) {
		return PhaseRunning
	}
	if occurrence.ClaimUntil != nil && now.Before(*occurrence.ClaimUntil) {
		return PhaseClaimWindow
	}
	return PhaseEnded
}

// Active reports RUNNING or CLAIM_WINDOW: the states a claim or a rule modifier
// may use (EA-7).
func (occurrence Occurrence) Active(now time.Time) bool {
	phase := occurrence.State(now)
	return phase == PhaseRunning || phase == PhaseClaimWindow
}

// Permanent reports an occurrence with no end instant (EA-1).
func (occurrence Occurrence) Permanent() bool {
	return occurrence.EndsAt == nil
}
