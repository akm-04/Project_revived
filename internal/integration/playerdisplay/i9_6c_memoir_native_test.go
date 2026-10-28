//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/memoirstore"
	applicationcombat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/i5"
	application "gxb.local/backend/v2/internal/application/memoir"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"sync"
	"testing"
	"time"
)

func memoirMode(t *testing.T, pool *postgres.Pool, clock *workplaceTime) application.Mode {
	t.Helper()
	base := marchMode(t, pool)
	fight := combatService(t, pool)
	owner := base.Grants.(i5.Service)
	mode := application.Mode{Timed: base.Timed, Fresh: pool, Store: memoirstore.Store{}, Content: contentstore.Store{Queryer: pool}, Fence: base.Fence, Functions: base.Functions, Heroes: base.Heroes, HeroLocks: base.HeroLocks, Roster: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Opponents: base.Opponents, Combat: fight, Grants: owner, Costs: base.Costs, Energy: owner, Exchange: owner, Receipts: base.Receipts, ReceiptRead: base.ReceiptRead}
	mode.Timed.Binder.Time = clock
	return mode
}
func memoirRecord(t *testing.T, pool *postgres.Pool, actor identity.ActorContext) memoir.State {
	t.Helper()
	state, present, err := (memoirstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if err != nil || !present {
		t.Fatal(present, err)
	}
	return state
}
func memoirWin(t *testing.T, mode application.Mode, state memoir.State, actor identity.ActorContext, position int, partner int64) application.MonsterResult {
	t.Helper()
	kind := state.Board.Cells[position-1]
	fight := state.Board.Enemies[position]
	catalog, err := mode.Content.MemoirCatalogTx(ctx, mode.Fresh, state.Revision)
	if err != nil {
		t.Fatal(err)
	}
	if kind == memoir.Guardian {
		fight = catalog.BossBattle(fight)
	}
	waves := catalog.Fights[fight]
	if len(waves) == 0 {
		t.Fatal("no waves")
	}
	enemies := []combat.ActorStatus{}
	seen := map[int64]bool{}
	for _, identifier := range waves[len(waves)-1] {
		if !seen[identifier] {
			enemies = append(enemies, combat.ActorStatus{Identity: identifier, HP: 0, MP: 300})
			seen[identifier] = true
		}
	}
	return application.MonsterResult{Grid: position, Report: combat.Report{Win: true, Formation: []int64{partner}, Round: len(waves), Allies: []combat.ActorStatus{{Player: int64(actor.PlayerID), Identity: partner, HP: 1, MP: 500}}, Enemies: enemies}}
}
func TestI9_6CMemoirNativeLifecycle(t *testing.T) {
	pool := pool(t)
	actor, revision := bornActor(t, pool), installed(t, pool)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	mode := memoirMode(t, pool, clock)
	if _, err := mode.Info(ctx, actor, op()); !errors.Is(err, memoir.ErrRefused) {
		t.Fatal("gate", err)
	}
	compositeLevel(t, pool, actor, revision, 100)
	bornHero(t, pool, actor, revision, 10001001, 1)
	grantGenuine(t, pool, actor, revision, "memoir keys", []grant.Line{{Kind: grant.StackItem, ItemID: 50001400, Amount: 3}, {Kind: grant.StackItem, ItemID: 50001401, Amount: 8}})
	if _, err := mode.Start(ctx, actor, 1, op()); !errors.Is(err, memoir.ErrInvalid) {
		t.Fatal("invalid girl", err)
	}
	catalog, err := mode.Content.MemoirCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	start := op()
	first, err := mode.Start(ctx, actor, catalog.Selected[0], start)
	if err != nil {
		t.Fatal("start", err)
	}
	repeated, err := mode.Start(ctx, actor, catalog.Selected[0], start)
	left, _ := combat.CanonicalJSON(first)
	right, _ := combat.CanonicalJSON(repeated)
	if err != nil || string(left) != string(right) {
		t.Fatal("start replay", err)
	}
	state := memoirRecord(t, pool, actor)
	if state.Board.CanExit(memoir.FinalPosition) || len(state.Opponents) == 0 {
		t.Fatal("map", state)
	}
	if _, err = mode.NextFloor(ctx, actor, memoir.FinalPosition, op()); !errors.Is(err, memoir.ErrRefused) {
		t.Fatal("guardian bypass", err)
	}
	if _, err = mode.SaveMap(ctx, actor, memoir.FinalPosition, []int{memoir.FinalPosition}, op()); !errors.Is(err, memoir.ErrRefused) {
		t.Fatal("teleport", err)
	}
	saveOperation := op()
	saved, err := mode.SaveMap(ctx, actor, 10, []int{1, 2, 10, 11, 19}, saveOperation)
	if err != nil {
		t.Fatal("save movement", err)
	}
	savedAgain, err := mode.SaveMap(ctx, actor, 10, []int{1, 2, 10, 11, 19}, saveOperation)
	savedRaw, _ := combat.CanonicalJSON(saved)
	savedReplay, _ := combat.CanonicalJSON(savedAgain)
	if err != nil || string(savedRaw) != string(savedReplay) || memoirRecord(t, pool, actor).Board.Position != 10 {
		t.Fatal("save retry", err)
	}
	for index, kind := range state.Board.Cells {
		if kind != memoir.SmallBox {
			continue
		}
		boxOperation := op()
		opened, err := mode.OpenBox(ctx, actor, index+1, boxOperation)
		if err != nil {
			t.Fatal("small box", err)
		}
		replay, err := mode.OpenBox(ctx, actor, index+1, boxOperation)
		first, _ := combat.CanonicalJSON(opened)
		second, _ := combat.CanonicalJSON(replay)
		if err != nil || string(first) != string(second) {
			t.Fatal("box exact retry", err)
		}
		var remaining int64
		if err = pool.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001401`, int64(actor.PlayerID)).Scan(&remaining); err != nil || remaining != 7 {
			t.Fatal("box retry charged twice", remaining, err)
		}
		break
	}
	for index, kind := range state.Board.Cells {
		if kind != memoir.BigBox {
			continue
		}
		errorsChannel := make(chan error, 2)
		var waiting sync.WaitGroup
		for attempt := 0; attempt < 2; attempt++ {
			waiting.Add(1)
			go func() { defer waiting.Done(); _, err := mode.OpenBox(ctx, actor, index+1, op()); errorsChannel <- err }()
		}
		waiting.Wait()
		close(errorsChannel)
		successes := 0
		for err := range errorsChannel {
			if err == nil {
				successes++
			} else if !errors.Is(err, memoir.ErrRefused) {
				t.Fatal("box concurrency", err)
			}
		}
		if successes != 1 {
			t.Fatal("box settled twice", successes)
		}
	}
	energy := func() int64 {
		var amount int64
		if err := pool.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`, int64(actor.PlayerID)).Scan(&amount); err != nil {
			t.Fatal(err)
		}
		return amount
	}
	for floor := 1; floor <= 3; floor++ {
		exec(t, pool, `UPDATE player_temporal_resources SET stored_amount=1000,regen_anchor_at=NULL WHERE player_id=$1 AND resource_key='energy'`, int64(actor.PlayerID))
		fightOperation := op()
		startedReply, err := mode.StartFight(ctx, actor, memoir.GuardianPosition, fightOperation)
		if err != nil {
			t.Fatal("fight start", floor, err)
		}
		replayedStart, err := mode.StartFight(ctx, actor, memoir.GuardianPosition, fightOperation)
		firstStart, _ := combat.CanonicalJSON(startedReply)
		secondStart, _ := combat.CanonicalJSON(replayedStart)
		if err != nil || string(firstStart) != string(secondStart) {
			t.Fatal("START exact retry", err)
		}
		state = memoirRecord(t, pool, actor)
		pending := *state.Pending
		balance := energy()
		if _, err = mode.StartFight(ctx, actor, memoir.GuardianPosition, op()); err != nil || energy() != balance {
			t.Fatal("paid retry", err)
		}
		if memoirRecord(t, pool, actor).Pending.Attempt != pending.Attempt {
			t.Fatal("attempt changed")
		}
		claim := memoirWin(t, mode, state, actor, memoir.GuardianPosition, 1)
		resultOperation := op()
		var result map[string]any
		if floor == 1 {
			type terminalReply struct {
				response  map[string]any
				operation operation.Context
				err       error
			}
			replies := make(chan terminalReply, 2)
			for attempt := 0; attempt < 2; attempt++ {
				go func() {
					operationContext := op()
					response, err := mode.MonsterResult(ctx, actor, claim, operationContext)
					replies <- terminalReply{response, operationContext, err}
				}()
			}
			accepted, duplicates := 0, 0
			for attempt := 0; attempt < 2; attempt++ {
				reply := <-replies
				if reply.err != nil {
					t.Fatal("concurrent terminal", reply.err)
				}
				if reply.response["error_code"] == nil {
					accepted++
					result, resultOperation = reply.response, reply.operation
				} else if reply.response["error_code"] == int64(combat.FightExistCode) {
					duplicates++
				} else {
					t.Fatal(reply.response)
				}
			}
			if accepted != 1 || duplicates != 1 {
				t.Fatal("terminal settled more than once", accepted, duplicates)
			}
		} else {
			result, err = mode.MonsterResult(ctx, actor, claim, resultOperation)
		}
		if err != nil || result["error_code"] != nil {
			t.Fatal("result", floor, result, err)
		}
		repeated, err := mode.MonsterResult(ctx, actor, claim, resultOperation)
		left, _ = combat.CanonicalJSON(result)
		right, _ = combat.CanonicalJSON(repeated)
		if err != nil || string(left) != string(right) {
			t.Fatal("exact result", err, string(left), string(right))
		}
		duplicate, err := mode.MonsterResult(ctx, actor, claim, op())
		if err != nil || duplicate["error_code"] != int64(combat.FightExistCode) {
			t.Fatal("duplicate", duplicate, err)
		}
		state = memoirRecord(t, pool, actor)
		if state.Pending != nil || state.Heroes[1].HP != 1 || state.MaxFloor[state.Girl] != floor || !state.Board.GuardianWon {
			t.Fatal("carry/progress", state)
		}
		if floor < 3 {
			nextOperation := op()
			first, err := mode.NextFloor(ctx, actor, memoir.FinalPosition, nextOperation)
			if err != nil {
				t.Fatal("next floor", err)
			}
			repeated, err := mode.NextFloor(ctx, actor, memoir.FinalPosition, nextOperation)
			left, _ := combat.CanonicalJSON(first)
			right, _ := combat.CanonicalJSON(repeated)
			if err != nil || string(left) != string(right) || memoirRecord(t, pool, actor).Floor != floor+1 {
				t.Fatal("next floor retry", err)
			}
		}
	}
	finalOperation := op()
	final, err := mode.FinalAward(ctx, actor, memoir.FinalPosition, catalog.FinalGifts[0], finalOperation)
	if err != nil {
		t.Fatal("final", err)
	}
	finalAgain, err := mode.FinalAward(ctx, actor, memoir.FinalPosition, catalog.FinalGifts[0], finalOperation)
	finalRaw, _ := combat.CanonicalJSON(final)
	finalReplay, _ := combat.CanonicalJSON(finalAgain)
	if err != nil || string(finalRaw) != string(finalReplay) {
		t.Fatal("final retry", err)
	}
	if memoirRecord(t, pool, actor).Active() {
		t.Fatal("run did not end")
	}
	if _, err = mode.FinalAward(ctx, actor, memoir.FinalPosition, catalog.FinalGifts[0], op()); !errors.Is(err, memoir.ErrRefused) {
		t.Fatal("repeat final", err)
	}
	if _, err = mode.Start(ctx, actor, catalog.Selected[0], op()); err != nil {
		t.Fatal("unlimited reentry", err)
	}
	state = memoirRecord(t, pool, actor)
	if state.MaxFloor[state.Girl] != 3 {
		t.Fatal("lifetime maximum lost")
	}
	if _, err = mode.StartFight(ctx, actor, memoir.GuardianPosition, op()); err != nil {
		t.Fatal("withdraw start", err)
	}
	if _, err = mode.Abandon(ctx, actor, op()); err != nil {
		t.Fatal("withdraw", err)
	}
	if memoirRecord(t, pool, actor).Active() {
		t.Fatal("abandon")
	}
}

func TestI9_6CMemoirNativeRejectedLossReviveAndDeadline(t *testing.T) {
	pool := pool(t)
	actor, revision := bornActor(t, pool), installed(t, pool)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	mode := memoirMode(t, pool, clock)
	compositeLevel(t, pool, actor, revision, 100)
	bornHero(t, pool, actor, revision, 10001001, 1)
	grantGenuine(t, pool, actor, revision, "memoir revive", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 1000}})
	catalog, err := mode.Content.MemoirCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = mode.Start(ctx, actor, catalog.Selected[0], op()); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `UPDATE player_temporal_resources SET stored_amount=0,regen_anchor_at=$2 WHERE player_id=$1 AND resource_key='energy'`, int64(actor.PlayerID), clock.at)
	if _, err = mode.StartFight(ctx, actor, memoir.GuardianPosition, op()); !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatal("insufficient energy", err)
	}
	if memoirRecord(t, pool, actor).Pending != nil {
		t.Fatal("failed admission wrote pending")
	}
	exec(t, pool, `UPDATE player_temporal_resources SET stored_amount=1000,regen_anchor_at=NULL WHERE player_id=$1 AND resource_key='energy'`, int64(actor.PlayerID))
	if _, err = mode.StartFight(ctx, actor, memoir.GuardianPosition, op()); err != nil {
		t.Fatal(err)
	}
	state := memoirRecord(t, pool, actor)
	claim := memoirWin(t, mode, state, actor, memoir.GuardianPosition, 1)
	claim.Report.Win = false
	claim.Report.Allies[0].HP = 0
	for index := range claim.Report.Enemies {
		claim.Report.Enemies[index].HP = 1
	}
	result, err := mode.MonsterResult(ctx, actor, claim, op())
	if err != nil || result["error_code"] != nil {
		t.Fatal("loss", result, err)
	}
	state = memoirRecord(t, pool, actor)
	if state.Alive(1) || state.Board.GuardianWon || len(state.Drops) != 0 {
		t.Fatal("loss applied rewards or lost death")
	}
	if _, err = mode.StartFight(ctx, actor, memoir.GuardianPosition, op()); !errors.Is(err, memoir.ErrRefused) {
		t.Fatal("dead hero admitted", err)
	}
	if _, err = mode.Revive(ctx, actor, 999, op()); !errors.Is(err, memoir.ErrRefused) {
		t.Fatal("foreign revive", err)
	}
	reviveOperation := op()
	revived, err := mode.Revive(ctx, actor, 1, reviveOperation)
	if err != nil {
		t.Fatal("revive", err)
	}
	repeatedRevive, err := mode.Revive(ctx, actor, 1, reviveOperation)
	revivedRaw, _ := combat.CanonicalJSON(revived)
	revivedReplay, _ := combat.CanonicalJSON(repeatedRevive)
	if err != nil || string(revivedRaw) != string(revivedReplay) {
		t.Fatal("revive retry", err)
	}
	state = memoirRecord(t, pool, actor)
	if !state.Alive(1) || state.ReviveTimes != 1 {
		t.Fatal("revive carry")
	}
	if _, err = mode.Revive(ctx, actor, 1, op()); !errors.Is(err, memoir.ErrRefused) {
		t.Fatal("second revive", err)
	}
	if _, err = mode.StartFight(ctx, actor, memoir.GuardianPosition, op()); err != nil {
		t.Fatal(err)
	}
	state = memoirRecord(t, pool, actor)
	bornHero(t, pool, actor, revision, 10001002, 2)
	claim = memoirWin(t, mode, state, actor, memoir.GuardianPosition, 2)
	result, err = mode.MonsterResult(ctx, actor, claim, op())
	if err != nil || result["error_code"] != int64(combat.FightExistCode) {
		t.Fatal("unfrozen hero", result, err)
	}
	if memoirRecord(t, pool, actor).Pending != nil || memoirRecord(t, pool, actor).Board.GuardianWon {
		t.Fatal("rejection did not close")
	}
	if _, err = mode.StartFight(ctx, actor, memoir.GuardianPosition, op()); err != nil {
		t.Fatal(err)
	}
	state = memoirRecord(t, pool, actor)
	clock.at = clock.at.Add(2 * time.Hour)
	claim = memoirWin(t, mode, state, actor, memoir.GuardianPosition, 1)
	result, err = mode.MonsterResult(ctx, actor, claim, op())
	if err != nil || result["error_code"] != int64(combat.FightExistCode) || memoirRecord(t, pool, actor).Pending != nil {
		t.Fatal("late report", result, err)
	}
}
func TestI9_6CMemoirNativePlayerServerResolution(t *testing.T) {
	pool := pool(t)
	actor, revision := bornActor(t, pool), installed(t, pool)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	mode := memoirMode(t, pool, clock)
	compositeLevel(t, pool, actor, revision, 100)
	bornHero(t, pool, actor, revision, 10001001, 1)
	catalog, err := mode.Content.MemoirCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = mode.Start(ctx, actor, catalog.Selected[0], op()); err != nil {
		t.Fatal(err)
	}
	state := memoirRecord(t, pool, actor)
	grid := 0
	for index, kind := range state.Board.Cells {
		if kind == memoir.Player {
			grid = index + 1
			break
		}
	}
	if grid == 0 {
		t.Fatal("no player encounter")
	}
	before, err := combat.CanonicalJSON(state.Opponents)
	if err != nil {
		t.Fatal(err)
	}
	request := application.PlayerFight{Grid: grid, Formation: []int64{1}}
	fightOperation := op()
	response, err := mode.PlayerFight(ctx, actor, request, fightOperation)
	if err != nil {
		t.Fatal("server battle", err)
	}
	battle, present := response["battle_info"].(map[string]any)
	if !present || battle["battle_report"] == "" {
		t.Fatal(response)
	}
	after := memoirRecord(t, pool, actor)
	copied, err := combat.CanonicalJSON(after.Opponents)
	if err != nil || string(before) != string(copied) {
		t.Fatal("frozen opponent mutated", err)
	}
	if after.Pending != nil || len(after.Heroes) != 1 || after.Heroes[1].Identity != 1 {
		t.Fatal("server carry missing", after)
	}
	repeated, err := mode.PlayerFight(ctx, actor, request, fightOperation)
	if err != nil {
		t.Fatal("server replay", err)
	}
	left, _ := combat.CanonicalJSON(response)
	right, _ := combat.CanonicalJSON(repeated)
	if string(left) != string(right) {
		t.Fatal("server replay changed")
	}
	if _, err = mode.Abandon(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}
	repeated, err = mode.PlayerFight(ctx, actor, request, fightOperation)
	right, _ = combat.CanonicalJSON(repeated)
	if err != nil || string(left) != string(right) {
		t.Fatal("old operation lost after abandon", err)
	}
}

type interruptedMemoirCombat struct {
	application.Combat
	interrupt bool
}

func (owner *interruptedMemoirCombat) Resolve(ctx context.Context, operationContext operation.Context, attempt ids.UUID) (applicationcombat.Resolved, error) {
	if owner.interrupt {
		owner.interrupt = false
		return applicationcombat.Resolved{}, combat.ErrResolverRetryable
	}
	return owner.Combat.Resolve(ctx, operationContext, attempt)
}
func TestI9_6CMemoirNativePlayerRecoveryAfterAdmission(t *testing.T) {
	pool := pool(t)
	actor, revision := bornActor(t, pool), installed(t, pool)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	mode := memoirMode(t, pool, clock)
	compositeLevel(t, pool, actor, revision, 100)
	bornHero(t, pool, actor, revision, 10001001, 1)
	catalog, err := mode.Content.MemoirCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = mode.Start(ctx, actor, catalog.Selected[0], op()); err != nil {
		t.Fatal(err)
	}
	state := memoirRecord(t, pool, actor)
	grid := 0
	for index, kind := range state.Board.Cells {
		if kind == memoir.Player {
			grid = index + 1
			break
		}
	}
	mode.Combat = &interruptedMemoirCombat{Combat: mode.Combat, interrupt: true}
	request := application.PlayerFight{Grid: grid, Formation: []int64{1}}
	fightOperation := op()
	if _, err = mode.PlayerFight(ctx, actor, request, fightOperation); !errors.Is(err, combat.ErrResolverRetryable) {
		t.Fatal("injected resolver interruption", err)
	}
	pending := memoirRecord(t, pool, actor).Pending
	if pending == nil {
		t.Fatal("admission not durable")
	}
	var before int64
	if err = pool.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`, int64(actor.PlayerID)).Scan(&before); err != nil {
		t.Fatal(err)
	}
	if _, err = mode.Info(ctx, actor, op()); err != nil {
		t.Fatal("resume via INFO", err)
	}
	state = memoirRecord(t, pool, actor)
	if state.Pending != nil || len(state.Heroes) != 1 {
		t.Fatal("resume lost terminal state")
	}
	var after int64
	if err = pool.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`, int64(actor.PlayerID)).Scan(&after); err != nil || before != after {
		t.Fatal("recovery charged twice", before, after, err)
	}
	replay, err := mode.PlayerFight(ctx, actor, request, fightOperation)
	if err != nil || replay["battle_info"] == nil {
		t.Fatal("original START did not find INFO settlement", err, replay)
	}
	if !state.Alive(1) {
		grantGenuine(t, pool, actor, revision, "memoir retry revive", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 500}})
		if _, err = mode.Revive(ctx, actor, 1, op()); err != nil {
			t.Fatal(err)
		}
	}
	// A lost encounter stays playable; its recorded reply cannot turn into a free retry.
	if state.Board.Cells[grid-1] == memoir.Player {
		if _, err = mode.PlayerFight(ctx, actor, request, op()); err != nil {
			t.Fatal("new paid attempt after loss", err)
		}
		if memoirRecord(t, pool, actor).Sequence <= state.Sequence {
			t.Fatal("loss replay trapped a fresh request")
		}
	}
}
