//go:build postgres

package playerdata_test

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/playerdatastore"
	"gxb.local/backend/v2/internal/application/playerdata"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func exportPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_R8_PLAYER_DATA_DSN")
	if dsn == "" {
		t.Fatal("GXB_R8_PLAYER_DATA_DSN required")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func exportRoot(t *testing.T) string {
	t.Helper()
	directory, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	for {
		if _, err := os.Stat(filepath.Join(directory, "docs", "data", "PLAYER_RESTORE_PLAN.json")); err == nil {
			return directory
		}
		parent := filepath.Dir(directory)
		if parent == directory {
			t.Fatal("backend root with docs/data/PLAYER_RESTORE_PLAN.json not found")
		}
		directory = parent
	}
}

func exportPlan(t *testing.T) (playerdata.Plan, string) {
	t.Helper()
	path := filepath.Join(exportRoot(t), "docs", "data", "PLAYER_RESTORE_PLAN.json")
	plan, digest, err := playerdata.LoadPlan(path)
	if err != nil {
		t.Fatal(err)
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256(raw)
	if digest != hex.EncodeToString(sum[:]) {
		t.Fatalf("plan digest %s does not pin the file", digest)
	}
	return plan, digest
}

type exportedPlayer struct {
	id      int64
	server  int32
	blobKey string
}

func seedPlayer(t *testing.T, pool *pg.Pool, populated bool) exportedPlayer {
	t.Helper()
	ctx := context.Background()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	operation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	var serverID int32
	if err := transaction.QueryRow(ctx, `SELECT logical_server_id FROM logical_servers ORDER BY logical_server_id LIMIT 1`).Scan(&serverID); err != nil {
		t.Fatal(err)
	}
	var playerID int64
	if err := transaction.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=$1 RETURNING next_player_id-1`, serverID).Scan(&playerID); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,$3,clock_timestamp(),'r86b-export-native')`, playerID, account.String(), serverID); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO daily_consumption_players(player_id,counts,updated_at,payload_version) VALUES($1,'{"1001":2}'::jsonb,clock_timestamp(),1)`, playerID); err != nil {
		t.Fatal(err)
	}
	seeded := exportedPlayer{id: playerID, server: serverID}
	if !populated {
		if err := transaction.Commit(ctx); err != nil {
			t.Fatal(err)
		}
		return seeded
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO player_public_profile_roots(player_id,intro,show_type_ids,hide_subtypes,share_switch,is_first_time,state_version,policy_version,created_at,updated_at)
VALUES($1,'native export',ARRAY[]::bigint[],ARRAY[]::smallint[],1,0,1,'I7B_PUBLIC_V1',clock_timestamp(),clock_timestamp())`, playerID); err != nil {
		t.Fatal(err)
	}
	const digest = "a3f1c2d4e5b60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90"
	reference, err := json.Marshal(map[string]any{
		"operation": operation.String(),
		"asset":     map[string]any{"policy": "I7B_PROFILE_PNG_V1", "sha256": digest, "md5": "00112233445566778899aabbccddeeff", "size": 10, "width": 1, "height": 1},
		"url":       "http://127.0.0.1:18080/profile-media/" + operation.String() + "/" + digest + ".png",
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO player_public_profile_media_history(operation_id,player_id,logical_server_id,reference,root_version,decision_at,payload_version)
VALUES($1::uuid,$2,$3,$4::jsonb,1,clock_timestamp(),1)`, operation.String(), playerID, serverID, string(reference)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	seeded.blobKey = digest + ".png"
	return seeded
}

func exportService(t *testing.T, pool *pg.Pool, plan playerdata.Plan, digest string, playerID int64, at time.Time) playerdata.Document {
	t.Helper()
	document, err := (playerdata.Service{Database: pool, Reader: playerdatastore.Store{}}).Export(context.Background(), plan, digest, playerID, at)
	if err != nil {
		t.Fatal(err)
	}
	return document
}

func encodeDocument(t *testing.T, document playerdata.Document) string {
	t.Helper()
	var buffer bytes.Buffer
	if err := playerdata.Encode(&buffer, document); err != nil {
		t.Fatal(err)
	}
	return buffer.String()
}

func assertPlanTables(t *testing.T, plan playerdata.Plan, document playerdata.Document) {
	t.Helper()
	if len(document.Tables) != len(plan.Tables) {
		t.Fatalf("export has %d tables, plan has %d", len(document.Tables), len(plan.Tables))
	}
	for index, table := range plan.Tables {
		exported := document.Tables[index]
		if exported.Table != table.Table || exported.Action != table.Action {
			t.Fatalf("table %d is %s/%s, plan says %s/%s", index, exported.Table, exported.Action, table.Table, table.Action)
		}
		if exported.Rows == nil {
			t.Fatalf("table %s has null rows", exported.Table)
		}
	}
}

func rowFor(t *testing.T, document playerdata.Document, table string) map[string]json.RawMessage {
	t.Helper()
	for _, exported := range document.Tables {
		if exported.Table != table {
			continue
		}
		if len(exported.Rows) != 1 {
			t.Fatalf("table %s has %d rows, want 1", table, len(exported.Rows))
		}
		var row map[string]json.RawMessage
		if err := json.Unmarshal(exported.Rows[0], &row); err != nil {
			t.Fatal(err)
		}
		return row
	}
	t.Fatalf("table %s missing from export", table)
	return nil
}

func TestExportFreshPlayer(t *testing.T) {
	pool := exportPool(t)
	plan, digest := exportPlan(t)
	player := seedPlayer(t, pool, false)
	at := time.Date(2026, 11, 16, 1, 2, 3, 4, time.UTC)

	document := exportService(t, pool, plan, digest, player.id, at)
	if document.Format != playerdata.ExportFormat || document.PlayerID != player.id || document.LogicalServerID != player.server {
		t.Fatalf("header %+v", document)
	}
	if !document.ExportedAt.Equal(at) {
		t.Fatalf("exported_at %s", document.ExportedAt)
	}
	if document.PlanSHA256 != digest {
		t.Fatalf("plan_sha256 %s", document.PlanSHA256)
	}
	var gooseVersion int64
	if err := pool.QueryRow(context.Background(), `SELECT COALESCE(max(version_id),0) FROM goose_db_version WHERE is_applied`).Scan(&gooseVersion); err != nil {
		t.Fatal(err)
	}
	if document.SchemaVersion != gooseVersion {
		t.Fatalf("schema_version %d, goose %d", document.SchemaVersion, gooseVersion)
	}
	if len(document.BlobKeys) != 0 {
		t.Fatalf("fresh player has blob keys %v", document.BlobKeys)
	}
	assertPlanTables(t, plan, document)

	players := rowFor(t, document, playerdata.PlayersTable)
	if string(players["player_id"]) != strconv.FormatInt(player.id, 10) {
		t.Fatalf("players row %s", players["player_id"])
	}
	consumption := rowFor(t, document, "daily_consumption_players")
	if string(consumption["payload_version"]) != "1" {
		t.Fatalf("payload_version %s", consumption["payload_version"])
	}
	if !json.Valid([]byte(encodeDocument(t, document))) {
		t.Fatal("export document is not valid JSON")
	}
}

func TestExportPopulatedPlayerIsStableAndListsBlobKeys(t *testing.T) {
	pool := exportPool(t)
	plan, digest := exportPlan(t)
	player := seedPlayer(t, pool, true)
	firstAt := time.Date(2026, 11, 16, 1, 2, 3, 4, time.UTC)
	secondAt := time.Date(2026, 11, 17, 5, 6, 7, 8, time.UTC)

	first := exportService(t, pool, plan, digest, player.id, firstAt)
	second := exportService(t, pool, plan, digest, player.id, secondAt)
	if len(first.BlobKeys) != 1 || first.BlobKeys[0] != player.blobKey {
		t.Fatalf("blob keys %v", first.BlobKeys)
	}
	if !reflect.DeepEqual(first.BlobKeys, second.BlobKeys) {
		t.Fatalf("blob keys changed between exports: %v %v", first.BlobKeys, second.BlobKeys)
	}
	media := rowFor(t, first, playerdata.MediaHistoryTable)
	if string(media["payload_version"]) != "1" {
		t.Fatalf("media payload_version %s", media["payload_version"])
	}
	first.ExportedAt = time.Time{}
	second.ExportedAt = time.Time{}
	if !reflect.DeepEqual(first, second) {
		t.Fatal("two exports of an unchanged player differ beyond exported_at")
	}
	firstText := encodeDocument(t, exportService(t, pool, plan, digest, player.id, firstAt))
	secondText := encodeDocument(t, exportService(t, pool, plan, digest, player.id, secondAt))
	if firstText == secondText {
		t.Fatal("exported_at did not reach the encoded document")
	}
	replaced := strings.Replace(firstText, firstAt.Format(time.RFC3339Nano), secondAt.Format(time.RFC3339Nano), 1)
	if replaced != secondText {
		t.Fatal("encoded exports differ beyond exported_at")
	}
}

func TestExportRefusesUnknownPlayer(t *testing.T) {
	pool := exportPool(t)
	plan, digest := exportPlan(t)
	_, err := (playerdata.Service{Database: pool, Reader: playerdatastore.Store{}}).Export(context.Background(), plan, digest, 99999999999, time.Now())
	if !errors.Is(err, playerdata.ErrPlayerNotFound) {
		t.Fatalf("want ErrPlayerNotFound, got %v", err)
	}
}
