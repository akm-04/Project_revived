package contentstore

import "testing"

func TestEmptyObjectiveRewardRequiresExactMissionPolicyBinding(t *testing.T) {
	for _, tc := range []struct {
		raw         string
		mission, ok bool
	}{
		{`{"Source":{"PolicyVersion":"I9_MISSIONS_V1"},"Lines":[]}`, true, true},
		{`{"Source":{"PolicyVersion":"I9_MISSIONS_V1"},"Lines":[]}`, false, false},
		{`{"Source":{"PolicyVersion":"another"},"Lines":[]}`, true, false},
		{`{"Source":{"PolicyVersion":"I9_MISSIONS_V1"},"Lines":[{"Kind":"STACK_ITEM","ItemID":1,"Amount":-1}]}`, true, false},
	} {
		if _, err := decodeContentGrantPlan([]byte(tc.raw), tc.mission); (err == nil) != tc.ok {
			t.Errorf("mission=%v raw=%s: %v", tc.mission, tc.raw, err)
		}
	}
}
