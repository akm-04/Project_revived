// Package dailyconsume owns daily purchase counters. Campaign owns trial wins;
// the I9-11 Gold/Fumo providers remain separate from the bounded trial writer.
package dailyconsume

import (
	"context"
	"errors"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrRefused = errors.New("daily consumption: refused")

type Counts map[int64]modes.Counter

type Store interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (Counts, error)
	LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (Counts, error)
	SaveTx(context.Context, tx.Tx, identity.PlayerID, Counts, time.Time) error
}
type Service struct {
	Store Store
	Costs i5.TxMaterialCostDebiter
}

func (s Service) ReadTx(c context.Context, q tx.Queryer, p identity.PlayerID, day int64) (map[int64]int64, error) {
	if s.Store == nil {
		return nil, errors.New("daily consumption: unavailable")
	}
	counts, err := s.Store.ReadTx(c, q, p)
	if err != nil {
		return nil, err
	}
	out := make(map[int64]int64, 10)
	for id := int64(1); id <= 10; id++ {
		v := counts[id]
		if v.Period > day {
			return nil, ErrRefused
		}
		out[id] = v.In(day).Used
	}
	return out, nil
}
func Pipe(counts map[int64]int64) string {
	out := make([]string, 10)
	for id := int64(1); id <= 10; id++ {
		out[id-1] = strconv.FormatInt(counts[id], 10)
	}
	return strings.Join(out, "|")
}

// BuyTrialTx is called after Campaign605 under its purchase receipt (D125).
func (s Service) BuyTrialTx(c context.Context, t tx.Tx, p identity.PlayerID, id, day, cost, limit, value int64, op operation.Context, at time.Time) error {
	if id < 3 || id > 10 || cost <= 0 || limit != 1 || value != 1 {
		return ErrRefused
	}
	if s.Store == nil || s.Costs == nil {
		return errors.New("daily consumption: unavailable")
	}
	counts, err := s.Store.LockTx(c, t, p, at)
	if err != nil {
		return err
	}
	old := counts[id]
	if old.Period > day {
		return ErrRefused
	}
	next, err := old.Use(day, 1, limit)
	if err != nil {
		return ErrRefused
	}
	if _, err = s.Costs.DebitMaterialCostTx(c, t, p, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}}, op); err != nil {
		return err
	}
	if counts == nil {
		counts = Counts{}
	}
	counts[id] = next
	return s.Store.SaveTx(c, t, p, counts, at)
}
