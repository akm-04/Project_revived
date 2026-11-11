//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/eventcentrestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	appeventcentre "gxb.local/backend/v2/internal/application/eventcentre"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func eventCentreService(database *pg.Pool, books appbook.Service) appeventcentre.Service {
	return appeventcentre.Service{
		Timed:    books.Timed,
		Reads:    tx.Runner{DB: database},
		Owner:    eventcentrestore.Store{},
		Book:     books,
		Content:  contentstore.Store{Queryer: database},
		Pets:     characterstore.Store{},
		Players:  i4store.PlayerRootLocker{},
		Fence:    i5store.Store{Queryer: database},
		Costs:    books.Costs,
		Grants:   books.Grants,
		Receipts: kernelstore.Store{},
	}
}

func eventCentreFixture(t *testing.T, database *pg.Pool, actor identity.ActorContext, books appbook.Service, revision string, lines []grant.Line) {
	t.Helper()
	operation := op()
	operation.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: revision})
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	plan := grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "i910a-fixture", Operation: "workshop-inputs", BusinessKey: operation.ID.String(), Occurrence: operation.ID.String(), PolicyVersion: "i910a-fixture-v1"}, Lines: lines}
	if _, err = books.Grants.SettleGrantTx(ctx, transaction, actor, plan, operation, i5.GrantTxOptions{}); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func insertWorkshopPet(t *testing.T, database *pg.Pool, actor identity.ActorContext, revision string, tableID int64) int64 {
	t.Helper()
	exec(t, database, `INSERT INTO player_pet_roots(player_id,next_pet_id,state_version,created_at,updated_at)VALUES($1,2,1,clock_timestamp(),clock_timestamp())ON CONFLICT(player_id)DO UPDATE SET next_pet_id=2`, int64(actor.PlayerID))
	exec(t, database, `INSERT INTO player_pets(player_id,pet_id,table_id,origin_table_id,star,level,exp,color,birthday,is_show,skill_1,skill_2,skill_3,skill_4,skill_5,equip_1,equip_2,equip_3,fumo_1,fumo_2,fumo_3,active_style,creation_content_revision,state_version,created_at,updated_at)VALUES($1,1,$2,$2,1,1,0,1,0,false,1,1,1,1,1,0,0,0,0,0,0,0,$3,1,clock_timestamp(),clock_timestamp())`, int64(actor.PlayerID), tableID, revision)
	return 1
}

func seedRecycleEnergy(t *testing.T, database *pg.Pool, actor identity.ActorContext, revision string, secondsAgo int64) {
	t.Helper()
	anchored := time.Now().UTC().Add(-time.Duration(secondsAgo) * time.Second)
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	owner := eventcentrestore.Store{}
	if err = owner.EnsureRootTx(ctx, transaction, actor.PlayerID, revision, anchored); err != nil {
		t.Fatal(err)
	}
	root, exists, err := owner.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil || !exists {
		t.Fatal("recycle root", exists, err)
	}
	root.Facts.Recycle.EnergyAt = anchored
	root.Version++
	root.UpdatedAt = anchored
	if err = owner.SaveRootTx(ctx, transaction, root, root.Version-1); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func int64Slice(t *testing.T, value any) []int64 {
	t.Helper()
	switch typed := value.(type) {
	case []int64:
		return typed
	case []any:
		out := make([]int64, 0, len(typed))
		for _, entry := range typed {
			out = append(out, number(t, entry))
		}
		return out
	default:
		t.Fatalf("not a number list: %#v", value)
		return nil
	}
}

func TestI910AWorkshopRecycleMakeAdminPetNative(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	eventCentre := eventCentreService(database, books)
	dispatcher := stockruntime.EventCentreDispatcher{Authority: playtestAuthority{actor}, Service: eventCentre}

	finishBuilding(t, books, actor, 1)
	finishBuilding(t, books, actor, 2)
	finishBuilding(t, books, actor, 5)
	finishBuilding(t, books, actor, 7)
	eventCentreFixture(t, database, actor, books, revision, []grant.Line{
		{Kind: grant.StackItem, ItemID: 30001006, Amount: 10},
		{Kind: grant.StackItem, ItemID: 50005024, Amount: 999},
		{Kind: grant.StackItem, ItemID: 50001094, Amount: 20},
	})

	seedRecycleEnergy(t, database, actor, revision, 3600)

	info := dispatcher.Dispatch(ctx, playtestRequest(actor, 1072, map[string]any{}))
	if info.HTTPStatus != 200 || number(t, info.Body["energy"]) < 200 || number(t, info.Body["energy_limit"]) != 10000 {
		t.Fatalf("1072: %d %+v", info.HTTPStatus, info.Body)
	}
	if _, ok := info.Body["building_info"].(map[string]any); !ok {
		t.Fatalf("1072 building_info: %+v", info.Body)
	}

	stacks := i5store.Store{}
	stackBefore, stackExists, err := stacks.ReadStackTx(ctx, database, actor.PlayerID, 30001006)
	if err != nil || !stackExists {
		t.Fatal("recycle fixture item", stackExists, err)
	}
	dustBefore, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "magic_dust")
	if err != nil {
		t.Fatal(err)
	}
	liquidBefore, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "magic_liquid")
	if err != nil {
		t.Fatal(err)
	}
	recycleRequest := playtestRequest(actor, 1073, map[string]any{"item_id": int64(30001006), "item_num": int64(2)})
	recycled := dispatcher.Dispatch(ctx, recycleRequest)
	if recycled.HTTPStatus != 200 {
		t.Fatalf("1073: %d %+v", recycled.HTTPStatus, recycled.Body)
	}
	before := number(t, info.Body["energy"])
	cost := number(t, recycled.Body["energy"])
	if before-cost < 2 || number(t, recycled.Body["energy_time"]) == 0 {
		t.Fatalf("recycle energy %d -> %d", before, cost)
	}
	types := int64Slice(t, recycled.Body["resolve_types"])
	numbers := int64Slice(t, recycled.Body["resolve_nums"])
	crits := int64Slice(t, recycled.Body["resolve_crits"])
	if len(types) != 2 || len(numbers) != 2 || len(crits) != 2 || types[0] != 11 || types[1] != 12 {
		t.Fatalf("1073 award vectors: %+v", recycled.Body)
	}
	if numbers[0] < 8 || numbers[1] < 8 {
		t.Fatalf("1073 award numbers: %+v", numbers)
	}
	if item, exists, err := stacks.ReadStackTx(ctx, database, actor.PlayerID, 30001006); err != nil || !exists || item.Quantity != stackBefore.Quantity-2 {
		t.Fatalf("recycled item balance: %+v %v %v", item, exists, err)
	}
	dustAfter, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "magic_dust")
	if err != nil {
		t.Fatal(err)
	}
	liquidAfter, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "magic_liquid")
	if err != nil {
		t.Fatal(err)
	}
	if dustAfter.Amount != dustBefore.Amount+numbers[0] || liquidAfter.Amount != liquidBefore.Amount+numbers[1] {
		t.Fatalf("recycle award was not granted: %+v -> %+v, %+v -> %+v", dustBefore, dustAfter, liquidBefore, liquidAfter)
	}
	replayed := dispatcher.Dispatch(ctx, recycleRequest)
	if replayed.HTTPStatus != 200 || number(t, replayed.Body["energy"]) != cost {
		t.Fatalf("1073 replay: %d %+v", replayed.HTTPStatus, replayed.Body)
	}
	refused := dispatcher.Dispatch(ctx, playtestRequest(actor, 1073, map[string]any{"item_id": int64(10010001), "item_num": int64(1)}))
	if refused.HTTPStatus != 409 || number(t, refused.Body["error_code"]) != 35028 {
		t.Fatalf("1073 foreign item: %d %+v", refused.HTTPStatus, refused.Body)
	}

	made := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)}))
	if made.HTTPStatus != 200 || number(t, made.Body["is_making"]) != 1 || number(t, made.Body["making_item"]) != 20001091 || number(t, made.Body["make_need_time"]) != 104400 {
		t.Fatalf("1075: %d %+v", made.HTTPStatus, made.Body)
	}
	accelerated := dispatcher.Dispatch(ctx, playtestRequest(actor, 1089, map[string]any{"speed_num": int64(348), "building_type": int64(2)}))
	if accelerated.HTTPStatus != 200 || number(t, accelerated.Body["is_making"]) != 0 || number(t, accelerated.Body["make_item"]) != 20001091 {
		t.Fatalf("1089: %d %+v", accelerated.HTTPStatus, accelerated.Body)
	}
	confirmed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1088, map[string]any{"building_type": int64(2)}))
	items := awardRows(t, confirmed.Body["items"])
	if confirmed.HTTPStatus != 200 || len(items) != 1 || number(t, items[0]["table_id"]) != 20001091 || number(t, items[0]["item_num"]) != 1 {
		t.Fatalf("1088: %d %+v", confirmed.HTTPStatus, confirmed.Body)
	}
	if extra := dispatcher.Dispatch(ctx, playtestRequest(actor, 1088, map[string]any{"building_type": int64(2)})); extra.HTTPStatus != 409 {
		t.Fatalf("1088 without pending item: %d %+v", extra.HTTPStatus, extra.Body)
	}

	if status := dispatcher.Dispatch(ctx, playtestRequest(actor, 1075, map[string]any{"item_id": int64(20001091)})).HTTPStatus; status != 200 {
		t.Fatalf("second 1075: %d", status)
	}
	cancelled := dispatcher.Dispatch(ctx, playtestRequest(actor, 1076, map[string]any{"building_type": int64(2)}))
	refundTypes := int64Slice(t, cancelled.Body["make_res_type"])
	refundNumbers := int64Slice(t, cancelled.Body["make_res_num"])
	if cancelled.HTTPStatus != 200 || len(refundTypes) != 1 || refundTypes[0] != 13 || refundNumbers[0] <= 0 || refundNumbers[0] > 53 {
		t.Fatalf("1076: %d %+v", cancelled.HTTPStatus, cancelled.Body)
	}

	crystalBefore, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "crystal")
	if err != nil {
		t.Fatal(err)
	}
	adminDustBefore, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "magic_dust")
	if err != nil {
		t.Fatal(err)
	}
	admin := dispatcher.Dispatch(ctx, playtestRequest(actor, 1082, map[string]any{"from_type": int64(2), "to_type": int64(11)}))
	if admin.HTTPStatus != 200 {
		t.Fatalf("1082: %d %+v", admin.HTTPStatus, admin.Body)
	}
	crystalAfter, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "crystal")
	if err != nil {
		t.Fatal(err)
	}
	adminDustAfter, _, err := stacks.ReadScalarTx(ctx, database, actor.PlayerID, "magic_dust")
	if err != nil {
		t.Fatal(err)
	}
	if crystalAfter.Amount != crystalBefore.Amount-300 || adminDustAfter.Amount != adminDustBefore.Amount+50000 {
		t.Fatalf("1082 exchange balances: crystal %d -> %d, dust %d -> %d", crystalBefore.Amount, crystalAfter.Amount, adminDustBefore.Amount, adminDustAfter.Amount)
	}
	adminInfo := dispatcher.Dispatch(ctx, playtestRequest(actor, 1081, map[string]any{}))
	table, ok := adminInfo.Body["info"].(map[string]any)
	if adminInfo.HTTPStatus != 200 || !ok || number(t, table["211"]) != 1 {
		t.Fatalf("1081: %d %+v", adminInfo.HTTPStatus, adminInfo.Body)
	}
	if locked := dispatcher.Dispatch(ctx, playtestRequest(actor, 1082, map[string]any{"from_type": int64(12), "to_type": int64(11)})); locked.HTTPStatus != 409 {
		t.Fatalf("1082 locked source: %d %+v", locked.HTTPStatus, locked.Body)
	}

	petID := insertWorkshopPet(t, database, actor, revision, 10010001)
	eventCentreFixture(t, database, actor, books, revision, []grant.Line{{Kind: grant.StackItem, ItemID: 50005024, Amount: 348}})
	deskInfo := dispatcher.Dispatch(ctx, playtestRequest(actor, 1074, map[string]any{}))
	if deskInfo.HTTPStatus != 200 || number(t, deskInfo.Body["is_making"]) != 0 || number(t, deskInfo.Body["make_item"]) != 0 {
		t.Fatalf("1074: %d %+v", deskInfo.HTTPStatus, deskInfo.Body)
	}
	petMake := dispatcher.Dispatch(ctx, playtestRequest(actor, 1091, map[string]any{"item_id": int64(80001027), "pet_id": petID}))
	if petMake.HTTPStatus != 200 || number(t, petMake.Body["is_making"]) != 1 || number(t, petMake.Body["pet_id"]) != petID || number(t, petMake.Body["making_item"]) != 80001027 {
		t.Fatalf("1091: %d %+v", petMake.HTTPStatus, petMake.Body)
	}
	petSpeed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1089, map[string]any{"speed_num": int64(864), "building_type": int64(7)}))
	if petSpeed.HTTPStatus != 200 || number(t, petSpeed.Body["is_making"]) != 0 || number(t, petSpeed.Body["make_item"]) != 80001027 {
		t.Fatalf("1089 pet: %d %+v", petSpeed.HTTPStatus, petSpeed.Body)
	}
	petConfirmed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1088, map[string]any{"building_type": int64(7)}))
	petItems := awardRows(t, petConfirmed.Body["items"])
	if petConfirmed.HTTPStatus != 200 || len(petItems) != 1 || number(t, petItems[0]["table_id"]) != 80001027 {
		t.Fatalf("1088 pet: %d %+v", petConfirmed.HTTPStatus, petConfirmed.Body)
	}
	petInfo := dispatcher.Dispatch(ctx, playtestRequest(actor, 1090, map[string]any{}))
	if petInfo.HTTPStatus != 200 || number(t, petInfo.Body["pet_id"]) != petID {
		t.Fatalf("1090: %d %+v", petInfo.HTTPStatus, petInfo.Body)
	}
}
