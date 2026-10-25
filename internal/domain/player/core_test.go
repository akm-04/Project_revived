package player

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
	"time"
)

func TestCompatibilityBootstrapMatchesFrozenI4PlayerCoreDefaults(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	c := CompatibilityBootstrap(identity.PlayerID(100001), now)
	if err := c.Validate(); err != nil {
		t.Fatal(err)
	}
	m, err := c.MID17OwnedFields()
	if err != nil {
		t.Fatal(err)
	}
	for k, want := range map[string]any{"player_name": "", "player_type": int64(0), "avatar_id": int64(110001001), "avatar_frame_id": int64(0), "lev": int64(1), "exp": int64(0), "story_id": int64(0), "story_state": int64(0), "guide_id": int64(0), "guide_return_id": int64(0)} {
		if got := m[k]; got != want {
			t.Fatalf("%s=%#v want %#v", k, got, want)
		}
	}
	if got := m["func_ids"].([]int64); len(got) != 0 {
		t.Fatalf("func_ids=%v", got)
	}
}

func TestSaveStoryGuideEndIsPresentationMarkerOnly(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	cur := CompatibilityBootstrap(identity.PlayerID(100001), now).Story
	next, done, err := SaveStory(cur, 3, 2, GuideEndID, now.Add(time.Second))
	if err != nil {
		t.Fatal(err)
	}
	if !done || next.GuideID != GuideEndID || next.StateVersion != 2 {
		t.Fatalf("next=%+v done=%v", next, done)
	}
	again, done, err := SaveStory(next, 3, 2, GuideEndID, now.Add(2*time.Second))
	if err != nil {
		t.Fatal(err)
	}
	if !done || again.StateVersion != 2 {
		t.Fatalf("replay mutated version: %+v", again)
	}
}

func TestGuideFunctionsProjectAsStringKeyedCompletionMap(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	core := CompatibilityBootstrap(identity.PlayerID(100001), now)
	guide, err := CompleteGuideFunction(core.GuideReturn, 18, now.Add(time.Second))
	if err != nil {
		t.Fatal(err)
	}
	guide, err = CompleteGuideFunction(guide, 17, now.Add(2*time.Second))
	if err != nil {
		t.Fatal(err)
	}
	again, err := CompleteGuideFunction(guide, 17, now.Add(3*time.Second))
	if err != nil || again.StateVersion != guide.StateVersion || guide.StateVersion != 3 {
		t.Fatalf("guide=%+v again=%+v err=%v", guide, again, err)
	}
	if len(guide.GuideFunctionIDs) != 2 || guide.GuideFunctionIDs[0] != 17 || len(core.GuideReturn.GuideFunctionIDs) != 0 {
		t.Fatalf("ids=%v original=%v", guide.GuideFunctionIDs, core.GuideReturn.GuideFunctionIDs)
	}
	core.GuideReturn = guide
	fields, err := core.MID17OwnedFields()
	if err != nil {
		t.Fatal(err)
	}
	if got := fields["guide_function_ids"].(map[string]int64); len(got) != 2 || got["17"] != 1 || got["18"] != 1 {
		t.Fatalf("guide_function_ids=%#v", got)
	}
	if _, err := CompleteGuideFunction(guide, 0, now); err == nil {
		t.Fatal("zero guide function id accepted")
	}
	back, err := SetGuideReturn(guide, 10900202, now.Add(4*time.Second))
	if err != nil || back.GuideReturnID != 10900202 || back.StateVersion != 4 {
		t.Fatalf("return=%+v err=%v", back, err)
	}
	if _, err := SetGuideReturn(back, -1, now); err == nil {
		t.Fatal("negative guide return id accepted")
	}
}
