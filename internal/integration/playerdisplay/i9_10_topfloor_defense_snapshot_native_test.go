//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"errors"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// D487: a new attack needs a currently valid saved defense and spends nothing
// when it is refused; a saved defense admits and an exact retry replays.
func TestI9_10TopFloorDefenseRequiredNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	actor, revision, hero := topFloorPlayer(t, pool, server)
	catalog, err := (contentstore.Store{Queryer: pool}).TopFloorCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Frozen(time.Now()) {
		t.Skip("21:00-21:30 GMT+8 settlement freeze admits no START")
	}
	view, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	enemy := view.Enemies[0]
	command := app.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: enemy.Occupant.TableID()}
	tickets := func() int64 {
		return scalar(t, pool, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID))
	}
	if _, err = service.Start(ctx, actor, command, op()); !errors.Is(err, d.ErrDefenseRequired) {
		t.Fatalf("attack without a saved defense: %v", err)
	}
	if tickets() != 5 || scalar(t, pool, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(actor.PlayerID)) != 0 ||
		scalar(t, pool, `SELECT fights FROM top_floor_players WHERE player_id=$1`, int64(actor.PlayerID)) != 0 ||
		scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(actor.PlayerID)) != view.Rank {
		t.Fatalf("refused admission spent or moved state: tickets=%d rank=%d", tickets(), scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(actor.PlayerID)))
	}

	if err = service.SaveDefense(ctx, actor, []int64{hero.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	fight, err := service.Start(ctx, actor, command, op())
	if err != nil || fight.Report == nil || tickets() != 4 {
		t.Fatalf("saved defense must admit: report=%d tickets=%d err=%v", len(fight.Report), tickets(), err)
	}
	replay, err := service.Start(ctx, actor, command, op())
	if err != nil || string(replay.Report) != string(fight.Report) || replay.Win != fight.Win || tickets() != 4 ||
		scalar(t, pool, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(actor.PlayerID)) != 1 {
		t.Fatalf("exact retry must replay once: tickets=%d err=%v", tickets(), err)
	}
}

// D488: the issued offer snapshot refuses a moved challenger or selected target
// with the stock stale-rank error, while an unrelated rank change is allowed.
func TestI9_10TopFloorStaleOfferSnapshotNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)

	actor, revision, hero := topFloorPlayer(t, pool, server)
	catalog, err := (contentstore.Store{Queryer: pool}).TopFloorCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Frozen(time.Now()) {
		t.Skip("21:00-21:30 GMT+8 settlement freeze admits no START")
	}
	view, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	if err = service.SaveDefense(ctx, actor, []int64{hero.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	target := view.Enemies[0]
	if err = service.PreFight(ctx, actor, target.Occupant.TableID()); err != nil {
		t.Fatalf("fresh preflight: %v", err)
	}
	// An unrelated rank change must not invalidate the issued offer.
	if err = swapRanks(t, pool, server, 500, 501); err != nil {
		t.Fatal(err)
	}
	if err = service.PreFight(ctx, actor, target.Occupant.TableID()); err != nil {
		t.Fatalf("unrelated rank change refused preflight: %v", err)
	}
	if _, err = service.Start(ctx, actor, app.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: target.Occupant.TableID()}, op()); err != nil {
		t.Fatalf("unrelated rank change refused START: %v", err)
	}

	// A third player taking the selected target's rank makes the snapshot stale.
	stale, _, staleHero := topFloorPlayer(t, pool, server)
	staleView, err := service.Load(ctx, stale, op())
	if err != nil {
		t.Fatal(err)
	}
	if err = service.SaveDefense(ctx, stale, []int64{staleHero.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	staleTarget := staleView.Enemies[0]
	if err = swapRanks(t, pool, server, staleTarget.Rank, 900); err != nil {
		t.Fatal(err)
	}
	tickets := func() int64 {
		return scalar(t, pool, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(stale.PlayerID))
	}
	if err = service.PreFight(ctx, stale, staleTarget.Occupant.TableID()); !errors.Is(err, d.ErrOfferStale) {
		t.Fatalf("stale preflight: %v", err)
	}
	if _, err = service.Start(ctx, stale, app.StartCommand{Formation: []int64{staleHero.PartnerID}, Enemy: staleTarget.Occupant.TableID()}, op()); !errors.Is(err, d.ErrOfferStale) {
		t.Fatalf("stale START: %v", err)
	}
	if tickets() != 5 || scalar(t, pool, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(stale.PlayerID)) != 0 {
		t.Fatalf("stale refusal spent state: tickets=%d", tickets())
	}

	// Refreshing the offers issues a new snapshot and admits again.
	refreshed, err := service.Load(ctx, stale, op())
	if err != nil || len(refreshed.Enemies) == 0 {
		t.Fatalf("refresh after stale: %v", err)
	}
	if _, err = service.Start(ctx, stale, app.StartCommand{Formation: []int64{staleHero.PartnerID}, Enemy: refreshed.Enemies[0].Occupant.TableID()}, op()); err != nil {
		t.Fatalf("refresh must recover: %v", err)
	}
	if count := scalar(t, pool, `SELECT count(*) FROM top_floor_offer_snapshots WHERE player_id=$1 AND scope=$2`, int64(stale.PlayerID), d.OfferScopeNormal); count != 1 {
		t.Fatalf("snapshots per scope %d", count)
	}
}

// D488: two attackers issued the same target. While the target's rank is
// unchanged the second is admitted; once it moved the second is refused with
// the stale-rank error and spends no ticket.
func TestI9_10TopFloorTwoAttackersSameTargetNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	actorA, _, heroA := topFloorPlayer(t, pool, server)
	actorB, _, heroB := topFloorPlayer(t, pool, server)
	target, _, targetHero := topFloorPlayer(t, pool, server)
	if _, err := service.Load(ctx, actorA, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Load(ctx, actorB, op()); err != nil {
		t.Fatal(err)
	}
	targetView, err := service.Load(ctx, target, op())
	if err != nil {
		t.Fatal(err)
	}
	if err = service.SaveDefense(ctx, actorA, []int64{heroA.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	if err = service.SaveDefense(ctx, actorB, []int64{heroB.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	if err = service.SaveDefense(ctx, target, []int64{targetHero.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	targetOccupant := d.Occupant{Player: target.PlayerID}
	targetRank := targetView.Rank
	forceOffer(t, pool, server, actorA.PlayerID, targetRank, targetOccupant)
	forceOffer(t, pool, server, actorB.PlayerID, targetRank, targetOccupant)

	if _, err = service.Start(ctx, actorA, app.StartCommand{Formation: []int64{heroA.PartnerID}, Enemy: int64(target.PlayerID) % d.RegionStride}, op()); err != nil {
		t.Fatalf("first attacker: %v", err)
	}
	if current := scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(target.PlayerID)); current == targetRank {
		if _, err = service.Start(ctx, actorB, app.StartCommand{Formation: []int64{heroB.PartnerID}, Enemy: int64(target.PlayerID) % d.RegionStride}, op()); err != nil {
			t.Fatalf("unchanged target must admit the second attacker: %v", err)
		}
	} else {
		if _, err = service.Start(ctx, actorB, app.StartCommand{Formation: []int64{heroB.PartnerID}, Enemy: int64(target.PlayerID) % d.RegionStride}, op()); !errors.Is(err, d.ErrOfferStale) {
			t.Fatalf("moved target must refuse the second attacker: %v", err)
		}
	}

	// A second pair: the target is moved after the first attack settles, so the
	// second attacker's issued snapshot is stale.
	actorC, _, heroC := topFloorPlayer(t, pool, server)
	actorD, _, heroD := topFloorPlayer(t, pool, server)
	moved, _, movedHero := topFloorPlayer(t, pool, server)
	if _, err = service.Load(ctx, actorC, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = service.Load(ctx, actorD, op()); err != nil {
		t.Fatal(err)
	}
	movedView, err := service.Load(ctx, moved, op())
	if err != nil {
		t.Fatal(err)
	}
	for _, save := range []struct {
		actor identity.ActorContext
		hero  int64
	}{{actorC, heroC.PartnerID}, {actorD, heroD.PartnerID}, {moved, movedHero.PartnerID}} {
		if err = service.SaveDefense(ctx, save.actor, []int64{save.hero}, 0, op()); err != nil {
			t.Fatal(err)
		}
	}
	forceOffer(t, pool, server, actorC.PlayerID, movedView.Rank, d.Occupant{Player: moved.PlayerID})
	forceOffer(t, pool, server, actorD.PlayerID, movedView.Rank, d.Occupant{Player: moved.PlayerID})
	if _, err = service.Start(ctx, actorC, app.StartCommand{Formation: []int64{heroC.PartnerID}, Enemy: int64(moved.PlayerID) % d.RegionStride}, op()); err != nil {
		t.Fatalf("first attacker of the moved target: %v", err)
	}
	if err = swapRanks(t, pool, server, scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(moved.PlayerID)), 900); err != nil {
		t.Fatal(err)
	}
	ticketsD := scalar(t, pool, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actorD.PlayerID))
	if _, err = service.Start(ctx, actorD, app.StartCommand{Formation: []int64{heroD.PartnerID}, Enemy: int64(moved.PlayerID) % d.RegionStride}, op()); !errors.Is(err, d.ErrOfferStale) {
		t.Fatalf("second attacker of a moved target: %v", err)
	}
	if scalar(t, pool, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(actorD.PlayerID)) != ticketsD ||
		scalar(t, pool, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(actorD.PlayerID)) != 0 {
		t.Fatal("stale second attacker spent state")
	}
}

// forceOffer writes the offer rows and the rank snapshot an offer response would
// have issued, for tests that need both attackers to see one target.
func forceOffer(t *testing.T, database *pg.Pool, server identity.LogicalServerID, challenger identity.PlayerID, targetRank int64, target d.Occupant) {
	t.Helper()
	offered, err := json.Marshal([]d.Occupant{target})
	if err != nil {
		t.Fatal(err)
	}
	exec(t, database, `UPDATE top_floor_players SET offered=$2::jsonb,state_version=state_version+1 WHERE player_id=$1`, int64(challenger), string(offered))
	challengerRank := scalar(t, database, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(challenger))
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err = (topfloorstore.Store{}).SaveOfferSnapshotTx(ctx, transaction, d.OfferSnapshot{Player: challenger, Server: server, Scope: d.OfferScopeNormal, Generation: 0,
		ChallengerRank: challengerRank, Offers: []d.Ranked{{Rank: targetRank, Occupant: target}}, UpdatedAt: time.Now().UTC()}); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

// swapRanks exchanges two ladder ranks, standing in for a settled battle or a
// third player taking a rank.
func swapRanks(t *testing.T, database *pg.Pool, server identity.LogicalServerID, first, second int64) error {
	t.Helper()
	store := topfloorstore.Store{}
	rows, err := store.RangeTx(ctx, database, server, first, first)
	if err != nil || len(rows) != 1 {
		t.Fatalf("rank %d fixture: %v %d", first, err, len(rows))
	}
	other, err := store.RangeTx(ctx, database, server, second, second)
	if err != nil || len(other) != 1 {
		t.Fatalf("rank %d fixture: %v %d", second, err, len(other))
	}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		return err
	}
	defer transaction.Rollback(ctx)
	if err = store.SwapTx(ctx, transaction, server, rows[0], other[0]); err != nil {
		return err
	}
	return transaction.Commit(ctx)
}
