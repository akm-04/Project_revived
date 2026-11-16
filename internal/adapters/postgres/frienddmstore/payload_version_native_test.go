//go:build postgres

package frienddmstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/frienddmstore"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripFriendDMStore(t *testing.T) {
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
VALUES(8,'payload-version-frienddm',NULL,false,false,false,825003,899999,1,now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777708','payload-version-frienddm','ACTIVE',now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(825001,'77777777-7777-4777-8777-777777777708',8,now(),'payload-version-frienddm')`); err != nil {
		t.Fatal(err)
	}

	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	canonical, err := friendmessage.Message{Kind: 0, Text: "golden"}.Canonical()
	if err != nil {
		t.Fatal(err)
	}
	written := dm.ProjectionReceipt{OperationID: operationID.String(), Recipient: identity.PlayerID(825001), ManifestDigest: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", ObservedAt: at, Messages: []dm.Projection{{PlayerID: identity.PlayerID(825002), Message: canonical, Time: at.Unix()}}}
	if err := (frienddmstore.Store{}).InsertProjectionTx(ctx, transaction, written); err != nil {
		t.Fatal(err)
	}

	var storedText string
	var version int16
	if err := transaction.QueryRow(ctx, `SELECT messages::text,payload_version FROM friend_dm_projection_receipts WHERE operation_id=$1::uuid`, operationID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	marshalled, err := json.Marshal(written.Messages)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := transaction.QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored messages=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded []dm.Projection
	if err := payload.Decode("friend_dm_projection_receipts", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !reflect.DeepEqual(decoded, written.Messages) {
		t.Fatalf("decoded=%#v want=%#v", decoded, written.Messages)
	}
	read, found, err := (frienddmstore.Store{}).FindProjection(ctx, transaction, operationID.String())
	if err != nil || !found {
		t.Fatalf("FindProjection found=%v err=%v", found, err)
	}
	if !reflect.DeepEqual(read.Messages, written.Messages) {
		t.Fatalf("FindProjection messages=%#v want=%#v", read.Messages, written.Messages)
	}
}
