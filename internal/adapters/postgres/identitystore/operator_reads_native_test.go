//go:build postgres

package identitystore_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const onlineServer = 9021

func onlinePool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_O2_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_O2_DSN required (ops/testing/fresh_db.sh o2)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func newUUID(t *testing.T) string {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value.String()
}

func TestOnlineSessionReadsNative(t *testing.T) {
	pool := onlinePool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	account, session, contextID := newUUID(t), newUUID(t), newUUID(t)
	player := int64(onlineServer*100000 + 1)
	// A fixed server id keeps the test repeatable; clear its identity rows first.
	cleanup := []struct {
		sql  string
		args []any
	}{
		{`DELETE FROM gameplay_contexts WHERE logical_server_id=$1`, []any{onlineServer}},
		{`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE logical_server_id=$1)`, []any{onlineServer}},
		{`DELETE FROM players WHERE logical_server_id=$1`, []any{onlineServer}},
		{`DELETE FROM player_directory_profiles WHERE player_id>=$1 AND player_id<$2`, []any{int64(onlineServer) * 100000, int64(onlineServer+1) * 100000}},
		{`DELETE FROM logical_servers WHERE logical_server_id=$1`, []any{onlineServer}},
	}
	for _, statement := range cleanup {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	statements := []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'Online',true,true,true,$2,$3,$4)`, []any{onlineServer, onlineServer*100000 + 25001, (onlineServer+1)*100000 - 1, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{account, "online-" + account, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'online')`, []any{player, account, onlineServer, now}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,$4,1)`, []any{session, account, now, now.Add(2 * time.Minute)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{contextID, session, account, onlineServer, player, now}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	store := identitystore.Store{}
	counts, err := store.OnlineCountsByServerTx(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	if counts[onlineServer] != 1 {
		t.Fatalf("counts = %v", counts)
	}
	server := int64(onlineServer)
	rows, err := store.ListOnlineSessionsTx(ctx, pool, operator.OnlineSessionFilter{ServerID: &server, Limit: 10})
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 1 || rows[0].PlayerID != player || rows[0].SessionID != session {
		t.Fatalf("rows = %+v", rows)
	}
	if !rows[0].StartedAt.Equal(now) || !rows[0].LastSeenAt.Equal(now.Add(2*time.Minute)) {
		t.Fatalf("timestamps = %+v", rows[0])
	}
	if _, err := pool.Raw().Exec(ctx, `UPDATE account_sessions SET revoked_at=$2,revocation_reason='operator_logout' WHERE session_id=$1::uuid`, session, now); err != nil {
		t.Fatal(err)
	}
	counts, err = store.OnlineCountsByServerTx(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	if counts[onlineServer] != 0 {
		t.Fatalf("revoked session still counted: %v", counts)
	}
}
