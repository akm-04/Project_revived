package receipt

import "testing"

func TestFingerprintPreservesTypesAndMapOrder(t *testing.T) {
	vals := []any{true, int64(1), uint64(1), float64(1), "1", []byte("1")}
	seen := map[[32]byte]bool{}
	for _, v := range vals {
		h, err := FingerprintRequest(v)
		if err != nil {
			t.Fatal(err)
		}
		if seen[h] {
			t.Fatalf("type collapsed: %#v", v)
		}
		seen[h] = true
	}
	a, _ := FingerprintRequest(map[string]any{"b": int64(2), "a": true})
	b, _ := FingerprintRequest(map[string]any{"a": true, "b": int64(2)})
	if a != b {
		t.Fatal("map order changed fingerprint")
	}
}
