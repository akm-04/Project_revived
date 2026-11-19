//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/eventcentrestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	appeventcentre "gxb.local/backend/v2/internal/application/eventcentre"
	i5 "gxb.local/backend/v2/internal/application/i5"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func boardService(t *testing.T, database *pg.Pool, books appbook.Service) appeventcentre.Service {
	t.Helper()
	values := i5store.Store{Queryer: database}
	return appeventcentre.Service{
		Timed:          books.Timed,
		Reads:          tx.Runner{DB: database},
		Owner:          eventcentrestore.Store{},
		Book:           books,
		Content:        contentstore.Store{Queryer: database},
		Pets:           characterstore.Store{},
		Players:        i4store.PlayerRootLocker{},
		Fence:          values,
		Costs:          i5.MaterialCostDebiter{Store: values, Content: contentstore.Store{Queryer: database}},
		Grants:         books.Grants,
		Receipts:       kernelstore.Store{},
		Heroes:         characterstore.Store{Queryer: database},
		Levels:         values,
		Stats:          rawBirthStats(database),
		Combat:         combatService(t, database),
		Facts:          i5.ObjectiveFacts{Owner: missionOwner(database), Open: i5store.Store{Queryer: database}},
		BattleObserver: libraryService(database, database),
	}
}

func boardRoot(t *testing.T, database *pg.Pool, player identity.PlayerID) ec.Root {
	t.Helper()
	root, found, err := (eventcentrestore.Store{}).ReadRootTx(ctx, database, player)
	if err != nil || !found {
		t.Fatalf("board root %v %v", found, err)
	}
	return root
}

func setBoardStart(t *testing.T, database *pg.Pool, actor identity.ActorContext, missionID, startAt int64) {
	t.Helper()
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	owner := eventcentrestore.Store{}
	root, found, err := owner.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil || !found {
		t.Fatalf("lock board root %v %v", found, err)
	}
	for index := range root.Facts.Board.Doing {
		if root.Facts.Board.Doing[index].MissionID == missionID {
			root.Facts.Board.Doing[index].StartAt = startAt
			root.Facts.Board.Doing[index].Attempt = ""
		}
	}
	previous := root.Version
	root.Version++
	root.UpdatedAt = time.Now().UTC()
	if err = owner.SaveRootTx(ctx, transaction, root, previous); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func injectBoardMission(t *testing.T, database *pg.Pool, actor identity.ActorContext, missionID int64, leader int64, partners []int64, startAt int64) {
	t.Helper()
	injectBoardMissionOfType(t, database, actor, missionID, leader, partners, startAt, ec.BoardTaskTypeNormal, 10001)
}

func injectBoardMissionOfType(t *testing.T, database *pg.Pool, actor identity.ActorContext, missionID int64, leader int64, partners []int64, startAt int64, kind int64, awardID int64) {
	t.Helper()
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	owner := eventcentrestore.Store{}
	root, found, err := owner.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil || !found {
		t.Fatalf("lock board root %v %v", found, err)
	}
	root.Facts.Board.Doing = append(root.Facts.Board.Doing, ec.BoardMission{MissionID: missionID, Leader: leader, Partners: partners, StartAt: startAt, Type: kind, AwardID: awardID})
	previous := root.Version
	root.Version++
	root.UpdatedAt = time.Now().UTC()
	if err = owner.SaveRootTx(ctx, transaction, root, previous); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func boardNumber(t *testing.T, body map[string]any, field string) int64 {
	t.Helper()
	switch value := body[field].(type) {
	case int64:
		return value
	case float64:
		return int64(value)
	default:
		t.Fatalf("%s is not a number: %#v", field, body[field])
		return 0
	}
}

func boardList(t *testing.T, body map[string]any, field string) []any {
	t.Helper()
	list, ok := body[field].([]any)
	if !ok {
		t.Fatalf("%s is not a list: %#v", field, body[field])
	}
	return list
}

func TestI910ANoticeBoardNative(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	bornHero(t, database, actor, revision, 10001001, 1)
	bornHero(t, database, actor, revision, 10001002, 2)
	service := boardService(t, database, books)
	dispatcher := stockruntime.EventCentreDispatcher{Authority: playtestAuthority{actor}, Service: service}

	// 1083 list: two owned tier-one heroes produce their tier-one missions.
	listed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if listed.HTTPStatus != 200 {
		t.Fatalf("1083: %d %+v", listed.HTTPStatus, listed.Body)
	}
	offers := boardList(t, listed.Body, "mission_list")
	if len(offers) != 2 {
		t.Fatalf("offers = %+v", offers)
	}
	offer := map[string]any{}
	for _, entry := range offers {
		candidate := entry.(map[string]any)
		if boardNumber(t, candidate, "mission_id") == 10001 {
			offer = candidate
		}
	}
	if boardNumber(t, offer, "type") != 1 || boardNumber(t, offer, "award_id") == 0 {
		t.Fatalf("offer = %+v", offers)
	}
	if len(boardList(t, listed.Body, "doing_mission_list")) != 0 || len(boardList(t, listed.Body, "finish_mission_list")) != 0 || len(boardList(t, listed.Body, "award_log")) != 0 {
		t.Fatalf("fresh board = %+v", listed.Body)
	}
	root := boardRoot(t, database, actor.PlayerID)
	if root.Facts.Board.RefreshDay != modes.Day(time.Now().UTC()) || len(root.Facts.Board.Offers) != 2 {
		t.Fatalf("refreshed root = %+v", root.Facts.Board)
	}

	// 1084 receive, then a repeat with the same operation is one mission only.
	receive := playtestRequest(actor, 1084, map[string]any{"mission_id": int64(10001), "leader": int64(1), "partners": []any{}, "wish_crystal": int64(0)})
	received := dispatcher.Dispatch(ctx, receive)
	if received.HTTPStatus != 200 {
		t.Fatalf("1084: %d %+v", received.HTTPStatus, received.Body)
	}
	if again := dispatcher.Dispatch(ctx, receive); again.HTTPStatus != 200 {
		t.Fatalf("1084 retry: %d %+v", again.HTTPStatus, again.Body)
	}
	root = boardRoot(t, database, actor.PlayerID)
	if len(root.Facts.Board.Doing) != 1 || root.Facts.Board.Doing[0].MissionID != 10001 || root.Facts.Board.Doing[0].Leader != 1 {
		t.Fatalf("doing after receive = %+v", root.Facts.Board.Doing)
	}

	// Busy hero: mission 10011 with the same leader refuses; partner 2 accepts.
	busy := dispatcher.Dispatch(ctx, playtestRequest(actor, 1084, map[string]any{"mission_id": int64(10011), "leader": int64(1), "partners": []any{}, "wish_crystal": int64(0)}))
	if busy.HTTPStatus != 409 {
		t.Fatalf("busy hero: %d %+v", busy.HTTPStatus, busy.Body)
	}
	if len(boardRoot(t, database, actor.PlayerID).Facts.Board.Doing) != 1 {
		t.Fatal("busy refusal wrote a mission")
	}

	// The wish debits the blessing crystal server-side, not only on the client.
	eventCentreFixture(t, database, actor, books, revision, []grant.Line{{Kind: grant.StackItem, ItemID: ec.BlessingCrystalItemID, Amount: 1}})
	wished := dispatcher.Dispatch(ctx, playtestRequest(actor, 1084, map[string]any{"mission_id": int64(10011), "leader": int64(2), "partners": []any{}, "wish_crystal": int64(1)}))
	if wished.HTTPStatus != 200 {
		t.Fatalf("wish 1084: %d %+v", wished.HTTPStatus, wished.Body)
	}
	if stack, exists, err := (i5store.Store{}).ReadStackTx(ctx, database, actor.PlayerID, ec.BlessingCrystalItemID); err != nil || exists && stack.Quantity != 0 {
		t.Fatalf("blessing crystal after wish: %+v %v %v", stack, exists, err)
	}

	// Give up frees the hero.
	for _, missionID := range []int64{10001, 10011} {
		if given := dispatcher.Dispatch(ctx, playtestRequest(actor, 1085, map[string]any{"mission_id": missionID})); given.HTTPStatus != 200 {
			t.Fatalf("1085 %d: %d %+v", missionID, given.HTTPStatus, given.Body)
		}
	}
	if len(boardRoot(t, database, actor.PlayerID).Facts.Board.Doing) != 0 {
		t.Fatal("give up left a mission")
	}

	// Loss settlement: a single weak hero loses, no award, report replayable.
	second := dispatcher.Dispatch(ctx, playtestRequest(actor, 1084, map[string]any{"mission_id": int64(10001), "leader": int64(1), "partners": []any{}, "wish_crystal": int64(0)}))
	if second.HTTPStatus != 200 {
		t.Fatalf("second 1084: %d %+v", second.HTTPStatus, second.Body)
	}
	manaBefore, _, err := i5store.Store{Queryer: database}.ReadScalarTx(ctx, database, actor.PlayerID, ec.BoardDepositResourceKey)
	if err != nil {
		t.Fatal(err)
	}
	setBoardStart(t, database, actor, 10001, time.Now().UTC().Add(-48*time.Hour).Unix())
	settled := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if settled.HTTPStatus != 200 {
		t.Fatalf("settle 1083: %d %+v", settled.HTTPStatus, settled.Body)
	}
	finish := boardList(t, settled.Body, "finish_mission_list")
	if len(finish) != 1 {
		t.Fatalf("finish after loss = %+v", finish)
	}
	run := finish[0].(map[string]any)
	if boardNumber(t, run, "is_win") != 0 || boardNumber(t, run, "battle_id") <= 0 {
		t.Fatalf("loss run = %+v", run)
	}
	if len(boardList(t, settled.Body, "award_log")) != 0 {
		t.Fatalf("loss granted an award: %+v", settled.Body)
	}
	manaAfter, _, err := i5store.Store{Queryer: database}.ReadScalarTx(ctx, database, actor.PlayerID, ec.BoardDepositResourceKey)
	if err != nil {
		t.Fatal(err)
	}
	if manaAfter.Amount != manaBefore.Amount {
		t.Fatalf("loss changed mana %d -> %d", manaBefore.Amount, manaAfter.Amount)
	}
	if count := girlsLogCount(t, database, actor.PlayerID, 1); count != 1 {
		t.Fatalf("settled board mission counted %d, want 1", count)
	}
	if rows := girlsLogRows(t, database, actor.PlayerID); len(rows) != 1 {
		t.Fatalf("settled board mission counted non-participants: %v", rows)
	}
	reportID := boardNumber(t, run, "battle_id")
	report := dispatcher.Dispatch(ctx, playtestRequest(actor, 1087, map[string]any{"battle_id": reportID}))
	if report.HTTPStatus != 200 {
		t.Fatalf("1087: %d %+v", report.HTTPStatus, report.Body)
	}
	entries := boardList(t, report.Body, "report")
	if len(entries) != 1 {
		t.Fatalf("report = %+v", report.Body)
	}
	var decoded map[string]any
	if err = json.Unmarshal([]byte(entries[0].(map[string]any)["content"].(string)), &decoded); err != nil || decoded["fighter"] == nil || decoded["star"] == nil {
		t.Fatalf("report content = %v %v", decoded, err)
	}

	// Settling again is a read: same run, no second report, no award.
	again := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if again.HTTPStatus != 200 {
		t.Fatalf("repeat 1083: %d %+v", again.HTTPStatus, again.Body)
	}
	repeatFinish := boardList(t, again.Body, "finish_mission_list")
	if len(repeatFinish) != 1 || boardNumber(t, repeatFinish[0].(map[string]any), "battle_id") != reportID {
		t.Fatalf("repeat finish = %+v", repeatFinish)
	}
	if len(boardList(t, again.Body, "doing_mission_list")) != 0 {
		t.Fatalf("repeat doing = %+v", again.Body["doing_mission_list"])
	}
	againMana, _, err := i5store.Store{Queryer: database}.ReadScalarTx(ctx, database, actor.PlayerID, ec.BoardDepositResourceKey)
	if err != nil || againMana.Amount != manaAfter.Amount {
		t.Fatalf("repeat settlement changed mana %+v %v", againMana, err)
	}
	if count := girlsLogCount(t, database, actor.PlayerID, 1); count != 1 {
		t.Fatalf("a repeated board read counted %d, want 1", count)
	}

	// Win settlement with award: inject a due mission with six strong heroes.
	strongHeroTables := []int64{10001087, 10001089, 10001090, 10001091, 10001092, 10001093}
	for index, tableID := range strongHeroTables {
		partner := int64(index + 1)
		if partner > 2 {
			bornHero(t, database, actor, revision, tableID, partner)
		}
		exec(t, database, `UPDATE player_heroes SET level=100,star=5,color=1,raw_skill_1=100,raw_skill_2=100,raw_skill_3=100,raw_skill_4=100,raw_skill_5=100,raw_skill_6=100,updated_at=clock_timestamp() WHERE player_id=$1 AND partner_id=$2`, int64(actor.PlayerID), partner)
	}
	injectBoardMission(t, database, actor, 10001, 1, []int64{2, 3, 4, 5, 6}, time.Now().UTC().Add(-48*time.Hour).Unix())
	manaBeforeWin, _, err := i5store.Store{Queryer: database}.ReadScalarTx(ctx, database, actor.PlayerID, ec.BoardDepositResourceKey)
	if err != nil {
		t.Fatal(err)
	}
	won := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if won.HTTPStatus != 200 {
		t.Fatalf("win 1083: %d %+v cause=%v", won.HTTPStatus, won.Body, won.Cause)
	}
	wins := boardList(t, won.Body, "finish_mission_list")
	if len(wins) != 2 {
		t.Fatalf("finish after win = %+v", wins)
	}
	winRun := wins[0].(map[string]any)
	if boardNumber(t, winRun, "is_win") != 1 || boardNumber(t, winRun, "battle_id") <= 0 {
		t.Fatalf("win run = %+v", winRun)
	}
	awards := boardList(t, won.Body, "award_log")
	if len(awards) != 1 {
		t.Fatalf("win award log = %+v", awards)
	}
	manaAfterWin, _, err := i5store.Store{Queryer: database}.ReadScalarTx(ctx, database, actor.PlayerID, ec.BoardDepositResourceKey)
	if err != nil {
		t.Fatal(err)
	}
	if manaAfterWin.Amount != manaBeforeWin.Amount+500000 {
		t.Fatalf("win award mana %d -> %d", manaBeforeWin.Amount, manaAfterWin.Amount)
	}
	if count := girlsLogCount(t, database, actor.PlayerID, 1); count != 2 {
		t.Fatalf("the leader's two settled missions counted %d, want 2", count)
	}
	for _, partner := range []int64{2, 3, 4, 5, 6} {
		if count := girlsLogCount(t, database, actor.PlayerID, partner); count != 1 {
			t.Fatalf("win partner %d counted %d, want 1", partner, count)
		}
	}
	if rows := girlsLogRows(t, database, actor.PlayerID); len(rows) != 6 {
		t.Fatalf("board counted non-participants: %v", rows)
	}
	winReport := dispatcher.Dispatch(ctx, playtestRequest(actor, 1087, map[string]any{"battle_id": boardNumber(t, winRun, "battle_id")}))
	if winReport.HTTPStatus != 200 {
		t.Fatalf("win 1087: %d %+v", winReport.HTTPStatus, winReport.Body)
	}

	// 1086 clears the award log; the history survives.
	if confirmed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1086, map[string]any{})); confirmed.HTTPStatus != 200 {
		t.Fatalf("1086: %d %+v", confirmed.HTTPStatus, confirmed.Body)
	}
	cleared := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if cleared.HTTPStatus != 200 || len(boardList(t, cleared.Body, "award_log")) != 0 || len(boardList(t, cleared.Body, "finish_mission_list")) != 2 {
		t.Fatalf("after confirm: %d %+v", cleared.HTTPStatus, cleared.Body)
	}
}
