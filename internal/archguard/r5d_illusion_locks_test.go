package archguard

import (
	"encoding/json"
	"os"
	"path/filepath"
	"slices"
	"testing"
)

// R5D keeps illusion on the shared attempt record without adding a lock rank
// or a new lock edge.
func TestR5DIllusionSystemMapLocksUnchanged(t *testing.T) {
	path := filepath.Join(repoRoot(t), "docs", "architecture", "system_map", "systems", "illusion.json")
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var record struct {
		Locks struct {
			RowLocks []string `json:"row_locks"`
		} `json:"locks"`
		Tables struct {
			Read    []string `json:"read"`
			Written []string `json:"written"`
		} `json:"tables"`
	}
	if err = json.Unmarshal(raw, &record); err != nil {
		t.Fatal(err)
	}
	wantLocks := []string{"account_sessions", "accounts", "gameplay_contexts", "illusion_occurrence_results", "illusion_occurrences", "illusion_players", "players"}
	if !slices.Equal(record.Locks.RowLocks, wantLocks) {
		t.Fatalf("illusion lock edges changed: %v", record.Locks.RowLocks)
	}
	for _, tables := range [][]string{record.Tables.Read, record.Tables.Written} {
		if slices.Contains(tables, "illusion_attempts") || !slices.Contains(tables, "illusion_attempt_settlements") {
			t.Fatalf("illusion is not on the shared attempt record: %v", tables)
		}
	}
}
