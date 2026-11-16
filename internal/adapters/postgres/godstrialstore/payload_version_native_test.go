//go:build postgres

package godstrialstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/godstrialstore"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripGodstrialStore(t *testing.T) {
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
VALUES(22,'payload-version-godstrial',NULL,false,false,false,2225001,2299999,1,now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777722','payload-version-godstrial','ACTIVE',now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(2200001,'77777777-7777-4777-8777-777777777722',22,now(),'payload-version-godstrial') ON CONFLICT DO NOTHING`)
	at := time.Date(2026, 11, 16, 4, 0, 0, 123456000, time.UTC)
	player := identity.PlayerID(2200001)
	line := grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "gold", ItemID: 1, Amount: 100, Domain: "i5", Metadata: map[string]string{"source": "godstrial"}}
	final := d.State{
		Player:       int64(player),
		Server:       22,
		Sequence:     3,
		LastObserved: 1763000000,
		Wins:         map[int64]int64{1: 2, 2: 1},
		Fight: &d.Fight{
			ID: "fight-1", Revision: strings.Repeat("b", 64), Provider: "combat",
			Campaign: 11, Pet: 0, Deadline: 1763000600,
			Formation: []int64{int64(player), 0, 0, 0},
			Lines:     []grant.Line{line},
		},
		Auto: &d.Auto{
			ID: "auto-1", Revision: "revision-1", Provider: "combat",
			Campaign: 11, Times: 2, Start: 1763000000, Due: 1763003600,
			Lines: []grant.Line{line},
		},
		LastResult: map[string]any{"campaign": int64(11)},
		LastStar:   3,
		LastAuto:   map[string]any{"times": int64(1)},
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	if _, err := (godstrialstore.Store{}).LockTx(ctx, transaction, player, at); err != nil {
		t.Fatal(err)
	}
	if err := (godstrialstore.Store{}).SaveTx(ctx, transaction, player, final, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM godstrial_players WHERE player_id=$1`, int64(player)).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded d.State
	if err := payload.Decode("godstrial_players", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSameJSON(t, decoded, final)
	readState, found, err := (godstrialstore.Store{}).ReadTx(ctx, pool, player)
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
