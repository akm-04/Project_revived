//go:build postgres

package rankingstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripRankingStore(t *testing.T) {
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
VALUES(11,'payload-version-ranking',NULL,false,false,false,1125001,1199999,1,now()) ON CONFLICT DO NOTHING`); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
VALUES($1,decode($1,'hex'),1,'probe','probe',jsonb_build_object('revision_id',$1,'schema_version',1,'compiler_version','probe','parser_version','probe')) ON CONFLICT DO NOTHING`, strings.Repeat("a", 64)); err != nil {
		t.Fatal(err)
	}
	server := identity.LogicalServerID(11)
	at := time.Date(2026, 11, 16, 3, 0, 0, 123456000, time.UTC)
	observedAt := at.Add(time.Minute)
	revision := strings.Repeat("a", 64)
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	metric := d.BoardMetric{
		Player: 1100001, Owner: d.GirlsBoard.SourceOwner, Policy: d.GirlsBoard.SourcePolicy, Semantics: d.GirlsBoard.SourceSemantics,
		Revision: revision, PopulationDigest: strings.Repeat("b", 64), FieldID: d.GirlsBoard.FieldID, Value: 7,
		SourceVersion: 1, PopulationVersion: 1, ObservedAt: observedAt,
	}
	entry := d.BoardEntry{Metric: metric, Display: d.BoardPresentation{Player: metric.Player, Name: "Golden", Level: 42}, ScoreSince: at}

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	root, err := (rankingstore.Store{}).LockBoardRootTx(ctx, transaction, d.GirlsBoard, server, at)
	if err != nil {
		t.Fatal(err)
	}
	next, snapshot, err := d.FreezeBoardSnapshot(root, observedAt, revision, operationID, []d.BoardEntry{entry})
	if err != nil {
		t.Fatalf("freeze fixture: %v", err)
	}
	if err := (rankingstore.Store{}).InsertBoardSnapshotTx(ctx, transaction, snapshot); err != nil {
		t.Fatal(err)
	}
	if err := (rankingstore.Store{}).SaveBoardRootTx(ctx, transaction, next, root.StateVersion); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	var rootText, snapshotText string
	var rootVersion, snapshotVersion int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM ranking_girls_roots WHERE logical_server_id=$1 AND policy_id=$2`, int64(server), d.GirlsBoard.Policy).Scan(&rootText, &rootVersion); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM ranking_girls_snapshots WHERE logical_server_id=$1 AND policy_id=$2 AND generation=$3`, int64(server), d.GirlsBoard.Policy, snapshot.Generation).Scan(&snapshotText, &snapshotVersion); err != nil {
		t.Fatal(err)
	}
	if rootVersion != payload.Current || snapshotVersion != payload.Current {
		t.Fatalf("payload_version root=%d snapshot=%d want=%d", rootVersion, snapshotVersion, payload.Current)
	}
	for name, row := range map[string]struct {
		stored  string
		written any
	}{
		"root":     {rootText, next},
		"snapshot": {snapshotText, snapshot},
	} {
		marshalled, err := json.Marshal(row.written)
		if err != nil {
			t.Fatal(err)
		}
		var expectedText string
		if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
			t.Fatal(err)
		}
		if row.stored != expectedText {
			t.Fatalf("%s stored=%s want json.Marshal=%s", name, row.stored, expectedText)
		}
	}
	var decodedRoot d.BoardRoot
	if err := payload.Decode("ranking_girls_roots", rootVersion, []byte(rootText), &decodedRoot); err != nil {
		t.Fatalf("root strict decode: %v", err)
	}
	var decodedSnapshot d.BoardSnapshot
	if err := payload.Decode("ranking_girls_snapshots", snapshotVersion, []byte(snapshotText), &decodedSnapshot); err != nil {
		t.Fatalf("snapshot strict decode: %v", err)
	}
	if !reflect.DeepEqual(decodedRoot, next) || !reflect.DeepEqual(decodedSnapshot, snapshot) {
		t.Fatalf("decoded root=%#v snapshot=%#v", decodedRoot, decodedSnapshot)
	}
	readRootRuns, err := (rankingstore.Store{}).ReadBoardRootRunsTx(ctx, pool, d.GirlsBoard, server)
	if err != nil || len(readRootRuns) != 0 {
		t.Fatalf("ReadBoardRootRunsTx runs=%v err=%v", readRootRuns, err)
	}
	readSnapshot, found, err := (rankingstore.Store{}).ReadBoardSnapshotTx(ctx, pool, d.GirlsBoard, server, snapshot.Generation)
	if err != nil || !found || !reflect.DeepEqual(readSnapshot, snapshot) {
		t.Fatalf("ReadBoardSnapshotTx found=%v err=%v read=%#v want=%#v", found, err, readSnapshot, snapshot)
	}
}
