package topfloor

import (
	"testing"
	"time"
)

func testCatalog() Catalog {
	ranges := []int64{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 70, 100, 200, 300, 400, 500, 700, 1000, 2000, 3000, 4000, 5000, 7000, 10000, 15000, 100000}
	rates := []int64{0, 5000000, 4000000, 3000000, 2500000, 2000000, 1900000, 1800000, 1700000, 1600000, 300000, 250000, 200000, 150000, 100000, 50000, 26664, 8000, 7200, 6800, 6000, 3000, 2000, 800, 720, 680, 600, 300, 40, 0}
	c := Catalog{FreeTickets: 5, BuyRestore: 5, CooldownSeconds: 300, ResetCost: 50, MatchHundredths: [3]int64{30, 50, 98}, CutoffSeconds: 75600, FreezeEndSeconds: 77400, BuyCosts: []int64{50, 100, 200}}
	for i, r := range ranges {
		c.Rewards = append(c.Rewards, Reward{ID: int64(i + 1), Range: r, BestRankRate: rates[i]})
	}
	return c
}

func TestBestRankRewardMatchesClientFormula(t *testing.T) {
	c := testCatalog()
	for _, tc := range []struct{ old, new, want int64 }{{10325, 9000, 32}, {15, 12, 90}, {2, 1, 500}, {100001, 50, 1}, {20000, 15000, 1}} {
		if got := c.BestRankReward(tc.old, tc.new); got != tc.want {
			t.Errorf("BestRankReward(%d,%d)=%d want %d", tc.old, tc.new, got, tc.want)
		}
	}
	if o := c.Decide(1, 50, 40, 45); !o.Win || o.ChallengerAfter != 40 || o.DefenderAfter != 50 || o.BestAfter != 40 || o.AwardCrystal != c.BestRankReward(45, 40) {
		t.Fatalf("win swap %+v", o)
	}
	if o := c.Decide(1, 40, 50, 40); o.ChallengerAfter != 40 || o.AwardCrystal != 0 {
		t.Fatalf("a win against a lower rank never swaps %+v", o)
	}
	if o := c.Decide(0, 50, 40, 45); o.Win || o.ChallengerAfter != 50 {
		t.Fatalf("loss %+v", o)
	}
}

func TestBandsAndRevenge(t *testing.T) {
	c := testCatalog()
	if got := c.Bands(1000); len(got) != 3 || got[0] != [2]int64{980, 999} || got[1] != [2]int64{500, 979} || got[2] != [2]int64{300, 499} {
		t.Fatalf("bands %v", got)
	}
	if got := c.Bands(5); len(got) != 3 || got[0] != [2]int64{4, 4} || got[2] != [2]int64{2, 2} {
		t.Fatalf("collapsed bands %v", got)
	}
	if got := c.Bands(1); len(got) != 0 {
		t.Fatalf("rank 1 bands %v", got)
	}
	ranks := c.OfferRanks(1, 100001, 1, 7, 0)
	if near := ranks[len(ranks)-1]; len(near) < 3 || near[0] != 2 || near[1] != 3 {
		t.Fatalf("rank 1 nearest %v", near)
	}
	if a, b := c.OfferRanks(1, 100001, 1000, 7, 0), c.OfferRanks(1, 100001, 1000, 7, 1); a[0][0] == b[0][0] && a[1][0] == b[1][0] && a[2][0] == b[2][0] {
		t.Fatal("refresh must reorder the bands")
	}
	if c.AvengeType(100, 30) != 0 || c.AvengeType(100, 29) != 4 || c.AvengeType(100, 120) != 3 {
		t.Fatal("avenge type")
	}
}

func TestCalendarAndTickets(t *testing.T) {
	c := testCatalog()
	gmt8 := time.FixedZone("GMT+8", 8*3600)
	at := time.Date(2026, 10, 19, 21, 10, 0, 0, gmt8)
	if !c.Frozen(at) || c.Frozen(at.Add(25*time.Minute)) || c.Frozen(at.Add(-11*time.Minute)) {
		t.Fatal("freeze window")
	}
	day := c.LatestCutoffDay(at)
	if !c.CutoffInstant(day).Equal(time.Date(2026, 10, 19, 21, 0, 0, 0, gmt8)) || c.LatestCutoffDay(at.Add(-11*time.Minute)) != day-1 || DayDate(day) != "2026-10-19" {
		t.Fatal("cutoff day")
	}
	if TicketDay(time.Date(2026, 10, 20, 4, 59, 0, 0, gmt8)) != TicketDay(time.Date(2026, 10, 19, 5, 0, 0, 0, gmt8)) || TicketDay(time.Date(2026, 10, 20, 5, 0, 0, 0, gmt8)) == TicketDay(time.Date(2026, 10, 19, 5, 0, 0, 0, gmt8)) {
		t.Fatal("ticket day boundary")
	}
	noon := time.Date(2026, 10, 19, 12, 0, 0, 0, gmt8)
	p := c.NewPlayer(100001, 1, "", 100, noon)
	p, err := c.AdmitStart(p, noon)
	if err != nil || p.TicketsLeft != 4 {
		t.Fatal("first start", err)
	}
	if _, err = c.AdmitStart(p, noon.Add(time.Minute)); err != ErrRefused {
		t.Fatal("cooldown must refuse")
	}
	if _, _, err = c.ResetTimer(p, VIP{}, false, noon.Add(time.Minute)); err != ErrRefused {
		t.Fatal("reset requires vip or monthly card")
	}
	reset, cost, err := c.ResetTimer(p, VIP{Reset: 1}, false, noon.Add(time.Minute))
	if err != nil || cost != 50 || reset.LastMatchAt != nil {
		t.Fatal("reset", err)
	}
	if _, _, err = c.Buy(p, VIP{Purchases: 1}, noon); err != ErrRefused {
		t.Fatal("buy requires exhausted tickets")
	}
	p.TicketsLeft = 0
	bought, cost, err := c.Buy(p, VIP{Purchases: 2}, noon)
	if err != nil || cost != 50 || bought.TicketsLeft != 5 || bought.Purchases != 1 {
		t.Fatal("buy", err)
	}
	if rolled := c.Rolled(bought, noon.Add(24*time.Hour)); rolled.Purchases != 0 || rolled.TicketsLeft != 5 {
		t.Fatal("daily roll")
	}
}
