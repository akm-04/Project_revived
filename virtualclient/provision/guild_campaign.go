package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
)

// GuildCampaignFixture seeds the campaign prerequisites the scenario does not
// prove: level 40+ and forty days of personal activity. It is declared prior
// state, not gameplay-origin proof.
func GuildCampaignFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-guild-campaign-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var player int64
	if err := pool.QueryRow(requestContext, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&player); err != nil {
		return fmt.Errorf("guild campaign fixture needs the driven player: %w", err)
	}
	if _, err := pool.Raw().Exec(requestContext, `UPDATE player_progression SET level=GREATEST(level,41),updated_at=clock_timestamp() WHERE player_id=$1`, player); err != nil {
		return err
	}
	if _, err := pool.Raw().Exec(requestContext, `UPDATE player_directory_profiles SET lev=GREATEST(lev,41),updated_at=clock_timestamp() WHERE player_id=$1`, player); err != nil {
		return err
	}
	day := (time.Now().Unix() + 8*3600 - 5*3600) / 86400
	for offset := int64(0); offset < 40; offset++ {
		if _, err := pool.Raw().Exec(requestContext, `INSERT INTO player_guild_activity_days(player_id,game_day,amount)VALUES($1,$2,1000)
			ON CONFLICT(player_id,game_day) DO UPDATE SET amount=GREATEST(player_guild_activity_days.amount,1000)`, player, day-offset); err != nil {
			return err
		}
	}
	return nil
}
