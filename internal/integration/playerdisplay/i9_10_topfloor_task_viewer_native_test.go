//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

// TestI9_10TopFloorTaskViewerVisibilityNative proves D512's read-only mode state:
// an unqualified player gets 282/283 and the subtype-2 list, while the write
// MIDs still refuse with the stock not-open code and no period is created.
func TestI9_10TopFloorTaskViewerVisibilityNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, _, _ := topFloorPlayer(t, database, server)
	exec(t, database, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(actor.PlayerID))
	if _, err := service.Load(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}

	view, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil || view.Rank != 0 || len(view.Enemies) != 0 {
		t.Fatalf("viewer load: %+v %v", view, err)
	}
	if view.Rotation.Mode < 1 || view.Rotation.Mode > 5 {
		t.Fatalf("viewer rotation kept mode %d", view.Rotation.Mode)
	}
	list, err := service.TaskRankList(ctx, actor)
	if err != nil || len(list.Rows) != 0 || list.MyRank != 0 {
		t.Fatalf("viewer rank list: %+v %v", list, err)
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_task_periods WHERE logical_server_id=$1`, int64(server)) != 0 {
		t.Fatal("viewer load created a period")
	}

	dispatcher := stockruntime.TopFloorTaskDispatcher{Authority: playtestAuthority{actor}, Service: service}
	ok := dispatcher.Dispatch(ctx, playtestRequest(actor, 282, map[string]any{}))
	if ok.HTTPStatus != 200 || ok.Body["rank"] != int64(0) || len(ok.Body["enemies"].([]map[string]any)) != 0 {
		t.Fatalf("viewer 282: %+v", ok)
	}
	if ok.Body["defense_"+jsonNumber(ok.Body["mode"])] != "" {
		t.Fatalf("viewer defense: %+v", ok.Body)
	}
	enemies := dispatcher.Dispatch(ctx, playtestRequest(actor, 283, map[string]any{}))
	if enemies.HTTPStatus != 200 || len(enemies.Body["enemies"].([]map[string]any)) != 0 {
		t.Fatalf("viewer 283: %+v", enemies)
	}

	number := func(value string) json.Number { return json.Number(value) }
	refusals := []struct {
		mid    uint16
		params map[string]any
	}{
		{284, map[string]any{"heroIDs": []any{}, "pet_id": number("0"), "leader_id": number("0")}},
		{285, map[string]any{"enemy_id": number("0")}},
		{286, map[string]any{"formation": "1", "pet_id": number("0"), "leader_id": number("0"), "enemy_id": number("1"), "is_avenge": number("0"), "campaign_id": number("0"), "campaign_type": number("0")}},
		{287, map[string]any{}},
		{296, map[string]any{}},
	}
	for _, refusal := range refusals {
		result := dispatcher.Dispatch(ctx, playtestRequest(actor, refusal.mid, refusal.params))
		if result.HTTPStatus != 409 || result.Body["error_code"] != int64(40001) {
			t.Fatalf("MID %d viewer refusal: %+v", refusal.mid, result)
		}
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_task_players WHERE logical_server_id=$1`, int64(server)) != 0 {
		t.Fatal("viewer MID created a task player")
	}

	// The server-level gate stays hard: below it, even the viewer state refuses.
	belowServer := rankingServer(t, database)
	below, _, _ := topFloorPlayer(t, database, belowServer)
	exec(t, database, `UPDATE player_directory_profiles SET lev=59 WHERE player_id >= $1 AND player_id < $2`, int64(belowServer)*100000, (int64(belowServer)+1)*100000)
	if _, err := service.LoadTask(ctx, below, op(), false); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("viewer below the server level answered: %v", err)
	}
}

func jsonNumber(value any) string {
	raw, err := json.Marshal(value)
	if err != nil {
		return ""
	}
	var number json.Number
	if json.Unmarshal(raw, &number) != nil {
		return ""
	}
	return number.String()
}
