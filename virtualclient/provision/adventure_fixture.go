package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
)

// AdventureEventFixture declares one live defense (10001) and one live
// illusion co-op (10006) occurrence so one virtual client can read the room
// replies. It is test input, not gameplay-origin proof.
func AdventureEventFixture(ctx context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-adventure-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var playerID int64
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&playerID); err != nil {
		return fmt.Errorf("adventure fixture player: %w", err)
	}
	_, err = pool.Raw().Exec(ctx, `INSERT INTO adventure_occurrences(player_id,logical_server_id,event_type,occurred_at,end_time,special_data,source_key)
VALUES($1,($1::bigint/100000)::int,10001,clock_timestamp(),clock_timestamp()+interval '2 hours',0,'vc-adventure-defense'),
      ($1,($1/100000)::int,10006,clock_timestamp(),clock_timestamp()+interval '2 hours',100011,'vc-adventure-illusion')
ON CONFLICT DO NOTHING`, playerID)
	return err
}
