//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strings"
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
	socialdomain "gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/operation"
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

type exchangeAward struct {
	TableID int64 `json:"table_id"`
	ItemNum int64 `json:"item_num"`
}
type exchangeReply struct {
	Awards  []exchangeAward  `json:"awards"`
	Economy map[string]int64 `json:"economy_"`
}

func decodeExchangeReply(t *testing.T, body map[string]any) exchangeReply {
	t.Helper()
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	var reply exchangeReply
	if err = json.Unmarshal(raw, &reply); err != nil {
		t.Fatal(err)
	}
	return reply
}

func expectedExchangeAwards(plan socialdomain.Plan, skip int64) []exchangeAward {
	awards := make([]exchangeAward, 0, len(plan.Items))
	for _, item := range plan.Items {
		if item.ItemID == skip {
			continue
		}
		awards = append(awards, exchangeAward{TableID: item.ItemID, ItemNum: item.ItemNum})
	}
	return awards
}

func exchangePlan(t *testing.T, catalog socialdomain.Catalog, productID, count int64, operation operation.Context) socialdomain.Plan {
	t.Helper()
	plan, err := socialdomain.BuildPlan(catalog, productID, count, operation)
	if err != nil {
		t.Fatal(err)
	}
	return plan
}

func exchangeDropboxItems(t *testing.T, catalog socialdomain.Catalog, productID int64) []int64 {
	t.Helper()
	dropboxID := int64(0)
	for _, product := range catalog.Products {
		if product.ID != productID {
			continue
		}
		for _, gift := range catalog.Gifts {
			if gift.ID == product.GiftID {
				dropboxID = gift.DropboxID
			}
		}
	}
	for _, dropbox := range catalog.Dropboxes {
		if dropbox.ID != dropboxID {
			continue
		}
		output := make([]int64, 0, len(dropbox.Rolls))
		for _, roll := range dropbox.Rolls {
			output = append(output, roll.ItemID)
		}
		return output
	}
	t.Fatal("product dropbox missing")
	return nil
}

func exchangeStackQuantity(t *testing.T, database *pg.Pool, player int64, itemID int64) int64 {
	t.Helper()
	var quantity int64
	if err := database.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, player, itemID).Scan(&quantity); err != nil {
		t.Fatal(err)
	}
	return quantity
}

func exchangeBalance(t *testing.T, database *pg.Pool, player int64) int64 {
	t.Helper()
	var amount int64
	if err := database.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='friendship_coin'`, player).Scan(&amount); err != nil {
		t.Fatal(err)
	}
	return amount
}

type failingExchangeSettings struct{}

func (failingExchangeSettings) TuningTx(ctx context.Context, query tx.Queryer) (json.RawMessage, error) {
	var value int64
	err := query.QueryRow(ctx, `SELECT nonexistent_tuning_column FROM social_exchange_tuning`).Scan(&value)
	return nil, err
}

func TestI910EExchangeAllSourceProductsDebitGrantReplayAndReload(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	exec(t, database, `DELETE FROM social_exchange_tuning`)
	catalog, err := (contentstore.Store{}).SocialExchangeCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	if len(catalog.Products) != 3 {
		t.Fatalf("source product count %d", len(catalog.Products))
	}
	service := exchangeService(database)
	for _, product := range catalog.Products {
		player := actor(t, database)
		operation := opPinned(revision)
		plan := exchangePlan(t, catalog, product.ID, 2, operation)
		paid := product.SellPrice * 2
		exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(player.PlayerID), paid)
		body, err := service.Exchange(ctx, player, exchange.Request{ProductID: product.ID, Count: 2}, operation)
		if err != nil {
			t.Fatal(product.ID, err)
		}
		reply := decodeExchangeReply(t, body)
		if remaining, found := reply.Economy[socialdomain.PriceCurrency]; !found || remaining != 0 || len(reply.Economy) != 1 {
			t.Fatal(product.ID, "economy", reply.Economy)
		}
		if expected := expectedExchangeAwards(plan, 0); !reflect.DeepEqual(reply.Awards, expected) {
			t.Fatal(product.ID, "awards", reply.Awards, expected)
		}
		if remaining := exchangeBalance(t, database, int64(player.PlayerID)); remaining != 0 {
			t.Fatal(product.ID, "balance", remaining)
		}
		for _, item := range plan.Items {
			if quantity := exchangeStackQuantity(t, database, int64(player.PlayerID), item.ItemID); quantity != item.ItemNum {
				t.Fatal(product.ID, item.ItemID, quantity, item.ItemNum)
			}
		}
		again, err := service.Exchange(ctx, player, exchange.Request{ProductID: product.ID, Count: 2}, operation)
		if err != nil || !reflect.DeepEqual(body, again) {
			t.Fatal(product.ID, "replay", err)
		}
		if remaining := exchangeBalance(t, database, int64(player.PlayerID)); remaining != 0 {
			t.Fatal(product.ID, "replay balance", remaining)
		}
		for _, item := range plan.Items {
			if quantity := exchangeStackQuantity(t, database, int64(player.PlayerID), item.ItemID); quantity != item.ItemNum {
				t.Fatal(product.ID, "replay stack", item.ItemID, quantity)
			}
		}
		var receipts int
		if err = database.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1 AND domain='socialexchange'`, fmt.Sprint(int64(player.PlayerID))).Scan(&receipts); err != nil || receipts != 1 {
			t.Fatal(product.ID, "replay receipts", receipts, err)
		}
	}
}

func TestI910EExchangeSourceMismatchOffAndTuningQualification(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	exec(t, database, `DELETE FROM social_exchange_tuning`)
	catalog, err := (contentstore.Store{}).SocialExchangeCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	product := catalog.Products[0]
	service := exchangeService(database)

	player := actor(t, database)
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(player.PlayerID), product.SellPrice)
	missing := strings.Repeat("d4", 32)
	if _, err = service.Exchange(ctx, player, exchange.Request{ProductID: product.ID, Count: 1}, opPinned(missing)); err == nil {
		t.Fatal("missing source revision purchased")
	}
	if exchangeBalance(t, database, int64(player.PlayerID)) != product.SellPrice {
		t.Fatal("missing source debited")
	}
	unknownPlayer := actor(t, database)
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(unknownPlayer.PlayerID), product.SellPrice)
	if _, err = service.Exchange(ctx, unknownPlayer, exchange.Request{ProductID: 9999, Count: 1}, opPinned(revision)); !errors.Is(err, socialdomain.ErrUnknownProduct) {
		t.Fatal("unknown product", err)
	}
	if exchangeBalance(t, database, int64(unknownPlayer.PlayerID)) != product.SellPrice {
		t.Fatal("unknown product debited")
	}

	offPlayer := actor(t, database)
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(offPlayer.PlayerID), product.SellPrice)
	exec(t, database, `INSERT INTO social_exchange_tuning(payload,updated_at)VALUES($1::jsonb,clock_timestamp())`, fmt.Sprintf(`{"version":1,"revision":"off","products":[{"id":%d,"off":true}]}`, product.ID))
	if _, err = service.Exchange(ctx, offPlayer, exchange.Request{ProductID: product.ID, Count: 1}, opPinned(revision)); !errors.Is(err, exchange.ErrProductOff) {
		t.Fatal("off", err)
	}
	if exchangeBalance(t, database, int64(offPlayer.PlayerID)) != product.SellPrice {
		t.Fatal("off debited")
	}
	exec(t, database, `DELETE FROM social_exchange_tuning`)

	failingPlayer := actor(t, database)
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(failingPlayer.PlayerID), product.SellPrice)
	failing := exchangeService(database)
	failing.Settings = failingExchangeSettings{}
	if _, err = failing.Exchange(ctx, failingPlayer, exchange.Request{ProductID: product.ID, Count: 1}, opPinned(revision)); err == nil {
		t.Fatal("tuning read failure swallowed")
	}
	if exchangeBalance(t, database, int64(failingPlayer.PlayerID)) != product.SellPrice {
		t.Fatal("tuning read failure debited")
	}
	var stacks int
	if err = database.QueryRow(ctx, `SELECT count(*) FROM player_item_stacks WHERE player_id=$1`, int64(failingPlayer.PlayerID)).Scan(&stacks); err != nil || stacks != 0 {
		t.Fatal("tuning read failure granted", stacks, err)
	}

	fallbackPlayer := actor(t, database)
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(fallbackPlayer.PlayerID), product.SellPrice)
	exec(t, database, `INSERT INTO social_exchange_tuning(payload,updated_at)VALUES($1::jsonb,clock_timestamp())`, fmt.Sprintf(`{"version":1,"revision":"dup","products":[{"id":%d,"price":120},{"id":%d,"price":120}]}`, product.ID, product.ID))
	fallbackOperation := opPinned(revision)
	fallbackBody, err := service.Exchange(ctx, fallbackPlayer, exchange.Request{ProductID: product.ID, Count: 1}, fallbackOperation)
	if err != nil {
		t.Fatal("fallback", err)
	}
	fallbackReply := decodeExchangeReply(t, fallbackBody)
	if remaining := fallbackReply.Economy[socialdomain.PriceCurrency]; remaining != 0 {
		t.Fatal("fallback price", fallbackReply.Economy)
	}
	if expected := expectedExchangeAwards(exchangePlan(t, catalog, product.ID, 1, fallbackOperation), 0); !reflect.DeepEqual(fallbackReply.Awards, expected) {
		t.Fatal("fallback awards", fallbackReply.Awards, expected)
	}
	exec(t, database, `DELETE FROM social_exchange_tuning`)

	tunedPlayer := actor(t, database)
	items := exchangeDropboxItems(t, catalog, product.ID)
	overrides := make([]map[string]any, 0, len(items))
	for _, itemID := range items {
		overrides = append(overrides, map[string]any{"item_id": itemID, "item_num": 2})
	}
	payload, err := json.Marshal(map[string]any{"version": 1, "revision": "tuned", "products": []any{map[string]any{"id": product.ID, "price": 120, "limit": 3, "items": overrides}}})
	if err != nil {
		t.Fatal(err)
	}
	exec(t, database, `INSERT INTO social_exchange_tuning(payload,updated_at)VALUES($1::jsonb,clock_timestamp())`, string(payload))
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(tunedPlayer.PlayerID), 360)
	tunedBody, err := service.Exchange(ctx, tunedPlayer, exchange.Request{ProductID: product.ID, Count: 3}, opPinned(revision))
	if err != nil {
		t.Fatal("tuned", err)
	}
	tunedReply := decodeExchangeReply(t, tunedBody)
	if remaining := tunedReply.Economy[socialdomain.PriceCurrency]; remaining != 0 {
		t.Fatal("tuned price", tunedReply.Economy)
	}
	total := int64(0)
	for _, award := range tunedReply.Awards {
		if award.ItemNum < 2 || award.ItemNum%2 != 0 {
			t.Fatal("tuned quantity", award)
		}
		total += award.ItemNum
	}
	if total != 6 {
		t.Fatal("tuned quantity total", total)
	}
	if _, err = service.Exchange(ctx, tunedPlayer, exchange.Request{ProductID: product.ID, Count: 4}, opPinned(revision)); !errors.Is(err, socialdomain.ErrCount) {
		t.Fatal("tuned limit", err)
	}
	if exchangeBalance(t, database, int64(tunedPlayer.PlayerID)) != 0 {
		t.Fatal("tuned limit debited")
	}
}

func TestI910EExchangeOverflowMailReportsOnlyDirectAwards(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	exec(t, database, `DELETE FROM social_exchange_tuning`)
	catalog, err := (contentstore.Store{}).SocialExchangeCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	product := catalog.Products[0]
	player := actor(t, database)
	operation := opPinned(revision)
	plan := exchangePlan(t, catalog, product.ID, 3, operation)
	chosen := plan.Items[0]
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'friendship_coin',$2,1,clock_timestamp()-interval '1 day')`, int64(player.PlayerID), product.SellPrice*3)
	exec(t, database, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,999,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, int64(player.PlayerID), chosen.ItemID)

	body, err := exchangeService(database).Exchange(ctx, player, exchange.Request{ProductID: product.ID, Count: 3}, operation)
	if err != nil {
		t.Fatal(err)
	}
	reply := decodeExchangeReply(t, body)
	if expected := expectedExchangeAwards(plan, chosen.ItemID); !reflect.DeepEqual(reply.Awards, expected) {
		t.Fatal("overflow reported as direct award", reply.Awards, expected)
	}
	if quantity := exchangeStackQuantity(t, database, int64(player.PlayerID), chosen.ItemID); quantity != 999 {
		t.Fatal("overflow stack", quantity)
	}
	var mails int
	if err = database.QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='GRANT_OVERFLOW'`, int64(player.PlayerID)).Scan(&mails); err != nil || mails != 1 {
		t.Fatal("overflow mail", mails, err)
	}
	var mailed int64
	if err = database.QueryRow(ctx, `SELECT COALESCE(SUM(a.amount),0) FROM mail_attachments a JOIN mail_records m ON m.mail_uuid=a.mail_uuid WHERE m.recipient_player_id=$1 AND m.source_kind='GRANT_OVERFLOW' AND a.item_id=$2`, int64(player.PlayerID), chosen.ItemID).Scan(&mailed); err != nil || mailed != chosen.ItemNum {
		t.Fatal("overflow mail amount", mailed, chosen.ItemNum, err)
	}
	if remaining := exchangeBalance(t, database, int64(player.PlayerID)); remaining != 0 {
		t.Fatal("overflow balance", remaining)
	}
}
