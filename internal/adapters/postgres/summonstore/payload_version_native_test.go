//go:build postgres

package summonstore_test

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/summonstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripSummonStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH16_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH16_DSN for a migrated test database is missing")
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
VALUES(12,'payload-version-summon',NULL,false,false,false,1225001,1299999,1,now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777712','payload-version-summon','ACTIVE',now()) ON CONFLICT DO NOTHING`)
	exec(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(1200001,'77777777-7777-4777-8777-777777777712',12,now(),'payload-version-summon') ON CONFLICT DO NOTHING`)
	at := time.Date(2026, 11, 16, 4, 0, 0, 123456000, time.UTC)
	player := identity.PlayerID(1200001)
	fresh := d.State{Counters: map[string]int64{"small": 1, "medium_paid": 0}}
	final := fresh
	final.Counters = map[string]int64{"small": 2, "medium_paid": 0, "medium_free": 3}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := (summonstore.Store{}).LockTx(ctx, transaction, player, fresh, at); err != nil {
		t.Fatal(err)
	}
	if err := (summonstore.Store{}).SaveTx(ctx, transaction, player, final, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	exec(`INSERT INTO summon_tuning(payload,updated_at) VALUES(jsonb_build_object('version',1,'partner_id',50001002),$1) ON CONFLICT DO NOTHING`, at)
	var counterText, tuningText string
	var counterVersion, tuningVersion int16
	if err := pool.Raw().QueryRow(ctx, `SELECT counters::text,payload_version FROM summon_players WHERE player_id=$1`, int64(player)).Scan(&counterText, &counterVersion); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM summon_tuning`).Scan(&tuningText, &tuningVersion); err != nil {
		t.Fatal(err)
	}
	if directory := os.Getenv("GXB_R8_2C_BATCH16_CAPTURE"); directory != "" {
		captureGolden(t, filepath.Join(directory, "internal/adapters/postgres/summonstore/testdata/payloads/summon_players.counters"), counterText, final.Counters)
		captureGolden(t, filepath.Join(directory, "internal/adapters/postgres/summonstore/testdata/payloads/summon_tuning.payload"), tuningText, d.Tuning{Version: 1, Partner: 50001002})
		return
	}
	if counterVersion != payload.Current {
		t.Fatalf("counters payload_version=%d want=%d", counterVersion, payload.Current)
	}
	if tuningVersion != 0 {
		t.Fatalf("summon_tuning payload_version=%d want=0 (operator SQL writer)", tuningVersion)
	}
	marshalled, err := json.Marshal(final.Counters)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if counterText != expectedText {
		t.Fatalf("stored counters=%s want json.Marshal=%s", counterText, expectedText)
	}
	var decodedCounters map[string]int64
	if err := payload.Decode("summon_players", counterVersion, []byte(counterText), &decodedCounters); err != nil {
		t.Fatalf("strict counters decode: %v", err)
	}
	if !reflect.DeepEqual(decodedCounters, final.Counters) {
		t.Fatalf("decoded counters=%v want=%v", decodedCounters, final.Counters)
	}
	readState, found, err := (summonstore.Store{}).ReadTx(ctx, pool, player)
	if err != nil || !found || !reflect.DeepEqual(readState.Counters, final.Counters) {
		t.Fatalf("ReadTx found=%v err=%v counters=%v want=%v", found, err, readState.Counters, final.Counters)
	}
	tuning, found, err := (summonstore.Store{}).TuningTx(ctx, pool)
	if err != nil || !found || tuning.Version != 1 || tuning.Partner != 50001002 {
		t.Fatalf("TuningTx found=%v err=%v tuning=%#v", found, err, tuning)
	}
}

func captureGolden(t *testing.T, directory, stored string, value any) {
	t.Helper()
	expected, err := json.MarshalIndent(value, "", "  ")
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
