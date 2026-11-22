//go:build postgres

package guildbroadcaststore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildbroadcaststore"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripGuildBroadcastStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH16_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH16_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	exec := func(statement string, arguments ...any) {
		t.Helper()
		if _, err := pool.Raw().Exec(ctx, statement, arguments...); err != nil {
			t.Fatalf("seed %q: %v", statement, err)
		}
	}
	exec(`INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(1,'payload-version-guildbroadcast',NULL,false,false,false,125002,199999,1,now()) ON CONFLICT DO NOTHING`)
	for index, playerID := range []int64{100001, 100002} {
		accountID := "77777777-7777-4777-8777-77777777100" + string(rune('1'+index))
		exec(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',now()) ON CONFLICT DO NOTHING`, accountID, "payload-version-guildbroadcast-"+accountID)
		exec(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,now(),'payload-version-guildbroadcast') ON CONFLICT DO NOTHING`, playerID, accountID)
	}
	revision := strings.Repeat("a", 64)
	coreRevision := strings.Repeat("b", 64)
	exec(`INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
VALUES($1,decode($1,'hex'),1,'probe','probe',jsonb_build_object('revision_id',$1,'schema_version',1,'compiler_version','probe','parser_version','probe')) ON CONFLICT DO NOTHING`, revision)

	at := time.Date(2026, 11, 16, 0, 0, 0, 123456000, time.UTC)
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	receiptID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		for _, statement := range []struct {
			query     string
			arguments []any
		}{
			{`DELETE FROM guild_broadcast_recipients WHERE source_id=$1::uuid`, []any{operationID.String()}},
			{`DELETE FROM guild_broadcast_sources WHERE source_id=$1::uuid`, []any{operationID.String()}},
			{`DELETE FROM gxb_operation_receipts WHERE receipt_id=$1::uuid`, []any{receiptID.String()}},
			{`DELETE FROM players WHERE player_id IN (100001,100002)`, nil},
			{`DELETE FROM accounts WHERE account_id IN ('77777777-7777-4777-8777-777777771001','77777777-7777-4777-8777-777777771002')`, nil},
			{`DELETE FROM gxb_content_revisions WHERE revision_id=$1`, []any{revision}},
		} {
			if _, err := pool.Raw().Exec(context.Background(), statement.query, statement.arguments...); err != nil {
				t.Errorf("cleanup %q: %v", statement.query, err)
			}
		}
	})
	exec(`INSERT INTO gxb_operation_receipts(receipt_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,recorded_at)
VALUES($1,'player','100001','guild-broadcast','submit','I7A8A_GUILD_SOURCE','payload-version-guildbroadcast',decode(repeat('ab',32),'hex'),'gxb.guild-broadcast.submit.v1','{}'::jsonb,$2,$2)`, receiptID.String(), at)
	references, err := policy.NewSet(
		policy.Ref{Name: "content", Version: revision},
		policy.Ref{Name: "guild-core", Version: coreRevision},
		policy.Ref{Name: "guild-broadcast", Version: gb.PolicyID},
	)
	if err != nil {
		t.Fatal(err)
	}
	written := gb.Source{
		Operation:             operation.Context{ID: operationID, StartedAt: at, Policies: references},
		GuildID:               1000001,
		Server:                1,
		LeaderID:              100001,
		NameSnapshotChangedAt: at,
		DecisionAt:            at,
		ContentRevision:       revision,
		GuildCoreRevision:     coreRevision,
		PolicyID:              gb.PolicyID,
		Request:               gb.Request{Title: "title", Content: "body"},
		Recipients:            []gb.Member{{PlayerID: 100001, JoinEventID: 1, JoinedAt: at}, {PlayerID: 100002, JoinEventID: 2, JoinedAt: at}},
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if err := (guildbroadcaststore.Store{}).InsertSourceTx(ctx, transaction, written, receiptID); err != nil {
		t.Fatal(err)
	}
	for _, member := range written.Recipients {
		binding := gb.Binding{SourceID: operationID, RecipientID: member.PlayerID, State: gb.Pending, LastEnqueueAt: at, NextWakeupAt: at.Add(time.Minute)}
		if err := (guildbroadcaststore.Store{}).InsertBindingTx(ctx, transaction, binding, member); err != nil {
			t.Fatal(err)
		}
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT policy_refs::text,payload_version FROM guild_broadcast_sources WHERE source_id=$1::uuid`, operationID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	marshalled, err := json.Marshal(written.Operation.Policies)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored policy_refs=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded policy.Set
	if err := payload.Decode("guild_broadcast_sources", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !decoded.Equal(written.Operation.Policies) {
		t.Fatalf("decoded=%v want=%v", decoded.Refs(), written.Operation.Policies.Refs())
	}
	read, found, err := (guildbroadcaststore.Store{}).ReadSourceTx(ctx, pool, operationID)
	if err != nil || !found {
		t.Fatalf("ReadSourceTx found=%v err=%v", found, err)
	}
	if !reflect.DeepEqual(read.Recipients, written.Recipients) || !read.Operation.Policies.Equal(written.Operation.Policies) {
		t.Fatalf("read=%#v want=%#v", read, written)
	}
}
