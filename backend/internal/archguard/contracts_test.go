package archguard

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

type bootContracts struct {
	Embedded []int `json:"embedded_mid1_records"`
	Critical []struct {
		MID      int `json:"mid"`
		Required any `json:"required"`
	} `json:"critical_source_consumed_shapes"`
}

func TestWaveSContractFixtureIntegrity(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "testdata", "contracts", "wave_s_boot_shape_contracts.pass409.json"))
	if err != nil {
		t.Fatal(err)
	}
	var c bootContracts
	if err := json.Unmarshal(b, &c); err != nil {
		t.Fatal(err)
	}
	if len(c.Embedded) != 33 {
		t.Fatalf("embedded MID1 contract count=%d want=33", len(c.Embedded))
	}
	need := map[int]bool{56: false, 1056: false, 176: false, 192: false, 2784: false, 32771: false, 32779: false, 32797: false}
	for _, x := range c.Critical {
		if _, ok := need[x.MID]; ok {
			need[x.MID] = true
		}
	}
	for mid, ok := range need {
		if !ok {
			t.Errorf("critical Wave-S MID %d missing", mid)
		}
	}
}
