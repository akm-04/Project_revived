//go:build postgres

package occultstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripOccultStore(t *testing.T) {
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
VALUES(25,'payload-version-occult',NULL,false,false,false,2525001,2599999,1,now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777725','payload-version-occult','ACTIVE',now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(2500001,'77777777-7777-4777-8777-777777777725',25,now(),'payload-version-occult') ON CONFLICT DO NOTHING`)
	at := time.Date(2026, 11, 16, 4, 0, 0, 123456000, time.UTC)
	player := identity.PlayerID(2500001)
	final := d.Scores{"1": 1000, "2": 1480}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	if _, err := (occultstore.Store{}).LockPlayerTx(ctx, transaction, 25, player, at); err != nil {
		t.Fatal(err)
	}
	if err := (occultstore.Store{}).SaveScoresTx(ctx, transaction, player, final, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT scores::text,payload_version FROM occult_players WHERE player_id=$1`, int64(player)).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if directory := os.Getenv("GXB_R8_2C_BATCH17_CAPTURE"); directory != "" {
		captureGolden(t, filepath.Join(directory, "internal/adapters/postgres/occultstore/testdata/payloads/occult_players.scores"), storedText)
		return
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded d.Scores
	if err := payload.Decode("occult_players", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSameJSON(t, decoded, final)
	readScores, err := (occultstore.Store{}).ReadScoresTx(ctx, pool, player)
	if err != nil {
		t.Fatal(err)
	}
	assertSameJSON(t, readScores, final)
	expected, err := json.Marshal(final)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(expected)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored scores=%s want json.Marshal=%s", storedText, expectedText)
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
	var decoded d.Scores
	if err := payload.Decode("occult_players", 0, []byte(stored), &decoded); err != nil {
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
