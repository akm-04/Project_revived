package eventcentre

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func boardCatalog() Catalog {
	return Catalog{
		Board: map[int64]BoardRule{
			1: {Level: 1, TaskLimit: 2, GoldTask: 0},
			5: {Level: 5, TaskLimit: 3, GoldTask: 1},
		},
		Missions: map[int64]MissionRule{
			10001: {ID: 10001, HeroID: 10001001, FightID: 9600101, Fighting: 2000, Duration: 21600, Deposit: 50000, EnemyIDs: make([]int64, 5), MonsterStars: make([]int64, 5), MonsterQualities: make([]int64, 5), MonsterLevels: make([]int64, 5)},
			10002: {ID: 10002, HeroID: 10001001, FightID: 9600102, Fighting: 5000, Duration: 28800, Deposit: 60000, EnemyIDs: make([]int64, 5), MonsterStars: make([]int64, 5), MonsterQualities: make([]int64, 5), MonsterLevels: make([]int64, 5)},
			10003: {ID: 10003, HeroID: 10001001, FightID: 9600103, Fighting: 9000, Duration: 36000, Deposit: 70000, EnemyIDs: make([]int64, 5), MonsterStars: make([]int64, 5), MonsterQualities: make([]int64, 5), MonsterLevels: make([]int64, 5)},
		},
		HeroProfiles: map[int64]HeroProfileRule{
			10001001: {HeroID: 10001001, MissionIDs: []int64{10001, 10002, 10003}, ForceThresholds: []int64{1500, 4000, 8000}},
		},
		Awards: map[int64]AwardRule{
			10001: {ID: 10001, Grade: 1, ItemID: 60001020, ItemCount: 1, MaterialIDs: []int64{11, 12}, MaterialAmounts: []int64{3250, 3200}, Gold: 500000},
			10002: {ID: 10002, Grade: 1, ItemID: 0, ItemCount: 0, MaterialIDs: []int64{11}, MaterialAmounts: []int64{6500}, Gold: 500000},
			11001: {ID: 11001, Grade: 2, ItemID: 60001027, ItemCount: 1, MaterialIDs: []int64{11}, MaterialAmounts: []int64{7650}, Gold: 600000},
			12001: {ID: 12001, Grade: 3, ItemID: 60001037, ItemCount: 1, MaterialIDs: []int64{12}, MaterialAmounts: []int64{14000}, Gold: 700000},
		},
	}
}

func TestBoardOffersRespectLevelOwnershipAndLimit(t *testing.T) {
	catalog := boardCatalog()
	player := identity.PlayerID(7)
	owned := map[int64]bool{10001001: true}
	offers := catalog.BoardOffers(1, 1, owned, 3, player)
	if len(offers) != 1 || offers[0].MissionID != 10001 || offers[0].Type != BoardTaskTypeNormal {
		t.Fatalf("level 1 offers = %+v", offers)
	}
	for _, offer := range offers {
		if offer.Type != BoardTaskTypeNormal {
			t.Fatalf("level 1 type = %+v", offer)
		}
	}
	again := catalog.BoardOffers(1, 1, owned, 3, player)
	if len(again) != len(offers) || again[0] != offers[0] {
		t.Fatalf("offers are not deterministic: %+v %+v", offers, again)
	}
	if other := catalog.BoardOffers(1, 1, map[int64]bool{}, 3, player); len(other) != 0 {
		t.Fatalf("unowned hero offered %+v", other)
	}
	if lowLevel := catalog.BoardOffers(5, 1, owned, 3, player); len(lowLevel) != 1 {
		t.Fatalf("tier gate ignored at level 1: %+v", lowLevel)
	}
}

func TestBoardOffersDepositTasksUseGradeTwoAward(t *testing.T) {
	catalog := boardCatalog()
	offers := catalog.BoardOffers(5, 20, map[int64]bool{10001001: true}, 3, identity.PlayerID(7))
	if len(offers) != 3 {
		t.Fatalf("level 5 offers = %+v", offers)
	}
	deposits := 0
	for _, offer := range offers {
		award, ok := catalog.Award(offer.AwardID)
		if !ok {
			t.Fatalf("unknown award %+v", offer)
		}
		if offer.Type == BoardTaskTypeDeposit {
			deposits++
			if award.Grade != 2 || offer.MissionID != 10003 {
				t.Fatalf("deposit offer = %+v award = %+v", offer, award)
			}
		}
		_, tier, _ := catalog.MissionTier(offer.MissionID)
		if offer.Type == BoardTaskTypeNormal && award.Grade != tier {
			t.Fatalf("normal award grade %d for tier %d", award.Grade, tier)
		}
	}
	if deposits != 1 {
		t.Fatalf("deposit tasks = %d offers %+v", deposits, offers)
	}
	sameDay := catalog.BoardOffers(5, 20, map[int64]bool{10001001: true}, 3, identity.PlayerID(7))
	if len(sameDay) != 3 || sameDay[0] != offers[0] || sameDay[2] != offers[2] {
		t.Fatalf("same-day offers changed: %+v %+v", offers, sameDay)
	}
	nextDay := catalog.BoardOffers(5, 20, map[int64]bool{10001001: true}, 4, identity.PlayerID(7))
	if len(nextDay) != 3 {
		t.Fatalf("next-day offers = %+v", nextDay)
	}
}

func TestMissionTierAndCap(t *testing.T) {
	catalog := boardCatalog()
	profile, tier, ok := catalog.MissionTier(10002)
	if !ok || tier != 2 || profile.HeroID != 10001001 {
		t.Fatalf("tier = %d profile = %+v ok = %v", tier, profile, ok)
	}
	cap, ok := catalog.CapFor(10003)
	if !ok || cap != 8000 {
		t.Fatalf("cap = %d ok = %v", cap, ok)
	}
	if _, ok = catalog.CapFor(99999); ok {
		t.Fatal("unknown mission has a cap")
	}
}

func TestWinAwardWishDoublesEveryLine(t *testing.T) {
	catalog := boardCatalog()
	plain, ok := catalog.WinAward(10001, false)
	if !ok || plain.Gold != 500000 || plain.ItemCount != 1 || plain.Materials[0].Amount != 3250 || plain.Materials[1].Amount != 3200 {
		t.Fatalf("plain award = %+v %v", plain, ok)
	}
	wished, ok := catalog.WinAward(10001, true)
	if !ok || wished.Gold != 1000000 || wished.ItemCount != 2 || wished.Materials[0].Amount != 6500 || wished.Materials[1].Amount != 6400 {
		t.Fatalf("wished award = %+v %v", wished, ok)
	}
	if _, ok = catalog.WinAward(55555, false); ok {
		t.Fatal("unknown award granted")
	}
}

func TestBoardStateRejectsBusyHeroAndBoundsHistory(t *testing.T) {
	state := BoardState{NextReportID: 1, Doing: []BoardMission{
		{MissionID: 10001, Leader: 11, Partners: []int64{12}, StartAt: 1, Type: BoardTaskTypeNormal, AwardID: 10001},
	}}
	if err := state.Validate(); err != nil {
		t.Fatal(err)
	}
	state.Doing = append(state.Doing, BoardMission{MissionID: 10002, Leader: 12, StartAt: 1, Type: BoardTaskTypeNormal, AwardID: 10001})
	if err := state.Validate(); err == nil {
		t.Fatal("busy partner accepted")
	}
	if busy := state.BusyHeroes(); !busy[11] || !busy[12] {
		t.Fatalf("busy heroes = %+v", busy)
	}
	history := BoardState{NextReportID: 1}
	for index := 0; index < BoardHistoryLimit+5; index++ {
		history.AppendHistory(BoardRun{MissionID: 10001, Win: index%2 == 0, ReportID: int64(index + 1)})
	}
	if len(history.History) != BoardHistoryLimit || history.History[0].ReportID != int64(BoardHistoryLimit+5) {
		t.Fatalf("history bounds = %d first %+v", len(history.History), history.History[0])
	}
	if err := history.Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestDueMissionsUsesTableDuration(t *testing.T) {
	catalog := boardCatalog()
	state := BoardState{NextReportID: 1, Doing: []BoardMission{
		{MissionID: 10001, Leader: 11, StartAt: 100, Type: BoardTaskTypeNormal, AwardID: 10001},
		{MissionID: 10002, Leader: 12, StartAt: 100, Type: BoardTaskTypeNormal, AwardID: 10001},
	}}
	due := state.DueMissions(100+21600, catalog)
	if len(due) != 1 || due[0].MissionID != 10001 {
		t.Fatalf("due at 21700 = %+v", due)
	}
	if due = state.DueMissions(100+28800, catalog); len(due) != 2 {
		t.Fatalf("due at 28900 = %+v", due)
	}
}

func TestBoardWireFieldPaths(t *testing.T) {
	state := BoardState{NextReportID: 2,
		Offers:   []BoardOffer{{MissionID: 10001, Type: 1, AwardID: 10001}},
		Doing:    []BoardMission{{MissionID: 10002, Leader: 11, Partners: []int64{12}, StartAt: 55, Type: 2, AwardID: 11001}},
		History:  []BoardRun{{MissionID: 10001, Win: true, ReportID: 7}},
		AwardLog: []BoardAward{{MissionID: 10001, Type: 1, AwardID: 10001, WishCrystal: 1}},
	}
	body := BoardWire(state)
	offers := body["mission_list"].([]any)
	offer := offers[0].(map[string]any)
	if offer["mission_id"] != int64(10001) || offer["type"] != int64(1) || offer["award_id"] != int64(10001) {
		t.Fatalf("offer wire = %+v", offer)
	}
	doing := body["doing_mission_list"].([]any)[0].(map[string]any)
	if doing["mission_id"] != int64(10002) || doing["leader"] != int64(11) || doing["start_time"] != int64(55) || len(doing["partners"].([]any)) != 1 {
		t.Fatalf("doing wire = %+v", doing)
	}
	finish := body["finish_mission_list"].([]any)[0].(map[string]any)
	if finish["mission_id"] != int64(10001) || finish["is_win"] != int64(1) || finish["battle_id"] != int64(7) {
		t.Fatalf("finish wire = %+v", finish)
	}
	award := body["award_log"].([]any)[0].(map[string]any)
	if award["mission_id"] != int64(10001) || award["type"] != int64(1) || award["award_id"] != int64(10001) || award["wish_crystal"] != int64(1) {
		t.Fatalf("award log wire = %+v", award)
	}
}

func TestSettleRecycleStillWorksWithBoardFacts(t *testing.T) {
	state := Seed()
	at := time.Unix(1000, 0).UTC()
	if err := SettleRecycle(&state.Recycle, 10, 15, at); err != nil {
		t.Fatal(err)
	}
	if err := state.Validate(); err != nil {
		t.Fatal(err)
	}
}
