package characterpet

import (
	"errors"

	"gxb.local/backend/v2/internal/domain/character"
)

type ProgressionTemplate struct {
	TableID     int64
	StoneItemID int64
}

func (p ProgressionTemplate) Validate() error {
	if p.TableID <= 0 || p.StoneItemID <= 0 {
		return errors.New("character pet: invalid progression template")
	}
	return nil
}

type SkillSlotDefinition struct {
	Slot          int64 `json:"slot"`
	SourceSkillID int64 `json:"source_skill_id"`
	StarBonus     int64 `json:"star_bonus"`
}

func (s SkillSlotDefinition) Validate() error {
	if s.Slot < 1 || s.Slot > 5 || s.SourceSkillID < 0 || (s.StarBonus != 0 && s.StarBonus != 10) {
		return errors.New("character pet: invalid source skill slot")
	}
	return nil
}

type ExpThreshold struct {
	Level    int64 `json:"level"`
	TotalExp int64 `json:"total_exp"`
}

func ValidateExpThresholds(rows []ExpThreshold, maxLevel int64) error {
	if maxLevel < 1 || maxLevel > 100 || int64(len(rows)) != maxLevel {
		return errors.New("character pet: incomplete EXP policy")
	}
	var prev int64 = -1
	for i, row := range rows {
		if row.Level != int64(i+1) || row.TotalExp < 0 || row.TotalExp < prev {
			return errors.New("character pet: invalid EXP policy")
		}
		prev = row.TotalExp
	}
	return nil
}

type SkillSlotPolicy struct {
	EffectiveOffset  int64
	MinColor         int64
	RequiresAwakened bool
}

func (p SkillSlotPolicy) Validate(slot int64) error {
	if slot < 1 || slot > 5 || p.EffectiveOffset < 0 || p.MinColor < 0 {
		return errors.New("character pet: invalid skill-slot policy")
	}
	if p.RequiresAwakened != (slot == 5) {
		return errors.New("character pet: invalid awakened slot policy")
	}
	return nil
}

type ProgressionPolicy struct {
	SkillBookItemID int64
}

func (p ProgressionPolicy) Validate() error {
	if p.SkillBookItemID <= 0 {
		return errors.New("character pet: invalid progression policy")
	}
	return nil
}

func RawSkillAt(p character.Pet, slot int64) (int64, error) {
	if slot < 1 || slot > 5 {
		return 0, errors.New("character pet: invalid skill slot")
	}
	return p.Skills[slot-1], nil
}
