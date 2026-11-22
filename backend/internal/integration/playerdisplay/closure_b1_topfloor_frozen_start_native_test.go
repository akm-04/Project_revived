//go:build postgres

package playerdisplay_test

import (
	"slices"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	application "gxb.local/backend/v2/internal/application/topfloor"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

// TestClosureB1TopFloorOpenStartReplaysFrozenFormationNative is DL-6c0fd231: a
// START for the enemy of an open attempt replays its frozen START even when the
// submitted formation changed (I8_PARENT_CONTRACT_V1 generation_supersede).
func TestClosureB1TopFloorOpenStartReplaysFrozenFormationNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, first := topFloorPlayer(t, database, server)
	secondDefinition := collectionResources(t, database, actor, revision, 10001002)
	second, err := ownerSummoner(database).SummonNormal(ctx, actor, 10001002, secondDefinition.Template.FragmentItemID, secondDefinition.FragmentCount, op())
	if err != nil {
		t.Fatal(err)
	}
	secondReference := second.Ref()
	view, err := service.Load(ctx, actor, op())
	if err != nil || len(view.Enemies) == 0 {
		t.Fatalf("load offers: %v", err)
	}
	if err = service.SaveDefense(ctx, actor, []int64{first.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	enemy := view.Enemies[0].Occupant.TableID()
	stalled := service
	stalled.Combat = stalledCombat{service.Combat}
	firstFight, err := stalled.Start(ctx, actor, application.StartCommand{Formation: []int64{first.PartnerID}, Enemy: enemy}, op())
	if err != nil || firstFight.Report != nil {
		t.Fatalf("first pending START report=%v err=%v", firstFight.Report, err)
	}
	replay, err := stalled.Start(ctx, actor, application.StartCommand{Formation: []int64{secondReference.PartnerID}, Enemy: enemy}, op())
	if err != nil {
		t.Fatalf("same-enemy START with another formation: %v", err)
	}
	if replay.Report != nil || len(replay.Formation) != 1 || formValue(t, replay.Formation[0], "partner_id") != first.PartnerID {
		t.Fatalf("frozen START formation=%+v report=%v", replay.Formation, replay.Report)
	}
	latest, found, err := (topfloorstore.Store{}).LatestFightTx(ctx, database, actor.PlayerID)
	if err != nil || !found || latest.Status != d.StatusStarted || !slices.Equal(latest.Formation, []int64{first.PartnerID}) {
		t.Fatalf("stored fight %+v found=%v err=%v", latest, found, err)
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(actor.PlayerID)) != 1 ||
		scalar(t, database, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID)) != 4 {
		t.Fatal("a replayed START staged a fight or spent a ticket")
	}
	if firstFight.Enemy.Occupant != replay.Enemy.Occupant {
		t.Fatalf("replay enemy %+v != %+v", replay.Enemy.Occupant, firstFight.Enemy.Occupant)
	}
}
