package events

import "time"

// GlobalGroup is one event scheduled across every current logical server
// (EA-15). EndsAt nil means permanent; EndedAt is set by events.end_now and no
// server joins after it.
type GlobalGroup struct {
	ID                 int64
	ActivityID         int64
	DefinitionRevision int64
	StartsAt           time.Time
	EndsAt             *time.Time
	State              string
	Revision           int64
	CreatedAt          time.Time
	EndedAt            *time.Time
	CreatedByCommand   string
}

const (
	GroupScheduled = "SCHEDULED"
	GroupRunning   = "RUNNING"
	GroupEnded     = "ENDED"
)

// Phase derives the group state from its instants, like an occurrence. The
// group has no claim window of its own; its occurrences carry theirs.
func (group GlobalGroup) Phase(now time.Time) Phase {
	if group.EndedAt != nil || (group.EndsAt != nil && !now.Before(*group.EndsAt)) {
		return PhaseEnded
	}
	if now.Before(group.StartsAt) {
		return PhaseScheduled
	}
	return PhaseRunning
}

// Joinable reports whether a server without a group occurrence should get one:
// a SCHEDULED or RUNNING group that has not been ended (EA-15 item 4).
func (group GlobalGroup) Joinable(now time.Time) bool {
	phase := group.Phase(now)
	return phase == PhaseScheduled || phase == PhaseRunning
}
