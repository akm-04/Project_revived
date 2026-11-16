//go:build postgres

package i5store_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripI5StoreMail(t *testing.T) {
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
VALUES(9,'payload-version-i5',NULL,false,false,false,925003,999999,1,now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777709','payload-version-i5','ACTIVE',now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(925001,'77777777-7777-4777-8777-777777777709',9,now(),'payload-version-i5')`); err != nil {
		t.Fatal(err)
	}

	mailUUID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	metadata := map[string]string{"golden": "yes"}
	written := mail.Record{MailUUID: mailUUID, Recipient: identity.PlayerID(925001), Address: mail.Address{Namespace: mail.Normal, WireID: 1}, SourceKind: "golden", SourceKey: "golden:1", Category: 1, Title: "t", Sender: "s", Body: "b", CreatedAt: at, Shown: true, Platform: mail.AnyPlatform, CompatibilityPolicyVersion: "GOLDEN_POLICY", StateVersion: 1, Attachments: []mail.Attachment{{Ordinal: 0, Line: grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "coin", Amount: 5, Metadata: metadata}}}}
	store := i5store.Store{Queryer: pool}
	if err := (i5store.Store{}).InsertMailTx(ctx, transaction, written); err != nil {
		t.Fatal(err)
	}

	var storedText string
	var version int16
	if err := transaction.QueryRow(ctx, `SELECT metadata::text,payload_version FROM mail_attachments WHERE mail_uuid=$1::uuid`, mailUUID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	marshalled, err := json.Marshal(metadata)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := transaction.QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored metadata=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded map[string]string
	if err := payload.Decode("mail_attachments", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !reflect.DeepEqual(decoded, metadata) {
		t.Fatalf("decoded=%#v want=%#v", decoded, metadata)
	}

	listed, total, fresh, err := store.ListMailTx(ctx, transaction, identity.PlayerID(925001), at.Add(time.Hour), 10)
	if err != nil || total != 1 || fresh != 1 || len(listed) != 1 {
		t.Fatalf("ListMailTx total=%d fresh=%d rows=%d err=%v", total, fresh, len(listed), err)
	}
	if !reflect.DeepEqual(listed[0].Attachments, written.Attachments) {
		t.Fatalf("ListMailTx attachments=%#v want=%#v", listed[0].Attachments, written.Attachments)
	}
	locked, err := (i5store.Store{}).LockMailTx(ctx, transaction, identity.PlayerID(925001), written.Address)
	if err != nil || !reflect.DeepEqual(locked.Attachments, written.Attachments) {
		t.Fatalf("LockMailTx attachments=%#v want=%#v err=%v", locked.Attachments, written.Attachments, err)
	}

	tuning, found, err := store.MailTuningTx(ctx, transaction)
	if err != nil || !found {
		t.Fatalf("MailTuningTx found=%v err=%v", found, err)
	}
	if tuning != (mail.Tuning{Version: 1, OverflowAfterLoginSeconds: 3600, OrdinarySeconds: 604800}) {
		t.Fatalf("MailTuningTx=%+v", tuning)
	}
}
