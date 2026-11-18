package occult

import (
	"encoding/json"
	"errors"
	"os"
	"slices"
	"testing"
)

func generatedCatalog(t *testing.T) Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/occult_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog Catalog
	if err := json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	if err := catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func TestGeneratedCatalogRoutesAndRewards(t *testing.T) {
	catalog := generatedCatalog(t)
	route, ok := catalog.RouteFor(1171001, 2)
	if !ok || route.FragmentItem != 60001170 {
		t.Fatalf("route=%+v ok=%v", route, ok)
	}
	if _, ok := catalog.RouteFor(1171001, 3); ok {
		t.Fatal("route must match its chapter")
	}
	if _, ok := catalog.FragmentReward(1171001, 1); ok {
		t.Fatal("chapter 1 has no routes")
	}
	fragment, _ := catalog.FragmentReward(1171001, 2)
	if fragment != (Reward{ItemID: 60001170, Quantity: 30}) {
		t.Fatalf("fragment=%+v", fragment)
	}
	clear, err := catalog.ClearRewards(2)
	if err != nil || len(clear) != 4 || clear[0] != (Reward{ItemID: 50010002, Quantity: 1}) {
		t.Fatalf("clear=%+v err=%v", clear, err)
	}
	if _, err := catalog.ClearRewards(9); !errors.Is(err, ErrInvalid) {
		t.Fatalf("unknown chapter err=%v", err)
	}
}

func TestSweepRewardsFloorSixtyPercentAtLeastOne(t *testing.T) {
	catalog := Catalog{SweepPercent: 60, Chapters: []Chapter{{ID: 1, ItemDisplay: []int64{7}}}}
	rewards, err := catalog.SweepRewards(1)
	if err != nil || rewards[0].Quantity != 1 {
		t.Fatalf("sweep=%+v err=%v", rewards, err)
	}
	if got := max(int64(10)*catalog.SweepPercent/100, 1); got != 6 {
		t.Fatalf("floor(60%% of 10)=%d", got)
	}
	if got := max(int64(1)*catalog.SweepPercent/100, 1); got != 1 {
		t.Fatalf("floor(60%% of 1)=%d", got)
	}
}

func TestAccrueTickets(t *testing.T) {
	cases := []struct{ tickets, progress, spent, wantTickets, wantProgress int64 }{
		{0, 0, 2999, 0, 2999},
		{0, 2999, 1, 1, 0},
		{0, 2000, 2000, 1, 1000},
		{1, 2500, 6000, 2, 0},
		{2, 100, 6000, 2, 0},
		{0, 0, 0, 0, 0},
	}
	for _, c := range cases {
		tickets, progress := AccrueTickets(c.tickets, c.progress, c.spent)
		if tickets != c.wantTickets || progress != c.wantProgress {
			t.Fatalf("%+v got %d %d", c, tickets, progress)
		}
	}
}

func TestScoresBestUnlocksSweep(t *testing.T) {
	scores := Scores{}
	if scores.SweepUnlocked(2) {
		t.Fatal("no score unlocks nothing")
	}
	scores, improved := scores.Record(2, 40)
	if !improved || !scores.SweepUnlocked(2) || scores.SweepUnlocked(3) {
		t.Fatalf("scores=%v", scores)
	}
	same, improved := scores.Record(2, 40)
	lower, lowerImproved := same.Record(2, 10)
	if improved || lowerImproved || lower.Best(2) != 40 {
		t.Fatalf("best kept: %v", lower)
	}
	loaded, err := LoadScores(json.RawMessage(`{"2":40}`))
	if err != nil || loaded.Best(2) != 40 {
		t.Fatalf("loaded=%v err=%v", loaded, err)
	}
}

func TestTimers(t *testing.T) {
	run := NewRun(2, MultiCampaignType)
	if run.RoomExpired(10_000) || run.SelectionExpired(10_000) || run.FightExpired(10_000) {
		t.Fatal("unstarted timers never expire")
	}
	if err := run.Start(1000); err != nil || run.Start(1001) == nil {
		t.Fatal("start once")
	}
	if run.RoomExpired(3999) || !run.RoomExpired(4000) {
		t.Fatal("room lasts 3000 s")
	}
	run.BeginSelection(2000)
	run.BeginFight(2000)
	if run.SelectionExpired(2059) || !run.SelectionExpired(2060) || run.FightExpired(2149) || !run.FightExpired(2150) {
		t.Fatal("selection 60 s, fight 150 s")
	}
	run.MarkLeft(7, 2000)
	if run.CanReenter(7, 2119) || !run.CanReenter(7, 2120) || !run.CanReenter(8, 2000) {
		t.Fatal("re-entry 120 s per player")
	}
}

func TestStagesInBattleArePlayerIDs(t *testing.T) {
	run := NewRun(2, MultiCampaignType)
	if run.BindStages(20003, nil) == nil || run.BindStages(20003, []int64{0}) == nil {
		t.Fatal("empty and zero HP stages refused")
	}
	if err := run.BindStages(20003, []int64{500, 700}); err != nil {
		t.Fatal(err)
	}
	if err := run.Enter(20003, 0, 11); err != nil {
		t.Fatal(err)
	}
	if run.Stages["20003"][0].InBattle != 11 {
		t.Fatal("in_battle holds the player id")
	}
	if !errors.Is(run.Enter(20003, 0, 12), ErrRefused) || !errors.Is(run.Enter(20003, 1, 11), ErrRefused) {
		t.Fatal("occupied stage and double fight refused")
	}
	run.Release(11)
	if run.Stages["20003"][0].InBattle != 0 || run.Enter(20003, 1, 11) != nil {
		t.Fatal("an abandoned fight can start again")
	}
	if err := run.BindStages(20003, []int64{1, 1}); err != nil || run.Stages["20003"][0].TotalHP != 500 {
		t.Fatal("rebinding keeps monster HP")
	}
	if !errors.Is(run.Enter(20003, 5, 11), ErrInvalid) {
		t.Fatal("unknown stage")
	}
}

func TestSoloResultClampsAndHeroStatusIsAuthority(t *testing.T) {
	run := NewRun(2, SingleCampaignType)
	_ = run.BindStages(20002, []int64{500})
	if _, err := run.ApplySolo(11, 20002, 0, SoloReport{Star: 3}, nil, 0, false); !errors.Is(err, ErrRefused) {
		t.Fatalf("a player who never entered cannot report: %v", err)
	}
	_ = run.Enter(20002, 0, 11)
	limits := map[int64]int64{1: 200, 2: 200}
	first, err := run.ApplySolo(11, 20002, 0, SoloReport{Star: 9, Score: -5, Heroes: map[int64]HeroStatus{1: {HP: 40, MP: 400}, 2: {HP: -3, MP: 10}}}, limits, 0, false)
	if err != nil || first != (SoloResult{Won: true, Star: 3, Score: 0}) {
		t.Fatalf("first=%+v err=%v", first, err)
	}
	if !run.Cleared(20002) || run.Stages["20002"][0].InBattle != 0 {
		t.Fatal("a win empties the stage and releases the player")
	}
	if got, _ := run.Status(11, 1); got != (HeroStatus{HP: 40, MP: 400, LimitHP: 200}) {
		t.Fatalf("hero 1=%+v", got)
	}
	if got, _ := run.Status(11, 2); got != (HeroStatus{HP: 0, MP: 10, LimitHP: 200}) {
		t.Fatalf("hero 2=%+v", got)
	}
	_ = run.BindStages(20003, []int64{500})
	_ = run.Enter(20003, 0, 11)
	if _, err := run.ApplySolo(11, 20003, 0, SoloReport{Star: 0, Heroes: map[int64]HeroStatus{1: {HP: 90, MP: 5}}}, limits, 250, true); err != nil {
		t.Fatal(err)
	}
	if got, _ := run.Status(11, 1); got != (HeroStatus{HP: 40, MP: 5, LimitHP: 200}) || run.Cleared(20003) {
		t.Fatalf("a result cannot heal and a loss keeps the stage: %+v", got)
	}
	if run.Stages["20003"][0].HP != 250 {
		t.Fatalf("a loss stores the absolute monster HP: %d", run.Stages["20003"][0].HP)
	}
}

func TestSoloRefusesMoreHeroesThanDispatchLimit(t *testing.T) {
	run := NewRun(2, SingleCampaignType)
	run.DispatchLimit = 1
	_ = run.BindStages(20002, []int64{500})
	_ = run.Enter(20002, 0, 11)
	_, err := run.ApplySolo(11, 20002, 0, SoloReport{Star: 1, Heroes: map[int64]HeroStatus{1: {HP: 1, MP: 1}, 2: {HP: 1, MP: 1}}}, map[int64]int64{1: 10, 2: 10}, 0, false)
	if !errors.Is(err, ErrRefused) {
		t.Fatalf("err=%v", err)
	}
}

func TestPrepareEventsApplyOnce(t *testing.T) {
	catalog := Catalog{EventPercent: 30, EventDispatch: 3}
	intro := Campaign{ID: 20003, EventID: int64(EventIncreaseDispatch)}
	run := NewRun(2, MultiCampaignType)
	outcomes := run.TriggerEvent(catalog, intro)
	if len(outcomes) != 1 || outcomes[0].Type != EventIncreaseDispatch || outcomes[0].DispatchLimit != DispatchLimit+3 || run.DispatchLimit != DispatchLimit+3 {
		t.Fatalf("dispatch event %+v limit=%d", outcomes, run.DispatchLimit)
	}
	if len(run.TriggerEvent(catalog, intro)) != 0 || run.DispatchLimit != DispatchLimit+3 {
		t.Fatal("a dispatch event fires once per campaign")
	}
	_ = run.BindStages(20004, []int64{500, 500})
	_ = run.Enter(20004, 0, 11)
	autoPass := Campaign{ID: 20004, EventID: int64(EventAutoPass)}
	if outcomes = run.TriggerEvent(catalog, autoPass); len(outcomes) != 1 || !run.Cleared(20004) || run.Stages["20004"][0].InBattle != 0 {
		t.Fatalf("auto pass outcomes=%v", outcomes)
	}
	if len(run.TriggerEvent(catalog, autoPass)) != 0 {
		t.Fatal("an auto pass fires once per campaign")
	}
}

func TestClearResultEventsDoNotFireAtPrepare(t *testing.T) {
	catalog := generatedCatalog(t)
	cases := []struct {
		campaignID   int64
		chapterID    int64
		campaignType int64
	}{
		{30002, 3, MultiCampaignType},
		{30016, 3, SingleCampaignType},
		{30007, 3, MultiCampaignType},
		{40015, 4, SingleCampaignType},
	}
	for _, c := range cases {
		campaign, found := catalog.Campaign(c.campaignID)
		if !found {
			t.Fatalf("campaign %d missing", c.campaignID)
		}
		run := NewRun(c.chapterID, c.campaignType)
		if err := run.BindRoom(catalog); err != nil {
			t.Fatal(err)
		}
		run.HeroStatus = map[string]map[string]HeroStatus{key(11): {
			key(1): {HP: 50, MP: 100, LimitHP: 100},
			key(2): {HP: 0, MP: 0, LimitHP: 100},
		}}
		if outcomes := run.TriggerEvent(catalog, campaign); len(outcomes) != 0 {
			t.Fatalf("campaign %d applied %v at prepare", c.campaignID, outcomes)
		}
		if slices.Contains(run.EventsDone, campaign.ID) || run.ExtraPoints != 0 {
			t.Fatalf("campaign %d was consumed at prepare: done=%v extra=%d", c.campaignID, run.EventsDone, run.ExtraPoints)
		}
		if status, _ := run.Status(11, 1); status.HP != 50 || status.MP != 100 {
			t.Fatalf("campaign %d changed the final team before a result: %+v", c.campaignID, status)
		}
		if status, _ := run.Status(11, 2); status.HP != 0 {
			t.Fatalf("campaign %d revived a dead girl before a result: %+v", c.campaignID, status)
		}
	}
}

func TestClearEventRecoversOnlyTheAcceptedFinalTeam(t *testing.T) {
	catalog := generatedCatalog(t)
	campaign, _ := catalog.Campaign(30002)
	run := NewRun(3, MultiCampaignType)
	if err := run.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	run.HeroStatus = map[string]map[string]HeroStatus{key(11): {
		key(1): {HP: 50, MP: 100, LimitHP: 200},
		key(2): {HP: 10, MP: 200, LimitHP: 200},
	}}
	finalTeam := []CampaignHero{{PlayerID: 11, HeroID: 1}}
	run.RecordCampaignHeroes(campaign.ID, append(finalTeam, CampaignHero{PlayerID: 11, HeroID: 2}))
	if len(run.ClearEvents(catalog, campaign, finalTeam)) != 0 {
		t.Fatal("an uncleared campaign applied its clear event")
	}
	for index := range run.Stages["30002"] {
		run.Stages["30002"][index].HP = 0
	}
	outcomes := run.ClearEvents(catalog, campaign, finalTeam)
	if len(outcomes) != 1 || outcomes[0].Type != EventRecoverHP {
		t.Fatalf("outcomes=%v", outcomes)
	}
	if status, _ := run.Status(11, 1); status.HP != 110 || status.MP != 100 {
		t.Fatalf("the final team was not healed by 30%%: %+v", status)
	}
	if status, _ := run.Status(11, 2); status.HP != 10 || status.MP != 200 {
		t.Fatalf("a girl outside the final team was healed: %+v", status)
	}
	if len(run.ClearEvents(catalog, campaign, finalTeam)) != 0 {
		t.Fatal("a clear event fires once per campaign")
	}
}

func TestClearEventRevivesOnlyTheFinalTeamDead(t *testing.T) {
	catalog := generatedCatalog(t)
	campaign, _ := catalog.Campaign(30007)
	run := NewRun(3, MultiCampaignType)
	if err := run.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	run.HeroStatus = map[string]map[string]HeroStatus{key(11): {
		key(1): {HP: 0, MP: 0, LimitHP: 200},
		key(2): {HP: 0, MP: 0, LimitHP: 200},
	}}
	for index := range run.Stages["30007"] {
		run.Stages["30007"][index].HP = 0
	}
	outcomes := run.ClearEvents(catalog, campaign, []CampaignHero{{PlayerID: 11, HeroID: 1}})
	if len(outcomes) != 1 || outcomes[0].Type != EventReviveHero {
		t.Fatalf("outcomes=%v", outcomes)
	}
	if status, _ := run.Status(11, 1); status.HP != 60 {
		t.Fatalf("the final team's dead girl was not revived: %+v", status)
	}
	if status, _ := run.Status(11, 2); status.HP != 0 {
		t.Fatalf("a girl outside the final team was revived: %+v", status)
	}
}

func TestExtraPointHonoursEventConditionAndIsConsumedOnce(t *testing.T) {
	catalog := generatedCatalog(t)
	campaign, _ := catalog.Campaign(40015)
	run := NewRun(4, SingleCampaignType)
	if err := run.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	for index := range run.Stages["40015"] {
		run.Stages["40015"][index].HP = 0
	}
	eight := make([]CampaignHero, 0, campaign.EventCondition)
	for heroID := int64(1); heroID <= campaign.EventCondition; heroID++ {
		eight = append(eight, CampaignHero{PlayerID: 11, HeroID: heroID})
	}
	run.RecordCampaignHeroes(campaign.ID, eight)
	if outcomes := run.ClearEvents(catalog, campaign, eight); len(outcomes) != 1 || outcomes[0].Type != EventExtraPoint || outcomes[0].ExtraPoints != 1000 || run.ExtraPoints != 1000 || run.Points != 1000 {
		t.Fatalf("outcomes=%v extra=%d points=%d", outcomes, run.ExtraPoints, run.Points)
	}
	if len(run.ClearEvents(catalog, campaign, eight)) != 0 || run.ExtraPoints != 1000 || run.Points != 1000 {
		t.Fatalf("the bonus was granted twice: extra=%d points=%d", run.ExtraPoints, run.Points)
	}

	tooMany := NewRun(4, SingleCampaignType)
	if err := tooMany.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	for index := range tooMany.Stages["40015"] {
		tooMany.Stages["40015"][index].HP = 0
	}
	nine := make([]CampaignHero, 0, campaign.EventCondition+1)
	for heroID := int64(1); heroID <= campaign.EventCondition+1; heroID++ {
		nine = append(nine, CampaignHero{PlayerID: 11, HeroID: heroID})
	}
	tooMany.RecordCampaignHeroes(campaign.ID, nine)
	tooMany.RecordCampaignHeroes(campaign.ID, nine)
	if outcomes := tooMany.ClearEvents(catalog, campaign, nine); len(outcomes) != 0 || tooMany.ExtraPoints != 0 {
		t.Fatalf("nine girls passed condition %d: %v extra=%d", campaign.EventCondition, outcomes, tooMany.ExtraPoints)
	}
	if !slices.Contains(tooMany.EventsDone, campaign.ID) {
		t.Fatal("a missed clear event was not consumed with its clearance")
	}
	if len(tooMany.CampaignHeroes[key(campaign.ID)]) != int(campaign.EventCondition+1) {
		t.Fatalf("participants were not deduplicated: %v", tooMany.CampaignHeroes)
	}
}

func TestRunStateRoundTrip(t *testing.T) {
	run := NewRun(3, MultiCampaignType)
	_ = run.Start(500)
	_ = run.BindStages(30002, []int64{9})
	run.MarkLeft(4, 600)
	raw, err := run.Encode()
	if err != nil {
		t.Fatal(err)
	}
	loaded, err := LoadRunState(raw)
	if err != nil || loaded.StartedAt != 500 || loaded.Stages["30002"][0].TotalHP != 9 || loaded.LeftAt["4"] != 600 {
		t.Fatalf("loaded=%+v err=%v", loaded, err)
	}
}

func TestRoomMapReachabilityEventsAndChapterClear(t *testing.T) {
	catalog := generatedCatalog(t)
	run := NewRun(2, SingleCampaignType)
	if err := run.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	start, _ := catalog.Campaign(20010)
	first, _ := catalog.Campaign(20011)
	later, _ := catalog.Campaign(20012)
	if !run.Reachable(catalog, start) || !run.Reachable(catalog, first) || run.Reachable(catalog, later) {
		t.Fatal("only the start point and its unlocks are reachable at first")
	}
	for index := range run.Stages["20011"] {
		run.Stages["20011"][index].HP = 0
	}
	if !run.Reachable(catalog, later) || run.ChapterCleared(catalog) {
		t.Fatal("clearing a campaign opens its unlocks, not the chapter")
	}
	eventful, _ := catalog.Campaign(20014)
	if outcomes := run.TriggerEvent(catalog, eventful); len(outcomes) != 0 || run.ExtraPoints != 0 {
		t.Fatalf("event 6 fired at prepare: %+v extra=%d", outcomes, run.ExtraPoints)
	}
	for index := range run.Stages["20014"] {
		run.Stages["20014"][index].HP = 0
	}
	run.RecordCampaignHeroes(eventful.ID, []CampaignHero{{PlayerID: 11, HeroID: 1}})
	outcomes := run.ClearEvents(catalog, eventful, nil)
	if len(outcomes) != 1 || outcomes[0].Type != EventExtraPoint || outcomes[0].ExtraPoints != 2000 || run.ExtraPoints != 2000 {
		t.Fatalf("event 6 bonus %+v extra=%d", outcomes, run.ExtraPoints)
	}
	if len(run.ClearEvents(catalog, eventful, nil)) != 0 || run.ExtraPoints != 2000 {
		t.Fatal("the bonus event fires once per campaign")
	}
	autoPass := Campaign{ID: 20012, EventID: int64(EventAutoPass)}
	if outcomes := run.TriggerEvent(catalog, autoPass); len(outcomes) != 1 || !run.Cleared(20012) {
		t.Fatalf("auto pass outcomes=%v", outcomes)
	}
	if len(run.TriggerEvent(catalog, autoPass)) != 0 {
		t.Fatal("an event fires once per campaign")
	}
	final, _ := catalog.Campaign(20018)
	if !final.Final() || start.Final() {
		t.Fatal("final campaign unlocks nothing and is not a start point")
	}
	for index := range run.Stages["20018"] {
		run.Stages["20018"][index].HP = 0
	}
	if !run.ChapterCleared(catalog) {
		t.Fatal("final campaign cleared clears the chapter")
	}
}

func TestChapterProgressAndStockScore(t *testing.T) {
	catalog := generatedCatalog(t)
	run := NewRun(4, SingleCampaignType)
	if err := run.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	if got := run.ProgressFraction(catalog); got != 0 {
		t.Fatalf("fresh progress %v", got)
	}
	run.HeroStatus = map[string]map[string]HeroStatus{key(11): {
		"1": {HP: 100, MP: 800, LimitHP: 100}, "2": {HP: 50, MP: 900, LimitHP: 100}, "3": {HP: 1, MP: 1000, LimitHP: 100},
	}}
	run.BeginFight(1000)
	for index := range run.Stages["40010"] {
		run.Stages["40010"][index].HP = 0
	}
	progress := run.ProgressFraction(catalog)
	if progress <= 0 || progress >= 1 {
		t.Fatalf("one cleared stage progress %v", progress)
	}
	// one cleared sub-stage of seven -> 14%; 3 survivors, 87 unused slots,
	// 140 s left: (3*25 + 87*35 + 14*100 + 140*11)/10.
	if got, want := run.ChapterScore(catalog, 11, 1010, 0), int64(606); got != want {
		t.Fatalf("score %d want %d", got, want)
	}
	if got, want := run.ChapterScore(catalog, 11, 1010, 1000), int64(1606); got != want {
		t.Fatalf("score with bonus %d want %d", got, want)
	}
	if got := run.ScoreSeconds(1150); got != 0 {
		t.Fatalf("expired fight seconds %d", got)
	}
}

func TestSoloCarriesEnergyAboveThePreviousValue(t *testing.T) {
	run := NewRun(2, SingleCampaignType)
	_ = run.BindStages(20002, []int64{500})
	_ = run.Enter(20002, 0, 11)
	limits := map[int64]int64{1: 200}
	if _, err := run.ApplySolo(11, 20002, 0, SoloReport{Star: 3, Heroes: map[int64]HeroStatus{1: {HP: 150, MP: 700}}}, limits, 0, false); err != nil {
		t.Fatal(err)
	}
	_ = run.BindStages(20003, []int64{500})
	_ = run.Enter(20003, 0, 11)
	if _, err := run.ApplySolo(11, 20003, 0, SoloReport{Star: 3, Heroes: map[int64]HeroStatus{1: {HP: 150, MP: 950}}}, limits, 0, false); err != nil {
		t.Fatal(err)
	}
	got, _ := run.Status(11, 1)
	if got.MP != 950 || got.HP != 150 {
		t.Fatalf("energy must carry forward and HP must not rise: %+v", got)
	}
}

func TestTeamRoomRules(t *testing.T) {
	if !WithinLevelBand(90, 95, 5) || WithinLevelBand(90, 96, 5) || WithinLevelBand(96, 90, 5) {
		t.Fatal("the level band is five levels either way")
	}
	run := NewRun(2, MultiCampaignType)
	run.Invite(8)
	run.Invite(8)
	if len(run.Invites) != 1 || !run.Invited(8) || run.Invited(9) {
		t.Fatalf("invites %v", run.Invites)
	}
	if !run.MayJoin(9, 100) {
		t.Fatal("a first-time player may join before the start")
	}
	run.MarkLeft(9, 100)
	if run.MayJoin(9, 219) || !run.MayJoin(9, 220) {
		t.Fatal("re-entry waits 120 seconds")
	}
	if err := run.Start(300); err != nil {
		t.Fatal(err)
	}
	if run.MayJoin(10, 1000) || !run.MayJoin(9, 1000) {
		t.Fatal("after the start only a returning member may join")
	}
}

func TestEventLogKeepsTheNewestAndCountsOn(t *testing.T) {
	run := NewRun(2, MultiCampaignType)
	for range eventLogLimit + 4 {
		run.RecordEvents([]EventOutcome{{Type: EventIncreaseDispatch, DispatchLimit: 33}})
	}
	last := run.Events[len(run.Events)-1]
	if len(run.Events) != eventLogLimit || last.Sequence != eventLogLimit+4 || run.Events[0].Sequence != 5 || last.Type != 5 || last.DispatchLimit != 33 {
		t.Fatalf("events %+v", run.Events)
	}
}
