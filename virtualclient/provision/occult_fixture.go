package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
)

// OccultTicketFixture declares prior energy-to-ticket conversions so the stock
// Create Room button is enabled; the real 3000-energy accrual is proven by the
// native ticket test.
//
// shortcut: the fixture writes the I5 scalar row directly because the stock
// client has no single action that spends 3000 energy; upgrade when one exists.
func OccultTicketFixture(ctx context.Context, databaseURL, accountID string, tickets int64) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-occult-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var playerID int64
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&playerID); err != nil {
		return fmt.Errorf("occult fixture player: %w", err)
	}
	_, err = pool.Raw().Exec(ctx, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'occult_ticket',$2,1,clock_timestamp())
		ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=$2,state_version=player_currency_balances.state_version+1`, playerID, tickets)
	return err
}
