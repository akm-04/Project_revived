//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// MID 1283 (playoffs info) reads through the actor liveness fence.
func TestC13BReadOnlyArenaPlayoffsNative(t *testing.T) {
	database := pool(t)
	installed(t, database)
	actor, _ := genuinePlayer(t, database, rankingServer(t, database))
	service := arenaService(t, database)
	gate := newSnapshotGate(database)
	service.Timed.Runner.DB = gate
	dispatcher := stockruntime.TournamentDispatcher{Authority: fixedLibraryAuthority{actor: actor}, Service: service}
	var response httpedge.Response
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, database, `UPDATE account_sessions SET last_activity_at=last_activity_at+interval '1 second' WHERE session_id=$1`, actor.SessionID.UUID().String())
		},
		func(c context.Context) error {
			response = dispatcher.Dispatch(c, nativeDispatch(actor, 1283, map[string]any{}, op()))
			return nil
		})
	if err != nil {
		t.Fatalf("1283 read: %v", err)
	}
	if response.HTTPStatus != 200 {
		t.Fatalf("1283 status %d body %+v", response.HTTPStatus, response.Body)
	}
	for _, key := range []string{"battle_status", "players_info", "player_info", "playoff_info", "support_info"} {
		if _, present := response.Body[key]; !present {
			t.Fatalf("1283 reply lost %s: %+v", key, response.Body)
		}
	}
	info, ok := response.Body["player_info"].(map[string]any)
	if !ok || info["have_dec_flag"] != int64(0) {
		t.Fatalf("1283 player_info.have_dec_flag = %#v", response.Body["player_info"])
	}
	status, ok := response.Body["battle_status"].(map[string]any)
	if !ok {
		t.Fatalf("1283 battle_status = %#v", response.Body["battle_status"])
	}
	if rows, ok := status["3"].([]int64); !ok || len(rows) != 0 {
		t.Fatalf("1283 undecided qualifiers = %#v", status["3"])
	}
	group := dispatcher.Dispatch(context.Background(), nativeDispatch(actor, 1286, map[string]any{"index": int64(1)}, op()))
	if group.HTTPStatus != 200 {
		t.Fatalf("1286 status %d body %+v", group.HTTPStatus, group.Body)
	}
	if _, ok := group.Body["0"]; ok {
		t.Fatalf("1286 served a BYE row without a locked group: %+v", group.Body)
	}
}
