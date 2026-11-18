package generaldmstore_test

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/generaldmstore"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type recordedStatement struct {
	sql  string
	args []any
}

type recordingTx struct{ statements []recordedStatement }

func (r *recordingTx) Exec(_ context.Context, sql string, args ...any) (tx.CommandTag, error) {
	r.statements = append(r.statements, recordedStatement{sql: sql, args: args})
	return recordingTag{}, nil
}
func (r *recordingTx) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (r *recordingTx) Commit(context.Context) error                    { return nil }
func (r *recordingTx) Rollback(context.Context) error                  { return nil }

type recordingTag struct{}

func (recordingTag) RowsAffected() int64 { return 1 }

func pendingIntent() dm.Intent {
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	return dm.Intent{ID: "5ff4a3c1-1d5e-4c8a-9a3f-2d6e4b8c1a70", Digest: strings.Repeat("a", 64), Sender: 1125001, Recipient: 1125003, Message: "hello", AcceptedAt: at, ExpiresAt: at.Add(dm.IntentLifetime), BlockVersion: 0, Bindings: []dm.Binding{{ContextID: "ctx", ContextGeneration: 1, SessionID: "sess", SessionLiveness: 1, ContextLiveness: 1, RealtimeInstanceID: "rt", ConnectionGeneration: 1, OwnerFence: 1, LogicalServerID: 11}}, Status: dm.Pending, StateVersion: 1, LastObservedAt: at}
}

// TestInsertTxAcquiresRank381OwnerKey pins the PASS647 owner381 creation fence:
// the production insert takes the canonical personal-dm.intent key before it
// writes any row, so the integration wrapper no longer supplies that witness.
func TestInsertTxAcquiresRank381OwnerKey(t *testing.T) {
	intent := pendingIntent()
	recorder := &recordingTx{}
	if err := (generaldmstore.Store{}).InsertTx(context.Background(), recorder, intent); err != nil {
		t.Fatal(err)
	}
	if len(recorder.statements) == 0 {
		t.Fatal("insert issued no statement")
	}
	first := recorder.statements[0]
	if !strings.Contains(first.sql, "pg_advisory_xact_lock") {
		t.Fatalf("first statement %q does not acquire the rank-%d owner key", first.sql, dm.LockRank)
	}
	want := fmt.Sprintf("gxb.%d.personal-dm.intent:%s", dm.LockRank, intent.ID)
	if len(first.args) != 1 || first.args[0] != want {
		t.Fatalf("owner key = %v, want %q", first.args, want)
	}
	for index, statement := range recorder.statements {
		if strings.Contains(statement.sql, "INSERT INTO personal_dm_intents") {
			if index == 0 {
				t.Fatal("owner key acquired after the intent mutation")
			}
			return
		}
	}
	t.Fatal("insert issued no personal_dm_intents row")
}
