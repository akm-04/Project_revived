package arena

import "testing"

func TestDeclarationLengthPreservesClientByteSemantics(t *testing.T) {
	for _, check := range []struct {
		value     string
		halfUnits int
	}{{"", 0}, {"Annie", 5}, {"女孩", 4}, {"é", 1}, {"😀", 3}, {"𐀀", 3}, {"\U00040000", 1}} {
		if actual := sourceDeclarationLength(check.value); actual != check.halfUnits {
			t.Fatalf("%q: %d want%d", check.value, actual, check.halfUnits)
		}
	}
}
