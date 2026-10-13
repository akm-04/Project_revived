package character

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
)

const HeroRawSkillSeedPolicyID = "I7C2A_V1_RAW_SKILL_SEED_V1"

// HeroRawSkillFacts are canonical owner facts. Zero ChoiceIDs mean no override;
// content, color and awakening determine effective IDs and unlocks separately.
type HeroRawSkillFacts struct {
	Levels       [6]int64 `json:"levels"`
	ChoiceIDs    [6]int64 `json:"choice_ids"`
	SeedPolicyID string   `json:"seed_policy_id"`
}

func NewHeroRawSkillSeed() HeroRawSkillFacts {
	return HeroRawSkillFacts{Levels: [6]int64{1, 1, 1, 1, 1, 1}, SeedPolicyID: HeroRawSkillSeedPolicyID}
}
func (s HeroRawSkillFacts) Validate() error {
	if s.SeedPolicyID != HeroRawSkillSeedPolicyID {
		return errors.New("character hero: missing or unknown raw skill policy")
	}
	for i := range s.Levels {
		if s.Levels[i] < 0 || s.ChoiceIDs[i] < 0 {
			return errors.New("character hero: invalid raw skill fact")
		}
	}
	return nil
}

func (s *HeroRawSkillFacts) UnmarshalJSON(raw []byte) error {
	var v struct {
		Levels       []int64 `json:"levels"`
		ChoiceIDs    []int64 `json:"choice_ids"`
		SeedPolicyID string  `json:"seed_policy_id"`
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if e := d.Decode(&v); e != nil {
		return e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return errors.New("Hero raw skill extra JSON")
	}
	if len(v.Levels) != 6 || len(v.ChoiceIDs) != 6 {
		return errors.New("Hero raw skill JSON requires six slots")
	}
	copy(s.Levels[:], v.Levels)
	copy(s.ChoiceIDs[:], v.ChoiceIDs)
	s.SeedPolicyID = v.SeedPolicyID
	return s.Validate()
}
