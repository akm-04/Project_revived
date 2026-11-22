//go:build postgres

package playerdisplay_test

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	projection "gxb.local/backend/v2/internal/projection/topfloor"
)

// TestL2TaskFormationLeaderNative proves the 295 ARENA_MODE_QUERY_FORMATION
// reply carries the stored task-mode leader to the Display and marks exactly
// that hero row for the stock client's is_leader check.
func TestL2TaskFormationLeaderNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, starter := topFloorPlayer(t, database, server)
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	clock := &workplaceTime{at: taskRotationForRule(t, catalog, func(rule d.TaskModeRule) bool {
		return rule.ID == d.TaskModeLeader
	})}
	service.Timed.Binder.Time = clock
	exec(t, database, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(actor.PlayerID))
	earnTaskChallenges(t, database, service, actor, starter, clock)

	formation := []int64{starter.PartnerID}
	summoner := ownerSummoner(database)
	for _, table := range []int64{10001002, 10001003, 10001004, 10001005} {
		resources := collectionResources(t, database, actor, revision, table)
		created, summonErr := summoner.SummonNormal(ctx, actor, table, resources.Template.FragmentItemID, resources.FragmentCount, op())
		if summonErr != nil {
			t.Fatalf("summon %d: %v", table, summonErr)
		}
		formation = append(formation, created.Ref().PartnerID)
	}
	leader := formation[0]
	if err = service.SaveTaskDefense(ctx, actor, d.TaskModeDefense{Heroes: formation, Leader: leader}, op()); err != nil {
		t.Fatal("save leader defense", err)
	}

	display, err := service.TaskFormation(ctx, actor, int64(actor.PlayerID))
	if err != nil {
		t.Fatal(err)
	}
	if display.Leader != leader {
		t.Fatalf("display leader %d, want %d", display.Leader, leader)
	}
	row := projection.Formation(display)
	heroes, ok := row["heros"].([]map[string]any)
	if !ok || len(heroes) != len(formation) {
		t.Fatalf("formation heroes %#v", row["heros"])
	}
	marked := 0
	for _, hero := range heroes {
		value, _ := hero["is_leader"].(int64)
		if value <= 0 {
			continue
		}
		marked++
		if hero["partner_id"] != leader {
			t.Fatalf("leader mark on partner %#v, want %d", hero["partner_id"], leader)
		}
	}
	if marked != 1 {
		t.Fatalf("leader marks %d, want exactly 1: %#v", marked, heroes)
	}
}
