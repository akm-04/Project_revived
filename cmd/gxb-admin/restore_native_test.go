//go:build postgres

package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/restorestore"
)

func closeRestoreEpochs(t *testing.T, pool *postgres.Pool) {
	t.Helper()
	adminExecute(t, pool, `UPDATE restore_epochs SET reconciled_at=now(), reconciliation_note='test cleanup' WHERE reconciled_at IS NULL`)
}

func restoreAuditRow(t *testing.T, pool *postgres.Pool, actor string) (string, string, string, string, string) {
	t.Helper()
	var action, actorKind, targetKind, targetKey, outcome string
	if err := pool.QueryRow(context.Background(), `SELECT action,actor_kind,target_kind,target_key,outcome FROM operator_audit_events WHERE actor_id=$1 ORDER BY id DESC LIMIT 1`, actor).Scan(&action, &actorKind, &targetKind, &targetKey, &outcome); err != nil {
		t.Fatalf("audit row for %s: %v", actor, err)
	}
	return action, actorKind, targetKind, targetKey, outcome
}

// An operator records the restore epoch before writes reopen; the API startup
// check stays red until the reconcile command records the payments attestation,
// and both commands leave durable audit rows.
func TestRestoreEpochCommandsGateStartupAndAudit(t *testing.T) {
	dsn := os.Getenv("GXB_L3B_ADMIN_DSN")
	if dsn == "" {
		t.Fatal("GXB_L3B_ADMIN_DSN is required")
	}
	ctx := context.Background()
	pool := adminPool(t, dsn)
	closeRestoreEpochs(t, pool)
	store := restorestore.Store{}
	backup := "l3b-backup-" + adminIdentifier(t).String()

	if err := runRestoreEpoch(ctx, []string{"begin", "-backup", backup, "-operator", "operator-restore"}, dsn); err != nil {
		t.Fatalf("restore-epoch begin: %v", err)
	}
	open, err := store.OpenEpoch(ctx, pool)
	if err != nil || open == nil {
		t.Fatalf("open epoch=%v err=%v", open, err)
	}
	if open.BackupLabel != backup || open.Operator != "operator-restore" || open.ReconciledAt != nil {
		t.Fatalf("begun epoch=%#v", open)
	}
	if err = store.CheckWritable(ctx, pool); !errors.Is(err, restorestore.ErrUnreconciledRestore) {
		t.Fatalf("startup check with open epoch=%v", err)
	}
	action, actorKind, targetKind, targetKey, outcome := restoreAuditRow(t, pool, "operator-restore")
	if action != restoreEpochBeginAction || actorKind != "AdminOperator" || targetKind != "restore_epoch" || targetKey != fmt.Sprint(open.Epoch) || outcome != "SUCCEEDED" {
		t.Fatalf("begin audit action=%s actor=%s target=%s/%s outcome=%s", action, actorKind, targetKind, targetKey, outcome)
	}

	if err = runRestoreEpoch(ctx, []string{"reconcile", "-epoch", fmt.Sprint(open.Epoch), "-operator", "operator-reconcile", "-note", "external payments reconciled"}, dsn); err != nil {
		t.Fatalf("restore-epoch reconcile: %v", err)
	}
	if err = store.CheckWritable(ctx, pool); err != nil {
		t.Fatalf("startup check after reconcile=%v", err)
	}
	closed, err := (restorestore.Store{}).OpenEpoch(ctx, pool)
	if err != nil || closed != nil {
		t.Fatalf("open epoch after reconcile=%v err=%v", closed, err)
	}
	var note string
	var reconciledAt time.Time
	if err = pool.QueryRow(ctx, `SELECT reconciled_at,reconciliation_note FROM restore_epochs WHERE epoch=$1`, open.Epoch).Scan(&reconciledAt, &note); err != nil {
		t.Fatal(err)
	}
	if reconciledAt.IsZero() || note != "external payments reconciled" {
		t.Fatalf("reconciled row at=%v note=%q", reconciledAt, note)
	}
	action, actorKind, targetKind, targetKey, outcome = restoreAuditRow(t, pool, "operator-reconcile")
	if action != restoreEpochReconcileAction || actorKind != "AdminOperator" || targetKind != "restore_epoch" || targetKey != fmt.Sprint(open.Epoch) || outcome != "SUCCEEDED" {
		t.Fatalf("reconcile audit action=%s actor=%s target=%s/%s outcome=%s", action, actorKind, targetKind, targetKey, outcome)
	}

	if err = runRestoreEpoch(ctx, []string{"reconcile", "-epoch", fmt.Sprint(open.Epoch), "-operator", "operator-reconcile", "-note", "misplaced retry"}, dsn); err == nil {
		t.Fatal("second reconcile was accepted")
	}
	action, _, _, targetKey, outcome = restoreAuditRow(t, pool, "operator-reconcile")
	if action != restoreEpochReconcileAction || targetKey != fmt.Sprint(open.Epoch) || outcome != "REFUSED" {
		t.Fatalf("refusal audit action=%s target=%s outcome=%s", action, targetKey, outcome)
	}
}
