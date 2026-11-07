package librarylocal

import (
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/foundation/receipt"
)

func TestTalkCommandPreservesLegacyRewardIdentity(t *testing.T) {
	for _, rewarded := range []bool{false, true} {
		command := Command{Family: TalkAward, PartnerID: 1, Value: 2, SelectID: 203001, IsReward: rewarded, HasSelect: true}
		legacy := struct {
			Family    string
			PartnerID int64
			Value     int64
			SelectID  int64 `json:",omitempty"`
			IsReward  bool  `json:",omitempty"`
			HasSelect bool  `json:",omitempty"`
		}{command.Family, command.PartnerID, command.Value, command.SelectID, command.IsReward, command.HasSelect}
		encoded, err := json.Marshal(command)
		if err != nil {
			t.Fatal(err)
		}
		previous, err := json.Marshal(legacy)
		if err != nil {
			t.Fatal(err)
		}
		if string(encoded) != string(previous) {
			t.Fatalf("legacy command changed: %s != %s", encoded, previous)
		}
		expected, err := receipt.FingerprintRequest(map[string]any{"family": TalkAward, "partner_id": int64(1), "value": int64(2), "policy": LifecyclePolicy, "select_id": int64(203001), "is_reward": rewarded, "has_select": true})
		if err != nil {
			t.Fatal(err)
		}
		actual, err := fingerprint(command)
		if err != nil || actual != expected {
			t.Fatalf("legacy fingerprint changed: %x != %x: %v", actual, expected, err)
		}
	}
}

func TestTalkRawRewardSelectsSourceDiscriminator(t *testing.T) {
	for _, tc := range []struct {
		name    string
		command Command
		want    int64
	}{
		{"zero", Command{IsReward: false}, 0},
		{"legacy one", Command{IsReward: true}, 1},
		{"raw two", Command{IsReward: true, RawReward: 2}, 2},
		{"raw three", Command{IsReward: true, RawReward: 3}, 3},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := talkRawReward(tc.command); got != tc.want {
				t.Fatalf("talkRawReward(%+v)=%d want %d", tc.command, got, tc.want)
			}
		})
	}
}

func TestTalkCommandRawRewardIsBoundToProof(t *testing.T) {
	command := Command{Family: TalkAward, PartnerID: 1, Value: 2, SelectID: 203001, IsReward: true, HasSelect: true}
	previous, err := fingerprint(command)
	if err != nil {
		t.Fatal(err)
	}
	seen := map[[32]byte]bool{previous: true}
	for _, rawReward := range []int64{2, 3} {
		command.RawReward = rawReward
		if err := command.Validate(); err != nil {
			t.Fatal(err)
		}
		actual, err := fingerprint(command)
		if err != nil {
			t.Fatal(err)
		}
		if seen[actual] {
			t.Fatalf("raw reward %d aliases another command", rawReward)
		}
		seen[actual] = true
		encoded, err := json.Marshal(command)
		if err != nil {
			t.Fatal(err)
		}
		var restored Command
		if err := json.Unmarshal(encoded, &restored); err != nil || restored != command {
			t.Fatalf("command lost discriminator: %s %v", encoded, err)
		}
	}
	for _, invalid := range []Command{
		{Family: TalkAward, PartnerID: 1, Value: 2, SelectID: 203001, IsReward: true, HasSelect: true, RawReward: 1},
		{Family: TalkAward, PartnerID: 1, Value: 2, SelectID: 203001, HasSelect: true, RawReward: 2},
		{Family: TalkAward, PartnerID: 1, Value: 2, RawReward: 2},
		{Family: Save, PartnerID: 1, RawReward: 2},
	} {
		if invalid.Validate() == nil {
			t.Fatalf("accepted inconsistent raw reward: %+v", invalid)
		}
	}
}
