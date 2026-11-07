//go:build postgres

package playerdisplay_test

import (
	"errors"
	"slices"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	application "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI9_10TopFloorOfferRefreshAndBotStartNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, hero := topFloorPlayer(t, database, server)
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Frozen(time.Now()) {
		t.Skip("21:00-21:30 GMT+8 settlement freeze admits no START")
	}
	view, err := service.Load(ctx, actor, op())
	if err != nil || len(view.Enemies) == 0 {
		t.Fatalf("load offers: %v", err)
	}
	if err = service.SaveDefense(ctx, actor, []int64{hero.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	target := view.Enemies[0]
	if !target.Occupant.IsRobot() {
		t.Fatalf("expected a robot target in the isolated ladder: %+v", target.Occupant)
	}
	command := application.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: target.Occupant.TableID()}
	exec(t, database, `DELETE FROM top_floor_offer_snapshots WHERE player_id=$1 AND scope=$2`, int64(actor.PlayerID), d.OfferScopeNormal)
	if _, err = service.Start(ctx, actor, command, op()); !errors.Is(err, d.ErrOfferStale) {
		t.Fatalf("START without an offer snapshot: %v", err)
	}
	if scalar(t, database, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID)) != 5 {
		t.Fatal("missing-snapshot refusal spent a ticket")
	}

	if err = swapRanks(t, database, server, target.Rank, 1); err != nil {
		t.Fatal(err)
	}
	refreshed, err := service.Refresh(ctx, actor, op())
	if err != nil || len(refreshed.Enemies) == 0 {
		t.Fatalf("refresh offers: %v", err)
	}
	for _, enemy := range refreshed.Enemies {
		if enemy.Occupant == target.Occupant {
			t.Fatal("refresh retained the target moved outside the offered bands")
		}
	}

	dispatcher := stockruntime.TopFloorDispatcher{Authority: playtestAuthority{actor}, Service: service}
	oldOffer := dispatcher.Dispatch(ctx, playtestRequest(actor, 280, map[string]any{
		"formation": strconv.FormatInt(hero.PartnerID, 10), "enemy_id": target.Occupant.TableID(), "campaign_type": d.CampaignType,
	}))
	if oldOffer.HTTPStatus != 400 || oldOffer.Body["error"] != "top_floor_request_refused" {
		t.Fatalf("reissued offer did not invalidate the old target: %+v", oldOffer)
	}
	if scalar(t, database, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID)) != 5 ||
		scalar(t, database, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(actor.PlayerID)) != 0 {
		t.Fatal("refusing an earlier offer spent state")
	}

	bot := refreshed.Enemies[0]
	if !bot.Occupant.IsRobot() {
		t.Fatalf("expected refreshed robot target: %+v", bot.Occupant)
	}
	start := dispatcher.Dispatch(ctx, playtestRequest(actor, 280, map[string]any{
		"formation": strconv.FormatInt(hero.PartnerID, 10), "enemy_id": bot.Occupant.TableID(), "campaign_type": d.CampaignType,
	}))
	if start.HTTPStatus != 200 {
		t.Fatalf("explicit bot START: %+v", start)
	}
	if scalar(t, database, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID)) != 4 {
		t.Fatal("bot START did not consume exactly one ticket")
	}

	removedActor, _, removedHero := topFloorPlayer(t, database, server)
	removedView, err := service.Load(ctx, removedActor, op())
	if err != nil || len(removedView.Enemies) == 0 {
		t.Fatalf("load removed-target offers: %v", err)
	}
	if err = service.SaveDefense(ctx, removedActor, []int64{removedHero.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	removedTarget := removedView.Enemies[0]
	exec(t, database, `DELETE FROM top_floor_ranks WHERE logical_server_id=$1 AND rank=$2`, int64(server), removedTarget.Rank)
	removedDispatcher := stockruntime.TopFloorDispatcher{Authority: playtestAuthority{removedActor}, Service: service}
	removedResponse := removedDispatcher.Dispatch(ctx, playtestRequest(removedActor, 280, map[string]any{
		"formation": strconv.FormatInt(removedHero.PartnerID, 10), "enemy_id": removedTarget.Occupant.TableID(), "campaign_type": d.CampaignType,
	}))
	if removedResponse.HTTPStatus != 409 || removedResponse.Body["error_code"] != int64(35026) {
		t.Fatalf("removed normal target response: %+v", removedResponse)
	}
}

func TestI9_10TopFloorTaskStaleOffersAndRevengeNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, hero := topFloorPlayer(t, database, server)
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	clock := &workplaceTime{}
	service.Timed.Binder.Time = clock
	storedHero, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, database, actor.PlayerID, hero.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	clock.at = taskRotationForRule(t, catalog, func(rule d.TaskModeRule) bool {
		return rule.HeroSlots == 1 && !slices.Contains(rule.BannedTables, storedHero.TableID)
	})
	rotation, err := catalog.TaskModes.Rotation(clock.at)
	if err != nil {
		t.Fatal(err)
	}
	rule, found := catalog.TaskModes.Rule(rotation.Mode)
	if !found {
		t.Fatal("task mode rule missing")
	}
	exec(t, database, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(actor.PlayerID))
	earnTaskChallenges(t, database, service, actor, hero, clock)
	defense := d.TaskModeDefense{Heroes: []int64{hero.PartnerID}}
	if rule.ID == d.TaskModeLeader {
		defense.Leader = hero.PartnerID
	}
	view, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil || len(view.Enemies) < 2 {
		t.Fatalf("load task offers: %v", err)
	}
	if err = service.SaveTaskDefense(ctx, actor, defense, op()); err != nil {
		t.Fatal(err)
	}

	removed := view.Enemies[0]
	if !removed.Occupant.IsRobot() {
		t.Fatalf("expected a task robot target: %+v", removed.Occupant)
	}
	exec(t, database, `DELETE FROM top_floor_task_ranks WHERE logical_server_id=$1 AND period_number=$2 AND rank=$3`, int64(server), view.Rotation.Number, removed.Rank)
	dispatcher := stockruntime.TopFloorTaskDispatcher{Authority: playtestAuthority{actor}, Service: service}
	removedResponse := dispatcher.Dispatch(ctx, playtestRequest(actor, 286, map[string]any{
		"formation": strconv.FormatInt(hero.PartnerID, 10), "leader_id": defense.Leader, "enemy_id": removed.Occupant.TableID(),
		"campaign_type": d.TaskModeCampaignType,
	}))
	if removedResponse.HTTPStatus != 409 || removedResponse.Body["error_code"] != int64(35026) {
		t.Fatalf("removed task target response: %+v", removedResponse)
	}

	missingSnapshotTarget := view.Enemies[1]
	taskCommand := func(enemy d.Display, avenge bool) application.TaskStartCommand {
		return application.TaskStartCommand{StartCommand: application.StartCommand{Formation: slices.Clone(defense.Heroes), Enemy: enemy.Occupant.TableID(), Avenge: avenge}, Leader: defense.Leader}
	}
	exec(t, database, `DELETE FROM top_floor_offer_snapshots WHERE player_id=$1 AND scope=$2`, int64(actor.PlayerID), d.OfferScopeSpecial)
	if _, err = service.StartTask(ctx, actor, taskCommand(missingSnapshotTarget, false), op()); !errors.Is(err, d.ErrOfferStale) {
		t.Fatalf("task START without a snapshot: %v", err)
	}
	if scalar(t, database, `SELECT (payload->'player'->>'TicketsLeft')::bigint FROM top_floor_task_players WHERE player_id=$1 AND period_number=$2`, int64(actor.PlayerID), view.Rotation.Number) != 5 {
		t.Fatal("missing task snapshot refusal spent a ticket")
	}

	reissued, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil || len(reissued.Enemies) == 0 {
		t.Fatalf("reissue task offers: %v", err)
	}
	stale := reissued.Enemies[0]
	if err = swapTaskRanks(t, database, server, view.Rotation.Number, stale.Rank, 1); err != nil {
		t.Fatal(err)
	}
	if _, err = service.StartTask(ctx, actor, taskCommand(stale, false), op()); !errors.Is(err, d.ErrOfferStale) {
		t.Fatalf("moved task offer START: %v", err)
	}
	if scalar(t, database, `SELECT (payload->'player'->>'TicketsLeft')::bigint FROM top_floor_task_players WHERE player_id=$1 AND period_number=$2`, int64(actor.PlayerID), view.Rotation.Number) != 5 {
		t.Fatal("stale task offer refusal spent a ticket")
	}

	refreshed, err := service.LoadTask(ctx, actor, op(), true)
	if err != nil || len(refreshed.Enemies) == 0 {
		t.Fatalf("refresh task offers: %v", err)
	}
	bot := refreshed.Enemies[0]
	if !bot.Occupant.IsRobot() {
		t.Fatalf("expected a refreshed task robot target: %+v", bot.Occupant)
	}
	if result, startErr := service.StartTask(ctx, actor, taskCommand(bot, false), op()); startErr != nil || len(result.Report) == 0 {
		t.Fatalf("refreshed task bot START: report=%d err=%v", len(result.Report), startErr)
	}

	period, found, err := (topfloorstore.Store{}).ReadTaskPeriodTx(ctx, database, server, view.Rotation.Number, false)
	if err != nil || !found {
		t.Fatalf("read task period: found=%t err=%v", found, err)
	}
	actorRank, found, err := (topfloorstore.Store{}).TaskRankOfTx(ctx, database, server, period.Rotation.Number, d.Occupant{Player: actor.PlayerID})
	if err != nil || !found || actorRank <= 1 {
		t.Fatalf("read actor task rank: rank=%d found=%t err=%v", actorRank, found, err)
	}
	other, _, otherHero := topFloorPlayer(t, database, server)
	otherRank := period.Ladder.Size + 1
	otherPlayer := d.TaskModePlayer{PeriodNumber: period.Rotation.Number, Player: catalog.NewPlayer(other.PlayerID, server, period.Ladder.ContentRevision, otherRank, clock.at)}
	otherPlayer.Player.Defense = []int64{otherHero.PartnerID}
	if rule.ID == d.TaskModeLeader {
		otherPlayer.Leader = otherHero.PartnerID
	}
	swapTargetRows, err := (topfloorstore.Store{}).TaskRangeTx(ctx, database, server, period.Rotation.Number, actorRank-1, actorRank-1)
	if err != nil || len(swapTargetRows) != 1 {
		t.Fatalf("read revenge rank: %v rows=%d", err, len(swapTargetRows))
	}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = (topfloorstore.Store{}).InsertTaskPlayerTx(ctx, transaction, otherPlayer, period); err == nil {
		err = (topfloorstore.Store{}).AppendTaskPlayerTx(ctx, transaction, server, period.Rotation.Number, otherRank, other.PlayerID)
	}
	if err == nil {
		previous := period.Ladder.StateVersion
		period.Ladder.Size++
		period.Ladder.StateVersion++
		period.Ladder.UpdatedAt = clock.at
		err = (topfloorstore.Store{}).SaveTaskPeriodTx(ctx, transaction, period, previous)
	}
	if err == nil {
		err = (topfloorstore.Store{}).SwapTaskRanksTx(ctx, transaction, server, period.Rotation.Number,
			d.Ranked{Rank: otherRank, Occupant: d.Occupant{Player: other.PlayerID}}, swapTargetRows[0])
	}
	if err != nil {
		transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	taskStore := topfloorstore.Store{}
	records, err := taskStore.TaskRecordsTx(ctx, database, actor.PlayerID)
	if err != nil || len(records) == 0 {
		t.Fatalf("read task fight record: %v records=%d", err, len(records))
	}
	revengeRecord := records[0]
	revengeRecord.Record.Attack = false
	revengeRecord.Record.Win = false
	revengeRecord.Record.Opponent = d.Occupant{Player: other.PlayerID}
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	exec(t, database, `DELETE FROM top_floor_task_records WHERE owner_player_id=$1 AND attempt_id=$2`, int64(actor.PlayerID), revengeRecord.Record.AttemptID.String())
	if err = taskStore.InsertTaskRecordTx(ctx, transaction, revengeRecord, catalog.RecordsMax); err != nil {
		transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	exec(t, database, `DELETE FROM top_floor_offer_snapshots WHERE player_id=$1 AND scope=$2`, int64(actor.PlayerID), d.OfferScopeSpecial)
	clock.at = clock.at.Add(time.Duration(catalog.CooldownSeconds+1) * time.Second)
	revengeCommand := application.TaskStartCommand{StartCommand: application.StartCommand{
		Formation: slices.Clone(defense.Heroes), Enemy: int64(other.PlayerID) % d.RegionStride, Avenge: true,
	}, Leader: defense.Leader}
	if result, startErr := service.StartTask(ctx, actor, revengeCommand, op()); startErr != nil || len(result.Report) == 0 {
		t.Fatalf("task revenge START without an offer snapshot: report=%d err=%v", len(result.Report), startErr)
	}
	latest, found, err := taskStore.LatestTaskFightTx(ctx, database, actor.PlayerID)
	if err != nil || !found || !latest.Fight.Avenge || latest.Fight.Defender != (d.Occupant{Player: other.PlayerID}) {
		t.Fatalf("latest revenge fight: %+v found=%t err=%v", latest.Fight, found, err)
	}
}

func swapTaskRanks(t *testing.T, database *pg.Pool, server identity.LogicalServerID, period, firstRank, secondRank int64) error {
	t.Helper()
	store := topfloorstore.Store{}
	first, err := store.TaskRangeTx(ctx, database, server, period, firstRank, firstRank)
	if err != nil || len(first) != 1 {
		t.Fatalf("task rank %d fixture: %v rows=%d", firstRank, err, len(first))
	}
	second, err := store.TaskRangeTx(ctx, database, server, period, secondRank, secondRank)
	if err != nil || len(second) != 1 {
		t.Fatalf("task rank %d fixture: %v rows=%d", secondRank, err, len(second))
	}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		return err
	}
	defer transaction.Rollback(ctx)
	if err = store.SwapTaskRanksTx(ctx, transaction, server, period, first[0], second[0]); err != nil {
		return err
	}
	return transaction.Commit(ctx)
}
