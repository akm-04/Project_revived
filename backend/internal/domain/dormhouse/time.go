package dormhouse

import (
	"math/big"
	"time"
)

const HourNumerator int64 = int64(time.Hour)
const MaxLoungeElapsed = 10 * time.Hour

type LoungeSettlement struct {
	WholeEXP, Fraction int64
	Anchor             time.Time
	DiscardedElapsed   bool
}

// SettleLounge implements user-authorized preservation, not recovered server
// rounding. No clock is sampled here. Apply WholeEXP through Character's port.
func SettleLounge(anchor, observed time.Time, fraction, comfort int64) (LoungeSettlement, error) {
	if anchor.IsZero() || observed.IsZero() || fraction < 0 || fraction >= HourNumerator || comfort < 0 {
		return LoungeSettlement{}, ErrInvalidFacts
	}
	if observed.Before(anchor) {
		return LoungeSettlement{}, ErrStaleTime
	}
	elapsed := observed.Sub(anchor)
	discarded := elapsed > MaxLoungeElapsed
	if discarded {
		elapsed = MaxLoungeElapsed
	}
	rate := new(big.Int).Mul(big.NewInt(comfort), big.NewInt(20))
	rate.Add(rate, big.NewInt(60))
	numerator := new(big.Int).Mul(rate, big.NewInt(int64(elapsed)))
	numerator.Add(numerator, big.NewInt(fraction))
	whole, rem := new(big.Int), new(big.Int)
	whole.QuoRem(numerator, big.NewInt(HourNumerator), rem)
	if !whole.IsInt64() {
		return LoungeSettlement{}, ErrInvalidFacts
	}
	return LoungeSettlement{whole.Int64(), rem.Int64(), observed.UTC(), discarded}, nil
}

// Expansion timestamps are integer-second wire facts. A deadline boundary is
// complete at equality; the client polls later, but cannot incur a price there.
func (e Expansion) Deadline() (time.Time, error) {
	if e.Occurrence == "" || e.ContentRevision == "" || e.NextLevel < 1 || e.DurationSeconds <= 0 || e.StartedAt.IsZero() || e.StartedAt.Nanosecond() != 0 {
		return time.Time{}, ErrInvalidFacts
	}
	// Duration overflow is a malformed catalog/occurrence, never a wraparound.
	if e.DurationSeconds > int64((1<<63-1)/int64(time.Second)) {
		return time.Time{}, ErrInvalidFacts
	}
	return e.StartedAt.Add(time.Duration(e.DurationSeconds) * time.Second), nil
}
func (e Expansion) FinishPrice(observed time.Time) (diamonds int64, complete bool, err error) {
	due, err := e.Deadline()
	if err != nil {
		return 0, false, err
	}
	if observed.IsZero() || observed.Before(e.StartedAt) {
		return 0, false, ErrStaleTime
	}
	remain := due.Unix() - observed.Unix()
	if remain <= 0 {
		return 0, true, nil
	}
	blocks := remain / 900
	if remain%900 > 0 {
		blocks++
	}
	if blocks > (1<<63-1)/125 {
		return 0, false, ErrInvalidFacts
	}
	return blocks * 125, false, nil
}
