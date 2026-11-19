package librarystore

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type wakeFaultTag int64

func (t wakeFaultTag) RowsAffected() int64 { return int64(t) }

type wakeFaultTx struct{}

func (wakeFaultTx) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (wakeFaultTx) Commit(context.Context) error                    { return nil }
func (wakeFaultTx) Rollback(context.Context) error                  { return nil }

func (wakeFaultTx) Exec(_ context.Context, sql string, _ ...any) (tx.CommandTag, error) {
	if strings.Contains(sql, "pg_notify") {
		return nil, errors.New("notify failed")
	}
	return wakeFaultTag(1), nil
}

// A failed pg_notify aborts the caller's transaction, so the wakeup error must
// reach the caller and the insert must not be reported as kept.
func TestInsertHeroLogReturnsTheWakeupFailure(t *testing.T) {
	inserted, err := (Store{}).InsertHeroLogTx(context.Background(), wakeFaultTx{}, library.HeroLogFact{
		PlayerID:   identity.PlayerID(1),
		PartnerID:  2,
		LogID:      library.LogAcquired,
		OccurredAt: time.Unix(1, 0).UTC(),
	})
	if err == nil || !strings.Contains(err.Error(), "notify failed") {
		t.Fatalf("wakeup error swallowed: inserted=%v err=%v", inserted, err)
	}
	if inserted {
		t.Fatal("row reported as kept after the transaction aborted")
	}
}
