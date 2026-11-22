//go:build postgres

package playerdisplay_test

import (
	"os"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	petapp "gxb.local/backend/v2/internal/application/petcampaign"
	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type capacityActor struct {
	actor identity.ActorContext
	hero  character.HeroRef
}

func capacityActors(t *testing.T, pool *pg.Pool, server identity.LogicalServerID, count int) []capacityActor {
	t.Helper()
	out := make([]capacityActor, 0, count)
	for range count {
		actor, _, hero := topFloorPlayer(t, pool, server)
		out = append(out, capacityActor{actor: actor, hero: hero})
	}
	return out
}

// Concurrent first entries by distinct players must all succeed: the ladder root
// is a shared counter, so entry waits on it instead of aborting on a stale read.
func TestI9_10TopFloorConcurrentEntryNative(t *testing.T) {
	pool := pool(t)
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	const players = 16
	actors := capacityActors(t, pool, server, players)
	begin := make(chan struct{})
	errs := make(chan error, players)
	for _, actor := range actors {
		go func(a identity.ActorContext) {
			<-begin
			_, err := service.Load(ctx, a, op())
			errs <- err
		}(actor.actor)
	}
	close(begin)
	for range players {
		if err := <-errs; err != nil {
			t.Fatalf("concurrent entry failed: %v", err)
		}
	}
	size := scalar(t, pool, `SELECT size FROM top_floor_ladders WHERE logical_server_id=$1`, int64(server))
	if size != d.RobotTeams+players {
		t.Fatalf("ladder size %d want %d", size, d.RobotTeams+players)
	}
	if got := scalar(t, pool, `SELECT count(DISTINCT player_id) FROM top_floor_ranks WHERE logical_server_id=$1 AND player_id IS NOT NULL`, int64(server)); got != players {
		t.Fatalf("ranked players %d want %d", got, players)
	}
}

// A START for one player must not queue behind another transaction holding the
// server ladder root: admission reads the ladder but does not mutate it.
func TestI9_10TopFloorStartDoesNotWaitOnLadderRootNative(t *testing.T) {
	pool := pool(t)
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	challenger, _, challengerHero := topFloorPlayer(t, pool, server)
	other, _, _ := topFloorPlayer(t, pool, server)
	view, err := service.Load(ctx, challenger, op())
	if err != nil {
		t.Fatal(err)
	}
	if _, err = service.Load(ctx, other, op()); err != nil {
		t.Fatal(err)
	}
	if err = service.SaveDefense(ctx, challenger, []int64{challengerHero.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	holder, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer holder.Rollback(ctx)
	var locked int64
	// SaveLadderTx updates only non-key columns, which is FOR NO KEY UPDATE and
	// conflicts with a START's own FOR UPDATE read but not with its FK share locks.
	if err = holder.QueryRow(ctx, `SELECT logical_server_id FROM top_floor_ladders WHERE logical_server_id=$1 FOR NO KEY UPDATE`, int64(server)).Scan(&locked); err != nil {
		t.Fatal(err)
	}
	stalled := service
	stalled.Combat = stalledCombat{service.Combat}
	done := make(chan error, 1)
	go func() {
		_, startErr := stalled.Start(ctx, challenger, app.StartCommand{Formation: []int64{challengerHero.PartnerID}, Enemy: view.Enemies[0].Occupant.TableID()}, op())
		done <- startErr
	}()
	select {
	case startErr := <-done:
		if startErr != nil {
			t.Fatalf("START while the ladder root is held: %v", startErr)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("START waited on the shared ladder root")
	}
	if err = holder.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
}

// Concurrent STARTS by distinct players must all be admitted.
func TestI9_10TopFloorConcurrentStartNative(t *testing.T) {
	pool := pool(t)
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	const players = 8
	type ready struct {
		actor   identity.ActorContext
		command app.StartCommand
	}
	prepared := make([]ready, 0, players)
	for range players {
		actor, _, hero := topFloorPlayer(t, pool, server)
		view, err := service.Load(ctx, actor, op())
		if err != nil {
			t.Fatal(err)
		}
		if err = service.SaveDefense(ctx, actor, []int64{hero.PartnerID}, 0, op()); err != nil {
			t.Fatal(err)
		}
		prepared = append(prepared, ready{actor: actor, command: app.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: view.Enemies[0].Occupant.TableID()}})
	}
	begin := make(chan struct{})
	var wait sync.WaitGroup
	errs := make(chan error, players)
	for _, item := range prepared {
		wait.Add(1)
		go func(item ready) {
			defer wait.Done()
			<-begin
			if _, err := service.Start(ctx, item.actor, item.command, op()); err != nil {
				errs <- err
			}
		}(item)
	}
	close(begin)
	wait.Wait()
	close(errs)
	for err := range errs {
		t.Fatalf("concurrent START failed: %v", err)
	}
	for _, item := range prepared {
		if got := scalar(t, pool, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(item.actor.PlayerID)); got != 1 {
			t.Fatalf("player %d admitted fights %d", item.actor.PlayerID, got)
		}
		if got := scalar(t, pool, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(item.actor.PlayerID)); got != 4 {
			t.Fatalf("player %d tickets left %d", item.actor.PlayerID, got)
		}
	}
}

// Concurrent sky tower STARTS by distinct players must all be admitted. Its
// combat input freeze reads the player's roster and content; under SERIALIZABLE
// those reads become predicate locks that abort unrelated players' starts.
func TestI9_10PetCampaignConcurrentStartNative(t *testing.T) {
	// A pool wide enough that the pool queue cannot mask the isolation effect
	// being measured; production width is unchanged.
	pool, err := pg.Open(ctx, os.Getenv("GXB_I7B6A_DSN"), pg.PoolSettings{MaxConns: 64, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	mode := petCampaignMode(t, pool, clock)
	revision := installed(t, pool)
	catalog, err := (contentstore.Store{Queryer: pool}).PetCampaignCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	floor, found := catalog.Floor(1, 1)
	if !found {
		t.Fatal("pet campaign floor 1 missing")
	}
	const players = 48
	actors := make([]identity.ActorContext, 0, players)
	for range players {
		actor := bornActor(t, pool)
		compositeLevel(t, pool, actor, revision, 100)
		bornHero(t, pool, actor, revision, 10001001, 1)
		if _, err = mode.Load(ctx, actor, op()); err != nil {
			t.Fatal("load", err)
		}
		actors = append(actors, actor)
	}
	begin := make(chan struct{})
	errs := make(chan error, players)
	for _, actor := range actors {
		go func(a identity.ActorContext) {
			<-begin
			_, startErr := mode.Start(ctx, a, petapp.Fight{Campaign: floor.ID, Formation: []int64{1, 0, 0, 0, 0}}, op())
			errs <- startErr
		}(actor)
	}
	close(begin)
	for range players {
		if err := <-errs; err != nil {
			t.Fatalf("concurrent pet campaign START failed: %v", err)
		}
	}
}
