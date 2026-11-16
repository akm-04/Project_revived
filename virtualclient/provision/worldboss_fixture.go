package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
)

// WorldBossAttemptFixture leaves one daily world boss attempt so the stock UI
// reaches the purchase button after one battle. It is a declared precondition,
// not proof of a genuinely exhausted day.
//
// shortcut: the fixture writes the world boss player row directly because the
// stock client cannot spend attempts without a full local battle; upgrade when
// the client gains an attempt-only admission path.
func WorldBossAttemptFixture(ctx context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-worldboss-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var playerID, day int64
	if err := pool.QueryRow(ctx, `SELECT player_id,floor((extract(epoch FROM clock_timestamp())+28800-18000)/86400)::bigint FROM players WHERE account_id=$1`, accountID).Scan(&playerID, &day); err != nil {
		return fmt.Errorf("world boss fixture player: %w", err)
	}
	_, err = pool.Raw().Exec(ctx, `INSERT INTO worldboss_players(player_id,logical_server_id,challenged_day,day,attempts,bought,swept_day,best_hit,best_hit_at,updated_at)SELECT $1,logical_server_id,0,$2,1,0,0,0,0,clock_timestamp() FROM players WHERE player_id=$1
		ON CONFLICT(player_id)DO UPDATE SET day=$2,attempts=1,bought=0,swept_day=0,best_hit=0,best_hit_at=0,updated_at=clock_timestamp()`, playerID, day)
	return err
}

// WorldBossSweepFixture seeds a ranked boss board where the player directly
// ahead of the driven player has no directory profile. The sweep reply must
// still carry a shaped pre_info row for that predecessor.
//
// shortcut: the board and the missing profile are declared fixture state, not
// proof of a genuine profile deletion; upgrade when the server exposes a
// reconcile path that removes a ranked directory row.
func WorldBossSweepFixture(ctx context.Context, databaseURL, accountID, peerAccountID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-worldboss-sweep-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var owner, peer int64
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&owner); err != nil {
		return fmt.Errorf("world boss sweep fixture owner: %w", err)
	}
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, peerAccountID).Scan(&peer); err != nil {
		return fmt.Errorf("world boss sweep fixture peer: %w", err)
	}
	server := owner / 100000
	if _, err = pool.Raw().Exec(ctx, `INSERT INTO worldboss_players(player_id,logical_server_id,challenged_day,day,attempts,bought,swept_day,best_hit,best_hit_at,updated_at)VALUES($1,$2,0,0,5,0,0,100,0,clock_timestamp())ON CONFLICT(player_id)DO UPDATE SET day=0,attempts=5,bought=0,swept_day=0,best_hit=100,best_hit_at=0,updated_at=clock_timestamp()`, owner, server); err != nil {
		return fmt.Errorf("world boss sweep fixture player: %w", err)
	}
	if _, err = pool.Raw().Exec(ctx, `DELETE FROM player_directory_profiles WHERE player_id=$1`, peer); err != nil {
		return fmt.Errorf("world boss sweep fixture profile: %w", err)
	}
	_, err = pool.Raw().Exec(ctx, `INSERT INTO worldboss_player_totals(logical_server_id,generation,boss_id,player_id,hurt,first_hurt_at,updated_at)VALUES($1,1,10011,$2,10000,0,clock_timestamp())ON CONFLICT(logical_server_id,generation,boss_id,player_id)DO UPDATE SET hurt=10000,updated_at=clock_timestamp()`, server, peer)
	return err
}
