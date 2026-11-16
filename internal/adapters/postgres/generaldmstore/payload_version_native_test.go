//go:build postgres

package generaldmstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/generaldmstore"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripGeneralDMStore(t *testing.T) {
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
VALUES(11,'payload-version-generaldm',NULL,false,false,false,1125003,1199999,1,now())`); err != nil {
		t.Fatal(err)
	}
	for index, playerID := range []int64{1125001, 1125003} {
		accountID := "77777777-7777-4777-8777-77777777771" + string(rune('0'+index))
		if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',now())`, accountID, "payload-version-generaldm-"+string(rune('0'+index))); err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,11,now(),'payload-version-generaldm')`, playerID, accountID); err != nil {
			t.Fatal(err)
		}
	}

	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	written := dm.Intent{ID: operationID.String(), Digest: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", Sender: 1125001, Recipient: 1125003, Message: "hello", AcceptedAt: at, ExpiresAt: at.Add(dm.IntentLifetime), BlockVersion: 0, Bindings: []dm.Binding{{ContextID: "ctx", ContextGeneration: 1, SessionID: "sess", SessionLiveness: 1, ContextLiveness: 1, RealtimeInstanceID: "rt", ConnectionGeneration: 1, OwnerFence: 1, LogicalServerID: 11}}, Status: dm.Pending, StateVersion: 1, LastObservedAt: at}
	if err := (generaldmstore.Store{}).InsertTx(ctx, transaction, written); err != nil {
		t.Fatal(err)
	}

	var storedText string
	var version int16
	if err := transaction.QueryRow(ctx, `SELECT payload::text,payload_version FROM personal_dm_payloads WHERE operation_id=$1::uuid`, operationID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
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
		t.Fatalf("stored payload=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded dm.Intent
	if err := payload.Decode("personal_dm_payloads", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !reflect.DeepEqual(decoded, written) {
		t.Fatalf("decoded=%#v want=%#v", decoded, written)
	}
	found, ok, err := (generaldmstore.Store{}).Find(ctx, transaction, operationID.String())
	if err != nil || !ok {
		t.Fatalf("Find found=%v err=%v", ok, err)
	}
	if !reflect.DeepEqual(found, written) {
		t.Fatalf("Find=%#v want=%#v", found, written)
	}
}
