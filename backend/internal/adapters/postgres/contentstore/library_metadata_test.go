package contentstore

import (
	"encoding/json"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/content/builtin"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
)

const metadataRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

func loadedLibraryInputs(t *testing.T) builtin.LibraryInputCatalog {
	t.Helper()
	catalog, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	return catalog.LibraryInputs
}

func domainFrom(t *testing.T, payload builtin.LibraryInputCatalog) library.Catalog {
	t.Helper()
	domain, e := libraryCatalogDomain(payload, metadataRevision)
	if e != nil {
		t.Fatal(e)
	}
	return domain
}

func TestLibraryCatalogRetainsCardSourceMetadata(t *testing.T) {
	domain := domainFrom(t, loadedLibraryInputs(t))
	base, ok := domain.Templates[10001001]
	if !ok || base.ModelID != 10001001 || base.AwakenTableID != 11001001 || base.Awaken != 1 {
		t.Fatalf("base template %+v", base)
	}
	transformed, ok := domain.Templates[11001001]
	if !ok || transformed.ModelID != 11001001 || transformed.AwakenTableID != 0 || transformed.Awaken != 1 {
		t.Fatalf("transformed template %+v", transformed)
	}
	if got, want := len(domain.Templates), 568; got != want {
		t.Fatalf("templates = %d, want %d", got, want)
	}
}

func TestLibraryCatalogOldRevisionWithoutCardMetadata(t *testing.T) {
	payload := loadedLibraryInputs(t)
	raw, e := json.Marshal(payload)
	if e != nil {
		t.Fatal(e)
	}
	var generic map[string]any
	if e = json.Unmarshal(raw, &generic); e != nil {
		t.Fatal(e)
	}
	for _, entry := range generic["templates"].([]any) {
		template := entry.(map[string]any)
		delete(template, "model_id")
		delete(template, "awaken_table_id")
		delete(template, "awaken")
	}
	oldRaw, e := json.Marshal(generic)
	if e != nil {
		t.Fatal(e)
	}
	var old builtin.LibraryInputCatalog
	if e = json.Unmarshal(oldRaw, &old); e != nil {
		t.Fatal(e)
	}
	domain := domainFrom(t, old)
	template := domain.Templates[10001001]
	if template.ModelID != 0 || template.AwakenTableID != 0 || template.Awaken != 0 {
		t.Fatalf("missing metadata decoded %+v", template)
	}
	if template.RelationshipSourceID != 10001001 || template.CollectionSourceID != 10001001 || !template.DialogEnabled {
		t.Fatalf("unrelated template identity lost %+v", template)
	}
	if len(domain.Gifts) != 10 || !domain.Gifts[50001112].Ring || len(domain.Talks) != 23 || len(domain.DialogConfigs) != 19 || len(domain.CourseGiftBoxes) != 2 {
		t.Fatalf("unrelated catalogs changed gifts=%d talks=%d dialogs=%d boxes=%d", len(domain.Gifts), len(domain.Talks), len(domain.DialogConfigs), len(domain.CourseGiftBoxes))
	}
}

func TestLibraryCatalogRejectsMalformedCardMetadata(t *testing.T) {
	for name, mutate := range map[string]func(*builtin.LibraryTemplateRule){
		"negative model":    func(r *builtin.LibraryTemplateRule) { r.ModelID = -1 },
		"negative target":   func(r *builtin.LibraryTemplateRule) { r.AwakenTableID = -1 },
		"non boolean awake": func(r *builtin.LibraryTemplateRule) { r.Awaken = 2 },
	} {
		t.Run(name, func(t *testing.T) {
			payload := loadedLibraryInputs(t)
			mutate(&payload.Templates[0])
			if _, e := libraryCatalogDomain(payload, metadataRevision); e != library.ErrUnqualified {
				t.Fatalf("error = %v", e)
			}
		})
	}
	payload := loadedLibraryInputs(t)
	payload.Templates = payload.Templates[:len(payload.Templates)-1]
	if _, e := libraryCatalogDomain(payload, metadataRevision); e == nil {
		t.Fatal("short template catalog accepted")
	}
	if !library.ValidRevision(strings.Repeat("a", 64)) {
		t.Fatal("fixture revision invalid")
	}
}
