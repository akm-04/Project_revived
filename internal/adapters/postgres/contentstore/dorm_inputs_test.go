package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
)

func dormTestRevision(label string) string {
	sum := sha256.Sum256([]byte(label))
	return hex.EncodeToString(sum[:])
}

func decodeDormV1(t *testing.T, bundle registry.Bundle) builtin.DormInputCatalog {
	t.Helper()
	var catalog builtin.DormInputCatalog
	decoder := json.NewDecoder(bytes.NewReader(bundle.DormInputsJSON()))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&catalog); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func encodeDormPayload(t *testing.T, catalog builtin.DormInputCatalog) []byte {
	t.Helper()
	raw, err := json.Marshal(catalog)
	if err != nil {
		t.Fatal(err)
	}
	return raw
}

func v2DormCatalog(t *testing.T, bundle registry.Bundle) builtin.DormInputCatalog {
	t.Helper()
	catalog := decodeDormV1(t, bundle)
	catalog.SchemaVersion = 2
	catalog.Glue = &builtin.DormGlueRules{
		DailyFloor:         100,
		PurchaseAmount:     50,
		PurchaseStartLimit: 300,
		VIPDailyCaps:       []builtin.DormVIPDailyCap{{VIP: 0, Cap: 1}, {VIP: 1, Cap: 2}},
		PurchaseCosts:      []builtin.DormPurchaseCost{{Ordinal: 1, Cost: 50}, {Ordinal: 2, Cost: 100}},
	}
	return catalog
}

func dormFixtureManifest(t *testing.T, bundle registry.Bundle, revision string, payload []byte) []byte {
	t.Helper()
	manifest, err := registry.DecodeManifestStrict(bundle.ManifestJSON())
	if err != nil {
		t.Fatal(err)
	}
	manifest.RevisionID = revision
	var generic any
	if err := json.Unmarshal(payload, &generic); err != nil {
		t.Fatal(err)
	}
	canonical, err := json.Marshal(generic)
	if err != nil {
		t.Fatal(err)
	}
	hash := sha256.Sum256(append(canonical, '\n'))
	manifest.ArtifactSHA256s["dorm_input_catalog.json"] = hex.EncodeToString(hash[:])
	raw, err := json.Marshal(manifest)
	if err != nil {
		t.Fatal(err)
	}
	return raw
}

func loadDormFixture(t *testing.T, revision string, manifest, payload []byte) (dorm.Catalog, error) {
	t.Helper()
	queryer := &recording{bySQL: map[string][]any{
		`SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`:      {string(manifest)},
		`SELECT payload::text FROM content_dorm_input_catalogs WHERE revision_id=$1`: {string(payload)},
	}}
	return (Store{}).DormCatalogTx(context.Background(), queryer, revision)
}

func TestDormCatalogReadsV1WithoutGlue(t *testing.T) {
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := loadDormFixture(t, bundle.RevisionID(), bundle.ManifestJSON(), bundle.DormInputsJSON())
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Glue != nil {
		t.Fatal("schema 1 catalog gained glue")
	}
	if len(catalog.Rooms) != 16 {
		t.Fatalf("rooms = %d, want 16", len(catalog.Rooms))
	}
}

func TestDormCatalogReadsV2Glue(t *testing.T) {
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	payload := encodeDormPayload(t, v2DormCatalog(t, bundle))
	revision := dormTestRevision("dorm v2 glue accepted")
	catalog, err := loadDormFixture(t, revision, dormFixtureManifest(t, bundle, revision, payload), payload)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Glue == nil {
		t.Fatal("schema 2 catalog lost glue")
	}
	if catalog.Glue.DailyFloor != 100 || catalog.Glue.PurchaseAmount != 50 || catalog.Glue.PurchaseStartLimit != 300 {
		t.Fatalf("glue scalars = %+v", catalog.Glue)
	}
	if cap, ok := catalog.Glue.VIPDailyCap(1); !ok || cap != 2 {
		t.Fatalf("VIPDailyCap(1) = %d,%v", cap, ok)
	}
	if _, ok := catalog.Glue.VIPDailyCap(2); ok {
		t.Fatal("unknown VIP returned a guessed cap")
	}
	if cost, ok := catalog.Glue.PurchaseCost(2); !ok || cost != 100 {
		t.Fatalf("PurchaseCost(2) = %d,%v", cost, ok)
	}
	if _, ok := catalog.Glue.PurchaseCost(3); ok {
		t.Fatal("unknown ordinal returned a guessed cost")
	}
}

func TestDormCatalogRejectsSchemaOneCarryingGlue(t *testing.T) {
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	catalog := decodeDormV1(t, bundle)
	catalog.Glue = &builtin.DormGlueRules{
		DailyFloor:         100,
		PurchaseAmount:     50,
		PurchaseStartLimit: 300,
		VIPDailyCaps:       []builtin.DormVIPDailyCap{{VIP: 0, Cap: 1}},
		PurchaseCosts:      []builtin.DormPurchaseCost{{Ordinal: 1, Cost: 50}},
	}
	payload := encodeDormPayload(t, catalog)
	revision := dormTestRevision("dorm schema1 glue rejected")
	if _, err := loadDormFixture(t, revision, dormFixtureManifest(t, bundle, revision, payload), payload); err == nil {
		t.Fatal("schema 1 carrying glue accepted")
	}
}

func TestDormCatalogRejectsV2MissingCostOrdinal(t *testing.T) {
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	catalog := v2DormCatalog(t, bundle)
	catalog.Glue.PurchaseCosts = []builtin.DormPurchaseCost{{Ordinal: 2, Cost: 100}}
	payload := encodeDormPayload(t, catalog)
	revision := dormTestRevision("dorm v2 missing cost rejected")
	if _, err := loadDormFixture(t, revision, dormFixtureManifest(t, bundle, revision, payload), payload); err == nil {
		t.Fatal("v2 cap without its cost ordinal accepted")
	}
}

func TestDormCatalogRejectsUnknownGlueField(t *testing.T) {
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	raw := encodeDormPayload(t, v2DormCatalog(t, bundle))
	var document map[string]any
	if err := json.Unmarshal(raw, &document); err != nil {
		t.Fatal(err)
	}
	document["glue"].(map[string]any)["invented_cap"] = 1
	payload, err := json.Marshal(document)
	if err != nil {
		t.Fatal(err)
	}
	revision := dormTestRevision("dorm v2 unknown field rejected")
	if _, err := loadDormFixture(t, revision, dormFixtureManifest(t, bundle, revision, payload), payload); err == nil {
		t.Fatal("unknown glue field accepted")
	}
}
