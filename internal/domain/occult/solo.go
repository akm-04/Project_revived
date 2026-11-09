package occult

import "slices"

// SoloReport is what the client posts after a solo fight; the server cannot
// verify it and only clamps it.
type SoloReport struct {
	Star   int64
	Score  int64
	Heroes map[int64]HeroStatus
}

type SoloResult struct {
	Won   bool
	Star  int64
	Score int64
}

func clamp(value, low, high int64) int64 {
	return max(min(value, high), low)
}

// ApplySolo clamps a reported result, writes hero_status as the next stage's
// absolute HP authority and, on a win, empties the stage. A loss stores the
// monster HP the client reported. The player must hold the stage. HP can only
// fall across stages; MP is carried up as well as down, so its ceiling is the
// energy maximum, not the prior value.
func (s *RunState) ApplySolo(playerID, campaignID int64, index int, report SoloReport, heroLimits map[int64]int64, monsterRemaining int64, monsterReported bool) (SoloResult, error) {
	stage, err := s.stage(campaignID, index)
	if err != nil {
		return SoloResult{}, err
	}
	if stage.InBattle != playerID {
		return SoloResult{}, ErrRefused
	}
	heroIDs := make([]int64, 0, len(report.Heroes))
	for heroID := range report.Heroes {
		heroIDs = append(heroIDs, heroID)
	}
	slices.Sort(heroIDs)
	for _, heroID := range heroIDs {
		limit, known := heroLimits[heroID]
		if !known || limit <= 0 {
			return SoloResult{}, ErrInvalid
		}
		reported := report.Heroes[heroID]
		hpCeiling := limit
		if prior, recorded := s.Status(playerID, heroID); recorded {
			hpCeiling = min(prior.HP, limit)
		}
		mpCeiling := int64(MaxEnergy)
		clamped := HeroStatus{HP: clamp(reported.HP, 0, hpCeiling), MP: clamp(reported.MP, 0, mpCeiling), LimitHP: limit}
		if err := s.setStatus(playerID, heroID, clamped); err != nil {
			return SoloResult{}, err
		}
	}
	result := SoloResult{Star: max(min(report.Star, MaxStar), 0), Score: max(report.Score, 0)}
	result.Won = result.Star > 0
	if result.Won {
		stage.HP = 0
	}
	if !result.Won && monsterReported && monsterRemaining > 0 {
		stage.HP = min(stage.HP, clamp(monsterRemaining, 1, stage.TotalHP))
	}
	stage.InBattle = 0
	return result, nil
}
