package adventure

import (
	"encoding/binary"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// Occurrence is one player's live or finished adventure event. Its end is the
// occurrence time plus the event time_limit (C3), and the row is insert-only.
type Occurrence struct {
	PlayerID   identity.PlayerID `json:"player_id"`
	EventType  int64             `json:"event_type"`
	OccurredAt time.Time         `json:"occurred_at"`
	EndTime    time.Time         `json:"end_time"`
	SourceKey  string            `json:"source_key"`
}

func NewOccurrence(factKey string, player identity.PlayerID, event Event, at time.Time) (Occurrence, error) {
	if strings.TrimSpace(factKey) == "" || !player.Valid() || at.IsZero() || event.TimeLimitSeconds <= 0 {
		return Occurrence{}, ErrInvalid
	}
	if _, ok := Profile(event.ID); !ok {
		return Occurrence{}, ErrInvalid
	}
	occurred := at.UTC()
	return Occurrence{
		PlayerID:   player,
		EventType:  event.ID,
		OccurredAt: occurred,
		EndTime:    occurred.Add(time.Duration(event.TimeLimitSeconds) * time.Second),
		SourceKey:  factKey,
	}, nil
}

func (o Occurrence) Validate() error {
	if !o.PlayerID.Valid() || strings.TrimSpace(o.SourceKey) == "" || o.OccurredAt.IsZero() {
		return ErrInvalid
	}
	event, ok := Profile(o.EventType)
	if !ok {
		return ErrInvalid
	}
	if !o.EndTime.Equal(o.OccurredAt.Add(time.Duration(event.TimeLimitSeconds) * time.Second)) {
		return ErrInvalid
	}
	return nil
}

// Active is true strictly before the end; C3 refuses reads at and after it.
func (o Occurrence) Active(at time.Time) bool { return at.Before(o.EndTime) }

func RequireActive(o Occurrence, at time.Time) error {
	if !o.Active(at) {
		return ErrExpired
	}
	return nil
}

func ActiveOfType(occurrences []Occurrence, eventType int64, at time.Time) (Occurrence, bool) {
	for _, occurrence := range occurrences {
		if occurrence.EventType == eventType && occurrence.Active(at) {
			return occurrence, true
		}
	}
	return Occurrence{}, false
}

// CanTrigger enforces one active occurrence per event type.
func CanTrigger(occurrences []Occurrence, event Event, at time.Time) bool {
	_, active := ActiveOfType(occurrences, event.ID, at)
	return !active
}

func ActiveTypes(occurrences []Occurrence, at time.Time) map[int64]struct{} {
	active := make(map[int64]struct{}, len(occurrences))
	for _, occurrence := range occurrences {
		if occurrence.Active(at) {
			active[occurrence.EventType] = struct{}{}
		}
	}
	return active
}

// Roll draws the table-rate trigger once per fact business key. The result is
// stable across transaction retries because operation.Context is stable.
func Roll(event Event, factKey string, op operation.Context) (bool, error) {
	if strings.TrimSpace(factKey) == "" || event.Rate < 0 || event.Rate > MaxTriggerRate {
		return false, ErrInvalid
	}
	digest := op.Derive("adventure.trigger/v1/"+factKey, 0)
	return binary.BigEndian.Uint64(digest[:8])%MaxTriggerRate < uint64(event.Rate), nil
}
