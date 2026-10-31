package occult

// Reward is one granted line. Source rates in item_num are probabilities, not
// counts, so a clear grants each displayed item once without a roll.
type Reward struct {
	ItemID   int64 `json:"item_id"`
	Quantity int64 `json:"quantity"`
}

func (c Catalog) ClearRewards(chapterID int64) ([]Reward, error) {
	chapter, ok := c.Chapter(chapterID)
	if !ok {
		return nil, ErrInvalid
	}
	rewards := make([]Reward, 0, len(chapter.ItemDisplay))
	for _, itemID := range chapter.ItemDisplay {
		rewards = append(rewards, Reward{ItemID: itemID, Quantity: 1})
	}
	return rewards, nil
}

// SweepRewards is the clear reward scaled to SweepPercent, floored, never
// below one.
func (c Catalog) SweepRewards(chapterID int64) ([]Reward, error) {
	rewards, err := c.ClearRewards(chapterID)
	if err != nil {
		return nil, err
	}
	for index := range rewards {
		rewards[index].Quantity = max(rewards[index].Quantity*c.SweepPercent/100, 1)
	}
	return rewards, nil
}

// FragmentReward is the single awakening fragment of an active route.
func (c Catalog) FragmentReward(missionID, chapterID int64) (Reward, bool) {
	route, ok := c.RouteFor(missionID, chapterID)
	if !ok {
		return Reward{}, false
	}
	return Reward{ItemID: route.FragmentItem, Quantity: 1}, true
}
