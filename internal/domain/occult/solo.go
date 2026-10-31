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

func clampPercent(reported, authority int64) int64 {
	return max(min(reported, authority), 0)
}

// ApplySolo clamps a reported result, writes hero_status as the next stage's
// HP authority and, on a win, empties the stage. The player must hold the stage.
func (s *RunState) ApplySolo(playerID, campaignID int64, index int, report SoloReport) (SoloResult, error) {
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
		authority := s.Status(playerID, heroID)
		reported := report.Heroes[heroID]
		clamped := HeroStatus{HP: clampPercent(reported.HP, authority.HP), MP: clampPercent(reported.MP, authority.MP)}
		if err := s.setStatus(playerID, heroID, clamped); err != nil {
			return SoloResult{}, err
		}
	}
	result := SoloResult{Star: max(min(report.Star, MaxStar), 0), Score: max(report.Score, 0)}
	result.Won = result.Star > 0
	if result.Won {
		stage.HP = 0
	}
	stage.InBattle = 0
	return result, nil
}
