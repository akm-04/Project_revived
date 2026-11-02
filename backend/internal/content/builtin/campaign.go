package builtin

import (
	"encoding/json"
	"errors"
)

// CampaignCatalog is the deployment profile of campaign_catalog.json; the
// campaign domain owns the full typed rules decoded from the stored payload.
type CampaignCatalog struct {
	SchemaVersion   int               `json:"schema_version"`
	ContractID      string            `json:"contract_id"`
	PolicyID        string            `json:"policy_id"`
	TrialGroups     []json.RawMessage `json:"trial_groups"`
	HeroFactions    map[string]int64  `json:"hero_factions"`
	DailyConsumes   []json.RawMessage `json:"daily_consumes"`
	ChapterGifts    []json.RawMessage `json:"chapter_gifts"`
	Chapters        []json.RawMessage `json:"chapters"`
	Nodes           []json.RawMessage `json:"nodes"`
	DropBoxes       []json.RawMessage `json:"drop_boxes"`
	StarBonus       []json.RawMessage `json:"star_bonus"`
	EliteResetCosts []int64           `json:"elite_reset_costs"`
	VIP             []json.RawMessage `json:"vip"`
}

func (c CampaignCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != "I9_CAMPAIGN_V1" || c.PolicyID != "I9_CAMPAIGN_PRIVATE_POLICY_V1" || len(c.Chapters) != 23 || len(c.Nodes) != 857 || len(c.DropBoxes) != 1233 || len(c.StarBonus) != 46 || len(c.EliteResetCosts) != 330 || len(c.TrialGroups) != 14 || len(c.HeroFactions) != 569 || len(c.DailyConsumes) != 10 || len(c.VIP) != 16 || len(c.ChapterGifts) != 12 {
		return errors.New("campaign catalog profile")
	}
	return nil
}
