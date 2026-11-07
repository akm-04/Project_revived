package builtin

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func loadDormV1(t *testing.T) DormInputCatalog {
	t.Helper()
	raw, err := os.ReadFile(filepath.Join("generated", "dorm_input_catalog.json"))
	if err != nil {
		t.Fatal(err)
	}

	var legacyFields map[string]json.RawMessage
	if err := json.Unmarshal(raw, &legacyFields); err != nil {
		t.Fatal(err)
	}
	delete(legacyFields, "glue")
	legacyFields["schema_version"] = json.RawMessage("1")
	legacyRaw, err := json.Marshal(legacyFields)
	if err != nil {
		t.Fatal(err)
	}
	legacyRaw = append(legacyRaw, '\n')
	digest := sha256.Sum256(legacyRaw)
	if hex.EncodeToString(digest[:]) != "9fa00237f6b160e7465b44edcf28aeb4b8b6ff46c1ed5e64189f2c2b4b2ce20f" {
		t.Fatal("retained schema1 payload changed")
	}
	var catalog DormInputCatalog
	decoder := json.NewDecoder(bytes.NewReader(legacyRaw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&catalog); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func validDormV2(t *testing.T) DormInputCatalog {
	t.Helper()
	catalog := loadDormV1(t)
	catalog.SchemaVersion = 2
	catalog.Glue = &DormGlueRules{
		DailyFloor:         100,
		PurchaseAmount:     50,
		PurchaseStartLimit: 300,
		VIPDailyCaps:       []DormVIPDailyCap{{VIP: 0, Cap: 1}, {VIP: 1, Cap: 2}},
		PurchaseCosts:      []DormPurchaseCost{{Ordinal: 1, Cost: 50}, {Ordinal: 2, Cost: 100}},
	}
	if err := catalog.Validate(); err != nil {
		t.Fatalf("v2 fixture is invalid: %v", err)
	}
	return catalog
}

func TestDormQualifiedPayloadAndEquipmentReuse(t *testing.T) {
	c, e := Load()
	if e != nil {
		t.Fatal(e)
	}
	d := c.DormInputs
	if e = d.Validate(); e != nil {
		t.Fatal(e)
	}
	if len(d.Rooms) != 16 || len(d.Furniture) != 267 || d.OriginalServerPolicyRecovered {
		t.Fatal("wrong profile")
	}
	primitives := map[int64]int64{}
	for _, r := range c.EquipmentPrimitives.Items {
		primitives[r.ItemID] = r.RequiredLevel
	}
	for _, r := range d.EquipmentItems {
		if primitives[r.ItemID] != r.RequiredLevel {
			t.Fatalf("Dorm item %d contradicts accepted equipment primitive", r.ItemID)
		}
	}
	for _, r := range d.HeroEquipment {
		if r.TemplateID == 11001 && r.Items[0] != 20001299 {
			t.Fatal("Super zero-before-awaken lost source", r)
		}
	}
	d.Keys = append([]DormKeyRule(nil), d.Keys...)
	d.Keys[0].Templates = []int64{999999}
	if d.Validate() == nil {
		t.Fatal("unknown room template qualified")
	}
}

func TestDormInputCatalogAcceptsV1WithoutGlue(t *testing.T) {
	catalog := loadDormV1(t)
	if catalog.SchemaVersion != 1 {
		t.Fatalf("checked-in schema_version = %d, want 1", catalog.SchemaVersion)
	}
	if catalog.Glue != nil {
		t.Fatal("schema 1 fixture unexpectedly carries glue")
	}
	if err := catalog.Validate(); err != nil {
		t.Fatalf("schema 1 rejected: %v", err)
	}
}

func TestDormInputCatalogAcceptsStrictV2RoundTrip(t *testing.T) {
	raw, err := json.Marshal(validDormV2(t))
	if err != nil {
		t.Fatal(err)
	}
	var decoded DormInputCatalog
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&decoded); err != nil {
		t.Fatal(err)
	}
	if err := decoded.Validate(); err != nil {
		t.Fatalf("v2 round trip rejected: %v", err)
	}
	if decoded.SchemaVersion != 2 || decoded.Glue == nil {
		t.Fatalf("v2 round trip lost glue: %+v", decoded)
	}
	if decoded.Glue.DailyFloor != 100 || decoded.Glue.PurchaseAmount != 50 || decoded.Glue.PurchaseStartLimit != 300 {
		t.Fatalf("v2 glue scalars = %+v", decoded.Glue)
	}
	if len(decoded.Glue.VIPDailyCaps) != 2 || decoded.Glue.VIPDailyCaps[1] != (DormVIPDailyCap{VIP: 1, Cap: 2}) {
		t.Fatalf("v2 vip caps = %+v", decoded.Glue.VIPDailyCaps)
	}
	if len(decoded.Glue.PurchaseCosts) != 2 || decoded.Glue.PurchaseCosts[1] != (DormPurchaseCost{Ordinal: 2, Cost: 100}) {
		t.Fatalf("v2 purchase costs = %+v", decoded.Glue.PurchaseCosts)
	}
}

func TestDormInputCatalogRejectsUnqualifiedGlue(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(*DormInputCatalog)
	}{
		{name: "schema 1 carrying glue", mutate: func(c *DormInputCatalog) { c.SchemaVersion = 1 }},
		{name: "schema 3", mutate: func(c *DormInputCatalog) { c.SchemaVersion = 3 }},
		{name: "schema 2 without glue", mutate: func(c *DormInputCatalog) { c.Glue = nil }},
		{name: "empty vip caps", mutate: func(c *DormInputCatalog) { c.Glue.VIPDailyCaps = nil }},
		{name: "empty purchase costs", mutate: func(c *DormInputCatalog) { c.Glue.PurchaseCosts = nil }},
		{name: "duplicate vip cap", mutate: func(c *DormInputCatalog) {
			c.Glue.VIPDailyCaps = []DormVIPDailyCap{{VIP: 0, Cap: 1}, {VIP: 0, Cap: 1}}
		}},
		{name: "unsorted vip caps", mutate: func(c *DormInputCatalog) {
			c.Glue.VIPDailyCaps = []DormVIPDailyCap{{VIP: 1, Cap: 2}, {VIP: 0, Cap: 1}}
		}},
		{name: "negative vip", mutate: func(c *DormInputCatalog) {
			c.Glue.VIPDailyCaps = []DormVIPDailyCap{{VIP: -1, Cap: 0}}
		}},
		{name: "negative cap", mutate: func(c *DormInputCatalog) { c.Glue.VIPDailyCaps[0].Cap = -1 }},
		{name: "duplicate purchase cost", mutate: func(c *DormInputCatalog) {
			c.Glue.PurchaseCosts = []DormPurchaseCost{{Ordinal: 1, Cost: 50}, {Ordinal: 1, Cost: 50}}
		}},
		{name: "unsorted purchase costs", mutate: func(c *DormInputCatalog) {
			c.Glue.PurchaseCosts = []DormPurchaseCost{{Ordinal: 2, Cost: 100}, {Ordinal: 1, Cost: 50}}
		}},
		{name: "zero ordinal", mutate: func(c *DormInputCatalog) {
			c.Glue.PurchaseCosts = []DormPurchaseCost{{Ordinal: 0, Cost: 50}}
		}},
		{name: "non-contiguous purchase costs", mutate: func(c *DormInputCatalog) {
			c.Glue.PurchaseCosts = []DormPurchaseCost{{Ordinal: 2, Cost: 100}}
		}},
		{name: "negative cost", mutate: func(c *DormInputCatalog) { c.Glue.PurchaseCosts[0].Cost = -1 }},
		{name: "cap without cost ordinal", mutate: func(c *DormInputCatalog) { c.Glue.VIPDailyCaps[1].Cap = 3 }},
		{name: "negative daily floor", mutate: func(c *DormInputCatalog) { c.Glue.DailyFloor = -1 }},
		{name: "negative purchase amount", mutate: func(c *DormInputCatalog) { c.Glue.PurchaseAmount = -1 }},
		{name: "negative purchase start limit", mutate: func(c *DormInputCatalog) { c.Glue.PurchaseStartLimit = -1 }},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			catalog := validDormV2(t)
			testCase.mutate(&catalog)
			if err := catalog.Validate(); err == nil {
				t.Fatal("unqualified glue accepted")
			}
		})
	}
}

func TestDormInputCatalogStrictDecodeRejectsUnknownGlueField(t *testing.T) {
	raw, err := json.Marshal(validDormV2(t))
	if err != nil {
		t.Fatal(err)
	}
	var document map[string]any
	if err := json.Unmarshal(raw, &document); err != nil {
		t.Fatal(err)
	}
	document["glue"].(map[string]any)["invented_cap"] = 1
	tampered, err := json.Marshal(document)
	if err != nil {
		t.Fatal(err)
	}
	var catalog DormInputCatalog
	decoder := json.NewDecoder(bytes.NewReader(tampered))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&catalog); err == nil {
		t.Fatal("unknown glue field accepted")
	}
}
