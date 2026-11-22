package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
)

// HeroSkillStaleFixture declares a hero write that happened after every request
// the virtual client will send, so the next MID 39 decision time is stale. It is
// test input for the C2 stale-time refusal, not gameplay-origin proof.
func HeroSkillStaleFixture(ctx context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-hero-skill-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	result, err := pool.Raw().Exec(ctx, `UPDATE player_heroes h SET updated_at=clock_timestamp()+interval '1 hour' FROM players p WHERE h.player_id=p.player_id AND p.account_id=$1`, accountID)
	if err != nil {
		return fmt.Errorf("hero skill stale fixture: %w", err)
	}
	if result.RowsAffected() == 0 {
		return fmt.Errorf("hero skill stale fixture requires an owned girl")
	}
	return nil
}
