//go:build postgres

package playerdisplay_test

import (
	"slices"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// taskDefense births the five owned heroes a leader-mode special fight requires.
func taskDefense(t *testing.T, database *pg.Pool, actor identity.ActorContext, revision string, base int64) []int64 {
	t.Helper()
	partners := make([]int64, 0, 5)
	for index := int64(0); index < 5; index++ {
		born := bornHeroCard(t, database, actor, revision, 10001002+index, 10001002+index, base+index)
		partners = append(partners, born.PartnerID)
	}
	return partners
}

// TestClosureE2TopFloorReplayIgnoresPetNative is the I8_PARENT_CONTRACT_V1
// generation_supersede rule 2 case for MID 280: an open attempt for the same
// enemy replays its frozen START when only the pet changed, and a settled
// attempt still replays only the same formation and pet inside the window.
func TestClosureE2TopFloorReplayIgnoresPetNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, first := topFloorPlayer(t, database, server)
	exec(t, database, `INSERT INTO player_pet_roots(player_id,next_pet_id,state_version,created_at,updated_at)VALUES($1,1,1,clock_timestamp(),clock_timestamp())ON CONFLICT(player_id)DO NOTHING`, int64(actor.PlayerID))
	egg := must((contentstore.Store{Queryer: database}).PetAcquisitionTx(ctx, database, revision, genuinePetTable))(t, "pet policy").EggItemID
	grantGenuine(t, database, actor, revision, "closure e2 pet", []grant.Line{{Kind: grant.StackItem, ItemID: egg, Amount: 1}, {Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 1000}})
	pets := genuinePetService(database)
	owned := must(pets.Summon(ctx, actor, genuinePetTable, op()))(t, "pet summon")
	must(pets.CleanCD(ctx, actor, owned.PetID, op()))(t, "pet hatch")
	// A fixed decision instant, set after the fixture rows, keeps the one-minute
	// settled window deterministic across the real resolver run.
	service.Timed.Binder.Time = &workplaceTime{at: time.Now().UTC()}
	view, err := service.Load(ctx, actor, op())
	if err != nil || len(view.Enemies) == 0 {
		t.Fatalf("load offers: %v", err)
	}
	if err = service.SaveDefense(ctx, actor, []int64{first.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	enemy := view.Enemies[0].Occupant.TableID()
	store := topfloorstore.Store{}
	stalled := service
	stalled.Combat = stalledCombat{service.Combat}
	pending, err := stalled.Start(ctx, actor, app.StartCommand{Formation: []int64{first.PartnerID}, PetID: owned.PetID, Enemy: enemy}, op())
	if err != nil || pending.Report != nil {
		t.Fatalf("first pending START report=%v err=%v", pending.Report, err)
	}
	replay, err := stalled.Start(ctx, actor, app.StartCommand{Formation: []int64{first.PartnerID}, Enemy: enemy}, op())
	if err != nil {
		t.Fatalf("same-enemy START without the pet: %v", err)
	}
	latest, found, err := store.LatestFightTx(ctx, database, actor.PlayerID)
	if err != nil || !found || latest.Status != domain.StatusStarted || latest.PetID != owned.PetID {
		t.Fatalf("frozen fight %+v found=%v err=%v", latest, found, err)
	}
	if !slices.Equal(latest.Formation, []int64{first.PartnerID}) || replay.Report != nil || len(replay.Formation) != 1 || formValue(t, replay.Formation[0], "partner_id") != first.PartnerID {
		t.Fatalf("frozen START formation=%+v report=%v", replay.Formation, replay.Report)
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(actor.PlayerID)) != 1 ||
		scalar(t, database, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID)) != 4 {
		t.Fatal("a replayed START staged a fight or spent a ticket")
	}
	frozenAttempt := latest.AttemptID
	settled, err := service.Start(ctx, actor, app.StartCommand{Formation: []int64{first.PartnerID}, Enemy: enemy}, op())
	if err != nil || len(settled.Report) == 0 {
		t.Fatalf("settle the frozen attempt: %v report=%d", err, len(settled.Report))
	}
	latest, found, err = store.LatestFightTx(ctx, database, actor.PlayerID)
	if err != nil || !found || latest.AttemptID != frozenAttempt || latest.Status != domain.StatusSettled {
		t.Fatalf("settled fight %+v found=%v err=%v", latest, found, err)
	}
	same, err := service.Start(ctx, actor, app.StartCommand{Formation: []int64{first.PartnerID}, PetID: owned.PetID, Enemy: enemy}, op())
	if err != nil || len(same.Report) == 0 || string(same.Report) != string(settled.Report) {
		t.Fatalf("settled replay with the same pet: %v report=%d", err, len(same.Report))
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(actor.PlayerID)) != 1 ||
		scalar(t, database, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID)) != 4 {
		t.Fatal("a settled replay staged a fight or spent a ticket")
	}
	// Precondition: with fewer tickets the 300 s cooldown would refuse a new
	// START before the settled-window choice check can be judged.
	exec(t, database, `UPDATE top_floor_players SET tickets_left=5 WHERE player_id=$1`, int64(actor.PlayerID))
	fresh, err := service.Start(ctx, actor, app.StartCommand{Formation: []int64{first.PartnerID}, Enemy: enemy}, op())
	if err != nil || len(fresh.Report) == 0 {
		t.Fatalf("settled START with another pet must be a new admission: %v report=%d", err, len(fresh.Report))
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1 AND attempt_id<>$2`, int64(actor.PlayerID), frozenAttempt.String()) != 1 ||
		scalar(t, database, `SELECT pet_id FROM top_floor_fights WHERE challenger_id=$1 AND attempt_id<>$2`, int64(actor.PlayerID), frozenAttempt.String()) != 0 {
		t.Fatal("another pet did not admit its own fight")
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(actor.PlayerID)) != 2 ||
		scalar(t, database, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID)) != 4 {
		t.Fatal("a settled START with another pet did not admit a new fight")
	}
}

// TestClosureE2TopFloorTaskReplayIgnoresLeaderNative is generation_supersede
// rule 2 for MID 286: an open attempt for the same enemy replays its frozen
// START when only the leader changed, and a settled attempt replays only the
// same formation, pet and leader inside the window.
func TestClosureE2TopFloorTaskReplayIgnoresLeaderNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, first := topFloorPlayer(t, database, server)
	heroes := []int64{first.PartnerID}
	for table := int64(10001002); len(heroes) < 5; table++ {
		definition := collectionResources(t, database, actor, revision, table)
		born, err := ownerSummoner(database).SummonNormal(ctx, actor, table, definition.Template.FragmentItemID, definition.FragmentCount, op())
		if err != nil {
			t.Fatal(err)
		}
		heroes = append(heroes, born.Ref().PartnerID)
	}
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	clock := &workplaceTime{at: taskRotationForRule(t, catalog, func(rule domain.TaskModeRule) bool { return rule.LeaderAllowed })}
	service.Timed.Binder.Time = clock
	exec(t, database, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(actor.PlayerID))
	current, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	if err = service.SaveDefense(ctx, actor, []int64{first.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	// D512 entry: the actor must hold a normal rank inside EntryRank 200 to be
	// admitted to the special ladder.
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	store := topfloorstore.Store{}
	if err = store.SwapTx(ctx, transaction, server, domain.Ranked{Rank: current.Rank, Occupant: domain.Occupant{Player: actor.PlayerID}}, domain.Ranked{Rank: 200, Occupant: domain.Occupant{Robot: domain.RobotTeams + 1 - 200}}); err != nil {
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
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for rank := int64(1); rank <= 3; rank++ {
		opponent, _, _ := topFloorPlayer(t, database, server)
		defense := taskDefense(t, database, opponent, revision, rank*10+1)
		opponentPlayer := catalog.NewPlayer(opponent.PlayerID, server, revision, rank, clock.at)
		opponentPlayer.Defense = defense
		transaction, err = database.Begin(ctx, tx.Options{})
		if err != nil {
			t.Fatal(err)
		}
		if err = store.InsertTaskPlayerTx(ctx, transaction, domain.TaskModePlayer{Player: opponentPlayer, PeriodNumber: period.Rotation.Number, Leader: defense[0]}, period); err == nil {
			err = store.AppendTaskPlayerTx(ctx, transaction, server, period.Rotation.Number, rank, opponent.PlayerID)
		}
		if err != nil {
			transaction.Rollback(ctx)
			t.Fatal(err)
		}
		if err = transaction.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	period.Ladder.Size, period.Ladder.StateVersion, period.Ladder.UpdatedAt = 3, 2, clock.at
	if err = store.SaveTaskPeriodTx(ctx, transaction, period, 1); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	taskView, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil || len(taskView.Enemies) == 0 {
		t.Fatalf("load special: %v enemies=%d", err, len(taskView.Enemies))
	}
	if err = service.SaveTaskDefense(ctx, actor, domain.TaskModeDefense{Heroes: heroes, Leader: heroes[0]}, op()); err != nil {
		t.Fatal(err)
	}
	firstCommand := app.TaskStartCommand{StartCommand: app.StartCommand{Formation: heroes, Enemy: taskView.Enemies[0].Occupant.TableID()}, Leader: heroes[0]}
	secondCommand := firstCommand
	secondCommand.Leader = heroes[1]
	taskFights := func() int64 {
		return scalar(t, database, `SELECT count(*) FROM top_floor_task_fights WHERE challenger_id=$1`, int64(actor.PlayerID))
	}
	taskTickets := func() int64 {
		return scalar(t, database, `SELECT (payload->'player'->>'TicketsLeft')::int8 FROM top_floor_task_players WHERE player_id=$1`, int64(actor.PlayerID))
	}
	stalled := service
	stalled.Combat = stalledCombat{service.Combat}
	pending, err := stalled.StartTask(ctx, actor, firstCommand, op())
	if err != nil || pending.Report != nil {
		t.Fatalf("first pending START report=%v err=%v", pending.Report, err)
	}
	replay, err := stalled.StartTask(ctx, actor, secondCommand, op())
	if err != nil {
		t.Fatalf("same-enemy START with another leader: %v", err)
	}
	latest, found, err := store.LatestTaskFightTx(ctx, database, actor.PlayerID)
	if err != nil || !found || latest.Fight.Status != domain.StatusStarted || !slices.Equal(latest.Fight.Formation, heroes) {
		t.Fatalf("frozen fight %+v found=%v err=%v", latest, found, err)
	}
	if replay.Report != nil || len(replay.Formation) != len(pending.Formation) || taskFights() != 1 || taskTickets() != 4 {
		t.Fatalf("frozen START formation=%d report=%v fights=%d tickets=%d", len(replay.Formation), replay.Report, taskFights(), taskTickets())
	}
	frozenAttempt := latest.Fight.AttemptID
	settled, err := service.StartTask(ctx, actor, secondCommand, op())
	if err != nil || len(settled.Report) == 0 {
		t.Fatalf("settle the frozen attempt: %v report=%d", err, len(settled.Report))
	}
	latest, found, err = store.LatestTaskFightTx(ctx, database, actor.PlayerID)
	if err != nil || !found || latest.Fight.AttemptID != frozenAttempt || latest.Fight.Status != domain.StatusSettled {
		t.Fatalf("settled fight %+v found=%v err=%v", latest, found, err)
	}
	same, err := service.StartTask(ctx, actor, firstCommand, op())
	if err != nil || len(same.Report) == 0 || string(same.Report) != string(settled.Report) {
		t.Fatalf("settled replay with the same leader: %v report=%d", err, len(same.Report))
	}
	if taskFights() != 1 || taskTickets() != 4 {
		t.Fatalf("settled replay staged fights=%d tickets=%d", taskFights(), taskTickets())
	}
	// Precondition: with fewer tickets the 300 s cooldown would refuse a new
	// START before the settled-window choice check can be judged.
	exec(t, database, `UPDATE top_floor_task_players SET payload=jsonb_set(payload,'{player,TicketsLeft}',to_jsonb(5::bigint)) WHERE player_id=$1`, int64(actor.PlayerID))
	fresh, err := service.StartTask(ctx, actor, secondCommand, op())
	if err != nil || len(fresh.Report) == 0 {
		t.Fatalf("settled START with another leader must be a new admission: %v report=%d", err, len(fresh.Report))
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_task_fights WHERE challenger_id=$1 AND attempt_id<>$2`, int64(actor.PlayerID), frozenAttempt.String()) != 1 ||
		scalar(t, database, `SELECT (payload->>'leader')::int8 FROM top_floor_task_fights WHERE challenger_id=$1 AND attempt_id<>$2`, int64(actor.PlayerID), frozenAttempt.String()) != heroes[1] {
		t.Fatal("another leader did not admit its own fight")
	}
	if taskFights() != 2 || taskTickets() != 4 {
		t.Fatalf("settled START with another leader did not admit fights=%d tickets=%d", taskFights(), taskTickets())
	}
}
