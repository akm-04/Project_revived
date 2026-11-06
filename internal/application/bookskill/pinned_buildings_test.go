package bookskill

import (
	"context"
	"reflect"
	"strings"
	"testing"
	"time"

	book "gxb.local/backend/v2/internal/domain/bookskill"
)

func TestExtensionFactsPreserveCallerCatalogAndQualifyBothPins(t *testing.T) {
	legacy := a44Catalog(false)
	service, owner, content, at := a44Service(legacy)
	revision := strings.Repeat("b", 64)
	jobRevision := strings.Repeat("c", 64)
	content.catalogs[revision] = a44Catalog(true)
	content.catalogs[jobRevision] = a44Catalog(true)
	owner.root.Facts.Buildings[2] = book.Building{Level: 1, CatalogRevision: revision, Job: &book.Job{Occurrence: "extension", Revision: jobRevision, StartedAt: at.Add(-time.Minute), Duration: 60, Target: 2, Subject: 2, Cost: book.EmptyCost()}}
	original := owner.root.Facts.Clone()
	inputs, err := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at})
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(inputs.Catalog, legacy) || inputs.ContentRevision != a44Revision {
		t.Fatal("caller catalog or pin changed")
	}
	if inputs.Applied.Buildings[2].Level != 2 || inputs.Applied.Buildings[2].CatalogRevision != jobRevision || inputs.Applied.Buildings[2].Job != nil {
		t.Fatal("completed target lost provenance", inputs.Applied.Buildings[2])
	}
	if !reflect.DeepEqual(original, owner.root.Facts) || owner.writes != 0 {
		t.Fatal("pure projection mutated owner")
	}
	if !reflect.DeepEqual(content.reads, []string{a44Revision, revision, jobRevision}) {
		t.Fatal("distinct pins not loaded deterministically", content.reads)
	}
	delete(content.catalogs[jobRevision].Buildings, [2]int64{2, 2})
	if _, err := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at}); err == nil {
		t.Fatal("missing pinned target rule admitted")
	}
	if !reflect.DeepEqual(original, owner.root.Facts) || owner.writes != 0 {
		t.Fatal("failed validation mutated owner")
	}
}

func TestPinnedExtensionFailuresDoNotWriteOrSubstituteActiveContent(t *testing.T) {
	for _, name := range []string{"missing-pin", "malformed-pin", "unavailable-pin", "unknown-type", "missing-legacy", "missing-level", "same-pin"} {
		t.Run(name, func(t *testing.T) {
			legacy := a44Catalog(false)
			service, owner, content, at := a44Service(legacy)
			revision := strings.Repeat("b", 64)
			content.catalogs[revision] = a44Catalog(true)
			owner.root.Facts.Buildings[2] = book.Building{Level: 1, CatalogRevision: revision}
			switch name {
			case "missing-pin":
				owner.root.Facts.Buildings[2] = book.Building{Level: 1}
			case "malformed-pin":
				owner.root.Facts.Buildings[2] = book.Building{Level: 1, CatalogRevision: strings.Repeat("z", 64)}
			case "unavailable-pin":
				delete(content.catalogs, revision)
			case "unknown-type":
				owner.root.Facts.Buildings[9] = book.Building{Level: 1, CatalogRevision: revision}
			case "missing-legacy":
				delete(owner.root.Facts.Buildings, 3)
			case "missing-level":
				delete(content.catalogs[revision].Buildings, [2]int64{2, 1})
			case "same-pin":
				owner.root.Facts.Buildings[5] = book.Building{Level: 1, CatalogRevision: revision}
			}
			original := owner.root.Facts.Clone()
			inputs, err := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at})
			if name == "same-pin" {
				if err != nil || !reflect.DeepEqual(content.reads, []string{a44Revision, revision}) {
					t.Fatal("pin not deduplicated", err, content.reads)
				}
			} else if err == nil || !reflect.DeepEqual(inputs, Inputs{}) {
				t.Fatal("unqualified extension returned usable inputs", err)
			}
			if owner.writes != 0 || !reflect.DeepEqual(owner.root.Facts, original) {
				t.Fatal("read mutated owner")
			}
		})
	}
}
