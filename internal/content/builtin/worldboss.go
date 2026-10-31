package builtin

import (
	"encoding/json"
	"errors"
)

type WorldBossCatalog struct {
	Schema      int               `json:"schema_version"`
	Contract    string            `json:"contract_id"`
	PolicyID    string            `json:"policy_id"`
	Policy      int               `json:"policy_version"`
	ActivityID  int64             `json:"activity_id"`
	OpenLevel   int64             `json:"open_level"`
	Attempts    int64             `json:"attempts"`
	WindowStart int64             `json:"window_start_seconds"`
	WindowStop  int64             `json:"window_stop_seconds"`
	Bosses      []json.RawMessage `json:"bosses"`
	RankRewards []json.RawMessage `json:"rank_rewards"`
	Mail        json.RawMessage   `json:"mail"`
	Texts       json.RawMessage   `json:"texts"`
}

func (c WorldBossCatalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_WORLD_BOSS_V1" || c.PolicyID != "I9_WORLD_BOSS_POLICY_V1" || c.Policy != 1 || c.ActivityID != 1026 || c.OpenLevel != 48 || c.Attempts != 5 || c.WindowStart != 0 || c.WindowStop != 79080 || len(c.Bosses) != 5 || len(c.RankRewards) != 25 || len(c.Mail) == 0 || len(c.Texts) == 0 {
		return errors.New("world boss catalog")
	}
	return nil
}
