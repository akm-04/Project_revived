package contentstore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

const (
	socialManifestQuery = "SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1"
	socialPayloadQuery  = "SELECT payload::text FROM content_social_input_catalogs WHERE revision_id=$1"
	coursePayloadQuery  = "SELECT payload::text FROM content_course_input_catalogs WHERE revision_id=$1"
	giftPayloadQuery    = "SELECT payload::text FROM content_social_gift_catalogs WHERE revision_id=$1"
)

func generatedManifest(t *testing.T) map[string]any {
	t.Helper()
	raw, err := builtin.GeneratedFile("manifest.json")
	if err != nil {
		t.Fatal(err)
	}
	var manifest map[string]any
	if err = json.Unmarshal(raw, &manifest); err != nil {
		t.Fatal(err)
	}
	return manifest
}

func generatedRaw(t *testing.T, name string) string {
	t.Helper()
	raw, err := builtin.GeneratedFile(name)
	if err != nil {
		t.Fatal(err)
	}
	return string(raw)
}

func encodeManifest(t *testing.T, manifest map[string]any) string {
	t.Helper()
	raw, err := json.Marshal(manifest)
	if err != nil {
		t.Fatal(err)
	}
	return string(raw)
}

func socialQueryer(manifest, payload string) *recording {
	q := &recording{}
	q.bySQL = map[string][]any{
		socialManifestQuery:                        {manifest},
		contentqueries.ReadContentRevisionManifest: {manifest},
		socialPayloadQuery:                         {payload},
	}
	return q
}

func currentSocialRevision(t *testing.T) (string, map[string]any) {
	t.Helper()
	manifest := generatedManifest(t)
	revision, ok := manifest["revision_id"].(string)
	if !ok || len(revision) != 64 {
		t.Fatal("generated manifest lacks a revision")
	}
	return revision, manifest
}

func withoutSocialCapability(t *testing.T, manifest map[string]any, revision string) string {
	t.Helper()
	manifest["revision_id"] = revision
	capabilities, ok := manifest["enabled_capabilities"].([]any)
	if !ok {
		t.Fatal("manifest lacks capabilities")
	}
	filtered := make([]any, 0, len(capabilities))
	for _, capability := range capabilities {
		if capability != socialContentCapability {
			filtered = append(filtered, capability)
		}
	}
	manifest["enabled_capabilities"] = filtered
	hashes, ok := manifest["artifact_sha256s"].(map[string]any)
	if !ok {
		t.Fatal("manifest lacks artifact hashes")
	}
	delete(hashes, "social_input_catalog.json")
	return encodeManifest(t, manifest)
}

func TestSocialInputCatalogTxReadsInstalledArtifact(t *testing.T) {
	ctx := context.Background()
	revision, _ := currentSocialRevision(t)
	manifest := generatedRaw(t, "manifest.json")
	payload := generatedRaw(t, "social_input_catalog.json")
	catalog, err := (Store{}).SocialInputCatalogTx(ctx, socialQueryer(manifest, payload), revision)
	if err != nil {
		t.Fatal(err)
	}
	productIDs := make([]int64, 0, len(catalog.ExchangeProducts))
	prices := make([]int64, 0, len(catalog.ExchangeProducts))
	for _, product := range catalog.ExchangeProducts {
		productIDs = append(productIDs, product.ID)
		prices = append(prices, product.SellPrice)
	}
	if !reflect.DeepEqual(productIDs, []int64{1, 2, 3}) || !reflect.DeepEqual(prices, []int64{100, 500, 700}) {
		t.Fatalf("source exchange identities/prices changed: %v %v", productIDs, prices)
	}
	if catalog.ExchangeLimit != 10 || len(catalog.Dropboxes) != 3 || len(catalog.Gifts) != 28 || len(catalog.RecallMilestones) != 25 || len(catalog.InvitationMissions) != 250 {
		t.Fatalf("source catalog drift: %+v", catalog)
	}
}

func TestSocialExchangeCatalogTxPlansAllThreeProducts(t *testing.T) {
	ctx := context.Background()
	revision, _ := currentSocialRevision(t)
	manifest := generatedRaw(t, "manifest.json")
	payload := generatedRaw(t, "social_input_catalog.json")
	catalog, err := (Store{}).SocialExchangeCatalogTx(ctx, socialQueryer(manifest, payload), revision)
	if err != nil {
		t.Fatal(err)
	}
	if len(catalog.Products) != 3 || len(catalog.Dropboxes) != 3 {
		t.Fatalf("exchange binding dropped products: %+v", catalog)
	}
	dropboxItems := make(map[int64]map[int64]struct{}, len(catalog.Dropboxes))
	for _, dropbox := range catalog.Dropboxes {
		items := make(map[int64]struct{}, len(dropbox.Rolls))
		for _, roll := range dropbox.Rolls {
			items[roll.ItemID] = struct{}{}
		}
		dropboxItems[dropbox.ID] = items
	}
	op := socialProofOperation(t)
	for _, product := range catalog.Products {
		plan, err := socialexchange.BuildPlan(catalog, product.ID, 1, op)
		if err != nil {
			t.Fatalf("product %d plan: %v", product.ID, err)
		}
		if plan.PriceCurrency != socialexchange.PriceCurrency || plan.UnitPrice != product.SellPrice || plan.TotalCost != product.SellPrice {
			t.Fatalf("product %d cost/currency separation lost: %+v", product.ID, plan)
		}
		items, found := dropboxItems[plan.DropboxID]
		if !found {
			t.Fatalf("product %d planned unknown dropbox %d", product.ID, plan.DropboxID)
		}
		for _, item := range plan.Items {
			if _, found := items[item.ItemID]; !found {
				t.Fatalf("product %d planned item %d outside its dropbox", product.ID, item.ItemID)
			}
			if item.ItemNum <= 0 {
				t.Fatalf("product %d planned non-positive quantity", product.ID)
			}
		}
	}
	second, err := socialexchange.BuildPlan(catalog, 2, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(second.Items, []socialexchange.ItemQuantity{{ItemID: 50001046, ItemNum: 1}}) {
		t.Fatalf("source product 2 reward wrong: %+v", second.Items)
	}
	third, err := socialexchange.BuildPlan(catalog, 3, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(third.Items, []socialexchange.ItemQuantity{{ItemID: 50001024, ItemNum: 1}}) {
		t.Fatalf("source product 3 reward wrong: %+v", third.Items)
	}
	if _, err := socialexchange.BuildPlan(catalog, 1, catalog.ExchangeLimit+1, op); !errors.Is(err, socialexchange.ErrCount) {
		t.Fatalf("count above source limit accepted: %v", err)
	}
	retry, err := socialexchange.BuildPlan(catalog, 1, 10, op)
	if err != nil {
		t.Fatal(err)
	}
	first, err := socialexchange.BuildPlan(catalog, 1, 10, op)
	if err != nil || !reflect.DeepEqual(first, retry) {
		t.Fatalf("retry changed the source plan: %+v %+v %v", first, retry, err)
	}
}

func TestSocialInputCatalogTxRejectsMissingCapabilityAndMalformedPayload(t *testing.T) {
	ctx := context.Background()
	payload := generatedRaw(t, "social_input_catalog.json")
	revision := strings.Repeat("a", 64)
	oldManifest := withoutSocialCapability(t, generatedManifest(t), revision)
	if _, err := (Store{}).SocialInputCatalogTx(ctx, socialQueryer(oldManifest, payload), revision); !errors.Is(err, ErrSocialContentUnavailable) {
		t.Fatalf("capability-less revision served Social content: %v", err)
	}
	if _, err := (Store{}).SocialInputCatalogTx(ctx, socialQueryer(oldManifest, payload), "short"); !errors.Is(err, ErrSocialContentUnavailable) {
		t.Fatalf("invalid revision served Social content: %v", err)
	}

	revision, _ = currentSocialRevision(t)
	manifest := generatedRaw(t, "manifest.json")
	hashMismatch := strings.Replace(payload, `"exchange_limit":10`, `"exchange_limit":9`, 1)
	if hashMismatch == payload {
		t.Fatal("payload fixture changed")
	}
	if _, err := (Store{}).SocialInputCatalogTx(ctx, socialQueryer(manifest, hashMismatch), revision); !errors.Is(err, ErrSocialContentUnavailable) {
		t.Fatalf("hash-mismatched payload accepted: %v", err)
	}
	if _, err := (Store{}).SocialInputCatalogTx(ctx, socialQueryer(manifest, payload+" {}"), revision); err == nil {
		t.Fatal("trailing payload accepted")
	}
	unknownField := `{"unknown":true,` + payload[1:]
	var malformedObject any
	if err := json.Unmarshal([]byte(unknownField), &malformedObject); err != nil {
		t.Fatal(err)
	}
	canonical, err := json.Marshal(malformedObject)
	if err != nil {
		t.Fatal(err)
	}
	digest := sha256.Sum256(append(canonical, '\n'))
	unknownManifest := generatedManifest(t)
	unknownManifest["artifact_sha256s"].(map[string]any)["social_input_catalog.json"] = hex.EncodeToString(digest[:])
	_, err = (Store{}).SocialInputCatalogTx(ctx, socialQueryer(encodeManifest(t, unknownManifest), unknownField), revision)
	if err == nil || errors.Is(err, ErrSocialContentUnavailable) || !strings.Contains(err.Error(), `unknown field "unknown"`) {
		t.Fatalf("matching-hash payload did not reach strict unknown-field rejection: %v", err)
	}
}

func TestOldRevisionKeepsExistingCourseAndGiftContent(t *testing.T) {
	ctx := context.Background()
	revision := strings.Repeat("b", 64)
	manifest := withoutSocialCapability(t, generatedManifest(t), revision)
	q := socialQueryer(manifest, generatedRaw(t, "social_input_catalog.json"))
	q.bySQL[coursePayloadQuery] = []any{generatedRaw(t, "course_input_catalog.json")}
	q.bySQL[giftPayloadQuery] = []any{generatedRaw(t, "social_gift_catalog.json")}

	s := Store{}
	if _, err := s.SocialInputCatalogTx(ctx, q, revision); !errors.Is(err, ErrSocialContentUnavailable) {
		t.Fatalf("old revision served new Social content: %v", err)
	}
	if _, err := s.CourseCatalogTx(ctx, q, revision); err != nil {
		t.Fatalf("old revision lost Course content: %v", err)
	}
	if _, err := s.ReadGiftContent(ctx, q, revision); err != nil {
		t.Fatalf("old revision lost SocialGift content: %v", err)
	}
}

func socialProofOperation(t *testing.T) operation.Context {
	t.Helper()
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	var seed [32]byte
	for index := range seed {
		seed[index] = byte(index + 1)
	}
	return operation.Context{ID: identifier, StartedAt: time.Unix(1_700_000_000, 0).UTC(), EntropySeed: seed}
}

func TestSocialRecallRulesTxBindsSchemaTwoAndRefusesHistoricalManifests(t *testing.T) {
	ctx := context.Background()
	revision, _ := currentSocialRevision(t)
	manifest := generatedRaw(t, "manifest.json")
	payload := generatedRaw(t, "social_input_catalog.json")
	rules, err := (Store{}).SocialRecallRulesTx(ctx, socialQueryer(manifest, payload), revision)
	if err != nil || rules.Limits.RequiredOffline != 7*24*time.Hour || rules.Limits.MaxActiveTasks != 3 || rules.TaskDuration != 3*24*time.Hour {
		t.Fatalf("schema2 rules: %+v %v", rules, err)
	}

	var legacy map[string]any
	if err := json.Unmarshal([]byte(payload), &legacy); err != nil {
		t.Fatal(err)
	}
	legacy["schema_version"] = float64(1)
	delete(legacy, "recall_rules")
	legacyRaw, err := json.Marshal(legacy)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := builtin.DecodeSocialInputCatalog(legacyRaw); err != nil {
		t.Fatalf("schema1 fixture is not a valid historical catalog: %v", err)
	}
	legacyDigest := sha256.Sum256(append(append([]byte{}, legacyRaw...), '\n'))
	legacyManifest := generatedManifest(t)
	legacyManifest["artifact_sha256s"].(map[string]any)["social_input_catalog.json"] = hex.EncodeToString(legacyDigest[:])
	legacyManifestRaw := encodeManifest(t, legacyManifest)
	if _, err := (Store{}).SocialInputCatalogTx(ctx, socialQueryer(legacyManifestRaw, string(legacyRaw)), revision); err != nil {
		t.Fatalf("schema1 historical exchange content became unreadable: %v", err)
	}
	if _, err := (Store{}).SocialRecallRulesTx(ctx, socialQueryer(legacyManifestRaw, string(legacyRaw)), revision); !errors.Is(err, ErrSocialContentUnavailable) {
		t.Fatalf("schema1 historical content invented recall settings: %v", err)
	}

	capabilityless := withoutSocialCapability(t, generatedManifest(t), revision)
	if _, err := (Store{}).SocialRecallRulesTx(ctx, socialQueryer(capabilityless, payload), revision); !errors.Is(err, ErrSocialContentUnavailable) {
		t.Fatalf("capability-less historical manifest served recall settings: %v", err)
	}
}

func TestSocialRecallRulesRejectLegacyAndBindSourceDays(t *testing.T) {
	raw, err := builtin.GeneratedFile("social_input_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := builtin.DecodeSocialInputCatalog(raw)
	if err != nil {
		t.Fatal(err)
	}
	rules, err := socialRecallRules(catalog)
	if err != nil || rules.Limits.RequiredOffline != 7*24*time.Hour || rules.Limits.MaxActiveTasks != 3 || rules.TaskDuration != 3*24*time.Hour {
		t.Fatal(rules, err)
	}
	catalog.SchemaVersion = 1
	catalog.RecallRules = nil
	if _, err = socialRecallRules(catalog); !errors.Is(err, ErrSocialContentUnavailable) {
		t.Fatal("legacy content invented settings", err)
	}
}
