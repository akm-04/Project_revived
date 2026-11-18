//go:build postgres

package main

import (
	"context"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/compatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func nativeCompatPool(t *testing.T) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I9_11D_DSN")
	if dsn == "" {
		t.Fatal("GXB_I9_11D_DSN required")
	}
	pool, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func nativeCompatActor(t *testing.T, pool *postgres.Pool, at time.Time) identity.ActorContext {
	t.Helper()
	ctx := context.Background()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	session, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	game, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err := transaction.Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at)
VALUES(1,'i9-11d-route-native',true,true,true,125001,199999,clock_timestamp()) ON CONFLICT(logical_server_id) DO NOTHING`); err != nil {
		t.Fatal(err)
	}
	var player int64
	if err := transaction.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&player); err != nil {
		t.Fatal(err)
	}
	for _, row := range []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), account.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,clock_timestamp(),'i9-11d-route-native')`, []any{player, account.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i94',$3,$3)`, []any{session.String(), account.String(), at.Add(-time.Hour)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,1,$4,1,$5)`, []any{game.String(), session.String(), account.String(), player, at.Add(-time.Hour)}},
	} {
		if _, err := transaction.Exec(ctx, row.sql, row.args...); err != nil {
			t.Fatal(err)
		}
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	accountID, err := identity.AccountIDFrom(account)
	if err != nil {
		t.Fatal(err)
	}
	sessionID, err := identity.SessionIDFrom(session)
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(game)
	if err != nil {
		t.Fatal(err)
	}
	return identity.ActorContext{
		AccountID: accountID, AccountUID: identity.AccountUID(account.String()),
		SessionID: sessionID, ContextID: contextID,
		LogicalServerID: 1, PlayerID: identity.PlayerID(player),
		ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1,
	}
}

func nativeCompatRouter(t *testing.T, pool *postgres.Pool, actor identity.ActorContext) *httpedge.Router {
	t.Helper()
	router := httpedge.NewRouter()
	register := func(mid uint16, dispatcher httpedge.Dispatcher) {
		if err := router.Register(mid, dispatcher); err != nil {
			t.Fatal(err)
		}
	}
	service := canonicalCompat(pool, tx.Runner{DB: pool}, contentstore.Store{Queryer: pool}, i5store.Store{Queryer: pool})
	authority := registrationAuthority{actor: actor}
	compat := stockruntime.NewCompatDispatcher(authority, service)
	for _, mid := range stockruntime.CompatMIDs {
		register(mid, compat)
	}
	arenaReport := stockruntime.NewArenaResultDispatcher(authority)
	for _, mid := range stockruntime.ArenaFightResultMIDs {
		register(mid, arenaReport)
	}
	return router
}

func nativeCompatDispatch(t *testing.T, router *httpedge.Router, mid uint16, params map[string]any, now time.Time) httpedge.Response {
	t.Helper()
	routed, ok := router.Lookup(mid)
	if !ok {
		t.Fatalf("MID %d is not registered", mid)
	}
	if params == nil {
		params = map[string]any{}
	}
	params["token"] = "bearer"
	params["region"] = int64(1)
	return routed.Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation: operation.Context{StartedAt: now}, MID: mid, ReceivedAt: now, Params: params,
		Claims: wire.CredentialClaims{Token: "bearer", Region: 1},
	}})
}

func nativeCompatCount(t *testing.T, pool *postgres.Pool, statement string, arguments ...any) int64 {
	t.Helper()
	var count int64
	if err := pool.Raw().QueryRow(context.Background(), statement, arguments...).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

// TestCompatRoutesReachTheServiceNatively drives the registered router into the
// production-shaped service and back to the database, the end-to-end proof
// REVIEW_D D-1 asked for.
func TestCompatRoutesReachTheServiceNatively(t *testing.T) {
	pool := nativeCompatPool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	actor := nativeCompatActor(t, pool, now)
	router := nativeCompatRouter(t, pool, actor)

	if response := nativeCompatDispatch(t, router, 1025, map[string]any{"message_type": int64(7)}, now); response.HTTPStatus != 200 || len(response.Body) != 0 {
		t.Fatalf("1025 = %+v", response)
	}
	preferences, found, err := (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if err != nil || !found || len(preferences.MessagePushIDs) != 1 || preferences.MessagePushIDs[0] != 7 {
		t.Fatalf("after 1025 found=%v prefs=%+v err=%v", found, preferences, err)
	}
	versionAfterAdd := preferences.StateVersion
	if response := nativeCompatDispatch(t, router, 1025, map[string]any{"message_type": int64(7)}, now); response.HTTPStatus != 200 {
		t.Fatalf("repeat 1025 = %+v", response)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if preferences.StateVersion != versionAfterAdd {
		t.Fatalf("repeat 1025 advanced state_version %d -> %d", versionAfterAdd, preferences.StateVersion)
	}
	if response := nativeCompatDispatch(t, router, 1026, map[string]any{"message_type": int64(7)}, now); response.HTTPStatus != 200 {
		t.Fatalf("1026 = %+v", response)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if len(preferences.MessagePushIDs) != 0 {
		t.Fatalf("after 1026 ids = %v", preferences.MessagePushIDs)
	}

	if response := nativeCompatDispatch(t, router, 1864, nil, now); response.HTTPStatus != 200 {
		t.Fatalf("1864 = %+v", response)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if preferences.FirstMainTouch != 1 {
		t.Fatalf("first_main_touch = %d", preferences.FirstMainTouch)
	}
	versionAfterTouch := preferences.StateVersion
	if response := nativeCompatDispatch(t, router, 1864, nil, now); response.HTTPStatus != 200 {
		t.Fatalf("repeat 1864 = %+v", response)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if preferences.StateVersion != versionAfterTouch {
		t.Fatalf("repeat 1864 advanced state_version %d -> %d", versionAfterTouch, preferences.StateVersion)
	}

	if response := nativeCompatDispatch(t, router, 1025, map[string]any{"message_type": "7"}, now); response.HTTPStatus != 400 || response.Body["error"] != "compat_invalid_parameter" {
		t.Fatalf("text message_type = %+v", response)
	}
	if response := nativeCompatDispatch(t, router, 1025, map[string]any{"message_type": int64(99)}, now); response.HTTPStatus != 400 {
		t.Fatalf("unknown message_type = %+v", response)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if preferences.StateVersion != versionAfterTouch || len(preferences.MessagePushIDs) != 0 {
		t.Fatalf("refused toggles changed the row: %+v", preferences)
	}
}

// TestArenaReportChangesNothingNatively proves the MID 279 terminal settles no
// receipt and no Top Floor state through the registered router.
func TestArenaReportChangesNothingNatively(t *testing.T) {
	pool := nativeCompatPool(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	actor := nativeCompatActor(t, pool, now)
	router := nativeCompatRouter(t, pool, actor)

	receiptsBefore := nativeCompatCount(t, pool, `SELECT count(*) FROM gxb_operation_receipts`)
	fightsBefore := nativeCompatCount(t, pool, `SELECT count(*) FROM top_floor_fights`)
	preferencesBefore := nativeCompatCount(t, pool, `SELECT count(*) FROM player_compat_preferences`)

	response := nativeCompatDispatch(t, router, 279, nil, now)
	if response.HTTPStatus != 200 || response.Body["error_code"] != int64(30005) || len(response.Body) != 3 {
		t.Fatalf("279 = %+v", response)
	}
	if got := nativeCompatCount(t, pool, `SELECT count(*) FROM gxb_operation_receipts`); got != receiptsBefore {
		t.Fatalf("279 wrote %d receipts", got-receiptsBefore)
	}
	if got := nativeCompatCount(t, pool, `SELECT count(*) FROM top_floor_fights`); got != fightsBefore {
		t.Fatalf("279 wrote %d top_floor_fights", got-fightsBefore)
	}
	if got := nativeCompatCount(t, pool, `SELECT count(*) FROM player_compat_preferences`); got != preferencesBefore {
		t.Fatalf("279 wrote %d compat rows", got-preferencesBefore)
	}
}
