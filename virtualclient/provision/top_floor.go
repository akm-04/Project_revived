package provision

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const topFloorTaskFixtureRank = 150
const topFloorTaskOpponentRobot = 1

// TopFloorTaskRankFixture declares a normal ladder rank inside the special-mode entry limit; it proves no rank climbing.
func TopFloorTaskRankFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-top-floor-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var player, server, rank, robot, occupantPlayer int64
	if err := pool.QueryRow(requestContext, `SELECT p.player_id, r.logical_server_id, r.rank FROM players p JOIN top_floor_ranks r ON r.player_id=p.player_id WHERE p.account_id=$1`, accountID).Scan(&player, &server, &rank); err != nil {
		return fmt.Errorf("top floor fixture needs a ladder rank: %w", err)
	}
	if rank == topFloorTaskFixtureRank {
		return nil
	}
	// An earlier scenario can leave a human at the fixture rank, where robot_team is NULL.
	if err := pool.QueryRow(requestContext, `SELECT COALESCE(robot_team,0), COALESCE(player_id,0) FROM top_floor_ranks WHERE logical_server_id=$1 AND rank=$2`, server, topFloorTaskFixtureRank).Scan(&robot, &occupantPlayer); err != nil {
		return err
	}
	targetOccupant := domain.Occupant{Player: identity.PlayerID(occupantPlayer)}
	if robot > 0 {
		targetOccupant = domain.Occupant{Robot: robot}
	}
	if !targetOccupant.Valid() {
		return fmt.Errorf("top floor fixture rank %d has no occupant", topFloorTaskFixtureRank)
	}
	transaction, err := pool.Begin(requestContext, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(requestContext)
	own := domain.Ranked{Rank: rank, Occupant: domain.Occupant{Player: identity.PlayerID(player)}}
	target := domain.Ranked{Rank: topFloorTaskFixtureRank, Occupant: targetOccupant}
	if err := (topfloorstore.Store{}).SwapTx(requestContext, transaction, identity.LogicalServerID(server), own, target); err != nil {
		return err
	}
	return transaction.Commit(requestContext)
}

// TopFloorNoDefenseFixture clears the D511 preset defense written by the first
// ladder entry, so the D487 refusal path stays reachable for a stock client that
// always owns preset girl 10001001.
func TopFloorNoDefenseFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-top-floor-no-defense"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var player int64
	if err := pool.QueryRow(requestContext, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&player); err != nil {
		return fmt.Errorf("top floor no-defense fixture needs a player: %w", err)
	}
	transaction, err := pool.Begin(requestContext, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(requestContext)
	store := topfloorstore.Store{}
	saved, found, err := store.ReadPlayerTx(requestContext, transaction, identity.PlayerID(player), true)
	if err != nil {
		return err
	}
	if !found {
		return fmt.Errorf("top floor no-defense fixture needs a ladder entry")
	}
	if len(saved.Defense) == 0 && saved.DefenseSetAt == nil {
		return transaction.Commit(requestContext)
	}
	next := saved
	next.Defense, next.DefensePet, next.DefenseSetAt = []int64{}, 0, nil
	next.StateVersion, next.UpdatedAt = saved.StateVersion+1, time.Now().UTC()
	if err := store.SavePlayerTx(requestContext, transaction, next, saved.StateVersion); err != nil {
		return err
	}
	return transaction.Commit(requestContext)
}

// TopFloorTaskOpponentFixture seeds one robot occupant in an empty special
// period, so a lone test account has a better-ranked mode target. D512 starts a
// new period empty; an earlier admitted player is already a valid target.
func TopFloorTaskOpponentFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-top-floor-task-opponent"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var server int64
	if err := pool.QueryRow(requestContext, `SELECT logical_server_id FROM players WHERE account_id=$1`, accountID).Scan(&server); err != nil {
		return fmt.Errorf("top floor task opponent fixture needs a player: %w", err)
	}
	contents := contentstore.Store{Queryer: pool}
	revision, err := contents.ActiveRevision(requestContext, pool)
	if err != nil {
		return err
	}
	catalog, err := contents.TopFloorCatalogTx(requestContext, pool, revision)
	if err != nil {
		return err
	}
	if catalog.TaskModes == nil {
		return fmt.Errorf("top floor task opponent fixture needs the task catalog")
	}
	now := time.Now().UTC()
	proposal, err := catalog.TaskModes.NewPeriod(identity.LogicalServerID(server), revision, now)
	if err != nil {
		return err
	}
	store := topfloorstore.Store{}
	transaction, err := pool.Begin(requestContext, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(requestContext)
	period, found, err := store.ReadTaskPeriodTx(requestContext, transaction, identity.LogicalServerID(server), proposal.Rotation.Number, true)
	if err != nil {
		return err
	}
	if !found {
		if err := store.CreateTaskPeriodTx(requestContext, transaction, proposal); err != nil {
			return err
		}
		period = proposal
	}
	if period.Ladder.Size > 0 {
		return transaction.Commit(requestContext)
	}
	if _, err := transaction.Exec(requestContext, `INSERT INTO top_floor_task_ranks(logical_server_id,period_number,rank,robot_team)VALUES($1,$2,1,$3)`, server, period.Rotation.Number, topFloorTaskOpponentRobot); err != nil {
		return err
	}
	seeded := period
	seeded.Ladder.Size, seeded.Ladder.StateVersion, seeded.Ladder.UpdatedAt = 1, period.Ladder.StateVersion+1, now
	if err := store.SaveTaskPeriodTx(requestContext, transaction, seeded, period.Ladder.StateVersion); err != nil {
		return err
	}
	return transaction.Commit(requestContext)
}

// OneOnOneCoolingFixture declares a just-fought 1on1 player; a lone test account has no opponent to fight for real.
func OneOnOneCoolingFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-top-floor-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var player int64
	if err := pool.QueryRow(requestContext, `UPDATE one_on_one_players o SET last_fight_at=now(), state_version=o.state_version+1 FROM players p WHERE o.player_id=p.player_id AND p.account_id=$1 RETURNING o.player_id`, accountID).Scan(&player); err != nil {
		return fmt.Errorf("one on one fixture needs a loaded player: %w", err)
	}
	return nil
}
