package heroassets

import (
	"context"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	d "gxb.local/backend/v2/internal/domain/heroassets"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var _ appboot.MID1DetailContributor = Bootstrap{}

// BuyCounterReader reads the named daily counters without writing.
type BuyCounterReader interface {
	ReadBuyTx(context.Context, tx.Queryer, identity.PlayerID, int64) (appconsume.BuyCounters, error)
}

// Bootstrap projects buy_skill_times into MID 1 detail 17. The 11B contributor
// owns the mana and energy keys; this one claims only the skill counter.
type Bootstrap struct{ Counters BuyCounterReader }

func (Bootstrap) Name() string     { return "i9-11a.buy-skill-counter" }
func (Bootstrap) Claims() []string { return []string{"17.buy_skill_times"} }

func (b Bootstrap) OverlayMID1(c context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	if b.Counters == nil {
		return d.ErrUnavailable
	}
	core, ok := detail["17"].(map[string]any)
	if !ok {
		return d.ErrUnavailable
	}
	counters, err := b.Counters.ReadBuyTx(c, q, actor.PlayerID, modes.Day(at))
	if err != nil {
		return err
	}
	core["buy_skill_times"] = counters.Skill
	return nil
}
