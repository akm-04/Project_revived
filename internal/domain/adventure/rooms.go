package adventure

import (
	"encoding/json"
	"slices"
	"strconv"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/sharedroom"
)

const (
	// RoomTypeDefense and RoomTypeIllusion are the stock notice 32 room_type
	// values of the two Adventure rooms.
	RoomTypeDefense  int64 = 2
	RoomTypeIllusion int64 = 3

	DefenseMaxStar        = 3
	DefenseDamageCap      = 5000000
	IllusionCoopSeats     = 3
	IllusionHeroes        = 2
	IllusionLevelBand     = 5
	IllusionBaseGift      = 90030022
	IllusionReportKeyKind = "ADVENTURE_ILLUSION_TEAM_RESULT"
)

// RoomPick is one member's frozen hero/pet selection in a co-op room.
type RoomPick struct {
	Heroes []int64 `json:"heroes,omitempty"`
	PetID  int64   `json:"pet_id,omitempty"`
	Force  int64   `json:"force,omitempty"`
}

// BusyState is one defense monster position's current occupant.
type BusyState struct {
	Player int64 `json:"player,omitempty"`
	Type   int64 `json:"busy_type"`
}

// MonsterState is one defense monster position's kill state.
type MonsterState struct {
	Killer       string            `json:"killer,omitempty"`
	KillerPlayer identity.PlayerID `json:"killer_player,omitempty"`
	Solved       bool              `json:"solved,omitempty"`
}

// DefenseCompleted reports whether every monster position has been solved.
func (s RoomState) DefenseCompleted() bool {
	solved := 0
	for _, monster := range s.Monsters {
		if monster.Solved {
			solved++
		}
	}
	return solved >= DefenseMonsterCount
}

// DefenseRecipients is the distinct players who solved a position, ascending by
// player id. A position solved before KillerPlayer was recorded has no
// recipient, so a room carried over from that time mails nobody for it.
func (s RoomState) DefenseRecipients() []identity.PlayerID {
	unique := make(map[identity.PlayerID]struct{}, len(s.Monsters))
	recipients := make([]identity.PlayerID, 0, len(s.Monsters))
	for _, monster := range s.Monsters {
		if !monster.Solved || monster.KillerPlayer == 0 {
			continue
		}
		if _, duplicate := unique[monster.KillerPlayer]; duplicate {
			continue
		}
		unique[monster.KillerPlayer] = struct{}{}
		recipients = append(recipients, monster.KillerPlayer)
	}
	slices.Sort(recipients)
	return recipients
}

// PushRecord is one room state change the realtime projection delivers once.
type PushRecord struct {
	Sequence int64          `json:"sequence"`
	Function int64          `json:"function"`
	Body     map[string]any `json:"body"`
	All      bool           `json:"all,omitempty"`
	Actor    int64          `json:"actor,omitempty"`
}

// RoomState is the opaque sharedroom payload of both Adventure rooms.
type RoomState struct {
	sharedroom.ChatRing
	RoomType    int64                      `json:"room_type"`
	SpecialData int64                      `json:"special_data"`
	CampaignID  int64                      `json:"campaign_id,omitempty"`
	MasterLevel int64                      `json:"master_level"`
	Phase       string                     `json:"phase"`
	Picks       map[string]RoomPick        `json:"picks,omitempty"`
	Invites     []int64                    `json:"invites,omitempty"`
	Attempts    map[string]string          `json:"attempts,omitempty"`
	Tries       map[string][]int64         `json:"tries,omitempty"`
	Busy        []BusyState                `json:"busy,omitempty"`
	Monsters    []MonsterState             `json:"monsters,omitempty"`
	Pushes      []PushRecord               `json:"pushes,omitempty"`
	AttemptID   string                     `json:"attempt_id,omitempty"`
	ReportID    string                     `json:"report_id,omitempty"`
	Damage      int64                      `json:"damage,omitempty"`
	TeamInfo    json.RawMessage            `json:"team_info,omitempty"`
	Reports     map[string]json.RawMessage `json:"reports,omitempty"`
	// Forces is each seat's best-15 AP frozen when the player entered the room.
	Forces map[string]int64 `json:"forces,omitempty"`
}

func (s RoomState) Encode() (json.RawMessage, error) { return json.Marshal(s) }

func LoadRoomState(raw json.RawMessage) (RoomState, error) {
	var state RoomState
	err := json.Unmarshal(raw, &state)
	if state.Picks == nil {
		state.Picks = map[string]RoomPick{}
	}
	if state.Attempts == nil {
		state.Attempts = map[string]string{}
	}
	if state.Tries == nil {
		state.Tries = map[string][]int64{}
	}
	if state.Reports == nil {
		state.Reports = map[string]json.RawMessage{}
	}
	if len(state.Busy) == 0 {
		state.Busy = make([]BusyState, DefenseMonsterCount)
	}
	if len(state.Monsters) == 0 {
		state.Monsters = make([]MonsterState, DefenseMonsterCount)
	}
	return state, err
}

func (s RoomState) Pick(playerID int64) RoomPick { return s.Picks[strconv.FormatInt(playerID, 10)] }

func (s RoomState) Force(playerID int64) int64 { return s.Forces[strconv.FormatInt(playerID, 10)] }

func (s *RoomState) SetForce(playerID, force int64) {
	if s.Forces == nil {
		s.Forces = map[string]int64{}
	}
	s.Forces[strconv.FormatInt(playerID, 10)] = force
}

func (s *RoomState) SetPick(playerID int64, pick RoomPick) {
	if s.Picks == nil {
		s.Picks = map[string]RoomPick{}
	}
	s.Picks[strconv.FormatInt(playerID, 10)] = pick
}

func (s RoomState) Invited(playerID int64) bool {
	for _, invitee := range s.Invites {
		if invitee == playerID {
			return true
		}
	}
	return false
}

func (s *RoomState) AddPush(function, actor int64, all bool, body map[string]any) {
	s.Pushes = append(s.Pushes, PushRecord{Sequence: int64(len(s.Pushes) + 1), Function: function, Actor: actor, All: all, Body: body})
}

func (s RoomState) TriesOf(playerID int64) []int64 {
	tries, found := s.Tries[strconv.FormatInt(playerID, 10)]
	if !found {
		return make([]int64, DefenseMonsterCount)
	}
	out := make([]int64, DefenseMonsterCount)
	copy(out, tries)
	return out
}

func (s *RoomState) SetTries(playerID int64, tries []int64) {
	if s.Tries == nil {
		s.Tries = map[string][]int64{}
	}
	s.Tries[strconv.FormatInt(playerID, 10)] = append([]int64(nil), tries...)
}
