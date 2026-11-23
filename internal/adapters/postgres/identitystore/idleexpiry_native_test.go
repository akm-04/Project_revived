//go:build postgres

package identitystore_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const idleExpiryServer = 9024

func mustBegin(t *testing.T, pool *pg.Pool) tx.Tx {
	t.Helper()
	transaction, err := pool.Begin(context.Background(), tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	return transaction
}

func mustParseUUID(t *testing.T, raw string) ids.UUID {
	t.Helper()
	value, err := ids.ParseUUID(raw)
	if err != nil {
		t.Fatal(err)
	}
	return value
}

func TestIdleExpirySweepNative(t *testing.T) {
	pool := onlinePool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	expiredAccount, expiredSession, expiredContext := newUUID(t), newUUID(t), newUUID(t)
	activeAccount, activeSession, activeContext := newUUID(t), newUUID(t), newUUID(t)
	expiredPlayer := int64(idleExpiryServer*100000 + 1)
	activePlayer := int64(idleExpiryServer*100000 + 2)
	cleanup := []struct {
		sql  string
		args []any
	}{
		{`DELETE FROM gameplay_contexts WHERE logical_server_id=$1`, []any{idleExpiryServer}},
		{`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE logical_server_id=$1)`, []any{idleExpiryServer}},
		{`DELETE FROM players WHERE logical_server_id=$1`, []any{idleExpiryServer}},
		{`DELETE FROM logical_servers WHERE logical_server_id=$1`, []any{idleExpiryServer}},
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
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'Idle',true,true,true,$2,$3,$4)`, []any{idleExpiryServer, idleExpiryServer*100000 + 25001, (idleExpiryServer+1)*100000 - 1, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{expiredAccount, "idle-e-" + expiredAccount, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{activeAccount, "idle-a-" + activeAccount, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'idle')`, []any{expiredPlayer, expiredAccount, idleExpiryServer, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'idle')`, []any{activePlayer, activeAccount, idleExpiryServer, now}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, []any{expiredSession, expiredAccount, now.Add(-48 * time.Hour), now.Add(-24*time.Hour - time.Second)}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, []any{activeSession, activeAccount, now.Add(-time.Hour), now.Add(-60 * time.Second)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{expiredContext, expiredSession, expiredAccount, idleExpiryServer, expiredPlayer, now.Add(-48 * time.Hour)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{activeContext, activeSession, activeAccount, idleExpiryServer, activePlayer, now.Add(-time.Hour)}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	sweep := appidentity.IdleExpirySweep{
		Runner:     tx.Runner{DB: pool},
		Store:      identitystore.Store{},
		Operations: operation.Factory{Clock: clock.System{}},
	}
	revoked, err := sweep.Run(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if revoked != 1 {
		t.Fatalf("revoked = %d, want the one session idle past 24 h", revoked)
	}
	var reason string
	var ended bool
	if err := pool.QueryRow(ctx, `SELECT revocation_reason FROM account_sessions WHERE session_id=$1::uuid`, expiredSession).Scan(&reason); err != nil || reason != identity.RevocationReasonIdleExpired {
		t.Fatalf("expired session reason = %q err=%v", reason, err)
	}
	if err := pool.QueryRow(ctx, `SELECT ended_at IS NOT NULL AND end_reason=$2 FROM gameplay_contexts WHERE context_id=$1::uuid`, expiredContext, identity.RevocationReasonIdleExpired).Scan(&ended); err != nil || !ended {
		t.Fatalf("expired context ended = %v err=%v", ended, err)
	}
	if err := pool.QueryRow(ctx, `SELECT revoked_at IS NULL FROM account_sessions WHERE session_id=$1::uuid`, activeSession).Scan(&ended); err != nil || !ended {
		t.Fatalf("active session revoked err=%v", err)
	}
	revoked, err = sweep.Run(ctx)
	if err != nil || revoked != 0 {
		t.Fatalf("second sweep revoked = %d err=%v, want idempotent 0", revoked, err)
	}
}

func TestIdleExpiryRevocationRechecksActivityNative(t *testing.T) {
	pool := onlinePool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	account, session, contextID := newUUID(t), newUUID(t), newUUID(t)
	player := int64(idleExpiryServer*100000 + 3)
	cleanup := []struct {
		sql  string
		args []any
	}{
		{`DELETE FROM gameplay_contexts WHERE logical_server_id=$1`, []any{idleExpiryServer}},
		{`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE logical_server_id=$1)`, []any{idleExpiryServer}},
		{`DELETE FROM players WHERE logical_server_id=$1`, []any{idleExpiryServer}},
		{`DELETE FROM logical_servers WHERE logical_server_id=$1`, []any{idleExpiryServer}},
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
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'Idle',true,true,true,$2,$3,$4)`, []any{idleExpiryServer, idleExpiryServer*100000 + 25001, (idleExpiryServer+1)*100000 - 1, now}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{account, "idle-r-" + account, now}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'idle')`, []any{player, account, idleExpiryServer, now}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, []any{session, account, now.Add(-48 * time.Hour), now.Add(-24*time.Hour - time.Second)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6,1)`, []any{contextID, session, account, idleExpiryServer, player, now.Add(-48 * time.Hour)}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	store := identitystore.Store{}
	page, err := store.ListIdleExpiredSessionIDsTx(ctx, pool, now, identity.SessionID{}, 500)
	if err != nil || len(page) != 1 {
		t.Fatalf("expired page = %v err=%v", page, err)
	}
	if _, err := pool.Raw().Exec(ctx, `UPDATE account_sessions SET last_activity_at=$2 WHERE session_id=$1::uuid`, session, now); err != nil {
		t.Fatal(err)
	}
	transaction := mustBegin(t, pool)
	revoked, err := store.RevokeIdleExpiredSessionsTx(ctx, transaction, page, now)
	if err != nil || revoked != 0 {
		t.Fatalf("touched session revoked = %d err=%v", revoked, err)
	}
	if err := transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestTouchActivityCoalescesNative(t *testing.T) {
	pool := onlinePool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	account, session := newUUID(t), newUUID(t)
	cleanup := []struct {
		sql  string
		args []any
	}{
		{`DELETE FROM account_sessions WHERE account_id=$1::uuid`, []any{account}},
		{`DELETE FROM accounts WHERE account_id=$1::uuid`, []any{account}},
	}
	for _, statement := range cleanup {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, account, "touch-"+account, now); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, session, account, now.Add(-time.Hour), now.Add(-60*time.Second)); err != nil {
		t.Fatal(err)
	}
	store := identitystore.Store{}
	sessionID, err := identity.SessionIDFrom(mustParseUUID(t, session))
	if err != nil {
		t.Fatal(err)
	}
	transaction := mustBegin(t, pool)
	changed, err := store.TouchSessionActivityTx(ctx, transaction, sessionID, now.Add(-30*time.Second), now)
	if err != nil || !changed {
		t.Fatalf("first touch changed=%v err=%v", changed, err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	transaction = mustBegin(t, pool)
	changed, err = store.TouchSessionActivityTx(ctx, transaction, sessionID, now.Add(-29*time.Second), now.Add(time.Second))
	if err != nil || changed {
		t.Fatalf("second touch changed=%v err=%v, want coalesced", changed, err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}
