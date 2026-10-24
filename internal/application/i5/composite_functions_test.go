package i5

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func TestCompositeGateParsing(t *testing.T) {
	if stage, ok := stageClearGate("2|200021"); !ok || stage != 200021 {
		t.Fatalf("kind 2: %d %v", stage, ok)
	}
	if level, vip, ok := levelAndVIPGate("3|30|9"); !ok || level != 30 || vip != 9 {
		t.Fatalf("kind 3: %d %d %v", level, vip, ok)
	}
	for _, raw := range []string{"1|30", "2|", "2|x", "3|30", "3|0|9", "4|1|2", "2|5|6"} {
		_, stageOK := stageClearGate(raw)
		_, _, levelOK := levelAndVIPGate(raw)
		if stageOK || levelOK {
			t.Fatalf("%q parsed as composite", raw)
		}
	}
}

func TestLevelAndVIPEligibility(t *testing.T) {
	policy := FunctionGatePolicy{Revision: "r", Gates: []FunctionGate{
		{FunctionID: 12, GateKind: "UNSUPPORTED_COMPOSITE", RawOpenValue: "3|30|9", SourceFactKey: "f12"},
		{FunctionID: 13, GateKind: "UNSUPPORTED_COMPOSITE", RawOpenValue: "3|40|11", SourceFactKey: "f13"},
		{FunctionID: 14, GateKind: "PURE_LEVEL", RequiredLevel: 30, RawOpenValue: "1|30", SourceFactKey: "f14"},
	}}
	pid := identity.PlayerID(7)
	now := time.Unix(1, 0)
	if reachesLevelAndVIPGate(policy, 29) || !reachesLevelAndVIPGate(policy, 30) {
		t.Fatal("level part of kind 3 misread")
	}
	if got := levelAndVIPEligibility(policy, pid, 45, 8, now); len(got) != 0 {
		t.Fatalf("VIP 8 opened %v", got)
	}
	got := levelAndVIPEligibility(policy, pid, 35, 11, now)
	if len(got) != 1 || got[0].FunctionID != 12 {
		t.Fatalf("level 35 VIP 11 opened %v", got)
	}
}
