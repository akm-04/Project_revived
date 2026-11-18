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
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TestI911CatalogPayloadVersionNative proves the 00174/00175/00176 content
// writers store foundation/payload.Current and their readers accept a stored
// payload_version 0 through the lenient decode path.
func TestI911CatalogPayloadVersionNative(t *testing.T) {
	dsn := os.Getenv("GXB_I9_10E_DSN")
	if dsn == "" {
		t.Skip("GXB_I9_10E_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "i9-11-catalog-payload-version"})
	if err != nil {
		t.Fatal(err)
	}
	defer p.Close()

	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	store := contentstore.Store{Queryer: p}
	service := registry.Service{Runner: tx.Runner{DB: p}, Repo: store, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, err = service.EnsureBuiltinInstalled(ctx, op, bundle); err != nil {
		t.Fatal(err)
	}

	for table, statement := range map[string]string{
		"content_daily_buy_input_catalogs": "SELECT payload_version FROM content_daily_buy_input_catalogs WHERE revision_id=$1",
		"content_compat_catalogs":          "SELECT payload_version FROM content_compat_catalogs WHERE revision_id=$1",
		"content_shop_catalogs":            "SELECT payload_version FROM content_shop_catalogs WHERE revision_id=$1",
	} {
		var version int16
		if err := p.QueryRow(ctx, statement, bundle.RevisionID()).Scan(&version); err != nil {
			t.Fatalf("%s: %v", table, err)
		}
		if version != payload.Current {
			t.Fatalf("%s payload_version=%d want %d", table, version, payload.Current)
		}
	}

	// A version 0 row predates the column; the readers must decode it leniently.
	for _, statement := range []string{
		`UPDATE content_daily_buy_input_catalogs SET payload_version=0 WHERE revision_id=$1`,
		`UPDATE content_compat_catalogs SET payload_version=0 WHERE revision_id=$1`,
		`UPDATE content_shop_catalogs SET payload_version=0 WHERE revision_id=$1`,
	} {
		if _, err := p.Raw().Exec(ctx, statement, bundle.RevisionID()); err != nil {
			t.Fatal(err)
		}
	}
	revision := bundle.RevisionID()
	if _, err := store.DailyBuyInputsTx(ctx, p, revision); err != nil {
		t.Fatalf("daily buy catalog version 0: %v", err)
	}
	if _, err := store.MessagePushCatalogTx(ctx, p, revision); err != nil {
		t.Fatalf("compat catalog version 0: %v", err)
	}
	if _, err := store.ShopCatalogTx(ctx, p, revision); err != nil {
		t.Fatalf("shop catalog version 0: %v", err)
	}
}
