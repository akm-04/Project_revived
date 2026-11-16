//go:build postgres

package socialinboxstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripSocialInboxStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH15_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH15_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err := transaction.Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(13,'payload-version-inbox',NULL,false,false,false,1325001,1399999,1,now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777713','payload-version-inbox','ACTIVE',now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(1325003,'77777777-7777-4777-8777-777777777713',13,now(),'payload-version-inbox')`); err != nil {
		t.Fatal(err)
	}
	receiptIDs := []ids.UUID{newUUID(t), newUUID(t)}
	for index, receiptID := range receiptIDs {
		if _, err := transaction.Exec(ctx, `INSERT INTO gxb_operation_receipts(receipt_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,recorded_at)
VALUES($1,'player',$2,'payload-version-inbox','golden','query',$3,decode(repeat('ab',32),'hex'),'payload.golden.v1','{}'::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`, receiptID.String(), "132500"+string(rune('1'+index)), "payload-version-inbox-"+string(rune('1'+index))); err != nil {
			t.Fatal(err)
		}
	}

	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	fingerprint := [32]byte{1}
	proof := gi.TargetProof{SourceID: newUUID(t), Recipient: 1325003, SourceFingerprint: fingerprint, ReceiptID: receiptIDs[0], State: gi.Suppressed, NoticeID: 0, RootVersion: 0, DecisionAt: at}
	store := socialinboxstore.Store{}
	if err := store.InsertInviteMaterializationTx(ctx, transaction, proof); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := transaction.QueryRow(ctx, `SELECT target_payload::text,payload_version FROM social_guild_invite_materializations WHERE source_id=$1::uuid`, proof.SourceID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	assertStoredPayload(t, ctx, transaction, "social_guild_invite_materializations", proof, storedText, version)
	readProof, found, err := store.ReadInviteMaterializationTx(ctx, transaction, proof.SourceID)
	if err != nil || !found {
		t.Fatalf("ReadInviteMaterializationTx found=%v err=%v", found, err)
	}
	if !reflect.DeepEqual(readProof, proof) {
		t.Fatalf("materialization=%#v want=%#v", readProof, proof)
	}

	invalidation := gi.InvalidationProof{MarkerID: newUUID(t), SourceID: newUUID(t), Recipient: 1325003, MarkerFingerprint: fingerprint, SourceFingerprint: fingerprint, ReceiptID: receiptIDs[1], NoticeID: 0, RootVersion: 0, NoticeStateVersion: 0, SourceSerial: 1, SourceKey: "golden:key", Consumed: false, DecisionAt: at}
	if err := store.InsertInviteInvalidationTx(ctx, transaction, invalidation); err != nil {
		t.Fatal(err)
	}
	if err := transaction.QueryRow(ctx, `SELECT target_payload::text,payload_version FROM social_guild_invite_invalidations WHERE marker_id=$1::uuid AND source_id=$2::uuid`, invalidation.MarkerID.String(), invalidation.SourceID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	assertStoredPayload(t, ctx, transaction, "social_guild_invite_invalidations", invalidation, storedText, version)
	readInvalidation, found, err := store.ReadInviteInvalidationTx(ctx, transaction, invalidation.MarkerID, invalidation.SourceID)
	if err != nil || !found {
		t.Fatalf("ReadInviteInvalidationTx found=%v err=%v", found, err)
	}
	if !reflect.DeepEqual(readInvalidation, invalidation) {
		t.Fatalf("invalidation=%#v want=%#v", readInvalidation, invalidation)
	}
}

func assertStoredPayload(t *testing.T, ctx context.Context, transaction tx.Tx, table string, written any, storedText string, version int16) {
	t.Helper()
	if version != payload.Current {
		t.Fatalf("%s payload_version=%d want=%d", table, version, payload.Current)
	}
	marshalled, err := json.Marshal(written)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := transaction.QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("%s stored payload=%s want json.Marshal=%s", table, storedText, expectedText)
	}
}

func newUUID(t *testing.T) ids.UUID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}
