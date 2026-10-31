package occult

import (
	"encoding/json"
	"strconv"
)

const (
	FullStatus = 100
	MaxStar    = 3
)

// StageState is one sub-stage of a campaign. InBattle holds the player id
// fighting it, 0 when empty. Monster HP lives here, in the room payload.
type StageState struct {
	HP       int64 `json:"hp"`
	TotalHP  int64 `json:"total_hp"`
	InBattle int64 `json:"in_battle"`
}

// HeroStatus is a hero's remaining HP and MP as percent of maximum.
type HeroStatus struct {
	HP int64 `json:"hp"`
	MP int64 `json:"mp"`
}

// RunState is the Occult family payload of one shared room. StartedAt is zero
// until the challenge starts. hero_status is the HP authority for the next
// stage; a result can only lower it.
type RunState struct {
	ChapterID          int64                            `json:"chapter_id"`
	CampaignType       int64                            `json:"campaign_type"`
	StartedAt          int64                            `json:"started_at"`
	SelectionStartedAt int64                            `json:"selection_started_at"`
	FightStartedAt     int64                            `json:"fight_started_at"`
	DispatchLimit      int64                            `json:"dispatch_limit"`
	Stages             map[string][]StageState          `json:"stages,omitempty"`
	HeroStatus         map[string]map[string]HeroStatus `json:"hero_status,omitempty"`
	LeftAt             map[string]int64                 `json:"left_at,omitempty"`
	Invites            []int64                          `json:"invites,omitempty"`
	StayPositions      map[string]int64                 `json:"stay_positions,omitempty"`
	EventsDone         []int64                          `json:"events_done,omitempty"`
	Points             int64                            `json:"points"`
	ClearSettled       bool                             `json:"clear_settled,omitempty"`
	Frozen             map[string]json.RawMessage       `json:"frozen,omitempty"`
	ReportID           string                           `json:"report_id,omitempty"`
	Events             []EventRecord                    `json:"events,omitempty"`
}

func NewRun(chapterID, campaignType int64) RunState {
	return RunState{ChapterID: chapterID, CampaignType: campaignType, DispatchLimit: DispatchLimit}
}

func (s RunState) Encode() (json.RawMessage, error) { return json.Marshal(s) }

func LoadRunState(raw json.RawMessage) (RunState, error) {
	var state RunState
	err := json.Unmarshal(raw, &state)
	return state, err
}

func key(id int64) string { return strconv.FormatInt(id, 10) }

func (s RunState) Started() bool { return s.StartedAt > 0 }

func (s *RunState) Start(at int64) error {
	if s.Started() {
		return ErrRefused
	}
	s.StartedAt = at
	return nil
}

func (s RunState) RoomExpired(at int64) bool {
	return s.Started() && at >= s.StartedAt+RoomSeconds
}

func (s *RunState) BeginSelection(at int64) { s.SelectionStartedAt = at }

func (s RunState) SelectionExpired(at int64) bool {
	return s.SelectionStartedAt > 0 && at >= s.SelectionStartedAt+SelectionSeconds
}

func (s *RunState) BeginFight(at int64) { s.FightStartedAt = at }

func (s RunState) FightExpired(at int64) bool {
	return s.FightStartedAt > 0 && at >= s.FightStartedAt+FightSeconds
}

// MarkLeft records when a player left so re-entry waits ReentrySeconds.
func (s *RunState) MarkLeft(playerID, at int64) {
	if s.LeftAt == nil {
		s.LeftAt = map[string]int64{}
	}
	s.LeftAt[key(playerID)] = at
}

func (s RunState) CanReenter(playerID, at int64) bool {
	leftAt, left := s.LeftAt[key(playerID)]
	return !left || at >= leftAt+ReentrySeconds
}

// BindStages creates the stages of a campaign once; a bound campaign keeps its
// monster HP.
func (s *RunState) BindStages(campaignID int64, totalHP []int64) error {
	if len(totalHP) == 0 {
		return ErrInvalid
	}
	if _, bound := s.Stages[key(campaignID)]; bound {
		return nil
	}
	stages := make([]StageState, len(totalHP))
	for index, total := range totalHP {
		if total <= 0 {
			return ErrInvalid
		}
		stages[index] = StageState{HP: total, TotalHP: total}
	}
	if s.Stages == nil {
		s.Stages = map[string][]StageState{}
	}
	s.Stages[key(campaignID)] = stages
	return nil
}

func (s RunState) stage(campaignID int64, index int) (*StageState, error) {
	stages := s.Stages[key(campaignID)]
	if index < 0 || index >= len(stages) {
		return nil, ErrInvalid
	}
	return &stages[index], nil
}

func (s RunState) fighting(playerID int64) bool {
	for _, stages := range s.Stages {
		for _, stage := range stages {
			if stage.InBattle == playerID {
				return true
			}
		}
	}
	return false
}

// Enter seats a player in an open stage. A player fights one stage at a time.
func (s *RunState) Enter(campaignID int64, index int, playerID int64) error {
	stage, err := s.stage(campaignID, index)
	if err != nil {
		return err
	}
	if stage.HP <= 0 || stage.InBattle != 0 || s.fighting(playerID) {
		return ErrRefused
	}
	stage.InBattle = playerID
	return nil
}

// Release frees every stage a player holds. Abandoning a fight, leaving or
// timing out all end here so the player can start again.
func (s *RunState) Release(playerID int64) {
	for _, stages := range s.Stages {
		for index := range stages {
			if stages[index].InBattle == playerID {
				stages[index].InBattle = 0
			}
		}
	}
}

func (s RunState) Cleared(campaignID int64) bool {
	stages := s.Stages[key(campaignID)]
	for _, stage := range stages {
		if stage.HP > 0 {
			return false
		}
	}
	return len(stages) > 0
}

// Status is the HP authority for one hero; an unrecorded hero is at full.
func (s RunState) Status(playerID, heroID int64) HeroStatus {
	status, recorded := s.HeroStatus[key(playerID)][key(heroID)]
	if !recorded {
		return HeroStatus{HP: FullStatus, MP: FullStatus}
	}
	return status
}

func (s *RunState) setStatus(playerID, heroID int64, status HeroStatus) error {
	heroes := s.HeroStatus[key(playerID)]
	_, recorded := heroes[key(heroID)]
	if !recorded && int64(len(heroes)) >= s.DispatchLimit {
		return ErrRefused
	}
	if s.HeroStatus == nil {
		s.HeroStatus = map[string]map[string]HeroStatus{}
	}
	if heroes == nil {
		heroes = map[string]HeroStatus{}
		s.HeroStatus[key(playerID)] = heroes
	}
	heroes[key(heroID)] = status
	return nil
}
