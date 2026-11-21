//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	da "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// BUGS #126: the stock defense battle scene sends total_damage as the raw harm
// sum (BattleCreate.lua:3175,3182), a Lua double. A fractional value must still
// decode through the production 2410 dispatcher, settle the win and free the
// position so the next 2412 is admitted.
func TestI9_12AdvroomDefenseFractionalResultNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	player, picks := adventureOwner(t, p, server, 11, 10001001)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	putAdventureOccurrence(t, p, player.PlayerID, da.EventDefense, 0, clock.at, clock.at.Add(time.Hour), "bug126-result")
	roomID := adventureRoomID(t, dispatch(t, mode, player, unpinnedRequest(2417, player, clock.at, map[string]any{"table_id": int64(da.EventDefense)})))
	formation := strconv.FormatInt(picks[0], 10)

	for position := int64(1); position <= da.DefenseMonsterCount; position++ {
		dispatch(t, mode, player, unpinnedRequest(2412, player, clock.at, map[string]any{"monster_pos": position, "table_id": int64(da.EventDefense)}))
		dispatch(t, mode, player, unpinnedRequest(2431, player, clock.at, map[string]any{"formation": formation, "pet_id": int64(0), "monster_pos": position, "table_id": int64(da.EventDefense)}))
		dispatch(t, mode, player, unpinnedRequest(2410, player, clock.at, map[string]any{
			"star":         json.Number("3"),
			"total_damage": json.Number("12345.75"),
			"monster_pos":  json.Number(strconv.FormatInt(position, 10)),
			"formation":    formation,
			"table_id":     json.Number("10001"),
		}))
		positions := adventureDefensePositions(t, dispatch(t, mode, player, unpinnedRequest(2417, player, clock.at, map[string]any{"table_id": int64(da.EventDefense)})))
		if busy := positions[position-1]; busy["busy_type"] != int64(0) {
			t.Fatalf("settled position %d still busy: %#v", position, busy)
		}
	}

	detail := adventureDefenseDetail(t, dispatch(t, mode, player, unpinnedRequest(2417, player, clock.at, map[string]any{"table_id": int64(da.EventDefense)})))
	monsters, _ := detail["monster_statuses"].([]any)
	for index, killer := range monsters {
		if killer == "" {
			t.Fatalf("position %d win was not saved: %#v", index+1, monsters)
		}
	}
	sourceKey := strconv.FormatInt(roomID, 10)
	if mails := scalar(t, p, `SELECT count(*) FROM mail_records WHERE source_kind='ADVENTURE_DEFENSE' AND source_key=$1`, sourceKey); mails != 1 {
		t.Fatalf("solved room mailed %d, want the band gift to the only defeater", mails)
	}
}

// BUGS #126: a started battle whose RESULT never arrives must not hold the
// position past the attempt's result deadline; a player who exits must not keep
// the position or the seat, and must be able to join and battle again.
func TestI9_12AdvroomDefenseDeadlineAndExitReleaseNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, _ := adventureOwner(t, p, server, 11, 10001001)
	member, memberPicks := adventureOwner(t, p, server, 11, 10001002)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	putAdventureOccurrence(t, p, owner.PlayerID, da.EventDefense, 0, clock.at, clock.at.Add(time.Hour), "bug126-release")
	roomID := adventureRoomID(t, dispatch(t, mode, owner, unpinnedRequest(2417, owner, clock.at, map[string]any{"table_id": int64(da.EventDefense)})))
	dispatch(t, mode, member, unpinnedRequest(2425, member, clock.at, map[string]any{"room_id": roomID, "table_id": int64(da.EventDefense)}))
	memberFormation := strconv.FormatInt(memberPicks[0], 10)

	// The member starts position 1; its result is never sent.
	dispatch(t, mode, member, unpinnedRequest(2412, member, clock.at, map[string]any{"monster_pos": int64(1), "table_id": int64(da.EventDefense)}))
	dispatch(t, mode, member, unpinnedRequest(2431, member, clock.at, map[string]any{"formation": memberFormation, "pet_id": int64(0), "monster_pos": int64(1), "table_id": int64(da.EventDefense)}))
	if response := dispatchResponse(t, mode, owner, unpinnedRequest(2412, owner, clock.at, map[string]any{"monster_pos": int64(1), "table_id": int64(da.EventDefense)})); response.HTTPStatus != 409 {
		t.Fatalf("position before the result deadline: %d %#v, want 409", response.HTTPStatus, response.Body)
	}

	// At the frozen result deadline the next prepare releases the hold.
	clock.Set(clock.at.Add(5 * time.Minute))
	dispatch(t, mode, owner, unpinnedRequest(2412, owner, clock.at, map[string]any{"monster_pos": int64(1), "table_id": int64(da.EventDefense)}))
	locator := fmt.Sprintf("room:%d/pos:1", roomID)
	if closed := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_DEFENSE' AND domain_locator=$1 AND terminal_kind='ADVENTURE_DEFENSE_EXPIRED'`, locator); closed != 1 {
		t.Fatalf("expired attempts %d, want the abandoned battle closed", closed)
	}
	dispatch(t, mode, owner, unpinnedRequest(2413, owner, clock.at, map[string]any{"monster_pos": int64(1), "table_id": int64(da.EventDefense)}))

	// Exit releases a started hold, the seat and the player.
	dispatch(t, mode, member, unpinnedRequest(2412, member, clock.at, map[string]any{"monster_pos": int64(2), "table_id": int64(da.EventDefense)}))
	dispatch(t, mode, member, unpinnedRequest(2431, member, clock.at, map[string]any{"formation": memberFormation, "pet_id": int64(0), "monster_pos": int64(2), "table_id": int64(da.EventDefense)}))
	dispatch(t, mode, member, unpinnedRequest(2426, member, clock.at, map[string]any{"table_id": int64(da.EventDefense)}))
	if busy := adventureDefensePositions(t, dispatch(t, mode, owner, unpinnedRequest(2417, owner, clock.at, map[string]any{"table_id": int64(da.EventDefense)})))[1]; busy["busy_type"] != int64(0) {
		t.Fatalf("departed member's position still busy: %#v", busy)
	}
	dispatch(t, mode, owner, unpinnedRequest(2412, owner, clock.at, map[string]any{"monster_pos": int64(2), "table_id": int64(da.EventDefense)}))
	dispatch(t, mode, owner, unpinnedRequest(2413, owner, clock.at, map[string]any{"monster_pos": int64(2), "table_id": int64(da.EventDefense)}))

	dispatch(t, mode, member, unpinnedRequest(2425, member, clock.at, map[string]any{"room_id": roomID, "table_id": int64(da.EventDefense)}))
	dispatch(t, mode, member, unpinnedRequest(2412, member, clock.at, map[string]any{"monster_pos": int64(3), "table_id": int64(da.EventDefense)}))
	dispatch(t, mode, member, unpinnedRequest(2431, member, clock.at, map[string]any{"formation": memberFormation, "pet_id": int64(0), "monster_pos": int64(3), "table_id": int64(da.EventDefense)}))
	dispatch(t, mode, member, unpinnedRequest(2410, member, clock.at, map[string]any{
		"star":         json.Number("1"),
		"total_damage": json.Number("10.5"),
		"monster_pos":  json.Number("3"),
		"formation":    memberFormation,
		"table_id":     json.Number("10001"),
	}))
}

func dispatchResponse(t *testing.T, mode appadventure.Mode, actor identity.ActorContext, request httpedge.DispatchRequest) httpedge.Response {
	t.Helper()
	dispatcher := stockruntime.AdventureDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Service: mode}
	return dispatcher.Dispatch(context.Background(), request)
}

func adventureDefenseDetail(t *testing.T, info map[string]any) map[string]any {
	t.Helper()
	detail, ok := info["detail"].(map[string]any)
	if !ok {
		t.Fatalf("2417 detail %#v", info)
	}
	return detail
}

func adventureDefensePositions(t *testing.T, info map[string]any) []map[string]any {
	t.Helper()
	detail := adventureDefenseDetail(t, info)
	rows, ok := detail["pos_statuses"].([]any)
	if !ok || len(rows) != da.DefenseMonsterCount {
		t.Fatalf("2417 pos_statuses %#v", detail["pos_statuses"])
	}
	out := make([]map[string]any, len(rows))
	for index, row := range rows {
		out[index], _ = row.(map[string]any)
	}
	return out
}
