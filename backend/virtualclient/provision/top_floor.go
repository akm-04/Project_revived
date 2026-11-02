package provision

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const topFloorTaskFixtureRank = 150

// TopFloorTaskRankFixture declares a normal ladder rank inside the special-mode entry limit; it proves no rank climbing.
func TopFloorTaskRankFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-top-floor-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var player, server, rank, robot int64
	if err := pool.QueryRow(requestContext, `SELECT p.player_id, r.logical_server_id, r.rank FROM players p JOIN top_floor_ranks r ON r.player_id=p.player_id WHERE p.account_id=$1`, accountID).Scan(&player, &server, &rank); err != nil {
		return fmt.Errorf("top floor fixture needs a ladder rank: %w", err)
	}
	if err := pool.QueryRow(requestContext, `SELECT robot_team FROM top_floor_ranks WHERE logical_server_id=$1 AND rank=$2`, server, topFloorTaskFixtureRank).Scan(&robot); err != nil {
		return err
	}
	transaction, err := pool.Begin(requestContext, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(requestContext)
	own := domain.Ranked{Rank: rank, Occupant: domain.Occupant{Player: identity.PlayerID(player)}}
	target := domain.Ranked{Rank: topFloorTaskFixtureRank, Occupant: domain.Occupant{Robot: robot}}
	if err := (topfloorstore.Store{}).SwapTx(requestContext, transaction, identity.LogicalServerID(server), own, target); err != nil {
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
