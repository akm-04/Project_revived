//go:build postgres

package i4store_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const o2Server = 9001

func o2DirectoryPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_O2_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_O2_DSN required (ops/testing/fresh_db.sh o2)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func o2UUID(t *testing.T) string {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value.String()
}

func TestOperatorPlayerReadsNative(t *testing.T) {
	pool := o2DirectoryPool(t)
	ctx := context.Background()
	firstAccount, secondAccount := o2UUID(t), o2UUID(t)
	firstUID, secondUID := "o2-"+firstAccount, "o2-"+secondAccount
	now := time.Now().UTC().Truncate(time.Second)
	statements := []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'o2',true,true,true,$2,$3,$4)`, []any{o2Server, o2Server*100000 + 25001, (o2Server+1)*100000 - 1, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{firstAccount, firstUID, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{secondAccount, secondUID, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'o2')`, []any{o2Server*100000 + 1, firstAccount, o2Server, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'o2')`, []any{o2Server*100000 + 2, secondAccount, o2Server, now}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at) VALUES($1,'O2 Alpha',12,$2,$2)`, []any{o2Server*100000 + 1, now}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at) VALUES($1,'O2 Beta',7,$2,$2)`, []any{o2Server*100000 + 2, now}},
		{`INSERT INTO player_login_observations(player_id,logical_server_id,last_login_at,source_operation_id,state_version) VALUES($1,$2,$3,$4::uuid,1)`, []any{o2Server*100000 + 1, o2Server, now, o2UUID(t)}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	reader := i4store.PlayerDirectoryReader{Queryer: pool}
	server := int64(o2Server)
	found, err := reader.FindPlayersTx(ctx, pool, playerdirectory.OperatorFind{NamePrefix: "O2 ", ServerID: &server, Limit: 50})
	if err != nil || len(found) != 2 {
		t.Fatalf("prefix find = %+v err=%v", found, err)
	}
	if found[0].Name != "O2 Alpha" || found[0].Level != 12 || found[0].AccountUID != firstUID {
		t.Fatalf("first row = %+v", found[0])
	}
	byUID, err := reader.FindPlayersTx(ctx, pool, playerdirectory.OperatorFind{UID: secondUID, Limit: 50})
	if err != nil || len(byUID) != 1 || byUID[0].PlayerID != identity.PlayerID(o2Server*100000+2) {
		t.Fatalf("uid find = %+v err=%v", byUID, err)
	}
	if byUID[0].LastLoginAt != nil {
		t.Fatalf("second player has a login observation: %v", byUID[0].LastLoginAt)
	}
	summary, exists, err := reader.OperatorPlayerTx(ctx, pool, identity.PlayerID(o2Server*100000+1))
	if err != nil || !exists || summary.LastLoginAt == nil || !summary.LastLoginAt.Equal(now) || summary.CreatedAt.IsZero() {
		t.Fatalf("summary = %+v exists=%v err=%v", summary, exists, err)
	}
	if _, exists, err := reader.OperatorPlayerTx(ctx, pool, identity.PlayerID(o2Server*100000+9)); err != nil || exists {
		t.Fatalf("missing player exists=%v err=%v", exists, err)
	}
	serverIDs, err := reader.ServerPlayerIDsTx(ctx, pool, identity.LogicalServerID(o2Server), 100)
	if err != nil || len(serverIDs) != 2 {
		t.Fatalf("server ids = %v err=%v", serverIDs, err)
	}
	allIDs, err := reader.AllPlayerIDsTx(ctx, pool, 100000)
	if err != nil || len(allIDs) < 2 {
		t.Fatalf("all ids = %v err=%v", allIDs, err)
	}
}
