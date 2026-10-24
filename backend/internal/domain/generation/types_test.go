package generation

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/foundation/ids"
)

func testUUID(last byte) ids.UUID {
	var u ids.UUID
	u[15] = last
	return u
}

func TestGenerationAndOccurrenceIdentityRemainDistinct(t *testing.T) {
	g, err := GenerationIDFrom(testUUID(1))
	if err != nil {
		t.Fatal(err)
	}
	o, err := OccurrenceIDFrom(testUUID(1))
	if err != nil {
		t.Fatal(err)
	}
	if g.UUID() != o.UUID() {
		t.Fatal("fixture should share underlying UUID bytes")
	}
	// Their exported types are intentionally different, so assignment/aliasing
	// requires an explicit conversion through the underlying UUID.
	if !g.Valid() || !o.Valid() {
		t.Fatal("valid typed identities rejected")
	}
}

func TestReferenceHierarchyValidation(t *testing.T) {
	g, _ := GenerationIDFrom(testUUID(1))
	o, _ := OccurrenceIDFrom(testUUID(2))
	scope, err := NewAuthorityScope("logical_server", "7")
	if err != nil {
		t.Fatal(err)
	}
	gr, err := NewGenerationRef("activity", scope, g)
	if err != nil {
		t.Fatal(err)
	}
	or, err := NewOccurrenceRef(gr, o)
	if err != nil {
		t.Fatal(err)
	}
	tr, err := NewTransitionRef(gr, "settle", "epoch:4")
	if err != nil {
		t.Fatal(err)
	}
	if or.Generation() != gr || tr.Generation() != gr || tr.Kind() != "settle" || tr.Target() != "epoch:4" {
		t.Fatalf("reference projection mismatch: %#v %#v", or, tr)
	}
}

func TestReferencesFailClosed(t *testing.T) {
	if _, err := GenerationIDFrom(ids.UUID{}); !errors.Is(err, ErrInvalidReference) {
		t.Fatalf("zero generation: %v", err)
	}
	if _, err := OccurrenceIDFrom(ids.UUID{}); !errors.Is(err, ErrInvalidReference) {
		t.Fatalf("zero occurrence: %v", err)
	}
	for _, tc := range [][2]string{{"", "1"}, {"server", ""}, {" ", "1"}, {"server", " "}} {
		if _, err := NewAuthorityScope(tc[0], tc[1]); !errors.Is(err, ErrInvalidReference) {
			t.Fatalf("scope %#v: %v", tc, err)
		}
	}
	g, _ := GenerationIDFrom(testUUID(1))
	scope, _ := NewAuthorityScope("server", "1")
	if _, err := NewGenerationRef(" ", scope, g); !errors.Is(err, ErrInvalidReference) {
		t.Fatalf("blank domain: %v", err)
	}
	gr, _ := NewGenerationRef("domain", scope, g)
	if _, err := NewOccurrenceRef(gr, OccurrenceID{}); !errors.Is(err, ErrInvalidReference) {
		t.Fatalf("zero occurrence ref: %v", err)
	}
	if _, err := NewTransitionRef(gr, "", "target"); !errors.Is(err, ErrInvalidReference) {
		t.Fatalf("blank transition kind: %v", err)
	}
	if _, err := NewTransitionRef(gr, "settle", " "); !errors.Is(err, ErrInvalidReference) {
		t.Fatalf("blank transition target: %v", err)
	}
}

func FuzzAuthorityScopeRejectsMissingComponent(f *testing.F) {
	f.Add("server", "1")
	f.Add("", "x")
	f.Fuzz(func(t *testing.T, kind, key string) {
		s, err := NewAuthorityScope(kind, key)
		if err == nil && !s.Valid() {
			t.Fatalf("constructor returned invalid success for %q/%q", kind, key)
		}
	})
}
