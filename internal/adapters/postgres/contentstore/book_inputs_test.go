package contentstore

import (
	"bytes"
	"encoding/json"
	"os"
	"testing"

	"gxb.local/backend/v2/internal/content/builtin"
)

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

// legacyBookInputCatalogDTO projects the generated schema2 payload to schema1;
// DTO-level proof only, not the retained old manifest or byte-identical old artifact.
func legacyBookInputCatalogDTO(t *testing.T) builtin.BookInputCatalog {
	t.Helper()
	catalog := generatedBookInputCatalog(t)
	catalog.SchemaVersion = 1
	buildings := []builtin.BookBuildingRule{}
	for _, rule := range catalog.Buildings {
		if rule.Type == 1 || rule.Type == 3 || rule.Type == 4 {
			buildings = append(buildings, rule)
		}
	}
	catalog.Buildings = buildings
	return catalog
}

func TestBookCatalogDomainBindsSchema2UpgradeCatalog(t *testing.T) {
	version1, err := bookCatalogDomain(legacyBookInputCatalogDTO(t))
	if err != nil {
		t.Fatal(err)
	}
	if len(version1.Buildings) != 112 {
		t.Fatalf("legacy projection building rules = %d, want 112", len(version1.Buildings))
	}
	version2, err := bookCatalogDomain(generatedBookInputCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	if len(version2.Buildings) != 135 {
		t.Fatalf("schema2 building rules = %d, want 135", len(version2.Buildings))
	}
	rule, ok := version2.Buildings[[2]int64{2, 8}]
	if !ok || rule.Duration != 0 || rule.RequiresType != 0 || rule.RequiresLevel != 0 || rule.CutTime != 0 {
		t.Fatalf("schema2 workbench binding = %+v, present %t", rule, ok)
	}
}

func TestBookCatalogDomainRejectsDuplicateSchema2Building(t *testing.T) {
	catalogDTO := generatedBookInputCatalog(t)
	catalogDTO.Buildings = append([]builtin.BookBuildingRule(nil), catalogDTO.Buildings...)
	catalogDTO.Buildings[len(catalogDTO.Buildings)-1].Level = 1
	if _, err := bookCatalogDomain(catalogDTO); err == nil {
		t.Fatal("duplicate schema2 building key qualified")
	}
}

func TestBookCatalogDomainCompilerPayload(t *testing.T) {
	payloadPath := os.Getenv("GXB_BOOK_COMPILER_PAYLOAD")
	if payloadPath == "" {
		t.Skip("compiler-produced payload not supplied")
	}
	raw, err := os.ReadFile(payloadPath)
	if err != nil {
		t.Fatal(err)
	}
	var input builtin.BookInputCatalog
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&input); err != nil {
		t.Fatal(err)
	}
	catalog, err := bookCatalogDomain(input)
	if err != nil {
		t.Fatal(err)
	}
	if input.SchemaVersion != 2 || len(catalog.Buildings) != 135 {
		t.Fatalf("unexpected compiler payload: schema %d, buildings %d", input.SchemaVersion, len(catalog.Buildings))
	}
	terminal := catalog.Buildings[[2]int64{2, 8}]
	if terminal.Duration != 0 || terminal.CutTime != 0 || len(terminal.Resources) != 0 {
		t.Fatalf("terminal workbench binding = %+v", terminal)
	}
	if catalog.Buildings[[2]int64{2, 3}].Resources["magic_energy"] != 1000 || catalog.Buildings[[2]int64{7, 1}].RequiresType != 2 {
		t.Fatal("source building facts changed at binding")
	}
}
