//go:build postgres

package playerdisplay_test

import (
	"net/http"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func a128DormService(p *pg.Pool) appdorm.Service {
	content := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p, StackUsage: appdorm.FurnitureUsage{Owner: dormstore.Store{Queryer: p}, Content: content}}
	runner := tx.Runner{DB: p}
	exchanger := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("a128-furniture-native-fixture-secret-0")}
	return appdorm.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Reads: tx.Runner{DB: p}, Heroes: characterstore.LibraryHeroPort{Store: characterstore.Store{Queryer: p}}, Owner: dormstore.Store{Queryer: p}, Content: content, Players: i4store.PlayerRootLocker{}, Fence: values, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Values: values, Exchange: exchanger, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func a128FurnitureDispatcher(t *testing.T, p *pg.Pool, a identity.ActorContext) stockruntime.ComposeDispatcher {
	t.Helper()
	return stockruntime.ComposeDispatcher{Authority: fixedBookAuthority{actor: a}, Book: stockruntime.NewCoalescedBookRead(bookService(p, p)), Furniture: a128DormService(p), Awakening: a128HeroService(p), Equipment: a128HeroService(p)}
}

func a128Level(t *testing.T, p *pg.Pool, a identity.ActorContext, level int64) {
	t.Helper()
	exec(t, p, `UPDATE player_progression SET level=$2,updated_at=clock_timestamp()-interval '1 hour' WHERE player_id=$1`, int64(a.PlayerID), level)
}

func a128Glue(t *testing.T, p *pg.Pool, a identity.ActorContext) int64 {
	t.Helper()
	var amount int64
	if e := p.QueryRow(ctx, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='glue'),0)`, int64(a.PlayerID)).Scan(&amount); e != nil {
		t.Fatal(e)
	}
	return amount
}

func a128SetGlue(t *testing.T, p *pg.Pool, a identity.ActorContext, amount int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'glue',$2,1,clock_timestamp()-interval '1 day') ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=excluded.amount,updated_at=excluded.updated_at`, int64(a.PlayerID), amount)
}

func TestA128FurnitureComposeThroughProductionDispatcher(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	a128Level(t, p, a, 100)
	dispatcher := a128FurnitureDispatcher(t, p, a)

	a128Stack(t, p, a, 50010002, 300)
	a128Stack(t, p, a, 50010001, 300)
	a128Stack(t, p, a, 50020013, 1)
	a128SetGlue(t, p, a, 500)

	first := op()
	got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50031013, 2, first))
	if got.HTTPStatus != http.StatusOK {
		t.Fatalf("furniture compose status=%d body=%#v", got.HTTPStatus, got.Body)
	}
	if quantity := a128Quantity(t, p, a, 50031013); quantity != 2 {
		t.Fatalf("furniture granted=%d", quantity)
	}
	if quantity := a128Quantity(t, p, a, 50010002); quantity != 252 {
		t.Fatalf("material 50010002 after compose=%d", quantity)
	}
	if quantity := a128Quantity(t, p, a, 50010001); quantity != 240 {
		t.Fatalf("material 50010001 after compose=%d", quantity)
	}
	if glue := a128Glue(t, p, a); glue != 392 {
		t.Fatalf("glue after compose=%d", glue)
	}
	if quantity := a128Quantity(t, p, a, 50020013); quantity != 1 {
		t.Fatalf("blueprint was consumed: %d", quantity)
	}

	replay := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50031013, 2, first))
	if replay.HTTPStatus != http.StatusOK {
		t.Fatalf("replay status=%d body=%#v", replay.HTTPStatus, replay.Body)
	}
	if quantity := a128Quantity(t, p, a, 50031013); quantity != 2 {
		t.Fatalf("replay granted again: %d", quantity)
	}
	if glue := a128Glue(t, p, a); glue != 392 {
		t.Fatalf("replay debited glue again: %d", glue)
	}

	a128Stack(t, p, a, 50021013, 50)
	if got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50020013, 1, op())); got.HTTPStatus != http.StatusOK {
		t.Fatalf("blueprint compose status=%d body=%#v", got.HTTPStatus, got.Body)
	}
	if quantity := a128Quantity(t, p, a, 50020013); quantity != 2 {
		t.Fatalf("blueprint granted=%d", quantity)
	}
	if quantity := a128Quantity(t, p, a, 50021013); quantity != 0 {
		t.Fatalf("pieces after blueprint compose=%d", quantity)
	}
}

func TestA128FurnitureComposeRefusals(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	a128Level(t, p, a, 100)
	dispatcher := a128FurnitureDispatcher(t, p, a)
	a128Stack(t, p, a, 50010002, 300)
	a128Stack(t, p, a, 50010001, 300)

	refused := func(itemID, amount int64) {
		t.Helper()
		got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, itemID, amount, op()))
		if got.HTTPStatus != http.StatusConflict || got.Body["error_code"] != int64(35028) {
			t.Fatalf("item %d amount %d status=%d body=%#v", itemID, amount, got.HTTPStatus, got.Body)
		}
	}

	refused(999999, 1)
	refused(50031013, 1) // no blueprint owned
	a128Stack(t, p, a, 50020013, 1)
	a128Level(t, p, a, 1)
	refused(50031013, 1)
	a128Level(t, p, a, 100)
	a128Stack(t, p, a, 50010002, 0)
	refused(50031013, 1)
	if quantity := a128Quantity(t, p, a, 50031013); quantity != 0 {
		t.Fatalf("refused compose granted furniture: %d", quantity)
	}
	a128Stack(t, p, a, 50010002, 300)
	refused(50020013, 1) // no pieces owned
	a128SetGlue(t, p, a, 0)
	refused(50031013, 10) // glue exceeds the daily floor
	if glue := a128Glue(t, p, a); glue != 0 {
		t.Fatalf("refused compose changed glue: %d", glue)
	}
}
