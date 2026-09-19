package policy

import (
	"errors"
	"testing"
)

func TestDurableJSONCanonicalRoundTrip(t *testing.T) {
	s, err := NewSet(Ref{Name: "zeta", Version: "v2"}, Ref{Name: "content", Version: "r1"})
	if err != nil {
		t.Fatal(err)
	}
	b, err := MarshalCanonicalJSON(s)
	if err != nil {
		t.Fatal(err)
	}
	if got, want := string(b), `[{"name":"content","version":"r1"},{"name":"zeta","version":"v2"}]`; got != want {
		t.Fatalf("json=%s want=%s", got, want)
	}
	got, err := ParseCanonicalJSON(b)
	if err != nil {
		t.Fatal(err)
	}
	if !got.Equal(s) {
		t.Fatalf("round trip mismatch: %#v %#v", got.Refs(), s.Refs())
	}
}

func TestDurableJSONZeroSetIsArray(t *testing.T) {
	b, err := MarshalCanonicalJSON(Set{})
	if err != nil {
		t.Fatal(err)
	}
	if string(b) != `[]` {
		t.Fatalf("zero set encoded %s", b)
	}
	got, err := ParseCanonicalJSON([]byte(`[]`))
	if err != nil || len(got.Refs()) != 0 {
		t.Fatalf("got=%#v err=%v", got.Refs(), err)
	}
}

func TestDurableJSONRejectsNoncanonicalEvidence(t *testing.T) {
	bad := []string{
		`null`,
		`[{"name":"","version":"r1"}]`,
		`[{"name":"content","version":" "}]`,
		`[{"name":"z","version":"1"},{"name":"a","version":"2"}]`,
		`[{"name":"a","version":"1"},{"name":"a","version":"2"}]`,
		`[{"name":"a","version":"1","extra":true}]`,
		`[{"name":"a","version":"1"}] {}`,
	}
	for _, raw := range bad {
		t.Run(raw, func(t *testing.T) {
			_, err := ParseCanonicalJSON([]byte(raw))
			if !errors.Is(err, ErrInvalidReference) {
				t.Fatalf("expected invalid reference for %s, got %v", raw, err)
			}
		})
	}
}

func TestNewSetRejectsWhitespaceOnlyReference(t *testing.T) {
	if _, err := NewSet(Ref{Name: " ", Version: "v1"}); !errors.Is(err, ErrInvalidReference) {
		t.Fatalf("got %v", err)
	}
}
