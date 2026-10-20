package conquerschool

import (
	"encoding/json"
	"errors"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// Conquer School mode rules (C5E_CONQUER_SCHOOL_MODE_V1, MIDs 1568-1573 and
// 2790). C5E_CONQUER_PRIVATE_POLICY_V1 marks every rule not recovered from source.
const (
	ModeContractID = "C5E_CONQUER_SCHOOL_MODE_V1"
	ModePolicyID   = "C5E_CONQUER_PRIVATE_POLICY_V1"
	// C5E policy bounds of client-attested RESULT summaries.
	MaxAlive  int64 = 6
	MaxDamage int64 = 1_000_000_000_000_000
)

var (
	ErrInvalid = errors.New("conquer: invalid request")
	ErrRefused = errors.New("conquer: refused by rule")
)

const (
	secondsPerDay = 86400
	zoneOffset    = 8 * 3600
)

type Mission struct {
	ID     int64    `json:"id"`
	Level  int64    `json:"lev"`
	Region int64    `json:"region"`
	NextID int64    `json:"next_id"`
	Teams  int64    `json:"teams"`
	Reward [2]int64 `json:"reward"`
}

type Loop struct {
	ID     int64    `json:"loop_id"`
	Reward [2]int64 `json:"reward"`
}

type ModeCatalog struct {
	SchemaVersion     int               `json:"schema_version"`
	ContractID        string            `json:"contract_id"`
	PolicyID          string            `json:"policy_id"`
	FunctionID        int64             `json:"function_id"`
	RequiredLevel     int64             `json:"required_level"`
	DayStartSeconds   int64             `json:"day_start_seconds"`
	MaxFormation      int               `json:"max_formation"`
	ChallengeNum      int64             `json:"challenge_num"`
	BuffLimit         int64             `json:"buff_limit"`
	BuyLimit          int64             `json:"buy_limit"`
	MaxLoop           int64             `json:"max_loop"`
	ReportLimit       int64             `json:"report_limit"`
	ReportReward      int64             `json:"report_reward"`
	ReportRewardLimit int64             `json:"report_reward_limit"`
	ReportRankRatio   int64             `json:"report_rank_ratio"`
	BuyCosts          []int64           `json:"buy_costs"`
	Missions          []Mission         `json:"missions"`
	Loops             []Loop            `json:"loops"`
	Mail              map[string]string `json:"mail"`
}

func (c ModeCatalog) Validate() error {
	shape := c.SchemaVersion == 1 && c.ContractID == ModeContractID && c.PolicyID == ModePolicyID && c.RequiredLevel > 0 && c.MaxFormation > 0 &&
		c.ChallengeNum > 0 && c.BuffLimit > 0 && c.ReportLimit > 0 && c.ReportRankRatio > 0 && c.ReportReward > 0 && c.ReportRewardLimit > 0 &&
		int64(len(c.BuyCosts)) == c.BuyLimit && int64(len(c.Loops)) == c.MaxLoop && len(c.Missions) == 56 && c.Missions[55].NextID == 0
	if !shape {
		return ErrUnqualified
	}
	for i, m := range c.Missions {
		chained := i == 55 || m.NextID == c.Missions[i+1].ID
		if !chained || m.Level != int64(i+1) || m.Teams < 1 || m.Teams > 5 || m.Reward[0] < 1 || m.Reward[1] < 1 {
			return ErrUnqualified
		}
	}
	for i, l := range c.Loops {
		if l.ID != int64(i+1) || l.Reward[0] < 1 || l.Reward[1] < 1 {
			return ErrUnqualified
		}
	}
	for _, key := range []string{"CONQUER_SCHOOL_MAIL_TITLE", "CONQUER_SCHOOL_MAIL_TEXT", "CONQUER_SCHOOL_MAIL_NAME"} {
		if c.Mail[key] == "" {
			return ErrUnqualified
		}
	}
	return nil
}

func floorDiv(a, b int64) int64 {
	q := a / b
	if a%b != 0 && (a < 0) != (b < 0) {
		q--
	}
	return q
}

// Day numbers the GMT+8 chance day, which begins at 05:00.
func (c ModeCatalog) Day(at time.Time) int64 {
	return floorDiv(at.Unix()+zoneOffset-c.DayStartSeconds, secondsPerDay)
}

func (c ModeCatalog) mission(id int64) (Mission, bool) {
	i := slices.IndexFunc(c.Missions, func(m Mission) bool { return m.ID == id })
	if i < 0 {
		return Mission{}, false
	}
	return c.Missions[i], true
}

// InitialRun is the first INFO's run of an INITIAL_NO_PROGRESS player.
func (c ModeCatalog) InitialRun(generation string) Run {
	return Run{Loop: 1, CurrentID: c.Missions[0].ID, PassedID: 0, Generation: generation}
}

// Ended mirrors the client checkEnd; every source mission is open.
func (c ModeCatalog) Ended(r Run) bool {
	return r.CurrentID == r.PassedID || r.Loop > c.MaxLoop
}

// Attempt is the open START of a mode player; a newer START supersedes it.
type Attempt struct {
	ID        string  `json:"id"`
	Loop      int64   `json:"loop"`
	MissionID int64   `json:"mission_id"`
	Formation []int64 `json:"formation"`
	Pet       int64   `json:"pet"`
}

// Mode is one player's mode state; Day scopes chances, buys and rewarded views.
type Mode struct {
	Player       identity.PlayerID `json:"-"`
	Day          int64             `json:"day"`
	LeftTimes    int64             `json:"left_times"`
	BuyTimes     int64             `json:"buy_times"`
	Buff         int64             `json:"buff"`
	AwardTimes   int64             `json:"report_award_times"`
	BeatenTeams  []int64           `json:"team_status"`
	UsedHeroes   []int64           `json:"used_heroes"`
	UsedPets     []int64           `json:"used_pets"`
	Attempt      *Attempt          `json:"attempt"`
	StateVersion int64             `json:"-"`
	CreatedAt    time.Time         `json:"-"`
	UpdatedAt    time.Time         `json:"-"`
}

func (c ModeCatalog) NewMode(player identity.PlayerID, at time.Time) Mode {
	return Mode{Player: player, Day: c.Day(at), LeftTimes: c.ChallengeNum, BeatenTeams: []int64{}, UsedHeroes: []int64{}, UsedPets: []int64{}, CreatedAt: at, UpdatedAt: at}
}

func (m Mode) clone() Mode {
	m.BeatenTeams, m.UsedHeroes, m.UsedPets = slices.Clone(m.BeatenTeams), slices.Clone(m.UsedHeroes), slices.Clone(m.UsedPets)
	if m.Attempt != nil {
		a := *m.Attempt
		a.Formation = slices.Clone(a.Formation)
		m.Attempt = &a
	}
	return m
}

// Rolled refills the chances and clears the day's buys and rewarded views on a new 05:00 day.
func (c ModeCatalog) Rolled(m Mode, at time.Time) Mode {
	m = m.clone()
	if day := c.Day(at); day != m.Day {
		m.Day, m.LeftTimes, m.BuyTimes, m.AwardTimes = day, c.ChallengeNum, 0, 0
	}
	return m
}

func (c ModeCatalog) clearMission(m Mode) Mode {
	m.BeatenTeams, m.UsedHeroes, m.UsedPets, m.Attempt = []int64{}, []int64{}, []int64{}, nil
	return m
}

// Start spends one chance and records the attempt for the current mission.
func (c ModeCatalog) Start(m Mode, r Run, formation []int64, pet int64, attemptID string) (Mode, error) {
	distinct := len(formation) > 0 && len(formation) <= c.MaxFormation && !slices.Contains(formation, 0) && len(uniq(formation)) == len(formation)
	if !distinct || pet < 0 || slices.ContainsFunc(formation, func(id int64) bool { return id < 0 }) {
		return m, ErrInvalid
	}
	if c.Ended(r) || m.LeftTimes < 1 {
		return m, ErrRefused
	}
	if slices.ContainsFunc(formation, func(id int64) bool { return slices.Contains(m.UsedHeroes, id) }) || pet > 0 && slices.Contains(m.UsedPets, pet) {
		return m, ErrRefused
	}
	m = m.clone()
	m.LeftTimes--
	m.Attempt = &Attempt{ID: attemptID, Loop: r.Loop, MissionID: r.CurrentID, Formation: slices.Clone(formation), Pet: pet}
	return m, nil
}

func uniq(values []int64) []int64 {
	out := slices.Clone(values)
	slices.Sort(out)
	return slices.Compact(out)
}

// Result is the client-attested RESULT summary (CLIENT_SUMMARY_ATTESTED).
type Result struct {
	CampaignID    int64
	TeamID        int64
	Win           bool
	Formation     []int64
	Pet           int64
	Damage        int64
	Alive         int64
	ReportInvalid bool
}

type Settlement struct {
	Mode       Mode
	Run        Run
	Progress   Progress
	Promoted   bool
	Rewards    [][2]int64
	KeepReport bool
	Attempt    Attempt
}

// Settle closes the open attempt and recomputes every canonical consequence.
func (c ModeCatalog) Settle(m Mode, r Run, p Progress, res Result) (Settlement, error) {
	if res.Damage < 0 || res.Damage > MaxDamage || res.Alive < 0 || res.Alive > MaxAlive || res.Pet < 0 {
		return Settlement{}, ErrInvalid
	}
	a := m.Attempt
	mission, known := c.mission(r.CurrentID)
	if a == nil || c.Ended(r) || !known || a.Loop != r.Loop || a.MissionID != r.CurrentID || res.CampaignID != r.CurrentID {
		return Settlement{}, ErrRefused
	}
	if res.TeamID < 1 || res.TeamID > mission.Teams || slices.Contains(m.BeatenTeams, res.TeamID) || !slices.Equal(res.Formation, a.Formation) || res.Pet != a.Pet {
		return Settlement{}, ErrRefused
	}
	m = m.clone()
	out := Settlement{Run: r, Progress: p, KeepReport: res.Win && !res.ReportInvalid, Attempt: *m.Attempt}
	m.Attempt = nil
	if !res.Win {
		m.Buff = min(m.Buff+1, c.BuffLimit)
		out.Mode = m
		return out, nil
	}
	m.BeatenTeams = append(m.BeatenTeams, res.TeamID)
	m.UsedHeroes = append(m.UsedHeroes, a.Formation...)
	if a.Pet > 0 {
		m.UsedPets = append(m.UsedPets, a.Pet)
	}
	if int64(len(m.BeatenTeams)) < mission.Teams {
		out.Mode = m
		return out, nil
	}
	m = c.clearMission(m)
	m.Buff, m.LeftTimes = 0, c.ChallengeNum
	out.Mode, out.Promoted, out.Rewards = m, true, [][2]int64{mission.Reward}
	out.Progress = Progress{Level: mission.Level, Loop: r.Loop}
	out.Run = Run{Loop: r.Loop, CurrentID: mission.NextID, PassedID: mission.ID, Generation: r.Generation}
	if mission.NextID != 0 {
		return out, nil
	}
	out.Rewards = append(out.Rewards, c.Loops[r.Loop-1].Reward)
	out.Progress.Loop = r.Loop + 1
	out.Run = c.InitialRun(r.Generation)
	out.Run.Loop = r.Loop + 1
	if out.Run.Loop > c.MaxLoop {
		out.Run.CurrentID, out.Run.PassedID = mission.ID, mission.ID
	}
	return out, nil
}

// Reset clears the current mission's beaten teams and used girls and pets;
// chances and the defeat buff stay (user decision "Keep it").
func (c ModeCatalog) Reset(m Mode, r Run) (Mode, error) {
	if c.Ended(r) {
		return m, ErrRefused
	}
	return c.clearMission(m.clone()), nil
}

// Buy adds one chance for the day's next buy_conquer_cost in crystal.
func (c ModeCatalog) Buy(m Mode, privilegeActive bool) (Mode, int64, error) {
	if !privilegeActive || m.BuyTimes >= c.BuyLimit {
		return m, 0, ErrRefused
	}
	m = m.clone()
	cost := c.BuyCosts[m.BuyTimes]
	m.BuyTimes++
	m.LeftTimes++
	return m, cost, nil
}

// Score ranks kept reports: survivors first, then damage.
func (c ModeCatalog) Score(alive, damage int64) int64 {
	return alive*c.ReportRankRatio + damage
}

// RewardView counts one rewarded view of the owner's reports today, up to the daily limit.
func (c ModeCatalog) RewardView(owner Mode, at time.Time) (Mode, bool) {
	owner = c.Rolled(owner, at)
	if owner.AwardTimes >= c.ReportRewardLimit {
		return owner, false
	}
	owner.AwardTimes++
	return owner, true
}

// ReportProfile is the owner's public card when the report was kept.
type ReportProfile struct {
	Name         string `json:"player_name"`
	Level        int64  `json:"lev"`
	ConquerLevel int64  `json:"conquer_lev"`
	ConquerLoop  int64  `json:"conquer_loop_id"`
	Server       int64  `json:"region"`
	AvatarID     int64  `json:"avatar_id"`
	FrameID      int64  `json:"avatar_frame_id"`
}

// Report is an immutable kept won fight; Heroes, Pet and Body are client wire snapshots.
type Report struct {
	Key        string
	Owner      identity.PlayerID
	Loop       int64
	MissionID  int64
	TeamID     int64
	Score      int64
	Profile    ReportProfile
	Heroes     json.RawMessage
	Pet        json.RawMessage
	Body       json.RawMessage
	AttemptID  string
	RecordedAt time.Time
}

// InfoView is the info object of 1568/1570/1573 for one mode player.
type InfoView struct {
	Run   Run
	Mode  Mode
	Teams int64
}

func (c ModeCatalog) Info(m Mode, r Run) InfoView {
	mission, _ := c.mission(r.CurrentID)
	return InfoView{Run: r, Mode: m, Teams: mission.Teams}
}

// ResultView answers 1570; Progress and Region are sent only on promotion.
type ResultView struct {
	Info     InfoView
	Promoted bool
	Rewards  [][2]int64
	Progress Progress
	Region   int64
}
