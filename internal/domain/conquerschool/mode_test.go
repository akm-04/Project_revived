package conquerschool_test

import (
	"encoding/json"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/content/builtin"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
)

func modeCatalog(t testing.TB) d.ModeCatalog {
	t.Helper()
	raw, e := builtin.GeneratedFile("conquer_mode_catalog.json")
	if e != nil {
		t.Fatal(e)
	}
	var c d.ModeCatalog
	if e = json.Unmarshal(raw, &c); e != nil {
		t.Fatal(e)
	}
	if e = c.Validate(); e != nil {
		t.Fatal(e)
	}
	return c
}

func TestModeCatalogSourceValues(t *testing.T) {
	c := modeCatalog(t)
	if c.RequiredLevel != 100 || c.ChallengeNum != 10 || c.BuffLimit != 10 || c.ReportLimit != 3 || c.ReportReward != 50000 || c.ReportRewardLimit != 10 {
		t.Fatalf("%+v", c)
	}
	if !reflect.DeepEqual(c.BuyCosts, []int64{20, 30, 50, 70, 80, 100, 100, 200, 200, 200}) {
		t.Fatal(c.BuyCosts)
	}
	if m := c.Missions[0]; m.ID != 10001 || m.Teams != 1 || m.Reward != [2]int64{20001157, 1} {
		t.Fatal(m)
	}
	if c.Missions[1].Teams != 2 || c.Loops[2].Reward != [2]int64{50001480, 8} {
		t.Fatal(c.Missions[1], c.Loops[2])
	}
	broken := c
	broken.Missions = append([]d.Mission(nil), c.Missions...)
	broken.Missions[3].NextID = 10001
	if broken.Validate() == nil {
		t.Fatal("broken chain accepted")
	}
}

func TestModeDayRollsAtFiveGMT8(t *testing.T) {
	c := modeCatalog(t)
	before := time.Date(2026, 10, 20, 20, 59, 59, 0, time.UTC) // 04:59:59 GMT+8
	m := c.NewMode(100001, before.Add(-time.Hour))
	m.LeftTimes, m.BuyTimes, m.AwardTimes, m.Buff = 2, 3, 4, 5
	if got := c.Rolled(m, before); got.LeftTimes != 2 || got.BuyTimes != 3 {
		t.Fatal(got)
	}
	got := c.Rolled(m, before.Add(time.Second))
	if got.LeftTimes != 10 || got.BuyTimes != 0 || got.AwardTimes != 0 || got.Buff != 5 || got.Day != m.Day+1 {
		t.Fatal(got)
	}
}

func TestModeStartSettleAndPromotion(t *testing.T) {
	c := modeCatalog(t)
	at := time.Unix(1_800_000_000, 0)
	run := c.InitialRun("g1")
	run.CurrentID, run.PassedID = 10002, 10001
	progress := d.Progress{Level: 1, Loop: 1}
	m := c.NewMode(100001, at)
	if _, e := c.Start(m, run, []int64{1, 1}, 0); !errors.Is(e, d.ErrInvalid) {
		t.Fatal("duplicate girls", e)
	}
	if _, e := c.Start(m, run, []int64{1, 2, 3, 4, 5, 6, 7}, 0); !errors.Is(e, d.ErrInvalid) {
		t.Fatal("seven girls", e)
	}
	m, e := c.Start(m, run, []int64{11, 12}, 7)
	if e != nil || m.LeftTimes != 9 {
		t.Fatal(m, e)
	}
	lost, e := c.Settle(m, run, progress, d.Result{CampaignID: 10002, TeamID: 1, Formation: []int64{11, 12}, Pet: 7}, "a1")
	if e != nil || lost.Mode.Buff != 1 || lost.Promoted || lost.KeepReport || lost.Attempt.ID != "a1" || lost.Attempt.MissionID != 10002 {
		t.Fatal(lost, e)
	}
	if _, e = c.Settle(lost.Mode, run, progress, d.Result{CampaignID: 10002, TeamID: 1, Formation: []int64{11, 12}, Pet: 7}, ""); !errors.Is(e, d.ErrRefused) {
		t.Fatal("settled without a Combat attempt", e)
	}
	m, _ = c.Start(lost.Mode, run, []int64{11, 12}, 7)
	if _, e = c.Settle(m, run, progress, d.Result{CampaignID: 10001, TeamID: 1, Formation: []int64{11, 12}, Pet: 7, Win: true}, "a2"); !errors.Is(e, d.ErrRefused) {
		t.Fatal("campaign mismatch", e)
	}
	won, e := c.Settle(m, run, progress, d.Result{CampaignID: 10002, TeamID: 1, Formation: []int64{11, 12}, Pet: 7, Win: true, Alive: 2, Damage: 9}, "a2")
	if e != nil || won.Promoted || !won.KeepReport || !reflect.DeepEqual(won.Mode.BeatenTeams, []int64{1}) || won.Mode.Buff != 1 {
		t.Fatal(won, e)
	}
	if _, e = c.Settle(won.Mode, run, progress, d.Result{CampaignID: 10002, TeamID: 1, Formation: []int64{13}, Win: true}, "a3"); !errors.Is(e, d.ErrRefused) {
		t.Fatal("beaten team", e)
	}
	if _, e = c.Start(won.Mode, run, []int64{12, 13}, 0); !errors.Is(e, d.ErrRefused) {
		t.Fatal("used girl", e)
	}
	if _, e = c.Start(won.Mode, run, []int64{13}, 7); !errors.Is(e, d.ErrRefused) {
		t.Fatal("used pet", e)
	}
	m, _ = c.Start(won.Mode, run, []int64{13}, 0)
	promoted, e := c.Settle(m, run, progress, d.Result{CampaignID: 10002, TeamID: 2, Formation: []int64{13}, Win: true, ReportInvalid: true}, "a3")
	if e != nil || !promoted.Promoted || promoted.KeepReport || promoted.Mode.Buff != 0 || promoted.Mode.LeftTimes != 10 || len(promoted.Mode.UsedHeroes) != 0 {
		t.Fatal(promoted, e)
	}
	if promoted.Progress != (d.Progress{Level: 2, Loop: 1}) || promoted.Run.CurrentID != 10003 || promoted.Run.PassedID != 10002 || !reflect.DeepEqual(promoted.Rewards, [][2]int64{{50001346, 1}}) {
		t.Fatal(promoted)
	}
}

func TestModeLoopTransitionAndEnd(t *testing.T) {
	c := modeCatalog(t)
	at := time.Unix(1_800_000_000, 0)
	for _, x := range []struct {
		loop     int64
		wantRun  d.Run
		wantLoop int64
	}{{1, d.Run{Loop: 2, CurrentID: 10001, Generation: "g"}, 2}, {8, d.Run{Loop: 9, CurrentID: 10056, PassedID: 10056, Generation: "g"}, 9}} {
		run := d.Run{Loop: x.loop, CurrentID: 10056, PassedID: 10055, Generation: "g"}
		m, e := c.Start(c.NewMode(100001, at), run, []int64{1}, 0)
		if e != nil {
			t.Fatal(e)
		}
		out, e := c.Settle(m, run, d.Progress{Level: 55, Loop: x.loop}, d.Result{CampaignID: 10056, TeamID: 1, Formation: []int64{1}, Win: true}, "a")
		if e != nil || out.Run != x.wantRun || out.Progress != (d.Progress{Level: 56, Loop: x.wantLoop}) || len(out.Rewards) != 2 || out.Rewards[1] != c.Loops[x.loop-1].Reward {
			t.Fatal(x.loop, out, e)
		}
		if x.loop == 8 && !c.Ended(out.Run) {
			t.Fatal("run after loop 8 not ended")
		}
	}
	ended := d.Run{Loop: 9, CurrentID: 10056, PassedID: 10056, Generation: "g"}
	if _, e := c.Start(c.NewMode(100001, at), ended, []int64{1}, 0); !errors.Is(e, d.ErrRefused) {
		t.Fatal("start after end", e)
	}
	if _, e := c.Reset(c.NewMode(100001, at), ended); !errors.Is(e, d.ErrRefused) {
		t.Fatal("reset after end", e)
	}
}

func TestModeResetBuyBuffCapAndViews(t *testing.T) {
	c := modeCatalog(t)
	at := time.Unix(1_800_000_000, 0)
	run := c.InitialRun("g")
	m := c.NewMode(100001, at)
	m.Buff, m.LeftTimes, m.BeatenTeams, m.UsedHeroes, m.UsedPets = 10, 3, []int64{1}, []int64{4}, []int64{5}
	reset, e := c.Reset(m, run)
	if e != nil || reset.Buff != 10 || reset.LeftTimes != 3 || len(reset.BeatenTeams)+len(reset.UsedHeroes)+len(reset.UsedPets) != 0 {
		t.Fatal(reset, e)
	}
	started, _ := c.Start(reset, run, []int64{1}, 0)
	lost, _ := c.Settle(started, run, d.Progress{Loop: 1}, d.Result{CampaignID: 10001, TeamID: 1, Formation: []int64{1}}, "a")
	if lost.Mode.Buff != 10 {
		t.Fatal("buff cap", lost.Mode.Buff)
	}
	if _, _, e = c.Buy(m, false); !errors.Is(e, d.ErrRefused) {
		t.Fatal("buy without privilege", e)
	}
	var spent int64
	for range 10 {
		var cost int64
		if m, cost, e = c.Buy(m, true); e != nil {
			t.Fatal(e)
		}
		spent += cost
	}
	if _, _, e = c.Buy(m, true); !errors.Is(e, d.ErrRefused) || spent != 1050 || m.LeftTimes != 13 {
		t.Fatal(spent, m.LeftTimes, e)
	}
	owner := c.NewMode(100002, at)
	rewarded := 0
	for range 12 {
		var ok bool
		if owner, ok = c.RewardView(owner, at); ok {
			rewarded++
		}
	}
	if rewarded != 10 || owner.AwardTimes != 10 {
		t.Fatal(rewarded, owner.AwardTimes)
	}
	if c.Score(2, 5) <= c.Score(1, 999_999_999) {
		t.Fatal("survivors rank first within the source ratio")
	}
}

func TestConquerRegionCount(t *testing.T) {
	c := catalog(t)
	for _, x := range []struct {
		progress d.Progress
		want     int64
	}{{d.Progress{Level: 0, Loop: 1}, 0}, {d.Progress{Level: 19, Loop: 1}, 0}, {d.Progress{Level: 20, Loop: 1}, 1}, {d.Progress{Level: 56, Loop: 1}, 5}, {d.Progress{Level: 1, Loop: 2}, 5}} {
		if got, e := c.Region(x.progress); e != nil || got != x.want {
			t.Fatal(x.progress, got, e)
		}
	}
}
