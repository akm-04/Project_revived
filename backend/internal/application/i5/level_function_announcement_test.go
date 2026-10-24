package i5

import (
	"context"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/player"
)

func TestLevelFunctionAnnouncementsAndBirthOpenings(t *testing.T) {
	policy := FunctionGatePolicy{Revision: "rev", Gates: []FunctionGate{
		{FunctionID: 1, GateKind: "PURE_LEVEL", RequiredLevel: 1, RawOpenValue: "1|1", SourceFactKey: "function:1", AnnouncementCapability: "NONE"},
		{FunctionID: 7, GateKind: "PURE_LEVEL", RequiredLevel: 25, RawOpenValue: "1|25", SourceFactKey: "function:7", AnnouncementCapability: "NONE"},
		{FunctionID: 38, GateKind: "PURE_LEVEL", RequiredLevel: 40, RawOpenValue: "1|40", SourceFactKey: "function:38", AnnouncementCapability: "PET_STARTER_CA3"},
		{FunctionID: 71, GateKind: "UNSUPPORTED_COMPOSITE", RawOpenValue: "2|100018", SourceFactKey: "function:71", AnnouncementCapability: "NONE"},
	}}
	now := time.Unix(100, 0).UTC()
	eligible, err := pureLevelEligibility(policy, 125001, 40, now)
	if err != nil {
		t.Fatal(err)
	}
	announced, err := LevelFunctionAnnouncements{}.Announce(context.Background(), 125001, policy, eligible)
	if err != nil || !reflect.DeepEqual(announced, []int64{1, 7, 38}) {
		t.Fatalf("level 40 announcements %v %v", announced, err)
	}
	born, unlocks, err := LevelFunctionOpenings(policy, 125001, 1, now)
	if err != nil || len(born) != 1 || !reflect.DeepEqual(unlocks, []player.FunctionUnlock{{PlayerID: 125001, FunctionID: 1, OpenedAt: now, SourceFactKey: born[0].SourceFactKey, StateVersion: 1}}) {
		t.Fatalf("birth openings %+v %+v %v", born, unlocks, err)
	}
	reached, unlocks, err := LevelFunctionOpenings(policy, 125001, 40, now)
	if err != nil || len(reached) != 2 || len(unlocks) != 2 || unlocks[0].FunctionID != 1 || unlocks[1].FunctionID != 7 {
		t.Fatalf("level 40 openings must leave the granting Pet Function 38 to its level-up: %+v %+v %v", reached, unlocks, err)
	}
}
