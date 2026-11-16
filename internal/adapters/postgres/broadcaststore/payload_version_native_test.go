//go:build postgres

package broadcaststore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/broadcaststore"
	"gxb.local/backend/v2/internal/application/broadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripBroadcastStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH14_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH14_DSN for a migrated test database is missing")
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
VALUES(999999,'payload-version-broadcast',NULL,false,false,false,99999925002,99999999999,1,now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777777','payload-version-broadcast','ACTIVE',now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(99999925001,'77777777-7777-4777-8777-777777777777',999999,now(),'payload-version-broadcast')`); err != nil {
		t.Fatal(err)
	}

	written := broadcast.Fields{Rank: 7, TableID: 9, EnemyName: "rival"}
	message := broadcast.Message{MID: 1, MsgType: 1, Server: identity.LogicalServerID(999999), Player: identity.PlayerID(99999925001), Fields: written}
	id, err := (broadcaststore.Store{}).InsertTx(ctx, transaction, message)
	if err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := transaction.QueryRow(ctx, `SELECT fields::text,payload_version FROM broadcast_outbox WHERE broadcast_id=$1`, id).Scan(&storedText, &version); err != nil {
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
		t.Fatalf("stored fields=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded broadcast.Fields
	if err := payload.Decode("broadcast_outbox", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !reflect.DeepEqual(decoded, written) {
		t.Fatalf("decoded=%#v want=%#v", decoded, written)
	}
	taken, ok, err := (broadcaststore.Store{}).TakeTx(ctx, transaction, id)
	if err != nil {
		t.Fatal(err)
	}
	if !ok {
		t.Fatal("TakeTx did not find the written message")
	}
	if !reflect.DeepEqual(taken.Fields, written) {
		t.Fatalf("TakeTx fields=%#v want=%#v", taken.Fields, written)
	}
}
