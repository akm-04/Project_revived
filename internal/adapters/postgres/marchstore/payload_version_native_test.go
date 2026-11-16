//go:build postgres

package marchstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/marchstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripMarchStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH17_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH17_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	exec := func(statement string, arguments ...any) {
		t.Helper()
		if _, err := pool.Raw().Exec(ctx, statement, arguments...); err != nil {
			t.Fatalf("seed %q: %v", statement, err)
		}
	}
	exec(`INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(23,'payload-version-march',NULL,false,false,false,2325001,2399999,1,now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777723','payload-version-march','ACTIVE',now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(2300001,'77777777-7777-4777-8777-777777777723',23,now(),'payload-version-march') ON CONFLICT DO NOTHING`)
	at := time.Date(2026, 11, 16, 4, 0, 0, 123456000, time.UTC)
	player := identity.PlayerID(2300001)
	final := d.Run{
		Revision:       strings.Repeat("c", 64),
		Occurrence:     "occurrence-1",
		ResetDay:       20600,
		ResetUsed:      true,
		DrinkDay:       20600,
		Drinks:         2,
		Passed:         3,
		Won:            true,
		Extra:          true,
		HasFight:       true,
		Advanced:       true,
		Heroes:         map[string]d.Status{"2300002": {Hero: 2300002, Player: 2300001, Health: 1, HP: 850.5, MP: 100, Reborn: 0}},
		Loan:           &d.Loan{Player: 2300003, Unit: 2300004, Health: 1, HP: 900, MP: 50},
		Enemies:        []d.Enemy{{TableID: 5, AvatarFrame: 1, ConquerLevel: 10, ConquerLoop: 1, Player: 2399999, Name: "rival", Level: 30, Avatar: 7, Robot: 1, Heroes: map[string]map[string]any{"2300005": {"hp": float64(100)}}, Force: 12345}},
		Rewards:        map[string][]any{"1": {map[string]any{"table_id": int64(1), "item_num": int64(10)}}},
		RecommendDay:   20600,
		Recommend:      []int64{2300002},
		Pending:        "operation-1",
		Formation:      []int64{2300002, 0, 0, 0},
		BattleOrdinal:  2,
		LastResult:     json.RawMessage(`{"map_info":{"stage_done":1}}`),
		ChestReplies:   map[string][]any{"1": {map[string]any{"table_id": int64(1)}}},
		LifetimeChests: 1,
		Version:        4,
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	if _, err := (marchstore.Store{}).LockTx(ctx, transaction, player, at); err != nil {
		t.Fatal(err)
	}
	if err := (marchstore.Store{}).SaveTx(ctx, transaction, player, final, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM march_players WHERE player_id=$1`, int64(player)).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if directory := os.Getenv("GXB_R8_2C_BATCH17_CAPTURE"); directory != "" {
		captureGolden(t, filepath.Join(directory, "internal/adapters/postgres/marchstore/testdata/payloads/march_players.payload"), storedText)
		return
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded d.Run
	if err := payload.Decode("march_players", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSameJSON(t, decoded, final)
	readRun, found, err := (marchstore.Store{}).ReadTx(ctx, pool, player)
	if err != nil || !found {
		t.Fatalf("ReadTx found=%v err=%v", found, err)
	}
	assertSameJSON(t, readRun, final)
	expected, err := json.Marshal(final)
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

func assertSameJSON(t *testing.T, got, want any) {
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

func captureGolden(t *testing.T, directory, stored string) {
	t.Helper()
	var decoded d.Run
	if err := payload.Decode("march_players", 0, []byte(stored), &decoded); err != nil {
		t.Fatal(err)
	}
	expected, err := json.MarshalIndent(decoded, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(directory, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "v0.json"), []byte(stored), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "v0.expected.json"), expected, 0o644); err != nil {
		t.Fatal(err)
	}
}
