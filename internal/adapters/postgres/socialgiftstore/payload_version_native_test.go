//go:build postgres

package socialgiftstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/socialgiftstore"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripSocialGiftStore(t *testing.T) {
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
VALUES(12,'payload-version-gift',NULL,false,false,false,1225001,1299999,1,now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777712','payload-version-gift','ACTIVE',now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(1225001,'77777777-7777-4777-8777-777777777712',12,now(),'payload-version-gift')`); err != nil {
		t.Fatal(err)
	}
	revision := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	if _, err := transaction.Exec(ctx, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
VALUES($1,decode($1,'hex'),1,'probe','probe',jsonb_build_object('revision_id',$1,'schema_version',1,'compiler_version','probe','parser_version','probe'))`, revision); err != nil {
		t.Fatal(err)
	}
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	transferID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	written := sg.ClaimOperation{ID: operationID, Recipient: 1225001, Fingerprint: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StartedAt: at, DecisionAt: at, Day: "2026-11-16", Revision: revision, Result: sg.Result{NoticeIDs: []socialinbox.NoticeID{1}, TransferIDs: []string{transferID.String()}, Amount: 5, Revision: revision}}
	if err := (socialgiftstore.Store{}).InsertClaim(ctx, transaction, written); err != nil {
		t.Fatal(err)
	}

	var storedText string
	var version int16
	if err := transaction.QueryRow(ctx, `SELECT semantic_result::text,payload_version FROM social_gift_claim_operations WHERE operation_id=$1::uuid`, operationID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	marshalled, err := json.Marshal(written.Result)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := transaction.QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored semantic_result=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded sg.Result
	if err := payload.Decode("social_gift_claim_operations", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !reflect.DeepEqual(decoded, written.Result) {
		t.Fatalf("decoded=%#v want=%#v", decoded, written.Result)
	}
	read, found, err := (socialgiftstore.Store{}).ReadClaim(ctx, transaction, operationID)
	if err != nil || !found {
		t.Fatalf("ReadClaim found=%v err=%v", found, err)
	}
	if !reflect.DeepEqual(read, written) {
		t.Fatalf("ReadClaim=%#v want=%#v", read, written)
	}
}
