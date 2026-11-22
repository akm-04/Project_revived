package bookskill

import (
	"context"
	"reflect"
	"testing"
	"time"

	book "gxb.local/backend/v2/internal/domain/bookskill"
)

// The interface bound is four extension buildings times current+job pins:
// eight distinct revisions, read once each in sorted order.
func TestA55EightDistinctPinsBoundedAndSorted(t *testing.T) {
	service, owner, content, at := a44Service(a44Catalog(false))
	pins := []string{
		"1111111111111111111111111111111111111111111111111111111111111111",
		"2222222222222222222222222222222222222222222222222222222222222222",
		"3333333333333333333333333333333333333333333333333333333333333333",
		"4444444444444444444444444444444444444444444444444444444444444444",
		"5555555555555555555555555555555555555555555555555555555555555555",
		"6666666666666666666666666666666666666666666666666666666666666666",
		"7777777777777777777777777777777777777777777777777777777777777777",
		"8888888888888888888888888888888888888888888888888888888888888888",
	}
	kinds := []int64{2, 5, 6, 7}
	for index, kind := range kinds {
		current, jobPin := pins[index], pins[index+len(kinds)]
		content.catalogs[current] = a44Catalog(true)
		content.catalogs[jobPin] = a44Catalog(true)
		owner.root.Facts.Buildings[kind] = book.Building{Level: 1, CatalogRevision: current, Job: &book.Job{Occurrence: "a55", Revision: jobPin, StartedAt: at.Add(-time.Minute), Duration: 3600, Target: 2, Subject: kind, Cost: book.EmptyCost()}}
	}
	inputs, err := service.BookInputsTx(context.Background(), a44Queryer{}, InputScope{Player: 1, ContentRevision: a44Revision, ObservedAt: at})
	if err != nil {
		t.Fatal(err)
	}
	if len(inputs.Catalog.Buildings) != 112 || inputs.ContentRevision != a44Revision {
		t.Fatal("caller catalog or revision changed")
	}
	if len(content.reads) != len(pins)+1 || content.reads[0] != a44Revision || !reflect.DeepEqual(content.reads[1:], pins) {
		t.Fatalf("reads = %v, want caller then sorted distinct pins", content.reads)
	}
}
