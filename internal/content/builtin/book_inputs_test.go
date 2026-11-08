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

// schema2BookInputCatalog is the generated payload itself; generation is the
// only source of schema2 rows.
func schema2BookInputCatalog(t *testing.T) BookInputCatalog {
	t.Helper()
	return generatedBookInputCatalog(t)
}

// legacyBookInputCatalog is a DTO-level projection of the current schema2
// payload, not the retained old manifest or byte-identical old artifact. It
// proves only that schema1 validation still accepts the unchanged 1/3/4 rows.
func legacyBookInputCatalog(t *testing.T) BookInputCatalog {
	t.Helper()
	catalog := generatedBookInputCatalog(t)
	catalog.SchemaVersion = 1
	buildings := []BookBuildingRule{}
	for _, rule := range catalog.Buildings {
		if rule.Type == 1 || rule.Type == 3 || rule.Type == 4 {
			buildings = append(buildings, rule)
		}
	}
	catalog.Buildings = buildings
	return catalog
}

func TestBookInputCatalogGeneratedSchema2Qualified(t *testing.T) {
	catalog, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if catalog.BookInputs.SchemaVersion != 2 || len(catalog.BookInputs.Buildings) != 135 {
		t.Fatalf("generated book inputs: version %d rows %d", catalog.BookInputs.SchemaVersion, len(catalog.BookInputs.Buildings))
	}
	counts := map[int64]int{}
	var terminal BookBuildingRule
	for _, rule := range catalog.BookInputs.Buildings {
		counts[rule.Type]++
		if rule.Type == 2 && rule.Level == 8 {
			terminal = rule
		}
	}
	want := map[int64]int{1: 6, 2: 8, 3: 6, 4: 100, 5: 5, 6: 5, 7: 5}
	for sourceType, n := range want {
		if counts[sourceType] != n {
			t.Fatalf("type %d rows = %d, want %d", sourceType, counts[sourceType], n)
		}
	}
	if terminal.Type != 2 || terminal.Level != 8 || terminal.Duration != 0 || terminal.RequiresType != 0 || terminal.RequiresLevel != 0 {
		t.Fatalf("terminal workbench row = %+v", terminal)
	}
}

func TestBookInputCatalogLegacyDTOProjectionQualified(t *testing.T) {
	catalog := legacyBookInputCatalog(t)
	if err := catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	counts := map[int64]int{}
	for _, rule := range catalog.Buildings {
		counts[rule.Type]++
	}
	if len(catalog.Buildings) != 112 || counts[1] != 6 || counts[3] != 6 || counts[4] != 100 {
		t.Fatalf("legacy projection rows=%d counts=%v", len(catalog.Buildings), counts)
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
			build: legacyBookInputCatalog,
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
