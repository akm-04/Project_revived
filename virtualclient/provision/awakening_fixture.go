package provision

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"time"
)

// AwakeningFixture declares prior Hero progression only; identity, inventory,
// mission progress, equipment and claims still come from their production owners.
func AwakeningFixture(ctx context.Context, dsn, account string) error {
	p, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-awakening-fixture"})
	if err != nil {
		return err
	}
	defer p.Close()
	result, err := p.Raw().Exec(ctx, `UPDATE player_heroes h SET level=90,color=15,state_version=h.state_version+1,updated_at=clock_timestamp() FROM players p JOIN player_progression v ON v.player_id=p.player_id WHERE h.player_id=p.player_id AND p.account_id=$1 AND v.level>=90 AND h.table_id=10001001 AND h.origin_table_id=10001001 AND h.level=1 AND h.color=1 AND h.state_version=1`, account)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return fmt.Errorf("awakening fixture requires one fresh canonical Aquaris and academy90+")
	}
	return nil
}
