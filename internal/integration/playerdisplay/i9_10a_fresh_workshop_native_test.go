//go:build postgres

package playerdisplay_test

import (
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/grant"
)

// Bug #74: a fresh player (bookskill Seed owns only buildings 1, 3 and 4)
// opens the stock Workshop window, which GET_BUILDING_LIST reports at level
// one, and presses Dismantle, Forge and Exchange. RealPG through the
// production dispatcher must serve all three without any building upgrade.
func TestI910AFreshPlayerWorkshopNative(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	eventCentreFixture(t, database, actor, books, revision, []grant.Line{
		{Kind: grant.StackItem, ItemID: 30001006, Amount: 10},
	})
	dispatcher := stockruntime.EventCentreDispatcher{Authority: playtestAuthority{actor}, Service: eventCentreService(database, books)}
	stacks := i5store.Store{}

	info := dispatcher.Dispatch(ctx, playtestRequest(actor, 1072, map[string]any{}))
	if info.HTTPStatus != 200 || number(t, info.Body["energy"]) != 10000 || number(t, info.Body["energy_limit"]) != 10000 {
		t.Fatalf("1072 fresh: %d %+v", info.HTTPStatus, info.Body)
	}
	buildingInfo, ok := info.Body["building_info"].(map[string]any)
	if !ok || number(t, buildingInfo["lev"]) != 1 {
		t.Fatalf("1072 fresh building_info: %+v", info.Body)
	}

	recycleRequest := playtestRequest(actor, 1073, map[string]any{"item_id": int64(30001006), "item_num": int64(1)})
	recycled := dispatcher.Dispatch(ctx, recycleRequest)
	if recycled.HTTPStatus != 200 || number(t, recycled.Body["energy"]) != 9999 {
		t.Fatalf("1073 fresh: %d %+v", recycled.HTTPStatus, recycled.Body)
	}
	types := int64Slice(t, recycled.Body["resolve_types"])
	numbers := int64Slice(t, recycled.Body["resolve_nums"])
	if len(types) != 2 || types[0] != 11 || types[1] != 12 || numbers[0] < 4 || numbers[1] < 4 {
		t.Fatalf("1073 fresh awards: %+v", recycled.Body)
	}
	replayedRecycle := dispatcher.Dispatch(ctx, recycleRequest)
	if replayedRecycle.HTTPStatus != 200 || !reflect.DeepEqual(normalizedBody(t, replayedRecycle.Body), normalizedBody(t, recycled.Body)) {
		t.Fatalf("1073 exact retry: %d %+v", replayedRecycle.HTTPStatus, replayedRecycle.Body)
	}
	if stack, exists, err := stacks.ReadStackTx(ctx, database, actor.PlayerID, 30001006); err != nil || !exists || stack.Quantity != 9 {
		t.Fatalf("1073 retry balance: %+v %v %v", stack, exists, err)
	}
	if refused := dispatcher.Dispatch(ctx, playtestRequest(actor, 1073, map[string]any{"item_id": int64(10010001), "item_num": int64(1)})); refused.HTTPStatus != 409 || number(t, refused.Body["error_code"]) != 35028 {
		t.Fatalf("1073 foreign item: %d %+v", refused.HTTPStatus, refused.Body)
	}
	if refused := dispatcher.Dispatch(ctx, playtestRequest(actor, 1073, map[string]any{"item_id": int64(30001006), "item_num": int64(11)})); refused.HTTPStatus != 409 || number(t, refused.Body["error_code"]) != 35028 {
		t.Fatalf("1073 overspent items: %d %+v", refused.HTTPStatus, refused.Body)
	}

	deskInfo := dispatcher.Dispatch(ctx, playtestRequest(actor, 1074, map[string]any{}))
	deskBuilding, ok := deskInfo.Body["building_info"].(map[string]any)
	if deskInfo.HTTPStatus != 200 || !ok || number(t, deskBuilding["lev"]) != 1 {
		t.Fatalf("1074 fresh: %d %+v", deskInfo.HTTPStatus, deskInfo.Body)
	}
	if refused := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001001)})); refused.HTTPStatus != 409 || number(t, refused.Body["error_code"]) != 35028 {
		t.Fatalf("1075 non-craftable: %d %+v", refused.HTTPStatus, refused.Body)
	}
	makeRequest := playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})
	made := dispatcher.Dispatch(ctx, makeRequest)
	if made.HTTPStatus != 200 || number(t, made.Body["is_making"]) != 1 || number(t, made.Body["making_item"]) != 20001091 || number(t, made.Body["make_need_time"]) != 108000 {
		t.Fatalf("1075 fresh: %d %+v", made.HTTPStatus, made.Body)
	}
	replayedMake := dispatcher.Dispatch(ctx, makeRequest)
	if replayedMake.HTTPStatus != 200 || !reflect.DeepEqual(normalizedBody(t, replayedMake.Body), normalizedBody(t, made.Body)) {
		t.Fatalf("1075 exact retry: %d %+v", replayedMake.HTTPStatus, replayedMake.Body)
	}
	if refused := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})); refused.HTTPStatus != 409 || number(t, refused.Body["error_code"]) != 35028 {
		t.Fatalf("1075 while making: %d %+v", refused.HTTPStatus, refused.Body)
	}

	adminInfo := dispatcher.Dispatch(ctx, playtestRequest(actor, 1081, map[string]any{}))
	table, ok := adminInfo.Body["info"].(map[string]any)
	if adminInfo.HTTPStatus != 200 || !ok || number(t, table["211"]) != 0 {
		t.Fatalf("1081 fresh: %d %+v", adminInfo.HTTPStatus, adminInfo.Body)
	}
	crystalBefore, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "crystal")
	if err != nil {
		t.Fatal(err)
	}
	dustBefore, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "magic_dust")
	if err != nil {
		t.Fatal(err)
	}
	adminRequest := playtestRequest(actor, 1082, map[string]any{"from_type": int64(2), "to_type": int64(11)})
	exchanged := dispatcher.Dispatch(ctx, adminRequest)
	if exchanged.HTTPStatus != 200 {
		t.Fatalf("1082 fresh: %d %+v", exchanged.HTTPStatus, exchanged.Body)
	}
	replayedAdmin := dispatcher.Dispatch(ctx, adminRequest)
	if replayedAdmin.HTTPStatus != 200 || !reflect.DeepEqual(normalizedBody(t, replayedAdmin.Body), normalizedBody(t, exchanged.Body)) {
		t.Fatalf("1082 exact retry: %d %+v", replayedAdmin.HTTPStatus, replayedAdmin.Body)
	}
	crystalAfter, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "crystal")
	if err != nil {
		t.Fatal(err)
	}
	dustAfter, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "magic_dust")
	if err != nil {
		t.Fatal(err)
	}
	if crystalAfter.Amount != crystalBefore.Amount-300 || dustAfter.Amount != dustBefore.Amount+50000 {
		t.Fatalf("1082 retry effect: crystal %d -> %d, dust %d -> %d", crystalBefore.Amount, crystalAfter.Amount, dustBefore.Amount, dustAfter.Amount)
	}
	afterExchange := dispatcher.Dispatch(ctx, playtestRequest(actor, 1081, map[string]any{}))
	afterTable, ok := afterExchange.Body["info"].(map[string]any)
	if afterExchange.HTTPStatus != 200 || !ok || number(t, afterTable["211"]) != 1 {
		t.Fatalf("1081 after exchange: %d %+v", afterExchange.HTTPStatus, afterExchange.Body)
	}
	for key, count := range afterTable {
		if key != "211" && number(t, count) != 0 {
			t.Fatalf("1081 retry double counted %s: %+v", key, afterExchange.Body)
		}
	}
	if refused := dispatcher.Dispatch(ctx, playtestRequest(actor, 1082, map[string]any{"from_type": int64(13), "to_type": int64(11)})); refused.HTTPStatus != 409 || number(t, refused.Body["error_code"]) != 35028 {
		t.Fatalf("1082 locked source: %d %+v", refused.HTTPStatus, refused.Body)
	}
	if refused := dispatcher.Dispatch(ctx, playtestRequest(actor, 1082, map[string]any{"from_type": int64(2), "to_type": int64(2)})); refused.HTTPStatus != 409 || number(t, refused.Body["error_code"]) != 35028 {
		t.Fatalf("1082 same source and destination: %d %+v", refused.HTTPStatus, refused.Body)
	}
	exec(t, database, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='crystal'`, int64(actor.PlayerID))
	if refused := dispatcher.Dispatch(ctx, playtestRequest(actor, 1082, map[string]any{"from_type": int64(2), "to_type": int64(11)})); refused.HTTPStatus != 409 || number(t, refused.Body["error_code"]) != 20005 {
		t.Fatalf("1082 without diamonds: %d %+v", refused.HTTPStatus, refused.Body)
	}
}
