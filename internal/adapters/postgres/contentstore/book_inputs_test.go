package contentstore

import (
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/content/builtin"
)

func schema2BuildingRows() []builtin.BookBuildingRule {
	rows := []builtin.BookBuildingRule{}
	for level := int64(1); level <= 8; level++ {
		rows = append(rows, builtin.BookBuildingRule{Type: 2, Level: level, Duration: 43200, RequiresType: 1, RequiresLevel: 2})
	}
	for sourceType, levels := range map[int64]int64{5: 5, 6: 5, 7: 5} {
		for level := int64(1); level <= levels; level++ {
			rows = append(rows, builtin.BookBuildingRule{Type: sourceType, Level: level, Duration: 43200, RequiresType: 1, RequiresLevel: 2})
		}
	}
	return rows
}

func generatedBookInputCatalog(t *testing.T) builtin.BookInputCatalog {
	t.Helper()
	raw, err := builtin.GeneratedFile("book_input_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog builtin.BookInputCatalog
	if err := json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func TestBookCatalogDomainBindsSchema2UpgradeCatalog(t *testing.T) {
	catalogDTO := generatedBookInputCatalog(t)
	version1, err := bookCatalogDomain(catalogDTO)
	if err != nil {
		t.Fatal(err)
	}
	if len(version1.Buildings) != 112 {
		t.Fatalf("schema1 building rules = %d, want 112", len(version1.Buildings))
	}
	catalogDTO.SchemaVersion = 2
	catalogDTO.Buildings = append(append([]builtin.BookBuildingRule(nil), catalogDTO.Buildings...), schema2BuildingRows()...)
	version2, err := bookCatalogDomain(catalogDTO)
	if err != nil {
		t.Fatal(err)
	}
	if len(version2.Buildings) != 135 {
		t.Fatalf("schema2 building rules = %d, want 135", len(version2.Buildings))
	}
	rule, ok := version2.Buildings[[2]int64{2, 8}]
	if !ok || rule.Duration != 43200 || rule.CutTime != 0 {
		t.Fatalf("schema2 workbench binding = %+v, present %t", rule, ok)
	}
}

func TestBookCatalogDomainRejectsDuplicateSchema2Building(t *testing.T) {
	catalogDTO := generatedBookInputCatalog(t)
	catalogDTO.SchemaVersion = 2
	catalogDTO.Buildings = append(append([]builtin.BookBuildingRule(nil), catalogDTO.Buildings...), schema2BuildingRows()...)
	catalogDTO.Buildings[len(catalogDTO.Buildings)-1].Level = 1
	if _, err := bookCatalogDomain(catalogDTO); err == nil {
		t.Fatal("duplicate schema2 building key qualified")
	}
}
