//go:build postgres

package playerdisplay_test

import (
	"strconv"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/shop"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func i911cComposition(p *pg.Pool, a identity.ActorContext) stockruntime.ShopComposition {
	return i911cCompositionAt(p, a, pg.AuthoritativeTime{Queryer: p})
}

func i911cCompositionAt(p *pg.Pool, a identity.ActorContext, authority gen.TimeAuthority) stockruntime.ShopComposition {
	return i911cTeamComposition(p, a, authority, nil)
}

func i911cCompositionWithFacts(p *pg.Pool, a identity.ActorContext, authority gen.TimeAuthority, facts app.ObjectiveFacts) stockruntime.ShopComposition {
	return i911cTeamComposition(p, a, authority, nil, facts)
}

func i911cTeamComposition(p *pg.Pool, a identity.ActorContext, authority gen.TimeAuthority, teamShops app.TeamShops, facts ...app.ObjectiveFacts) stockruntime.ShopComposition {
	content := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	receipts := kernelstore.Store{}
	privileges := privilegeProvider(p)
	i5svc := appi5.Service{Runner: runner, Store: values, Content: content, Privileges: privileges,
		Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p}}
	achievements := catalogAchievements(p, fixedCounts{})
	achievements.Runtime.Timed.Binder.Time = authority
	factPort := app.ObjectiveFacts(appi5.ObjectiveFacts{Owner: i5svc, Open: values})
	if len(facts) > 0 && facts[0] != nil {
		factPort = facts[0]
	}
	return stockruntime.NewShopComposition(stockruntime.ShopDependencies{
		Timed:        gen.TimedRunner{Binder: gen.Binder{Time: authority}, Runner: runner},
		Fresh:        p,
		Content:      content,
		Values:       values,
		Privileges:   privileges,
		I5:           i5svc,
		Receipts:     receipts,
		ReceiptRead:  kernelstore.Reader{Queryer: p},
		Authority:    playtestAuthority{actor: a},
		TeamShops:    teamShops,
		Achievements: achievements,
		Facts:        factPort,
	})
}

func i911cOpenFunctions(t *testing.T, p *pg.Pool, a identity.ActorContext, revision string) {
	t.Helper()
	for _, function := range []int64{4, 5, 8, 12, 13, 15, 16, 35, 37, 43, 46, 47, 69, 91} {
		exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,$2,$3,$4,clock_timestamp()) ON CONFLICT DO NOTHING`,
			int64(a.PlayerID), function, revision, "i9-11c-native:"+strconv.FormatInt(function, 10))
	}
}

func i911cScalar(t *testing.T, p *pg.Pool, a identity.ActorContext, key string, amount int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,$2,$3,1,clock_timestamp()) ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=excluded.amount,updated_at=excluded.updated_at`, int64(a.PlayerID), key, amount)
}

func i911cScalarAmount(t *testing.T, p *pg.Pool, a identity.ActorContext, key string) int64 {
	t.Helper()
	var amount int64
	err := p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2`, int64(a.PlayerID), key).Scan(&amount)
	if err != nil {
		t.Fatal(err)
	}
	return amount
}

func i911cStack(t *testing.T, p *pg.Pool, a identity.ActorContext, itemID, quantity int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=excluded.quantity,updated_at=excluded.updated_at`, int64(a.PlayerID), itemID, quantity)
}

func i911cDispatch(t *testing.T, dispatcher stockruntime.ShopDispatcher, a identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	return dispatcher.Dispatch(ctx, playtestRequest(a, mid, params))
}

func i911cItems(t *testing.T, response httpedge.Response) []map[string]any {
	t.Helper()
	raw, ok := response.Body["items"].([]any)
	if !ok {
		t.Fatalf("reply has no items array: %#v", response.Body)
	}
	items := make([]map[string]any, 0, len(raw))
	for _, entry := range raw {
		row, ok := entry.(map[string]any)
		if !ok {
			t.Fatalf("item row is not an object: %#v", entry)
		}
		items = append(items, row)
	}
	return items
}

func TestI911CCoreShopsNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	i911cOpenFunctions(t, p, a, revision)
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(a.PlayerID))
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)
	i911cStack(t, p, a, 50002072, 1_000_000)
	composition := i911cComposition(p, a)
	dispatcher := composition.Dispatcher

	list := i911cDispatch(t, dispatcher, a, 37, map[string]any{})
	if list.HTTPStatus != 200 {
		t.Fatalf("MID 37: %+v", list)
	}
	served, _ := list.Body["list"].([]int64)
	found := map[int64]bool{}
	for _, shopType := range served {
		found[shopType] = true
	}
	for _, want := range []int64{1, 4, 5, 8, 13, 30, 35} {
		if !found[want] {
			t.Fatalf("MID 37 list %v misses %d", served, want)
		}
	}
	if found[15] {
		t.Fatalf("team shop 15 listed while the guild campaign emits chapter_version 1")
	}

	load := i911cDispatch(t, dispatcher, a, 32, map[string]any{"shop_type": int64(1)})
	if load.HTTPStatus != 200 || load.Body["shop_type"] != int64(1) || load.Body["is_open"] != int64(1) || load.Body["open_time"] != int64(0) || load.Body["count_down"] != int64(0) {
		t.Fatalf("MID 32 type 1: %+v", load)
	}
	items := i911cItems(t, load)
	if len(items) != 8 {
		t.Fatalf("type 1 slot count %d, want 8", len(items))
	}
	for _, item := range items {
		if item["isbuy"] != int64(0) || item["buy_times"] != int64(0) || item["index"] == nil || item["sell_price"] == nil {
			t.Fatalf("unfrozen or sold item: %#v", item)
		}
		if _, present := item["stone_id"]; present {
			t.Fatalf("non-stone row carries stone_id: %#v", item)
		}
	}

	target := items[0]
	index := target["index"].(int64)
	price := target["sell_price"].(int64)
	currency := "mana"
	if target["sell_type"] == int64(2) {
		currency = "crystal"
	}
	before := i911cScalarAmount(t, p, a, currency)
	buy := i911cDispatch(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": index})
	if buy.HTTPStatus != 200 || buy.Body["isbuy"] != int64(1) || buy.Body["isBuy"] != int64(1) || buy.Body["buy_times"] != int64(1) {
		t.Fatalf("MID 33: %+v", buy)
	}
	if after := i911cScalarAmount(t, p, a, currency); after != before-price {
		t.Fatalf("%s %d -> %d, price %d", currency, before, after, price)
	}
	repeat := i911cDispatch(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": index})
	if repeat.HTTPStatus != 409 || repeat.Body["error_code"] != int64(35028) {
		t.Fatalf("cap refusal: %+v", repeat)
	}

	var pair []any
	for _, item := range items {
		if item["isbuy"] == int64(0) && item["index"] != index {
			pair = append(pair, item["index"])
		}
		if len(pair) == 2 {
			break
		}
	}
	multi := i911cDispatch(t, dispatcher, a, 2982, map[string]any{"shop_type": int64(1), "list": pair, "client_prices": map[string]any{}, "nums": map[string]any{}})
	if multi.HTTPStatus != 200 {
		t.Fatalf("MID 2982: %+v", multi)
	}
	if isBuy, _ := multi.Body["isbuy"].([]int64); len(isBuy) != 2 || isBuy[0] != 1 || isBuy[1] != 1 {
		t.Fatalf("multi isbuy %#v", multi.Body["isbuy"])
	}

	crystalBeforeRefresh := i911cScalarAmount(t, p, a, "crystal")
	refresh := i911cDispatch(t, dispatcher, a, 34, map[string]any{"shop_type": int64(1)})
	if refresh.HTTPStatus != 200 || refresh.Body["refresh_times"] != int64(1) {
		t.Fatalf("MID 34: %+v", refresh)
	}
	if after := i911cScalarAmount(t, p, a, "crystal"); after != crystalBeforeRefresh-50 {
		t.Fatalf("refresh debit %d -> %d, want 50", crystalBeforeRefresh, after)
	}
	for _, item := range i911cItems(t, refresh) {
		if item["isbuy"] != int64(0) {
			t.Fatalf("refresh kept a sold slot: %#v", item)
		}
	}

	// A purchase never generates stock, so the client loads type 30 first.
	vending := i911cDispatch(t, dispatcher, a, 32, map[string]any{"shop_type": int64(30)})
	if vending.HTTPStatus != 200 {
		t.Fatalf("MID 32 type 30: %+v", vending)
	}
	noCoin := i911cDispatch(t, dispatcher, a, 33, map[string]any{"shop_type": int64(30), "index": int64(1)})
	if noCoin.HTTPStatus != 409 || noCoin.Body["error_code"] != int64(35028) {
		t.Fatalf("type 30 minted summon_coin: %+v", noCoin)
	}

	league := i911cDispatch(t, dispatcher, a, 32, map[string]any{"shop_type": int64(35)})
	if league.HTTPStatus != 200 {
		t.Fatalf("MID 32 type 35: %+v", league)
	}
	cubeItem := i911cItems(t, league)[0]
	cubeBefore := i911cStackAmount(t, p, a, 50002072)
	cubePrice := cubeItem["sell_price"].(int64)
	cubeBuy := i911cDispatch(t, dispatcher, a, 33, map[string]any{"shop_type": int64(35), "index": cubeItem["index"]})
	if cubeBuy.HTTPStatus != 200 {
		t.Fatalf("type 35 cube purchase: %+v", cubeBuy)
	}
	if after := i911cStackAmount(t, p, a, 50002072); after != cubeBefore-cubePrice {
		t.Fatalf("type 35 cube debit %d -> %d, want %d", cubeBefore, after, cubePrice)
	}

	team := i911cDispatch(t, dispatcher, a, 32, map[string]any{"shop_type": int64(15)})
	if team.HTTPStatus != 409 || team.Body["error_code"] != int64(35028) {
		t.Fatalf("team shop listed or bought at chapter_version 1: %+v", team)
	}

	close := i911cDispatch(t, dispatcher, a, 38, map[string]any{"shop_type": int64(1)})
	if close.HTTPStatus != 409 || close.Body["error_code"] != int64(35028) {
		t.Fatalf("MID 38 closed a permanent shop: %+v", close)
	}
}
