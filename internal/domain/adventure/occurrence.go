package adventure

import (
	"crypto/sha256"
	"encoding/binary"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// Occurrence is one player's live or finished adventure event. Its end is the
// occurrence time plus the event time_limit (C3), and the row is insert-only.
type Occurrence struct {
	PlayerID    identity.PlayerID `json:"player_id"`
	EventType   int64             `json:"event_type"`
	OccurredAt  time.Time         `json:"occurred_at"`
	EndTime     time.Time         `json:"end_time"`
	SpecialData int64             `json:"special_data"`
	SourceKey   string            `json:"source_key"`
	FinishedAt  *time.Time        `json:"finished_at"`
}

// NewOccurrence fixes the event lifetime (C3) and picks the event's
// server-owned special_data: a shop row, a card row, or the Fantasy boss.
func NewOccurrence(factKey string, player identity.PlayerID, event Event, at time.Time) (Occurrence, error) {
	if strings.TrimSpace(factKey) == "" || !player.Valid() || at.IsZero() || event.TimeLimitSeconds <= 0 {
		return Occurrence{}, ErrInvalid
	}
	if _, ok := Profile(event.ID); !ok {
		return Occurrence{}, ErrInvalid
	}
	occurred := at.UTC()
	return Occurrence{
		PlayerID:    player,
		EventType:   event.ID,
		OccurredAt:  occurred,
		EndTime:     occurred.Add(time.Duration(event.TimeLimitSeconds) * time.Second),
		SpecialData: specialDataFor(factKey, event.ID),
		SourceKey:   factKey,
	}, nil
}

func specialDataFor(factKey string, eventType int64) int64 {
	sum := sha256.Sum256([]byte(factKey))
	choice := binary.BigEndian.Uint64(sum[:8])
	switch eventType {
	case EventShop:
		return 1001 + int64(choice%7)
	case EventSummon:
		return 100001 + int64(choice%72)
	case EventIllusion:
		return IllusionHiddenBoss
	default:
		return 0
	}
}

func (o Occurrence) Validate() error {
	if !o.PlayerID.Valid() || strings.TrimSpace(o.SourceKey) == "" || o.OccurredAt.IsZero() {
		return ErrInvalid
	}
	event, ok := Profile(o.EventType)
	if !ok {
		return ErrInvalid
	}
	if !o.EndTime.Equal(o.OccurredAt.Add(time.Duration(event.TimeLimitSeconds)*time.Second)) || o.SpecialData < 0 {
		return ErrInvalid
	}
	if o.FinishedAt != nil && o.FinishedAt.Before(o.OccurredAt) {
		return ErrInvalid
	}
	return nil
}

// Active is true strictly before the end and only while unfinished; C3
// refuses reads at and after the end.
func (o Occurrence) Active(at time.Time) bool {
	return o.FinishedAt == nil && at.Before(o.EndTime)
}

func (o Occurrence) Finished() bool { return o.FinishedAt != nil }

// Finish marks the occurrence closed once; a second call reports no change.
func (o *Occurrence) Finish(at time.Time) bool {
	if o.FinishedAt != nil || at.IsZero() {
		return false
	}
	finished := at.UTC()
	o.FinishedAt = &finished
	return true
}

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
