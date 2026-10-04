package presencestore

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ownerFenceTag int64

func (t ownerFenceTag) RowsAffected() int64 { return int64(t) }

type ownerFenceTx struct {
	current int64
	rowErr  error
	sql     string
}

func (t *ownerFenceTx) QueryRow(_ context.Context, sql string, _ ...any) tx.Row {
	t.sql = sql
	return ownerFenceRow{value: t.current, err: t.rowErr}
}
func (t *ownerFenceTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return ownerFenceTag(1), nil
}
func (t *ownerFenceTx) Commit(context.Context) error   { return nil }
func (t *ownerFenceTx) Rollback(context.Context) error { return nil }

func TestAssertOwnerFenceTxLocksCurrentEpochAndFailsStale(t *testing.T) {
	txv := &ownerFenceTx{current: 42}
	if err := (Store{}).AssertOwnerFenceTx(context.Background(), txv, 42); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(txv.sql, "FOR SHARE") || !strings.Contains(txv.sql, "realtime_presence_owner_state") {
		t.Fatalf("writer-fence query lost handoff lock: %q", txv.sql)
	}
	if err := (Store{}).AssertOwnerFenceTx(context.Background(), txv, 41); !errors.Is(err, socialpresence.ErrStaleRealtimeOwner) {
		t.Fatalf("stale err=%v", err)
	}
}

func TestI7A3BaseMigrationDeclaresDerivedPresenceOwnership(t *testing.T) {
	raw, err := os.ReadFile("../../../../migrations/00031_i7a3_social_presence.sql")
	if err != nil {
		t.Fatal(err)
	}
	s := string(raw)
	for _, needle := range []string{
		"CREATE TABLE player_social_presence",
		"CREATE TABLE realtime_presence_leases",
		"PRIMARY KEY(gameplay_context_id,physical_role)",
		"ON DELETE CASCADE",
		"connection_generation bigint NOT NULL CHECK (connection_generation > 0)",
		"physical_role IN ('WORLD','GUILD','SERVICE')",
	} {
		if !strings.Contains(s, needle) {
			t.Fatalf("migration 00031 missing %q", needle)
		}
	}
	if strings.Contains(s, "realtime_owner_fence") || strings.Contains(s, "realtime_presence_owner_state") {
		t.Fatal("sealed 00031 must remain pre-repair bytes; owner fence belongs to 00032")
	}
}

func TestI7A3OwnerFenceRepairIsForwardOnlyMigration32(t *testing.T) {
	raw, err := os.ReadFile("../../../../migrations/00032_i7a3_presence_owner_fence_repair.sql")
	if err != nil {
		t.Fatal(err)
	}
	s := string(raw)
	for _, needle := range []string{
		"CREATE SEQUENCE realtime_presence_owner_fence_seq AS bigint",
		"CREATE TABLE realtime_presence_owner_state",
		"DELETE FROM realtime_presence_leases",
		"ADD COLUMN realtime_owner_fence bigint NOT NULL CHECK (realtime_owner_fence > 0)",
	} {
		if !strings.Contains(s, needle) {
			t.Fatalf("migration 00032 missing %q", needle)
		}
	}
	if strings.Contains(s, "DELETE FROM player_social_presence") {
		t.Fatal("repair must preserve durable last_seen roots")
	}
}

func TestLeaseUpsertContainsOwnerFenceAndGenerationFence(t *testing.T) {
	required := []string{
		"realtime_presence_leases.player_id=EXCLUDED.player_id",
		"realtime_presence_leases.realtime_owner_fence < EXCLUDED.realtime_owner_fence",
		"realtime_presence_leases.realtime_owner_fence = EXCLUDED.realtime_owner_fence",
		"realtime_presence_leases.realtime_instance_id = EXCLUDED.realtime_instance_id",
		"realtime_presence_leases.connection_generation <= EXCLUDED.connection_generation",
		"GREATEST(realtime_presence_leases.lease_expires_at,EXCLUDED.lease_expires_at)",
	}
	for _, needle := range required {
		if !strings.Contains(upsertLeaseSQL, needle) {
			t.Fatalf("upsert fence missing %q", needle)
		}
	}
	forbidden := "realtime_presence_leases.realtime_instance_id<>EXCLUDED.realtime_instance_id"
	if strings.Contains(upsertLeaseSQL, forbidden) {
		t.Fatalf("unordered instance identity still used as takeover fence: %q", forbidden)
	}
}

type ownerFenceRow struct {
	value int64
	err   error
}

func (r ownerFenceRow) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}
	*(dest[0].(*int64)) = r.value
	return nil
}

type ownerFenceQueryer struct {
	sql string
	row ownerFenceRow
}

func (q *ownerFenceQueryer) QueryRow(_ context.Context, sql string, _ ...any) tx.Row {
	q.sql = sql
	return q.row
}
func TestActivateRealtimeOwnerFence(t *testing.T) {
	q := &ownerFenceQueryer{row: ownerFenceRow{value: 42}}
	got, err := (Store{Queryer: q}).ActivateRealtimeOwnerFence(context.Background())
	if err != nil || got != 42 {
		t.Fatalf("got=%d err=%v", got, err)
	}
	if q.sql != activateRealtimeOwnerFenceSQL {
		t.Fatalf("unexpected sql %q", q.sql)
	}
	q.row = ownerFenceRow{value: 0}
	if _, err := (Store{Queryer: q}).ActivateRealtimeOwnerFence(context.Background()); err == nil {
		t.Fatal("nonpositive fence accepted")
	}
	q.row = ownerFenceRow{err: errors.New("db down")}
	if _, err := (Store{Queryer: q}).ActivateRealtimeOwnerFence(context.Background()); err == nil {
		t.Fatal("query error hidden")
	}
	if _, err := (Store{}).ActivateRealtimeOwnerFence(context.Background()); err == nil {
		t.Fatal("nil queryer accepted")
	}
}
