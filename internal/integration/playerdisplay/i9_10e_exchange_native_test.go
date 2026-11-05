//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"sync"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialexchangestore"
	generation "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	exchange "gxb.local/backend/v2/internal/application/socialexchange"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func exchangeService(database *pg.Pool) exchange.Service {
	store := i5store.Store{Queryer: database}
	content := contentstore.Store{Queryer: database}
	materials := i5.Service{Runner: tx.Runner{DB: database}, Store: store, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: store, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: database}, RedeemSecret: []byte("social191-native-test-key-000000000000")}
	return exchange.Service{Timed: generation.TimedRunner{Binder: generation.Binder{Time: pg.AuthoritativeTime{Queryer: database}}, Runner: tx.Runner{DB: database}}, Fence: store, Players: i4store.PlayerRootLocker{}, Content: content, Settings: socialexchangestore.Store{}, Materials: materials, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: database}}
}
func TestI910EExchangeAtomicReplayAndConcurrentPurchases(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := actor(t, database)
	exec(t, database, `DELETE FROM social_exchange_tuning`)
	catalog, err := (contentstore.Store{}).SocialExchangeCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	product := catalog.Products[0]
	price := product.SellPrice
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(player.PlayerID), price*2)
	service := exchangeService(database)
	operation := opPinned(revision)
	request := exchange.Request{ProductID: product.ID, Count: 1}
	first, err := service.Exchange(ctx, player, request, operation)
	if err != nil {
		t.Fatal(err)
	}
	exec(t, database, `INSERT INTO social_exchange_tuning(payload,updated_at)VALUES($1::jsonb,clock_timestamp())`, `{"version":1,"revision":"off","products":[{"id":1,"off":true}]}`)
	again, err := service.Exchange(ctx, player, request, operation)
	if err != nil || !reflect.DeepEqual(first, again) {
		t.Fatal("replay", first, again, err)
	}
	_, err = service.Exchange(ctx, player, request, opPinned(revision))
	if !errors.Is(err, exchange.ErrProductOff) {
		t.Fatal("off", err)
	}
	exec(t, database, `DELETE FROM social_exchange_tuning`)
	var wait sync.WaitGroup
	results := make(chan error, 2)
	for index := 0; index < 2; index++ {
		wait.Add(1)
		go func() {
			defer wait.Done()
			_, err := service.Exchange(ctx, player, request, opPinned(revision))
			results <- err
		}()
	}
	wait.Wait()
	close(results)
	success, refusal := 0, 0
	for err := range results {
		if err == nil {
			success++
		} else if errors.Is(err, economy.ErrInsufficientBalance) {
			refusal++
		} else {
			t.Fatal(err)
		}
	}
	if success != 1 || refusal != 1 {
		t.Fatal("overspend", success, refusal)
	}
	var remaining int64
	if err = database.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='friendship_coin'`, int64(player.PlayerID)).Scan(&remaining); err != nil || remaining != 0 {
		t.Fatal(remaining, err)
	}
	var count int
	if err = database.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1 AND domain='socialexchange'`, fmt.Sprint(int64(player.PlayerID))).Scan(&count); err != nil || count != 2 {
		t.Fatal("receipts", count, err)
	}
}

var _ receipt.Store = kernelstore.Store{}

type rejectedExchangeReceipt struct{ kernelstore.Store }

var receiptFailure = errors.New("injected outer receipt persistence failure")

func (rejectedExchangeReceipt) PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error) {
	return receipt.PutResult{}, receiptFailure
}
func TestI910EExchangeRollbackAndConcurrentSameOperation(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := actor(t, database)
	exec(t, database, `DELETE FROM social_exchange_tuning`)
	catalog, err := (contentstore.Store{}).SocialExchangeCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	price := catalog.Products[1].SellPrice
	request := exchange.Request{ProductID: catalog.Products[1].ID, Count: 1}
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(player.PlayerID), price)
	service := exchangeService(database)
	service.Receipts = rejectedExchangeReceipt{}
	if _, err = service.Exchange(ctx, player, request, opPinned(revision)); !errors.Is(err, receiptFailure) {
		t.Fatal("missing injected failure", err)
	}
	var remaining, stacks, receipts int64
	if err = database.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='friendship_coin'`, int64(player.PlayerID)).Scan(&remaining); err != nil || remaining != price {
		t.Fatal("debit not rolled back", remaining, err)
	}
	if err = database.QueryRow(ctx, `SELECT count(*) FROM player_item_stacks WHERE player_id=$1`, int64(player.PlayerID)).Scan(&stacks); err != nil || stacks != 0 {
		t.Fatal("grant not rolled back", stacks, err)
	}
	if err = database.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1`, fmt.Sprint(int64(player.PlayerID))).Scan(&receipts); err != nil || receipts != 0 {
		t.Fatal("inner receipt survived", receipts, err)
	}
	service.Receipts = kernelstore.Store{}
	operation := opPinned(revision)
	type response struct {
		body map[string]any
		err  error
	}
	results := make(chan response, 2)
	var wait sync.WaitGroup
	for index := 0; index < 2; index++ {
		wait.Add(1)
		go func() {
			defer wait.Done()
			body, err := service.Exchange(ctx, player, request, operation)
			results <- response{body, err}
		}()
	}
	wait.Wait()
	close(results)
	var first map[string]any
	for result := range results {
		if result.err != nil {
			t.Fatal(result.err)
		}
		if first == nil {
			first = result.body
		} else if !reflect.DeepEqual(first, result.body) {
			t.Fatal("same operation changed response", first, result.body)
		}
	}
	if err = database.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='friendship_coin'`, int64(player.PlayerID)).Scan(&remaining); err != nil || remaining != 0 {
		t.Fatal("replay debit", remaining, err)
	}
	if err = database.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1 AND domain='socialexchange'`, fmt.Sprint(int64(player.PlayerID))).Scan(&receipts); err != nil || receipts != 1 {
		t.Fatal("replay receipts", receipts, err)
	}
}

type exchangeCommitDatabase struct {
	tx.Beginner
	commit bool
	begins int
}

func (database *exchangeCommitDatabase) Begin(ctx context.Context, options tx.Options) (tx.Tx, error) {
	database.begins++
	transaction, err := database.Beginner.Begin(ctx, options)
	if err != nil {
		return nil, err
	}
	return faultTx{Tx: transaction, commit: database.commit}, nil
}
func TestI910EExchangeRealUnknownCommitPresenceAndAbsence(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	exec(t, database, `DELETE FROM social_exchange_tuning`)
	catalog, err := (contentstore.Store{}).SocialExchangeCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	product := catalog.Products[2]
	for _, committed := range []bool{true, false} {
		player := actor(t, database)
		exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(player.PlayerID), product.SellPrice)
		fault := &exchangeCommitDatabase{Beginner: database, commit: committed}
		service := exchangeService(database)
		service.Timed.Runner.DB = fault
		body, err := service.Exchange(ctx, player, exchange.Request{ProductID: product.ID, Count: 1}, opPinned(revision))
		var remaining int64
		if queryErr := database.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='friendship_coin'`, int64(player.PlayerID)).Scan(&remaining); queryErr != nil {
			t.Fatal(queryErr)
		}
		if committed {
			if err != nil || body == nil || remaining != 0 {
				t.Fatal("positive recovery", body, err, remaining)
			}
		} else {
			var unknown *tx.UnknownCommitError
			if !errors.As(err, &unknown) || body != nil || remaining != product.SellPrice {
				t.Fatal("absence replayed", body, err, remaining)
			}
		}
		if fault.begins != 1 {
			t.Fatal("ambiguous commit retried spend", fault.begins)
		}
	}
}
