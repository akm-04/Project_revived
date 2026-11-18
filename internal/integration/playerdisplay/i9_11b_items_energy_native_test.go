//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"math"
	"net/http"
	"reflect"
	"sort"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyconsumestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/missioninputs"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

func itemsEnergyComposition(p *postgres.Pool, db tx.Beginner, a identity.ActorContext) stockruntime.ItemsEnergyComposition {
	return itemsEnergyCompositionAt(p, db, a, postgres.AuthoritativeTime{Queryer: p})
}

func itemsEnergyCompositionAt(p *postgres.Pool, db tx.Beginner, a identity.ActorContext, clock gen.TimeAuthority) stockruntime.ItemsEnergyComposition {
	cs := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: db}
	receipts := kernelstore.Store{}
	privileges := privilegeProvider(p)
	i5svc := appi5.Service{Runner: runner, Store: values, Content: cs, Privileges: privileges,
		Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p},
		RedeemSecret: []byte("i9-11b-fixture-redeem-key-0000000000")}
	i5svc.Missions = &appi5.MissionMaterializer{Store: values, Catalog: cs, Activity: cs,
		Observations: missioninputs.Reader{Spending: values, Heroes: characterstore.Store{Queryer: p},
			Progression: values, Campaigns: campaignstore.Store{}, Privileges: privileges, Books: bookService(p, p)}}
	heroDB := characterstore.Store{Queryer: p}
	timed := gen.TimedRunner{Binder: gen.Binder{Time: clock}, Runner: runner}
	heroSvc := apphero.Service{Store: heroDB, AcquisitionStore: heroDB, Acquisition: cs,
		CollectionAdmission: apphero.CatalogCollectionAdmission{Content: cs}, Content: cs, Fencer: values,
		Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p},
		Runner: runner, Timed: timed, ProgressionStore: heroDB, Progression: cs,
		Economy: appi5.HeroProgressionDebiter{Store: values, Content: cs}, Backpack: values,
		Equipment: cs, EquipmentResources: appi5.HeroEquipmentResourceDebiter{Store: values, Content: cs},
		Fumo: cs, MaterialCosts: appi5.MaterialCostDebiter{Store: values, Content: cs},
		AwakeningPositions: &apphero.AwakeningPositionResolver{Raw: characterstore.RawAwakeningStore{}, Content: cs, Queryer: p},
		DailyConsume:       appconsume.Service{Store: dailyconsumestore.Store{}}}
	return stockruntime.NewItemsEnergyComposition(stockruntime.ItemsEnergyDependencies{
		Timed:       timed,
		Fresh:       p,
		Content:     cs,
		Values:      values,
		Privileges:  privileges,
		I5:          i5svc,
		Heroes:      heroSvc,
		Receipts:    receipts,
		ReceiptRead: kernelstore.Reader{Queryer: p},
		Authority:   playtestAuthority{a},
		Fumo:        &heroSvc,
	})
}

func i911bFixture(t *testing.T, p *postgres.Pool) (identity.ActorContext, string, d.Catalog) {
	t.Helper()
	rev := installed(t, p)
	a := bornActor(t, p)
	if _, err := privilegeService(p, p).ImportManual(ctx, authority(), importQ(a, uuid().String(), 0), op()); err != nil {
		t.Fatal(err)
	}
	exec(t, p, `INSERT INTO player_temporal_resources(player_id,resource_key,stored_amount,regen_anchor_at,state_version,policy_version,content_revision,updated_at)VALUES($1,'energy',100,clock_timestamp()-interval '1 hour',1,$2,$2,clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,resource_key) DO UPDATE SET stored_amount=100,regen_anchor_at=excluded.regen_anchor_at,policy_version=excluded.policy_version,content_revision=excluded.content_revision,updated_at=excluded.updated_at`, int64(a.PlayerID), rev)
	catalog, err := (contentstore.Store{Queryer: p}).DailyBuyInputsTx(ctx, p, rev)
	if err != nil {
		t.Fatal(err)
	}
	return a, rev, catalog
}

func i911bRequest(a identity.ActorContext, mid uint16, params map[string]any, o operation.Context) httpedge.DispatchRequest {
	r := playtestRequest(a, mid, params)
	r.Envelope.Operation = o
	return r
}

func i911bStatusCode(t *testing.T, response httpedge.Response) int {
	t.Helper()
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("status %d body %#v", response.HTTPStatus, response.Body)
	}
	return response.HTTPStatus
}

func i911bBodyJSON(t *testing.T, body map[string]any) string {
	t.Helper()
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	return string(raw)
}

func i911bStack(t *testing.T, p *postgres.Pool, a identity.ActorContext, itemID, quantity int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=excluded.quantity,updated_at=excluded.updated_at`, int64(a.PlayerID), itemID, quantity)
}

func i911bStackQuantity(t *testing.T, p *postgres.Pool, a identity.ActorContext, itemID int64) int64 {
	t.Helper()
	var quantity int64
	err := p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), itemID).Scan(&quantity)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0
	}
	if err != nil {
		t.Fatal(err)
	}
	return quantity
}

func i911bScalar(t *testing.T, p *postgres.Pool, a identity.ActorContext, key string) int64 {
	t.Helper()
	balance, _, err := (i5store.Store{}).ReadScalarTx(ctx, p, a.PlayerID, key)
	if err != nil {
		t.Fatal(err)
	}
	return balance.Amount
}

func i911bScalarSet(t *testing.T, p *postgres.Pool, a identity.ActorContext, key string, amount int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,$2,$3,1,clock_timestamp()) ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=excluded.amount`, int64(a.PlayerID), key, amount)
}

func i911bEnergy(t *testing.T, p *postgres.Pool, a identity.ActorContext) int64 {
	t.Helper()
	state, _, err := (i5store.Store{}).ReadTemporalTx(ctx, p, a.PlayerID, "energy")
	if err != nil {
		t.Fatal(err)
	}
	return state.StoredAmount
}

func i911bGoldenHandFacts(t *testing.T, p *postgres.Pool, a identity.ActorContext) int64 {
	t.Helper()
	return scalar(t, p, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='objective' AND operation='mission-source-fact'`, strconv.FormatInt(int64(a.PlayerID), 10))
}

func i911bFirstItem(catalog d.Catalog, match func(d.Item) bool) (d.Item, bool) {
	ids := make([]int64, 0, len(catalog.Items))
	for id := range catalog.Items {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, id := range ids {
		if match(catalog.Items[id]) {
			return catalog.Items[id], true
		}
	}
	return d.Item{}, false
}

func i911bBox(catalog d.Catalog, wantDrops, wantHero, wantMissing bool) (int64, int64, bool) {
	ids := make([]int64, 0, len(catalog.Items))
	for id := range catalog.Items {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, id := range ids {
		item := catalog.Items[id]
		for _, giftID := range append(append([]int64(nil), item.Gifts...), item.OneInMore...) {
			_, ok := catalog.Gift(giftID)
			if !ok {
				if wantMissing && len(item.Gifts) > 0 {
					return item.ID, giftID, true
				}
				continue
			}
			if wantMissing {
				continue
			}
			plan, err := catalog.ResolveBox(item.ID, giftID, 1)
			if err != nil {
				continue
			}
			rewards, err := catalog.GiftRewards(plan.Gift, 1)
			if err != nil {
				continue
			}
			if wantDrops != (len(plan.Gift.Drops) > 0) || wantHero != (len(rewards.Heroes) > 0) {
				continue
			}
			return item.ID, giftID, true
		}
	}
	return 0, 0, false
}

func TestI911BEnergyBuyCapAndCounterProjection(t *testing.T) {
	database := pool(t)
	a, _, _ := i911bFixture(t, database)
	composition := itemsEnergyComposition(database, database, a)
	dispatcher := composition.Dispatcher
	first := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	i911bStatusCode(t, first)
	replyconformance.Check(t, 97, first.Body)
	if first.Body["buy_energy_times"] != int64(1) || first.Body["energy"] != int64(220) || i911bScalar(t, database, a, "crystal") != 950 {
		t.Fatalf("first energy buy %#v crystal=%d", first.Body, i911bScalar(t, database, a, "crystal"))
	}
	detail := map[string]any{"17": map[string]any{}}
	if err := composition.MID1.OverlayMID1(ctx, database, a, false, time.Now().UTC(), detail); err != nil {
		t.Fatal(err)
	}
	if detail["17"].(map[string]any)["buy_energy_times"] != int64(1) {
		t.Fatalf("MID17 counter %#v", detail)
	}
	if counters, err := composition.Counters.Counters(ctx, a.PlayerID, time.Now().UTC()); err != nil || counters.BuyEnergyTimes != 1 || counters.BuyManaTimes != 0 {
		t.Fatalf("daily-reset counters %+v %v", counters, err)
	}
	nextDay := map[string]any{"17": map[string]any{}}
	if err := composition.MID1.OverlayMID1(ctx, database, a, false, time.Now().UTC().Add(24*time.Hour), nextDay); err != nil || nextDay["17"].(map[string]any)["buy_energy_times"] != int64(0) {
		t.Fatalf("next-day MID17 counter %#v %v", nextDay, err)
	}
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=499 WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID))
	exec(t, database, `UPDATE daily_consumption_players SET counts='{}'::jsonb WHERE player_id=$1`, int64(a.PlayerID))
	atCap := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	i911bStatusCode(t, atCap)
	if i911bEnergy(t, database, a) != 619 {
		t.Fatal("499 grant", i911bEnergy(t, database, a))
	}
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=500 WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID))
	exec(t, database, `UPDATE daily_consumption_players SET counts='{}'::jsonb WHERE player_id=$1`, int64(a.PlayerID))
	crystal := i911bScalar(t, database, a, "crystal")
	capRefusal := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	if capRefusal.HTTPStatus != http.StatusConflict || capRefusal.Body["error_code"] != int64(35031) {
		t.Fatalf("cap status %d body %#v", capRefusal.HTTPStatus, capRefusal.Body)
	}
	if capRefusal.Body["energy"] != int64(500) || capRefusal.Body["buy_energy_times"] != int64(0) {
		t.Fatalf("cap refusal projection %#v", capRefusal.Body)
	}
	if i911bScalar(t, database, a, "crystal") != crystal {
		t.Fatal("cap refusal charged crystals")
	}
	// The cap refusal wins even when the crystal balance is also short (L4).
	exec(t, database, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	capFirst := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	if capFirst.HTTPStatus != http.StatusConflict || capFirst.Body["error_code"] != int64(35031) {
		t.Fatalf("cap over balance status %d body %#v", capFirst.HTTPStatus, capFirst.Body)
	}
}

func TestI911BTuningOverlayAndFallback(t *testing.T) {
	database := pool(t)
	a, _, _ := i911bFixture(t, database)
	dispatcher := itemsEnergyComposition(database, database, a).Dispatcher
	exec(t, database, `INSERT INTO items_energy_tuning(payload,updated_at)VALUES('{"energy_max_limit":600}'::jsonb,now())`)
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=500 WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID))
	accepted := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	i911bStatusCode(t, accepted)
	if accepted.Body["energy"] != int64(620) {
		t.Fatalf("tuned cap did not serve: %#v", accepted.Body)
	}
	exec(t, database, `UPDATE items_energy_tuning SET payload='{"midas_crit_type":[1],"midas_crit_rate":[1,2]}'::jsonb`)
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=500 WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID))
	exec(t, database, `UPDATE daily_consumption_players SET counts='{}'::jsonb WHERE player_id=$1`, int64(a.PlayerID))
	fallback := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	if fallback.HTTPStatus != http.StatusConflict || fallback.Body["error_code"] != int64(35031) {
		t.Fatalf("invalid overlay did not fall back to source: %d %#v", fallback.HTTPStatus, fallback.Body)
	}
	exec(t, database, `DELETE FROM items_energy_tuning`)
}

func TestI911BGoldenHandAndTenfoldSpendOnce(t *testing.T) {
	database := pool(t)
	a, _, catalog := i911bFixture(t, database)
	composition := itemsEnergyComposition(database, database, a)
	dispatcher := composition.Dispatcher
	decorated := stockruntime.Decorated{Next: dispatcher}
	fixed := op()
	fixed.EntropySeed = [32]byte{7, 11, 13, 17}
	first := i911bRequest(a, 96, map[string]any{}, fixed)
	const manaStart = int64(5000)
	i911bScalarSet(t, database, a, "mana", manaStart)
	response := decorated.Dispatch(ctx, first)
	i911bStatusCode(t, response)
	replyconformance.Check(t, 96, response.Body)
	expectedMana, expectedCrit, _, err := catalog.MidasMana(1, 1, 1, combat.NewStream(fixed.Derive("items-energy.golden-hand/v1", 0)))
	if err != nil {
		t.Fatal(err)
	}
	// F1: mana is the rolled gain, never the post-grant balance; economy_ still
	// carries the balance from the owner's recorded write.
	if response.Body["mana"] != expectedMana {
		t.Fatalf("golden hand reply mana=%v want gain %d", response.Body["mana"], expectedMana)
	}
	i911bAssertGoldenHandBounds(t, catalog, 1, expectedMana)
	economy, _ := response.Body["economy_"].(map[string]any)
	if response.Body["crit"] != expectedCrit || i911bScalar(t, database, a, "mana")-manaStart != expectedMana || economy["mana"] != manaStart+expectedMana {
		t.Fatalf("golden hand schedule crit=%v mana=%d economy=%v want crit=%d gain=%d balance=%d", response.Body["crit"], i911bScalar(t, database, a, "mana")-manaStart, economy, expectedCrit, expectedMana, manaStart+expectedMana)
	}
	if response.Body["cost"] != int64(10) || response.Body["buy_mana_times"] != int64(1) || i911bScalar(t, database, a, "crystal") != 990 {
		t.Fatalf("golden hand %#v crystal=%d", response.Body, i911bScalar(t, database, a, "crystal"))
	}
	if i911bGoldenHandFacts(t, database, a) != 1 {
		t.Fatalf("golden-hand facts after MID96 = %d", i911bGoldenHandFacts(t, database, a))
	}
	tenfoldOp := op()
	tenfoldOp.EntropySeed = [32]byte{19, 23, 29, 31}
	tenfold := dispatcher.Dispatch(ctx, i911bRequest(a, 29, map[string]any{"consume_id": int64(1)}, tenfoldOp))
	i911bStatusCode(t, tenfold)
	replyconformance.Check(t, 29, tenfold.Body)
	expectedTenfold, _, _, err := catalog.MidasMana(1, 2, 10, combat.NewStream(tenfoldOp.Derive("items-energy.golden-hand/v1", 0)))
	if err != nil {
		t.Fatal(err)
	}
	if tenfold.Body["mana"] != expectedTenfold {
		t.Fatalf("tenfold reply mana=%v want rolled total %d", tenfold.Body["mana"], expectedTenfold)
	}
	i911bAssertGoldenHandBounds(t, catalog, 10, expectedTenfold)
	if tenfold.Body["cost"] != int64(70) || tenfold.Body["fumo"] == nil || tenfold.Body["trial_info"] == nil || i911bScalar(t, database, a, "crystal") != 920 {
		t.Fatalf("tenfold %#v", tenfold.Body)
	}
	if i911bGoldenHandFacts(t, database, a) != 2 {
		t.Fatalf("golden-hand facts after tenfold = %d", i911bGoldenHandFacts(t, database, a))
	}
	secondTenfold := dispatcher.Dispatch(ctx, i911bRequest(a, 29, map[string]any{"consume_id": int64(1)}, op()))
	if secondTenfold.HTTPStatus != http.StatusConflict || secondTenfold.Body["error_code"] != int64(35028) {
		t.Fatalf("second tenfold status %d body %#v", secondTenfold.HTTPStatus, secondTenfold.Body)
	}
	// The VIP0 golden-hand allowance is one per day.
	secondHand := dispatcher.Dispatch(ctx, i911bRequest(a, 96, map[string]any{}, op()))
	if secondHand.HTTPStatus != http.StatusConflict || secondHand.Body["error_code"] != int64(35028) {
		t.Fatalf("second golden hand status %d body %#v", secondHand.HTTPStatus, secondHand.Body)
	}
	// The same operation replays the stored answer without spending again.
	crystal := i911bScalar(t, database, a, "crystal")
	replay := dispatcher.Dispatch(ctx, first)
	i911bStatusCode(t, replay)
	wantReplay := map[string]any{}
	for _, key := range []string{"cost", "crit", "mana", "buy_mana_times"} {
		wantReplay[key] = response.Body[key]
	}
	if i911bBodyJSON(t, replay.Body) != i911bBodyJSON(t, wantReplay) {
		t.Fatalf("replay %#v != %#v", replay.Body, wantReplay)
	}
	if i911bScalar(t, database, a, "crystal") != crystal {
		t.Fatal("replay spent again")
	}
	if i911bGoldenHandFacts(t, database, a) != 2 {
		t.Fatal("replay recorded a second fact")
	}
}

func TestI911BUseSellAndMagic(t *testing.T) {
	database := pool(t)
	a, _, catalog := i911bFixture(t, database)
	dispatcher := itemsEnergyComposition(database, database, a).Dispatcher
	energyItem, ok := i911bFirstItem(catalog, func(item d.Item) bool {
		return item.Type == 4 && item.SubType == 5 && item.Energy > 0 && item.Stack > 0
	})
	if !ok {
		t.Fatal("no energy item")
	}
	i911bStack(t, database, a, energyItem.ID, 5)
	used := dispatcher.Dispatch(ctx, i911bRequest(a, 27, map[string]any{"item_id": energyItem.ID, "item_num": int64(2)}, op()))
	i911bStatusCode(t, used)
	if i911bEnergy(t, database, a) != 100+2*energyItem.Energy || i911bStackQuantity(t, database, a, energyItem.ID) != 3 {
		t.Fatal("energy item use", i911bEnergy(t, database, a), i911bStackQuantity(t, database, a, energyItem.ID))
	}
	sellItem, ok := i911bFirstItem(catalog, func(item d.Item) bool { return item.Stack > 0 && item.Mana > 0 && item.Type != -1 })
	if !ok {
		t.Fatal("no sell item")
	}
	i911bStack(t, database, a, sellItem.ID, 4)
	manaBefore := i911bScalar(t, database, a, "mana")
	sold := dispatcher.Dispatch(ctx, i911bRequest(a, 82, map[string]any{"item_id": sellItem.ID, "item_num": int64(3)}, op()))
	i911bStatusCode(t, sold)
	if i911bScalar(t, database, a, "mana") != manaBefore+3*sellItem.Mana || i911bStackQuantity(t, database, a, sellItem.ID) != 1 {
		t.Fatal("sell", i911bScalar(t, database, a, "mana"), i911bStackQuantity(t, database, a, sellItem.ID))
	}
	magicItem, ok := i911bFirstItem(catalog, func(item d.Item) bool {
		return item.SubType == 12 && item.Stack > 0 && (item.MagicEnergy > 0 || item.MagicDust > 0 || item.MagicLiquid > 0)
	})
	if !ok {
		t.Fatal("no magic item")
	}
	i911bStack(t, database, a, magicItem.ID, 2)
	magicBefore := i911bScalar(t, database, a, "magic_energy")
	magic := dispatcher.Dispatch(ctx, i911bRequest(a, 87, map[string]any{"items": []any{map[string]any{"item_id": magicItem.ID, "item_num": int64(2)}}}, op()))
	i911bStatusCode(t, magic)
	if i911bStackQuantity(t, database, a, magicItem.ID) != 0 || i911bScalar(t, database, a, "magic_energy") != magicBefore+2*magicItem.MagicEnergy {
		t.Fatal("magic use", i911bScalar(t, database, a, "magic_energy"))
	}
	// An over-stack request is stale state (409+40002) and leaves the stack alone.
	overStack := dispatcher.Dispatch(ctx, i911bRequest(a, 27, map[string]any{"item_id": energyItem.ID, "item_num": int64(99)}, op()))
	if overStack.HTTPStatus != http.StatusConflict || overStack.Body["error_code"] != int64(40002) {
		t.Fatalf("over-stack status %d body %#v", overStack.HTTPStatus, overStack.Body)
	}
	if overStack.Body["energy"] != i911bEnergy(t, database, a) || overStack.Body["buy_energy_times"] == nil {
		t.Fatalf("over-stack projection %#v", overStack.Body)
	}
	if i911bStackQuantity(t, database, a, energyItem.ID) != 3 {
		t.Fatal("failed use mutated the stack")
	}
	// MID 86 enforces the 200-request bound.
	rows := make([]any, 0, 201)
	for index := 0; index < 201; index++ {
		rows = append(rows, map[string]any{"item_id": int64(index + 1), "item_num": int64(1)})
	}
	tooMany := dispatcher.Dispatch(ctx, i911bRequest(a, 86, map[string]any{"items": rows}, op()))
	if tooMany.HTTPStatus != http.StatusBadRequest {
		t.Fatalf("201-row sell status %d body %#v", tooMany.HTTPStatus, tooMany.Body)
	}
}

func TestI911BBoxScheduleAndReplay(t *testing.T) {
	database := pool(t)
	a, _, catalog := i911bFixture(t, database)
	dispatcher := itemsEnergyComposition(database, database, a).Dispatcher
	itemID, giftID, ok := i911bBox(catalog, true, false, false)
	if !ok {
		t.Fatal("no drop box")
	}
	plan, err := catalog.ResolveBox(itemID, giftID, 1)
	if err != nil {
		t.Fatal(err)
	}
	fixed := op()
	var expected d.Rewards
	for attempt := 0; attempt < 256; attempt++ {
		fixed.EntropySeed = [32]byte{byte(attempt), 3, 5, 7}
		expected, err = catalog.RollBox(plan, combat.NewStream(fixed.Derive("items-energy.box/v1", 0)))
		if err != nil {
			t.Fatal(err)
		}
		if len(expected.Awards) > 0 {
			break
		}
	}
	if len(expected.Awards) == 0 {
		t.Fatal("no pinned seed draws an item award")
	}
	wantAwards := make([]any, 0, len(expected.Awards))
	for _, award := range expected.Awards {
		wantAwards = append(wantAwards, map[string]any{"table_id": award.TableID, "item_num": award.ItemNum})
	}
	i911bStack(t, database, a, itemID, 3)
	first := i911bRequest(a, 241, map[string]any{"item_id": itemID, "gift_id": giftID, "num": int64(1)}, fixed)
	response := dispatcher.Dispatch(ctx, first)
	i911bStatusCode(t, response)
	replyconformance.Check(t, 241, response.Body)
	if !reflect.DeepEqual(response.Body["awards"], wantAwards) || response.Body["spirit_awards"] == nil {
		t.Fatalf("box awards %#v want %#v", response.Body["awards"], wantAwards)
	}
	if i911bStackQuantity(t, database, a, itemID) != 2 {
		t.Fatal("box debit", i911bStackQuantity(t, database, a, itemID))
	}
	replay := dispatcher.Dispatch(ctx, first)
	i911bStatusCode(t, replay)
	if i911bBodyJSON(t, replay.Body) != i911bBodyJSON(t, response.Body) || i911bStackQuantity(t, database, a, itemID) != 2 {
		t.Fatalf("box replay %#v stacks=%d", replay.Body, i911bStackQuantity(t, database, a, itemID))
	}
	next := dispatcher.Dispatch(ctx, i911bRequest(a, 241, map[string]any{"item_id": itemID, "gift_id": giftID, "num": int64(1)}, op()))
	i911bStatusCode(t, next)
	if i911bStackQuantity(t, database, a, itemID) != 1 {
		t.Fatal("new box operation", i911bStackQuantity(t, database, a, itemID))
	}
	missingItem, missingGift, ok := i911bBox(catalog, false, false, true)
	if !ok {
		t.Fatal("no missing-gift box")
	}
	i911bStack(t, database, a, missingItem, 1)
	blocked := dispatcher.Dispatch(ctx, i911bRequest(a, 241, map[string]any{"item_id": missingItem, "gift_id": missingGift, "num": int64(1)}, op()))
	if blocked.HTTPStatus != http.StatusConflict || blocked.Body["error_code"] != int64(35028) {
		t.Fatalf("missing gift status %d body %#v", blocked.HTTPStatus, blocked.Body)
	}
	if i911bStackQuantity(t, database, a, missingItem) != 1 {
		t.Fatal("blocked box debited the stack")
	}
}

func TestI911BBoxHeroDuplicateToStone(t *testing.T) {
	database := pool(t)
	a, rev, catalog := i911bFixture(t, database)
	dispatcher := itemsEnergyComposition(database, database, a).Dispatcher
	itemID, giftID, ok := i911bBox(catalog, false, true, false)
	if !ok {
		t.Skip("no hero box in this content revision")
	}
	gift, _ := catalog.Gift(giftID)
	rewards, err := catalog.GiftRewards(gift, 1)
	if err != nil || len(rewards.Heroes) == 0 {
		t.Fatal(err)
	}
	heroID := rewards.Heroes[0]
	bornHero(t, database, a, rev, heroID, heroID)
	stone, err := (contentstore.Store{Queryer: database}).HeroFragmentsTx(ctx, database, rev, heroID)
	if err != nil {
		t.Skipf("hero %d has no summon duplicate conversion: %v", heroID, err)
	}
	i911bStack(t, database, a, itemID, 1)
	response := dispatcher.Dispatch(ctx, i911bRequest(a, 241, map[string]any{"item_id": itemID, "gift_id": giftID, "num": int64(1)}, op()))
	i911bStatusCode(t, response)
	replyconformance.Check(t, 241, response.Body)
	found := false
	for _, entry := range response.Body["awards"].([]any) {
		award, ok := entry.(map[string]any)
		if ok && award["table_id"] == stone[0] && award["to_stone"] == true {
			found = true
		}
	}
	if !found {
		t.Fatalf("duplicate hero did not become stone %v in %#v", stone, response.Body["awards"])
	}
	if i911bStackQuantity(t, database, a, stone[0]) < stone[1] {
		t.Fatal("stone not granted")
	}
}

// i911bAssertGoldenHandBounds checks the rolled gain against the source float
// and crit bounds, never against the wallet balance.
func i911bAssertGoldenHandBounds(t *testing.T, catalog d.Catalog, multiplier, gain int64) {
	t.Helper()
	base, err := catalog.MidasSingleBase(1, 1)
	if err != nil {
		t.Fatal(err)
	}
	floatUp := float64(catalog.Misc.MidasFloatUpBasisPoints) / 10000
	maxCrit := int64(1)
	for _, crit := range catalog.Misc.MidasCritTypes {
		if crit > maxCrit {
			maxCrit = crit
		}
	}
	lower := int64(math.Ceil(base * float64(multiplier)))
	upper := int64(math.Ceil(base * float64(multiplier) * (1 + floatUp) * float64(maxCrit)))
	if gain < lower || gain > upper {
		t.Fatalf("golden-hand gain %d outside [%d,%d]", gain, lower, upper)
	}
}

func i911bFumoHero(t *testing.T, p *postgres.Pool, a identity.ActorContext, revision string, tableID, color, slot int64) character.Hero {
	t.Helper()
	h := bornHero(t, p, a, revision, tableID, tableID)
	transaction, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := characterstore.Store{}
	hero, err := store.LockHeroByPartnerIDTx(ctx, transaction, a.PlayerID, h.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	previous := hero.StateVersion
	hero.Color = color
	hero.Equipment[slot-1] = 1
	hero.StateVersion++
	hero.UpdatedAt = time.Now().UTC()
	if err := hero.ValidatePersistent(); err != nil {
		t.Fatal(err)
	}
	if err := store.SaveHeroStateTx(ctx, transaction, hero, previous); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return hero
}

func i911bHeroFumo(t *testing.T, p *postgres.Pool, a identity.ActorContext, partnerID, slot int64) int64 {
	t.Helper()
	var fumo int64
	err := p.QueryRow(ctx, `SELECT fumo_`+strconv.FormatInt(slot, 10)+` FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), partnerID).Scan(&fumo)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0
	}
	if err != nil {
		t.Fatal(err)
	}
	return fumo
}

func i911bDailyCounts(t *testing.T, p *postgres.Pool, a identity.ActorContext, day int64) map[int64]int64 {
	t.Helper()
	counts, err := (appconsume.Service{Store: dailyconsumestore.Store{}}).ReadTx(ctx, p, a.PlayerID, day)
	if err != nil {
		t.Fatal(err)
	}
	return counts
}

func i911bScalarBalance(t *testing.T, p *postgres.Pool, a identity.ActorContext, key string) int64 {
	t.Helper()
	balance, found, err := (i5store.Store{}).ReadScalarTx(ctx, p, a.PlayerID, key)
	if err != nil {
		t.Fatal(err)
	}
	if !found {
		return 0
	}
	return balance.Amount
}

func i911bTemporal(t *testing.T, p *postgres.Pool, a identity.ActorContext, key string) int64 {
	t.Helper()
	state, found, err := (i5store.Store{}).ReadTemporalTx(ctx, p, a.PlayerID, key)
	if err != nil {
		t.Fatal(err)
	}
	if !found {
		return 0
	}
	return state.StoredAmount
}

// TestI911BQuickFumoOwnerRoute proves MID 29 consume_id 2 reaches the fumo
// owner's transaction, not Campaign, and reports the post-grant raw Fumo.
func TestI911BQuickFumoOwnerRoute(t *testing.T) {
	database := pool(t)
	a, revision, _ := i911bFixture(t, database)
	composition := itemsEnergyComposition(database, database, a)
	dispatcher := composition.Dispatcher
	hero := i911bFumoHero(t, database, a, revision, 10001001, 3, 1)
	i911bScalarSet(t, database, a, "crystal", 1000)
	request := func() httpedge.DispatchRequest {
		return i911bRequest(a, 29, map[string]any{"consume_id": int64(2), "partner_id": hero.PartnerID, "equip_index": int64(1)}, op())
	}
	response := dispatcher.Dispatch(ctx, request())
	i911bStatusCode(t, response)
	replyconformance.Check(t, 29, response.Body)
	if response.Body["fumo"] != int64(150) || response.Body["cost"] != int64(20) {
		t.Fatalf("quick fumo reply %#v", response.Body)
	}
	if i911bHeroFumo(t, database, a, hero.PartnerID, 1) != 150 || i911bScalarBalance(t, database, a, "crystal") != 980 {
		t.Fatalf("quick fumo state fumo=%d crystal=%d", i911bHeroFumo(t, database, a, hero.PartnerID, 1), i911bScalarBalance(t, database, a, "crystal"))
	}
	dayCounts := i911bDailyCounts(t, database, a, modes.Day(time.Now().UTC()))
	if dayCounts[2] != 1 {
		t.Fatalf("daily_consume id 2 count = %d", dayCounts[2])
	}
	if pipe := appconsume.Pipe(dayCounts); len(pipe) < 4 || pipe[0:4] != "0|1|" {
		t.Fatalf("MID 28 pipe projection %q", pipe)
	}
	second := dispatcher.Dispatch(ctx, request())
	if second.HTTPStatus != http.StatusConflict || second.Body["error_code"] != int64(35028) {
		t.Fatalf("second quick fumo status %d body %#v", second.HTTPStatus, second.Body)
	}
	if i911bHeroFumo(t, database, a, hero.PartnerID, 1) != 150 || i911bScalarBalance(t, database, a, "crystal") != 980 {
		t.Fatal("refused quick fumo changed state")
	}
}

// TestI911BBoxFixedChooseOneSpirit proves the MID 241 families C9 requires.
func TestI911BBoxFixedChooseOneSpirit(t *testing.T) {
	database := pool(t)
	a, _, catalog := i911bFixture(t, database)
	dispatcher := itemsEnergyComposition(database, database, a).Dispatcher
	// Fixed (no-drops, no-hero) box: 50002102 -> gift 90040391 grants 1000 crystal.
	if item, err := catalog.Item(50002102); err != nil || !reflect.DeepEqual(item.Gifts, []int64{90040391}) {
		t.Fatalf("fixed box content drift %+v %v", item, err)
	}
	i911bStack(t, database, a, 50002102, 1)
	crystalBefore := i911bScalarBalance(t, database, a, "crystal")
	fixed := dispatcher.Dispatch(ctx, i911bRequest(a, 241, map[string]any{"item_id": int64(50002102), "gift_id": int64(90040391), "num": int64(1)}, op()))
	i911bStatusCode(t, fixed)
	replyconformance.Check(t, 241, fixed.Body)
	if i911bScalarBalance(t, database, a, "crystal") != crystalBefore+1000 || i911bStackQuantity(t, database, a, 50002102) != 0 || len(fixed.Body["awards"].([]any)) != 0 {
		t.Fatalf("fixed box %#v crystal=%d", fixed.Body, i911bScalarBalance(t, database, a, "crystal"))
	}
	// Choose-one item (one_in_more): the client sends one of the item's gift rows.
	chooseItem, err := catalog.Item(50001052)
	if err != nil || len(chooseItem.OneInMore) == 0 {
		t.Fatalf("choose-one content missing: %v", err)
	}
	rewards, err := catalog.GiftRewards(catalog.Gifts[90001088], 1)
	if err != nil || len(rewards.Heroes) != 1 {
		t.Fatalf("choose-one gift rewards %+v %v", rewards, err)
	}
	i911bStack(t, database, a, 50001052, 1)
	chosen := dispatcher.Dispatch(ctx, i911bRequest(a, 241, map[string]any{"item_id": int64(50001052), "gift_id": int64(90001088), "num": int64(1)}, op()))
	i911bStatusCode(t, chosen)
	replyconformance.Check(t, 241, chosen.Body)
	if len(chosen.Body["awards"].([]any)) == 0 || i911bStackQuantity(t, database, a, 50001052) != 0 {
		t.Fatalf("choose-one box %#v", chosen.Body)
	}
	// Spirit-energy gift row: 50002142 -> gift 90040410 grants 6 spirit energy.
	before := i911bTemporal(t, database, a, "spirit_energy")
	i911bStack(t, database, a, 50002142, 1)
	spirit := dispatcher.Dispatch(ctx, i911bRequest(a, 241, map[string]any{"item_id": int64(50002142), "gift_id": int64(90040410), "num": int64(1)}, op()))
	i911bStatusCode(t, spirit)
	replyconformance.Check(t, 241, spirit.Body)
	if i911bTemporal(t, database, a, "spirit_energy") != before+6 || i911bStackQuantity(t, database, a, 50002142) != 0 {
		t.Fatalf("spirit gift %#v spirit=%d", spirit.Body, i911bTemporal(t, database, a, "spirit_energy"))
	}
}

// TestI911BBoxFailClosedEquipAndZeroStack proves two C11 families reach the
// production dispatcher and leave the stack intact. The equipment owner does
// not exist yet, and a zero-stack item cannot be opened. The lucky_coin family
// has no referenced gift row in the compiled bundle (see rules_test.go).
func TestI911BBoxFailClosedEquipAndZeroStack(t *testing.T) {
	database := pool(t)
	a, _, catalog := i911bFixture(t, database)
	dispatcher := itemsEnergyComposition(database, database, a).Dispatcher
	for _, cell := range []struct {
		itemID int64
		giftID int64
	}{
		{50001190, 90050001},
		{50001326, 1},
	} {
		if _, err := catalog.Item(cell.itemID); err != nil {
			t.Fatalf("content row %d missing: %v", cell.itemID, err)
		}
		i911bStack(t, database, a, cell.itemID, 1)
		response := dispatcher.Dispatch(ctx, i911bRequest(a, 241, map[string]any{"item_id": cell.itemID, "gift_id": cell.giftID, "num": int64(1)}, op()))
		if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35028) {
			t.Fatalf("fail-closed %d status %d body %#v", cell.itemID, response.HTTPStatus, response.Body)
		}
		if i911bStackQuantity(t, database, a, cell.itemID) != 1 {
			t.Fatalf("fail-closed %d debited the stack", cell.itemID)
		}
	}
}

// TestI911BSellAllOrNoneAt200Rows proves MID 86 validates every row before any
// mutation, including at its 200-distinct-id bound.
func TestI911BSellAllOrNoneAt200Rows(t *testing.T) {
	database := pool(t)
	a, _, catalog := i911bFixture(t, database)
	dispatcher := itemsEnergyComposition(database, database, a).Dispatcher
	sellable := make([]int64, 0, maxBatchTestItems)
	for id := range catalog.Items {
		item := catalog.Items[id]
		if item.Type != -1 && item.Stack > 0 && (item.Mana > 0 || item.Crystal > 0) {
			sellable = append(sellable, id)
		}
	}
	sort.Slice(sellable, func(i, j int) bool { return sellable[i] < sellable[j] })
	if len(sellable) < 199 {
		t.Fatalf("only %d sellable items", len(sellable))
	}
	zeroPrice := int64(0)
	for id := range catalog.Items {
		item := catalog.Items[id]
		if id != sellable[0] && item.Type != -1 && item.Stack > 0 && item.Mana == 0 && item.Crystal == 0 {
			zeroPrice = id
			break
		}
	}
	if zeroPrice == 0 {
		t.Fatal("no zero-price item")
	}
	i911bStack(t, database, a, sellable[0], 5)
	manaBefore := i911bScalarBalance(t, database, a, "mana")
	rows := func(last map[string]any) []any {
		out := make([]any, 0, 200)
		out = append(out, map[string]any{"item_id": sellable[0], "item_num": int64(1)})
		for _, id := range sellable[1:199] {
			out = append(out, map[string]any{"item_id": id, "item_num": int64(1)})
		}
		out = append(out, last)
		return out
	}
	for _, last := range []map[string]any{
		{"item_id": int64(999999999), "item_num": int64(1)},
		{"item_id": zeroPrice, "item_num": int64(1)},
	} {
		response := dispatcher.Dispatch(ctx, i911bRequest(a, 86, map[string]any{"items": rows(last)}, op()))
		if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35028) {
			t.Fatalf("all-or-none status %d body %#v", response.HTTPStatus, response.Body)
		}
		if i911bStackQuantity(t, database, a, sellable[0]) != 5 || i911bScalarBalance(t, database, a, "mana") != manaBefore {
			t.Fatal("all-or-none sell mutated state")
		}
	}
}

const maxBatchTestItems = 200

// TestI911BEnergyAllowanceExhausted proves MID 97 refuses the exhausted VIP0
// allowance with 409+35028 after one accepted buy.
func TestI911BEnergyAllowanceExhausted(t *testing.T) {
	database := pool(t)
	a, _, _ := i911bFixture(t, database)
	dispatcher := itemsEnergyComposition(database, database, a).Dispatcher
	first := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	i911bStatusCode(t, first)
	crystal := i911bScalarBalance(t, database, a, "crystal")
	energy := i911bEnergy(t, database, a)
	second := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	if second.HTTPStatus != http.StatusConflict || second.Body["error_code"] != int64(35028) {
		t.Fatalf("exhausted allowance status %d body %#v", second.HTTPStatus, second.Body)
	}
	if i911bScalarBalance(t, database, a, "crystal") != crystal || i911bEnergy(t, database, a) != energy {
		t.Fatal("exhausted allowance charged")
	}
}

type i911bClock struct{ at time.Time }

func (c *i911bClock) Now(context.Context) (time.Time, error) { return c.at, nil }

// TestI911BEnergyBuyResetsAtFive proves the 05:00 GMT+8 game-day reset by moving
// the operation's decision time across the boundary, not by a +24h overlay.
func TestI911BEnergyBuyResetsAtFive(t *testing.T) {
	database := pool(t)
	a, _, _ := i911bFixture(t, database)
	// The next boundary keeps the pinned decision times after the fixture's
	// privilege import while still crossing exactly one 05:00 GMT+8 reset.
	boundary := modes.DayBegins(modes.Day(time.Now().UTC()) + 1)
	before, after := boundary.Add(-time.Minute), boundary.Add(time.Minute)
	clock := &i911bClock{at: before}
	dispatcher := itemsEnergyCompositionAt(database, database, a, clock).Dispatcher
	exec(t, database, `UPDATE player_temporal_resources SET regen_anchor_at=$2 WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID), before.Add(-time.Hour))
	first := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	i911bStatusCode(t, first)
	if first.Body["buy_energy_times"] != int64(1) {
		t.Fatalf("pre-boundary buy %#v", first.Body)
	}
	detail := map[string]any{"17": map[string]any{}}
	composition := itemsEnergyCompositionAt(database, database, a, clock)
	if err := composition.MID1.OverlayMID1(ctx, database, a, false, before, detail); err != nil {
		t.Fatal(err)
	}
	if detail["17"].(map[string]any)["buy_energy_times"] != int64(1) {
		t.Fatalf("pre-boundary MID17 %#v", detail)
	}
	nextDay := map[string]any{"17": map[string]any{}}
	if err := composition.MID1.OverlayMID1(ctx, database, a, false, after, nextDay); err != nil || nextDay["17"].(map[string]any)["buy_energy_times"] != int64(0) {
		t.Fatalf("post-boundary MID17 %#v %v", nextDay, err)
	}
	clock.at = after
	second := dispatcher.Dispatch(ctx, i911bRequest(a, 97, map[string]any{}, op()))
	i911bStatusCode(t, second)
	if second.Body["buy_energy_times"] != int64(1) {
		t.Fatalf("post-boundary buy %#v", second.Body)
	}
	if i911bScalarBalance(t, database, a, "crystal") != 900 {
		t.Fatalf("post-boundary crystal %d", i911bScalarBalance(t, database, a, "crystal"))
	}
	if counters, err := composition.Counters.Counters(ctx, a.PlayerID, after); err != nil || counters.BuyEnergyTimes != 1 {
		t.Fatalf("post-boundary counter %+v %v", counters, err)
	}
}

type i911bRollbackDB struct{ tx.Beginner }

func (d i911bRollbackDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	transaction, err := d.Beginner.Begin(c, o)
	if err != nil {
		return nil, err
	}
	return i911bRollbackTx{Tx: transaction}, nil
}

type i911bRollbackTx struct{ tx.Tx }

func (t i911bRollbackTx) Commit(c context.Context) error {
	_ = t.Tx.Rollback(c)
	return errors.New("i9-11b injected rollback")
}

// TestI911BAtomicRollbackEveryWriteMID runs one accepted command per write MID
// through a transaction whose COMMIT is replaced by ROLLBACK and proves no part
// of any command survives.
func TestI911BAtomicRollbackEveryWriteMID(t *testing.T) {
	database := pool(t)
	a, revision, catalog := i911bFixture(t, database)
	rollback := itemsEnergyComposition(database, i911bRollbackDB{Beginner: database}, a).Dispatcher
	energyItem, found := i911bFirstItem(catalog, func(item d.Item) bool {
		return item.Type == 4 && item.SubType == 5 && item.Energy > 0 && item.Stack > 0
	})
	if !found {
		t.Fatal("no energy item")
	}
	magicItem, found := i911bFirstItem(catalog, func(item d.Item) bool {
		return item.SubType == 12 && item.Stack > 0 && (item.MagicEnergy > 0 || item.MagicDust > 0 || item.MagicLiquid > 0)
	})
	if !found {
		t.Fatal("no magic item")
	}
	secondSell := int64(0)
	for id, item := range catalog.Items {
		if id != 41001 && item.Type != -1 && item.Stack > 0 && item.Mana > 0 {
			secondSell = id
			break
		}
	}
	if secondSell == 0 {
		t.Fatal("no second sell item")
	}
	hero := i911bFumoHero(t, database, a, revision, 10001001, 3, 1)
	i911bStack(t, database, a, energyItem.ID, 5)
	i911bStack(t, database, a, 41001, 4)
	i911bStack(t, database, a, secondSell, 3)
	i911bStack(t, database, a, magicItem.ID, 2)
	i911bStack(t, database, a, 50002102, 3)
	i911bScalarSet(t, database, a, "crystal", 1000)
	i911bScalarSet(t, database, a, "mana", 5000)
	dispatch := func(mid uint16, params map[string]any) {
		t.Helper()
		response := rollback.Dispatch(ctx, i911bRequest(a, mid, params, op()))
		if response.HTTPStatus == http.StatusOK {
			t.Fatalf("MID %d committed through the injected rollback: %#v", mid, response.Body)
		}
	}
	dispatch(27, map[string]any{"item_id": energyItem.ID, "item_num": int64(2)})
	if i911bStackQuantity(t, database, a, energyItem.ID) != 5 || i911bEnergy(t, database, a) != 100 {
		t.Fatal("MID 27 rollback leaked")
	}
	dispatch(82, map[string]any{"item_id": int64(41001), "item_num": int64(1)})
	if i911bStackQuantity(t, database, a, 41001) != 4 || i911bScalarBalance(t, database, a, "mana") != 5000 {
		t.Fatal("MID 82 rollback leaked")
	}
	dispatch(86, map[string]any{"items": []any{map[string]any{"item_id": int64(41001), "item_num": int64(1)}, map[string]any{"item_id": secondSell, "item_num": int64(1)}}})
	if i911bStackQuantity(t, database, a, 41001) != 4 || i911bStackQuantity(t, database, a, secondSell) != 3 {
		t.Fatal("MID 86 rollback leaked")
	}
	dispatch(87, map[string]any{"items": []any{map[string]any{"item_id": magicItem.ID, "item_num": int64(1)}}})
	if i911bStackQuantity(t, database, a, magicItem.ID) != 2 || i911bScalarBalance(t, database, a, "magic_energy") != 0 {
		t.Fatal("MID 87 rollback leaked")
	}
	dispatch(96, map[string]any{})
	if i911bScalarBalance(t, database, a, "crystal") != 1000 || i911bScalarBalance(t, database, a, "mana") != 5000 || i911bGoldenHandFacts(t, database, a) != 0 {
		t.Fatal("MID 96 rollback leaked")
	}
	dispatch(97, map[string]any{})
	if i911bScalarBalance(t, database, a, "crystal") != 1000 || i911bEnergy(t, database, a) != 100 {
		t.Fatal("MID 97 rollback leaked")
	}
	dispatch(241, map[string]any{"item_id": int64(50002102), "gift_id": int64(90040391), "num": int64(1)})
	if i911bStackQuantity(t, database, a, 50002102) != 3 || i911bScalarBalance(t, database, a, "crystal") != 1000 {
		t.Fatal("MID 241 rollback leaked")
	}
	dispatch(29, map[string]any{"consume_id": int64(1)})
	if i911bScalarBalance(t, database, a, "crystal") != 1000 || i911bScalarBalance(t, database, a, "mana") != 5000 {
		t.Fatal("MID 29 id 1 rollback leaked")
	}
	dispatch(29, map[string]any{"consume_id": int64(2), "partner_id": hero.PartnerID, "equip_index": int64(1)})
	if i911bScalarBalance(t, database, a, "crystal") != 1000 || i911bHeroFumo(t, database, a, hero.PartnerID, 1) != 0 {
		t.Fatal("MID 29 id 2 rollback leaked")
	}
	if dayCounts := i911bDailyCounts(t, database, a, modes.Day(time.Now().UTC())); dayCounts[1] != 0 || dayCounts[2] != 0 {
		t.Fatalf("daily counters leaked %v", dayCounts)
	}
}
