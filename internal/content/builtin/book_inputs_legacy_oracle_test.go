package builtin

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"testing"
)

func TestGeneratedBookLegacyRowsMatchHistoricalPayload(t *testing.T) {
	raw, err := os.ReadFile("testdata/book_input_catalog_i9_9c.json")
	if err != nil {
		t.Fatal(err)
	}
	if fmt.Sprintf("%x", sha256.Sum256(raw)) != "987852793701b17759e41d620a50dab08b50a23ba4efe89db7ff5a07a4f11861" {
		t.Fatal("historical payload bytes changed")
	}
	var historical BookInputCatalog
	if err = json.Unmarshal(raw, &historical); err != nil {
		t.Fatal(err)
	}
	if err = historical.Validate(); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(legacyBookInputCatalog(t), historical) {
		t.Fatal("generated legacy rows diverged from the independently retained old payload")
	}
}
