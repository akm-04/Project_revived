package illusion

import (
	"encoding/json"
	"slices"
	"strconv"
)

const (
	// StagePrepare is IllusionWindow's PREPARE: the master has not yet opened
	// the pick. StageSelectHero is SELECT_HERO, entered by 1351.
	StagePrepare    int64 = 0
	StageSelectHero int64 = 1
	// ChatHistoryLimit bounds the chat ring kept in the room payload for the
	// realtime pusher; older lines are already delivered or lost.
	ChatHistoryLimit = 24
)

// TeamPick is one member's chosen partner ids and master pet, in client wire
// form. Force is the summed public force the team window displays.
type TeamPick struct {
	Heroes []int64 `json:"heroes,omitempty"`
	PetID  int64   `json:"pet_id,omitempty"`
	Force  int64   `json:"force,omitempty"`
}

// ChatMessage is one delivered room-chat line. Message is the canonical
// CHAT_TO_FRIEND body, including selectType so the recipient's window accepts it.
type ChatMessage struct {
	Serial     int64   `json:"serial"`
	Sender     int64   `json:"sender"`
	Recipients []int64 `json:"recipients"`
	Message    string  `json:"message"`
	At         int64   `json:"at"`
}

// RoomState is the Illusion family payload of one shared room: the boss bound
// when the room opened, each member's pick, and the terminal team report.
type RoomState struct {
	ParadiseID    int64                      `json:"paradise_id"`
	MasterLevel   int64                      `json:"master_level"`
	Stage         int64                      `json:"stage,omitempty"`
	Picks         map[string]TeamPick        `json:"picks,omitempty"`
	ChatSerial    int64                      `json:"chat_serial,omitempty"`
	Chats         []ChatMessage              `json:"chats,omitempty"`
	AttemptID     string                     `json:"attempt_id,omitempty"`
	ReportID      string                     `json:"report_id,omitempty"`
	TeamInfo      json.RawMessage            `json:"team_info,omitempty"`
	DamageResults map[string]json.RawMessage `json:"damage_results,omitempty"`
	Invites       []int64                    `json:"invites,omitempty"`
	// Forces is each seat's best-15 AP frozen when the player entered the room.
	Forces map[string]int64 `json:"forces,omitempty"`
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

func (s RoomState) Force(playerID int64) int64 {
	return s.Forces[strconv.FormatInt(playerID, 10)]
}

func (s *RoomState) SetForce(playerID, force int64) {
	if s.Forces == nil {
		s.Forces = map[string]int64{}
	}
	s.Forces[strconv.FormatInt(playerID, 10)] = force
}

func (s RoomState) Invited(playerID int64) bool {
	return slices.Contains(s.Invites, playerID)
}

// Status is the wire stage: selection is open only after the master pressed
// 1351 and while all three seats are filled.
func (s RoomState) Status(seated int) int64 {
	if s.Stage == StageSelectHero && seated == TeamSeats {
		return StageSelectHero
	}
	return StagePrepare
}

// AddChat appends one line to the bounded room chat ring.
func (s *RoomState) AddChat(message ChatMessage) {
	s.ChatSerial++
	message.Serial = s.ChatSerial
	s.Chats = append(s.Chats, message)
	if len(s.Chats) > ChatHistoryLimit {
		s.Chats = s.Chats[len(s.Chats)-ChatHistoryLimit:]
	}
}
