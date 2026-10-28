package provision

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"time"
)

// PetAwakeningFixture declares one prior hatched level-90 Ricky only; the awakening mission,
// its open, Go routing and the Sky Tower read still come from their production owners.
func PetAwakeningFixture(ctx context.Context, dsn, account string) error {
	p, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-pet-awakening-fixture"})
	if err != nil {
		return err
	}
	defer p.Close()
	result, err := p.Raw().Exec(ctx, `WITH root AS (
  UPDATE player_pet_roots r SET next_pet_id=r.next_pet_id+1,state_version=r.state_version+1,updated_at=clock_timestamp()
  FROM players p JOIN player_progression v ON v.player_id=p.player_id
  WHERE r.player_id=p.player_id AND p.account_id=$1 AND v.level>=90
    AND NOT EXISTS (SELECT 1 FROM player_pets e WHERE e.player_id=r.player_id)
  RETURNING r.player_id, r.next_pet_id-1 AS pet_id)
INSERT INTO player_pets (player_id,pet_id,table_id,origin_table_id,star,level,exp,color,birthday,is_show,creation_content_revision,state_version,created_at,updated_at)
SELECT root.player_id,root.pet_id,10010001,10010001,1,90,0,15,extract(epoch FROM clock_timestamp())::bigint,true,h.creation_content_revision,1,clock_timestamp(),clock_timestamp()
FROM root JOIN player_heroes h ON h.player_id=root.player_id AND h.origin_table_id=10001001`, account)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return fmt.Errorf("pet awakening fixture requires a petless academy90+ player with the canonical Aquaris")
	}
	return nil
}
