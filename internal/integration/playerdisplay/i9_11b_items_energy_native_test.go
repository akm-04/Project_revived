//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"errors"
	"sort"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyconsumestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/itemsenergy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

func itemsEnergyService(p *pg.Pool, db tx.Beginner) app.Service {
	cs := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: db}
	receipts := kernelstore.Store{}
	privileges := privilegeProvider(p)
	i5svc := appi5.Service{Runner: runner, Store: values, Content: cs, Privileges: privileges,
		Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p},
		RedeemSecret: []byte("i9-11b-fixture-redeem-key-0000000000")}
	heroDB := characterstore.Store{Queryer: p}
	heroSvc := apphero.Service{Store: heroDB, AcquisitionStore: heroDB, Acquisition: cs,
		CollectionAdmission: apphero.CatalogCollectionAdmission{Content: cs}, Content: cs, Fencer: values,
		Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p}}
	return app.Service{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner},
		Fresh:       p,
		Content:     cs,
		Fence:       values,
		Players:     i4store.PlayerRootLocker{},
		Counters:    appconsume.Service{Store: dailyconsumestore.Store{}, Costs: appi5.MaterialCostDebiter{Store: values, Content: cs}},
		Exchange:    i5svc,
		Debiter:     appi5.MaterialCostDebiter{Store: values, Content: cs},
		Balances:    values,
		Privileges:  privileges,
		Progression: values,
		Facts:       appi5.ObjectiveFacts{Owner: i5svc, Open: values},
		Heroes:      heroSvc,
		Fragments:   cs,
		HeroWire:    heroproj.StockHero,
		Receipts:    receipts,
		ReceiptRead: kernelstore.Reader{Queryer: p},
	}
}

func i911bFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, d.Catalog) {
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

func i911bStack(t *testing.T, p *pg.Pool, a identity.ActorContext, itemID, quantity int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=excluded.quantity,updated_at=excluded.updated_at`, int64(a.PlayerID), itemID, quantity)
}

func i911bStackQuantity(t *testing.T, p *pg.Pool, a identity.ActorContext, itemID int64) int64 {
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

func i911bScalar(t *testing.T, p *pg.Pool, a identity.ActorContext, key string) int64 {
	t.Helper()
	balance, _, err := (i5store.Store{}).ReadScalarTx(ctx, p, a.PlayerID, key)
	if err != nil {
		t.Fatal(err)
	}
	return balance.Amount
}

func i911bEnergy(t *testing.T, p *pg.Pool, a identity.ActorContext) int64 {
	t.Helper()
	state, _, err := (i5store.Store{}).ReadTemporalTx(ctx, p, a.PlayerID, "energy")
	if err != nil {
		t.Fatal(err)
	}
	return state.StoredAmount
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
	for _, item := range catalog.Items {
		for _, giftID := range append(append([]int64(nil), item.Gifts...), item.OneInMore...) {
			gift, ok := catalog.Gift(giftID)
			if !ok {
				if wantMissing && len(item.Gifts) > 0 {
					return item.ID, giftID, true
				}
				continue
			}
			if wantMissing {
				continue
			}
			rewards, err := catalog.GiftRewards(gift, 1)
			if err != nil {
				continue
			}
			if wantDrops != (len(gift.Drops) > 0) || wantHero != (len(rewards.Heroes) > 0) {
				continue
			}
			return item.ID, giftID, true
		}
	}
	return 0, 0, false
}

func TestI911BEnergyBuyCapAndCounterProjection(t *testing.T) {
	database := pool(t)
	a, rev, _ := i911bFixture(t, database)
	service := itemsEnergyService(database, database)
	current := opPinned(rev)
	body, err := service.EnergyBuy(ctx, a, current)
	if err != nil {
		t.Fatal(err)
	}
	if body["buy_energy_times"] != int64(1) || body["energy"] != int64(220) || i911bScalar(t, database, a, "crystal") != 950 {
		t.Fatalf("first energy buy %#v crystal=%d", body, i911bScalar(t, database, a, "crystal"))
	}
	projection := app.Bootstrap{Counters: appconsume.Service{Store: dailyconsumestore.Store{}}}
	detail := map[string]any{"17": map[string]any{}}
	if err = projection.OverlayMID1(ctx, database, a, false, time.Now().UTC(), detail); err != nil {
		t.Fatal(err)
	}
	if detail["17"].(map[string]any)["buy_energy_times"] != int64(1) {
		t.Fatalf("MID17 counter %#v", detail)
	}
	nextDay := map[string]any{"17": map[string]any{}}
	if err = projection.OverlayMID1(ctx, database, a, false, time.Now().UTC().Add(24*time.Hour), nextDay); err != nil || nextDay["17"].(map[string]any)["buy_energy_times"] != int64(0) {
		t.Fatalf("next-day MID17 counter %#v %v", nextDay, err)
	}
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=499 WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID))
	exec(t, database, `UPDATE daily_consumption_players SET counts='{}'::jsonb WHERE player_id=$1`, int64(a.PlayerID))
	if _, err = service.EnergyBuy(ctx, a, opPinned(rev)); err != nil {
		t.Fatal("499 was refused", err)
	}
	if i911bEnergy(t, database, a) != 619 {
		t.Fatal("499 grant", i911bEnergy(t, database, a))
	}
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=500 WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID))
	exec(t, database, `UPDATE daily_consumption_players SET counts='{}'::jsonb WHERE player_id=$1`, int64(a.PlayerID))
	if _, err = service.EnergyBuy(ctx, a, opPinned(rev)); !errors.Is(err, app.ErrEnergyCap) {
		t.Fatalf("500 accepted: %v", err)
	}
	if i911bScalar(t, database, a, "crystal") != 900 {
		t.Fatal("cap refusal charged crystals")
	}
}

func TestI911BGoldenHandAndTenfoldSpendOnce(t *testing.T) {
	database := pool(t)
	a, rev, _ := i911bFixture(t, database)
	service := itemsEnergyService(database, database)
	first := opPinned(rev)
	body, err := service.GoldenHand(ctx, a, first)
	if err != nil {
		t.Fatal(err)
	}
	crit := body["crit"].(int64)
	if crit != 1 && crit != 2 && crit != 3 && crit != 5 && crit != 10 {
		t.Fatalf("crit %d", crit)
	}
	if body["cost"] != int64(10) || body["buy_mana_times"] != int64(1) || i911bScalar(t, database, a, "crystal") != 990 {
		t.Fatalf("golden hand %#v crystal=%d", body, i911bScalar(t, database, a, "crystal"))
	}
	mana := i911bScalar(t, database, a, "mana")
	if body["mana"] != mana || mana < 20000 {
		t.Fatalf("mana %d body %#v", mana, body)
	}
	tenfold, err := service.TenfoldGoldenHand(ctx, a, opPinned(rev))
	if err != nil {
		t.Fatal(err)
	}
	if tenfold["cost"] != int64(70) || tenfold["fumo"] == nil || tenfold["trial_info"] == nil || i911bScalar(t, database, a, "crystal") != 920 {
		t.Fatalf("tenfold %#v", tenfold)
	}
	if _, err = service.TenfoldGoldenHand(ctx, a, opPinned(rev)); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("second tenfold accepted: %v", err)
	}
	// The VIP0 golden-hand allowance is one per day.
	if _, err = service.GoldenHand(ctx, a, opPinned(rev)); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("second golden hand accepted: %v", err)
	}
	// The same operation replays the stored answer without spending again.
	crystal := i911bScalar(t, database, a, "crystal")
	replay, err := service.GoldenHand(ctx, a, first)
	expected, _ := json.Marshal(body)
	actual, _ := json.Marshal(replay)
	if err != nil || string(expected) != string(actual) || i911bScalar(t, database, a, "crystal") != crystal {
		t.Fatalf("replay %s != %s err=%v", actual, expected, err)
	}
}

func TestI911BUseSellAndMagic(t *testing.T) {
	database := pool(t)
	a, rev, catalog := i911bFixture(t, database)
	energyItem, ok := i911bFirstItem(catalog, func(item d.Item) bool {
		return item.Type == 4 && item.SubType == 5 && item.Energy > 0 && item.Stack > 0
	})
	if !ok {
		t.Fatal("no energy item")
	}
	i911bStack(t, database, a, energyItem.ID, 5)
	service := itemsEnergyService(database, database)
	if _, err := service.UseEnergyItem(ctx, a, energyItem.ID, 2, opPinned(rev)); err != nil {
		t.Fatal(err)
	}
	if i911bEnergy(t, database, a) != 100+2*energyItem.Energy || i911bStackQuantity(t, database, a, energyItem.ID) != 3 {
		t.Fatal("energy item use", i911bEnergy(t, database, a), i911bStackQuantity(t, database, a, energyItem.ID))
	}
	sellItem, ok := i911bFirstItem(catalog, func(item d.Item) bool { return item.Stack > 0 && item.Mana > 0 && item.Type != -1 })
	if !ok {
		t.Fatal("no sell item")
	}
	i911bStack(t, database, a, sellItem.ID, 4)
	manaBefore := i911bScalar(t, database, a, "mana")
	if _, err := service.SellItem(ctx, a, sellItem.ID, 3, opPinned(rev)); err != nil {
		t.Fatal(err)
	}
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
	if _, err := service.UseMagicItems(ctx, a, []app.ItemAmount{{ItemID: magicItem.ID, Num: 2}}, opPinned(rev)); err != nil {
		t.Fatal(err)
	}
	if i911bStackQuantity(t, database, a, magicItem.ID) != 0 || i911bScalar(t, database, a, "magic_energy") != magicBefore+2*magicItem.MagicEnergy {
		t.Fatal("magic use", i911bScalar(t, database, a, "magic_energy"))
	}
	// An over-stack request leaves the stack and energy untouched.
	if _, err := service.UseEnergyItem(ctx, a, energyItem.ID, 99, opPinned(rev)); err == nil {
		t.Fatal("over-stack use accepted")
	}
	if i911bStackQuantity(t, database, a, energyItem.ID) != 3 {
		t.Fatal("failed use mutated the stack")
	}
}

func TestI911BBoxFixedDrawReplayAndFailClosed(t *testing.T) {
	database := pool(t)
	a, rev, catalog := i911bFixture(t, database)
	itemID, giftID, ok := i911bBox(catalog, true, false, false)
	if !ok {
		t.Fatal("no drop box")
	}
	gift, _ := catalog.Gift(giftID)
	rewards, err := catalog.GiftRewards(gift, 1)
	if err != nil {
		t.Fatal(err)
	}
	stackAmount := int64(0)
	if len(rewards.Stacks) > 0 {
		stackAmount = rewards.Stacks[0].Amount
	}
	i911bStack(t, database, a, itemID, 3)
	service := itemsEnergyService(database, database)
	current := opPinned(rev)
	body, err := service.ExchangeCode(ctx, a, itemID, giftID, 1, current)
	if err != nil {
		t.Fatal(err)
	}
	awards, ok := body["awards"].([]any)
	if !ok || len(awards) == 0 || body["spirit_awards"] == nil {
		t.Fatalf("box reply %#v", body)
	}
	if i911bStackQuantity(t, database, a, itemID) != 2 {
		t.Fatal("box debit", i911bStackQuantity(t, database, a, itemID))
	}
	_ = stackAmount
	replay, err := service.ExchangeCode(ctx, a, itemID, giftID, 1, current)
	expected, _ := json.Marshal(body)
	actual, _ := json.Marshal(replay)
	if err != nil || string(expected) != string(actual) || i911bStackQuantity(t, database, a, itemID) != 2 {
		t.Fatalf("box replay %s != %s err=%v stacks=%d", actual, expected, err, i911bStackQuantity(t, database, a, itemID))
	}
	if _, err = service.ExchangeCode(ctx, a, itemID, giftID, 1, opPinned(rev)); err != nil || i911bStackQuantity(t, database, a, itemID) != 1 {
		t.Fatalf("new box operation %v stacks=%d", err, i911bStackQuantity(t, database, a, itemID))
	}
	missingItem, missingGift, ok := i911bBox(catalog, false, false, true)
	if !ok {
		t.Fatal("no missing-gift box")
	}
	i911bStack(t, database, a, missingItem, 1)
	if _, err = service.ExchangeCode(ctx, a, missingItem, missingGift, 1, opPinned(rev)); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("missing gift not refused: %v", err)
	}
	if i911bStackQuantity(t, database, a, missingItem) != 1 {
		t.Fatal("blocked box debited the stack")
	}
}

func TestI911BBoxHeroDuplicateToStone(t *testing.T) {
	database := pool(t)
	a, rev, catalog := i911bFixture(t, database)
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
	service := itemsEnergyService(database, database)
	body, err := service.ExchangeCode(ctx, a, itemID, giftID, 1, opPinned(rev))
	if err != nil {
		t.Fatal(err)
	}
	awards := body["awards"].([]any)
	found := false
	for _, entry := range awards {
		award, ok := entry.(map[string]any)
		if ok && award["table_id"] == stone[0] && award["to_stone"] == true {
			found = true
		}
	}
	if !found {
		t.Fatalf("duplicate hero did not become stone %v in %#v", stone, awards)
	}
	if i911bStackQuantity(t, database, a, stone[0]) < stone[1] {
		t.Fatal("stone not granted")
	}
}
