package archguard

import (
	"encoding/json"
	"os"
	"path/filepath"
	"slices"
	"testing"
)

// R5D keeps adventure single on the shared attempt record without adding a lock
// rank or a new lock edge.
func TestR5DAdventureSystemMapLocksUnchanged(t *testing.T) {
	path := filepath.Join(repoRoot(t), "docs", "architecture", "system_map", "systems", "adventure.json")
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var record struct {
		Locks struct {
			Ranks   []string `json:"ranks"`
			RowLock []string `json:"row_locks"`
		} `json:"locks"`
		Tables struct {
			Read    []string `json:"read"`
			Written []string `json:"written"`
		} `json:"tables"`
	}
	if err = json.Unmarshal(raw, &record); err != nil {
		t.Fatal(err)
	}
	if len(record.Locks.RowLock) != 0 || len(record.Locks.Ranks) != 0 {
		t.Fatalf("adventure lock edges changed: locks=%v ranks=%v", record.Locks.RowLock, record.Locks.Ranks)
	}
	for _, tables := range [][]string{record.Tables.Read, record.Tables.Written} {
		if slices.Contains(tables, "adventure_single_attempts") || !slices.Contains(tables, "adventure_attempt_settlements") {
			t.Fatalf("adventure is not on the shared attempt record: %v", tables)
		}
	}
}
