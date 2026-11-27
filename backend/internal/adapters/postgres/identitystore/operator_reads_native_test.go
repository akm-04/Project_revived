//go:build postgres

package identitystore_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
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

func TestSessionHoldsNative(t *testing.T) {
	pool := onlinePool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	const holdServer = onlineServer + 1
	account, session, contextID := newUUID(t), newUUID(t), newUUID(t)
	player := int64(holdServer*100000 + 1)
	cleanup := []struct {
		sql  string
		args []any
	}{
		{`DELETE FROM operator_session_holds WHERE command_key LIKE 'hold-native-%'`, nil},
		{`DELETE FROM gameplay_contexts WHERE logical_server_id=$1`, []any{holdServer}},
		{`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE logical_server_id=$1)`, []any{holdServer}},
		{`DELETE FROM players WHERE logical_server_id=$1`, []any{holdServer}},
		{`DELETE FROM logical_servers WHERE logical_server_id=$1`, []any{holdServer}},
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
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'Holds',true,true,true,$2,$3,$4)`, []any{holdServer, holdServer*100000 + 25001, (holdServer+1)*100000 - 1, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{account, "holds-" + account, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'holds')`, []any{player, account, holdServer, now}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,$3,1)`, []any{session, account, now}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{contextID, session, account, holdServer, player, now}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	store := identitystore.Store{}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	until := now.Add(time.Hour)
	for _, hold := range []appidentity.SessionHold{
		{ScopeKind: appidentity.HoldScopeServer, ScopeKey: holdServer, HeldUntil: until, Reason: "test", CommandKey: "hold-native-server"},
		{ScopeKind: appidentity.HoldScopePlayer, ScopeKey: player, HeldUntil: until, Reason: "test", CommandKey: "hold-native-player"},
	} {
		if err := store.InsertSessionHoldTx(ctx, transaction, hold); err != nil {
			t.Fatal(err)
		}
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	active, err := store.ActiveSessionHoldTx(ctx, pool, identity.LogicalServerID(holdServer), identity.PlayerID(player), now)
	if err != nil || !active {
		t.Fatalf("active = %v err=%v", active, err)
	}
	if active, err := store.ActiveSessionHoldTx(ctx, pool, identity.LogicalServerID(holdServer+1), identity.PlayerID(player+1), now); err != nil || active {
		t.Fatalf("other scope active = %v err=%v", active, err)
	}
	if active, err := store.ActiveSessionHoldTx(ctx, pool, identity.LogicalServerID(holdServer), identity.PlayerID(player), until.Add(time.Second)); err != nil || active {
		t.Fatalf("expired hold active = %v err=%v", active, err)
	}
	globalTransaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if err := store.InsertSessionHoldTx(ctx, globalTransaction, appidentity.SessionHold{ScopeKind: appidentity.HoldScopeGlobal, HeldUntil: until, Reason: "test", CommandKey: "hold-native-global"}); err != nil {
		t.Fatal(err)
	}
	if err := globalTransaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if active, err := store.ActiveSessionHoldTx(ctx, pool, identity.LogicalServerID(holdServer+1), identity.PlayerID(player+1), now); err != nil || !active {
		t.Fatalf("global hold active = %v err=%v", active, err)
	}
	players, err := store.PlayerIDsForSessionIDsTx(ctx, pool, []identity.SessionID{})
	if err != nil || len(players) != 0 {
		t.Fatalf("empty session read = %v err=%v", players, err)
	}
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

func TestOnlineSessionsDedupeRepeatedLoginsNative(t *testing.T) {
	pool := onlinePool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	const dedupeServer = onlineServer + 3
	const stalePlayer = int64(dedupeServer*100000 + 1)
	const otherPlayer = int64(dedupeServer*100000 + 2)
	account, olderSession, olderContext := newUUID(t), newUUID(t), newUUID(t)
	newerSession, newerContext := newUUID(t), newUUID(t)
	otherAccount, otherSession, otherContext := newUUID(t), newUUID(t), newUUID(t)
	cleanup := []struct {
		sql  string
		args []any
	}{
		{`DELETE FROM gameplay_contexts WHERE logical_server_id=$1`, []any{dedupeServer}},
		{`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE logical_server_id=$1)`, []any{dedupeServer}},
		{`DELETE FROM players WHERE logical_server_id=$1`, []any{dedupeServer}},
		{`DELETE FROM logical_servers WHERE logical_server_id=$1`, []any{dedupeServer}},
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
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'Dedupe',true,true,true,$2,$3,$4)`, []any{dedupeServer, dedupeServer*100000 + 25001, (dedupeServer+1)*100000 - 1, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{account, "dedupe-player-" + account, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{otherAccount, "dedupe-other-" + otherAccount, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'dedupe')`, []any{stalePlayer, account, dedupeServer, now.Add(-2 * time.Hour)}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'dedupe')`, []any{otherPlayer, otherAccount, dedupeServer, now}},
		// The same player logged in again: the older session is still open and quiet, the newer one is online.
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$3,1)`, []any{olderSession, account, now.Add(-2 * time.Hour)}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, []any{newerSession, account, now.Add(-time.Hour), now}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, []any{otherSession, otherAccount, now, now}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{olderContext, olderSession, account, dedupeServer, stalePlayer, now.Add(-2 * time.Hour)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{newerContext, newerSession, account, dedupeServer, stalePlayer, now.Add(-time.Hour)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{otherContext, otherSession, otherAccount, dedupeServer, otherPlayer, now}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	store := identitystore.Store{}
	server := int64(dedupeServer)
	rows, err := store.ListOnlineSessionsTx(ctx, pool, operator.OnlineSessionFilter{ServerID: &server, Limit: 10})
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 {
		t.Fatalf("rows = %+v, want one row per player", rows)
	}
	byPlayer := map[int64]operator.OnlineSession{}
	for _, row := range rows {
		byPlayer[row.PlayerID] = row
	}
	stale, ok := byPlayer[stalePlayer]
	if !ok || stale.SessionID != newerSession || !stale.Online {
		t.Fatalf("player %d row = %+v, want newest session %s online", stalePlayer, stale, newerSession)
	}
	if _, ok := byPlayer[otherPlayer]; !ok {
		t.Fatalf("player %d missing from %+v", otherPlayer, rows)
	}
	counts, err := store.OnlineCountsByServerTx(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	if counts[dedupeServer] != 2 {
		t.Fatalf("online count = %d, want 2 players (not 3 open contexts)", counts[dedupeServer])
	}

	if _, err := pool.Raw().Exec(ctx, `UPDATE account_sessions SET revoked_at=$2,revocation_reason='operator_logout' WHERE session_id=$1::uuid`, newerSession, now); err != nil {
		t.Fatal(err)
	}
	rows, err = store.ListOnlineSessionsTx(ctx, pool, operator.OnlineSessionFilter{ServerID: &server, Limit: 10})
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 {
		t.Fatalf("rows after revoke = %+v", rows)
	}
	byPlayer = map[int64]operator.OnlineSession{}
	for _, row := range rows {
		byPlayer[row.PlayerID] = row
	}
	stale = byPlayer[stalePlayer]
	if stale.SessionID != olderSession || stale.Online {
		t.Fatalf("player %d row after revoke = %+v, want quiet older session %s", stalePlayer, stale, olderSession)
	}
	counts, err = store.OnlineCountsByServerTx(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	if counts[dedupeServer] != 1 {
		t.Fatalf("online count after revoke = %d, want only the other player", counts[dedupeServer])
	}
}

func TestPresenceWindowMarksQuietSessionsOfflineNative(t *testing.T) {
	pool := onlinePool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	const presenceServer = onlineServer + 2
	activeAccount, activeSession, activeContext := newUUID(t), newUUID(t), newUUID(t)
	quietAccount, quietSession, quietContext := newUUID(t), newUUID(t), newUUID(t)
	activePlayer := int64(presenceServer*100000 + 1)
	quietPlayer := int64(presenceServer*100000 + 2)
	cleanup := []struct {
		sql  string
		args []any
	}{
		{`DELETE FROM gameplay_contexts WHERE logical_server_id=$1`, []any{presenceServer}},
		{`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE logical_server_id=$1)`, []any{presenceServer}},
		{`DELETE FROM players WHERE logical_server_id=$1`, []any{presenceServer}},
		{`DELETE FROM logical_servers WHERE logical_server_id=$1`, []any{presenceServer}},
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
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'Presence',true,true,true,$2,$3,$4)`, []any{presenceServer, presenceServer*100000 + 25001, (presenceServer+1)*100000 - 1, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{activeAccount, "presence-a-" + activeAccount, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{quietAccount, "presence-q-" + quietAccount, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'presence')`, []any{activePlayer, activeAccount, presenceServer, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'presence')`, []any{quietPlayer, quietAccount, presenceServer, now}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, []any{activeSession, activeAccount, now, now.Add(-60 * time.Second)}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, []any{quietSession, quietAccount, now, now.Add(-120 * time.Second)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{activeContext, activeSession, activeAccount, presenceServer, activePlayer, now}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{quietContext, quietSession, quietAccount, presenceServer, quietPlayer, now}},
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
	if counts[presenceServer] != 1 {
		t.Fatalf("online count = %d, want 1 (60 s touch online, 120 s touch offline)", counts[presenceServer])
	}
	server := int64(presenceServer)
	rows, err := store.ListOnlineSessionsTx(ctx, pool, operator.OnlineSessionFilter{ServerID: &server, Limit: 10})
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 {
		t.Fatalf("rows = %+v", rows)
	}
	onlineByPlayer := map[int64]bool{}
	for _, row := range rows {
		onlineByPlayer[row.PlayerID] = row.Online
	}
	if !onlineByPlayer[activePlayer] || onlineByPlayer[quietPlayer] {
		t.Fatalf("online flags = %v, want active %d online and quiet %d offline", onlineByPlayer, activePlayer, quietPlayer)
	}
}
