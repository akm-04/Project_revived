//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"reflect"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/eventcentrestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func workshopClosurePlayer(t *testing.T) (*pg.Pool, identity.ActorContext, string, stockruntime.EventCentreDispatcher) {
	t.Helper()
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	for _, building := range []int64{1, 2, 5, 7} {
		finishBuilding(t, books, actor, building)
	}
	eventCentreFixture(t, database, actor, books, revision, []grant.Line{
		{Kind: grant.StackItem, ItemID: 30001006, Amount: 10},
		{Kind: grant.StackItem, ItemID: 50005024, Amount: 400},
		{Kind: grant.StackItem, ItemID: 50001094, Amount: 20},
	})
	service := eventCentreService(database, books)
	return database, actor, revision, stockruntime.EventCentreDispatcher{Authority: playtestAuthority{actor}, Service: service}
}

func workshopRoot(t *testing.T, database *pg.Pool, player identity.PlayerID) ec.Root {
	t.Helper()
	root, found, err := (eventcentrestore.Store{}).ReadRootTx(ctx, database, player)
	if err != nil || !found {
		t.Fatalf("event centre root %v %v", found, err)
	}
	return root
}

func workshopScalar(t *testing.T, database *pg.Pool, player identity.PlayerID, key string) int64 {
	t.Helper()
	amount, _, err := (i5store.Store{}).ReadScalarTx(ctx, database, player, key)
	if err != nil {
		t.Fatal(err)
	}
	return amount.Amount
}

func workshopStack(t *testing.T, database *pg.Pool, player identity.PlayerID, itemID int64) int64 {
	t.Helper()
	stack, found, err := (i5store.Store{}).ReadStackTx(ctx, database, player, itemID)
	if err != nil {
		t.Fatal(err)
	}
	if !found {
		return 0
	}
	return stack.Quantity
}

func dispatchTogether(t *testing.T, dispatcher stockruntime.EventCentreDispatcher, firstRequest, secondRequest httpedge.DispatchRequest) (httpedge.Response, httpedge.Response) {
	t.Helper()
	var wait sync.WaitGroup
	var first, second httpedge.Response
	wait.Add(2)
	go func() {
		defer wait.Done()
		first = dispatcher.Dispatch(ctx, firstRequest)
	}()
	go func() {
		defer wait.Done()
		second = dispatcher.Dispatch(ctx, secondRequest)
	}()
	wait.Wait()
	return first, second
}

// requireOneAccepted asserts that two simultaneous requests have exactly one
// effect and returns the winning request and body.
func requireOneAccepted(t *testing.T, label string, firstRequest, secondRequest httpedge.DispatchRequest, first, second httpedge.Response) (httpedge.DispatchRequest, httpedge.Response) {
	t.Helper()
	if (first.HTTPStatus == 200) == (second.HTTPStatus == 200) {
		t.Fatalf("%s concurrent pair: %d %+v / %d %+v", label, first.HTTPStatus, first.Body, second.HTTPStatus, second.Body)
	}
	winnerRequest, winner := firstRequest, first
	loser := second
	if second.HTTPStatus == 200 {
		winnerRequest, winner, loser = secondRequest, second, first
	}
	if loser.HTTPStatus != 409 || number(t, loser.Body["error_code"]) != 1 {
		t.Fatalf("%s losing request: %d %+v", label, loser.HTTPStatus, loser.Body)
	}
	return winnerRequest, winner
}

func requireRetrySame(t *testing.T, label string, dispatcher stockruntime.EventCentreDispatcher, request httpedge.DispatchRequest, want map[string]any) {
	t.Helper()
	again := dispatcher.Dispatch(ctx, request)
	if again.HTTPStatus != 200 || !reflect.DeepEqual(normalizedBody(t, again.Body), normalizedBody(t, want)) {
		t.Fatalf("%s exact retry: %d %+v want %+v", label, again.HTTPStatus, again.Body, want)
	}
}

// normalizedBody round-trips through JSON so the stored receipt's decoded
// numbers compare equal to the first response's native int64 values.
func normalizedBody(t *testing.T, body map[string]any) map[string]any {
	t.Helper()
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	var out map[string]any
	if err = json.Unmarshal(raw, &out); err != nil {
		t.Fatal(err)
	}
	return out
}

func requireRefusal(t *testing.T, label string, response httpedge.Response) {
	t.Helper()
	if response.HTTPStatus != 409 || number(t, response.Body["error_code"]) != 1 {
		t.Fatalf("%s refusal: %d %+v", label, response.HTTPStatus, response.Body)
	}
}

func TestI910AWorkshopBusinessRefusalsNative(t *testing.T) {
	database, actor, _, dispatcher := workshopClosurePlayer(t)

	requireRefusal(t, "1075 uncraftable item", dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(10010001)})))
	made := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)}))
	if made.HTTPStatus != 200 {
		t.Fatalf("1075 make: %d %+v", made.HTTPStatus, made.Body)
	}
	requireRefusal(t, "1075 while making", dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})))

	cancelled := dispatcher.Dispatch(ctx, playtestRequest(actor, 1076, map[string]any{"building_type": int64(2)}))
	if cancelled.HTTPStatus != 200 {
		t.Fatalf("1076 cancel: %d %+v", cancelled.HTTPStatus, cancelled.Body)
	}
	requireRefusal(t, "1076 without a job", dispatcher.Dispatch(ctx, playtestRequest(actor, 1076, map[string]any{"building_type": int64(2)})))
	requireRefusal(t, "1089 without a job", dispatcher.Dispatch(ctx, playtestRequest(actor, 1089, map[string]any{"speed_num": int64(1), "building_type": int64(2)})))

	requireRefusal(t, "1091 unowned pet", dispatcher.Dispatch(ctx, playtestRequest(actor, 1091, map[string]any{"item_id": int64(80001027), "pet_id": int64(1)})))

	requireRefusal(t, "1082 locked source", dispatcher.Dispatch(ctx, playtestRequest(actor, 1082, map[string]any{"from_type": int64(12), "to_type": int64(11)})))
	admin := dispatcher.Dispatch(ctx, playtestRequest(actor, 1082, map[string]any{"from_type": int64(2), "to_type": int64(11)}))
	if admin.HTTPStatus != 200 {
		t.Fatalf("1082 accepted exchange: %d %+v", admin.HTTPStatus, admin.Body)
	}

	madeAgain := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)}))
	if madeAgain.HTTPStatus != 200 {
		t.Fatalf("1075 make for over-speed: %d %+v", madeAgain.HTTPStatus, madeAgain.Body)
	}
	requireRefusal(t, "1089 over speed", dispatcher.Dispatch(ctx, playtestRequest(actor, 1089, map[string]any{"speed_num": int64(999999), "building_type": int64(2)})))

	if root := workshopRoot(t, database, actor.PlayerID); root.Facts.Desk.Job == nil {
		t.Fatal("refusals cancelled the accepted make job")
	}
}

func TestI910ARecycleConcurrencyAndRetryNative(t *testing.T) {
	database, actor, revision, dispatcher := workshopClosurePlayer(t)
	seedRecycleEnergy(t, database, actor, revision, 3600)
	exec(t, database, `UPDATE player_item_stacks SET quantity=1 WHERE player_id=$1 AND item_id=30001006`, int64(actor.PlayerID))
	dustBefore := workshopScalar(t, database, actor.PlayerID, "magic_dust")
	firstRequest := playtestRequest(actor, 1073, map[string]any{"item_id": int64(30001006), "item_num": int64(1)})
	secondRequest := playtestRequest(actor, 1073, map[string]any{"item_id": int64(30001006), "item_num": int64(1)})
	first, second := dispatchTogether(t, dispatcher, firstRequest, secondRequest)
	winnerRequest, winner := requireOneAccepted(t, "1073", firstRequest, secondRequest, first, second)
	if stack := workshopStack(t, database, actor.PlayerID, 30001006); stack != 0 {
		t.Fatalf("1073 stack after concurrency = %d", stack)
	}
	// Recycle may crit (RecycleCritPolicy), doubling the 4 dust.
	if awarded := workshopScalar(t, database, actor.PlayerID, "magic_dust") - dustBefore; awarded != 4 && awarded != 8 {
		t.Fatalf("1073 awarded %d dust", awarded)
	}
	requireRetrySame(t, "1073", dispatcher, winnerRequest, winner.Body)
	if stack := workshopStack(t, database, actor.PlayerID, 30001006); stack != 0 {
		t.Fatalf("1073 retry spent a second item: %d", stack)
	}
	// Recycle may crit (RecycleCritPolicy), doubling the 4 dust.
	if awarded := workshopScalar(t, database, actor.PlayerID, "magic_dust") - dustBefore; awarded != 4 && awarded != 8 {
		t.Fatalf("1073 retry awarded again: %d", awarded)
	}
}

func TestI910AMakeConcurrencyAndRetryNative(t *testing.T) {
	database, actor, _, dispatcher := workshopClosurePlayer(t)
	energyBefore := workshopScalar(t, database, actor.PlayerID, "magic_energy")
	firstRequest := playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})
	secondRequest := playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})
	first, second := dispatchTogether(t, dispatcher, firstRequest, secondRequest)
	winnerRequest, winner := requireOneAccepted(t, "1075", firstRequest, secondRequest, first, second)
	root := workshopRoot(t, database, actor.PlayerID)
	if root.Facts.Desk.Job == nil || root.Facts.Desk.Job.Occurrence != winnerRequest.Envelope.Operation.ID.String() {
		t.Fatalf("1075 job = %+v", root.Facts.Desk.Job)
	}
	if root.Facts.Recycle.EnergyAt.IsZero() {
		t.Fatal("1075 did not persist the recycle energy anchor")
	}
	if spent := energyBefore - workshopScalar(t, database, actor.PlayerID, "magic_energy"); spent != 53 {
		t.Fatalf("1075 spent %d magic_energy", spent)
	}
	requireRetrySame(t, "1075", dispatcher, winnerRequest, winner.Body)
	if spent := energyBefore - workshopScalar(t, database, actor.PlayerID, "magic_energy"); spent != 53 {
		t.Fatalf("1075 retry spent again: %d", spent)
	}
}

func TestI910ACancelConcurrencyAndRetryNative(t *testing.T) {
	database, actor, _, dispatcher := workshopClosurePlayer(t)
	if made := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})); made.HTTPStatus != 200 {
		t.Fatalf("1076 setup make: %d %+v", made.HTTPStatus, made.Body)
	}
	refundBefore := workshopScalar(t, database, actor.PlayerID, "magic_energy")
	firstRequest := playtestRequest(actor, 1076, map[string]any{"building_type": int64(2)})
	secondRequest := playtestRequest(actor, 1076, map[string]any{"building_type": int64(2)})
	first, second := dispatchTogether(t, dispatcher, firstRequest, secondRequest)
	winnerRequest, winner := requireOneAccepted(t, "1076", firstRequest, secondRequest, first, second)
	if root := workshopRoot(t, database, actor.PlayerID); root.Facts.Desk.Job != nil {
		t.Fatal("1076 left the job")
	}
	refunded := workshopScalar(t, database, actor.PlayerID, "magic_energy") - refundBefore
	if refunded <= 0 {
		t.Fatalf("1076 refund = %d", refunded)
	}
	requireRetrySame(t, "1076", dispatcher, winnerRequest, winner.Body)
	if again := workshopScalar(t, database, actor.PlayerID, "magic_energy") - refundBefore; again != refunded {
		t.Fatalf("1076 retry refunded again: %d -> %d", refunded, again)
	}
}

func TestI910AAdminConcurrencyAndRetryNative(t *testing.T) {
	database, actor, _, dispatcher := workshopClosurePlayer(t)
	exec(t, database, `UPDATE player_currency_balances SET amount=300 WHERE player_id=$1 AND resource_key='crystal'`, int64(actor.PlayerID))
	firstRequest := playtestRequest(actor, 1082, map[string]any{"from_type": int64(2), "to_type": int64(11)})
	secondRequest := playtestRequest(actor, 1082, map[string]any{"from_type": int64(2), "to_type": int64(11)})
	first, second := dispatchTogether(t, dispatcher, firstRequest, secondRequest)
	winnerRequest, winner := requireOneAccepted(t, "1082", firstRequest, secondRequest, first, second)
	root := workshopRoot(t, database, actor.PlayerID)
	if root.Facts.Admin[ec.AdminKey(2, 11)] != 1 {
		t.Fatalf("1082 admin counter = %+v", root.Facts.Admin)
	}
	if crystal := workshopScalar(t, database, actor.PlayerID, "crystal"); crystal != 0 {
		t.Fatalf("1082 crystal after one exchange = %d", crystal)
	}
	requireRetrySame(t, "1082", dispatcher, winnerRequest, winner.Body)
	if root := workshopRoot(t, database, actor.PlayerID); root.Facts.Admin[ec.AdminKey(2, 11)] != 1 {
		t.Fatalf("1082 retry counter = %+v", root.Facts.Admin)
	}
}

func TestI910AConfirmConcurrencyAndRetryNative(t *testing.T) {
	database, actor, _, dispatcher := workshopClosurePlayer(t)
	if made := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})); made.HTTPStatus != 200 {
		t.Fatalf("1088 setup make: %d %+v", made.HTTPStatus, made.Body)
	}
	if sped := dispatcher.Dispatch(ctx, playtestRequest(actor, 1089, map[string]any{"speed_num": int64(348), "building_type": int64(2)})); sped.HTTPStatus != 200 {
		t.Fatalf("1088 setup accelerate: %d %+v", sped.HTTPStatus, sped.Body)
	}
	firstRequest := playtestRequest(actor, 1088, map[string]any{"building_type": int64(2)})
	secondRequest := playtestRequest(actor, 1088, map[string]any{"building_type": int64(2)})
	first, second := dispatchTogether(t, dispatcher, firstRequest, secondRequest)
	winnerRequest, winner := requireOneAccepted(t, "1088", firstRequest, secondRequest, first, second)
	if items := workshopStack(t, database, actor.PlayerID, 20001091); items != 1 {
		t.Fatalf("1088 granted %d items", items)
	}
	requireRetrySame(t, "1088", dispatcher, winnerRequest, winner.Body)
	if items := workshopStack(t, database, actor.PlayerID, 20001091); items != 1 {
		t.Fatalf("1088 retry granted again: %d", items)
	}
}

func TestI910AAccelerateConcurrencyAndRetryNative(t *testing.T) {
	database, actor, _, dispatcher := workshopClosurePlayer(t)
	if made := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})); made.HTTPStatus != 200 {
		t.Fatalf("1089 setup make: %d %+v", made.HTTPStatus, made.Body)
	}
	speedBefore := workshopStack(t, database, actor.PlayerID, 50005024)
	firstRequest := playtestRequest(actor, 1089, map[string]any{"speed_num": int64(348), "building_type": int64(2)})
	secondRequest := playtestRequest(actor, 1089, map[string]any{"speed_num": int64(348), "building_type": int64(2)})
	first, second := dispatchTogether(t, dispatcher, firstRequest, secondRequest)
	winnerRequest, winner := requireOneAccepted(t, "1089", firstRequest, secondRequest, first, second)
	if spent := speedBefore - workshopStack(t, database, actor.PlayerID, 50005024); spent != 348 {
		t.Fatalf("1089 spent %d speed items", spent)
	}
	root := workshopRoot(t, database, actor.PlayerID)
	if root.Facts.Desk.Job != nil || root.Facts.Desk.PendingItem != 20001091 {
		t.Fatalf("1089 desk = %+v", root.Facts.Desk)
	}
	requireRetrySame(t, "1089", dispatcher, winnerRequest, winner.Body)
	if spent := speedBefore - workshopStack(t, database, actor.PlayerID, 50005024); spent != 348 {
		t.Fatalf("1089 retry spent again: %d", spent)
	}
}

func TestI910APetMakeConcurrencyAndRetryNative(t *testing.T) {
	database, actor, revision, dispatcher := workshopClosurePlayer(t)
	petID := insertWorkshopPet(t, database, actor, revision, 10010001)
	firstRequest := playtestRequest(actor, 1091, map[string]any{"item_id": int64(80001027), "pet_id": petID})
	secondRequest := playtestRequest(actor, 1091, map[string]any{"item_id": int64(80001027), "pet_id": petID})
	first, second := dispatchTogether(t, dispatcher, firstRequest, secondRequest)
	winnerRequest, winner := requireOneAccepted(t, "1091", firstRequest, secondRequest, first, second)
	root := workshopRoot(t, database, actor.PlayerID)
	if root.Facts.Pet.Job == nil || root.Facts.Pet.Job.Occurrence != winnerRequest.Envelope.Operation.ID.String() || root.Facts.Pet.PetID != petID {
		t.Fatalf("1091 pet = %+v", root.Facts.Pet)
	}
	requireRetrySame(t, "1091", dispatcher, winnerRequest, winner.Body)
	if root := workshopRoot(t, database, actor.PlayerID); root.Facts.Pet.Job == nil || root.Facts.Pet.Job.Occurrence != winnerRequest.Envelope.Operation.ID.String() {
		t.Fatalf("1091 retry pet = %+v", root.Facts.Pet)
	}
}

func TestI910ABoardReceiveConcurrencyNative(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	bornHero(t, database, actor, revision, 10001001, 1)
	bornHero(t, database, actor, revision, 10001002, 2)
	dispatcher := stockruntime.EventCentreDispatcher{Authority: playtestAuthority{actor}, Service: boardService(t, database, books)}
	listed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if listed.HTTPStatus != 200 {
		t.Fatalf("1084 setup list: %d %+v", listed.HTTPStatus, listed.Body)
	}
	// The stock Lua encoder sends an empty partners array as {}.
	firstRequest := playtestRequest(actor, 1084, map[string]any{"mission_id": int64(10001), "leader": int64(1), "partners": map[string]any{}, "wish_crystal": int64(0)})
	secondRequest := playtestRequest(actor, 1084, map[string]any{"mission_id": int64(10001), "leader": int64(1), "partners": map[string]any{}, "wish_crystal": int64(0)})
	first, second := dispatchTogether(t, dispatcher, firstRequest, secondRequest)
	winnerRequest, winner := requireOneAccepted(t, "1084", firstRequest, secondRequest, first, second)
	if partners, ok := winner.Body["partners"].([]int64); !ok || len(partners) != 0 {
		t.Fatalf("1084 empty partners reply = %#v", winner.Body["partners"])
	}
	root := boardRoot(t, database, actor.PlayerID)
	if len(root.Facts.Board.Doing) != 1 || root.Facts.Board.Doing[0].MissionID != 10001 {
		t.Fatalf("1084 doing = %+v", root.Facts.Board.Doing)
	}
	requireRetrySame(t, "1084", dispatcher, winnerRequest, winner.Body)
	if root := boardRoot(t, database, actor.PlayerID); len(root.Facts.Board.Doing) != 1 {
		t.Fatalf("1084 retry doing = %+v", root.Facts.Board.Doing)
	}
}

func TestI910AVoyageFinishedMissionFactNative(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	bornHero(t, database, actor, revision, 10001001, 1)
	exec(t, database, `UPDATE player_progression SET level=14,updated_at=clock_timestamp() WHERE player_id=$1`, int64(actor.PlayerID))
	dispatcher := stockruntime.EventCentreDispatcher{Authority: playtestAuthority{actor}, Service: boardService(t, database, books)}
	if listed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{})); listed.HTTPStatus != 200 {
		t.Fatalf("voyage setup list: %d %+v", listed.HTTPStatus, listed.Body)
	}
	injectBoardMission(t, database, actor, 10001, 1, nil, time.Now().UTC().Add(-48*time.Hour).Unix())

	settled := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if settled.HTTPStatus != 200 {
		t.Fatalf("voyage settle: %d %+v cause=%v", settled.HTTPStatus, settled.Body, settled.Cause)
	}
	if finish := boardList(t, settled.Body, "finish_mission_list"); len(finish) != 1 {
		t.Fatalf("voyage finish list = %+v", finish)
	}
	if progress := missionProgress(t, database, actor.PlayerID, 10030); progress != 1 {
		t.Fatalf("mission 10030 progress after one voyage = %d", progress)
	}
	again := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if again.HTTPStatus != 200 {
		t.Fatalf("voyage re-read: %d %+v", again.HTTPStatus, again.Body)
	}
	if progress := missionProgress(t, database, actor.PlayerID, 10030); progress != 1 {
		t.Fatalf("mission 10030 advanced on a read: %d", progress)
	}
}
