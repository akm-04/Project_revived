//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/shop"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// countingShopFacts is the app ObjectiveFacts port plus a record of every fact
// the shop command reported inside its transaction.
type countingShopFacts struct {
	app.ObjectiveFacts
	facts []objective.Fact
}

func (f *countingShopFacts) RecordTx(c context.Context, t tx.Tx, op operation.Context, facts ...objective.Fact) error {
	if err := f.ObjectiveFacts.RecordTx(c, t, op, facts...); err != nil {
		return err
	}
	f.facts = append(f.facts, facts...)
	return nil
}

func shopTriggerFacts(p *pg.Pool) *countingShopFacts {
	values := i5store.Store{Queryer: p}
	owner := appi5.Service{Store: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
	real := appi5.ObjectiveFacts{Owner: owner, Open: values, Observer: appadventure.Observer{Store: adventurestore.Store{}}}
	return &countingShopFacts{ObjectiveFacts: real}
}

// shopTriggeringOperation returns an operation whose SHOP_PURCHASE fact key
// rolls below the event 10003 rate.
func shopTriggeringOperation(t *testing.T, player identity.PlayerID, at time.Time) operation.Context {
	t.Helper()
	event, ok := d.EventForFactKind(objective.ShopPurchaseKind)
	if !ok {
		t.Fatal("SHOP_PURCHASE has no event")
	}
	for seed := 0; seed < 256; seed++ {
		op := i911cFixedOperation(at, byte(seed))
		fact := objective.Fact{PlayerID: player, SourceDomain: "shop", SourceBusinessKey: op.ID.String(), Kind: objective.ShopPurchaseKind, Delta: 1}
		key, err := fact.Key()
		if err != nil {
			t.Fatal(err)
		}
		triggered, err := d.Roll(event, key, op)
		if err != nil {
			t.Fatal(err)
		}
		if triggered {
			return op
		}
	}
	t.Fatal("no triggering operation seed found")
	return operation.Context{}
}

// shopSlotWithSellType freezes and reloads a type 1 generation until it holds a
// slot priced in the wanted currency.
func shopSlotWithSellType(t *testing.T, p *pg.Pool, dispatcher stockruntime.ShopDispatcher, a identity.ActorContext, sellType int64) map[string]any {
	t.Helper()
	at := time.Now().UTC()
	for attempt := 0; attempt < 40; attempt++ {
		exec(t, p, `DELETE FROM shop_players WHERE player_id=$1 AND shop_type=1`, int64(a.PlayerID))
		load := i911cDispatchAt(t, dispatcher, a, 32, map[string]any{"shop_type": int64(1)}, at, byte(attempt))
		if load.HTTPStatus != 200 {
			t.Fatalf("MID 32: %+v", load)
		}
		for _, item := range i911cItems(t, load) {
			if item["sell_type"] == sellType {
				return item
			}
		}
	}
	t.Fatalf("no slot priced in sell_type %d", sellType)
	return nil
}

func shopOccurrences(t *testing.T, p *pg.Pool, player identity.PlayerID) (int64, int64) {
	t.Helper()
	var count, special int64
	err := p.QueryRow(ctx, `SELECT count(*), coalesce(min(special_data),0) FROM adventure_occurrences WHERE player_id=$1 AND event_type=10003`, int64(player)).Scan(&count, &special)
	if err != nil {
		t.Fatal(err)
	}
	return count, special
}

func TestI9_11ASAdventureShopPurchaseNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	authority := pg.AuthoritativeTime{Queryer: p}
	a := i911cPlayer(t, p, revision)
	i911cScalar(t, p, a, "crystal", 1_000_000)
	i911cScalar(t, p, a, "mana", 1_000_000)
	facts := shopTriggerFacts(p)
	dispatcher := i911cCompositionWithFacts(p, a, authority, facts).Dispatcher

	crystalSlot := shopSlotWithSellType(t, p, dispatcher, a, 2)
	at := time.Now().UTC()
	operation := shopTriggeringOperation(t, a.PlayerID, at)
	crystalBefore := i911cScalarAmount(t, p, a, "crystal")
	request := playtestRequest(a, 33, map[string]any{"shop_type": int64(1), "index": crystalSlot["index"]})
	request.Envelope.Operation = operation
	buy := dispatcher.Dispatch(ctx, request)
	if buy.HTTPStatus != 200 {
		t.Fatalf("MID 33 crystal purchase: %+v", buy)
	}
	price := crystalBefore - i911cScalarAmount(t, p, a, "crystal")
	if len(facts.facts) != 1 || facts.facts[0].Kind != objective.ShopPurchaseKind || facts.facts[0].Delta != price || price <= 0 {
		t.Fatalf("facts %+v price %d", facts.facts, price)
	}
	if count, special := shopOccurrences(t, p, a.PlayerID); count != 1 || special < 1001 || special > 1007 {
		t.Fatalf("occurrence count=%d special=%d", count, special)
	}

	replay := dispatcher.Dispatch(ctx, request)
	if replay.HTTPStatus != 200 || i911cScalarAmount(t, p, a, "crystal") != crystalBefore-price {
		t.Fatalf("receipt replay: %+v", replay)
	}
	if len(facts.facts) != 1 {
		t.Fatalf("receipt replay recorded %d facts", len(facts.facts))
	}
	if count, _ := shopOccurrences(t, p, a.PlayerID); count != 1 {
		t.Fatalf("receipt replay created %d occurrences", count)
	}

	b := i911cPlayer(t, p, revision)
	i911cScalar(t, p, b, "mana", 1_000_000)
	i911cScalar(t, p, b, "crystal", 1_000_000)
	dispatcherB := i911cCompositionWithFacts(p, b, authority, facts).Dispatcher
	manaSlot := shopSlotWithSellType(t, p, dispatcherB, b, 1)
	mana := playtestRequest(b, 33, map[string]any{"shop_type": int64(1), "index": manaSlot["index"]})
	mana.Envelope.Operation = i911cFixedOperation(at, 3)
	if response := dispatcherB.Dispatch(ctx, mana); response.HTTPStatus != 200 {
		t.Fatalf("MID 33 mana purchase: %+v", response)
	}
	if len(facts.facts) != 1 {
		t.Fatalf("coin-only purchase recorded a fact: %+v", facts.facts)
	}
	refused := playtestRequest(b, 33, map[string]any{"shop_type": int64(1), "index": manaSlot["index"]})
	refused.Envelope.Operation = i911cFixedOperation(at, 4)
	if response := dispatcherB.Dispatch(ctx, refused); response.HTTPStatus != 409 {
		t.Fatalf("second purchase of a sold slot: %+v", response)
	}
	if len(facts.facts) != 1 {
		t.Fatalf("refused purchase recorded a fact: %+v", facts.facts)
	}
	if count, _ := shopOccurrences(t, p, b.PlayerID); count != 0 {
		t.Fatalf("coin-only/refused purchases created %d occurrences", count)
	}
}
