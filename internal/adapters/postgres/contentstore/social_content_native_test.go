//go:build postgres

package contentstore_test

import (
	"context"
	"errors"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestSocialContentNativeInstallReadVerifyCoexistence(t *testing.T) {
	dsn := os.Getenv("GXB_I9_10E_DSN")
	if dsn == "" {
		t.Skip("GXB_I9_10E_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "i9-10e-social-content"})
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
	verification, err := store.VerifyRevision(ctx, p, bundle)
	if err != nil || !verification.Matches(bundle) || verification.SocialInputCount != 1 {
		t.Fatalf("exact Social content verification failed: %+v %v", verification, err)
	}
	var rows int64
	if err = p.QueryRow(ctx, `SELECT count(*) FROM content_social_input_catalogs WHERE revision_id=$1`, bundle.RevisionID()).Scan(&rows); err != nil || rows != 1 {
		t.Fatalf("Social content rows=%d err=%v", rows, err)
	}

	catalog, err := store.SocialInputCatalogTx(ctx, p, bundle.RevisionID())
	if err != nil {
		t.Fatal(err)
	}
	productIDs := make([]int64, 0, len(catalog.ExchangeProducts))
	for _, product := range catalog.ExchangeProducts {
		productIDs = append(productIDs, product.ID)
	}
	if !reflect.DeepEqual(productIDs, []int64{1, 2, 3}) || len(catalog.Dropboxes) != 3 || len(catalog.RecallMilestones) != 25 || len(catalog.InvitationMissions) != 250 {
		t.Fatalf("installed Social source drift: %+v", catalog)
	}
	exchange, err := store.SocialExchangeCatalogTx(ctx, p, bundle.RevisionID())
	if err != nil {
		t.Fatal(err)
	}
	for _, product := range exchange.Products {
		plan, err := socialexchange.BuildPlan(exchange, product.ID, 1, op)
		if err != nil || plan.PriceCurrency != socialexchange.PriceCurrency || plan.UnitPrice != product.SellPrice || len(plan.Items) == 0 {
			t.Fatalf("product %d plan through installed content: %+v %v", product.ID, plan, err)
		}
	}

	old := strings.Repeat("c", 64)
	if _, err = p.Raw().Exec(ctx, oldRevisionSQL, old, bundle.RevisionID()); err != nil {
		t.Fatal(err)
	}
	for _, statement := range []string{copyCourseSQL, copyBookSQL, copyGiftSQL, copyManaSQL} {
		if _, err = p.Raw().Exec(ctx, statement, old, bundle.RevisionID()); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = store.SocialInputCatalogTx(ctx, p, old); !errors.Is(err, contentstore.ErrSocialContentUnavailable) {
		t.Fatalf("old revision served new Social content: %v", err)
	}
	if _, err = store.CourseCatalogTx(ctx, p, old); err != nil {
		t.Fatalf("old revision lost Course content: %v", err)
	}
	if _, err = store.BookCatalogTx(ctx, p, old); err != nil {
		t.Fatalf("old revision lost Book content: %v", err)
	}
	if _, err = store.ReadGiftContent(ctx, p, old); err != nil {
		t.Fatalf("old revision lost SocialGift content: %v", err)
	}
	if _, err = store.ResolveResourceTx(ctx, p, old, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 1}); err != nil {
		t.Fatalf("old revision lost I5 resource read: %v", err)
	}
	if _, err = store.SocialInputCatalogTx(ctx, p, bundle.RevisionID()); err != nil {
		t.Fatalf("coexisting new revision unreadable: %v", err)
	}
	t.Log("REAL_PG exact Social install/verify/read plus capability-less revision coexistence")
}

const oldRevisionSQL = `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
SELECT $1,decode($1,'hex'),schema_version,compiler_version,parser_version,
  jsonb_set(
    jsonb_set(manifest #- '{artifact_sha256s,social_input_catalog.json}','{revision_id}',to_jsonb($1::text)),
    '{enabled_capabilities}',
    COALESCE((SELECT jsonb_agg(capability) FROM jsonb_array_elements_text(manifest->'enabled_capabilities') AS capability WHERE capability <> 'SOCIAL_CONTENT_I9_10E'),'[]'::jsonb))
FROM gxb_content_revisions WHERE revision_id=$2 ON CONFLICT DO NOTHING`

const copyCourseSQL = `INSERT INTO content_course_input_catalogs(revision_id,payload) SELECT $1,payload FROM content_course_input_catalogs WHERE revision_id=$2 ON CONFLICT DO NOTHING`

const copyBookSQL = `INSERT INTO content_book_input_catalogs(revision_id,payload) SELECT $1,payload FROM content_book_input_catalogs WHERE revision_id=$2 ON CONFLICT DO NOTHING`

const copyGiftSQL = `INSERT INTO content_social_gift_catalogs(revision_id,payload) SELECT $1,payload FROM content_social_gift_catalogs WHERE revision_id=$2 ON CONFLICT DO NOTHING`

const copyManaSQL = `INSERT INTO gxb_content_resource_definitions(revision_id,definition_key,class,catalog_status,settlement_activation,resource_key,source_asset_id)
SELECT $1,definition_key,class,catalog_status,settlement_activation,resource_key,source_asset_id
FROM gxb_content_resource_definitions WHERE revision_id=$2 AND class='SCALAR_CURRENCY' AND resource_key='mana' ON CONFLICT DO NOTHING`
