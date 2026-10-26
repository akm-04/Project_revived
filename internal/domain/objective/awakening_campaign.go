package objective

import "slices"

type AwakeFrozenDrop struct {
	Occurrence AwakeInstance `json:"occurrence"`
	ItemID     int64         `json:"item_id"`
	Rate       int64         `json:"rate"`
	Count      int64         `json:"count"`
}
type AwakeCampaignContext struct {
	Player    int64             `json:"player"`
	Campaign  int64             `json:"campaign"`
	Type      int64             `json:"type"`
	Formation []int64           `json:"formation"`
	Pet       int64             `json:"pet"`
	Final     *AwakeInstance    `json:"final,omitempty"`
	Drops     []AwakeFrozenDrop `json:"drops"`
}

func (c AwakeCampaignContext) Validate() error {
	if c.Player <= 0 || c.Campaign <= 0 || c.Type < 1 || c.Type > 2 || c.Pet < 0 || len(c.Formation) > 6 || len(c.Drops) > 2 {
		return ErrAwakeningRefused
	}
	seen := map[int64]bool{}
	for _, id := range c.Formation {
		if id < 0 || id > 0 && seen[id] {
			return ErrAwakeningRefused
		}
		if id > 0 {
			seen[id] = true
		}
	}
	if c.Final != nil && (c.Final.Validate() != nil || c.Final.Type != 1 || !slices.Contains(c.Formation, c.Final.OwnerID)) {
		return ErrAwakeningRefused
	}
	for _, d := range c.Drops {
		if d.Occurrence.Validate() != nil || d.Occurrence.Type == 3 || d.ItemID <= 0 || d.Rate < 0 || d.Rate > 10000 || d.Count < 0 || d.Count > 1 {
			return ErrAwakeningRefused
		}
	}
	return nil
}
func (c AwakeCampaignContext) Draw(source interface{ Uniform(uint64) uint64 }) AwakeCampaignContext {
	c.Drops = append([]AwakeFrozenDrop{}, c.Drops...)
	for i := range c.Drops {
		c.Drops[i].Count = 0
		if c.Drops[i].Rate > 0 && int64(source.Uniform(10000)) < c.Drops[i].Rate {
			c.Drops[i].Count = 1
		}
	}
	return c
}
