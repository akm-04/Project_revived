package i5store

import (
	"context"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
	"testing"
	"time"
)

type stackWriteTx struct {
	bootstrapOwnerTx
	args     []any
	affected int64
}

func (t *stackWriteTx) Exec(_ context.Context, q string, args ...any) (tx.CommandTag, error) {
	t.sql = append(t.sql, q)
	t.args = args
	return bootstrapTag(t.affected), nil
}
func TestR5StackZeroDeletesWithExpectedVersion(t *testing.T) {
	now := time.Unix(100, 0)
	s := economy.StackState{PlayerID: 100001, ItemID: 42, Quantity: 0, StateVersion: 8, AcquiredAt: now, UpdatedAt: now}
	f := &stackWriteTx{affected: 1}
	if err := (Store{}).SaveStackTx(context.Background(), f, s, true); err != nil {
		t.Fatal(err)
	}
	if len(f.sql) != 1 || !strings.Contains(f.sql[0], "DELETE FROM player_item_stacks") || f.args[2] != int64(7) {
		t.Fatalf("%v %v", f.sql, f.args)
	}
	f = &stackWriteTx{}
	if err := (Store{}).SaveStackTx(context.Background(), f, s, true); err == nil {
		t.Fatal("stale delete accepted")
	}
	f = &stackWriteTx{}
	if err := (Store{}).SaveStackTx(context.Background(), f, s, false); err != nil || len(f.sql) != 0 {
		t.Fatal(err, f.sql)
	}
}

func TestR5TemporalRebindUsesLegacyOnlyOptimisticCAS(t *testing.T) {
	now := time.Unix(200, 0).UTC()
	s := economy.TemporalState{
		PlayerID: 100001, ResourceKey: "spirit_energy", StoredAmount: 101,
		PolicyVersion:   "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		ContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		StateVersion:    6, UpdatedAt: now,
	}
	f := &stackWriteTx{affected: 1}
	if err := (Store{}).RebindTemporalTx(context.Background(), f, s, 5); err != nil {
		t.Fatal(err)
	}
	if len(f.sql) != 1 || !strings.Contains(f.sql[0], "content_revision IS NULL") || !strings.Contains(f.sql[0], "state_version=$9") {
		t.Fatalf("rebind SQL lost legacy-only CAS: %q", f.sql)
	}
	if len(f.args) != 9 || f.args[5] != s.ContentRevision || f.args[8] != int64(5) {
		t.Fatalf("rebind args=%#v", f.args)
	}
	f = &stackWriteTx{affected: 0}
	if err := (Store{}).RebindTemporalTx(context.Background(), f, s, 5); err == nil {
		t.Fatal("stale/nonlegacy temporal rebind was accepted")
	}
}

func TestR5StockAnchorProjectsNullAsNumericZero(t *testing.T) {
	if got := stockAnchor(nil); got != 0 {
		t.Fatalf("NULL paused anchor projected as %d", got)
	}
	now := time.Unix(321, 0).UTC()
	if got := stockAnchor(&now); got != 321 {
		t.Fatalf("running anchor projected as %d", got)
	}
}
