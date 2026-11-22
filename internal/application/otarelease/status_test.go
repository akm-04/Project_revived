package otarelease

import (
	"fmt"
	"testing"
)

func statusVersion(index int) string { return fmt.Sprintf("1.640.%d", index+1) }

func overBoundSnapshot() StatusSnapshot {
	active := make([]ActiveRow, 0, StatusActiveLimit+1)
	for index := 0; index <= StatusActiveLimit; index++ {
		active = append(active, ActiveRow{Version: statusVersion(index), Lane: "catalog"})
	}
	built := make([]BuiltRelease, 0, StatusBuiltLimit+1)
	for index := 0; index <= StatusBuiltLimit; index++ {
		built = append(built, BuiltRelease{Version: statusVersion(index), Lane: "code"})
	}
	activations := make([]ActivationStatus, 0, StatusActivationLimit+1)
	for index := 0; index <= StatusActivationLimit; index++ {
		activations = append(activations, ActivationStatus{ID: int64(index + 1), Version: statusVersion(index)})
	}
	served := make([]ServedCounter, 0, StatusServedLimit+1)
	for index := 0; index <= StatusServedLimit; index++ {
		served = append(served, ServedCounter{Path: fmt.Sprintf("src_64/app/%d.lua", index)})
	}
	misses := make([]AssetMiss, 0, StatusMissesLimit+1)
	for index := 0; index <= StatusMissesLimit; index++ {
		misses = append(misses, AssetMiss{Path: fmt.Sprintf("src_64/missing/%d.lua", index)})
	}
	return StatusSnapshot{Active: active, Built: built, Activations: activations, Served: served, Misses: misses}
}

func TestFoldStatusTruncatesEveryListToItsBound(t *testing.T) {
	status, err := foldStatus(overBoundSnapshot())
	if err != nil {
		t.Fatal(err)
	}
	if !status.Truncated.Active || !status.Truncated.Built || !status.Truncated.Activations || !status.Truncated.Served || !status.Truncated.Misses {
		t.Fatalf("truncated=%+v", status.Truncated)
	}
	if len(status.Active.Catalog) != StatusActiveLimit || len(status.Built) != StatusBuiltLimit || len(status.Activations) != StatusActivationLimit || len(status.Served) != StatusServedLimit || len(status.Misses) != StatusMissesLimit {
		t.Fatalf("lengths active=%d built=%d activations=%d served=%d misses=%d", len(status.Active.Catalog), len(status.Built), len(status.Activations), len(status.Served), len(status.Misses))
	}
}

func TestFoldStatusReportsNoTruncationAtTheBound(t *testing.T) {
	snapshot := overBoundSnapshot()
	snapshot.Active = snapshot.Active[:StatusActiveLimit]
	snapshot.Built = snapshot.Built[:StatusBuiltLimit]
	snapshot.Activations = snapshot.Activations[:StatusActivationLimit]
	snapshot.Served = snapshot.Served[:StatusServedLimit]
	snapshot.Misses = snapshot.Misses[:StatusMissesLimit]
	status, err := foldStatus(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	if status.Truncated != (TruncatedLists{}) {
		t.Fatalf("truncated=%+v", status.Truncated)
	}
}
