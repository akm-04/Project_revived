//go:build postgres

package memoirstore_test

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
	"gxb.local/backend/v2/internal/adapters/postgres/memoirstore"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/march"
	d "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripMemoirStore(t *testing.T) {
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
VALUES(24,'payload-version-memoir',NULL,false,false,false,2425001,2499999,1,now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777724','payload-version-memoir','ACTIVE',now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(2400001,'77777777-7777-4777-8777-777777777724',24,now(),'payload-version-memoir') ON CONFLICT DO NOTHING`)
	at := time.Date(2026, 11, 16, 4, 0, 0, 123456000, time.UTC)
	player := identity.PlayerID(2400001)
	board := d.Board{Cells: make([]int64, d.BoardCells), Open: map[int]int64{1: 1}, Enemies: map[int]int64{d.GuardianPosition: 9}, Position: 1}
	board.Cells[d.FinalPosition-1] = d.Endpoint
	board.Cells[d.GuardianPosition-1] = d.Guardian
	final := d.State{
		Occurrence:  "occurrence-1",
		Revision:    strings.Repeat("d", 64),
		Girl:        2400002,
		Floor:       2,
		Board:       board,
		ReviveTimes: 1,
		Heroes:      map[int64]combat.ActorStatus{2400002: {Player: 2400001, Identity: 2400002, HP: 100, MP: 50, Reborn: 0}},
		Enemies:     map[int]d.EnemyCarry{1: {Round: 1, Statuses: map[int64]combat.ActorStatus{2400003: {Identity: 2400003, HP: 80, MP: 10}}}},
		Opponents:   map[int]march.Enemy{1: {TableID: 5, Name: "rival", Heroes: map[string]map[string]any{}}},
		Drops:       []campaign.Item{{ItemID: 1, Num: 2}},
		MaxFloor:    map[int64]int{1: 3},
		Sequence:    5,
		Pending: &d.Pending{
			Attempt: "attempt-1", Generation: "generation-1", Revision: "revision-1",
			Grid: 2, Kind: 1, FirstWave: 1,
			Rewards:   []campaign.Item{{ItemID: 2, Num: 1}},
			Formation: []int64{2400002, 0, 0, 0},
			Deadline:  1763000000,
		},
		LastGrid:   2,
		LastResult: map[string]any{"battle_info": map[string]any{"win": true}},
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	if _, err := (memoirstore.Store{}).LockTx(ctx, transaction, player, at); err != nil {
		t.Fatal(err)
	}
	if err := (memoirstore.Store{}).SaveTx(ctx, transaction, player, final, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM memoir_players WHERE player_id=$1`, int64(player)).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if directory := os.Getenv("GXB_R8_2C_BATCH17_CAPTURE"); directory != "" {
		captureGolden(t, filepath.Join(directory, "internal/adapters/postgres/memoirstore/testdata/payloads/memoir_players.payload"), storedText)
		return
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded d.State
	if err := payload.Decode("memoir_players", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSameJSON(t, decoded, final)
	readState, found, err := (memoirstore.Store{}).ReadTx(ctx, pool, player)
	if err != nil || !found {
		t.Fatalf("ReadTx found=%v err=%v", found, err)
	}
	assertSameJSON(t, readState, final)
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
	var decoded d.State
	if err := payload.Decode("memoir_players", 0, []byte(stored), &decoded); err != nil {
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
