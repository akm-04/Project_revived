package events

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"strconv"
	"strings"
	"time"
)

// Duration is a schedule/extend span (ruling 5, EA-1).
type Duration struct {
	Permanent bool
	Span      time.Duration
	Text      string
}

// ErrInvalidDuration is a span that is not one of the shipped forms.
var ErrInvalidDuration = errors.New("events: invalid duration")

// ParseDuration accepts the five shipped spans, custom whole hours and
// "permanent".
func ParseDuration(text string) (Duration, error) {
	if text == "permanent" {
		return Duration{Permanent: true, Text: text}, nil
	}
	switch text {
	case "1d", "3d", "7d", "14d", "30d":
		days, _ := strconv.Atoi(strings.TrimSuffix(text, "d"))
		return Duration{Span: time.Duration(days) * 24 * time.Hour, Text: text}, nil
	}
	hoursText, found := strings.CutSuffix(text, "h")
	if !found {
		return Duration{}, fmt.Errorf("%w: %q is not 1d, 3d, 7d, 14d, 30d, <hours>h or permanent", ErrInvalidDuration, text)
	}
	hours, err := strconv.Atoi(hoursText)
	if err != nil || hours < 1 || hours > 24*365 {
		return Duration{}, fmt.Errorf("%w: custom hours must be 1 to %d", ErrInvalidDuration, 24*365)
	}
	return Duration{Span: time.Duration(hours) * time.Hour, Text: text}, nil
}

// ErrInvalidCycle is the default-cycle body refusing validation (ruling 8).
var ErrInvalidCycle = errors.New("events: invalid cycle")

// CycleEntry is one slot of the duration loop. The loop has no gaps: a slot
// starts when the previous one ends.
type CycleEntry struct {
	ActivityID int64  `json:"activity_id"`
	Duration   string `json:"duration"`
}

// Cycle is the shipped default-cycle body (ruling 8): an anchor instant and a
// duration loop. Its revision is monotonic when an operator replaces it.
type Cycle struct {
	Revision int64        `json:"revision"`
	Anchor   time.Time    `json:"anchor"`
	Entries  []CycleEntry `json:"entries"`
}

// ParseCycle decodes the one strict JSON value a cycle body holds.
func ParseCycle(raw []byte) (Cycle, error) {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	var cycle Cycle
	if err := decoder.Decode(&cycle); err != nil {
		return Cycle{}, fmt.Errorf("%w: %v", ErrInvalidCycle, err)
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return Cycle{}, fmt.Errorf("%w: trailing data after the cycle", ErrInvalidCycle)
	}
	if err := cycle.Validate(); err != nil {
		return Cycle{}, err
	}
	return cycle, nil
}

// Validate refuses a cycle the materialiser could not schedule.
func (cycle Cycle) Validate() error {
	if cycle.Revision <= 0 {
		return fmt.Errorf("%w: revision must be positive", ErrInvalidCycle)
	}
	if cycle.Anchor.IsZero() {
		return fmt.Errorf("%w: anchor is required", ErrInvalidCycle)
	}
	if len(cycle.Entries) < 1 || len(cycle.Entries) > 50 {
		return fmt.Errorf("%w: a cycle needs one to fifty entries", ErrInvalidCycle)
	}
	for index, entry := range cycle.Entries {
		if entry.ActivityID <= 0 || entry.ActivityID > math.MaxInt32 {
			return fmt.Errorf("%w: entry %d activity_id must be a client table id", ErrInvalidCycle, index)
		}
		duration, err := ParseDuration(entry.Duration)
		if err != nil {
			return fmt.Errorf("%w: entry %d: %v", ErrInvalidCycle, index, err)
		}
		if duration.Permanent {
			return fmt.Errorf("%w: entry %d cannot be permanent", ErrInvalidCycle, index)
		}
	}
	return nil
}

// Body is the canonical stored form.
func (cycle Cycle) Body() ([]byte, error) {
	return json.Marshal(cycle)
}

// Slot is one materialisable cycle occurrence (ruling 8). ClaimUntil is the
// settings claim window after EndsAt.
type Slot struct {
	ActivityID int64
	StartsAt   time.Time
	EndsAt     time.Time
	ClaimUntil time.Time
}

// NextSlots returns the next count future slots of the loop. A slot whose start
// has strictly passed is skipped, so a late start never backfills the calendar;
// the caller decides which of the returned slots actually run.
func (cycle Cycle) NextSlots(now time.Time, count int, claimWindow time.Duration) []Slot {
	if count <= 0 || claimWindow < 0 || cycle.Anchor.IsZero() || len(cycle.Entries) == 0 {
		return nil
	}
	durations := make([]time.Duration, 0, len(cycle.Entries))
	var loop time.Duration
	for _, entry := range cycle.Entries {
		duration, err := ParseDuration(entry.Duration)
		if err != nil || duration.Permanent {
			return nil
		}
		durations = append(durations, duration.Span)
		loop += duration.Span
	}
	if loop <= 0 {
		return nil
	}
	anchor := cycle.Anchor.UTC()
	start := anchor
	if !anchor.After(now) {
		start = anchor.Add((now.Sub(anchor) / loop) * loop)
	}
	slots := make([]Slot, 0, count)
	for slotStart := start; len(slots) < count; {
		for index, entry := range cycle.Entries {
			slotEnd := slotStart.Add(durations[index])
			if !slotStart.Before(now) {
				slots = append(slots, Slot{ActivityID: entry.ActivityID, StartsAt: slotStart, EndsAt: slotEnd, ClaimUntil: slotEnd.Add(claimWindow)})
				if len(slots) == count {
					return slots
				}
			}
			slotStart = slotEnd
		}
	}
	return slots
}
