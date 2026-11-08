//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/topfloor"
)

// A chat card is opened by a player who did not fight: LOAD_ARENA_FIGHT_RECORDS
// with fighter_id and id must answer the stored report through the stock MID.
func TestI9_10HArenaReferenceReplayNonParticipantNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, hero := topFloorPlayer(t, database, server)
	viewer, _, _ := topFloorPlayer(t, database, server)
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Frozen(time.Now()) {
		t.Skip("21:00-21:30 GMT+8 settlement freeze admits no START")
	}
	view, err := service.Load(ctx, actor, op())
	if err != nil || len(view.Enemies) == 0 {
		t.Fatalf("load offers: %v", err)
	}
	if err = service.SaveDefense(ctx, actor, []int64{hero.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	enemy := view.Enemies[0]
	fight, err := service.Start(ctx, actor, topfloor.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: enemy.Occupant.TableID()}, op())
	if err != nil || len(fight.Report) == 0 {
		t.Fatalf("robot fight: %v", err)
	}
	records, err := service.Records(ctx, actor)
	if err != nil || len(records) != 1 {
		t.Fatalf("records: %v %d", err, len(records))
	}
	record := records[0].Record

	dispatcher := stockruntime.TopFloorDispatcher{Authority: playtestAuthority{viewer}, Service: service}
	response := dispatcher.Dispatch(ctx, playtestRequest(viewer, 289, map[string]any{"fighter_id": int64(actor.PlayerID), "id": record.ID}))
	if response.HTTPStatus != 200 {
		t.Fatalf("card replay: %+v", response)
	}
	replay, ok := response.Body["records"].(map[string]any)
	if !ok || len(replay) == 0 {
		t.Fatalf("card replay body: %+v", response.Body)
	}
	report, ok := replay["report"].([]map[string]any)
	if !ok || len(report) != 1 || report[0]["content"] != string(fight.Report) {
		t.Fatalf("card replay report: %+v", replay["report"])
	}
	if replay["is_attack"] != int64(1) || replay["win"] != boolFlag(fight.Win) || replay["attack_name"] == "" || replay["defend_name"] == "" {
		t.Fatalf("card replay row: %+v", replay)
	}

	missing := dispatcher.Dispatch(ctx, playtestRequest(viewer, 289, map[string]any{"fighter_id": int64(actor.PlayerID), "id": record.ID + 1000000}))
	if empty, ok := missing.Body["records"].(map[string]any); !ok || len(empty) != 0 {
		t.Fatalf("missing record must answer out of date: %+v", missing.Body)
	}
}

func boolFlag(v bool) int64 {
	if v {
		return 1
	}
	return 0
}
