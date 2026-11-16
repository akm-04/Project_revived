//go:build postgres && linux

package profilemedia_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestAuditA069RecentlyReplacedOldAvatarKeepsItsURLWindow(t *testing.T) {
	pool := pool(t)
	installed(t, pool)
	actor := actor(t, pool)
	service := mediaService(pool, pool, blobs(t))
	first := upload(t, service, actor, pngBytes(t, 21), op())
	// The aged publication is a time-travel fixture; restore it so later tests
	// in the shared native database can still verify the joint media proof.
	t.Cleanup(func() {
		sqlExec(t, pool, `UPDATE player_public_profile_media_history SET decision_at=$2 WHERE operation_id=$1`, first.History.Operation.String(), first.History.DecisionAt)
	})
	sqlExec(t, pool, `UPDATE player_public_profile_media_history SET decision_at=clock_timestamp()-interval '20 days' WHERE operation_id=$1`, first.History.Operation.String())
	second := upload(t, service, actor, pngBytes(t, 41), op())
	if second.History.Operation == first.History.Operation {
		t.Fatal("replacement did not change the avatar")
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	_, err = (retentionstore.Store{}).DeleteExpiredMediaHistory(ctx, transaction, time.Now().Add(-15*24*time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	_, found, err := service.Media.ReadMediaHistoryTx(ctx, pool, first.History.Operation)
	if err != nil || !found {
		t.Fatalf("an avatar replaced just now lost its 15-day URL history: found=%v err=%v", found, err)
	}
}
