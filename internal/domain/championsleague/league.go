// Package championsleague owns ACADEMY_LEAGUE facts. Source rules and the
// explicitly reconstructed C5F private policy are distinct from Region Arena.
package championsleague

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"math"
	"slices"
	"time"
)

const (
	ContractID          = "C5F_CHAMPIONS_LEAGUE_MODE_V1"
	PolicyID            = "C5F_LEAGUE_PRIVATE_POLICY_V2"
	CompetitionID       = "GLOBAL"
	CampaignType  int64 = 3
	BattleID      int64 = 111001
	RecordsMax          = 20
	ResultSeconds int64 = 600
)

var (
	ErrUnavailable = errors.New("league: unavailable")
	ErrInvalid     = errors.New("league: invalid request")
	ErrRefused     = errors.New("league: request refused")
	ErrConflict    = errors.New("league: conflicting state")
	ErrDue         = errors.New("league: cutoff due")
	ErrPending     = errors.New("league: battle pending")
)

type DailyReward struct {
	Group  int64 `json:"group"`
	Rank   int64 `json:"rank"`
	GiftID int64 `json:"gift_id"`
}
type Reward struct {
	Group    int64      `json:"group"`
	Rank     int64      `json:"rank"`
	Items    [][2]int64 `json:"items"`
	Crystal  int64      `json:"crystal"`
	BubbleID int64      `json:"bubble_id"`
}
type Gift struct {
	ID      int64      `json:"id"`
	Items   [][2]int64 `json:"items"`
	Crystal int64      `json:"crystal"`
	Mana    int64      `json:"mana"`
}
type Catalog struct {
	Mail             map[string]string `json:"mail"`
	SchemaVersion    int               `json:"schema_version"`
	ContractID       string            `json:"contract_id"`
	PolicyID         string            `json:"policy_id"`
	FunctionID       int64             `json:"function_id"`
	Levels           [3]int64          `json:"levels"`
	InitialPoints    int64             `json:"initial_points"`
	PointMax         int64             `json:"point_max"`
	PointMin         int64             `json:"point_min"`
	OpponentRadius   int64             `json:"opponent_radius"`
	NormalProtection int64             `json:"normal_protection"`
	FrenzyProtection int64             `json:"frenzy_protection"`
	FrenzyStart      int64             `json:"frenzy_start"`
	FrenzySeconds    int64             `json:"frenzy_seconds"`
	DayStart         int64             `json:"day_start"`
	SeasonDays       int64             `json:"season_days"`
	RestDays         int64             `json:"rest_days"`
	RatingScale      int64             `json:"rating_scale"`
	Schedule         []string          `json:"schedule"`
	FirstGift        int64             `json:"first_gift"`
	Daily            []DailyReward     `json:"daily"`
	Final            []Reward          `json:"final"`
	Gifts            []Gift            `json:"gifts"`
	TitleIDs         []int64           `json:"title_ids"`
	BubbleSeconds    int64             `json:"bubble_seconds"`
}

func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != ContractID || c.PolicyID != PolicyID || c.FunctionID != 91 || c.Levels != [3]int64{70, 90, 100} || c.InitialPoints != 2000 || c.PointMax != 36 || c.PointMin != 2 || c.OpponentRadius != 10 || c.NormalProtection != 1800 || c.FrenzyProtection != 180 || c.FrenzyStart != 75600 || c.FrenzySeconds != 3600 || c.DayStart != 79200 || c.SeasonDays != 30 || c.RestDays != 3 || c.RatingScale != 400 || len(c.Schedule) != 50 || len(c.Daily) != 90 || len(c.Final) != 30 || len(c.TitleIDs) != 10 || c.BubbleSeconds != 2592000 {
		return ErrUnavailable
	}
	var last time.Time
	for _, s := range c.Schedule {
		t, e := time.Parse("2006-01-02", s)
		if e != nil || !t.After(last) {
			return ErrUnavailable
		}
		last = t
	}
	for g := int64(1); g <= 3; g++ {
		var prev int64
		for _, r := range c.Daily {
			if r.Group == g {
				if r.Rank <= prev || r.GiftID <= 0 {
					return ErrUnavailable
				}
				if _, ok := c.Gift(r.GiftID); !ok {
					return ErrUnavailable
				}
				prev = r.Rank
			}
		}
		if prev < 5000 {
			return ErrUnavailable
		}
		prev = 0
		for _, r := range c.Final {
			if r.Group == g {
				if r.Rank <= prev || r.Crystal < 0 || len(r.Items) == 0 {
					return ErrUnavailable
				}
				prev = r.Rank
			}
		}
		if prev != 5000 {
			return ErrUnavailable
		}
	}
	return nil
}
func (c Catalog) Group(level int64) int64 {
	for i := 2; i >= 0; i-- {
		if level >= c.Levels[i] {
			return int64(i + 1)
		}
	}
	return 0
}
func (c Catalog) Gift(id int64) (Gift, bool) {
	for _, g := range c.Gifts {
		if g.ID == id {
			return g, true
		}
	}
	return Gift{}, false
}
func (c Catalog) DailyGift(group, rank int64) Gift {
	for _, r := range c.Daily {
		if r.Group == group && rank > 0 && rank <= r.Rank {
			g, _ := c.Gift(r.GiftID)
			return g
		}
	}
	g, _ := c.Gift(c.FirstGift)
	return g
}
func (c Catalog) FinalReward(group, rank int64) (Reward, bool) {
	for _, r := range c.Final {
		if r.Group == group && rank > 0 && rank <= r.Rank {
			return r, true
		}
	}
	return Reward{}, false
}
func floor(a, b int64) int64 {
	q := a / b
	if a%b < 0 {
		q--
	}
	return q
}
func (c Catalog) Day(at time.Time) int64    { return floor(at.Unix()+28800-c.DayStart, 86400) }
func (c Catalog) DayAt(day int64) time.Time { return time.Unix(day*86400-28800+c.DayStart, 0).UTC() }
func (c Catalog) seasonStart(index int64) time.Time {
	n := int64(len(c.Schedule))
	i := min(max(index, 1), n) - 1
	t, _ := time.Parse("2006-01-02", c.Schedule[i])
	return t.Add(-8*time.Hour + time.Duration(max(0, index-n)*c.SeasonDays)*24*time.Hour)
}

type Season struct {
	Number                    int64
	OpensAt, ClosesAt, NextAt time.Time
}

func (s Season) Open(at time.Time) bool {
	return s.Number > 0 && !at.Before(s.OpensAt) && at.Before(s.ClosesAt)
}
func (c Catalog) SeasonNumbered(n int64) Season {
	return Season{n, c.seasonStart(n), c.seasonStart(n + 1).Add(-time.Duration(c.RestDays) * 24 * time.Hour), c.seasonStart(n + 1)}
}
func (c Catalog) SeasonAt(at time.Time) Season {
	if at.Before(c.seasonStart(1)) {
		return Season{}
	}
	n := int64(len(c.Schedule))
	if !at.Before(c.seasonStart(n)) {
		n += floor(at.Unix()-c.seasonStart(n).Unix(), c.SeasonDays*86400)
		return c.SeasonNumbered(n)
	}
	for i := int64(1); i < n; i++ {
		if at.Before(c.seasonStart(i + 1)) {
			return c.SeasonNumbered(i)
		}
	}
	return Season{}
}

// Protection follows the window's normal-to-frenzy clipping rule. Half-open
// frenzy end is the explicit private boundary decision.
func (c Catalog) Protection(last, at time.Time) time.Time {
	if last.IsZero() {
		return time.Time{}
	}
	midnight := time.Unix(floor(at.Unix()+28800, 86400)*86400-28800, 0).UTC()
	start := midnight.Add(time.Duration(c.FrenzyStart) * time.Second)
	end := start.Add(time.Duration(c.FrenzySeconds) * time.Second)
	until := last.Add(time.Duration(c.NormalProtection) * time.Second)
	if !at.Before(start) && at.Before(end) {
		if last.Before(start) {
			until = minTime(until, start.Add(time.Duration(c.FrenzyProtection)*time.Second))
		} else {
			until = last.Add(time.Duration(c.FrenzyProtection) * time.Second)
		}
	}
	// Attacks during frenzy retain their short protection after22:00.
	lm := time.Unix(floor(last.Unix()+28800, 86400)*86400-28800, 0)
	ls := lm.Add(time.Duration(c.FrenzyStart) * time.Second)
	if !last.Before(ls) && last.Before(ls.Add(time.Duration(c.FrenzySeconds)*time.Second)) {
		until = minTime(until, last.Add(time.Duration(c.FrenzyProtection)*time.Second))
	}
	return until
}
func minTime(a, b time.Time) time.Time {
	if a.Before(b) {
		return a
	}
	return b
}

// Transfer is private integer policy, not recovered Elo. It conserves points.
func (c Catalog) Transfer(winner, loser int64) int64 {
	diff := max(int64(-1600), min(int64(1600), winner-loser))
	raw := float64(c.PointMax) / (1 + math.Pow(10, float64(diff)/float64(c.RatingScale)))
	return min(loser, max(c.PointMin, min(c.PointMax, int64(math.Floor(raw+0.5)))))
}

type Root struct {
	Revision             string
	Season               int64
	SettledSeason        int64
	Day                  int64
	Version              int64
	CreatedAt, UpdatedAt time.Time
}

func (r Root) Validate() error {
	if len(r.Revision) != 64 || r.Season < 1 || r.SettledSeason < r.Season-1 || r.SettledSeason > r.Season || r.Version < 1 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return ErrConflict
	}
	return nil
}

type Lineup struct {
	Heroes []int64
	Pet    int64
}

func (l Lineup) Valid(empty bool) bool {
	if len(l.Heroes) > 5 || !empty && len(l.Heroes) == 0 || l.Pet < 0 {
		return false
	}
	seen := map[int64]bool{}
	for _, id := range l.Heroes {
		if id <= 0 || seen[id] {
			return false
		}
		seen[id] = true
	}
	return true
}

type Placement struct {
	Group, Rank, Points int64
	ScoreAt             time.Time
	Tie                 string
	Participated        bool
}
type Player struct {
	ID                         identity.PlayerID
	Server                     identity.LogicalServerID
	Season, Group, Points      int64
	ScoreAt                    time.Time
	Tie                        string
	Defense                    Lineup
	Fights, Wins               int64
	Participated               bool
	LastWin, LastAttacked      time.Time
	ProtectedBy                ids.UUID
	Prior                      Placement
	Choice                     int64
	ChoicePending              bool
	LastDay                    Placement
	ClaimedDay                 int64
	QualifyingDays, TopSeasons int64
	Intent                     int64
	Selected                   identity.PlayerID
	Version                    int64
	CreatedAt, UpdatedAt       time.Time
}

func (c Catalog) NewPlayer(id identity.PlayerID, server identity.LogicalServerID, level int64, at time.Time) Player {
	p := Player{ID: id, Server: server, Season: c.SeasonAt(at).Number, Group: c.Group(level), Points: c.InitialPoints, ScoreAt: at, Defense: Lineup{Heroes: []int64{}}, Intent: 1, ClaimedDay: c.Day(at) - 1, Version: 1, CreatedAt: at, UpdatedAt: at}
	p.Tie = Tie(p.Season, p.Group, id)
	return p
}
func Tie(season, group int64, p identity.PlayerID) string {
	h := sha256.Sum256([]byte(fmt.Sprintf("%d:%d:%d", season, group, p)))
	return hex.EncodeToString(h[:])
}
func (p Player) Validate() error {
	if !p.ID.Valid() || !p.Server.Valid() || p.Season < 1 || p.Group < 1 || p.Group > 3 || p.Points < 0 || p.Points > 9007199254740991 || p.Fights < 0 || p.Wins < 0 || p.Wins > p.Fights || len(p.Tie) != 64 || p.ScoreAt.IsZero() || !p.Defense.Valid(true) || p.Intent < 1 || p.Version < 1 || p.UpdatedAt.Before(p.CreatedAt) || p.QualifyingDays < 0 || p.TopSeasons < 0 {
		return ErrConflict
	}
	return nil
}
func (c Catalog) Rolled(p Player, at time.Time) Player {
	if season := c.SeasonAt(at).Number; season > p.Season {
		p.Season = season
		p.Points = c.InitialPoints
		p.ScoreAt = at
		p.Fights = 0
		p.Wins = 0
		p.Participated = false
		p.LastWin = time.Time{}
		p.LastAttacked = time.Time{}
		p.ProtectedBy = ids.UUID{}
		p.Prior = Placement{}
		p.ChoicePending = false
		p.Choice = 0
		p.LastDay = Placement{}
		p.Selected = 0
		p.Intent++
		p.Tie = Tie(p.Season, p.Group, p.ID)
	}
	return p
}
func (c Catalog) Promote(p Player, group, rank int64, at time.Time) Player {
	if group <= p.Group {
		return p
	}
	p.Prior = Placement{Group: p.Group, Rank: rank, Points: p.Points, ScoreAt: p.ScoreAt, Tie: p.Tie, Participated: p.Participated}
	p.Group = group
	p.Points = c.InitialPoints
	p.ScoreAt = at
	p.Tie = Tie(p.Season, p.Group, p.ID)
	p.ChoicePending = true
	p.Choice = 1
	p.Participated = false
	p.Selected = 0
	p.Intent++
	return p
}
func Order(players []Player, season, group int64) []Player {
	out := []Player{}
	for _, p := range players {
		if p.Season == season && p.Group == group {
			out = append(out, p)
		}
	}
	slices.SortFunc(out, func(a, b Player) int {
		if a.Points > b.Points {
			return -1
		}
		if a.Points < b.Points {
			return 1
		}
		if a.ScoreAt.Before(b.ScoreAt) {
			return -1
		}
		if a.ScoreAt.After(b.ScoreAt) {
			return 1
		}
		if a.Tie < b.Tie {
			return -1
		}
		if a.Tie > b.Tie {
			return 1
		}
		return 0
	})
	return out
}
func Rank(players []Player, id identity.PlayerID) int64 {
	for i, p := range players {
		if p.ID == id {
			return int64(i + 1)
		}
	}
	return 0
}
func (c Catalog) Attack(a, b Player, win bool, at time.Time) (Player, Player, int64) {
	delta := c.Transfer(b.Points, a.Points)
	if win {
		delta = c.Transfer(a.Points, b.Points)
	} else {
		delta = -delta
	}
	a.Points += delta
	b.Points -= delta
	a.Fights++
	b.Fights++
	a.Participated = true
	b.Participated = true
	if win {
		a.Wins++
		a.LastWin = at
	} else {
		b.Wins++
		b.LastWin = at
	}
	if delta != 0 {
		a.ScoreAt = at
		b.ScoreAt = at
	}
	return a, b, delta
}

type Match struct {
	ID                            ids.UUID
	WireID                        int64
	Attacker, Defender            identity.PlayerID
	Intent, Season, Group         int64
	Fingerprint, Revision, Status string
	Attempt                       ids.UUID
	Attack, Defense               Lineup
	SelfRows, EnemyRows           []map[string]any
	EnemyPet                      map[string]any
	SelfFace, EnemyFace           Face
	PreviousAttack                time.Time
	PreviousProtectedBy           ids.UUID
	StartedAt                     time.Time
	SettledAt                     *time.Time
	Win                           bool
	Delta                         int64
	Version                       int64
}
type Face struct {
	ID                                           identity.PlayerID
	Name                                         string
	Level, Avatar, Frame, Conquer, Loop, GuildID int64
	GuildName                                    string
}

func (m Match) Validate() error {
	if m.ID.IsZero() || !m.Attacker.Valid() || !m.Defender.Valid() || m.Attacker == m.Defender || m.Intent < 1 || m.Season < 1 || m.Group < 1 || m.Group > 3 || len(m.Fingerprint) != 64 || len(m.Revision) != 64 || m.Attempt.IsZero() || !m.Attack.Valid(false) || !m.Defense.Valid(false) || m.Version < 1 || (m.Status != "FIGHTING" && m.Status != "SETTLED" && m.Status != "CLOSED") || (m.Status == "FIGHTING") != (m.SettledAt == nil) {
		return ErrConflict
	}
	return nil
}

type SettlementRow struct {
	Player                     identity.PlayerID
	Placement                  Placement
	Reward                     Reward
	TopSeasons, QualifyingDays int64
	Face                       Face
	Heroes                     []map[string]any
	Pet                        map[string]any
}
type Settlement struct {
	Kind                string
	Number              int64
	CutoffAt, SettledAt time.Time
	Revision            string
	Rows                []SettlementRow
}

// FinalOrder retains the selectable prior-group score, then recomputes rank.
// Promotion never guarantees an ordinal placement while others keep playing.
type FinalStanding struct {
	Player    identity.PlayerID
	Placement Placement
}

func FinalOrder(players []Player, season, group int64) []FinalStanding {
	out := []FinalStanding{}
	for _, p := range players {
		if p.Season != season {
			continue
		}
		if p.Group == group {
			out = append(out, FinalStanding{p.ID, Placement{Group: p.Group, Points: p.Points, ScoreAt: p.ScoreAt, Tie: p.Tie, Participated: p.Participated}})
		} else if p.Prior.Group == group && (p.ChoicePending || p.Choice == 1) {
			out = append(out, FinalStanding{p.ID, p.Prior})
		}
	}
	slices.SortFunc(out, func(a, b FinalStanding) int {
		x, y := a.Placement, b.Placement
		if x.Points > y.Points {
			return -1
		}
		if x.Points < y.Points {
			return 1
		}
		if x.ScoreAt.Before(y.ScoreAt) {
			return -1
		}
		if x.ScoreAt.After(y.ScoreAt) {
			return 1
		}
		if x.Tie < y.Tie {
			return -1
		}
		if x.Tie > y.Tie {
			return 1
		}
		return 0
	})
	for i := range out {
		out[i].Placement.Rank = int64(i + 1)
	}
	return out
}
func FinalPlacement(players []Player, p Player) Placement {
	group := p.Group
	if p.Prior.Group > 0 && (p.ChoicePending || p.Choice == 1) {
		group = p.Prior.Group
	}
	for _, r := range FinalOrder(players, p.Season, group) {
		if r.Player == p.ID {
			return r.Placement
		}
	}
	return Placement{}
}
