//go:build postgres

package main

import (
	"context"
	"net/http"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/compatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/playerdatastore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/playerdata"
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

// nativeProductionInactiveRouter mirrors main_postgres.go:946-951: the shared
// inactive dispatcher is registered last, only for unowned surface MIDs.
func nativeProductionInactiveRouter(t *testing.T, actor identity.ActorContext) *httpedge.Router {
	t.Helper()
	router := httpedge.NewRouter()
	inactive := stockruntime.InactiveModeDispatcher{Authority: registrationAuthority{actor: actor}}
	for _, mid := range stockruntime.InactiveModeMIDs {
		if _, owned := router.Lookup(mid); owned {
			continue
		}
		if err := router.Register(mid, inactive); err != nil {
			t.Fatalf("register inactive MID %d: %v", mid, err)
		}
	}
	return router
}

func nativeBackendRoot(t *testing.T) string {
	t.Helper()
	directory, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	for {
		if _, err := os.Stat(filepath.Join(directory, "docs", "data", "PLAYER_RESTORE_PLAN.json")); err == nil {
			return directory
		}
		parent := filepath.Dir(directory)
		if parent == directory {
			t.Fatal("backend root with docs/data/PLAYER_RESTORE_PLAN.json not found")
		}
		directory = parent
	}
}

// nativePlayerSnapshot captures every row the restore plan selects for the
// player, so a refusal or an inactive answer that writes anything is visible.
func nativePlayerSnapshot(t *testing.T, pool *postgres.Pool, playerID int64) map[string]string {
	t.Helper()
	plan, _, err := playerdata.LoadPlan(filepath.Join(nativeBackendRoot(t), "docs", "data", "PLAYER_RESTORE_PLAN.json"))
	if err != nil {
		t.Fatal(err)
	}
	snapshot := make(map[string]string, len(plan.Tables))
	for _, table := range plan.Tables {
		rows, err := (playerdatastore.Store{}).SelectRows(context.Background(), pool, table.Select, playerID)
		if err != nil {
			t.Fatalf("%s snapshot: %v", table.Table, err)
		}
		parts := make([]string, len(rows))
		for index, row := range rows {
			parts[index] = string(row)
		}
		snapshot[table.Table] = strings.Join(parts, "\n")
	}
	return snapshot
}

// TestInactiveMIDsAnswerThroughTheProductionRouterNatively drives C13: the
// MIDs C5/C6 declare INACTIVE_SUPERSEDED answer the shared 409 terminal through
// the same registration loop main_postgres.go uses and write no player row.
func TestInactiveMIDsAnswerThroughTheProductionRouterNatively(t *testing.T) {
	pool := nativeCompatPool(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	actor := nativeCompatActor(t, pool, now)
	router := nativeProductionInactiveRouter(t, actor)
	before := nativePlayerSnapshot(t, pool, int64(actor.PlayerID))
	for _, mid := range []uint16{17, 80, 84, 85, 208, 209, 210, 211, 212, 213, 246, 1412} {
		if !slices.Contains(stockruntime.InactiveModeMIDs, mid) {
			t.Fatalf("MID %d is not on the generated inactive list", mid)
		}
		response := nativeCompatDispatch(t, router, mid, nil, now)
		if response.HTTPStatus != http.StatusConflict || len(response.Body) != 2 || response.Body["error_code"] != int64(35028) || response.Body["error_msg"] != "" {
			t.Fatalf("MID %d inactive answer = %+v", mid, response)
		}
	}
	after := nativePlayerSnapshot(t, pool, int64(actor.PlayerID))
	if !reflect.DeepEqual(before, after) {
		t.Fatal("inactive MIDs wrote a player row")
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
