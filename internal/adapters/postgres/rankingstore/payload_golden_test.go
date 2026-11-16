package rankingstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenRankingStore(t *testing.T) {
	rootDirectory := filepath.Join("testdata", "payloads", "ranking_girls_roots.payload")
	rootRaw, err := os.ReadFile(filepath.Join(rootDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var root d.BoardRoot
	if err := payload.Decode("ranking_girls_roots", 0, rootRaw, &root); err != nil {
		t.Fatalf("ranking_girls_roots v0: %v", err)
	}
	assertGolden(t, "ranking_girls_roots", rootDirectory, root)

	snapshotDirectory := filepath.Join("testdata", "payloads", "ranking_girls_snapshots.payload")
	snapshotRaw, err := os.ReadFile(filepath.Join(snapshotDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var snapshot d.BoardSnapshot
	if err := payload.Decode("ranking_girls_snapshots", 0, snapshotRaw, &snapshot); err != nil {
		t.Fatalf("ranking_girls_snapshots v0: %v", err)
	}
	assertGolden(t, "ranking_girls_snapshots", snapshotDirectory, snapshot)
}

func assertGolden(t *testing.T, table, directory string, value any) {
	t.Helper()
	got, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("%s v0 decoded value:\n%s\nwant:\n%s", table, got, want)
	}
}
