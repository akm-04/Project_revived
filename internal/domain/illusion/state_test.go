package illusion

import (
	"encoding/json"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/modes"
)

func sourceCatalog(t *testing.T) Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/illusion_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog Catalog
	if err = json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	if err = catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func TestSourceCatalog(t *testing.T) {
	catalog := sourceCatalog(t)
	first, ok := catalog.Campaign(100001)
	if !ok || first.Name != "Pirate Captain " || first.NextID != 100002 || first.FightID != 1500001 || first.MonsterID != 89220003 || first.ModelID != 12001003 {
		t.Fatal(first, ok)
	}
	skip, ok := catalog.Campaign(100010)
	if !ok || skip.NextID != 100012 {
		t.Fatal(skip, ok)
	}
	terminal, ok := catalog.Campaign(100011)
	if !ok || terminal.NextID != 0 || catalog.NextCampaignID(100011) != 100001 {
		t.Fatal(terminal, ok)
	}
	last, ok := catalog.Campaign(100012)
	if !ok || last.NextID != 100001 || catalog.NextCampaignID(100012) != 100001 {
		t.Fatal(last, ok)
	}
	if catalog.NextCampaignID(999999) != 0 {
		t.Fatal("unknown campaign must not advance")
	}
	if reward := catalog.PersonReward(1); reward.Coin != 1600 || len(reward.ItemIDs) != 2 || reward.ItemNums[0] != 12 {
		t.Fatal(reward)
	}
	if reward := catalog.PersonReward(100000); reward.Coin != 100 || len(reward.ItemIDs) != 0 {
		t.Fatal(reward)
	}
	if reward := catalog.PersonReward(100001); reward.Range != 0 || reward.Coin != 0 {
		t.Fatal(reward)
	}
	if reward := catalog.CommunityReward(1); reward.Coin != 10000 || reward.PersonCoin != 1000 {
		t.Fatal(reward)
	}
	if reward := catalog.CommunityReward(10000); reward.Coin != 500 || reward.PersonCoin != 450 {
		t.Fatal(reward)
	}
	cost, ok := catalog.BuyCost(1)
	if !ok || cost != 50 {
		t.Fatal(cost, ok)
	}
	if cost, ok = catalog.BuyCost(7); !ok || cost != 1000 {
		t.Fatal(cost, ok)
	}
	if _, ok = catalog.BuyCost(0); ok {
		t.Fatal("zero purchase index must refuse")
	}
	if catalog.BuyCap(0) != 0 || catalog.BuyCap(3) != 1 || catalog.BuyCap(7) != 5 || catalog.BuyCap(15) != 13 || catalog.BuyCap(16) != 0 {
		t.Fatal(catalog.BuyCaps)
	}
	if catalog.OpenLevel != 65 || catalog.FreeChances != 5 || catalog.ChancesPerBuy != 5 || catalog.DamageCap != 12000000 || catalog.RewardPercentHundredths != 20 {
		t.Fatal(catalog.OpenLevel, catalog.FreeChances, catalog.ChancesPerBuy, catalog.DamageCap)
	}
	if catalog.OpenSecond != 28800 || catalog.CloseSecond != 79080 || catalog.SettleSecond != 79200 {
		t.Fatal(catalog.OpenSecond, catalog.CloseSecond, catalog.SettleSecond)
	}
	if catalog.TeamHeroLimit != 5 || catalog.TeamPowerLimit != 30 || catalog.PolicyID != PolicyID || catalog.PolicyVersion != PolicyVersion {
		t.Fatal(catalog.TeamHeroLimit, catalog.TeamPowerLimit, catalog.PolicyID)
	}
}

func TestClampAndPool(t *testing.T) {
	cases := []struct {
		pool, hurt, reported, want int64
	}{
		{120000000, 0, 12000000, 12000000},
		{120000000, 0, 15000000, 12000000},
		{120000000, 115000000, 12000000, 5000000},
		{120000000, 120000000, 12000000, 0},
		{120000000, 0, -1, 0},
		{120000000, 0, 0, 0},
	}
	for _, item := range cases {
		if got := ClampDamage(item.pool, item.hurt, item.reported); got != item.want {
			t.Fatalf("pool=%d hurt=%d reported=%d got=%d want=%d", item.pool, item.hurt, item.reported, got, item.want)
		}
	}
	occurrence := NewOccurrence(1, 100001, 100)
	if accepted := occurrence.Accept(13000000); accepted != 12000000 || occurrence.PoolHurt != 12000000 {
		t.Fatal(accepted, occurrence)
	}
	occurrence.PoolHurt = 119000000
	if accepted := occurrence.Accept(12000000); accepted != 1000000 || !occurrence.Done() {
		t.Fatal(accepted, occurrence)
	}
}

func TestCyclePhaseSettlementAndRestDay(t *testing.T) {
	zone := time.FixedZone("GMT+8", 8*3600)
	open := time.Date(2026, 10, 31, 8, 0, 0, 0, zone)
	openDay := modes.Day(open)
	occurrence := NewOccurrence(1, 100001, openDay)
	if occurrence.PhaseAt(open.Add(-time.Second)) != PhaseWaiting {
		t.Fatal("before open")
	}
	if occurrence.PhaseAt(open) != PhaseOpen || !occurrence.CanStart(open) {
		t.Fatal("08:00 must open")
	}
	if occurrence.PhaseAt(open.Add(13*time.Hour+57*time.Minute+59*time.Second)) != PhaseOpen {
		t.Fatal("21:57:59 must stay open")
	}
	closed := open.Add(13*time.Hour + 58*time.Minute)
	if occurrence.PhaseAt(closed) != PhaseClosed || occurrence.CanStart(closed) {
		t.Fatal("21:58 must close new starts")
	}
	settle := open.Add(14 * time.Hour)
	if occurrence.PhaseAt(settle) != PhaseSettlement {
		t.Fatal("22:00 settlement")
	}
	rest := open.Add(24 * time.Hour)
	if occurrence.PhaseAt(rest) != PhaseRest || occurrence.CanStart(rest) {
		t.Fatal("rest day must not restart")
	}
}

func TestAdvanceFollowsChainAndWraps(t *testing.T) {
	catalog := sourceCatalog(t)
	for _, step := range []struct{ from, to int64 }{{100001, 100002}, {100011, 100001}, {100012, 100001}} {
		occurrence := NewOccurrence(1, step.from, 7)
		if !occurrence.Advance(catalog) || occurrence.CampaignID != step.to || occurrence.OpenDay != 7+CycleDays {
			t.Fatal(step, occurrence)
		}
	}
}

func TestSettlementDueAndAdvance(t *testing.T) {
	zone := time.FixedZone("GMT+8", 8*3600)
	open := time.Date(2026, 10, 31, 8, 0, 0, 0, zone)
	openDay := modes.Day(open)
	occurrence := NewOccurrence(1, 100001, openDay)
	occurrence.PoolHurt = 500
	if occurrence.SettlementDue(open.Add(13*time.Hour + 57*time.Minute + 59*time.Second)) {
		t.Fatal("21:57:59 is not due")
	}
	if !occurrence.SettlementDue(open.Add(14 * time.Hour)) {
		t.Fatal("22:00 is due")
	}
	for _, late := range []time.Duration{24 * time.Hour, 48 * time.Hour, 30 * 24 * time.Hour} {
		if !occurrence.SettlementDue(open.Add(late)) {
			t.Fatal("a missed settlement stays due", late)
		}
	}
	if !occurrence.Advance(sourceCatalog(t)) || occurrence.CampaignID != 100002 || occurrence.OpenDay != openDay+CycleDays ||
		occurrence.SettledOpenDay != openDay || occurrence.PoolHurt != 0 || occurrence.PoolHP != DefaultPoolHP {
		t.Fatal("advance", occurrence)
	}
	if occurrence.SettlementDue(open.Add(48 * time.Hour)) {
		t.Fatal("an advanced occurrence settles early")
	}
	nextOpen := open.Add(CycleDays * 24 * time.Hour)
	if occurrence.BoardDay(open.Add(14*time.Hour)) != openDay || occurrence.BoardDay(nextOpen.Add(-time.Second)) != openDay {
		t.Fatal("the settled board stays until the next opening")
	}
	if occurrence.BoardDay(nextOpen) != occurrence.OpenDay {
		t.Fatal("the next opening clears the board")
	}
}

func TestPlayerChancesBuysAndBestHit(t *testing.T) {
	catalog := sourceCatalog(t)
	player := Player{PlayerID: 7}
	day := int64(100)
	if !player.Reset(day) || player.Chances != FreeChances || player.Bought != 0 || player.Reset(day) {
		t.Fatal(player)
	}
	if cost, err := player.Buy(catalog, 0); err == nil || cost != 0 {
		t.Fatal("VIP 0 must refuse buys")
	}
	if cost, err := player.Buy(catalog, 3); err != nil || cost != 50 || player.Chances != 10 || player.Bought != 1 {
		t.Fatal(cost, err, player)
	}
	if _, err := player.Buy(catalog, 3); err == nil {
		t.Fatal("VIP 3 buys once")
	}
	if cost, err := player.Buy(catalog, 7); err != nil || cost != 100 || player.Bought != 2 {
		t.Fatal(cost, err, player)
	}
	for player.Chances > 0 {
		if err := player.ConsumeChance(); err != nil {
			t.Fatal(err)
		}
	}
	if player.Chances != 0 || player.ConsumeChance() == nil {
		t.Fatal("no chances left")
	}
	if !player.Reset(day+1) || player.Chances != FreeChances || player.Bought != 0 {
		t.Fatal(player)
	}
	player.RecordHit(100, 5)
	player.RecordHit(100, 4)
	player.RecordHit(90, 1)
	if player.BestHit != 100 || player.BestTime != 4 {
		t.Fatal(player)
	}
	player.RecordHit(0, 0)
	if player.BestHit != 100 || player.BestTime != 4 {
		t.Fatal(player)
	}
}

func TestRankBestHitAndShorterTimeTies(t *testing.T) {
	entries := []Result{
		{PlayerID: 1, Hurt: 100, CostTime: 5},
		{PlayerID: 2, Hurt: 100, CostTime: 4},
		{PlayerID: 3, Hurt: 200, CostTime: 9},
		{PlayerID: 4, Hurt: 100, CostTime: 4},
	}
	ordered := OrderRank(entries)
	want := []int64{3, 2, 4, 1}
	for index, entry := range ordered {
		if entry.PlayerID != want[index] {
			t.Fatal(index, entry)
		}
	}
	if rank, hurt := RankOf(entries, 4); rank != 3 || hurt != 100 {
		t.Fatal(rank, hurt)
	}
	if rank, hurt := RankOf(entries, 9); rank != 0 || hurt != 0 {
		t.Fatal(rank, hurt)
	}
}

func TestTeamRules(t *testing.T) {
	valid := func() Team {
		return Team{Members: []TeamMember{
			{PlayerID: 1, Level: 70, Force: 3000, Heroes: []Hero{{TableID: 1, Power: 100}}, PetID: 7},
			{PlayerID: 2, Level: 67, Force: 2700, Heroes: []Hero{{TableID: 2, Power: 90}, {TableID: 3, Power: 120}}},
			{PlayerID: 3, Level: 75, Force: 3000, Heroes: []Hero{{TableID: 4, Power: 100}, {TableID: 5, Power: 100}}},
		}}
	}
	if err := valid().Validate(); err != nil {
		t.Fatal(err)
	}
	cases := map[string]func(*Team){
		"two seats": func(team *Team) { team.Members = team.Members[:2] },
		"master two heroes": func(team *Team) {
			team.Members[0].Heroes = append(team.Members[0].Heroes, Hero{TableID: 9, Power: 100})
		},
		"master no pet":      func(team *Team) { team.Members[0].PetID = 0 },
		"mate one hero":      func(team *Team) { team.Members[1].Heroes = team.Members[1].Heroes[:1] },
		"mate pet":           func(team *Team) { team.Members[1].PetID = 8 },
		"duplicate hero":     func(team *Team) { team.Members[2].Heroes[1].TableID = 2 },
		"duplicate player":   func(team *Team) { team.Members[2].PlayerID = 1 },
		"low power":          func(team *Team) { team.Members[0].Heroes[0].Power = 99 },
		"below level":        func(team *Team) { team.Members[2].Level = 64 },
		"outside level band": func(team *Team) { team.Members[2].Level = 76 },
		"zero hero":          func(team *Team) { team.Members[2].Heroes[1].TableID = 0 },
	}
	for name, mutate := range cases {
		team := valid()
		mutate(&team)
		if err := team.Validate(); err == nil {
			t.Fatalf("%s accepted", name)
		}
	}
}
