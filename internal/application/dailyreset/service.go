// Package dailyreset owns the game-day reset signal: the first successful reply of a new game day carries
// economy_.daily_updates with the client's daily counters, so the stock client clears its reset-sensitive caches.
package dailyreset

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
)

// Counters are the buy counters the client reloads from the economy daily reset.
type Counters struct {
	BuyManaTimes   int64
	BuyEnergyTimes int64
	BuySkillTimes  int64
}

// MarkerStore is the durable per-player record of the last game day the signal was delivered.
type MarkerStore interface {
	// Advance records day and reports whether it is later than the stored one; one atomic conditional write.
	Advance(ctx context.Context, player identity.PlayerID, day int64) (bool, error)
	// Set records day without reporting a transition.
	Set(ctx context.Context, player identity.PlayerID, day int64) error
}

// CounterReader returns today's normalised buy counters.
type CounterReader interface {
	Counters(ctx context.Context, player identity.PlayerID, at time.Time) (Counters, error)
}

// ZeroCounters is the closed product's reader. The buy features do not exist yet, so every counter reads 0,
// the same value MID 1 serves (internal/projection/lobby/shapes.go). The I9-11 buy counters plug in here later.
type ZeroCounters struct{}

func (ZeroCounters) Counters(context.Context, identity.PlayerID, time.Time) (Counters, error) {
	return Counters{}, nil
}

// Service decides whether one reply carries the daily reset signal and with which counter values.
type Service struct {
	Markers  MarkerStore
	Counters CounterReader
}

// Advance reports whether this reply is the player's first successful reply of the game day, and its counters.
// A failure to read the counters does not consume the marker.
func (service Service) Advance(ctx context.Context, player identity.PlayerID, at time.Time) (Counters, bool, error) {
	if service.Markers == nil || !player.Valid() || at.IsZero() {
		return Counters{}, false, nil
	}
	counters, err := service.counters(ctx, player, at)
	if err != nil {
		return Counters{}, false, err
	}
	advanced, err := service.Markers.Advance(ctx, player, modes.Day(at))
	if err != nil || !advanced {
		return Counters{}, false, err
	}
	return counters, true, nil
}

// MarkLogin records the day as delivered: the login reply already carries the fresh counters.
func (service Service) MarkLogin(ctx context.Context, player identity.PlayerID, at time.Time) error {
	if service.Markers == nil || !player.Valid() || at.IsZero() {
		return nil
	}
	return service.Markers.Set(ctx, player, modes.Day(at))
}

func (service Service) counters(ctx context.Context, player identity.PlayerID, at time.Time) (Counters, error) {
	if service.Counters == nil {
		return Counters{}, nil
	}
	return service.Counters.Counters(ctx, player, at)
}
