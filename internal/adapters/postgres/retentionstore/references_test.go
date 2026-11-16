package retentionstore

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
)

type generatedReference struct {
	Table  string `json:"table"`
	Column string `json:"column"`
}

type generatedReferences struct {
	AttemptIDs   []generatedReference `json:"attempt_ids"`
	ReceiptIDs   []generatedReference `json:"receipt_ids"`
	OperationIDs []generatedReference `json:"operation_ids"`
}

func TestReferenceTableCoversGeneratedLists(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join("..", "..", "..", "..", "docs/data/RETENTION_REFERENCES.json"))
	if err != nil {
		t.Fatal(err)
	}
	var document generatedReferences
	if err = json.Unmarshal(raw, &document); err != nil {
		t.Fatal(err)
	}
	assertSameReferences(t, "combat-chain", document.AttemptIDs)
	assertSameReferences(t, "receipts", append(append([]generatedReference{}, document.ReceiptIDs...), document.OperationIDs...))
}

func TestReceiptKeptWhileCitesEveryReference(t *testing.T) {
	query := receiptKeptWhileSQL()
	for _, reference := range append(append([]string{}, receiptIdReferences...), operationIdReferences...) {
		if reference == ownReceiptColumn {
			if strings.Contains(query, reference) {
				t.Fatalf("own receipt key %s keeps its own receipt", reference)
			}
			continue
		}
		table, column, _ := strings.Cut(reference, ".")
		if !strings.Contains(query, "FROM "+table+" held WHERE held."+column+"::text") {
			t.Fatalf("receipt rule does not hold %s", reference)
		}
	}
}

func assertSameReferences(t *testing.T, group string, generated []generatedReference) {
	t.Helper()
	want := make([]string, 0, len(generated))
	for _, entry := range generated {
		want = append(want, entry.Table+"."+entry.Column)
	}
	got := append([]string{}, RuleReferenceColumns[group]...)
	sort.Strings(want)
	sort.Strings(got)
	if strings.Join(got, "\n") != strings.Join(want, "\n") {
		t.Fatalf("%s references differ:\n got %v\nwant %v", group, got, want)
	}
}
