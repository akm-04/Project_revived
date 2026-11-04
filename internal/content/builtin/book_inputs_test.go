package builtin

import (
	"encoding/json"
	"testing"
)

func generatedBookInputCatalog(t *testing.T) BookInputCatalog {
	t.Helper()
	raw, err := GeneratedFile("book_input_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog BookInputCatalog
	if err := json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func schema2BookInputCatalog(t *testing.T) BookInputCatalog {
	t.Helper()
	catalog := generatedBookInputCatalog(t)
	catalog.SchemaVersion = 2
	added := []BookBuildingRule{
		{Type: 2, Level: 1, Duration: 43200, RequiresType: 1, RequiresLevel: 2, Resources: map[string]int64{"magic_dust": 25000, "magic_liquid": 25000, "magic_energy": 150}},
		{Type: 2, Level: 2, Duration: 86400, RequiresType: 1, RequiresLevel: 3, Resources: map[string]int64{"magic_dust": 50000, "magic_liquid": 50000, "magic_energy": 400}},
		{Type: 2, Level: 3, Duration: 129600, RequiresType: 1, RequiresLevel: 4},
		{Type: 2, Level: 4, Duration: 172800, RequiresType: 1, RequiresLevel: 5},
		{Type: 2, Level: 5, Duration: 216000, RequiresType: 1, RequiresLevel: 5},
		{Type: 2, Level: 6, Duration: 259200, RequiresType: 1, RequiresLevel: 6},
		{Type: 2, Level: 7, Duration: 302400, RequiresType: 1, RequiresLevel: 6},
		{Type: 2, Level: 8},
		{Type: 5, Level: 1, Duration: 43200, RequiresType: 1, RequiresLevel: 2},
		{Type: 5, Level: 2, Duration: 86400, RequiresType: 1, RequiresLevel: 3},
		{Type: 5, Level: 3, Duration: 129600, RequiresType: 1, RequiresLevel: 4},
		{Type: 5, Level: 4, Duration: 172800, RequiresType: 1, RequiresLevel: 5},
		{Type: 5, Level: 5},
		{Type: 6, Level: 1, Duration: 43200, RequiresType: 1, RequiresLevel: 2},
		{Type: 6, Level: 2, Duration: 86400, RequiresType: 1, RequiresLevel: 3},
		{Type: 6, Level: 3, Duration: 129600, RequiresType: 1, RequiresLevel: 4},
		{Type: 6, Level: 4, Duration: 172800, RequiresType: 1, RequiresLevel: 5},
		{Type: 6, Level: 5},
		{Type: 7, Level: 1, Duration: 43200, RequiresType: 2, RequiresLevel: 2},
		{Type: 7, Level: 2, Duration: 86400, RequiresType: 2, RequiresLevel: 3},
		{Type: 7, Level: 3, Duration: 129600, RequiresType: 2, RequiresLevel: 4},
		{Type: 7, Level: 4, Duration: 172800, RequiresType: 2, RequiresLevel: 5},
		{Type: 7, Level: 5, RequiresType: 2},
	}
	catalog.Buildings = append(append([]BookBuildingRule(nil), catalog.Buildings...), added...)
	return catalog
}

func TestBookInputCatalogSchema1RemainsQualified(t *testing.T) {
	catalog, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if catalog.BookInputs.SchemaVersion != 1 || len(catalog.BookInputs.Buildings) != 112 {
		t.Fatalf("schema1 book inputs no longer load: version %d rows %d", catalog.BookInputs.SchemaVersion, len(catalog.BookInputs.Buildings))
	}
}

func TestBookInputCatalogSchema2Qualified(t *testing.T) {
	catalog := schema2BookInputCatalog(t)
	if err := catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	if len(catalog.Buildings) != 135 {
		t.Fatalf("schema2 building rows = %d, want 135", len(catalog.Buildings))
	}
}

func TestBookInputCatalogRejectsMalformedSchemas(t *testing.T) {
	tests := []struct {
		name   string
		build  func(t *testing.T) BookInputCatalog
		mutate func(*BookInputCatalog)
	}{
		{
			name:  "unknown schema version",
			build: generatedBookInputCatalog,
			mutate: func(c *BookInputCatalog) {
				c.SchemaVersion = 3
			},
		},
		{
			name:  "schema1 carrying a schema2 building type",
			build: generatedBookInputCatalog,
			mutate: func(c *BookInputCatalog) {
				c.Buildings = append([]BookBuildingRule(nil), c.Buildings...)
				c.Buildings[0].Type = 2
			},
		},
		{
			name:  "schema2 missing a building type",
			build: schema2BookInputCatalog,
			mutate: func(c *BookInputCatalog) {
				c.Buildings = append([]BookBuildingRule(nil), c.Buildings...)
				for i := range c.Buildings {
					if c.Buildings[i].Type == 5 {
						c.Buildings[i].Type = 1
					}
				}
			},
		},
		{
			name:  "schema2 short building rows",
			build: schema2BookInputCatalog,
			mutate: func(c *BookInputCatalog) {
				c.Buildings = append([]BookBuildingRule(nil), c.Buildings[:len(c.Buildings)-1]...)
			},
		},
		{
			name:  "duplicate building source key",
			build: schema2BookInputCatalog,
			mutate: func(c *BookInputCatalog) {
				c.Buildings = append([]BookBuildingRule(nil), c.Buildings...)
				c.Buildings[len(c.Buildings)-1].Level = 1
			},
		},
		{
			name:  "schema2 short book rows",
			build: schema2BookInputCatalog,
			mutate: func(c *BookInputCatalog) {
				c.Books = append([]BookRule(nil), c.Books[:len(c.Books)-1]...)
			},
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			catalog := test.build(t)
			test.mutate(&catalog)
			if err := catalog.Validate(); err == nil {
				t.Fatal("malformed book input catalog qualified")
			}
		})
	}
}
