//go:build postgres

package playerdisplay_test

import (
	"encoding/binary"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	app "gxb.local/backend/v2/internal/application/shop"
	"gxb.local/backend/v2/internal/domain/combat"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// i911cCrystalOperation returns an operation whose first shop type 1 generation
// holds slotIndex with a crystal price, so the crystal purchase branch is
// deterministic instead of depending on a random stock roll.
func i911cCrystalOperation(t *testing.T, p *pg.Pool, revision string, level int64) (operation.Context, int64) {
	t.Helper()
	catalog, err := (contentstore.Store{Queryer: p}).ShopCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	shop, ok := catalog.Shop(1)
	if !ok {
		t.Fatal("shop type 1 is not served")
	}
	for attempt := 1; attempt <= 1000; attempt++ {
		opContext := op()
		binary.BigEndian.PutUint64(opContext.EntropySeed[:], uint64(attempt))
		slots, err := catalog.Generate(shop, level, combat.NewStream(opContext.Derive(d.EntropyLabel, 1)))
		if err != nil {
			t.Fatal(err)
		}
		for _, slot := range slots {
			if slot.SellType == int64(d.SellCrystal) {
				return opContext, slot.Index
			}
		}
	}
	t.Fatal("no operation seed produced a crystal slot")
	return operation.Context{}, 0
}

// A crystal purchase records a SHOP_PURCHASE mission fact, so the shop path must
// prepare the mission facts in the settling transaction (MID 33, I9-11C C4).
func TestI911CCoreShopsCrystalBuyPreparesMissionFactsNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	i911cOpenFunctions(t, p, a, revision)
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(a.PlayerID))
	i911cScalar(t, p, a, "crystal", 1_000_000)
	i911cScalar(t, p, a, "mana", 1_000_000)
	facts := app.ObjectiveFacts(i911aMissionFacts(p))
	composition := i911cCompositionWithFacts(p, a, pg.AuthoritativeTime{Queryer: p}, facts)
	dispatcher := composition.Dispatcher

	stockOp, index := i911cCrystalOperation(t, p, revision, 100)
	loadRequest := playtestRequest(a, 32, map[string]any{"shop_type": int64(1)})
	loadRequest.Envelope.Operation = stockOp
	load := dispatcher.Dispatch(ctx, loadRequest)
	if load.HTTPStatus != 200 {
		t.Fatalf("MID 32: %+v", load)
	}
	price := int64(-1)
	for _, item := range i911cItems(t, load) {
		if item["index"] == index && item["sell_type"] == int64(d.SellCrystal) {
			price = item["sell_price"].(int64)
		}
	}
	if price < 0 {
		t.Fatalf("crystal slot %d is absent from the frozen stock", index)
	}
	before := i911cScalarAmount(t, p, a, "crystal")
	buy := i911cDispatch(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": index})
	if buy.HTTPStatus != 200 {
		t.Fatalf("MID 33 crystal purchase: %+v", buy)
	}
	if after := i911cScalarAmount(t, p, a, "crystal"); after != before-price {
		t.Fatalf("crystal %d -> %d, price %d", before, after, price)
	}
}
