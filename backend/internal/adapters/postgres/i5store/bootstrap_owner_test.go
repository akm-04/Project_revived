package i5store

import (
	"context"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type bootstrapTag int64

func (t bootstrapTag) RowsAffected() int64 { return int64(t) }

type bootstrapOwnerTx struct{ sql []string }

func (t *bootstrapOwnerTx) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (t *bootstrapOwnerTx) Exec(_ context.Context, q string, _ ...any) (tx.CommandTag, error) {
	t.sql = append(t.sql, q)
	return bootstrapTag(1), nil
}
func (t *bootstrapOwnerTx) Commit(context.Context) error   { return nil }
func (t *bootstrapOwnerTx) Rollback(context.Context) error { return nil }

func TestPlayerCoreBootstrapContributorOwnsExactlyPlayerCoreTables(t *testing.T) {
	aid, _ := identity.AccountIDFrom(ids.UUID{1})
	sid, _ := identity.SessionIDFrom(ids.UUID{2})
	b := logicalserver.BootstrapContext{AccountID: aid, SessionID: sid, LogicalServerID: 1, PlayerID: 100001, Operation: operation.Context{ID: ids.UUID{3}, StartedAt: time.Unix(100, 0).UTC()}, BootstrapProfileVersion: "i4-wave-s-v1"}
	f := &bootstrapOwnerTx{}
	if err := (PlayerCoreBootstrapContributor{}).PersistCharacterBootstrap(context.Background(), f, b); err != nil {
		t.Fatal(err)
	}
	want := []string{"player_profiles", "player_progression", "player_story_cursors", "player_guide_return_state", "player_function_state_owners"}
	if len(f.sql) != len(want) {
		t.Fatalf("writes=%d want %d", len(f.sql), len(want))
	}
	for i, table := range want {
		if !strings.Contains(f.sql[i], table) {
			t.Fatalf("write %d does not own %s: %s", i, table, f.sql[i])
		}
	}
}

func TestBootstrapProjectionClaimsAreStableAndUnique(t *testing.T) {
	a := (BootstrapProjection{}).Claims()
	b := (BootstrapProjection{}).Claims()
	if len(a) == 0 || len(a) != len(b) {
		t.Fatalf("claims len %d/%d", len(a), len(b))
	}
	seen := map[string]bool{}
	for i := range a {
		if a[i] != b[i] {
			t.Fatalf("claim order unstable at %d: %q/%q", i, a[i], b[i])
		}
		if seen[a[i]] {
			t.Fatalf("duplicate claim %q", a[i])
		}
		seen[a[i]] = true
	}
	if !seen["17.lev"] || !seen["17.max_color"] || !seen["368"] {
		t.Fatalf("required claims absent: %v", a)
	}
}
