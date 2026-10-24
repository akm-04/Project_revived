package character

import (
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestCollectionAdmissionCatalogAndRetainedOrigins(t *testing.T) {
	at := time.Unix(1780000000, 123).UTC()
	rev := strings.Repeat("a", 64)
	catalog, owned := []int64{3, 1, 2}, []int64{9000, 1}
	first, e := AdmitCollectionOrigin(1, 7, rev, at, catalog, owned, 2)
	if e != nil || first.Validate() != nil || first.CatalogCount != 3 || first.OwnedCount != 2 || first.RetainedLegacyCount != 1 || first.UnionLimit != 4 || first.ResultCount != 3 {
		t.Fatal(first, e)
	}
	ordered, e := AdmitCollectionOrigin(1, 7, rev, at, []int64{1, 2, 3}, []int64{1, 9000}, 2)
	if e != nil || !reflect.DeepEqual(first, ordered) || !reflect.DeepEqual(catalog, []int64{3, 1, 2}) || !reflect.DeepEqual(owned, []int64{9000, 1}) {
		t.Fatal("order-dependent provenance or caller mutation", first, ordered, e)
	}
	// A historical guessed 80-slot ceiling must not become this private policy.
	largeCatalog, largeOwned := []int64{}, []int64{}
	for id := int64(1); id <= 300; id++ {
		largeCatalog = append(largeCatalog, id)
		if id < 300 {
			largeOwned = append(largeOwned, id)
		}
	}
	last, e := AdmitCollectionOrigin(1, 9, rev, at, largeCatalog, largeOwned, 300)
	if e != nil || last.ResultCount != 300 || last.UnionLimit != 300 {
		t.Fatal("fabricated purchased-slot limit", last, e)
	}
}

func TestCollectionAdmissionRejectsUnqualifiedPopulation(t *testing.T) {
	at := time.Unix(1780000000, 0).UTC()
	for _, tc := range []struct {
		name           string
		catalog, owned []int64
		candidate      int64
	}{
		{"missing catalog", nil, nil, 1},
		{"duplicate catalog", []int64{1, 1}, nil, 1},
		{"invalid catalog id", []int64{0, 1}, nil, 1},
		{"unknown candidate", []int64{1, 2}, nil, 3},
		{"already owned", []int64{1, 2}, []int64{1}, 1},
		{"duplicate owned", []int64{1, 2}, []int64{9, 9}, 1},
		{"invalid owned", []int64{1, 2}, []int64{-1}, 1},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if _, e := AdmitCollectionOrigin(1, 1, strings.Repeat("a", 64), at, tc.catalog, tc.owned, tc.candidate); e == nil {
				t.Fatal("unqualified source admitted")
			}
		})
	}
	proof, e := AdmitCollectionOrigin(1, 1, strings.Repeat("a", 64), at, []int64{1}, nil, 1)
	if e != nil {
		t.Fatal(e)
	}
	proof.UnionLimit++
	if proof.Validate() == nil {
		t.Fatal("inconsistent budget witness accepted")
	}
}
