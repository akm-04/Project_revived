//go:build postgres

package auditstore_test

import (
	"context"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/auditstore"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func auditPool(t *testing.T) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_L3B_AUDIT_DSN")
	if dsn == "" {
		t.Fatal("GXB_L3B_AUDIT_DSN is required")
	}
	pool, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func auditCorrelation(t *testing.T) string {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id.String()
}

func auditEvent(correlation string) audit.Event {
	return audit.Event{
		OccurredAt:    time.Now().UTC().Truncate(time.Microsecond),
		ActorKind:     "AdminOperator",
		ActorID:       "operator-7",
		Action:        "identity.session.revoke",
		TargetKind:    "session",
		TargetKey:     "00000000-0000-0000-0000-000000000001",
		Outcome:       "SUCCEEDED",
		ReasonCode:    "support",
		CorrelationID: correlation,
		PolicyVersion: "gxb.identity.session-revoke.v1",
	}
}

func readAuditRow(t *testing.T, pool *postgres.Pool, correlation string) (int64, audit.Event) {
	t.Helper()
	var (
		id    int64
		event audit.Event
	)
	if err := pool.QueryRow(context.Background(), `SELECT id,occurred_at,actor_kind,actor_id,action,target_kind,target_key,outcome,reason_code,correlation_id,policy_version FROM operator_audit_events WHERE correlation_id=$1`, correlation).Scan(&id, &event.OccurredAt, &event.ActorKind, &event.ActorID, &event.Action, &event.TargetKind, &event.TargetKey, &event.Outcome, &event.ReasonCode, &event.CorrelationID, &event.PolicyVersion); err != nil {
		t.Fatalf("audit row %s: %v", correlation, err)
	}
	return id, event
}

func TestAuditStoreInsertTxWritesOneRowInsideCallerTransaction(t *testing.T) {
	ctx := context.Background()
	pool := auditPool(t)
	correlation := auditCorrelation(t)
	want := auditEvent(correlation)
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if err = (auditstore.Store{}).InsertTx(ctx, transaction, want); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	_, got := readAuditRow(t, pool, correlation)
	if !got.OccurredAt.Equal(want.OccurredAt) || got.ActorKind != want.ActorKind || got.ActorID != want.ActorID || got.Action != want.Action || got.TargetKind != want.TargetKind || got.TargetKey != want.TargetKey || got.Outcome != want.Outcome || got.ReasonCode != want.ReasonCode || got.PolicyVersion != want.PolicyVersion {
		t.Fatalf("audit row=%#v want=%#v", got, want)
	}
}

func TestAuditStoreRejectsRolledBackInsertAndInvalidEvent(t *testing.T) {
	ctx := context.Background()
	pool := auditPool(t)
	correlation := auditCorrelation(t)
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if err = (auditstore.Store{}).InsertTx(ctx, transaction, auditEvent(correlation)); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	var count int64
	if err = pool.QueryRow(ctx, `SELECT count(*) FROM operator_audit_events WHERE correlation_id=$1`, correlation).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 0 {
		t.Fatalf("rolled-back audit rows=%d want 0", count)
	}
	transaction, err = pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err = (auditstore.Store{}).InsertTx(ctx, transaction, audit.Event{}); err == nil {
		t.Fatal("invalid audit event was inserted")
	}
}

func TestAuditEmitterInsertsInItsOwnTransaction(t *testing.T) {
	ctx := context.Background()
	pool := auditPool(t)
	correlation := auditCorrelation(t)
	auditstore.Emitter{Pool: pool}.Emit(ctx, auditEvent(correlation))
	_, got := readAuditRow(t, pool, correlation)
	if got.CorrelationID != correlation || got.ActorID != "operator-7" || got.Outcome != "SUCCEEDED" {
		t.Fatalf("emitted audit row=%#v", got)
	}
}

func TestOperatorAuditEventsRefuseUpdateAndDelete(t *testing.T) {
	ctx := context.Background()
	pool := auditPool(t)
	correlation := auditCorrelation(t)
	auditstore.Emitter{Pool: pool}.Emit(ctx, auditEvent(correlation))
	id, _ := readAuditRow(t, pool, correlation)
	if _, err := pool.Raw().Exec(ctx, `UPDATE operator_audit_events SET outcome='CHANGED' WHERE id=$1`, id); err == nil {
		t.Fatal("operator_audit_events accepted an UPDATE")
	}
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM operator_audit_events WHERE id=$1`, id); err == nil {
		t.Fatal("operator_audit_events accepted a DELETE")
	}
	_, got := readAuditRow(t, pool, correlation)
	if got.Outcome != "SUCCEEDED" {
		t.Fatalf("audit row changed to %q", got.Outcome)
	}
}
