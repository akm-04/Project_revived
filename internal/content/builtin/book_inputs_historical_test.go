package builtin

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"testing"
)

// The fixture is the exact i9-9c manifest retained from Git HEAD (sha256
// 6e63476b42df4ced26d5600b1553ff8b12aa25dbcac1e25e23fd15b83eb27b43).
func TestHistoricalLoaderProfile404RemainsAccepted(t *testing.T) {
	raw, err := os.ReadFile("testdata/manifest_i9_9c_404.json")
	if err != nil {
		t.Fatal(err)
	}
	if fmt.Sprintf("%x", sha256.Sum256(raw)) != "6e63476b42df4ced26d5600b1553ff8b12aa25dbcac1e25e23fd15b83eb27b43" {
		t.Fatal("historical manifest bytes changed")
	}
	var manifest Manifest
	if err = json.Unmarshal(raw, &manifest); err != nil {
		t.Fatal(err)
	}
	if manifest.CompilerVersion != "i9-9c-guild-campaign" || len(manifest.Sources) != 404 {
		t.Fatalf("retained fixture drifted: compiler %q sources %d", manifest.CompilerVersion, len(manifest.Sources))
	}
	if err = validateManifest(raw, &manifest); err != nil {
		t.Fatalf("historical loader profile rejected: %v", err)
	}
	manifest.CompilerVersion = "i9-10-event-centre-buildings"
	if err = validateManifest(raw, &manifest); err == nil {
		t.Fatal("new profile accepted a manifest with only 404 source records")
	}
}
