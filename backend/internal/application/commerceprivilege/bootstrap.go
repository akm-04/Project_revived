package commerceprivilege

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// BootstrapProjection consumes only canonical privilege state; missing legacy
// state preserves the prior inactive bootstrap, never a qualified4Aabsence.
type BootstrapProjection struct{ Provider Provider }

func (BootstrapProjection) Name() string { return "commerce.i7c4a.privilege" }
func (BootstrapProjection) Claims() []string {
	return []string{"17.vip", "17.charge", "17.month_card_start", "17.month_card_end", "17.left_card_day", "17.left_week_card_day",
		"17.left_month_tili_day", "17.privilege_left_card_day", "17.privilege_month_card_end", "17.vip_awards"}
}
func (p BootstrapProjection) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	snap, privilegeKnown, e := p.Provider.snapshot(c, q, a.PlayerID, "", at)
	if e != nil {
		return e
	}
	out, ok := detail["17"].(map[string]any)
	if !ok {
		return errors.New("privilege MID17 projection unavailable")
	}
	claimed, e := p.Provider.Store.ReadVIPClaimedTx(c, q, a.PlayerID)
	if e != nil {
		return e
	}
	awards := make([]int64, 15)
	for _, level := range claimed {
		if level >= 1 && level <= 15 {
			awards[level-1] = 1
		}
	}
	// Claim flags must exist before the first tap, independently of privilege qualification.
	out["vip_awards"] = awards
	if !privilegeKnown {
		return nil
	}
	cards, e := p.Provider.Store.ReadCardsTx(c, q, a.PlayerID)
	if e != nil {
		return e
	}
	now := at.Unix()
	out["vip"] = snap.State.VIPLevel
	out["charge"] = snap.State.Charge
	out["month_card_start"] = cards.MonthCardStart
	out["month_card_end"] = cards.MonthCardEnd
	out["left_card_day"] = d.LeftDays(cards.MonthCardEnd, now)
	out["left_week_card_day"] = int64(0)
	out["left_month_tili_day"] = int64(0)
	out["privilege_left_card_day"] = d.LeftDays(cards.PrivilegeCardEnd, now)
	out["privilege_month_card_end"] = cards.PrivilegeCardEnd
	return nil
}
