package events

import (
	"testing"
	"time"
)

func TestGlobalGroupPhaseAndJoinable(t *testing.T) {
	at := time.Date(2026, 11, 23, 12, 0, 0, 0, time.UTC)
	start, end := at.Add(-time.Hour), at.Add(time.Hour)
	group := GlobalGroup{StartsAt: start, EndsAt: &end}
	if phase := group.Phase(at); phase != PhaseRunning {
		t.Fatalf("running group phase = %s", phase)
	}
	if !group.Joinable(at) {
		t.Fatal("a running group joins new servers")
	}

	future := GlobalGroup{StartsAt: at.Add(time.Hour)}
	if phase := future.Phase(at); phase != PhaseScheduled {
		t.Fatalf("future group phase = %s", phase)
	}
	if !future.Joinable(at) {
		t.Fatal("a scheduled group joins new servers")
	}

	ended := at
	group.EndedAt = &ended
	if phase := group.Phase(at); phase != PhaseEnded {
		t.Fatalf("ended group phase = %s", phase)
	}
	if group.Joinable(at) {
		t.Fatal("an ended group must not join")
	}

	permanent := GlobalGroup{StartsAt: start}
	if phase := permanent.Phase(at); phase != PhaseRunning {
		t.Fatalf("permanent group phase = %s", phase)
	}
	if !permanent.Joinable(at) {
		t.Fatal("a permanent group joins new servers")
	}
}
