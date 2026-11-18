//go:build postgres

package compat_test

import (
	"context"
	"errors"
	"os"
	"slices"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/compatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	appcompat "gxb.local/backend/v2/internal/application/compat"
	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func compatPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I9_11D_DSN")
	if dsn == "" {
		t.Fatal("GXB_I9_11D_DSN required")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func compatActor(t *testing.T, pool *pg.Pool, at time.Time) identity.ActorContext {
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
	tr, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err := tr.Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at)
VALUES(1,'i9-11d-native',true,true,true,125001,199999,clock_timestamp()) ON CONFLICT(logical_server_id) DO NOTHING`); err != nil {
		t.Fatal(err)
	}
	var player int64
	if err := tr.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&player); err != nil {
		t.Fatal(err)
	}
	for _, row := range []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), account.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,clock_timestamp(),'i9-11d-native')`, []any{player, account.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i94',$3,$3)`, []any{session.String(), account.String(), at.Add(-time.Hour)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,1,$4,1,$5)`, []any{game.String(), session.String(), account.String(), player, at.Add(-time.Hour)}},
	} {
		if _, err := tr.Exec(ctx, row.sql, row.args...); err != nil {
			t.Fatal(err)
		}
	}
	if err := tr.Commit(ctx); err != nil {
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

func compatOperation(t *testing.T, at time.Time) operation.Context {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at}
}

func compatService(pool *pg.Pool) appcompat.Service {
	return appcompat.Service{
		Runner:  tx.Runner{DB: pool},
		Fresh:   pool,
		Store:   compatstore.Store{},
		Content: contentstore.Store{},
		Players: i4store.PlayerRootLocker{},
		Fence:   i5store.Store{},
	}
}

func TestCompatPreferencesNatively(t *testing.T) {
	pool := compatPool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	actor := compatActor(t, pool, now)
	service := compatService(pool)

	if err := service.FirstMainTouch(ctx, actor, compatOperation(t, now)); err != nil {
		t.Fatal(err)
	}
	preferences, found, err := (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if err != nil || !found {
		t.Fatalf("after first touch found=%v err=%v", found, err)
	}
	if preferences.FirstMainTouch != 1 || preferences.StateVersion != 2 {
		t.Fatalf("first touch row = %+v", preferences)
	}
	if err := service.FirstMainTouch(ctx, actor, compatOperation(t, now)); err != nil {
		t.Fatal(err)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if preferences.StateVersion != 2 {
		t.Fatalf("repeat first touch advanced state_version to %d", preferences.StateVersion)
	}

	if err := service.SetMessagePush(ctx, actor, 1, true, compatOperation(t, now)); err != nil {
		t.Fatal(err)
	}
	if err := service.SetMessagePush(ctx, actor, 1, true, compatOperation(t, now)); err != nil {
		t.Fatal(err)
	}
	if err := service.SetMessagePush(ctx, actor, 9, true, compatOperation(t, now)); err != nil {
		t.Fatal(err)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if !slices.Equal(preferences.MessagePushIDs, []int64{1, 9}) {
		t.Fatalf("enabled set = %v", preferences.MessagePushIDs)
	}
	if preferences.StateVersion != 4 {
		t.Fatalf("state_version = %d, want 4 (first touch and two real changes)", preferences.StateVersion)
	}
	if err := service.SetMessagePush(ctx, actor, 1, false, compatOperation(t, now)); err != nil {
		t.Fatal(err)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if !slices.Equal(preferences.MessagePushIDs, []int64{9}) {
		t.Fatalf("enabled set after remove = %v", preferences.MessagePushIDs)
	}

	if err := service.SetMessagePush(ctx, actor, 99, true, compatOperation(t, now)); !errors.Is(err, d.ErrInvalidMessageType) {
		t.Fatalf("unknown message_type = %v", err)
	}
	preferences, _, _ = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if !slices.Equal(preferences.MessagePushIDs, []int64{9}) {
		t.Fatalf("refused add changed the set to %v", preferences.MessagePushIDs)
	}

	detail := map[string]any{"17": map[string]any{"first_main_touch": int64(0), "message_pushes": map[string]any{}}}
	if err := (appcompat.BootstrapProjection{Store: compatstore.Store{}}).OverlayMID1(ctx, pool, actor, false, now, detail); err != nil {
		t.Fatal(err)
	}
	record := detail["17"].(map[string]any)
	if record["first_main_touch"] != int64(1) {
		t.Fatalf("projected first_main_touch = %#v", record["first_main_touch"])
	}
	if !slices.Equal(record["message_pushes"].([]int64), []int64{9}) {
		t.Fatalf("projected message_pushes = %#v", record["message_pushes"])
	}
}

func TestCompatCatalogIsInstalledAndCoversTheStockIds(t *testing.T) {
	pool := compatPool(t)
	ctx := context.Background()
	content := contentstore.Store{}
	revision, err := content.ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := content.MessagePushCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	for id := int64(1); id <= 12; id++ {
		if !catalog.ValidMessagePush(id) {
			t.Fatalf("message_push id %d missing from the installed catalog", id)
		}
	}
	if catalog.ValidMessagePush(13) {
		t.Fatal("message_push id 13 must not exist")
	}
}

func TestMissingRowProjectsNewPlayerDefaults(t *testing.T) {
	pool := compatPool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	actor := compatActor(t, pool, now)
	preferences, found, err := (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if err != nil || found {
		t.Fatalf("new player row found=%v err=%v", found, err)
	}
	if preferences.FirstMainTouch != 0 || len(preferences.MessagePushIDs) != 0 {
		t.Fatalf("new player defaults = %+v", preferences)
	}
}

func TestBackfillMarksExistingPlayersTouched(t *testing.T) {
	pool := compatPool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	actor := compatActor(t, pool, now)
	preferences, found, err := (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if err != nil || found {
		t.Fatalf("precondition row found=%v err=%v", found, err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_compat_preferences(player_id,first_main_touch,created_at,updated_at) VALUES($1,1,now(),now())`, int64(actor.PlayerID)); err != nil {
		t.Fatal(err)
	}
	preferences, found, err = (compatstore.Store{}).ReadTx(ctx, pool, actor.PlayerID)
	if err != nil || !found || preferences.FirstMainTouch != 1 {
		t.Fatalf("backfilled row found=%v prefs=%+v err=%v", found, preferences, err)
	}
}
