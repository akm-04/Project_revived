package occult

import "slices"

const eventLogLimit = 16

// EventRecord is one applied event kept for the room's EVENT push; Sequence
// grows by one per record so a pusher can tell which it already sent.
type EventRecord struct {
	Sequence      int64 `json:"sequence"`
	Type          int64 `json:"type"`
	DispatchLimit int64 `json:"dispatch_limit"`
}

func (s *RunState) RecordEvents(outcomes []EventOutcome) {
	for _, outcome := range outcomes {
		next := int64(1)
		if length := len(s.Events); length > 0 {
			next = s.Events[length-1].Sequence + 1
		}
		s.Events = append(s.Events, EventRecord{Sequence: next, Type: int64(outcome.Type), DispatchLimit: outcome.DispatchLimit})
	}
	if overflow := len(s.Events) - eventLogLimit; overflow > 0 {
		s.Events = slices.Clone(s.Events[overflow:])
	}
}

// WithinLevelBand is the room's level rule: members differ by at most band levels.
func WithinLevelBand(left, right, band int64) bool {
	return left-right <= band && right-left <= band
}

func (s RunState) Invited(playerID int64) bool { return slices.Contains(s.Invites, playerID) }

func (s *RunState) Invite(playerID int64) {
	if !s.Invited(playerID) {
		s.Invites = append(s.Invites, playerID)
	}
}

// MayJoin admits a first-time member before the challenge starts and a returning
// member, who already paid a ticket, once the re-entry wait has passed.
func (s RunState) MayJoin(playerID, at int64) bool {
	if _, left := s.LeftAt[key(playerID)]; !left && s.Started() {
		return false
	}
	return s.CanReenter(playerID, at)
}
