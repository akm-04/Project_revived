//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	cd "gxb.local/backend/v2/internal/domain/combat"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// setBoardBuildingLevel raises a fixture building so the source notice board
// table offers gold (deposit) tasks, which only exist at board level 5.
func setBoardBuildingLevel(t *testing.T, database *pg.Pool, actor identity.ActorContext, revision string, kind, level int64) {
	t.Helper()
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	owner := bookstore.Store{}
	at := time.Now().UTC()
	if err = owner.EnsureRootTx(ctx, transaction, actor.PlayerID, revision, at); err != nil {
		t.Fatal(err)
	}
	root, err := owner.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	building := root.Facts.Buildings[kind]
	building.Level = level
	building.Job = nil
	building.CatalogRevision = revision
	root.Facts.Buildings[kind] = building
	previous := root.Version
	root.Version++
	root.UpdatedAt = at
	if err = owner.SaveRootTx(ctx, transaction, root, previous); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func boardMana(t *testing.T, database *pg.Pool, actor identity.ActorContext) int64 {
	t.Helper()
	scalar, exists, err := (i5store.Store{Queryer: database}).ReadScalarTx(ctx, database, actor.PlayerID, ec.BoardDepositResourceKey)
	if err != nil {
		t.Fatal(err)
	}
	if !exists {
		t.Fatal("fixture has no mana balance")
	}
	return scalar.Amount
}

func boardOfferOfType(t *testing.T, body map[string]any, kind int64) map[string]any {
	t.Helper()
	for _, entry := range boardList(t, body, "mission_list") {
		offer := entry.(map[string]any)
		if boardNumber(t, offer, "type") == kind {
			return offer
		}
	}
	t.Fatalf("no type %d offer in %+v", kind, body["mission_list"])
	return nil
}

func TestI910BDepositNative(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	bornHero(t, database, actor, revision, 10001001, 1)
	service := boardService(t, database, books)
	setBoardBuildingLevel(t, database, actor, revision, ec.BoardBuilding, 5)
	dispatcher := stockruntime.EventCentreDispatcher{Authority: playtestAuthority{actor}, Service: service}
	catalog, err := (contentstore.Store{Queryer: database}).WorkshopInputsTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}

	listed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if listed.HTTPStatus != 200 {
		t.Fatalf("1083: %d %+v", listed.HTTPStatus, listed.Body)
	}
	offer := boardOfferOfType(t, listed.Body, ec.BoardTaskTypeDeposit)
	missionID := boardNumber(t, offer, "mission_id")
	awardID := boardNumber(t, offer, "award_id")
	rule, known := catalog.Mission(missionID)
	if !known || rule.Deposit <= 0 {
		t.Fatalf("deposit mission %d = %+v known=%v", missionID, rule, known)
	}

	manaBefore := boardMana(t, database, actor)
	started := dispatcher.Dispatch(ctx, playtestRequest(actor, 1084, map[string]any{"mission_id": missionID, "leader": int64(1), "partners": []any{}, "wish_crystal": int64(0)}))
	if started.HTTPStatus != 200 {
		t.Fatalf("deposit 1084: %d %+v", started.HTTPStatus, started.Body)
	}
	if after := boardMana(t, database, actor); after != manaBefore-rule.Deposit {
		t.Fatalf("deposit debit %d -> %d, want -%d", manaBefore, after, rule.Deposit)
	}
	doing := boardRoot(t, database, actor.PlayerID).Facts.Board.Doing
	if len(doing) != 1 || doing[0].Type != ec.BoardTaskTypeDeposit {
		t.Fatalf("doing after deposit start = %+v", doing)
	}

	// A loss refunds the deposit in full.
	setBoardStart(t, database, actor, missionID, time.Now().UTC().Add(-48*time.Hour).Unix())
	lost := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if lost.HTTPStatus != 200 {
		t.Fatalf("loss 1083: %d %+v", lost.HTTPStatus, lost.Body)
	}
	losses := boardList(t, lost.Body, "finish_mission_list")
	if len(losses) != 1 || boardNumber(t, losses[0].(map[string]any), "is_win") != 0 {
		t.Fatalf("deposit loss history = %+v", losses)
	}
	if after := boardMana(t, database, actor); after != manaBefore {
		t.Fatalf("loss refund %d -> %d, want %d", manaBefore, after, manaBefore)
	}
	if len(boardList(t, lost.Body, "doing_mission_list")) != 0 {
		t.Fatalf("loss left a mission: %+v", lost.Body["doing_mission_list"])
	}

	// A win consumes the deposit: the settled balance only gains the award gold.
	strongHeroTables := []int64{10001087, 10001089, 10001090, 10001091, 10001092, 10001093}
	for index, tableID := range strongHeroTables {
		partner := int64(index + 1)
		if partner > 1 {
			bornHero(t, database, actor, revision, tableID, partner)
		}
		exec(t, database, `UPDATE player_heroes SET level=100,star=5,color=1,raw_skill_1=100,raw_skill_2=100,raw_skill_3=100,raw_skill_4=100,raw_skill_5=100,raw_skill_6=100,updated_at=clock_timestamp() WHERE player_id=$1 AND partner_id=$2`, int64(actor.PlayerID), partner)
	}
	award, known := catalog.WinAward(awardID, false)
	if !known {
		t.Fatalf("award %d unknown", awardID)
	}
	injectBoardMissionOfType(t, database, actor, missionID, 1, []int64{2, 3, 4, 5, 6}, time.Now().UTC().Add(-48*time.Hour).Unix(), ec.BoardTaskTypeDeposit, awardID)
	manaBeforeWin := boardMana(t, database, actor)
	won := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if won.HTTPStatus != 200 {
		t.Fatalf("win 1083: %d %+v", won.HTTPStatus, won.Body)
	}
	wins := boardList(t, won.Body, "finish_mission_list")
	if len(wins) != 2 || boardNumber(t, wins[0].(map[string]any), "is_win") != 1 {
		t.Fatalf("deposit win history = %+v", wins)
	}
	if after := boardMana(t, database, actor); after != manaBeforeWin+award.Gold {
		t.Fatalf("win balance %d -> %d, want award only +%d (deposit not consumed)", manaBeforeWin, after, award.Gold)
	}
}

type permanentBoardWorker struct{}

func (permanentBoardWorker) Resolve(context.Context, []byte, string, [32]byte) (appcombat.WorkerOutput, error) {
	return appcombat.WorkerOutput{}, fmt.Errorf("%w: injected", cd.ErrResolverPermanent)
}

func TestI910BPermanentResolverFailureNative(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	bornHero(t, database, actor, revision, 10001001, 1)
	service := boardService(t, database, books)
	setBoardBuildingLevel(t, database, actor, revision, ec.BoardBuilding, 5)
	dispatcher := stockruntime.EventCentreDispatcher{Authority: playtestAuthority{actor}, Service: service}
	catalog, err := (contentstore.Store{Queryer: database}).WorkshopInputsTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}

	listed := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if listed.HTTPStatus != 200 {
		t.Fatalf("1083: %d %+v", listed.HTTPStatus, listed.Body)
	}
	offer := boardOfferOfType(t, listed.Body, ec.BoardTaskTypeDeposit)
	missionID := boardNumber(t, offer, "mission_id")
	rule, known := catalog.Mission(missionID)
	if !known || rule.Deposit <= 0 {
		t.Fatalf("deposit mission %d = %+v known=%v", missionID, rule, known)
	}
	manaBefore := boardMana(t, database, actor)
	started := dispatcher.Dispatch(ctx, playtestRequest(actor, 1084, map[string]any{"mission_id": missionID, "leader": int64(1), "partners": []any{}, "wish_crystal": int64(0)}))
	if started.HTTPStatus != 200 {
		t.Fatalf("deposit 1084: %d %+v", started.HTTPStatus, started.Body)
	}
	if after := boardMana(t, database, actor); after != manaBefore-rule.Deposit {
		t.Fatalf("deposit debit %d -> %d, want -%d", manaBefore, after, rule.Deposit)
	}

	real, ok := service.Combat.(appcombat.Service)
	if !ok {
		t.Fatalf("board combat is %T", service.Combat)
	}
	real.Worker = permanentBoardWorker{}
	broken := service
	broken.Combat = real
	dispatcher.Service = broken
	setBoardStart(t, database, actor, missionID, time.Now().UTC().Add(-48*time.Hour).Unix())
	settled := dispatcher.Dispatch(ctx, playtestRequest(actor, 1083, map[string]any{}))
	if settled.HTTPStatus != 200 {
		t.Fatalf("permanent 1083: %d %+v", settled.HTTPStatus, settled.Body)
	}
	if len(boardList(t, settled.Body, "doing_mission_list")) != 0 {
		t.Fatalf("closed mission still doing: %+v", settled.Body["doing_mission_list"])
	}
	if len(boardList(t, settled.Body, "finish_mission_list")) != 0 {
		t.Fatalf("permanent failure added history: %+v", settled.Body["finish_mission_list"])
	}
	if after := boardMana(t, database, actor); after != manaBefore {
		t.Fatalf("permanent failure refund %d -> %d, want %d", manaBefore, after, manaBefore)
	}
	if history := boardRoot(t, database, actor.PlayerID).Facts.Board.History; len(history) != 0 {
		t.Fatalf("permanent failure stored history: %+v", history)
	}

	// The closed attempt freed the locator and the hero, so the same mission starts again.
	again := dispatcher.Dispatch(ctx, playtestRequest(actor, 1084, map[string]any{"mission_id": missionID, "leader": int64(1), "partners": []any{}, "wish_crystal": int64(0)}))
	if again.HTTPStatus != 200 {
		t.Fatalf("restart after permanent failure: %d %+v", again.HTTPStatus, again.Body)
	}
	if doing := boardRoot(t, database, actor.PlayerID).Facts.Board.Doing; len(doing) != 1 || doing[0].Leader != 1 {
		t.Fatalf("restart doing = %+v", doing)
	}
}
