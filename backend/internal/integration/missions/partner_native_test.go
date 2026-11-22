//go:build postgres

package missions_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// The stock Task model keys partner missions by hero table id
// (Task.lua:162-170) and the cell formats the mission name with the hero name
// (TaskPartnerCell.lua:30-31). The rows come from mission.lua new_type 6.
func TestPartnerMissionRowsChainsAndRewards(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := now.Add(24 * time.Hour)
	a := runtimeActor(t, p, at)
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	seedMissionHeroes(t, p, a.PlayerID, catalog.RevisionID())
	service := runtimeService(p, &missionClock{at: at})
	dispatcher := stockruntime.Decorated{Next: stockruntime.I5Dispatcher{Authority: activityFixtureAuthority{a}, Service: service, Missions: service}}
	request := func(mid uint16, params map[string]any) httpedge.Response {
		t.Helper()
		return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: runtimeOperation(t, at), MID: mid, ReceivedAt: at, Params: params, Claims: wire.CredentialClaims{Token: "fixture", Region: 1}}})
	}

	const hero = int64(10001001)
	partnerRows := func() map[string]map[int64]map[string]any {
		t.Helper()
		reply := request(2736, map[string]any{"mission_type": int64(objective.Partner)})
		if reply.HTTPStatus != 200 {
			t.Fatalf("2736 partner %#v", reply)
		}
		if violations := (replyconformance.Checker{}).Check(2736, reply.Body); len(violations) != 0 {
			t.Fatalf("2736 partner conformance: %v", violations)
		}
		list, ok := reply.Body["mission_list"].(map[string]any)
		if !ok {
			t.Fatalf("2736 partner mission_list %T %#v", reply.Body["mission_list"], reply.Body)
		}
		out := map[string]map[int64]map[string]any{}
		for key, raw := range list {
			rows, ok := raw.([]any)
			if !ok {
				t.Fatalf("partner hero %s rows %T", key, raw)
			}
			byID := map[int64]map[string]any{}
			for _, row := range rows {
				mission, ok := row.(map[string]any)
				if !ok {
					t.Fatalf("partner hero %s row %T", key, row)
				}
				byID[mission["table_id"].(int64)] = mission
			}
			out[key] = byID
		}
		return out
	}

	claim := func(id int64) httpedge.Response {
		t.Helper()
		reply := request(161, map[string]any{"table_id": id, "hero_table_id": hero})
		if reply.HTTPStatus != 200 {
			t.Fatalf("claim %d %#v", id, reply)
		}
		if violations := (replyconformance.Checker{}).Check(161, reply.Body); len(violations) != 0 {
			t.Fatalf("claim %d conformance: %v", id, violations)
		}
		return reply
	}
	expectReward := func(id, item, amount int64) httpedge.Response {
		t.Helper()
		reply := claim(id)
		for _, award := range reply.Body["awards"].([]map[string]any) {
			if award["table_id"] == item && award["item_num"] == amount {
				return reply
			}
		}
		t.Fatalf("claim %d rewards %#v, want item %d x%d", id, reply.Body["awards"], item, amount)
		return reply
	}
	// The claim reply must carry the chain delta so the open tab shows the next
	// row without reopening (I9_MISSIONS_V1 M8; Task.lua:42-66).
	nextRow := func(reply httpedge.Response) map[string]any {
		t.Helper()
		hooks, ok := reply.Body["partner_mission_"].([]any)
		if !ok {
			t.Fatalf("claim reply lacks partner_mission_: %#v", reply.Body)
		}
		for _, hook := range hooks {
			if row, ok := hook.(map[string]any)["10001001"]; ok {
				return row.(map[string]any)
			}
		}
		return nil
	}

	rows := partnerRows()
	if len(rows) != 123 {
		t.Fatalf("partner heroes %d", len(rows))
	}
	own := rows["10001001"]
	if len(own) != 1 || own[120001] == nil {
		t.Fatalf("first partner row before claim %#v", own)
	}
	if own[120001]["count"] != int64(1) || own[120001]["is_complete"] != int64(1) {
		t.Fatalf("first partner row %#v", own[120001])
	}
	if row := nextRow(expectReward(120001, 50001005, 1)); row == nil || row["table_id"] != int64(130001) {
		t.Fatalf("claim 120001 did not push its successor: %#v", row)
	}

	rows = partnerRows()
	own = rows["10001001"]
	if own[120001] != nil || own[130001] == nil {
		t.Fatalf("chain after first claim %#v", own)
	}
	if own[130001]["count"] != int64(1) || own[130001]["is_complete"] != int64(0) {
		t.Fatalf("level row at hero level 1 %#v", own[130001])
	}

	_, err = p.Raw().Exec(ctx, `UPDATE player_heroes SET level=10 WHERE player_id=$1 AND origin_table_id=$2`, int64(a.PlayerID), hero)
	if err != nil {
		t.Fatal(err)
	}
	rows = partnerRows()
	own = rows["10001001"]
	if own[130001]["count"] != int64(10) || own[130001]["is_complete"] != int64(1) {
		t.Fatalf("level row at hero level 10 %#v", own[130001])
	}
	expectReward(130001, 50001538, 1)

	rows = partnerRows()
	own = rows["10001001"]
	if own[140001] == nil || own[140001]["count"] != int64(1) || own[140001]["is_complete"] != int64(0) {
		t.Fatalf("promotion row at color 1 %#v", own[140001])
	}
	_, err = p.Raw().Exec(ctx, `UPDATE player_heroes SET color=2 WHERE player_id=$1 AND origin_table_id=$2`, int64(a.PlayerID), hero)
	if err != nil {
		t.Fatal(err)
	}
	expectReward(140001, 50001005, 3)

	_, err = p.Raw().Exec(ctx, `UPDATE player_heroes SET level=20 WHERE player_id=$1 AND origin_table_id=$2`, int64(a.PlayerID), hero)
	if err != nil {
		t.Fatal(err)
	}
	expectReward(130002, 50001538, 1)

	_, err = p.Raw().Exec(ctx, `UPDATE player_heroes SET color=4 WHERE player_id=$1 AND origin_table_id=$2`, int64(a.PlayerID), hero)
	if err != nil {
		t.Fatal(err)
	}
	expectReward(140002, 50001005, 5)

	_, err = p.Raw().Exec(ctx, `UPDATE player_heroes SET level=40 WHERE player_id=$1 AND origin_table_id=$2`, int64(a.PlayerID), hero)
	if err != nil {
		t.Fatal(err)
	}
	expectReward(130003, 50001538, 2)

	_, err = p.Raw().Exec(ctx, `UPDATE player_heroes SET color=7 WHERE player_id=$1 AND origin_table_id=$2`, int64(a.PlayerID), hero)
	if err != nil {
		t.Fatal(err)
	}
	expectReward(140003, 50001005, 5)

	rows = partnerRows()
	if own = rows["10001001"]; len(own) != 0 {
		t.Fatalf("partner chain did not end: %#v", own)
	}
	if len(rows) != 122 {
		t.Fatalf("other heroes stayed materialized: %d", len(rows))
	}
}
