package topfloor

import (
	"reflect"
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
	for _, rank := range []int64{3, 2} {
		near := c.OfferRanks(1, 100001, rank, 7, 0)
		last := near[len(near)-1]
		for _, r := range last {
			if r >= rank {
				t.Fatalf("rank %d nearest offered %d at or below its rank: %v", rank, r, last)
			}
		}
	}
	if last := c.OfferRanks(1, 100001, 3, 7, 0); len(last[len(last)-1]) != 2 || last[len(last)-1][0] != 2 || last[len(last)-1][1] != 1 {
		t.Fatalf("rank 3 nearest %v", last[len(last)-1])
	}
	if last := c.OfferRanks(1, 100001, 2, 7, 0); len(last[len(last)-1]) != 1 || last[len(last)-1][0] != 1 {
		t.Fatalf("rank 2 nearest %v", last[len(last)-1])
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

func TestRobotHeroParamsCarrySourceEquipment(t *testing.T) {
	c := Catalog{RobotHeroes: []RobotHero{{ID: 77001005, Level: 77, PartnerID: 10001005, Quality: 9, Star: 3, EquipFlags: []int64{1, 0, 1, 1, 1, 1}}}}
	params, ok := c.RobotHeroParams(77001005)
	if !ok {
		t.Fatal("robot hero missing")
	}
	if params["lev"] != int64(77) || params["star"] != int64(3) || params["color"] != int64(9) || params["partner_id"] != int64(10001005) {
		t.Fatalf("source params %v", params)
	}
	if !reflect.DeepEqual(params["equips"], []any{int64(1), int64(0), int64(1), int64(1), int64(1), int64(1)}) {
		t.Fatalf("source equip flags %v", params["equips"])
	}
	if !reflect.DeepEqual(params["skills"], []any{1, 1, 1, 1, 1, 1}) {
		t.Fatalf("client-default skill levels %v", params["skills"])
	}
}

func bandTestCatalog() Catalog {
	return Catalog{
		RobotHeroes: []RobotHero{{ID: 1, Level: 79, PartnerID: 10001031, Quality: 10, Star: 2, EquipFlags: []int64{1, 1, 0, 1, 1, 1}}},
		PetPool:     []RobotPetTemplate{{TableID: 10010001, InitialStar: 1}, {TableID: 10020001, InitialStar: 3}},
		RobotRankBands: RobotRankBandPolicy{Label: "PRIVATE_POLICY", PolicyID: "I9_10_ROBOT_RANK_BANDS_V1_PRIVATE_POLICY", MeetingRank: 500,
			Anchors: []RobotRankAnchor{
				{Rank: 1, Quality: 16, Level: 100, Star: 3, PetLevel: 100},
				{Rank: 10, Quality: 16, Level: 100, Star: 3, PetLevel: 100},
				{Rank: 11, Quality: 16, Level: 99, Star: 3, PetLevel: 99},
				{Rank: 25, Quality: 15, Level: 90, Star: 3, PetLevel: 90},
				{Rank: 26, Quality: 13, Level: 89, Star: 3, PetLevel: 89},
				{Rank: 500, Quality: 3, Level: 14, Star: 1, PetLevel: 14},
			}},
	}
}

func TestRobotRankBandTable(t *testing.T) {
	c := bandTestCatalog()
	for _, tc := range []struct {
		rank           int64
		quality, level int64
		star, petLevel int64
	}{
		{1, 16, 100, 3, 100},
		{10, 16, 100, 3, 100},
		{11, 16, 99, 3, 99},
		{25, 15, 90, 3, 90},
		{26, 13, 89, 3, 89},
		{30, 13, 88, 3, 88},
		{500, 3, 14, 1, 14},
	} {
		band, ok := c.RobotBand(tc.rank)
		if !ok || band.Quality != tc.quality || band.Level != tc.level || band.Star != tc.star || band.PetLevel != tc.petLevel {
			t.Fatalf("rank %d band %+v ok=%v want %+v", tc.rank, band, ok, tc)
		}
	}
	if _, ok := c.RobotBand(501); ok {
		t.Fatal("ranks after the meeting rank must use source values")
	}
}

func TestRobotBandRaisesSourceHeroAndAddsPet(t *testing.T) {
	c := bandTestCatalog()
	params, ok := c.RobotHeroParamsAt(1, 1)
	if !ok || params["lev"] != int64(100) || params["color"] != int64(16) || params["star"] != int64(3) {
		t.Fatalf("rank 1 hero %v", params)
	}
	if !reflect.DeepEqual(params["equips"], []any{int64(1), int64(1), int64(0), int64(1), int64(1), int64(1)}) {
		t.Fatalf("rank 1 source equipment %v", params["equips"])
	}
	pet, ok := c.RobotPet(3, 1)
	if !ok || pet["lev"] != int64(100) || (pet["table_id"] != int64(10010001) && pet["table_id"] != int64(10020001)) {
		t.Fatalf("rank 1 pet %v", pet)
	}
	again, _ := c.RobotPet(3, 1)
	if !reflect.DeepEqual(pet, again) {
		t.Fatal("robot pet must be deterministic")
	}
	source, ok := c.RobotHeroParamsAt(1, 600)
	if !ok || source["lev"] != int64(79) || source["color"] != int64(10) || source["star"] != int64(2) {
		t.Fatalf("rank 600 source hero %v", source)
	}
	if _, ok := c.RobotPet(3, 600); ok {
		t.Fatal("rank 600 source robot carries no pet")
	}
}
