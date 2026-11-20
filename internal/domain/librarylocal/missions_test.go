package librarylocal

import (
	"testing"
	"time"
)

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
