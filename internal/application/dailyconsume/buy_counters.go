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

// IncrementBuyTx is the one shared locked increment of a named buy counter. It
// lazily starts a new game day, enforces the caller's allowance and saves the
// whole counter map; a read path never calls it.
func (s Service) IncrementBuyTx(c context.Context, t tx.Tx, p identity.PlayerID, day, id, limit int64, at time.Time) (BuyCounters, error) {
	if s.Store == nil {
		return BuyCounters{}, errors.New("daily consumption: unavailable")
	}
	if (id != CounterBuyMana && id != CounterBuyEnergy && id != CounterBuySkill) || limit <= 0 {
		return BuyCounters{}, ErrRefused
	}
	counts, err := s.Store.LockTx(c, t, p, at)
	if err != nil {
		return BuyCounters{}, err
	}
	current := counts[id]
	if current.Period > day {
		return BuyCounters{}, ErrRefused
	}
	next, err := current.Use(day, 1, limit)
	if err != nil {
		return BuyCounters{}, ErrRefused
	}
	if counts == nil {
		counts = Counts{}
	}
	counts[id] = next
	if err = s.Store.SaveTx(c, t, p, counts, at); err != nil {
		return BuyCounters{}, err
	}
	return buyCounters(counts, day), nil
}

// IncrementDailyTx advances one daily_consume table id (1..10) under the same
// locked row, for the tenfold Golden Hand slot.
func (s Service) IncrementDailyTx(c context.Context, t tx.Tx, p identity.PlayerID, day, id, limit int64, at time.Time) (int64, error) {
	if s.Store == nil {
		return 0, errors.New("daily consumption: unavailable")
	}
	if id < 1 || id > 10 || limit <= 0 {
		return 0, ErrRefused
	}
	counts, err := s.Store.LockTx(c, t, p, at)
	if err != nil {
		return 0, err
	}
	current := counts[id]
	if current.Period > day {
		return 0, ErrRefused
	}
	next, err := current.Use(day, 1, limit)
	if err != nil {
		return 0, ErrRefused
	}
	if counts == nil {
		counts = Counts{}
	}
	counts[id] = next
	if err = s.Store.SaveTx(c, t, p, counts, at); err != nil {
		return 0, err
	}
	return next.Used, nil
}
