//go:build postgres

package publicprofilestore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripPublicProfileStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH18_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH18_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	at := time.Date(2026, 11, 16, 5, 30, 0, 777888000, time.UTC)
	player := identity.PlayerID(2900001)
	server := identity.LogicalServerID(29)
	for _, statement := range []struct {
		query     string
		arguments []any
	}{
		{`INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(29,'payload-version-media',NULL,false,false,false,2999999,2999999,1,now()) ON CONFLICT DO NOTHING`, nil},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777729','payload-version-media','ACTIVE',now()) ON CONFLICT DO NOTHING`, nil},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(2900001,'77777777-7777-4777-8777-777777777729',29,now(),'payload-version-media') ON CONFLICT DO NOTHING`, nil},
		{`INSERT INTO player_public_profile_roots(player_id,state_version,policy_version,created_at,updated_at) VALUES($1,1,'I7B_PUBLIC_V1',$2,$2) ON CONFLICT DO NOTHING`, []any{int64(player), at}},
	} {
		if _, err := pool.Raw().Exec(ctx, statement.query, statement.arguments...); err != nil {
			t.Fatal(err)
		}
	}
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	origin, err := app.NewMediaURL("http://media.payload.test")
	if err != nil {
		t.Fatal(err)
	}
	reference, err := origin.Reference(operationID, profileasset.Descriptor{
		Policy: profileasset.Policy,
		SHA256: strings.Repeat("ab", 32),
		MD5:    strings.Repeat("cd", 16),
		Size:   1234,
		Width:  64,
		Height: 64,
	})
	if err != nil {
		t.Fatal(err)
	}
	history := app.MediaHistory{Operation: operationID, PlayerID: player, Server: server, Reference: reference, RootVersion: 1, DecisionAt: at}
	store := publicprofilestore.Store{}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	if err := store.InsertMediaHistoryTx(ctx, transaction, history); err != nil {
		t.Fatal(err)
	}
	if err := store.SetCurrentMediaTx(ctx, transaction, player, operationID); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT reference::text,payload_version FROM player_public_profile_media_history WHERE operation_id=$1::uuid`, operationID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded app.MediaReference
	if err := payload.Decode(mediaHistoryTable, version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSamePublicProfileJSON(t, decoded, reference)
	byOperation, found, err := store.ReadMediaHistoryTx(ctx, pool, operationID)
	if err != nil || !found {
		t.Fatalf("ReadMediaHistoryTx found=%v err=%v", found, err)
	}
	assertSamePublicProfileJSON(t, byOperation, history)
	current, found, err := store.ReadCurrentMediaTx(ctx, pool, player)
	if err != nil || !found {
		t.Fatalf("ReadCurrentMediaTx found=%v err=%v", found, err)
	}
	assertSamePublicProfileJSON(t, current, history)
	inventory, err := store.InventoryMediaTx(ctx, pool)
	if err != nil || len(inventory.History) != 1 || len(inventory.Current) != 1 {
		t.Fatalf("InventoryMediaTx history=%d current=%d err=%v", len(inventory.History), len(inventory.Current), err)
	}
	assertSamePublicProfileJSON(t, inventory.History[0], history)
	expected, err := json.Marshal(reference)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(expected)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored reference=%s want json.Marshal=%s", storedText, expectedText)
	}
}

func assertSamePublicProfileJSON(t *testing.T, got, want any) {
	t.Helper()
	gotRaw, err := json.Marshal(got)
	if err != nil {
		t.Fatal(err)
	}
	wantRaw, err := json.Marshal(want)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(gotRaw, wantRaw) {
		t.Fatalf("decoded=%s want=%s", gotRaw, wantRaw)
	}
}
