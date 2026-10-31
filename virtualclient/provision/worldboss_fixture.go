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
	_, err = pool.Raw().Exec(ctx, `INSERT INTO worldboss_players(player_id,day,attempts,bought,swept_day,best_hit,best_hit_at,updated_at)VALUES($1,$2,1,0,0,0,0,clock_timestamp())
		ON CONFLICT(player_id)DO UPDATE SET day=$2,attempts=1,bought=0,swept_day=0,best_hit=0,best_hit_at=0,updated_at=clock_timestamp()`, playerID, day)
	return err
}
