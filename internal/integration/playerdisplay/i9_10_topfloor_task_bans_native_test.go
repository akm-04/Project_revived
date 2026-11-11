//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"net/http"
	"strconv"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI9_10TopFloorOperatorBansNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, originalHero := topFloorPlayer(t, database, server)
	alternateHero := bornHero(t, database, actor, revision, 10001003, 2001)
	attackHero := bornHero(t, database, actor, revision, 10001004, 2002)
	opponent, _, _ := topFloorPlayer(t, database, server)
	opponentHero := bornHero(t, database, opponent, revision, 10001002, 2001)
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	original, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, database, actor.PlayerID, originalHero.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	alternate, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, database, actor.PlayerID, alternateHero.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	attack, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, database, actor.PlayerID, attackHero.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	defender, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, database, opponent.PlayerID, opponentHero.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	clock := &workplaceTime{at: taskRotationForRule(t, catalog, func(rule d.TaskModeRule) bool {
		return rule.ID == d.TaskModeSingle && rule.HeroSlots == 1 && !containsTaskTable(rule.BannedTables, original.TableID, alternate.TableID, attack.TableID, defender.TableID)
	})}
	service.Timed.Binder.Time = clock
	rotation, err := catalog.TaskModes.Rotation(clock.at)
	if err != nil {
		t.Fatal(err)
	}
	if rotation.Mode != d.TaskModeSingle {
		t.Fatalf("test rotation mode %d, want single-girl mode", rotation.Mode)
	}
	exec(t, database, `DELETE FROM top_floor_task_bans WHERE mode_id=$1 AND rotation_number IN ($2,$3)`, rotation.Mode, rotation.Number, rotation.Number+1)
	t.Cleanup(func() {
		exec(t, database, `DELETE FROM top_floor_task_bans WHERE mode_id=$1 AND rotation_number IN ($2,$3)`, rotation.Mode, rotation.Number, rotation.Number+1)
	})
	exec(t, database, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(actor.PlayerID))
	normal, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal("load normal Top Floor for admission", err)
	}
	store := topfloorstore.Store{}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SwapTx(ctx, transaction, server, d.Ranked{Rank: normal.Rank, Occupant: d.Occupant{Player: actor.PlayerID}}, d.Ranked{Rank: 200, Occupant: d.Occupant{Robot: d.RobotTeams + 1 - 200}}); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	period, err := catalog.TaskModes.NewPeriod(server, revision, clock.at)
	if err != nil {
		t.Fatal(err)
	}
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.CreateTaskPeriodTx(ctx, transaction, period); err != nil {
		t.Fatal(err)
	}
	opponentPlayer := catalog.NewPlayer(opponent.PlayerID, server, revision, 1, clock.at)
	opponentPlayer.Defense = []int64{opponentHero.PartnerID}
	if err = store.InsertTaskPlayerTx(ctx, transaction, d.TaskModePlayer{Player: opponentPlayer, PeriodNumber: rotation.Number}, period); err == nil {
		err = store.AppendTaskPlayerTx(ctx, transaction, server, rotation.Number, 1, opponent.PlayerID)
	}
	if err == nil {
		period.Ladder.Size, period.Ladder.StateVersion, period.Ladder.UpdatedAt = 1, 2, clock.at
		err = store.SaveTaskPeriodTx(ctx, transaction, period, 1)
	}
	if err != nil {
		transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err = store.SaveTaskPreferenceTx(ctx, transaction, actor.PlayerID, rotation.Mode, d.TaskModeDefense{Heroes: []int64{originalHero.PartnerID}}); err != nil {
		transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	exec(t, database, `INSERT INTO top_floor_task_bans(mode_id,rotation_number,banned_table_id) VALUES($1,$2,$3)`, rotation.Mode, rotation.Number, original.TableID)

	view, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil || len(view.Player.Defense) != 0 || len(view.Enemies) != 1 {
		t.Fatalf("banned carried defense fallback or human offer: defense=%v enemies=%d err=%v", view.Player.Defense, len(view.Enemies), err)
	}
	requestNumber := func(value int64) json.Number { return json.Number(strconv.FormatInt(value, 10)) }
	dispatcher := stockruntime.TopFloorTaskDispatcher{Authority: playtestAuthority{actor}, Service: service}
	defenseRequest := func(partnerID int64) map[string]any {
		return map[string]any{"heroIDs": []any{requestNumber(partnerID)}, "pet_id": requestNumber(0), "leader_id": requestNumber(0)}
	}
	formationRequest := func(partnerID int64, enemy int64) map[string]any {
		return map[string]any{"formation": strconv.FormatInt(partnerID, 10), "pet_id": requestNumber(0), "leader_id": requestNumber(0), "enemy_id": requestNumber(enemy), "is_avenge": requestNumber(0), "campaign_id": requestNumber(0), "campaign_type": requestNumber(d.TaskModeCampaignType)}
	}
	assertRefusal := func(mid uint16, parameters map[string]any) {
		t.Helper()
		response := dispatcher.Dispatch(ctx, playtestRequest(actor, mid, parameters))
		if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(40001) {
			t.Fatalf("MID %d operator-banned refusal: %+v", mid, response)
		}
	}
	otherWeek := dispatcher.Dispatch(ctx, playtestRequest(actor, 284, defenseRequest(alternateHero.PartnerID)))
	if otherWeek.HTTPStatus != http.StatusOK {
		t.Fatalf("other-week ban affected current defense: %+v", otherWeek)
	}
	exec(t, database, `INSERT INTO top_floor_task_bans(mode_id,rotation_number,banned_table_id) VALUES($1,$2,$3)`, rotation.Mode, rotation.Number+1, alternate.TableID)
	otherWeek = dispatcher.Dispatch(ctx, playtestRequest(actor, 284, defenseRequest(alternateHero.PartnerID)))
	if otherWeek.HTTPStatus != http.StatusOK {
		t.Fatalf("next-week row affected current defense: %+v", otherWeek)
	}
	if len(view.Enemies) != 1 {
		t.Fatalf("ranked human offer missing: %+v", view.Enemies)
	}
	enemy := view.Enemies[0].Occupant.TableID()
	exec(t, database, `INSERT INTO top_floor_task_bans(mode_id,rotation_number,banned_table_id) VALUES($1,$2,$3)`, rotation.Mode, rotation.Number, defender.TableID)
	assertRefusal(285, map[string]any{"enemy_id": requestNumber(enemy)})
	assertRefusal(286, formationRequest(attackHero.PartnerID, enemy))
	exec(t, database, `DELETE FROM top_floor_task_bans WHERE mode_id=$1 AND rotation_number=$2 AND banned_table_id=$3`, rotation.Mode, rotation.Number, defender.TableID)

	exec(t, database, `INSERT INTO top_floor_task_bans(mode_id,rotation_number,banned_table_id) VALUES($1,$2,$3)`, rotation.Mode, rotation.Number, alternate.TableID)
	assertRefusal(284, defenseRequest(alternateHero.PartnerID))
	assertRefusal(286, formationRequest(alternateHero.PartnerID, enemy))
	defenseRefusal := dispatcher.Dispatch(ctx, playtestRequest(actor, 286, formationRequest(attackHero.PartnerID, enemy)))
	if defenseRefusal.HTTPStatus != http.StatusConflict || defenseRefusal.Body["error_code"] != int64(35028) {
		t.Fatalf("banned saved defense refusal: %+v", defenseRefusal)
	}
	if scalar(t, database, `SELECT (payload->'player'->>'TicketsLeft')::bigint FROM top_floor_task_players WHERE player_id=$1 AND period_number=$2`, int64(actor.PlayerID), rotation.Number) != 5 {
		t.Fatal("operator-ban refusals spent a task ticket")
	}
}

func containsTaskTable(bannedTables []int64, tables ...int64) bool {
	for _, bannedTable := range bannedTables {
		for _, table := range tables {
			if bannedTable == table {
				return true
			}
		}
	}
	return false
}
