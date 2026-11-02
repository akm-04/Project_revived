//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dodgeballstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/application/dodgeball"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialrelation"
	domain "gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"sync"
	"testing"
	"time"
)

func dodgeballMode(t *testing.T, pool *postgres.Pool, clock *workplaceTime) dodgeball.Mode {
	t.Helper()
	base := marchMode(t, pool)
	values, content := i5store.Store{Queryer: pool}, contentstore.Store{Queryer: pool}
	relations := socialrelationstore.Store{}
	mode := dodgeball.Mode{Timed: base.Timed, Fresh: pool, Store: dodgeballstore.Store{}, Content: content, Fence: values, Functions: values, Players: i4store.PlayerRootLocker{}, Privacy: socialrelation.FriendDMPrivacyProvider{Store: relations}, Friends: relations, Presentation: socialpresentation.TransactionReader{}, Combat: combatService(t, pool), Values: base.Grants, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Mail: values, Delivery: i5.SettlementMail{Store: values}, Receipts: base.Receipts, ReceiptRead: base.ReceiptRead}
	mode.Timed.Binder.Time = clock
	return mode
}

func dodgeballState(t *testing.T, pool *postgres.Pool, player identity.PlayerID) domain.State {
	t.Helper()
	state, present, err := (dodgeballstore.Store{}).ReadTx(ctx, pool, player)
	if err != nil || !present {
		t.Fatal("mode state", present, err)
	}
	return state
}

func dodgeballFriends(t *testing.T, pool *postgres.Pool, first, second identity.PlayerID, at time.Time) {
	t.Helper()
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	identifiers := []identity.PlayerID{first, second}
	sort.Slice(identifiers, func(left, right int) bool { return identifiers[left] < identifiers[right] })
	if _, err = (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, transaction, identity.LogicalServerID(int64(first)/100000), identifiers); err != nil {
		t.Fatal(err)
	}
	store := socialrelationstore.Store{}
	for _, identifier := range identifiers {
		if _, err = store.EnsureRootTx(ctx, transaction, identifier, at); err != nil {
			t.Fatal(err)
		}
	}
	relation := socialrelation.Friendship{PlayerLowID: identifiers[0], PlayerHighID: identifiers[1], Generation: 1, Active: true, ActivatedAt: at, StateVersion: 1, UpdatedAt: at}
	if err = store.PutFriendshipTx(ctx, transaction, nil, relation); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestI9_6BDodgeballNativeLifecycle(t *testing.T) {
	pool := pool(t)
	actor, revision := bornActor(t, pool), installed(t, pool)
	friend := bornActor(t, pool)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	mode := dodgeballMode(t, pool, clock)
	if _, err := mode.Info(ctx, actor, op()); !errors.Is(err, domain.ErrRefused) {
		t.Fatal("function gate", err)
	}
	compositeLevel(t, pool, actor, revision, 100)
	compositeLevel(t, pool, friend, revision, 100)
	grantGenuine(t, pool, actor, revision, "dodgeball tickets", []grant.Line{{Kind: grant.StackItem, ItemID: 50001979, Amount: 10}})
	if _, err := mode.Enter(ctx, actor, friend.PlayerID, op()); !errors.Is(err, domain.ErrRefused) {
		t.Fatal("nonfriend admitted", err)
	}
	dodgeballFriends(t, pool, actor.PlayerID, friend.PlayerID, clock.at.Add(-time.Minute))
	balance := func() int64 {
		var amount int64
		if err := pool.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001979`, int64(actor.PlayerID)).Scan(&amount); err != nil {
			t.Fatal(err)
		}
		return amount
	}
	enterOperation := op()
	entered, err := mode.Enter(ctx, actor, friend.PlayerID, enterOperation)
	if err != nil {
		t.Fatal("ENTER", err)
	}
	if balance() != 9 {
		t.Fatal("ticket not consumed", balance())
	}
	before, _ := json.Marshal(entered)
	replay, err := mode.Enter(ctx, actor, friend.PlayerID, enterOperation)
	after, _ := json.Marshal(replay)
	if err != nil || string(before) != string(after) || balance() != 9 {
		t.Fatal("exact ENTER", err, replay)
	}
	state := dodgeballState(t, pool, actor.PlayerID)
	if state.Pending == nil || state.Sequence != 1 || dodgeballState(t, pool, friend.PlayerID).Incoming != 1 {
		t.Fatal(state)
	}
	info, err := mode.Info(ctx, actor, op())
	if err != nil || len(info["friend_infos"].([]map[string]any)) != 1 {
		t.Fatal("real friend projection", info, err)
	}
	friendRow := info["friend_infos"].([]map[string]any)[0]
	if friendRow["is_invited"] != int64(1) {
		t.Fatal("source numeric invitation flag", friendRow)
	}
	if _, present := friendRow["player_info"].(map[string]any)["conquer_lev"]; !present {
		t.Fatal("source conquer field", friendRow)
	}
	marked := state.Pending.Board.Marked[0]
	if _, err = mode.Start(ctx, actor, marked, op()); err != nil {
		t.Fatal("START", err)
	}
	started := dodgeballState(t, pool, actor.PlayerID)
	stable, _ := json.Marshal(started.Pending.Draws)
	if _, err = mode.Start(ctx, actor, marked, op()); err != nil {
		t.Fatal("lost START", err)
	}
	repeated, _ := json.Marshal(dodgeballState(t, pool, actor.PlayerID).Pending.Draws)
	if string(stable) != string(repeated) {
		t.Fatal("entropy changed")
	}
	if _, err = mode.Start(ctx, actor, state.Pending.Board.Marked[1], op()); !errors.Is(err, domain.ErrRefused) {
		t.Fatal("changed selection", err)
	}
	catalog, err := mode.Content.DodgeballCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	occurrence, throw := int64(0), int64(0)
	for index, identifier := range started.Pending.Board.Monsters {
		target, _ := catalog.Target(identifier)
		probability := target.Probability * 10
		for drawIndex, draw := range started.Pending.Draws.Streams["self"] {
			if drawIndex > 100 {
				break
			}
			if draw <= probability && started.Pending.Draws.Streams["friend"][drawIndex] <= catalog.FriendProbability {
				occurrence, throw = int64(index+1), int64(drawIndex+1)
				break
			}
		}
		if occurrence > 0 {
			break
		}
	}
	if occurrence == 0 {
		t.Fatal("no valid assisted target in frozen draws")
	}
	records := []domain.HitRecord{{Throw: throw, Occurrence: occurrence, Hits: 10}}
	invalid := append(records, records[0])
	if _, err = mode.Result(ctx, actor, invalid, op()); !errors.Is(err, domain.ErrRefused) {
		t.Fatal("duplicate occurrence", err)
	}
	target, _ := catalog.Target(started.Pending.Board.Monsters[occurrence-1])
	amount := target.Amount
	if target.ID == marked {
		amount *= catalog.MarkedMultiplier
	}
	var previous int64
	if err = pool.QueryRow(ctx, `SELECT COALESCE(sum(quantity),0) FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(actor.PlayerID), target.ItemID).Scan(&previous); err != nil {
		t.Fatal(err)
	}
	errorsChannel := make(chan error, 2)
	var waiting sync.WaitGroup
	for attempt := 0; attempt < 2; attempt++ {
		waiting.Add(1)
		go func() { defer waiting.Done(); _, err := mode.Result(ctx, actor, records, op()); errorsChannel <- err }()
	}
	waiting.Wait()
	close(errorsChannel)
	for err := range errorsChannel {
		if err != nil {
			t.Fatal("concurrent RESULT", err)
		}
	}
	var awarded, mailCount int64
	if err = pool.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(actor.PlayerID), target.ItemID).Scan(&awarded); err != nil || awarded != previous+amount {
		t.Fatal("once-only actor reward", awarded, previous, amount, err)
	}
	if err = pool.QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='DODGEBALL_FRIEND' AND source_key=$2`, int64(friend.PlayerID), started.Pending.Identity).Scan(&mailCount); err != nil || mailCount != 1 {
		t.Fatal("friend mail", mailCount, err)
	}
	if replay, retryError := mode.Result(ctx, actor, records, op()); retryError != nil || fmt.Sprint(replay["error_code"]) != "30005" {
		t.Fatal("terminal semantic retry", replay, retryError)
	}
	if balance() != 9 {
		t.Fatal("RESULT recharged ticket")
	}
	// Reverse player-ID order exercises the other canonical lock order.
	grantGenuine(t, pool, friend, revision, "reverse tickets", []grant.Line{{Kind: grant.StackItem, ItemID: 50001979, Amount: 1}})
	if _, err = mode.Enter(ctx, friend, actor.PlayerID, op()); err != nil {
		t.Fatal("reverse invitation", err)
	}
	for invitation := 0; invitation < 2; invitation++ {
		if _, err = mode.Enter(ctx, actor, friend.PlayerID, op()); err != nil {
			t.Fatal("remaining invitation", err)
		}
	}
	if _, err = mode.Enter(ctx, actor, friend.PlayerID, op()); !errors.Is(err, domain.ErrRefused) || balance() != 7 {
		t.Fatal("incoming cap/ticket rollback", balance(), err)
	}
	clock.at = modes.DayBegins(modes.Day(clock.at) + 1).Add(time.Minute)
	if _, err = mode.Enter(ctx, actor, friend.PlayerID, op()); err != nil {
		t.Fatal("next-day admission", err)
	}
	state = dodgeballState(t, pool, actor.PlayerID)
	if state.Sequence != 4 || state.Played != 1 || dodgeballState(t, pool, friend.PlayerID).Incoming != 1 {
		t.Fatal("day reset lost sequence", state)
	}
	if _, err = mode.Start(ctx, actor, state.Pending.Board.Marked[0], op()); err != nil {
		t.Fatal(err)
	}
	clock.at = clock.at.Add(61 * time.Minute)
	if _, err = mode.Result(ctx, actor, []domain.HitRecord{}, op()); !errors.Is(err, domain.ErrRefused) {
		t.Fatal("expired result", err)
	}
	if _, err = mode.Enter(ctx, actor, 0, op()); err != nil {
		t.Fatal("replace expired game", err)
	}
	state = dodgeballState(t, pool, actor.PlayerID)
	if _, err = mode.Start(ctx, actor, state.Pending.Board.Marked[0], op()); err != nil {
		t.Fatal(err)
	}
	if _, err = mode.Result(ctx, actor, []domain.HitRecord{}, op()); err != nil {
		t.Fatal("empty RESULT", err)
	}
	if dodgeballState(t, pool, actor.PlayerID).Pending != nil {
		t.Fatal("empty game remained open")
	}
	var resolved int64
	if err = pool.QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE actor_player_id=$1 AND resolver_status<>'NOT_REQUIRED'`, int64(actor.PlayerID)).Scan(&resolved); err != nil || resolved != 0 {
		t.Fatal("minigame used simulation", resolved, err)
	}
	t.Log(fmt.Sprintf("game=%s target=%d awards=%d incoming cap=3", started.Pending.Identity, target.ID, amount))
}

func TestI9_6BDodgeballNativeGlobalQuotaAndRejectedEntropy(t *testing.T) {
	pool := pool(t)
	revision := installed(t, pool)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	mode := dodgeballMode(t, pool, clock)
	recipient := bornActor(t, pool)
	compositeLevel(t, pool, recipient, revision, 100)
	actors := []identity.ActorContext{}
	for index := 0; index < 4; index++ {
		actor := bornActor(t, pool)
		compositeLevel(t, pool, actor, revision, 100)
		grantGenuine(t, pool, actor, revision, "quota ticket", []grant.Line{{Kind: grant.StackItem, ItemID: 50001979, Amount: 2}})
		dodgeballFriends(t, pool, actor.PlayerID, recipient.PlayerID, clock.at.Add(-time.Minute))
		actors = append(actors, actor)
	}
	results := make(chan error, 4)
	var waiting sync.WaitGroup
	for _, actor := range actors {
		waiting.Add(1)
		go func(actor identity.ActorContext) {
			defer waiting.Done()
			_, err := mode.Enter(ctx, actor, recipient.PlayerID, op())
			results <- err
		}(actor)
	}
	waiting.Wait()
	close(results)
	admitted, refused := 0, 0
	for err := range results {
		if err == nil {
			admitted++
			continue
		}
		if !errors.Is(err, domain.ErrRefused) {
			t.Fatal("concurrent global quota", err)
		}
		refused++
	}
	if admitted != 3 || refused != 1 || dodgeballState(t, pool, recipient.PlayerID).Incoming != 3 {
		t.Fatal("quota over-admission", admitted, refused)
	}
	actor := actors[0]
	if _, err := mode.Enter(ctx, actor, 0, op()); err != nil {
		t.Fatal(err)
	}
	state := dodgeballState(t, pool, actor.PlayerID)
	if _, err := mode.Start(ctx, actor, state.Pending.Board.Marked[0], op()); err != nil {
		t.Fatal(err)
	}
	state = dodgeballState(t, pool, actor.PlayerID)
	catalog, err := mode.Content.DodgeballCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	var records []domain.HitRecord
	for index, identifier := range state.Pending.Board.Monsters {
		target, _ := catalog.Target(identifier)
		for throw, draw := range state.Pending.Draws.Streams["self"] {
			if throw >= 100 {
				break
			}
			if draw > target.Probability {
				records = []domain.HitRecord{{Throw: int64(throw + 1), Occurrence: int64(index + 1), Hits: 1}}
				break
			}
		}
		if len(records) > 0 {
			break
		}
	}
	if len(records) == 0 {
		t.Fatal("no negative entropy witness")
	}
	var beforeReward int64
	if err = pool.QueryRow(ctx, `SELECT COALESCE(sum(quantity),0) FROM player_item_stacks WHERE player_id=$1`, int64(actor.PlayerID)).Scan(&beforeReward); err != nil {
		t.Fatal(err)
	}
	response, err := mode.Result(ctx, actor, records, op())
	if err != nil || fmt.Sprint(response["error_code"]) != "30005" {
		t.Fatal("unearned entropy reward accepted", response, err)
	}
	if dodgeballState(t, pool, actor.PlayerID).Pending != nil {
		t.Fatal("rejected attempt not closed")
	}
	var afterReward int64
	if err = pool.QueryRow(ctx, `SELECT COALESCE(sum(quantity),0) FROM player_item_stacks WHERE player_id=$1`, int64(actor.PlayerID)).Scan(&afterReward); err != nil || afterReward != beforeReward {
		t.Fatal("rejected claim rewarded", afterReward, beforeReward, err)
	}
}
