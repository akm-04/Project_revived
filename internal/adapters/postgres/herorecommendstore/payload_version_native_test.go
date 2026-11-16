//go:build postgres

package herorecommendstore_test

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/herorecommendstore"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripHeroRecommendStore(t *testing.T) {
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
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(10,'payload-version-herorecommend',NULL,false,false,false,1025001,1099999,1,now()) ON CONFLICT DO NOTHING`); err != nil {
		t.Fatal(err)
	}
	observedAt := time.Date(2026, 11, 16, 1, 2, 3, 123456000, time.UTC)
	written := d.Snapshot{
		Schema:     d.Schema,
		Server:     10,
		Generation: 1,
		Revision:   strings.Repeat("a", 64),
		ObservedAt: observedAt,
		Digest:     strings.Repeat("b", 64),
		Overview: d.Overview{
			SubRankList:   map[string][]int64{"11": {100001, 100002}},
			TotalRankList: []map[string]any{{"player": float64(100001), "force": float64(42)}},
		},
		Details: map[string]d.Detail{
			"50001001": {
				Score:     42,
				TopPlayer: d.PlayerCard{PlayerID: 100001, Name: "Golden", Level: 42},
				TopHero:   map[string]any{"hero_id": float64(50001001)},
				Formations: map[string]any{
					"1": map[string]any{"slots": []any{float64(1), float64(2)}},
				},
				ForceRows: []d.ForceRow{{Player: d.PlayerCard{PlayerID: 100001, Name: "Golden", Level: 42}, Force: 42}},
			},
		},
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if err := (herorecommendstore.Store{}).InsertSnapshotTx(ctx, transaction, written); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM hero_recommend_snapshots WHERE logical_server_id=$1 AND generation=$2`, written.Server, written.Generation).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if directory := os.Getenv("GXB_R8_2C_BATCH16_CAPTURE"); directory != "" {
		captureGolden(t, filepath.Join(directory, "internal/adapters/postgres/herorecommendstore/testdata/payloads/hero_recommend_snapshots.payload"), storedText, written)
		return
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	marshalled, err := json.Marshal(written)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored payload=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded d.Snapshot
	if err := payload.Decode("hero_recommend_snapshots", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !reflect.DeepEqual(decoded, written) {
		t.Fatalf("decoded=%#v want=%#v", decoded, written)
	}
	read, found, err := (herorecommendstore.Store{}).LatestSnapshotTx(ctx, pool, identity.LogicalServerID(10))
	if err != nil || !found || !reflect.DeepEqual(read, written) {
		t.Fatalf("LatestSnapshotTx found=%v err=%v read=%#v want=%#v", found, err, read, written)
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
