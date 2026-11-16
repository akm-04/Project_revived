//go:build postgres && linux

package profilemedia_test

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	backup "gxb.local/backend/v2/internal/adapters/profilemediabackup"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func sweepMediaHistory(t *testing.T, p *pg.Pool, cutoff time.Time) int64 {
	t.Helper()
	transaction, e := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	deleted, e := (retentionstore.Store{}).DeleteExpiredMediaHistory(ctx, transaction, cutoff)
	if e != nil {
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return deleted
}

// A-050/A-051: a replaced avatar and its receipt leave together after the
// media window, and the media maintenance commands still pass afterwards.
func TestRetentionMediaHistoryMediaMaintenanceStaysGreen(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)

	// A-069: the URL window starts at replacement, so it is the replacement's
	// decision time, not the first publication's, that must precede the cutoff.
	// Both uploads use a fixed clock so the history, its receipt and the root
	// proof see one coherent time rather than a row aged behind its evidence.
	firstAt := time.Now().UTC().Truncate(time.Microsecond).Add(-21 * 24 * time.Hour)
	s.Commands.Timed.Binder.Time = fixedTime{firstAt}
	replaced := upload(t, s, a, pngBytes(t, 20), op())
	s.Commands.Timed.Binder.Time = fixedTime{firstAt.Add(24 * time.Hour)}
	newest := upload(t, s, a, pngBytes(t, 40), op())
	if replaced.History.Operation == newest.History.Operation {
		t.Fatal("the second upload did not replace the first")
	}
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

// A-069: a replaced avatar is deleted once the replacement itself is older than
// the URL window, together with its receipt.
func TestRetentionMediaHistoryDeletesAfterReplacementWindow(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	s := mediaService(p, p, blobs(t))

	replaced := upload(t, s, a, pngBytes(t, 70), op())
	replacement := upload(t, s, a, pngBytes(t, 71), op())
	if replaced.History.Operation == replacement.History.Operation {
		t.Fatal("the second upload did not replace the first")
	}
	t.Cleanup(func() {
		sqlExec(t, p, `UPDATE player_public_profile_media_history SET decision_at=$2 WHERE operation_id=$1`, replacement.History.Operation.String(), replacement.History.DecisionAt)
	})
	sqlExec(t, p, `UPDATE player_public_profile_media_history SET decision_at=clock_timestamp()-interval '30 days' WHERE operation_id=$1`, replaced.History.Operation.String())
	sqlExec(t, p, `UPDATE player_public_profile_media_history SET decision_at=clock_timestamp()-interval '20 days' WHERE operation_id=$1`, replacement.History.Operation.String())

	if deleted := sweepMediaHistory(t, p, time.Now().Add(-15*24*time.Hour)); deleted != 1 {
		t.Fatalf("media history rule deleted=%d want 1", deleted)
	}
	var historyRows, receiptRows int
	if e := p.Raw().QueryRow(ctx, `SELECT count(*) FROM player_public_profile_media_history WHERE operation_id=$1`, replaced.History.Operation.String()).Scan(&historyRows); e != nil {
		t.Fatal(e)
	}
	if e := p.Raw().QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE operation_id=$1`, replaced.History.Operation.String()).Scan(&receiptRows); e != nil {
		t.Fatal(e)
	}
	if historyRows != 0 || receiptRows != 0 {
		t.Fatalf("replaced history=%d receipt=%d, want both removed", historyRows, receiptRows)
	}
}

// A-069: a same-asset republish adds a history row whose reference names the
// origin, and that reference guard keeps the origin after its own window ends.
func TestRetentionMediaHistoryKeepsSameAssetOrigin(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	s := mediaService(p, p, blobs(t))

	origin := upload(t, s, a, pngBytes(t, 72), op())
	republish := upload(t, s, a, pngBytes(t, 72), op())
	if republish.History.Operation == origin.History.Operation {
		t.Fatal("the same-asset republish did not add a history row")
	}
	if republish.History.Reference.Operation != origin.History.Operation {
		t.Fatalf("republish origin=%s want %s", republish.History.Reference.Operation, origin.History.Operation)
	}
	upload(t, s, a, pngBytes(t, 73), op())
	t.Cleanup(func() {
		sqlExec(t, p, `UPDATE player_public_profile_media_history SET decision_at=$2 WHERE operation_id=$1`, origin.History.Operation.String(), origin.History.DecisionAt)
		sqlExec(t, p, `UPDATE player_public_profile_media_history SET decision_at=$2 WHERE operation_id=$1`, republish.History.Operation.String(), republish.History.DecisionAt)
	})
	sqlExec(t, p, `UPDATE player_public_profile_media_history SET decision_at=clock_timestamp()-interval '30 days' WHERE operation_id=$1`, origin.History.Operation.String())
	sqlExec(t, p, `UPDATE player_public_profile_media_history SET decision_at=clock_timestamp()-interval '20 days' WHERE operation_id=$1`, republish.History.Operation.String())

	if deleted := sweepMediaHistory(t, p, time.Now().Add(-15*24*time.Hour)); deleted != 0 {
		t.Fatalf("media history rule deleted=%d, want the origin kept", deleted)
	}
	if _, found, e := s.Media.ReadMediaHistoryTx(ctx, p, origin.History.Operation); e != nil || !found {
		t.Fatalf("the origin of a same-asset republish lost its history: found=%v err=%v", found, e)
	}
}
