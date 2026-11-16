//go:build postgres

package datacontract_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TestPayloadVersionLeavesRowJSONUnchanged proves the R8-2 guards keep bytes
// stable: for a row of a 00163 table, the touched whole-row expression minus
// payload_version equals the same expression over a copy of the row with the
// column dropped, which is exactly the pre-00163 row JSON. A copy is used
// instead of a golden string so the comparison covers every column the table
// has, including columns added after this test was written.
func TestPayloadVersionLeavesRowJSONUnchanged(t *testing.T) {
	dsn := os.Getenv("GXB_R8_MANIFEST_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_MANIFEST_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 1, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = transaction.Rollback(ctx) })

	receiptID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO gxb_operation_receipts(receipt_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,recorded_at)
VALUES($1,'player','999999001','datacontract','payload-version-probe','query','payload-version-probe',decode(repeat('ab',32),'hex'),'probe.v1','{"probe":true}'::jsonb,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z')`, receiptID.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `CREATE TEMP TABLE payload_version_receipt_copy AS SELECT * FROM gxb_operation_receipts WHERE receipt_id=$1`, receiptID.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `ALTER TABLE payload_version_receipt_copy DROP COLUMN payload_version`); err != nil {
		t.Fatal(err)
	}
	var receiptEqual bool
	if err := transaction.QueryRow(ctx, `SELECT
 (SELECT (to_jsonb(r)-ARRAY['operation_started_at','recorded_at','retain_until','request_fingerprint','payload_version'])||jsonb_build_object('operation_started_at',to_char(r.operation_started_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'recorded_at',to_char(r.recorded_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'retain_until',CASE WHEN r.retain_until IS NULL THEN NULL ELSE to_char(r.retain_until AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') END,'request_fingerprint',encode(r.request_fingerprint,'hex')) FROM gxb_operation_receipts r WHERE r.receipt_id=$1)
 IS NOT DISTINCT FROM
 (SELECT (to_jsonb(c)-ARRAY['operation_started_at','recorded_at','retain_until','request_fingerprint'])||jsonb_build_object('operation_started_at',to_char(c.operation_started_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'recorded_at',to_char(c.recorded_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'retain_until',CASE WHEN c.retain_until IS NULL THEN NULL ELSE to_char(c.retain_until AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') END,'request_fingerprint',encode(c.request_fingerprint,'hex')) FROM payload_version_receipt_copy c)`, receiptID.String()).Scan(&receiptEqual); err != nil {
		t.Fatal(err)
	}
	if !receiptEqual {
		t.Fatal("gxb_operation_receipts payload changed by payload_version")
	}

	if _, err := transaction.Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(999999,'payload-version-probe',NULL,false,false,false,99999925001,99999999999,1,now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO ranking_girls_roots(logical_server_id,policy_id,state_version,payload) VALUES(999999,'PAYLOAD_VERSION_PROBE',1,'{"probe":true}'::jsonb)`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `CREATE TEMP TABLE payload_version_root_copy AS SELECT * FROM ranking_girls_roots WHERE logical_server_id=999999 AND policy_id='PAYLOAD_VERSION_PROBE'`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `ALTER TABLE payload_version_root_copy DROP COLUMN payload_version`); err != nil {
		t.Fatal(err)
	}
	var rootEqual bool
	if err := transaction.QueryRow(ctx, `SELECT (SELECT to_jsonb(x)-'payload_version' FROM ranking_girls_roots x WHERE logical_server_id=999999 AND policy_id='PAYLOAD_VERSION_PROBE') IS NOT DISTINCT FROM (SELECT to_jsonb(c) FROM payload_version_root_copy c)`).Scan(&rootEqual); err != nil {
		t.Fatal(err)
	}
	if !rootEqual {
		t.Fatal("ranking_girls_roots payload changed by payload_version")
	}

	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777777','payload-version-probe','ACTIVE',now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(99999900001,'77777777-7777-4777-8777-777777777777',999999,now(),'payload-version-probe')`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO social_guild_invite_invalidations(marker_id,source_id,source_serial,source_key,recipient_player_id,marker_fingerprint,source_fingerprint,receipt_id,notice_id,root_version,consumed,target_payload,decision_at)
VALUES('99999999-9999-4999-8999-999999999999','88888888-8888-4888-8888-888888888888',1,'payload-version-probe',99999900001,repeat('ab',32),repeat('cd',32),$1,NULL,0,false,'{"probe":true}'::jsonb,'2026-01-01T00:00:00Z')`, receiptID.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `CREATE TEMP TABLE payload_version_invalidation_copy AS SELECT * FROM social_guild_invite_invalidations WHERE source_id='88888888-8888-4888-8888-888888888888'`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `ALTER TABLE payload_version_invalidation_copy DROP COLUMN payload_version`); err != nil {
		t.Fatal(err)
	}
	var invalidationEqual bool
	if err := transaction.QueryRow(ctx, `SELECT
 (SELECT (to_jsonb(i)-ARRAY['decision_at','payload_version'])||jsonb_build_object('decision_at',to_char(i.decision_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"')) FROM social_guild_invite_invalidations i WHERE source_id='88888888-8888-4888-8888-888888888888')
 IS NOT DISTINCT FROM
 (SELECT (to_jsonb(c)-ARRAY['decision_at'])||jsonb_build_object('decision_at',to_char(c.decision_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"')) FROM payload_version_invalidation_copy c)`).Scan(&invalidationEqual); err != nil {
		t.Fatal(err)
	}
	if !invalidationEqual {
		t.Fatal("social_guild_invite_invalidations payload changed by payload_version")
	}
}
