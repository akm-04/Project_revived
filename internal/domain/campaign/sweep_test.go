package campaign

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/player"
)

func TestSweepAndResetSourceRules(t *testing.T) {
	c := loadCatalog(t)
	p := Progress{Nodes: map[int64]NodeState{100001: {CampaignID: 100001, Star: 3}, 100019: {CampaignID: 100019, Star: 3}}}
	n, _ := c.Node(100001)
	if _, err := c.Sweep(p, n, 10, 1, 100, 0, false); !errors.Is(err, ErrRefused) {
		t.Fatal("VIP0 multi", err)
	}
	if _, err := c.Sweep(p, n, 10, 2, 100, 0, true); err != nil {
		t.Fatal("monthly multi", err)
	}
	if _, err := c.Sweep(p, n, 1, 1, 100, 0, false); err != nil {
		t.Fatal("VIP0 single", err)
	}
	for _, count := range []int64{-1, 0, 11, 1 << 62} {
		if _, err := c.Sweep(p, n, count, 1, 100, 15, false); err == nil {
			t.Fatal("invalid count", count)
		}
	}
	elite, _ := c.Node(100019)
	if _, _, err := c.Reset(p, elite.ID, 45, 100, 15, true, false); !errors.Is(err, ErrRefused) {
		t.Fatal("reset initial unexhausted", err)
	}
	spent, err := c.Sweep(p, elite, 3, 1, 100, 15, false)
	if err != nil || c.Remaining(spent, elite, 100) != 0 {
		t.Fatal("super use", spent, err)
	}
	if _, err = c.Sweep(spent, elite, 1, 1, 100, 15, false); !errors.Is(err, ErrRefused) {
		t.Fatal("overspend", err)
	}
	if _, _, err = c.Reset(spent, elite.ID, 45, 100, 0, true, false); !errors.Is(err, ErrRefused) {
		t.Fatal("no allowance", err)
	}
	next, price, err := c.Reset(spent, elite.ID, 45, 100, 15, true, false)
	if err != nil || price != c.EliteResetCosts[0] || c.Remaining(next, elite, 100) != 3 || next.State(elite.ID).Resets.In(100).Used != 1 {
		t.Fatal("reset", next, price, err)
	}
	_, price, err = c.Reset(next, elite.ID, 45, 100, 15, true, false)
	if err != nil || price != 0 {
		t.Fatal("natural replay charged", price, err)
	}
	if c.Remaining(spent, elite, 101) != 3 || spent.State(elite.ID).Resets.In(101).Used != 0 {
		t.Fatal("day rollover")
	}
	state := spent.State(elite.ID)
	state.Resets = modes.Counter{Period: 100, Used: c.VIP[0].NumElite}
	spent = spent.with(state)
	if _, _, err = c.Reset(spent, elite.ID, 45, 100, 0, true, true); err != nil {
		t.Fatal("monthly allowance", err)
	}
}

func TestSweepEXPClientBoundary(t *testing.T) {
	c := loadCatalog(t)
	n, _ := c.Node(100001)
	rule := player.ProgressionPolicy{Rows: make([]player.ProgressionRow, 11)}
	rule.Rows[9].TotalExp = 100
	exp, err := c.SweepEXP(n, 3, player.Progression{Level: 10, Exp: 94}, rule)
	if err != nil || exp != 6+18+18 {
		t.Fatal("level10 crossing", exp, err)
	}
	exp, err = c.SweepEXP(n, 10, player.Progression{Level: 45, Exp: 999}, rule)
	if err != nil || exp != 180 {
		t.Fatal("high level", exp, err)
	}
}
