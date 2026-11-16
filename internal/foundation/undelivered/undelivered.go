// Package undelivered is the persistence boundary for an edge-replay cache: the
// latest committed reply an HTTP write could not deliver. It is not gameplay
// authority; a missing or unusable mark falls back to ordinary dispatch.
package undelivered

import (
	"context"
	"time"
)

// Metric names shared by the edge (marking) and the replay guard.
const (
	MarksTotal        = "undelivered_marks_total"
	MarkFailuresTotal = "undelivered_mark_failures_total"
	ReplaysTotal      = "undelivered_replays_total"
)

// Mark is one player's undelivered success reply.
type Mark struct {
	PlayerID    int64
	SessionID   string
	MID         int64
	Fingerprint [32]byte
	Reply       []byte
	MarkedAt    time.Time
}

// Marker records a mark after a failed reply write.
type Marker interface {
	Mark(context.Context, Mark) error
}

// Taker consumes a player's mark in one statement, so concurrent identical
// resends hand it to exactly one caller.
type Taker interface {
	TakeMark(context.Context, int64) (Mark, bool, error)
}
