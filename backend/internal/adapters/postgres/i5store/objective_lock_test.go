package i5store

import (
	"strings"
	"testing"
)

func TestObjectiveStockClaimLocksBaseMissionRowsInsideCandidateCTE(t *testing.T) {
	q := lockObjectiveForClaimQuery
	candidateEnd := strings.Index(q, "), unique_candidate AS")
	if candidateEnd < 0 {
		t.Fatal("candidate CTE boundary missing")
	}
	candidate := q[:candidateEnd]
	if !strings.Contains(candidate, "WITH candidate AS MATERIALIZED") {
		t.Fatalf("candidate must be materialized: %s", q)
	}
	if !strings.Contains(candidate, "FROM player_mission_instances i") {
		t.Fatalf("candidate does not read mission owner row: %s", q)
	}
	if !strings.Contains(candidate, "FOR UPDATE OF i") {
		t.Fatalf("mission owner row is not locked inside candidate CTE: %s", q)
	}
	tail := q[candidateEnd:]
	if strings.Contains(tail, "FOR UPDATE") {
		t.Fatalf("outer/derived query must not pretend to lock the base row: %s", q)
	}
	if !strings.Contains(tail, "(SELECT count(*) FROM candidate)=1") {
		t.Fatalf("ambiguous candidate fail-closed rule lost: %s", q)
	}
}
