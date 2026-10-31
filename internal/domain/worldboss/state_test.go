package worldboss

import (
	"encoding/json"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/modes"
)

func sourceCatalog(t *testing.T) Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/world_boss_catalog.json")
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
	first, ok := catalog.Boss(10011)
	if !ok || first.Name != "Karatine" || first.NeedBrave != 20000000 || first.FightID != 115012 || first.MonsterID != 92000063 || first.NextID != 10012 {
		t.Fatal(first, ok)
	}
	last, ok := catalog.Boss(10015)
	if !ok || last.NeedBrave != 100000000 || last.NextID != 0 || last.DefeatStone != 40001033 {
		t.Fatal(last, ok)
	}
	if reward := catalog.Reward(1); reward.Diamond != 480 || reward.Mana != 40000 || reward.Stone != 24 {
		t.Fatal(reward)
	}
	if reward := catalog.Reward(11); reward.Range != 20 || reward.Diamond != 280 {
		t.Fatal(reward)
	}
	if reward := catalog.Reward(100000); reward.Diamond != 10 || reward.Stone != 0 {
		t.Fatal(reward)
	}
	if reward := catalog.Reward(0); reward != (RankReward{}) {
		t.Fatal(reward)
	}
	if reward := catalog.Reward(100001); reward != (RankReward{}) {
		t.Fatal(reward)
	}
	if catalog.Texts.Title != "Fate Rules" || catalog.Mail.Sender != "Commander" || catalog.Mail.Title != "Fate Rewards" {
		t.Fatal(catalog.Texts.Title, catalog.Mail)
	}
	if catalog.Texts.RankTitles[0] != "Karatine" || catalog.Texts.RankTitles[4] != "Saint" {
		t.Fatal(catalog.Texts.RankTitles)
	}
	if catalog.ActivityID != 1026 || catalog.OpenLevel != 48 || catalog.Attempts != 5 || catalog.WindowStop != 79080 {
		t.Fatal(catalog.ActivityID, catalog.OpenLevel, catalog.Attempts, catalog.WindowStop)
	}
}

func TestClampDamage(t *testing.T) {
	cases := []struct {
		courage, need, reported, want int64
	}{
		{0, 20000000, 12000000, 10000000},
		{15000000, 20000000, 7000000, 5000000},
		{20000000, 20000000, 7000000, 0},
		{0, 20000000, -1, 0},
		{0, 20000000, 0, 0},
		{0, 20000000, 3000000, 3000000},
	}
	for _, item := range cases {
		if got := ClampDamage(item.courage, item.need, item.reported); got != item.want {
			t.Fatalf("courage=%d need=%d reported=%d got=%d want=%d", item.courage, item.need, item.reported, got, item.want)
		}
	}
}

func TestDailyCourage(t *testing.T) {
	if got := DailyCourage(0, 0); got != 6666668 {
		t.Fatal(got)
	}
	if got := DailyCourage(3, 2); got != 6666668+3*100000+2*10000 {
		t.Fatal(got)
	}
	if got := DailyCourage(-1, 0); got != 0 {
		t.Fatal(got)
	}
}

func TestOccurrenceCourageAndDefeat(t *testing.T) {
	catalog := sourceCatalog(t)
	occurrence := Occurrence{LogicalServerID: 1, Generation: 1, CurrentBoss: 10011}
	if accepted, err := occurrence.Accept(catalog, 12000000); err != nil || accepted != 10000000 || occurrence.Courage != 10000000 {
		t.Fatal(accepted, err, occurrence)
	}
	if accepted, err := occurrence.Accept(catalog, 12000000); err != nil || accepted != 10000000 || occurrence.Courage != 20000000 {
		t.Fatal(accepted, err, occurrence)
	}
	if defeated, restarted := occurrence.Defeat(catalog); len(defeated) != 1 || restarted || occurrence.CurrentBoss != 10012 || occurrence.Courage != 20000000 {
		t.Fatal(defeated, restarted, occurrence)
	}
	if accepted, err := occurrence.Accept(catalog, 12000000); err != nil || accepted != 10000000 || occurrence.Courage != 30000000 {
		t.Fatal(accepted, err, occurrence)
	}
	occurrence.CurrentBoss = 10015
	occurrence.Courage = 100000000
	if defeated, restarted := occurrence.Defeat(catalog); len(defeated) != 1 || !restarted || occurrence.CurrentBoss != 10011 || occurrence.Courage != 0 || occurrence.Generation != 2 {
		t.Fatal(defeated, restarted, occurrence)
	}
	occurrence.CurrentBoss = 10011
	occurrence.Courage = 100000000
	if defeated, restarted := occurrence.Defeat(catalog); len(defeated) != 5 || !restarted || occurrence.Generation != 3 || occurrence.CurrentBoss != 10011 || occurrence.Courage != 0 {
		t.Fatal(defeated, restarted, occurrence)
	}
}

func TestPlayerResetBestHitAndSweep(t *testing.T) {
	at := time.Date(2026, 10, 31, 12, 0, 0, 0, time.FixedZone("GMT+8", 8*3600))
	day := modes.Day(at)
	player := Player{PlayerID: 7}
	if !player.Reset(day) || player.Attempts != 5 || player.Bought != 0 || player.SweptDay != 0 {
		t.Fatal(player)
	}
	if player.Reset(day) {
		t.Fatal("same-day reset")
	}
	player.RecordHit(100, 10)
	player.RecordHit(50, 20)
	if player.BestHit != 100 || player.BestHitAt != 10 {
		t.Fatal(player)
	}
	if !player.CanSweep() {
		t.Fatal("sweep should be available")
	}
	player.SweptDay = day
	if player.CanSweep() {
		t.Fatal("sweep repeated in one day")
	}
	player.SweptDay = 0
	player.Attempts = 0
	if player.CanSweep() {
		t.Fatal("sweep without attempts")
	}
	player.Attempts = 2
	player.Bought = 3
	if !player.Reset(day+1) || player.Attempts != 5 || player.Bought != 0 || player.SweptDay != 0 || player.BestHit != 100 {
		t.Fatal(player)
	}
}

func TestRankOrderAndTies(t *testing.T) {
	entries := []RankEntry{
		{PlayerID: 1, TotalHurt: 100, FirstHurtAt: 5},
		{PlayerID: 2, TotalHurt: 100, FirstHurtAt: 4},
		{PlayerID: 3, TotalHurt: 200, FirstHurtAt: 9},
		{PlayerID: 4, TotalHurt: 100, FirstHurtAt: 4},
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
	total := Total{PlayerID: 1}
	total.AddHurt(0, 3)
	total.AddHurt(10, 4)
	total.AddHurt(5, 6)
	if total.Hurt != 15 || total.FirstHurtAt != 4 {
		t.Fatal(total)
	}
}

func TestStartWindowAndAttemptBinding(t *testing.T) {
	zone := time.FixedZone("GMT+8", 8*3600)
	if !StartAllowed(SecondOfDay(time.Date(2026, 10, 31, 21, 57, 59, 0, zone))) {
		t.Fatal("21:57:59 should be open")
	}
	if StartAllowed(SecondOfDay(time.Date(2026, 10, 31, 21, 58, 0, 0, zone))) {
		t.Fatal("21:58 should be closed")
	}
	if StartAllowed(SecondOfDay(time.Date(2026, 10, 31, 23, 59, 59, 0, zone))) {
		t.Fatal("23:59:59 should be closed")
	}
	if !StartAllowed(SecondOfDay(time.Date(2026, 11, 1, 0, 0, 0, 0, zone))) {
		t.Fatal("midnight should be open")
	}
	occurrence := Occurrence{LogicalServerID: 1, Generation: 2, CurrentBoss: 10012}
	attempt := Attempt{ID: "a", PlayerID: 1, LogicalServerID: 1, Generation: 2, CampaignID: 10012}
	if !attempt.Matches(occurrence) {
		t.Fatal("current occurrence should match")
	}
	attempt.Generation = 1
	if attempt.Matches(occurrence) {
		t.Fatal("late attempt must not match a newer occurrence")
	}
}
