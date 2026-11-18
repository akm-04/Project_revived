package dailyconsume

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Reserved named counters (LEAD_SEAMS_I9-11 V2 section 3). Ids 1..10 stay the
// daily_consume table ids.
const (
	CounterBuyMana   int64 = 1001
	CounterBuyEnergy int64 = 1002
	CounterBuySkill  int64 = 1003
)

// BuyCounters is the three named purchase counters normalised to one game day.
type BuyCounters struct {
	Mana   int64
	Energy int64
	Skill  int64
}

func buyCounters(counts Counts, day int64) BuyCounters {
	return BuyCounters{
		Mana:   counts[CounterBuyMana].In(day).Used,
		Energy: counts[CounterBuyEnergy].In(day).Used,
		Skill:  counts[CounterBuySkill].In(day).Used,
	}
}

// ReadBuyTx normalises the named counters on read and never writes.
func (s Service) ReadBuyTx(c context.Context, q tx.Queryer, p identity.PlayerID, day int64) (BuyCounters, error) {
	if s.Store == nil {
		return BuyCounters{}, errors.New("daily consumption: unavailable")
	}
	counts, err := s.Store.ReadTx(c, q, p)
	if err != nil {
		return BuyCounters{}, err
	}
	return buyCounters(counts, day), nil
}

// LockedCounters is the rank-450 counter row locked and read before any
// mutation. A caller that also takes higher-rank locks prepares those first,
// then calls Advance, so no lock is discovered after the counter write.
type LockedCounters struct {
	counts Counts
	day    int64
	at     time.Time
}

// LockBuyTx locks the counter row and normalises the named counters on read.
func (s Service) LockBuyTx(c context.Context, t tx.Tx, p identity.PlayerID, day int64, at time.Time) (LockedCounters, BuyCounters, error) {
	if s.Store == nil {
		return LockedCounters{}, BuyCounters{}, errors.New("daily consumption: unavailable")
	}
	counts, err := s.Store.LockTx(c, t, p, at)
	if err != nil {
		return LockedCounters{}, BuyCounters{}, err
	}
	return LockedCounters{counts: counts, day: day, at: at}, buyCounters(counts, day), nil
}

// AdvanceBuyTx advances one named buy counter in the locked row, enforcing the
// caller's allowance, and saves the whole counter map.
func (s Service) AdvanceBuyTx(c context.Context, t tx.Tx, p identity.PlayerID, locked LockedCounters, id, limit int64) (BuyCounters, error) {
	if (id != CounterBuyMana && id != CounterBuyEnergy && id != CounterBuySkill) || limit <= 0 {
		return BuyCounters{}, ErrRefused
	}
	counts, err := advanceLocked(locked, id, limit)
	if err != nil {
		return BuyCounters{}, err
	}
	if err = s.Store.SaveTx(c, t, p, counts, locked.at); err != nil {
		return BuyCounters{}, err
	}
	return buyCounters(counts, locked.day), nil
}

// AdvanceDailyTx advances one daily_consume table id (1..10) in the locked row,
// for the tenfold Golden Hand slot.
func (s Service) AdvanceDailyTx(c context.Context, t tx.Tx, p identity.PlayerID, locked LockedCounters, id, limit int64) (int64, error) {
	if id < 1 || id > 10 || limit <= 0 {
		return 0, ErrRefused
	}
	counts, err := advanceLocked(locked, id, limit)
	if err != nil {
		return 0, err
	}
	if err = s.Store.SaveTx(c, t, p, counts, locked.at); err != nil {
		return 0, err
	}
	return counts[id].Used, nil
}

func advanceLocked(locked LockedCounters, id, limit int64) (Counts, error) {
	current := locked.counts[id]
	if current.Period > locked.day {
		return nil, ErrRefused
	}
	next, err := current.Use(locked.day, 1, limit)
	if err != nil {
		return nil, ErrRefused
	}
	counts := locked.counts
	if counts == nil {
		counts = Counts{}
	}
	counts[id] = next
	return counts, nil
}

// IncrementBuyTx is the shared locked increment for callers that take no other
// lock: it locks the rank-450 row, advances the counter and saves it.
func (s Service) IncrementBuyTx(c context.Context, t tx.Tx, p identity.PlayerID, day, id, limit int64, at time.Time) (BuyCounters, error) {
	locked, _, err := s.LockBuyTx(c, t, p, day, at)
	if err != nil {
		return BuyCounters{}, err
	}
	return s.AdvanceBuyTx(c, t, p, locked, id, limit)
}

// IncrementDailyTx is the shared locked increment of one daily_consume id.
func (s Service) IncrementDailyTx(c context.Context, t tx.Tx, p identity.PlayerID, day, id, limit int64, at time.Time) (int64, error) {
	locked, _, err := s.LockBuyTx(c, t, p, day, at)
	if err != nil {
		return 0, err
	}
	return s.AdvanceDailyTx(c, t, p, locked, id, limit)
}
