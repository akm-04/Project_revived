//go:build postgres

package retentionstore_test

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func openPool(t *testing.T) (*pg.Pool, context.Context) {
	t.Helper()
	dsn := os.Getenv("GXB_R8_4C_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_4C_DSN with a migrated and content-deployed disposable database is required")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	t.Cleanup(cancel)
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-4c-retention"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool, ctx
}

func newUUID(t *testing.T) string {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id.String()
}

func contentRevision(t *testing.T, ctx context.Context, pool *pg.Pool) string {
	t.Helper()
	var revision string
	if err := pool.Raw().QueryRow(ctx, `SELECT revision_id FROM gxb_content_activation WHERE slot='content'`).Scan(&revision); err != nil {
		t.Fatalf("content-deployed database required: %v", err)
	}
	return revision
}

func seedServerAndPlayer(t *testing.T, ctx context.Context, pool *pg.Pool, server, player int64) {
	t.Helper()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	_, err = pool.Raw().Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES($1,'R8-4c retention native',clock_timestamp(),true,true,true,$2,$3,1,clock_timestamp())`, server, server*100000+25001, (server+1)*100000-1)
	if err != nil {
		t.Fatal(err)
	}
	_, err = pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), "r8-4c-native-"+account.String())
	if err != nil {
		t.Fatal(err)
	}
	_, err = pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'r8-4c-native')`, player, account.String(), server)
	if err != nil {
		t.Fatal(err)
	}
}

func putProbeReceipt(t *testing.T, ctx context.Context, pool *pg.Pool, semanticKey string) receipt.Receipt {
	t.Helper()
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	if semanticKey == "" {
		semanticKey = op.ID.String()
	}
	identity := receipt.Identity{OwnerKind: "player", OwnerKey: "r8-4c-probe", Domain: "r8-4c-probe", Operation: "probe", SemanticKey: semanticKey}
	fingerprint, err := receipt.FingerprintRequest(map[string]any{"probe": semanticKey})
	if err != nil {
		t.Fatal(err)
	}
	created, err := receipt.New(op, identity, "R8_4C_PROBE", "gxb.r8-4c.probe.v1", []byte(`{"probe":true}`), fingerprint)
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err = (kernelstore.Store{}).PutTx(ctx, transaction, created); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return created
}

func ageReceipt(t *testing.T, ctx context.Context, pool *pg.Pool, id ids.UUID, recordedAt time.Time) {
	t.Helper()
	if _, err := pool.Raw().Exec(ctx, `UPDATE gxb_operation_receipts SET recorded_at=$2 WHERE receipt_id=$1`, id.String(), recordedAt.UTC()); err != nil {
		t.Fatal(err)
	}
}

func receiptExists(t *testing.T, ctx context.Context, pool *pg.Pool, id ids.UUID) bool {
	t.Helper()
	var count int
	if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE receipt_id=$1`, id.String()).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count == 1
}

func TestRetentionReceiptsRule(t *testing.T) {
	pool, ctx := openPool(t)
	revision := contentRevision(t, ctx, pool)
	seedServerAndPlayer(t, ctx, pool, 884001, 88400100001)
	old := time.Now().Add(-2 * time.Hour)

	unreferenced := putProbeReceipt(t, ctx, pool, "")
	ageReceipt(t, ctx, pool, unreferenced.ID, old)

	operationHeld := putProbeReceipt(t, ctx, pool, "")
	ageReceipt(t, ctx, pool, operationHeld.ID, old)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ranking_girls_roots(logical_server_id,policy_id,state_version,payload)VALUES(884001,'r8-4c-native',1,'{}'::jsonb)`); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ranking_girls_snapshots(logical_server_id,policy_id,generation,operation_id,content_revision,observed_at,digest,payload)
VALUES(884001,'r8-4c-native',1,$1,$2,clock_timestamp(),repeat('a',64),'{}'::jsonb)`, operationHeld.OperationID.String(), revision); err != nil {
		t.Fatal(err)
	}

	receiptHeld := putProbeReceipt(t, ctx, pool, "")
	ageReceipt(t, ctx, pool, receiptHeld.ID, old)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO social_gift_claim_operations(operation_id,recipient_player_id,request_fingerprint,operation_started_at,decision_at,created_at,claim_day,content_revision,grant_receipt_id,semantic_result)
VALUES($1,88400100001,repeat('c',64),clock_timestamp(),clock_timestamp(),clock_timestamp(),'2026-11-16',$2,$3,'{}'::jsonb)`, newUUID(t), revision, receiptHeld.ID.String()); err != nil {
		t.Fatal(err)
	}

	evidence := putProbeReceipt(t, ctx, pool, "evidence-"+unreferenced.ID.String())
	ageReceipt(t, ctx, pool, evidence.ID, old)

	fresh := putProbeReceipt(t, ctx, pool, "")

	legacy := putProbeReceipt(t, ctx, pool, "")
	ageReceipt(t, ctx, pool, legacy.ID, old)
	if _, err := pool.Raw().Exec(ctx, `UPDATE gxb_operation_receipts SET operation_id=NULL WHERE receipt_id=$1`, legacy.ID.String()); err != nil {
		t.Fatal(err)
	}

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	deleted, err := (retentionstore.Store{}).DeleteReplayOnlyReceipts(ctx, transaction, time.Now().Add(-time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if deleted != 1 {
		t.Fatalf("deleted=%d want 1", deleted)
	}
	if receiptExists(t, ctx, pool, unreferenced.ID) {
		t.Fatal("unreferenced replay-only receipt survived")
	}
	for name, id := range map[string]ids.UUID{"operation-held": operationHeld.ID, "receipt-held": receiptHeld.ID, "evidence": evidence.ID, "fresh": fresh.ID, "legacy-null": legacy.ID} {
		if !receiptExists(t, ctx, pool, id) {
			t.Fatalf("%s receipt was purged", name)
		}
	}
}

func TestRetentionReceiptsRuleBoundsOneStatement(t *testing.T) {
	pool, ctx := openPool(t)
	old := time.Now().Add(-2 * time.Hour)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO gxb_operation_receipts(receipt_id,operation_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,recorded_at,operation_policy_refs)
SELECT gen_random_uuid(),o.operation_id,'player','r8-4c-batch','r8-4c-batch','probe','R8_4C_BATCH',o.operation_id::text,decode(repeat('00',32),'hex'),'gxb.r8-4c.probe.v1','{}'::jsonb,$1,$1,'[]'::jsonb
FROM (SELECT gen_random_uuid() AS operation_id FROM generate_series(1,1001)) o`, old.UTC()); err != nil {
		t.Fatal(err)
	}

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	deleted, err := (retentionstore.Store{}).DeleteReplayOnlyReceipts(ctx, transaction, time.Now().Add(-time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if deleted != retentionstore.BatchSize {
		t.Fatalf("first statement deleted=%d want %d", deleted, retentionstore.BatchSize)
	}
	transaction, err = pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	deleted, err = (retentionstore.Store{}).DeleteReplayOnlyReceipts(ctx, transaction, time.Now().Add(-time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if deleted != 1 {
		t.Fatalf("second statement deleted=%d want 1", deleted)
	}
}

func TestRetentionSnapshotsRule(t *testing.T) {
	pool, ctx := openPool(t)
	revision := contentRevision(t, ctx, pool)
	old := time.Now().Add(-2 * time.Hour)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(884003,'R8-4c ranking snapshot native',clock_timestamp(),true,true,true,88400325001,88400399999,1,clock_timestamp())`); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ranking_girls_roots(logical_server_id,policy_id,state_version,payload)VALUES(884003,'r8-4c-native',1,'{}'::jsonb)`); err != nil {
		t.Fatal(err)
	}
	insertSnapshot := func(generation int64, observedAt time.Time) {
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO ranking_girls_snapshots(logical_server_id,policy_id,generation,operation_id,content_revision,observed_at,digest,payload)
VALUES(884003,'r8-4c-native',$1,$2,$3,$4,repeat('a',64),'{}'::jsonb)`, generation, newUUID(t), revision, observedAt.UTC()); err != nil {
			t.Fatal(err)
		}
	}
	insertSnapshot(1, old)
	insertSnapshot(2, old)
	insertSnapshot(3, time.Now())
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ranking_girls_periods(logical_server_id,policy_id,week_start,snapshot_generation)VALUES(884003,'r8-4c-native','2026-11-09T00:00:00Z',1)`); err != nil {
		t.Fatal(err)
	}
	insertHero := func(generation int64, observedAt time.Time) {
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO hero_recommend_snapshots(logical_server_id,generation,content_revision,observed_at,digest,payload)
VALUES(884003,$1,$2,$3,repeat('d',64),'{}'::jsonb)`, generation, revision, observedAt.UTC()); err != nil {
			t.Fatal(err)
		}
	}
	insertHero(1, old)
	insertHero(2, old)
	insertHero(3, time.Now())

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	deleted, err := (retentionstore.Store{}).DeleteStaleRankingSnapshots(ctx, transaction, time.Now().Add(-time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if deleted != 1 {
		t.Fatalf("ranking snapshots deleted=%d want 1", deleted)
	}
	transaction, err = pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	deleted, err = (retentionstore.Store{}).DeleteStaleHeroRecommendSnapshots(ctx, transaction, time.Now().Add(-time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if deleted != 2 {
		t.Fatalf("hero snapshots deleted=%d want 2", deleted)
	}
	var rankingGenerations, heroGenerations []int64
	rows, err := pool.Raw().Query(ctx, `SELECT generation FROM ranking_girls_snapshots WHERE logical_server_id=884003 AND policy_id='r8-4c-native' ORDER BY generation`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var generation int64
		if err = rows.Scan(&generation); err != nil {
			t.Fatal(err)
		}
		rankingGenerations = append(rankingGenerations, generation)
	}
	rows.Close()
	if len(rankingGenerations) != 2 || rankingGenerations[0] != 1 || rankingGenerations[1] != 3 {
		t.Fatalf("kept ranking generations=%v want [1 3]", rankingGenerations)
	}
	rows, err = pool.Raw().Query(ctx, `SELECT generation FROM hero_recommend_snapshots WHERE logical_server_id=884003 ORDER BY generation`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var generation int64
		if err = rows.Scan(&generation); err != nil {
			t.Fatal(err)
		}
		heroGenerations = append(heroGenerations, generation)
	}
	rows.Close()
	if len(heroGenerations) != 1 || heroGenerations[0] != 3 {
		t.Fatalf("kept hero generations=%v want [3]", heroGenerations)
	}
}

func putMediaReceipt(t *testing.T, ctx context.Context, pool *pg.Pool, player int64, op operation.Context) receipt.Receipt {
	t.Helper()
	identity := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(player, 10), Domain: "public-profile", Operation: "custom-avatar", SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(map[string]any{"operation": op.ID.String()})
	if err != nil {
		t.Fatal(err)
	}
	created, err := receipt.New(op, identity, "I7B5B_MEDIA_ASSIGNMENT", "gxb.public-profile.media.v1", []byte(`{}`), fingerprint)
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err = (kernelstore.Store{}).PutTx(ctx, transaction, created); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return created
}

func insertMediaHistory(t *testing.T, ctx context.Context, pool *pg.Pool, player, server int64, op, referenceOperation ids.UUID, decisionAt time.Time, current bool) {
	t.Helper()
	reference := fmt.Sprintf(`{"operation":"%s"}`, referenceOperation.String())
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_public_profile_media_history(operation_id,player_id,logical_server_id,reference,root_version,decision_at)
VALUES($1,$2,$3,$4::jsonb,1,$5)`, op.String(), player, server, reference, decisionAt.UTC()); err != nil {
		t.Fatal(err)
	}
	if current {
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_public_profile_media_current(player_id,operation_id)VALUES($1,$2) ON CONFLICT(player_id) DO UPDATE SET operation_id=EXCLUDED.operation_id`, player, op.String()); err != nil {
			t.Fatal(err)
		}
	}
}

func TestRetentionMediaHistoryRule(t *testing.T) {
	pool, ctx := openPool(t)
	const player, server = int64(88400700001), int64(884007)
	seedServerAndPlayer(t, ctx, pool, server, player)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_public_profile_roots(player_id,state_version,policy_version,created_at,updated_at)
VALUES($1,1,'I7B_PUBLIC_V1',clock_timestamp(),clock_timestamp())`, player); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cleanup := context.Background()
		for _, statement := range []string{
			`DELETE FROM player_public_profile_media_current WHERE player_id=$1`,
			`DELETE FROM player_public_profile_media_history WHERE player_id=$1`,
			`DELETE FROM player_public_profile_roots WHERE player_id=$1`,
		} {
			_, _ = pool.Raw().Exec(cleanup, statement, player)
		}
		_, _ = pool.Raw().Exec(cleanup, `DELETE FROM gxb_operation_receipts WHERE owner_kind='player' AND domain='public-profile' AND owner_key=$1`, strconv.FormatInt(player, 10))
	})
	old := time.Now().Add(-2 * time.Hour)
	currentOperation := newUUID(t)
	orphanOperation := newUUID(t)
	originOperation := newUUID(t)
	descendantOperation := newUUID(t)
	freshOperation := newUUID(t)

	for _, operationID := range []string{currentOperation, orphanOperation, originOperation, descendantOperation, freshOperation} {
		op := operation.Context{ID: mustUUID(t, operationID), StartedAt: old.UTC(), Policies: policy.Set{}}
		created := putMediaReceipt(t, ctx, pool, player, op)
		if created.OperationID.String() != operationID {
			t.Fatalf("receipt operation id %s want %s", created.OperationID, operationID)
		}
		if operationID == orphanOperation || operationID == originOperation {
			ageReceipt(t, ctx, pool, created.ID, old)
		}
	}
	insertMediaHistory(t, ctx, pool, player, server, mustUUID(t, currentOperation), mustUUID(t, currentOperation), old, true)
	// Older than the current row so it is replaced whatever the random operation ids compare as.
	insertMediaHistory(t, ctx, pool, player, server, mustUUID(t, orphanOperation), mustUUID(t, orphanOperation), old.Add(-time.Minute), false)
	insertMediaHistory(t, ctx, pool, player, server, mustUUID(t, originOperation), mustUUID(t, originOperation), old, false)
	insertMediaHistory(t, ctx, pool, player, server, mustUUID(t, descendantOperation), mustUUID(t, originOperation), time.Now(), false)
	insertMediaHistory(t, ctx, pool, player, server, mustUUID(t, freshOperation), mustUUID(t, freshOperation), time.Now(), false)

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	deleted, err := (retentionstore.Store{}).DeleteExpiredMediaHistory(ctx, transaction, time.Now().Add(-time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if deleted != 1 {
		t.Fatalf("deleted=%d want 1", deleted)
	}
	for name, operation := range map[string]string{"current": currentOperation, "origin": originOperation, "descendant": descendantOperation, "fresh": freshOperation} {
		var count int
		if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM player_public_profile_media_history WHERE operation_id=$1`, operation).Scan(&count); err != nil {
			t.Fatal(err)
		}
		if count != 1 {
			t.Fatalf("%s history row was purged", name)
		}
	}
	var orphanRows, orphanReceipts int
	if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM player_public_profile_media_history WHERE operation_id=$1`, orphanOperation).Scan(&orphanRows); err != nil {
		t.Fatal(err)
	}
	if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE semantic_key=$1`, orphanOperation).Scan(&orphanReceipts); err != nil {
		t.Fatal(err)
	}
	if orphanRows != 0 || orphanReceipts != 0 {
		t.Fatalf("orphan history=%d receipt=%d, want both removed", orphanRows, orphanReceipts)
	}
}

func mustUUID(t *testing.T, value string) ids.UUID {
	t.Helper()
	parsed, err := ids.ParseUUID(value)
	if err != nil {
		t.Fatal(err)
	}
	return parsed
}

func TestRetentionNeverPurgedTables(t *testing.T) {
	pool, ctx := openPool(t)
	revision := contentRevision(t, ctx, pool)
	seedServerAndPlayer(t, ctx, pool, 884005, 88400500001)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO achievement_roots(player_id,content_revision,policy_id,progress,complete_times,state_version,created_at,updated_at)
VALUES(88400500001,$1,'C4B_MARRIED_POPULATION_TIER_FACTS_V1',0,'[0,0,0]'::jsonb,1,clock_timestamp(),clock_timestamp())`, revision); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO achievement_events(player_id,event_key,fingerprint,source_operation,partner_id,old_version,new_version,population,content_revision,decision_at)
VALUES(88400500001,repeat('a',64),repeat('b',64),$1,1,1,2,1,$2,clock_timestamp())`, newUUID(t), revision); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO achievement_award_claims(player_id,level_id,content_revision,operation_id,total_points,claimed_at)
VALUES(88400500001,2,$1,$2,0,clock_timestamp())`, revision, newUUID(t)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO mail_records(mail_uuid,recipient_player_id,namespace,wire_id,source_kind,source_key,created_at,compatibility_policy_version)
VALUES($1,88400500001,'NORMAL',1,'R8_4C_NATIVE','probe',clock_timestamp(),'r8-4c-native')`, newUUID(t)); err != nil {
		t.Fatal(err)
	}

	before := map[string]int64{}
	for _, table := range []string{"achievement_events", "achievement_award_claims", "mail_records", "players", "logical_servers"} {
		var count int64
		if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM `+table).Scan(&count); err != nil {
			t.Fatal(err)
		}
		before[table] = count
	}

	future := time.Now().Add(100 * 365 * 24 * time.Hour)
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = (retentionstore.Store{}).DeleteReplayOnlyReceipts(ctx, transaction, future); err != nil {
		t.Fatal(err)
	}
	if _, err = (retentionstore.Store{}).DeleteStaleRankingSnapshots(ctx, transaction, future); err != nil {
		t.Fatal(err)
	}
	if _, err = (retentionstore.Store{}).DeleteStaleHeroRecommendSnapshots(ctx, transaction, future); err != nil {
		t.Fatal(err)
	}
	if _, err = (retentionstore.Store{}).DeleteExpiredMediaHistory(ctx, transaction, future); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	for _, table := range []string{"achievement_events", "achievement_award_claims", "mail_records", "players", "logical_servers"} {
		var count int64
		if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM `+table).Scan(&count); err != nil {
			t.Fatal(err)
		}
		if count != before[table] {
			t.Fatalf("%s changed from %d to %d rows", table, before[table], count)
		}
	}
}
