package librarylocal

import "testing"

func talkReward(value int64) *int64 { return &value }

func talkGraph(relationship int64, groups map[int64]map[int64]DialogNode) Catalog {
	nodes := map[DialogGroupKey]map[int64]DialogNode{}
	for group, rows := range groups {
		nodes[DialogGroupKey{RelationshipSourceID: relationship, DialogGroup: group}] = rows
	}
	return Catalog{DialogNodes: nodes}
}

func TestTalkChoiceRequiresReachableMatchingOption(t *testing.T) {
	catalog := talkGraph(10001006, map[int64]map[int64]DialogNode{
		2: {
			201001: {NodeID: 201001, TurnIDs: []int64{201002}},
			201002: {NodeID: 201002, TurnIDs: []int64{201004}},
			201004: {NodeID: 201004, TurnIDs: []int64{202001, 203001, 202004, 202005}},
			202001: {NodeID: 202001, IsReward: talkReward(3), TurnIDs: []int64{-1}},
			203001: {NodeID: 203001, IsReward: talkReward(2), TurnIDs: []int64{-1}},
			202004: {NodeID: 202004, IsReward: talkReward(0), TurnIDs: []int64{-1}},
		},
	})
	for _, tc := range []struct {
		name   string
		option int64
		raw    int64
		grant  bool
		fail   bool
	}{
		{"raw3", 202001, 3, true, false},
		{"raw2", 203001, 2, true, false},
		{"raw0", 202004, 0, false, false},
		{"mismatched flag", 202001, 2, false, true},
		{"zero on positive", 202001, 0, false, true},
		{"non-outgoing", 999999, 3, false, true},
		{"choice node itself", 201004, 3, false, true},
		{"missing target node", 202005, 1, false, true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			grant, err := catalog.TalkChoice(10001006, 2, tc.option, tc.raw)
			if tc.fail && err == nil {
				t.Fatalf("accepted option %d raw %d", tc.option, tc.raw)
			}
			if !tc.fail && err != nil {
				t.Fatalf("option %d raw %d: %v", tc.option, tc.raw, err)
			}
			if !tc.fail && grant != tc.grant {
				t.Fatalf("option %d raw %d grant=%v want %v", tc.option, tc.raw, grant, tc.grant)
			}
		})
	}
}

func TestTalkEndFollowsCrossGroupRetainedChoice(t *testing.T) {
	catalog := talkGraph(10001013, map[int64]map[int64]DialogNode{
		2: {
			201001: {NodeID: 201001, TurnIDs: []int64{201004}},
			201004: {NodeID: 201004, TurnIDs: []int64{202001, 203001}},
			203001: {NodeID: 203001, IsReward: talkReward(0), TurnIDs: []int64{203002}},
			203002: {NodeID: 203002, IsReward: talkReward(0), TurnIDs: []int64{-1}},
		},
		3: {
			202001: {NodeID: 202001, IsReward: talkReward(1), TurnIDs: []int64{202002}},
			202002: {NodeID: 202002, IsReward: talkReward(1), TurnIDs: []int64{-1}},
		},
	})
	for _, tc := range []struct {
		name     string
		selectID int64
		grant    bool
		fail     bool
	}{
		{"cross-group positive", 202001, true, false},
		{"retained zero", 203001, false, false},
		{"missing retained choice", 0, false, false},
		{"saved choice not on branch", 999999, false, true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			grant, err := catalog.TalkEnd(10001013, 2, tc.selectID)
			if tc.fail && err == nil {
				t.Fatalf("accepted select %d", tc.selectID)
			}
			if !tc.fail && err != nil {
				t.Fatalf("select %d: %v", tc.selectID, err)
			}
			if !tc.fail && grant != tc.grant {
				t.Fatalf("select %d grant=%v want %v", tc.selectID, grant, tc.grant)
			}
		})
	}
}

func TestTalkEndUsesOnlyTheReachedTerminal(t *testing.T) {
	catalog := talkGraph(10001001, map[int64]map[int64]DialogNode{
		2: {
			201001: {NodeID: 201001, IsReward: talkReward(0), TurnIDs: []int64{201002}},
			201002: {NodeID: 201002, IsReward: talkReward(0), TurnIDs: []int64{-1}},
			900001: {NodeID: 900001, IsReward: talkReward(1), TurnIDs: []int64{-1}},
		},
	})
	if grant, err := catalog.TalkEnd(10001001, 2, 0); err != nil || grant {
		t.Fatalf("disconnected positive terminal granted=%v err=%v", grant, err)
	}
	if grant, err := catalog.TalkEnd(10001001, 2, 400000); err != nil || grant {
		t.Fatalf("stale saved choice affected a choice-free path grant=%v err=%v", grant, err)
	}
	positive := talkGraph(10001001, map[int64]map[int64]DialogNode{
		2: {201001: {NodeID: 201001, IsReward: talkReward(1), TurnIDs: []int64{-1}}},
	})
	if grant, err := positive.TalkEnd(10001001, 2, 0); err != nil || !grant {
		t.Fatalf("positive entry terminal grant=%v err=%v", grant, err)
	}
	missingReward := talkGraph(10001001, map[int64]map[int64]DialogNode{
		2: {201001: {NodeID: 201001, TurnIDs: []int64{-1}}},
	})
	if _, err := missingReward.TalkEnd(10001001, 2, 0); err == nil {
		t.Fatal("accepted terminal without source reward")
	}
}

func TestTalkEndRejectsBrokenPaths(t *testing.T) {
	for name, catalog := range map[string]Catalog{
		"missing edge": talkGraph(1, map[int64]map[int64]DialogNode{
			2: {100: {NodeID: 100, TurnIDs: []int64{999}}},
		}),
		"cycle": talkGraph(1, map[int64]map[int64]DialogNode{
			2: {100: {NodeID: 100, TurnIDs: []int64{101}}, 101: {NodeID: 101, TurnIDs: []int64{100}}},
		}),
		"self loop": talkGraph(1, map[int64]map[int64]DialogNode{
			2: {100: {NodeID: 100, TurnIDs: []int64{100}}},
		}),
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := catalog.TalkEnd(1, 2, 0); err == nil {
				t.Fatal("accepted broken path")
			}
		})
	}
}

func TestTalkEndRejectsNestedRetainedChoice(t *testing.T) {
	catalog := talkGraph(5, map[int64]map[int64]DialogNode{
		2: {
			100: {NodeID: 100, TurnIDs: []int64{200, 300}},
			200: {NodeID: 200, TurnIDs: []int64{201, 202}},
			201: {NodeID: 201, IsReward: talkReward(1), TurnIDs: []int64{-1}},
			202: {NodeID: 202, IsReward: talkReward(1), TurnIDs: []int64{-1}},
			300: {NodeID: 300, IsReward: talkReward(0), TurnIDs: []int64{-1}},
		},
	})
	if _, err := catalog.TalkEnd(5, 2, 200); err == nil {
		t.Fatal("accepted nested retained choice")
	}
}

func TestTalkGraphRequiresEntryAndUniqueGlobalIds(t *testing.T) {
	if _, err := (Catalog{}).TalkEnd(1, 2, 0); err == nil {
		t.Fatal("accepted missing relationship graph")
	}
	duplicate := talkGraph(1, map[int64]map[int64]DialogNode{
		2: {100: {NodeID: 100, IsReward: talkReward(1), TurnIDs: []int64{-1}}},
		3: {100: {NodeID: 100, IsReward: talkReward(1), TurnIDs: []int64{-1}}},
	})
	if _, err := duplicate.TalkEnd(1, 2, 0); err == nil {
		t.Fatal("accepted duplicate node id across groups")
	}
}
