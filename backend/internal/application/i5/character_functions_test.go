package i5

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
	"time"
)

func TestCharacterFunctionPredicatesKeepUnsupportedKindsClosed(t *testing.T) {
	policy := FunctionGatePolicy{Revision: "revision", Gates: []FunctionGate{{FunctionID: 16, RawOpenValue: "6|55|15"}, {FunctionID: 37, RawOpenValue: "6|60|5"}, {FunctionID: 45, RawOpenValue: "7|100"}, {FunctionID: 99, RawOpenValue: "6|1|1"}, {FunctionID: 17, RawOpenValue: "4|1"}}}
	at := time.Date(2026, 10, 29, 1, 0, 0, 0, time.UTC)
	for _, check := range []struct {
		level, count int64
		emblem       bool
		expected     int
	}{{54, 15, false, 0}, {55, 14, false, 0}, {55, 15, false, 1}, {60, 4, false, 0}, {60, 5, false, 1}, {60, 15, false, 2}, {1, 1, true, 1}, {100, 1, false, 0}, {60, 15, true, 3}} {
		observed := CharacterFunctionObservation{Player: identity.PlayerID(100001), OwnedGirls: check.count, EmblemReady: check.emblem}
		actual := characterFunctionEligibility(policy, observed, check.level, at)
		if len(actual) != check.expected {
			t.Fatalf("%+v -> %+v", check, actual)
		}
	}
	policy.Gates[0].RawOpenValue = "6|55|14"
	if got := characterFunctionEligibility(policy, CharacterFunctionObservation{OwnedGirls: 15}, 55, at); len(got) != 0 {
		t.Fatal("unqualified source gate", got)
	}
}
