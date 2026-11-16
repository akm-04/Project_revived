//go:build postgres

package playerdisplay_test

import (
	"testing"

	"gxb.local/backend/v2/internal/application/playerdisplay"
	projection "gxb.local/backend/v2/internal/projection/topfloor"
)

// TestL2TopFloorEnemyTitleNative proves a ranked opponent's selected title
// reaches the LOAD_ARENA/ARENA_MODE enemy face (DL-cff1b30a), which the stock
// ArenaWindow passes to NewBattleLoadingWindow setPlayerTitle.
func TestL2TopFloorEnemyTitleNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	topFloor := topFloorService(t, database)
	displayService := service(database, database)
	server := rankingServer(t, database)
	challenger, revision, _ := topFloorPlayer(t, database, server)
	defender, _, _ := topFloorPlayer(t, database, server)
	displayService.External = originProvider{o: playerdisplay.Origin{PlayerID: defender.PlayerID, Key: "l2-topfloor-enemy-title", Owner: "test-qualified-source", Family: "title", CatalogID: 100001, Revision: revision, StateVersion: 1}}
	topFloor.PlayerDisplay = displayService
	if _, err := topFloor.Load(ctx, challenger, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := topFloor.Load(ctx, defender, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := displayService.Execute(ctx, defender, playerdisplay.Command{Kind: "title", ID: 100001}, op()); err != nil {
		t.Fatalf("select defender title: %v", err)
	}

	display, err := topFloor.Formation(ctx, challenger, int64(defender.PlayerID), op())
	if err != nil {
		t.Fatal(err)
	}
	title, ok := display.TitleInfo["title_id"].(int64)
	if !ok || title != 100001 {
		t.Fatalf("display title %#v", display.TitleInfo)
	}
	row, ok := projection.Formation(display)["title_info"].(map[string]any)
	if !ok || row["title_id"] != int64(100001) {
		t.Fatalf("wire title_info %#v", projection.Formation(display)["title_info"])
	}
}
