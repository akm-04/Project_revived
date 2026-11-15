package main

import (
	"go/constant"
	"strings"
	"testing"
)

func TestUnboundedSQLStatements(t *testing.T) {
	for _, test := range []struct {
		name, sql string
		want      int
	}{
		{"no where is unbounded", "SELECT id FROM player_heroes", 1},
		{"limit bounds it", "SELECT id FROM player_heroes LIMIT 10", 0},
		{"player key bounds it", "SELECT id FROM player_heroes WHERE player_id=$1", 0},
		{"context key bounds it", "SELECT id FROM gameplay_contexts WHERE context_id=$1", 0},
		{"server key is not an actor key", "SELECT id FROM player_heroes WHERE logical_server_id=$1", 1},
		{"joined literals split", "SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1\nSELECT payload::text FROM content_catalogs WHERE revision_id=$1", 2},
		{"write is not a read", "UPDATE player_heroes SET level=1 WHERE player_id=$1", 0},
	} {
		t.Run(test.name, func(t *testing.T) {
			got := unboundedSQLStatements(test.sql)
			if len(got) != test.want {
				t.Fatalf("unboundedSQLStatements(%q) = %v, want %d", test.sql, got, test.want)
			}
		})
	}
}

func TestIsolationName(t *testing.T) {
	for value, want := range map[int64]string{1: "read_committed", 2: "repeatable_read", 3: "serializable"} {
		got, ok := isolationName(constant.MakeInt64(value))
		if !ok || got != want {
			t.Fatalf("isolationName(%d) = %q,%v want %q", value, got, ok, want)
		}
	}
	if _, ok := isolationName(constant.MakeInt64(9)); ok {
		t.Fatal("unknown isolation number was accepted")
	}
}

func TestWritesClassPrecedence(t *testing.T) {
	unknown := &classBuilder{}
	unknown.noteMarker("FANOUT hidden writer")
	if got := unknown.writes(); got != "UNKNOWN" {
		t.Fatalf("marker-only writes = %q, want UNKNOWN", got)
	}
	none := &classBuilder{}
	if got := none.writes(); got != "none" {
		t.Fatalf("empty writes = %q, want none", got)
	}
	receiptOnly := &classBuilder{}
	receiptOnly.recordReceipt("internal/application/i5/awakening.go:176")
	if got := receiptOnly.writes(); got != "receipt" {
		t.Fatalf("receipt writes = %q, want receipt", got)
	}
	stateAndReceipt := &classBuilder{}
	stateAndReceipt.recordReceipt("internal/application/eventcentre/board.go:313")
	stateAndReceipt.recordStateWrite("internal/application/eventcentre/board.go:313")
	if got := stateAndReceipt.writes(); got != "state" {
		t.Fatalf("state plus receipt writes = %q, want state", got)
	}
}

func TestBuildKeepsSiteEvidence(t *testing.T) {
	builder := &classBuilder{}
	builder.addRun(classTransaction{Function: "Service.Load", Isolation: "repeatable_read", ReadOnly: "true", Retry: "1", File: "internal/application/i5/read.go", Line: 12})
	class := builder.build(161, registration{MID: 161, HandlerFile: "internal/adapters/stockruntime/i5_dispatcher.go", Owner: "i5"})
	if class.MID != 161 || class.System != "i5" || len(class.Transactions) != 1 {
		t.Fatalf("class = %+v", class)
	}
	if class.Isolation[0].Value != "repeatable_read" || class.Isolation[0].File != "internal/application/i5/read.go" || class.Isolation[0].Line != 12 {
		t.Fatalf("isolation evidence = %+v", class.Isolation)
	}
	if !strings.Contains(class.Handler, "i5_dispatcher.go") || class.Writes != "none" {
		t.Fatalf("class fields = %+v", class)
	}
}
