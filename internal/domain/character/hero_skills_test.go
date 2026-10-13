package character

import (
	"encoding/json"
	"testing"
)

func TestRawSkillSeedAndStrictShape(t *testing.T) {
	s := NewHeroRawSkillSeed()
	if s.Validate() != nil || s.Levels != [6]int64{1, 1, 1, 1, 1, 1} || s.ChoiceIDs != [6]int64{} {
		t.Fatal(s)
	}
	for _, raw := range []string{`{"levels":[1],"choice_ids":[0,0,0,0,0,0],"seed_policy_id":"I7C2A_V1_RAW_SKILL_SEED_V1"}`, `{"levels":[1,1,1,1,1,1,1],"choice_ids":[0,0,0,0,0,0],"seed_policy_id":"I7C2A_V1_RAW_SKILL_SEED_V1"}`, `{"levels":[1,1,1,1,1,1],"choice_ids":[0,0,0,0,-1,0],"seed_policy_id":"I7C2A_V1_RAW_SKILL_SEED_V1"}`} {
		var got HeroRawSkillFacts
		if json.Unmarshal([]byte(raw), &got) == nil {
			t.Fatal("invalid raw facts", raw)
		}
	}
}
