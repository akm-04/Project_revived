//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type i911cFixedClock struct {
	mu sync.Mutex
	at time.Time
}

func (c *i911cFixedClock) Now(context.Context) (time.Time, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.at, nil
}

func (c *i911cFixedClock) Set(at time.Time) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.at = at.UTC()
}

func i911cFixedOperation(at time.Time, seed byte) operation.Context {
	var entropy [32]byte
	entropy[0] = seed
	return operation.Context{ID: uuid(), StartedAt: at.UTC(), EntropySeed: entropy}
}

func i911cDispatchAt(t *testing.T, dispatcher stockruntime.ShopDispatcher, a identity.ActorContext, mid uint16, params map[string]any, at time.Time, seed byte) httpedge.Response {
	t.Helper()
	request := playtestRequest(a, mid, params)
	request.Envelope.Operation = i911cFixedOperation(at, seed)
	return dispatcher.Dispatch(ctx, request)
}

func i911cPlayer(t *testing.T, p *pg.Pool, revision string) identity.ActorContext {
	t.Helper()
	a := bornActor(t, p)
	i911cOpenFunctions(t, p, a, revision)
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(a.PlayerID))
	return a
}

func i911cStackAmount(t *testing.T, p *pg.Pool, a identity.ActorContext, itemID int64) int64 {
	t.Helper()
	var amount int64
	err := p.QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(a.PlayerID), itemID).Scan(&amount)
	if err != nil {
		t.Fatal(err)
	}
	return amount
}

func i911cShopGeneration(t *testing.T, p *pg.Pool, a identity.ActorContext, shopType int64) (int64, int64) {
	t.Helper()
	var generation, day int64
	err := p.QueryRow(ctx, `SELECT generation,refresh_day FROM shop_players WHERE player_id=$1 AND shop_type=$2`, int64(a.PlayerID), shopType).Scan(&generation, &day)
	if err != nil {
		t.Fatal(err)
	}
	return generation, day
}

func i911cFrozenPrice(t *testing.T, p *pg.Pool, a identity.ActorContext, shopType, index int64) int64 {
	t.Helper()
	var raw string
	err := p.QueryRow(ctx, `SELECT stock->>'slots' FROM shop_players WHERE player_id=$1 AND shop_type=$2`, int64(a.PlayerID), shopType).Scan(&raw)
	if err != nil {
		t.Fatal(err)
	}
	var slots []struct {
		Index     int64 `json:"index"`
		SellPrice int64 `json:"sell_price"`
	}
	if err = json.Unmarshal([]byte(raw), &slots); err != nil {
		t.Fatal(err)
	}
	for _, slot := range slots {
		if slot.Index == index {
			return slot.SellPrice
		}
	}
	t.Fatalf("frozen slot %d is absent", index)
	return 0
}

func i911cLoad(t *testing.T, dispatcher stockruntime.ShopDispatcher, a identity.ActorContext, shopType int64, at time.Time, seed byte) []map[string]any {
	t.Helper()
	response := i911cDispatchAt(t, dispatcher, a, 32, map[string]any{"shop_type": shopType}, at, seed)
	if response.HTTPStatus != 200 {
		t.Fatalf("MID 32 type %d: %+v", shopType, response)
	}
	return i911cItems(t, response)
}

func i911cFind(items []map[string]any, sellType int64) map[string]any {
	for _, item := range items {
		if item["sell_type"] == sellType {
			return item
		}
	}
	return nil
}

// C9/C4/C5: every sell_type 7/15 slot carries the source stone, not the
// substitute; the substitute pays first for type 7 and the frozen stone pays
// when it does not cover the price.
func TestI911CCoreShopsStoneSettlementNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}
	const substitute = int64(50001427)

	itemsFor := func(a identity.ActorContext) []map[string]any {
		dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
		return i911cLoad(t, dispatcher, a, 8, at, 9)
	}
	slotFor := func(items []map[string]any, sellType int64) map[string]any {
		item := i911cFind(items, sellType)
		if item == nil {
			t.Fatalf("type 8 has no sell_type %d slot", sellType)
		}
		if item["stone_id"] == nil || item["stone_id"].(int64) <= 0 {
			t.Fatalf("sell_type %d slot has no stone_id: %#v", sellType, item)
		}
		return item
	}

	substitutePlayer := i911cPlayer(t, p, revision)
	substituteItems := itemsFor(substitutePlayer)
	substituteSlot := slotFor(substituteItems, 7)
	substitutePrice := substituteSlot["sell_price"].(int64)
	product := substituteSlot["item_id"].(int64)
	stone := substituteSlot["stone_id"].(int64)
	i911cStack(t, p, substitutePlayer, substitute, substitutePrice)
	i911cStack(t, p, substitutePlayer, stone, 0)
	dispatcher := i911cCompositionAt(p, substitutePlayer, clock).Dispatcher
	buy := i911cDispatchAt(t, dispatcher, substitutePlayer, 33, map[string]any{"shop_type": int64(8), "index": substituteSlot["index"]}, at, 9)
	if buy.HTTPStatus != 200 {
		t.Fatalf("substitute purchase: %+v", buy)
	}
	if got := i911cStackAmount(t, p, substitutePlayer, substitute); got != 0 {
		t.Fatalf("substitute after = %d, want 0", got)
	}
	if got := i911cStackAmount(t, p, substitutePlayer, product); got != substituteSlot["item_num"].(int64) {
		t.Fatalf("product after substitute = %d, want %d", got, substituteSlot["item_num"])
	}

	stonePlayer := i911cPlayer(t, p, revision)
	stoneSlot := slotFor(itemsFor(stonePlayer), 7)
	stonePrice := stoneSlot["sell_price"].(int64)
	product = stoneSlot["item_id"].(int64)
	stone = stoneSlot["stone_id"].(int64)
	i911cStack(t, p, stonePlayer, substitute, 0)
	i911cStack(t, p, stonePlayer, stone, stonePrice)
	dispatcher = i911cCompositionAt(p, stonePlayer, clock).Dispatcher
	buy = i911cDispatchAt(t, dispatcher, stonePlayer, 33, map[string]any{"shop_type": int64(8), "index": stoneSlot["index"]}, at, 9)
	if buy.HTTPStatus != 200 {
		t.Fatalf("stone fallback purchase: %+v", buy)
	}
	wantStone := int64(0)
	if stone == product {
		wantStone = stoneSlot["item_num"].(int64)
	}
	if got := i911cStackAmount(t, p, stonePlayer, stone); got != wantStone {
		t.Fatalf("stone after = %d, want %d", got, wantStone)
	}

	petPlayer := i911cPlayer(t, p, revision)
	petSlot := slotFor(itemsFor(petPlayer), 15)
	petPrice := petSlot["sell_price"].(int64)
	petStone := petSlot["stone_id"].(int64)
	petProduct := petSlot["item_id"].(int64)
	i911cStack(t, p, petPlayer, substitute, 1_000_000)
	i911cStack(t, p, petPlayer, petStone, petPrice)
	dispatcher = i911cCompositionAt(p, petPlayer, clock).Dispatcher
	buy = i911cDispatchAt(t, dispatcher, petPlayer, 33, map[string]any{"shop_type": int64(8), "index": petSlot["index"]}, at, 9)
	if buy.HTTPStatus != 200 {
		t.Fatalf("pet-stone purchase: %+v", buy)
	}
	if got := i911cStackAmount(t, p, petPlayer, substitute); got != 1_000_000 {
		t.Fatalf("pet stone used the substitute: %d", got)
	}
	wantPet := int64(0)
	if petStone == petProduct {
		wantPet = petSlot["item_num"].(int64)
	}
	if got := i911cStackAmount(t, p, petPlayer, petStone); got != wantPet {
		t.Fatalf("pet stone after = %d, want %d", got, wantPet)
	}
}

// C8: the game day starts at 05:00 GMT+8 and a read rerolls only when a source
// mark passed; crossing midnight inside the game day rerolls nothing.
func TestI911CCoreShopsScheduleNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := i911cPlayer(t, p, revision)
	gmt8 := time.FixedZone("GMT+8", 8*3600)
	clock := &i911cFixedClock{at: time.Date(2026, 11, 18, 4, 59, 0, 0, gmt8)}
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher

	load := func(at time.Time) (int64, int64) {
		clock.Set(at)
		i911cLoad(t, dispatcher, a, 1, at, 4)
		return i911cShopGeneration(t, p, a, 1)
	}
	firstGeneration, firstDay := load(time.Date(2026, 11, 18, 4, 59, 0, 0, gmt8))
	afterReset, resetDay := load(time.Date(2026, 11, 18, 5, 1, 0, 0, gmt8))
	if afterReset != firstGeneration+1 || resetDay == firstDay {
		t.Fatalf("05:00 reset did not reroll: %d/%d -> %d/%d", firstGeneration, firstDay, afterReset, resetDay)
	}
	afterMark, markDay := load(time.Date(2026, 11, 18, 23, 59, 0, 0, gmt8))
	if afterMark != afterReset+1 || markDay != resetDay {
		t.Fatalf("21:00 mark did not reroll inside the game day: %d -> %d", afterReset, afterMark)
	}
	afterMidnight, midnightDay := load(time.Date(2026, 11, 19, 0, 1, 0, 0, gmt8))
	if afterMidnight != afterMark || midnightDay != markDay {
		t.Fatalf("midnight reroll outside the 05:00 boundary: %d -> %d", afterMark, afterMidnight)
	}
	nextReset, nextDay := load(time.Date(2026, 11, 19, 5, 1, 0, 0, gmt8))
	if nextReset != afterMidnight+1 || nextDay == midnightDay {
		t.Fatalf("next 05:00 reset did not reroll: %d/%d -> %d/%d", afterMidnight, midnightDay, nextReset, nextDay)
	}
}

// C7: one accepted purchase per slot per generation under concurrency.
func TestI911CCoreShopsConcurrentDoubleBuyNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := i911cPlayer(t, p, revision)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)
	items := i911cLoad(t, dispatcher, a, 1, at, 5)
	target := items[0]
	price := target["sell_price"].(int64)
	currency := "mana"
	if target["sell_type"] == int64(2) {
		currency = "crystal"
	}
	before := i911cScalarAmount(t, p, a, currency)

	responses := make(chan httpedge.Response, 2)
	var wait sync.WaitGroup
	for range 2 {
		wait.Add(1)
		go func() {
			defer wait.Done()
			responses <- i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": target["index"]}, at, 5)
		}()
	}
	wait.Wait()
	close(responses)
	ok, refused := 0, 0
	for response := range responses {
		switch {
		case response.HTTPStatus == 200:
			ok++
		case response.HTTPStatus == 409 && response.Body["error_code"] == int64(35028):
			refused++
		}
	}
	if ok != 1 || refused != 1 {
		t.Fatalf("concurrent double buy: %d accepted, %d refused", ok, refused)
	}
	if after := i911cScalarAmount(t, p, a, currency); after != before-price {
		t.Fatalf("%s %d -> %d, one debit of %d", currency, before, after, price)
	}
}

// C5: a multi-buy settles every selected slot or none.
func TestI911CCoreShopsMultiBuyAtomicNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := i911cPlayer(t, p, revision)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 0)
	items := i911cLoad(t, dispatcher, a, 1, at, 6)
	manaSlot := i911cFind(items, 1)
	if manaSlot == nil {
		t.Fatalf("type 1 drew no mana slot: %#v", items)
	}
	unaffordable := i911cFind(items, 2)
	if unaffordable == nil {
		t.Fatalf("type 1 drew no crystal slot: %#v", items)
	}

	manaBefore := i911cScalarAmount(t, p, a, "mana")
	multi := i911cDispatchAt(t, dispatcher, a, 2982, map[string]any{
		"shop_type": int64(1),
		"list":      []any{manaSlot["index"], unaffordable["index"]},
		"nums":      map[string]any{},
	}, at, 6)
	if multi.HTTPStatus != 409 || multi.Body["error_code"] != int64(20005) {
		t.Fatalf("unaffordable multi-buy: %+v", multi)
	}
	if after := i911cScalarAmount(t, p, a, "mana"); after != manaBefore {
		t.Fatalf("failed multi-buy debited mana: %d -> %d", manaBefore, after)
	}
	for _, item := range i911cLoad(t, dispatcher, a, 1, at, 6) {
		if item["isbuy"] != int64(0) {
			t.Fatalf("failed multi-buy kept a purchase: %#v", item)
		}
	}

	if buy := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": manaSlot["index"]}, at, 6); buy.HTTPStatus != 200 {
		t.Fatalf("single buy before the cap proof: %+v", buy)
	}
	manaBefore = i911cScalarAmount(t, p, a, "mana")
	cap := i911cDispatchAt(t, dispatcher, a, 2982, map[string]any{
		"shop_type": int64(1),
		"list":      []any{manaSlot["index"], unaffordable["index"]},
		"nums":      map[string]any{},
	}, at, 6)
	if cap.HTTPStatus != 409 || cap.Body["error_code"] != int64(35028) {
		t.Fatalf("cap refusal in multi-buy: %+v", cap)
	}
	if after := i911cScalarAmount(t, p, a, "mana"); after != manaBefore {
		t.Fatalf("capped multi-buy debited mana: %d -> %d", manaBefore, after)
	}
	for _, item := range i911cLoad(t, dispatcher, a, 1, at, 6) {
		if item["index"] == unaffordable["index"] && item["isbuy"] != int64(0) {
			t.Fatalf("capped multi-buy settled the second slot: %#v", item)
		}
	}
}

// C5: a failure after the I5 mutation rolls the whole command back.
func TestI911CCoreShopsRollbackNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := i911cPlayer(t, p, revision)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)
	items := i911cLoad(t, dispatcher, a, 1, at, 7)
	target := items[0]
	currency := "mana"
	if target["sell_type"] == int64(2) {
		currency = "crystal"
	}
	before := i911cScalarAmount(t, p, a, currency)

	trigger := fmt.Sprintf("i911c_rollback_%d", a.PlayerID)
	function := fmt.Sprintf("i911c_rollback_fn_%d", a.PlayerID)
	exec(t, p, fmt.Sprintf(`CREATE FUNCTION %s() RETURNS trigger LANGUAGE plpgsql AS $$BEGIN RAISE EXCEPTION 'i9-11c rollback proof'; END$$`, function))
	exec(t, p, fmt.Sprintf(`CREATE TRIGGER %s BEFORE UPDATE ON shop_players FOR EACH ROW WHEN (OLD.player_id = %d) EXECUTE FUNCTION %s()`, trigger, int64(a.PlayerID), function))
	t.Cleanup(func() {
		exec(t, p, fmt.Sprintf(`DROP TRIGGER IF EXISTS %s ON shop_players`, trigger))
		exec(t, p, fmt.Sprintf(`DROP FUNCTION IF EXISTS %s()`, function))
	})

	failed := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": target["index"]}, at, 7)
	if failed.HTTPStatus != 500 {
		t.Fatalf("mid-transaction failure answered: %+v", failed)
	}
	exec(t, p, fmt.Sprintf(`DROP TRIGGER %s ON shop_players`, trigger))
	if after := i911cScalarAmount(t, p, a, currency); after != before {
		t.Fatalf("rolled-back command debited %s: %d -> %d", currency, before, after)
	}
	for _, item := range i911cLoad(t, dispatcher, a, 1, at, 7) {
		if item["index"] == target["index"] && item["isbuy"] != int64(0) {
			t.Fatalf("rolled-back command kept the purchase: %#v", item)
		}
	}
}

// C10: the discount applies through the production price path, and the month
// card lowers it only for the two merchant types.
func TestI911CCoreShopsDiscountNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}

	findDiscounted := func() (identity.ActorContext, byte, map[string]any) {
		for seed := byte(1); seed <= 32; seed++ {
			a := i911cPlayer(t, p, revision)
			dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
			for _, item := range i911cLoad(t, dispatcher, a, 4, at, seed) {
				if item["discount"] == int64(1) {
					return a, seed, item
				}
			}
		}
		t.Fatal("no discounted type 4 slot in 32 seeds")
		return identity.ActorContext{}, 0, nil
	}
	plainPlayer, seed, plainSlot := findDiscounted()
	i911cScalar(t, p, plainPlayer, "crystal", 1_000_000)
	rawPrice := i911cFrozenPrice(t, p, plainPlayer, 4, plainSlot["index"].(int64))
	plainPrice := rawPrice * 600_000 / 1_000_000
	if plainSlot["sell_price"] != plainPrice || plainPrice >= rawPrice || plainPrice <= 0 {
		t.Fatalf("discount 0.6 was not applied: raw %d reply %#v", rawPrice, plainSlot)
	}
	plainBefore := i911cScalarAmount(t, p, plainPlayer, "crystal")
	buy := i911cDispatchAt(t, i911cCompositionAt(p, plainPlayer, clock).Dispatcher, plainPlayer, 33, map[string]any{"shop_type": int64(4), "index": plainSlot["index"]}, at, seed)
	if buy.HTTPStatus != 200 {
		t.Fatalf("discounted purchase: %+v", buy)
	}
	if after := i911cScalarAmount(t, p, plainPlayer, "crystal"); after != plainBefore-plainPrice {
		t.Fatalf("discount debit %d -> %d, want %d", plainBefore, after, plainPrice)
	}

	cardPlayer := i911cPlayer(t, p, revision)
	i911cMonthCard(t, p, cardPlayer, revision, at)
	i911cScalar(t, p, cardPlayer, "crystal", 1_000_000)
	dispatcher := i911cCompositionAt(p, cardPlayer, clock).Dispatcher
	var cardSlot map[string]any
	for _, item := range i911cLoad(t, dispatcher, cardPlayer, 4, at, seed) {
		if item["index"] == plainSlot["index"] {
			cardSlot = item
		}
	}
	if cardSlot == nil {
		t.Fatal("month-card player did not load the same slot")
	}
	cardPrice := i911cFrozenPrice(t, p, cardPlayer, 4, cardSlot["index"].(int64)) * 550_000 / 1_000_000
	if cardSlot["sell_price"] != cardPrice || cardPrice >= plainPrice {
		t.Fatalf("month card price = %v, want %d below %d", cardSlot["sell_price"], cardPrice, plainPrice)
	}
	cardBefore := i911cScalarAmount(t, p, cardPlayer, "crystal")
	buy = i911cDispatchAt(t, dispatcher, cardPlayer, 33, map[string]any{"shop_type": int64(4), "index": cardSlot["index"]}, at, seed)
	if buy.HTTPStatus != 200 {
		t.Fatalf("month-card purchase: %+v", buy)
	}
	if after := i911cScalarAmount(t, p, cardPlayer, "crystal"); after != cardBefore-cardPrice {
		t.Fatalf("month-card debit %d -> %d, want %d", cardBefore, after, cardPrice)
	}
}

func i911cMonthCard(t *testing.T, p *pg.Pool, a identity.ActorContext, revision string, at time.Time) {
	t.Helper()
	exec(t, p, `INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at)VALUES($1,$2,100,1,'QUALIFIED_ABSENT',$3,'C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1','MANUAL_PRESERVATION','i9-11c-native','i9-11c month card',1,$4,$4)`,
		int64(a.PlayerID), int64(a.LogicalServerID), revision, at.Add(-time.Hour))
	exec(t, p, `INSERT INTO commerce_charge_cards(player_id,month_card_start,month_card_end,privilege_card_end,updated_at)VALUES($1,$2,$3,0,$4)`,
		int64(a.PlayerID), at.Add(-time.Hour).Unix(), at.Add(time.Hour).Unix(), at)
}

// C10/C8: type 13 uses the base price and refuses a client price that disagrees
// with it; a missing or short price list is malformed.
func TestI911CCoreShopsMagicPriceNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := i911cPlayer(t, p, revision)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "crystal", 1_000_000)
	items := i911cLoad(t, dispatcher, a, 13, at, 8)
	if len(items) < 3 {
		t.Fatalf("type 13 has %d slots", len(items))
	}
	target, second, third := items[0], items[1], items[2]
	price := target["sell_price"].(int64)
	if price <= 0 {
		t.Fatalf("type 13 base price: %#v", target)
	}
	missing := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(13), "index": target["index"]}, at, 8)
	if missing.HTTPStatus != 400 {
		t.Fatalf("missing client_price: %+v", missing)
	}
	expired := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(13), "index": target["index"], "client_price": price - 1}, at, 8)
	if expired.HTTPStatus != 409 || expired.Body["error_code"] != int64(34020) {
		t.Fatalf("expired client price: %+v", expired)
	}
	discounted := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(13), "index": target["index"], "client_price": price + 1}, at, 8)
	if discounted.HTTPStatus != 409 || discounted.Body["error_code"] != int64(34021) {
		t.Fatalf("extra client discount: %+v", discounted)
	}
	crystalBefore := i911cScalarAmount(t, p, a, "crystal")
	ok := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(13), "index": target["index"], "client_price": price}, at, 8)
	if ok.HTTPStatus != 200 {
		t.Fatalf("type 13 base price purchase: %+v", ok)
	}
	if after := i911cScalarAmount(t, p, a, "crystal"); after != crystalBefore-price {
		t.Fatalf("type 13 debit %d -> %d, want %d", crystalBefore, after, price)
	}

	short := i911cDispatchAt(t, dispatcher, a, 2982, map[string]any{
		"shop_type":     int64(13),
		"list":          []any{second["index"], third["index"]},
		"client_prices": []any{second["sell_price"]},
		"nums":          map[string]any{},
	}, at, 8)
	if short.HTTPStatus != 400 {
		t.Fatalf("short client_prices: %+v", short)
	}
	beforeMulti := i911cScalarAmount(t, p, a, "crystal")
	multi := i911cDispatchAt(t, dispatcher, a, 2982, map[string]any{
		"shop_type":     int64(13),
		"list":          []any{second["index"], third["index"]},
		"client_prices": []any{second["sell_price"], third["sell_price"]},
		"nums":          map[string]any{},
	}, at, 8)
	if multi.HTTPStatus != 200 {
		t.Fatalf("type 13 multi-buy: %+v", multi)
	}
	want := second["sell_price"].(int64) + third["sell_price"].(int64)
	if after := i911cScalarAmount(t, p, a, "crystal"); after != beforeMulti-want {
		t.Fatalf("type 13 multi debit %d -> %d, want %d", beforeMulti, after, want)
	}
}

// C14/D476: a valid overlay disables or reprices known rows and an invalid one
// fails closed to the source catalog.
func TestI911CCoreShopsTuningNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := i911cPlayer(t, p, revision)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)
	items := i911cLoad(t, dispatcher, a, 1, at, 10)
	first, second, third := items[0]["index"], items[1]["index"], items[2]["index"]

	overlay := fmt.Sprintf(`{"revision":1,"rows":[{"shop_type":1,"index":%d,"disabled":true},{"shop_type":1,"index":%d,"sell_price":7},{"shop_type":1,"index":%d,"max_buys":0}]}`,
		first, second, third)
	exec(t, p, `INSERT INTO shop_tuning(singleton,payload,payload_version,revision,updated_at)VALUES(true,$1::jsonb,1,1,$2)`, overlay, at)
	t.Cleanup(func() {
		exec(t, p, `DELETE FROM shop_tuning`)
	})

	tuned := i911cLoad(t, dispatcher, a, 1, at, 10)
	for _, item := range tuned {
		switch item["index"] {
		case first, third:
			if item["isbuy"] != int64(1) {
				t.Fatalf("disabled slot %v is buyable: %#v", item["index"], item)
			}
		case second:
			if item["sell_price"] != int64(7) {
				t.Fatalf("repriced slot = %v, want 7", item["sell_price"])
			}
		}
	}
	for _, index := range []any{first, third} {
		if refused := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": index}, at, 10); refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(35028) {
			t.Fatalf("disabled slot %v sold: %+v", index, refused)
		}
	}
	if buy := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": second}, at, 10); buy.HTTPStatus != 200 {
		t.Fatalf("repriced slot buy: %+v", buy)
	}

	invalid := `{"revision":2,"rows":[{"shop_type":1,"index":9999,"disabled":true}]}`
	exec(t, p, `UPDATE shop_tuning SET payload=$1::jsonb,revision=2,updated_at=$2`, invalid, at)
	restored := i911cLoad(t, dispatcher, a, 1, at, 10)
	for _, item := range restored {
		if item["index"] == first && item["isbuy"] != int64(0) {
			t.Fatalf("invalid overlay still disabled a slot: %#v", item)
		}
	}
	if buy := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": first}, at, 10); buy.HTTPStatus != 200 {
		t.Fatalf("source catalog not restored: %+v", buy)
	}
}

// C2/C17: the installed catalog keeps its pinned counts and rejects drift.
func TestI911CCoreShopsCatalogDriftNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	var raw string
	if err := p.QueryRow(ctx, `SELECT payload::text FROM content_shop_catalogs WHERE revision_id=$1`, revision).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	var catalog builtin.ShopCatalog
	if err := json.Unmarshal([]byte(raw), &catalog); err != nil {
		t.Fatal(err)
	}
	if err := builtin.QualifyShopCatalog(catalog); err != nil {
		t.Fatalf("installed catalog does not qualify: %v", err)
	}
	counts := catalog.SourceRowCounts
	if counts.StockRows != 1317 || counts.DropboxGroupsReferenced != 342 || counts.DropboxRowsReferenced != 2690 || counts.RefreshCostRows != 330 {
		t.Fatalf("installed catalog counts: %+v", counts)
	}
	groups := 0
	for key, rolls := range catalog.Groups {
		for position, roll := range rolls {
			if roll.SellType != 7 && roll.SellType != 15 {
				continue
			}
			groups++
			catalog.Groups[key][position].StoneID = 0
			if err := builtin.QualifyShopCatalog(catalog); err == nil {
				t.Fatalf("missing stone_id was accepted for group %s", key)
			}
			catalog.Groups[key][position].StoneID = roll.StoneID
		}
	}
	if groups == 0 {
		t.Fatal("installed catalog has no stone-priced roll")
	}
}
