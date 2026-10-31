package occult

import (
	"encoding/json"
	"slices"
)

const (
	TeamHeroSlots = 2
	noticeLimit   = 32
)

// Room push function numbers follow the client's OccultFunctionType.
const (
	NoticeTeamInvite  int64 = 2
	NoticeTeamAccept  int64 = 3
	NoticeTeamQuit    int64 = 4
	NoticeTeamSelect  int64 = 5
	NoticeTeamPrepare int64 = 6
	NoticeTeamFight   int64 = 7
	NoticeSingleFight int64 = 10
	NoticeFightStatus int64 = 11
)

// TeamPick is one member's formation: hero partner ids by position, 0 empty,
// with the stock roster rows the team window draws, frozen when picked.
type TeamPick struct {
	Heroes []int64           `json:"heroes"`
	Rows   []json.RawMessage `json:"rows"`
	PetID  int64             `json:"pet_id"`
	PetRow json.RawMessage   `json:"pet_row,omitempty"`
}

// TeamFight is the co-op fight of one stage. Timers are the server's: the accept
// and selection windows run SelectionSeconds, the fight FightSeconds. A stored
// ReportKey means the fight settled and is only replayed.
type TeamFight struct {
	CampaignID         int64               `json:"campaign_id"`
	SubID              int64               `json:"sub_id"`
	StartPlayer        int64               `json:"start_player"`
	Round              int64               `json:"round"`
	OpenedAt           int64               `json:"opened_at"`
	SelectionStartedAt int64               `json:"selection_started_at"`
	FightStartedAt     int64               `json:"fight_started_at"`
	Accepted           []int64             `json:"accepted"`
	Prepared           []int64             `json:"prepared,omitempty"`
	Picks              map[string]TeamPick `json:"picks,omitempty"`
	AttemptID          string              `json:"attempt_id,omitempty"`
	ReportKey          string              `json:"report_key,omitempty"`
}

// NoticeRecord is one team push kept for the room's wakeup; Sequence grows by
// one per record so a pusher can tell which it already sent.
type NoticeRecord struct {
	Sequence   int64  `json:"sequence"`
	Function   int64  `json:"function"`
	Actor      int64  `json:"actor"`
	CampaignID int64  `json:"campaign_id"`
	SubID      int64  `json:"sub_id"`
	ReportKey  string `json:"report_key,omitempty"`
}

func (s *RunState) AddNotice(record NoticeRecord) {
	record.Sequence = 1
	if length := len(s.Notices); length > 0 {
		record.Sequence = s.Notices[length-1].Sequence + 1
	}
	s.Notices = append(s.Notices, record)
	if overflow := len(s.Notices) - noticeLimit; overflow > 0 {
		s.Notices = slices.Clone(s.Notices[overflow:])
	}
}

func (t TeamFight) Settled() bool { return t.ReportKey != "" }

func (t TeamFight) Selecting() bool { return t.SelectionStartedAt > 0 }

func (t TeamFight) Fighting() bool { return t.FightStartedAt > 0 }

// Expired applies the window that is running: accept, selection or fight.
func (t TeamFight) Expired(at int64) bool {
	switch {
	case t.Settled():
		return false
	case t.Fighting():
		return at >= t.FightStartedAt+FightSeconds
	case t.Selecting():
		return at >= t.SelectionStartedAt+SelectionSeconds
	}
	return at >= t.OpenedAt+SelectionSeconds
}

func (t TeamFight) Pick(playerID int64) TeamPick {
	pick, picked := t.Picks[key(playerID)]
	if !picked {
		return TeamPick{Heroes: make([]int64, TeamHeroSlots), Rows: make([]json.RawMessage, TeamHeroSlots)}
	}
	return pick
}

func (t TeamFight) IsPrepared(playerID int64) bool { return slices.Contains(t.Prepared, playerID) }

// OpenTeamFight holds the stage for the player who invites. A team fight that is
// settled or ran out its window is replaced; a live one is refused unless it is
// the same stage, which answers again without changing anything; its own
// start player may move on to another stage.
func (s *RunState) OpenTeamFight(campaignID int64, index int, startPlayer, at int64) (bool, error) {
	s.ExpireTeam(at)
	if s.Team != nil && !s.Team.Settled() {
		if s.Team.CampaignID == campaignID && s.Team.SubID == int64(index)+1 && s.Team.StartPlayer == startPlayer {
			return false, nil
		}
		if s.Team.StartPlayer != startPlayer {
			return false, ErrRefused
		}
		s.AbandonTeam()
	}
	s.Release(startPlayer)
	if err := s.Enter(campaignID, index, startPlayer); err != nil {
		return false, err
	}
	s.TeamRounds++
	s.Team = &TeamFight{CampaignID: campaignID, SubID: int64(index) + 1, StartPlayer: startPlayer, Round: s.TeamRounds, OpenedAt: at, Accepted: []int64{startPlayer}}
	return true, nil
}

// ExpireTeam abandons a team fight whose window ran out and frees its stage.
func (s *RunState) ExpireTeam(at int64) bool {
	if s.Team == nil || !s.Team.Expired(at) {
		return false
	}
	s.AbandonTeam()
	return true
}

// AbandonTeam frees the held stage so the room can start again.
func (s *RunState) AbandonTeam() {
	if s.Team == nil {
		return
	}
	if !s.Team.Settled() {
		s.Release(s.Team.StartPlayer)
	}
	s.Team = nil
}

// LiveTeam is the unsettled team fight of a stage, or nil.
func (s *RunState) LiveTeam(campaignID, subID, at int64) *TeamFight {
	s.ExpireTeam(at)
	if s.Team == nil || s.Team.Settled() || s.Team.CampaignID != campaignID || s.Team.SubID != subID {
		return nil
	}
	return s.Team
}

// Accept records an invitee's answer; when every member accepted the selection
// window starts. It reports whether the fight is now complete.
func (t *TeamFight) Accept(playerID int64, memberCount int, at int64) bool {
	if !slices.Contains(t.Accepted, playerID) {
		t.Accepted = append(t.Accepted, playerID)
	}
	if len(t.Accepted) == memberCount && !t.Selecting() {
		t.SelectionStartedAt = at
	}
	return t.Selecting()
}

func (t *TeamFight) SetHero(playerID int64, position int, partnerID int64, row json.RawMessage) {
	pick := t.Pick(playerID)
	pick.Heroes, pick.Rows = slices.Clone(pick.Heroes), slices.Clone(pick.Rows)
	pick.Heroes[position-1], pick.Rows[position-1] = partnerID, row
	t.setPick(playerID, pick)
}

func (t *TeamFight) SetPet(playerID, petID int64, row json.RawMessage) {
	pick := t.Pick(playerID)
	pick.PetID, pick.PetRow = petID, row
	t.setPick(playerID, pick)
}

// setPick drops the member's readiness: a changed formation must be confirmed again.
func (t *TeamFight) setPick(playerID int64, pick TeamPick) {
	if t.Picks == nil {
		t.Picks = map[string]TeamPick{}
	}
	t.Picks[key(playerID)] = pick
	t.Prepared = slices.DeleteFunc(t.Prepared, func(id int64) bool { return id == playerID })
}

// Toggle flips a member's readiness and returns the new state.
func (t *TeamFight) Toggle(playerID int64) bool {
	if t.IsPrepared(playerID) {
		t.Prepared = slices.DeleteFunc(t.Prepared, func(id int64) bool { return id == playerID })
		return false
	}
	t.Prepared = append(t.Prepared, playerID)
	return true
}

func (t TeamFight) AllPrepared(members []int64) bool {
	for _, member := range members {
		if !t.IsPrepared(member) {
			return false
		}
	}
	return len(members) > 0
}

// Fielded lists the member's picked heroes without the empty positions.
func (p TeamPick) Fielded() []int64 {
	return slices.DeleteFunc(slices.Clone(p.Heroes), func(id int64) bool { return id == 0 })
}

// Conclude marks the fight settled under its report key and frees the stage.
func (s *RunState) Conclude(reportKey string) {
	s.Release(s.Team.StartPlayer)
	s.Team.ReportKey = reportKey
}

// ApplyTeamResult empties the stage and adds the score on a win.
func (s *RunState) ApplyTeamResult(star int64) (SoloResult, error) {
	index := int(s.Team.SubID) - 1
	stage, err := s.stage(s.Team.CampaignID, index)
	if err != nil {
		return SoloResult{}, err
	}
	result := SoloResult{Star: max(min(star, MaxStar), 0)}
	result.Score = result.Star
	result.Won = result.Star > 0
	if result.Won {
		stage.HP = 0
		s.Points += result.Score
	}
	return result, nil
}
