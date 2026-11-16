// Package undelivered is the persistence boundary for an edge-replay cache: the
// latest committed reply an HTTP write could not deliver. It is not gameplay
// authority; a missing or unusable mark falls back to ordinary dispatch.
package undelivered

import (
	"context"
	"errors"
	"time"
)

// Metric names shared by the edge (marking) and the replay guard.
const (
	MarksTotal        = "undelivered_marks_total"
	MarkFailuresTotal = "undelivered_mark_failures_total"
	ReplaysTotal      = "undelivered_replays_total"
)

// ErrSuperseded reports a mark write whose claim a later state request took, so
// the reply must be dropped instead of restoring an invalidated reply.
var ErrSuperseded = errors.New("undelivered: mark superseded")

// Mark is one player's undelivered success reply. Claim is the fence the
// request took before dispatch; a mark is stored only while it still holds.
type Mark struct {
	PlayerID    int64
	Claim       int64
	SessionID   string
	MID         int64
	Fingerprint [32]byte
	Reply       []byte
	MarkedAt    time.Time
}

// Take is the claim one state request holds for its dispatch plus the mark the
// previous state request left, if any.
type Take struct {
	Claim   int64
	Mark    Mark
	HasMark bool
}

// Marker records a mark after a failed reply write.
type Marker interface {
	Mark(context.Context, Mark) error
}

// Taker locks the player's row, takes the next claim and returns the displaced
// mark in one statement, so concurrent identical resends hand a mark to exactly
// one caller and a later take fences an earlier request's late mark.
type Taker interface {
	TakeMark(context.Context, int64) (Take, error)
}
