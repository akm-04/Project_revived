//go:build postgres

package workplacestore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/workplacestore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripWorkplaceStore(t *testing.T) {
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
	for _, statement := range []string{
		`INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(28,'payload-version-workplace',NULL,false,false,false,2899999,2899999,1,now()) ON CONFLICT DO NOTHING`,
		`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777719','payload-version-workplace','ACTIVE',now()) ON CONFLICT DO NOTHING`,
		`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(2800001,'77777777-7777-4777-8777-777777777719',28,now(),'payload-version-workplace') ON CONFLICT DO NOTHING`,
	} {
		if _, err := pool.Raw().Exec(ctx, statement); err != nil {
			t.Fatal(err)
		}
	}
	at := time.Date(2026, 11, 16, 5, 10, 0, 654321000, time.UTC)
	player := identity.PlayerID(2800001)
	store := workplacestore.Store{}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	state, err := store.LockTx(ctx, transaction, player, at)
	if err != nil {
		t.Fatal(err)
	}
	state.Init()
	state.Sequence = 9
	state.Day = 5
	state.Initialized = true
	state.BonusLocation = 2
	state.BonusBase = 100
	state.BonusUsed = true
	state.Slots = map[int64]*d.Occurrence{1: {ID: "slot-1", Team: 3, Job: 7, Revision: "rev-1", Start: at.UnixMilli(), Award: map[string]any{"coins": 5}}}
	state.Selections = map[int64][]int64{1: {4, 5}}
	state.Last = map[int64]map[string]any{1: {"result": "ok"}}
	state.Diary = []map[string]any{{"day": 5, "note": "worked"}}
	if err := store.SaveTx(ctx, transaction, player, state, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM workplace_players WHERE player_id=$1`, int64(player)).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded d.State
	if err := payload.DecodeNumbers(workplaceTable, version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSameWorkplaceJSON(t, decoded, state)
	read, found, err := store.ReadTx(ctx, pool, player)
	if err != nil || !found {
		t.Fatalf("ReadTx found=%v err=%v", found, err)
	}
	assertSameWorkplaceJSON(t, read, state)
	expected, err := json.Marshal(state)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(expected)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored payload=%s want json.Marshal=%s", storedText, expectedText)
	}
}

func assertSameWorkplaceJSON(t *testing.T, got, want any) {
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
