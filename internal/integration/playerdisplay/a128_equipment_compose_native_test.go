//go:build postgres

package playerdisplay_test

import (
	"net/http"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func a128HeroService(p *pg.Pool) characterhero.Service {
	content := contentstore.Store{Queryer: p}
	heroes := characterstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	exchanger := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("a128-native-fixture-only-secret-000")}
	return characterhero.Service{Runner: runner, Store: heroes, Fencer: values, Content: content, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, ProgressionStore: heroes, Progression: content, Equipment: content, Exchange: exchanger}
}

func a128ComposeDispatcher(t *testing.T, p *pg.Pool, a identity.ActorContext) stockruntime.ComposeDispatcher {
	t.Helper()
	return stockruntime.ComposeDispatcher{Authority: fixedBookAuthority{actor: a}, Book: stockruntime.NewCoalescedBookRead(bookService(p, p)), Equipment: a128HeroService(p)}
}

func a128ComposeRequest(t *testing.T, a identity.ActorContext, itemID, amount int64, op operation.Context) httpedge.DispatchRequest {
	t.Helper()
	params := map[string]any{"item_id": itemID}
	if amount != 1 {
		params["item_num"] = amount
	}
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 83, Params: params, ReceivedAt: time.Now().UTC(), Operation: op, Claims: wire.CredentialClaims{Token: "bearer", Region: int64(a.LogicalServerID)}}}
}

func a128Stack(t *testing.T, p *pg.Pool, a identity.ActorContext, itemID, quantity int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,1,clock_timestamp(),clock_timestamp()) ON CONFLICT(player_id,item_id)DO UPDATE SET quantity=excluded.quantity`, int64(a.PlayerID), itemID, quantity)
}

func a128Quantity(t *testing.T, p *pg.Pool, a identity.ActorContext, itemID int64) int64 {
	t.Helper()
	var quantity int64
	if e := p.QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(a.PlayerID), itemID).Scan(&quantity); e != nil {
		t.Fatal(e)
	}
	return quantity
}

func a128Mana(t *testing.T, p *pg.Pool, a identity.ActorContext) int64 {
	t.Helper()
	var amount int64
	if e := p.QueryRow(ctx, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='mana'),0)`, int64(a.PlayerID)).Scan(&amount); e != nil {
		t.Fatal(e)
	}
	return amount
}

func a128SetMana(t *testing.T, p *pg.Pool, a identity.ActorContext, amount int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'mana',$2,1,clock_timestamp()) ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=excluded.amount`, int64(a.PlayerID), amount)
}

func a128GrantWatchBoard(t *testing.T, p *pg.Pool, a identity.ActorContext) {
	t.Helper()
	for _, item := range []int64{50001645, 20001134, 20001136, 20001130} {
		a128Stack(t, p, a, item, 1)
	}
}

func TestA128EquipmentComposeThroughProductionDispatcher(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	dispatcher := a128ComposeDispatcher(t, p, a)
	a128GrantWatchBoard(t, p, a)
	a128SetMana(t, p, a, 100000)

	first := op()
	got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 20001361, 1, first))
	if got.HTTPStatus != http.StatusOK {
		t.Fatalf("equipment compose status=%d body=%#v", got.HTTPStatus, got.Body)
	}
	if got := a128Quantity(t, p, a, 20001361); got != 1 {
		t.Fatalf("target quantity=%d", got)
	}
	for _, item := range []int64{50001645, 20001134, 20001136, 20001130} {
		if got := a128Quantity(t, p, a, item); got != 0 {
			t.Fatalf("component %d quantity=%d", item, got)
		}
	}
	if got := a128Mana(t, p, a); got != 90000 {
		t.Fatalf("mana after compose=%d", got)
	}

	replay := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 20001361, 1, first))
	if replay.HTTPStatus != http.StatusOK {
		t.Fatalf("replay status=%d body=%#v", replay.HTTPStatus, replay.Body)
	}
	if got := a128Quantity(t, p, a, 20001361); got != 1 {
		t.Fatalf("replay granted again: %d", got)
	}
	if got := a128Mana(t, p, a); got != 90000 {
		t.Fatalf("replay debited again: %d", got)
	}

	a128GrantWatchBoard(t, p, a)
	a128Stack(t, p, a, 20001134, 0)
	refused := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 20001361, 1, op()))
	if refused.HTTPStatus != http.StatusConflict || refused.Body["error_code"] != int64(35028) {
		t.Fatalf("missing component status=%d body=%#v", refused.HTTPStatus, refused.Body)
	}
	if got := a128Quantity(t, p, a, 20001361); got != 1 {
		t.Fatalf("refused compose granted: %d", got)
	}
	if got := a128Mana(t, p, a); got != 90000 {
		t.Fatalf("refused compose debited mana: %d", got)
	}
}

func TestA128EquipmentCategoryBoundaries(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	dispatcher := a128ComposeDispatcher(t, p, a)
	a128SetMana(t, p, a, 100000)

	// Aegis: the second awakened equipment recipe from the same source graph.
	a128Stack(t, p, a, 50001893, 1)
	a128Stack(t, p, a, 20001155, 1)
	a128Stack(t, p, a, 20001138, 1)
	a128Stack(t, p, a, 20001130, 1)
	if got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 20001435, 1, op())); got.HTTPStatus != http.StatusOK {
		t.Fatalf("Aegis compose status=%d body=%#v", got.HTTPStatus, got.Body)
	}

	// Ordinary gear uses the same recipe graph and source item type.
	a128Stack(t, p, a, 60001027, 60)
	if got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 20001134, 1, op())); got.HTTPStatus != http.StatusOK {
		t.Fatalf("ordinary gear compose status=%d body=%#v", got.HTTPStatus, got.Body)
	}

	// Book composition stays with its Book owner.
	a128Stack(t, p, a, 140001001, 20)
	if got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 130001001, 1, op())); got.HTTPStatus != http.StatusOK {
		t.Fatalf("book compose status=%d body=%#v", got.HTTPStatus, got.Body)
	}

	// Furniture paper, activity skin dot and pet equipment recipes stay refused.
	for _, itemID := range []int64{50020001, 50001433, 80001024} {
		got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, itemID, 1, op()))
		if got.HTTPStatus != http.StatusConflict || got.Body["error_code"] != int64(35028) {
			t.Fatalf("item %d status=%d body=%#v", itemID, got.HTTPStatus, got.Body)
		}
		if got := a128Quantity(t, p, a, itemID); got != 0 {
			t.Fatalf("refused item %d granted: %d", itemID, got)
		}
	}
}
