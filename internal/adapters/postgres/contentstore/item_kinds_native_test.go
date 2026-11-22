//go:build postgres

package contentstore_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func e2ContentPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_E2_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_E2_DSN required (ops/testing/fresh_db.sh i11ae2)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	store := contentstore.Store{Queryer: pool}
	service := registry.Service{Runner: tx.Runner{DB: pool}, Repo: store, Fresh: pool, Providers: registry.DefaultProviderSet()}
	if _, err = service.EnsureBuiltinInstalled(context.Background(), op, bundle); err != nil {
		t.Fatal(err)
	}
	return pool
}

// TestItemKindsReadActiveRevision checks the new narrow read the 1008 hook needs
// (I11A_EVENTS_V1 ruling 10, EA-8) on the installed catalogue: the four client
// kinds the 1008 text names, an unlisted kind, and an absent id.
func TestItemKindsReadActiveRevision(t *testing.T) {
	pool := e2ContentPool(t)
	ctx := context.Background()
	store := contentstore.Store{}
	revision, err := store.ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	ids := []int64{20001001, 30001001, 50001322, 50001137, 50001013, 999999999}
	kinds, err := store.ItemKindsTx(ctx, pool, revision, ids)
	if err != nil {
		t.Fatal(err)
	}
	want := map[int64]int64{20001001: 1, 30001001: 2, 50001322: 5, 50001137: 6, 50001013: 4}
	if len(kinds) != len(want) {
		t.Fatalf("item kinds = %+v, want %+v", kinds, want)
	}
	for itemID, wantKind := range want {
		if kinds[itemID] != wantKind {
			t.Fatalf("item %d kind = %d, want %d (%+v)", itemID, kinds[itemID], wantKind, kinds)
		}
	}
	if _, found := kinds[999999999]; found {
		t.Fatalf("an absent item id must stay absent: %+v", kinds)
	}
	if _, err := store.ItemKindsTx(ctx, pool, revision, nil); err == nil {
		t.Fatal("an empty item id list must be refused")
	}
	if _, err := store.ItemKindsTx(ctx, pool, "", ids); err == nil {
		t.Fatal("a missing revision must be refused")
	}
}
