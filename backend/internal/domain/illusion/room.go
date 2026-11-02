package illusion

import (
	"encoding/json"
	"slices"
	"strconv"
)

// TeamPick is one member's chosen partner ids and master pet, in client wire
// form. Force is the summed public force the team window displays.
type TeamPick struct {
	Heroes []int64 `json:"heroes,omitempty"`
	PetID  int64   `json:"pet_id,omitempty"`
	Force  int64   `json:"force,omitempty"`
}

// RoomState is the Illusion family payload of one shared room: the boss bound
// when the room opened, each member's pick, and the terminal team report.
type RoomState struct {
	ParadiseID    int64                      `json:"paradise_id"`
	MasterLevel   int64                      `json:"master_level"`
	Picks         map[string]TeamPick        `json:"picks,omitempty"`
	AttemptID     string                     `json:"attempt_id,omitempty"`
	ReportID      string                     `json:"report_id,omitempty"`
	TeamInfo      json.RawMessage            `json:"team_info,omitempty"`
	DamageResults map[string]json.RawMessage `json:"damage_results,omitempty"`
	Invites       []int64                    `json:"invites,omitempty"`
}

func (s RoomState) Encode() (json.RawMessage, error) {
	raw, err := json.Marshal(s)
	return raw, err
}

func LoadRoomState(raw json.RawMessage) (RoomState, error) {
	var state RoomState
	err := json.Unmarshal(raw, &state)
	return state, err
}

func (s RoomState) Pick(playerID int64) TeamPick {
	return s.Picks[strconv.FormatInt(playerID, 10)]
}

func (s *RoomState) SetPick(playerID int64, pick TeamPick) {
	if s.Picks == nil {
		s.Picks = map[string]TeamPick{}
	}
	s.Picks[strconv.FormatInt(playerID, 10)] = pick
}

func (s RoomState) Invited(playerID int64) bool {
	return slices.Contains(s.Invites, playerID)
}
