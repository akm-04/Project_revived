//go:build postgres

package dormstore_test

import (
	"context"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
)

// seedPlayers creates the account and player rows that the player_dorm_* foreign keys require.
func seedPlayers(t *testing.T, pool *pg.Pool, server int64, players ...identity.PlayerID) {
	t.Helper()
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	accountUIDs := make([]string, 0, len(players))
	for _, player := range players {
		accountUID := "dorm-native-player-" + strconv.FormatInt(int64(player), 10)
		accountUIDs = append(accountUIDs, accountUID)
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES(gen_random_uuid(),$1,'ACTIVE',$2) ON CONFLICT (account_uid) DO NOTHING`, accountUID, now); err != nil {
			t.Fatal(err)
		}
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) SELECT $1,account_id,$2,$3,'dorm-native' FROM accounts WHERE account_uid=$4 ON CONFLICT (player_id) DO NOTHING`, int64(player), server, now, accountUID); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		cleanupContext := context.Background()
		for _, player := range players {
			if _, err := pool.Raw().Exec(cleanupContext, `DELETE FROM players WHERE player_id=$1`, int64(player)); err != nil {
				t.Error(err)
			}
		}
		for _, accountUID := range accountUIDs {
			if _, err := pool.Raw().Exec(cleanupContext, `DELETE FROM accounts WHERE account_uid=$1`, accountUID); err != nil {
				t.Error(err)
			}
		}
	})
}
