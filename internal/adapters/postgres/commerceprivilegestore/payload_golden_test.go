package commerceprivilegestore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenCommercePrivilegeStore(t *testing.T) {
	directory := filepath.Join("testdata", "payloads", "commerce_recharge_tuning.payload")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var tuning d.ChargeTuning
	if err := payload.Decode("commerce_recharge_tuning", 0, raw, &tuning); err != nil {
		t.Fatalf("commerce_recharge_tuning v0: %v", err)
	}
	got, err := json.MarshalIndent(tuning, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("commerce_recharge_tuning v0 decoded value:\n%s\nwant:\n%s", got, want)
	}
}
