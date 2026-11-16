//go:build postgres && linux

package profilemedia_test

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	backup "gxb.local/backend/v2/internal/adapters/profilemediabackup"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// A-050/A-051: a replaced avatar and its receipt leave together after the
// media window, and the media maintenance commands still pass afterwards.
func TestRetentionMediaHistoryMediaMaintenanceStaysGreen(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)

	replaced := upload(t, s, a, pngBytes(t, 20), op())
	newest := upload(t, s, a, pngBytes(t, 40), op())
	if replaced.History.Operation == newest.History.Operation {
		t.Fatal("the second upload did not replace the first")
	}
	sqlExec(t, p, `UPDATE player_public_profile_media_history SET decision_at=clock_timestamp()-interval '20 days' WHERE operation_id=$1`, replaced.History.Operation.String())
	sqlExec(t, p, `UPDATE gxb_operation_receipts SET recorded_at=clock_timestamp()-interval '20 days' WHERE operation_id=$1`, replaced.History.Operation.String())
	cutoff := time.Now().Add(-15 * 24 * time.Hour)

	transaction, e := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	deleted, e := (retentionstore.Store{}).DeleteReplayOnlyReceipts(ctx, transaction, cutoff)
	if e != nil {
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if deleted != 0 {
		t.Fatalf("receipt rule deleted %d receipts still held by media history", deleted)
	}

	transaction, e = p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	deleted, e = (retentionstore.Store{}).DeleteExpiredMediaHistory(ctx, transaction, cutoff)
	if e != nil {
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if deleted != 1 {
		t.Fatalf("media history rule deleted=%d want 1", deleted)
	}

	var historyRows, receiptRows int
	if e = p.Raw().QueryRow(ctx, `SELECT count(*) FROM player_public_profile_media_history WHERE operation_id=$1`, replaced.History.Operation.String()).Scan(&historyRows); e != nil {
		t.Fatal(e)
	}
	if e = p.Raw().QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE operation_id=$1`, replaced.History.Operation.String()).Scan(&receiptRows); e != nil {
		t.Fatal(e)
	}
	if historyRows != 0 || receiptRows != 0 {
		t.Fatalf("replaced history=%d receipt=%d, want both removed", historyRows, receiptRows)
	}
	var currentOperation string
	if e = p.Raw().QueryRow(ctx, `SELECT operation_id::text FROM player_public_profile_media_current WHERE player_id=$1`, a.PlayerID).Scan(&currentOperation); e != nil {
		t.Fatal(e)
	}
	if currentOperation != newest.History.Operation.String() {
		t.Fatalf("current media=%s want %s", currentOperation, newest.History.Operation)
	}

	maintenanceService := maintenance(s)
	if e = maintenanceService.Validate(ctx); e != nil {
		t.Fatalf("media verify: %v", e)
	}
	if _, e = maintenanceService.Collect(ctx); e != nil {
		t.Fatalf("media gc: %v", e)
	}
	dsn := os.Getenv("GXB_I7B5B_DSN")
	destination := filepath.Join(t.TempDir(), "joint-media-bundle")
	dump := func(c context.Context, path string) error {
		command := exec.CommandContext(c, "pg_dump", "--format=custom", "--no-owner", "--file", path, dsn)
		command.Stdout = os.Stderr
		command.Stderr = os.Stderr
		return command.Run()
	}
	if e = backup.Backup(ctx, maintenanceService, destination, true, dump); e != nil {
		t.Fatalf("media backup: %v", e)
	}
}
