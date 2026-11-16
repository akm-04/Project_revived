//go:build postgres

package dodgeballstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dodgeballstore"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripDodgeballStore(t *testing.T) {
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
VALUES(21,'payload-version-dodgeball',NULL,false,false,false,2125001,2199999,1,now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777721','payload-version-dodgeball','ACTIVE',now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(2100001,'77777777-7777-4777-8777-777777777721',21,now(),'payload-version-dodgeball') ON CONFLICT DO NOTHING`)
	at := time.Date(2026, 11, 16, 4, 0, 0, 123456000, time.UTC)
	player := identity.PlayerID(2100001)
	final := dodgeball.State{
		Day:             20600,
		Incoming:        1,
		Played:          2,
		Invited:         map[int64]bool{2100002: true, 2100003: false},
		Sequence:        7,
		LastFingerprint: "fingerprint-7",
		Pending: &dodgeball.Occurrence{
			Identity: "occurrence-7",
			Revision: strings.Repeat("a", 64),
			Friend:   2100002,
			Deadline: 1763000000,
			Board:    dodgeball.Board{Monsters: []int64{101, 102}, Buffs: []dodgeball.PositionedBuff{{ID: 7, Position: 2}}, Marked: []int64{101}},
			Marked:   101,
			Draws:    &combat.DrawPackage{Policy: "dodgeball.draw/v1", Version: 1, Streams: map[string][]int64{"self": {1, 2}}},
		},
		LastResult: map[string]any{"error_code": int64(0)},
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	if _, err := (dodgeballstore.Store{}).LockTx(ctx, transaction, player, at); err != nil {
		t.Fatal(err)
	}
	if err := (dodgeballstore.Store{}).SaveTx(ctx, transaction, player, final, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM dodgeball_players WHERE player_id=$1`, int64(player)).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded dodgeball.State
	if err := payload.Decode("dodgeball_players", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSameJSON(t, decoded, final)
	readState, found, err := (dodgeballstore.Store{}).ReadTx(ctx, pool, player)
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
