package builtin

import (
	"encoding/json"
	"errors"
)

// TopFloorCatalog is the deployment profile of top_floor_catalog.json; the
// Top Floor domain owns the full typed rules decoded from the stored payload.
type TopFloorTaskCatalog struct {
	SchemaVersion int               `json:"schema_version"`
	ContractID    string            `json:"contract_id"`
	PolicyID      string            `json:"policy_id"`
	Rules         []json.RawMessage `json:"rules"`
	Schedule      []json.RawMessage `json:"schedule"`
	Rewards       []json.RawMessage `json:"rewards"`
	HeroCamps     map[string]int64  `json:"hero_camps"`
	MailTitle     string            `json:"mail_title"`
	MailText      string            `json:"mail_text"`
	MailSender    string            `json:"mail_sender"`
}
type TopFloorCatalog struct {
	TaskModes     TopFloorTaskCatalog `json:"task_modes"`
	SchemaVersion int                 `json:"schema_version"`
	ContractID    string              `json:"contract_id"`
	PolicyID      string              `json:"policy_id"`
	Rewards       []json.RawMessage   `json:"rewards"`
	Robots        []json.RawMessage   `json:"robots"`
	RobotHeroes   []json.RawMessage   `json:"robot_heroes"`
}

func (c TopFloorCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != "C5B_TOP_FLOOR_MODE_V1" || c.PolicyID != "C5B_TOP_FLOOR_PRIVATE_POLICY_V1" || len(c.Rewards) != 30 || len(c.Robots) != 10325 || len(c.RobotHeroes) != 2805 {
		return errors.New("top floor catalog profile")
	}
	task := c.TaskModes
	if task.SchemaVersion != 1 || task.ContractID != "I9_TOP_FLOOR_TASK_MODE_V1" || task.PolicyID != "I9_TOP_FLOOR_TASK_POLICY_V1" || len(task.Rules) != 6 || len(task.Schedule) != 91 || len(task.Rewards) != 17 || len(task.HeroCamps) != 569 || task.MailTitle == "" || task.MailText == "" || task.MailSender == "" {
		return errors.New("top floor task catalog profile")
	}
	return nil
}
