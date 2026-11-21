package librarylocal

import (
	"slices"
	"testing"
	"time"
)

// stageCatalog mirrors library_amour.lua: the mission set of the stage whose
// amour upper bound contains the favor value.
func stageCatalog() Catalog {
	return Catalog{Stages: []StageRule{
		{ID: 1, Favor: 100, ActIDs: []int64{1}, MissionIDs: []int64{1001, 1002, 1003}},
		{ID: 2, Favor: 300, ActIDs: []int64{1, 2}, MissionIDs: []int64{1001, 1002, 1003, 1005}},
		{ID: 3, Favor: 800, ActIDs: []int64{1, 2, 3}, MissionIDs: []int64{1001, 1002, 1003, 1004, 1005}},
		{ID: 4, Favor: 2000, ActIDs: []int64{1, 2, 3, 4}, MissionIDs: []int64{1001, 1002, 1003, 1004, 1005, 1006}},
		{ID: 5, Favor: 2001, ActIDs: []int64{1, 2, 3, 4}, MissionIDs: []int64{1001, 1002, 1003, 1004, 1005, 1006}},
	}}
}

// A-203 S30: UnlockedMissions reads the stage containing the favor, not every
// stage below it, and shares ActUnlocked's stage lookup.
func TestUnlockedMissionsUsesContainingStage(t *testing.T) {
	catalog := stageCatalog()
	for _, tc := range []struct {
		favor int64
		want  []int64
	}{
		{0, []int64{1001, 1002, 1003}},
		{100, []int64{1001, 1002, 1003}},
		{101, []int64{1001, 1002, 1003, 1005}},
		{300, []int64{1001, 1002, 1003, 1005}},
		{301, []int64{1001, 1002, 1003, 1004, 1005}},
		{801, []int64{1001, 1002, 1003, 1004, 1005, 1006}},
		{2001, []int64{1001, 1002, 1003, 1004, 1005, 1006}},
		{99999, []int64{1001, 1002, 1003, 1004, 1005, 1006}},
	} {
		got := catalog.UnlockedMissions(tc.favor)
		if !slices.Equal(got, tc.want) {
			t.Fatalf("favor %d missions %v want %v", tc.favor, got, tc.want)
		}
	}
	if !catalog.ActUnlocked(1, 0) || catalog.ActUnlocked(2, 0) {
		t.Fatal("favor 0 must open only act 1")
	}
	if !catalog.ActUnlocked(2, 101) || catalog.ActUnlocked(3, 101) {
		t.Fatal("favor 101 must open act 2 only")
	}
	if !catalog.ActUnlocked(4, 2001) {
		t.Fatal("above the last bound must use the last stage")
	}
}

func TestMissionAwardIsTerminalOnce(t *testing.T) {
	at := time.Date(2026, 11, 19, 12, 0, 0, 0, time.UTC)
	proceed := MissionFact{PlayerID: 1, PartnerID: 1, MissionID: GiftMissionID, MissionState: MissionProceed, UpdatedAt: at}
	if _, changed, err := proceed.Award(at); err != nil || changed {
		t.Fatalf("proceed award changed=%v err=%v", changed, err)
	}
	success, changed, err := proceed.Advance(1, at)
	if err != nil || !changed || success.MissionState != MissionSuccess {
		t.Fatalf("advance changed=%v state=%d err=%v", changed, success.MissionState, err)
	}
	awarded, changed, err := success.Award(at)
	if err != nil || !changed || awarded.MissionState != MissionAwarded {
		t.Fatalf("success award changed=%v state=%d err=%v", changed, awarded.MissionState, err)
	}
	again, changed, err := awarded.Award(at)
	if err != nil || changed || again.MissionState != MissionAwarded {
		t.Fatalf("replay changed=%v state=%d err=%v", changed, again.MissionState, err)
	}
}
