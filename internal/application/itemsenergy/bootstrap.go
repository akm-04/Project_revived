package itemsenergy

import (
	"context"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/dailyreset"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var _ appboot.MID1DetailContributor = Bootstrap{}

// Bootstrap projects the named purchase counters into MID 1 detail 17. The
// lobby baseline still writes zero for the not-yet-owned keys.
type Bootstrap struct{ Counters Counters }

func (Bootstrap) Name() string     { return "i9-11b.buy-counters" }
func (Bootstrap) Claims() []string { return []string{"17.buy_mana_times", "17.buy_energy_times"} }

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
	core["buy_mana_times"] = counters.Mana
	core["buy_energy_times"] = counters.Energy
	return nil
}

var _ dailyreset.CounterReader = BuyCounterReader{}

// BuyCounterReader is the daily-reset decorator's real CounterReader.
type BuyCounterReader struct {
	Reads Counters
	Fresh tx.Queryer
}

func (r BuyCounterReader) Counters(c context.Context, player identity.PlayerID, at time.Time) (dailyreset.Counters, error) {
	if r.Reads == nil || r.Fresh == nil {
		return dailyreset.Counters{}, d.ErrUnavailable
	}
	values, err := r.Reads.ReadBuyTx(c, r.Fresh, player, modes.Day(at))
	if err != nil {
		return dailyreset.Counters{}, err
	}
	return dailyreset.Counters{BuyManaTimes: values.Mana, BuyEnergyTimes: values.Energy, BuySkillTimes: values.Skill}, nil
}
