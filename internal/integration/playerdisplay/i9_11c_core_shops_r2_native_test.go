//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"strconv"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
)

type i911cSequenceClock struct {
	mu    sync.Mutex
	times []time.Time
	next  int
}

func (c *i911cSequenceClock) Now(context.Context) (time.Time, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.next >= len(c.times) {
		return time.Time{}, errors.New("i9-11c sequence clock exhausted")
	}
	at := c.times[c.next]
	c.next++
	return at.UTC(), nil
}

func (c *i911cSequenceClock) Queue(times ...time.Time) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.times = append(c.times, times...)
}

func i911cShopReceiptCount(t *testing.T, p *pg.Pool, a identity.ActorContext) int64 {
	t.Helper()
	var count int64
	err := p.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='shop'`,
		strconv.FormatInt(int64(a.PlayerID), 10)).Scan(&count)
	if err != nil {
		t.Fatal(err)
	}
	return count
}

func i911cShopRow(t *testing.T, p *pg.Pool, a identity.ActorContext, shopType int64) (int64, string) {
	t.Helper()
	var generation int64
	var stock string
	err := p.QueryRow(ctx, `SELECT generation,stock::text FROM shop_players WHERE player_id=$1 AND shop_type=$2`,
		int64(a.PlayerID), shopType).Scan(&generation, &stock)
	if err != nil {
		t.Fatal(err)
	}
	return generation, stock
}

// C5/C16 (A-138): a purchase whose product stack is full refuses 409+35028 and
// changes neither the stack, the currency, the shop row nor the receipts.
func TestI911CCoreShopsFullBackpackNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}
	a := i911cPlayer(t, p, revision)
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)

	for _, item := range i911cLoad(t, dispatcher, a, 1, at, 21) {
		itemID := item["item_id"].(int64)
		var capacity int64
		var enabled bool
		err := p.QueryRow(ctx, `SELECT stack_cap,settlement_activation='ENABLED_R4' FROM gxb_content_resource_definitions WHERE revision_id=$1 AND item_id=$2 AND class='STACK_ITEM' AND stack_cap>0`,
			revision, itemID).Scan(&capacity, &enabled)
		if err != nil || !enabled {
			continue
		}
		i911cStack(t, p, a, itemID, capacity)
		currency := "mana"
		if item["sell_type"] == int64(2) {
			currency = "crystal"
		}
		balanceBefore := i911cScalarAmount(t, p, a, currency)
		generationBefore, stockBefore := i911cShopRow(t, p, a, 1)
		receiptsBefore := i911cShopReceiptCount(t, p, a)

		response := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": item["index"]}, at, 21)
		if response.HTTPStatus != 409 || response.Body["error_code"] != int64(35028) {
			t.Fatalf("full stack purchase: %+v", response)
		}
		if got := i911cStackAmount(t, p, a, itemID); got != capacity {
			t.Fatalf("full stack changed: %d -> %d (cap %d)", capacity, got, capacity)
		}
		if got := i911cScalarAmount(t, p, a, currency); got != balanceBefore {
			t.Fatalf("full stack purchase debited %s: %d -> %d", currency, balanceBefore, got)
		}
		if gotGeneration, gotStock := i911cShopRow(t, p, a, 1); gotGeneration != generationBefore || gotStock != stockBefore {
			t.Fatalf("full stack purchase rewrote the shop row: %d -> %d", generationBefore, gotGeneration)
		}
		if got := i911cShopReceiptCount(t, p, a); got != receiptsBefore {
			t.Fatalf("full stack purchase wrote a receipt: %d -> %d", receiptsBefore, got)
		}
		return
	}
	t.Fatal("type 1 has no buyable stack slot")
}

// C8: type 13's first five manual refreshes are free, the sixth charges the
// ladder, and the 05:00 game-day boundary resets the counter.
func TestI911CCoreShopsType13RefreshNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	gmt8 := time.FixedZone("GMT+8", 8*3600)
	at := time.Date(2026, 11, 18, 20, 0, 0, 0, gmt8)
	clock := &i911cFixedClock{at: at}
	a := i911cPlayer(t, p, revision)
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "crystal", 1_000_000)
	i911cLoad(t, dispatcher, a, 13, at, 23)

	catalog, err := (contentstore.Store{Queryer: p}).ShopCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	shop, ok := catalog.Shop(13)
	if !ok {
		t.Fatal("catalog has no type 13")
	}
	for refreshTimes := int64(0); refreshTimes < 5; refreshTimes++ {
		if cost, ok := catalog.RefreshCostAt(shop, refreshTimes); !ok || cost != 0 {
			t.Fatalf("type 13 refresh %d costs %d, want free", refreshTimes, cost)
		}
	}
	paidCost, ok := catalog.RefreshCostAt(shop, 5)
	if !ok || paidCost <= 0 {
		t.Fatalf("type 13 sixth refresh cost = %d, want paid", paidCost)
	}

	freeBefore := i911cScalarAmount(t, p, a, "crystal")
	for count := int64(1); count <= 5; count++ {
		response := i911cDispatchAt(t, dispatcher, a, 34, map[string]any{"shop_type": int64(13)}, at, 23)
		if response.HTTPStatus != 200 || response.Body["refresh_times"] != count {
			t.Fatalf("free refresh %d: %+v", count, response)
		}
	}
	if got := i911cScalarAmount(t, p, a, "crystal"); got != freeBefore {
		t.Fatalf("five free refreshes charged: %d -> %d", freeBefore, got)
	}

	paidBefore := i911cScalarAmount(t, p, a, "crystal")
	paid := i911cDispatchAt(t, dispatcher, a, 34, map[string]any{"shop_type": int64(13)}, at, 23)
	if paid.HTTPStatus != 200 || paid.Body["refresh_times"] != int64(6) {
		t.Fatalf("sixth refresh: %+v", paid)
	}
	if got := i911cScalarAmount(t, p, a, "crystal"); got != paidBefore-paidCost {
		t.Fatalf("sixth refresh debit %d -> %d, want %d", paidBefore, got, paidCost)
	}

	clock.Set(time.Date(2026, 11, 19, 5, 1, 0, 0, gmt8))
	reset := i911cDispatchAt(t, dispatcher, a, 32, map[string]any{"shop_type": int64(13)}, time.Date(2026, 11, 19, 5, 1, 0, 0, gmt8), 23)
	if reset.HTTPStatus != 200 || reset.Body["refresh_times"] != int64(0) {
		t.Fatalf("05:00 reset did not clear refresh_times: %+v", reset)
	}
	resetBefore := i911cScalarAmount(t, p, a, "crystal")
	first := i911cDispatchAt(t, dispatcher, a, 34, map[string]any{"shop_type": int64(13)}, time.Date(2026, 11, 19, 5, 1, 0, 0, gmt8), 23)
	if first.HTTPStatus != 200 || first.Body["refresh_times"] != int64(1) {
		t.Fatalf("first refresh of the new day: %+v", first)
	}
	if got := i911cScalarAmount(t, p, a, "crystal"); got != resetBefore {
		t.Fatalf("new-day first refresh charged: %d -> %d", resetBefore, got)
	}
}

// C16 (A-139): a purchase confirmed after a scheduled reroll is stale; it must
// not generate stock or debit for a slot the client never saw. The same holds
// across the 05:00 game-day boundary.
func TestI911CCoreShopsStalePurchaseNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	gmt8 := time.FixedZone("GMT+8", 8*3600)

	exercised := func(a identity.ActorContext, clock *i911cFixedClock, loadedAt, boughtAt time.Time, seed byte) {
		t.Helper()
		dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
		i911cScalar(t, p, a, "mana", 1_000_000)
		i911cScalar(t, p, a, "crystal", 1_000_000)
		items := i911cLoad(t, dispatcher, a, 1, loadedAt, seed)
		generationBefore, stockBefore := i911cShopRow(t, p, a, 1)
		manaBefore := i911cScalarAmount(t, p, a, "mana")
		crystalBefore := i911cScalarAmount(t, p, a, "crystal")
		receiptsBefore := i911cShopReceiptCount(t, p, a)
		clock.Set(boughtAt)

		buy := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": items[0]["index"]}, boughtAt, seed)
		if buy.HTTPStatus != 409 || buy.Body["error_code"] != int64(40002) {
			t.Fatalf("stale buy: %+v", buy)
		}
		multi := i911cDispatchAt(t, dispatcher, a, 2982, map[string]any{
			"shop_type": int64(1), "list": []any{items[0]["index"], items[1]["index"]}, "nums": map[string]any{},
		}, boughtAt, seed)
		if multi.HTTPStatus != 409 || multi.Body["error_code"] != int64(40002) {
			t.Fatalf("stale multi-buy: %+v", multi)
		}
		if gotGeneration, gotStock := i911cShopRow(t, p, a, 1); gotGeneration != generationBefore || gotStock != stockBefore {
			t.Fatalf("stale purchase rewrote the shop row: generation %d -> %d", generationBefore, gotGeneration)
		}
		if got := i911cScalarAmount(t, p, a, "mana"); got != manaBefore {
			t.Fatalf("stale purchase debited mana: %d -> %d", manaBefore, got)
		}
		if got := i911cScalarAmount(t, p, a, "crystal"); got != crystalBefore {
			t.Fatalf("stale purchase debited crystal: %d -> %d", crystalBefore, got)
		}
		if got := i911cShopReceiptCount(t, p, a); got != receiptsBefore {
			t.Fatalf("stale purchase wrote a receipt: %d -> %d", receiptsBefore, got)
		}
	}

	markPlayer := i911cPlayer(t, p, revision)
	exercised(markPlayer, &i911cFixedClock{at: time.Date(2026, 11, 18, 8, 58, 0, 0, gmt8)},
		time.Date(2026, 11, 18, 8, 58, 0, 0, gmt8), time.Date(2026, 11, 18, 9, 1, 0, 0, gmt8), 24)

	dayPlayer := i911cPlayer(t, p, revision)
	exercised(dayPlayer, &i911cFixedClock{at: time.Date(2026, 11, 19, 4, 59, 0, 0, gmt8)},
		time.Date(2026, 11, 19, 4, 59, 0, 0, gmt8), time.Date(2026, 11, 19, 5, 1, 0, 0, gmt8), 25)

	unloaded := i911cPlayer(t, p, revision)
	unloadedDispatcher := i911cCompositionAt(p, unloaded, &i911cFixedClock{at: time.Date(2026, 11, 18, 12, 0, 0, 0, gmt8)}).Dispatcher
	i911cScalar(t, p, unloaded, "mana", 1_000_000)
	neverLoaded := i911cDispatchAt(t, unloadedDispatcher, unloaded, 33, map[string]any{"shop_type": int64(1), "index": int64(1)}, time.Date(2026, 11, 18, 12, 0, 0, 0, gmt8), 26)
	if neverLoaded.HTTPStatus != 409 || neverLoaded.Body["error_code"] != int64(40002) {
		t.Fatalf("purchase without a loaded generation: %+v", neverLoaded)
	}
	var rows int64
	if err := p.QueryRow(ctx, `SELECT count(*) FROM shop_players WHERE player_id=$1`, int64(unloaded.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("purchase generated %d shop rows", rows)
	}
}

// D5/C16: an owner that is not ready answers 503+35033, and a drifted shop
// artifact fails closed before any purchase changes state.
func TestI911CCoreShopsUnavailableAndDriftNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)

	unavailable := i911cPlayer(t, p, revision)
	broken := stockruntime.NewShopComposition(stockruntime.ShopDependencies{Authority: playtestAuthority{actor: unavailable}})
	response := broken.Dispatcher.Dispatch(ctx, playtestRequest(unavailable, 32, map[string]any{"shop_type": int64(1)}))
	if response.HTTPStatus != 503 || response.Body["error_code"] != int64(35033) {
		t.Fatalf("unavailable owner: %+v", response)
	}

	a := i911cPlayer(t, p, revision)
	clock := &i911cFixedClock{at: at}
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)
	items := i911cLoad(t, dispatcher, a, 1, at, 27)

	drifted := "abababababababababababababababababababababababababababababababab"
	exec(t, p, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
SELECT $1::text,decode($1::text,'hex'),schema_version,compiler_version,parser_version,
 jsonb_set(jsonb_set(manifest,'{revision_id}',to_jsonb($1::text)),'{artifact_sha256s,shop_catalog.json}',to_jsonb($2::text))
FROM gxb_content_revisions WHERE revision_id=$3`, drifted, "0000000000000000000000000000000000000000000000000000000000000000", revision)
	exec(t, p, `INSERT INTO content_shop_catalogs(revision_id,payload,payload_version)SELECT $1,payload,payload_version FROM content_shop_catalogs WHERE revision_id=$2`, drifted, revision)
	t.Cleanup(func() {
		exec(t, p, `UPDATE gxb_content_activation SET revision_id=$1 WHERE slot='content'`, revision)
		exec(t, p, `DELETE FROM content_shop_catalogs WHERE revision_id=$1`, drifted)
		exec(t, p, `DELETE FROM gxb_content_revisions WHERE revision_id=$1`, drifted)
	})
	exec(t, p, `UPDATE gxb_content_activation SET revision_id=$1,activation_version=activation_version+1,activated_at=clock_timestamp() WHERE slot='content'`, drifted)

	generationBefore, stockBefore := i911cShopRow(t, p, a, 1)
	balanceBefore := i911cScalarAmount(t, p, a, "mana")
	drift := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": items[0]["index"]}, at, 27)
	if drift.HTTPStatus != 503 || drift.Body["error_code"] != int64(35033) {
		t.Fatalf("drifted artifact: %+v", drift)
	}
	if gotGeneration, gotStock := i911cShopRow(t, p, a, 1); gotGeneration != generationBefore || gotStock != stockBefore {
		t.Fatalf("drifted purchase rewrote the shop row: generation %d -> %d", generationBefore, gotGeneration)
	}
	if got := i911cScalarAmount(t, p, a, "mana"); got != balanceBefore {
		t.Fatalf("drifted purchase debited mana: %d -> %d", balanceBefore, got)
	}
}

// D5 (A-140): a purchase whose decision time is older than a newer accepted
// purchase refuses 409+40002 and rolls back its count, debit, grant and slot.
func TestI911CCoreShopsOvertakenPurchaseNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	atLoad := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	newer := atLoad.Add(time.Second)
	older := atLoad
	clock := &i911cSequenceClock{}
	a := i911cPlayer(t, p, revision)
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)

	clock.Queue(atLoad)
	items := i911cLoad(t, dispatcher, a, 1, atLoad, 28)
	first, second := items[0], items[1]
	clock.Queue(newer)
	if accepted := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": second["index"]}, newer, 28); accepted.HTTPStatus != 200 {
		t.Fatalf("newer purchase: %+v", accepted)
	}
	var dayBefore, countBefore, streakVersionBefore int64
	var streakUpdatedBefore time.Time
	if err := p.QueryRow(ctx, `SELECT day-DATE '1970-01-01',count FROM achievement_daily_counts WHERE player_id=$1 AND achievement_id=100011`, int64(a.PlayerID)).Scan(&dayBefore, &countBefore); err != nil {
		t.Fatal(err)
	}
	if err := p.QueryRow(ctx, `SELECT state_version,updated_at FROM achievement_streaks WHERE player_id=$1 AND achievement_id=100011`, int64(a.PlayerID)).Scan(&streakVersionBefore, &streakUpdatedBefore); err != nil {
		t.Fatal(err)
	}
	manaBefore := i911cScalarAmount(t, p, a, "mana")
	crystalBefore := i911cScalarAmount(t, p, a, "crystal")
	receiptsBefore := i911cShopReceiptCount(t, p, a)

	clock.Queue(older)
	if overtaken := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": first["index"]}, older, 28); overtaken.HTTPStatus != 409 || overtaken.Body["error_code"] != int64(40002) {
		t.Fatalf("overtaken purchase: %+v", overtaken)
	}
	if got := i911cScalarAmount(t, p, a, "mana"); got != manaBefore {
		t.Fatalf("overtaken purchase debited mana: %d -> %d", manaBefore, got)
	}
	if got := i911cScalarAmount(t, p, a, "crystal"); got != crystalBefore {
		t.Fatalf("overtaken purchase debited crystal: %d -> %d", crystalBefore, got)
	}
	var dayAfter, countAfter, streakVersionAfter int64
	var streakUpdatedAfter time.Time
	if err := p.QueryRow(ctx, `SELECT day-DATE '1970-01-01',count FROM achievement_daily_counts WHERE player_id=$1 AND achievement_id=100011`, int64(a.PlayerID)).Scan(&dayAfter, &countAfter); err != nil {
		t.Fatal(err)
	}
	if err := p.QueryRow(ctx, `SELECT state_version,updated_at FROM achievement_streaks WHERE player_id=$1 AND achievement_id=100011`, int64(a.PlayerID)).Scan(&streakVersionAfter, &streakUpdatedAfter); err != nil {
		t.Fatal(err)
	}
	if dayAfter != dayBefore || countAfter != countBefore || streakVersionAfter != streakVersionBefore || !streakUpdatedAfter.Equal(streakUpdatedBefore) {
		t.Fatalf("overtaken purchase changed the achievement: day %d->%d count %d->%d version %d->%d",
			dayBefore, dayAfter, countBefore, countAfter, streakVersionBefore, streakVersionAfter)
	}
	if got := i911cShopReceiptCount(t, p, a); got != receiptsBefore {
		t.Fatalf("overtaken purchase wrote a receipt: %d -> %d", receiptsBefore, got)
	}
	clock.Queue(atLoad)
	for _, item := range i911cLoad(t, dispatcher, a, 1, atLoad, 28) {
		if item["index"] == first["index"] && item["isbuy"] != int64(0) {
			t.Fatalf("overtaken purchase kept the slot: %#v", item)
		}
	}
}

// D5 (A-140): across 05:00 an older command never overwrites the newer day's
// count; the stale-generation guard refuses before the achievement producer.
func TestI911CCoreShopsOvertakenAcrossResetNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	gmt8 := time.FixedZone("GMT+8", 8*3600)
	newDay := time.Date(2026, 11, 19, 5, 1, 0, 0, gmt8)
	oldDay := time.Date(2026, 11, 19, 4, 59, 0, 0, gmt8)
	clock := &i911cSequenceClock{}
	a := i911cPlayer(t, p, revision)
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)

	clock.Queue(newDay)
	items := i911cLoad(t, dispatcher, a, 1, newDay, 29)
	first, second := items[0], items[1]
	clock.Queue(newDay.Add(time.Second))
	if accepted := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": second["index"]}, newDay.Add(time.Second), 29); accepted.HTTPStatus != 200 {
		t.Fatalf("new-day purchase: %+v", accepted)
	}
	var dayBefore, countBefore int64
	if err := p.QueryRow(ctx, `SELECT day-DATE '1970-01-01',count FROM achievement_daily_counts WHERE player_id=$1 AND achievement_id=100011`, int64(a.PlayerID)).Scan(&dayBefore, &countBefore); err != nil {
		t.Fatal(err)
	}
	manaBefore := i911cScalarAmount(t, p, a, "mana")
	receiptsBefore := i911cShopReceiptCount(t, p, a)

	clock.Queue(oldDay)
	if older := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": first["index"]}, oldDay, 29); older.HTTPStatus != 409 || older.Body["error_code"] != int64(40002) {
		t.Fatalf("purchase from the previous day: %+v", older)
	}
	var dayAfter, countAfter int64
	if err := p.QueryRow(ctx, `SELECT day-DATE '1970-01-01',count FROM achievement_daily_counts WHERE player_id=$1 AND achievement_id=100011`, int64(a.PlayerID)).Scan(&dayAfter, &countAfter); err != nil {
		t.Fatal(err)
	}
	if dayAfter != dayBefore || countAfter != countBefore {
		t.Fatalf("older command rewrote the newer day's count: day %d->%d count %d->%d", dayBefore, dayAfter, countBefore, countAfter)
	}
	if got := i911cScalarAmount(t, p, a, "mana"); got != manaBefore {
		t.Fatalf("older command debited mana: %d -> %d", manaBefore, got)
	}
	if got := i911cShopReceiptCount(t, p, a); got != receiptsBefore {
		t.Fatalf("older command wrote a receipt: %d -> %d", receiptsBefore, got)
	}
}
