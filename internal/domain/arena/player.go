package arena

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// Lineup is a saved defense: girls by table id (own or summoned this season)
// and an optional own pet id.
type Lineup struct {
	Heroes []int64 `json:"heroes"`
	Pet    int64   `json:"pet"`
}

// Award is one girl's season exchange state (RegionArenaHeroShop), keyed by
// her base (pre-awaken) table id.
type Award struct {
	TableID int64 `json:"table_id"`
	AddStar int64 `json:"add_star"`
	Awake   bool  `json:"is_awake"`
	Summon  bool  `json:"is_summon"`
	Picks   int64 `json:"region_arena_times"`
}

type MissionSlot struct {
	MissionID int64 `json:"mission_id"`
	Current   int64 `json:"current_num"`
	Complete  bool  `json:"is_complete"`
}

// Player is one competitor's Arena state; season-scoped fields belong to
// Season and are reset by Rolled when a newer season opens.
type Player struct {
	PlayerID      identity.PlayerID
	Server        identity.LogicalServerID
	Season        int64
	Star          int64
	Point         int64
	StarAt        time.Time
	TotalFight    int64
	WinTimes      int64
	KeepWin       int64
	DefenseWins   int64
	DefenseLosses int64
	DailyDay      int64
	DailyFights   int64
	Defense       Lineup
	Opponent      identity.PlayerID
	Practice      bool
	MatchCounter  int64
	Missions      []MissionSlot
	MissionTime   time.Time
	MissionDraws  int64
	ExchangeTimes [3]int64
	Awards        []Award
	StateVersion  int64
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

func NewPlayer(c Catalog, pid identity.PlayerID, server identity.LogicalServerID, at time.Time) Player {
	p := Player{PlayerID: pid, Server: server, Season: c.SeasonAt(at).Number, StarAt: at, DailyDay: Day(at), Defense: Lineup{Heroes: []int64{}},
		Missions: []MissionSlot{}, Awards: []Award{}, MissionTime: at, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	return c.Refill(p, at, true)
}

// Rolled applies the season and daily boundaries at at: a newer season resets
// stars, points, statistics, streaks and exchanges (user decision 2026-10-20
// full reset); missions, mission time and the saved defense carry over.
func (c Catalog) Rolled(p Player, at time.Time) Player {
	if season := c.SeasonAt(at).Number; season > p.Season {
		p.Season, p.Star, p.Point, p.StarAt = season, 0, 0, at
		p.TotalFight, p.WinTimes, p.KeepWin, p.DefenseWins, p.DefenseLosses = 0, 0, 0, 0, 0
		p.Opponent, p.Practice, p.ExchangeTimes, p.Awards = 0, false, [3]int64{}, []Award{}
	}
	if day := Day(at); day != p.DailyDay {
		p.DailyDay, p.DailyFights = day, 0
	}
	return c.Refill(p, at, false)
}

// Fought reports participation in the season (settlement eligibility, C5D policy).
func (p Player) Fought() bool { return p.TotalFight > 0 }

func (p Player) Award(baseTableID int64) (Award, int) {
	for i, a := range p.Awards {
		if a.TableID == baseTableID {
			return a, i
		}
	}
	return Award{TableID: baseTableID}, -1
}

func (p Player) withAward(a Award, index int) Player {
	awards := append([]Award{}, p.Awards...)
	if index < 0 {
		p.Awards = append(awards, a)
		return p
	}
	awards[index] = a
	p.Awards = awards
	return p
}

func (c Catalog) addStars(star, n int64) int64 { return min(star+n, c.MaxStars()) }

// dropStars applies rule 5 and the misc protections: no loss at or below
// region_arena_fail_protect or at Challenger; never below
// region_arena_upgrade_protect once reached; multi-star drops floor at the
// applicable protection (C5D policy).
func (c Catalog) dropStars(star, n int64) int64 {
	if star <= c.FailProtect || c.Challenger(star) {
		return star
	}
	floor := c.FailProtect
	if star >= c.UpgradeProtect {
		floor = c.UpgradeProtect
	}
	return max(star-n, floor)
}

// winStars is rule 3: two gems below LV20 after an attack win streak of 4.
func (c Catalog) winStars(p Player) int64 {
	if c.LevelOf(p.Star) < c.StreakBonusBelowLevel && p.KeepWin >= c.StreakBonusAfter {
		return 2
	}
	return 1
}

// pointChange is the C5D Lord point formula for a Challenger attacker:
// min(limit, base + param1 x max(0, opponent advantage)), added on a win and
// removed (floored at 0) on a loss.
func (c Catalog) pointChange(attacker, defender int64, win bool) int64 {
	advantage := defender - attacker
	if !win {
		advantage = attacker - defender
	}
	amount := min(c.PointLimit, c.PointBase+max(0, advantage)*c.PointHundredths[0]/100)
	if win {
		return amount
	}
	return -min(amount, attacker)
}

func (p Player) setStar(star int64, at time.Time) Player {
	if star != p.Star {
		p.Star, p.StarAt = star, at
	}
	return p
}

// Result is one settled ranked attack (or forfeit) for both players.
type Result struct {
	Attacker Player
	Defender Player
	Coins    int64
}

// Attack settles a ranked attack. A forfeit (STOP or abandon) is a loss for
// the attacker without coins or defender effects.
func (c Catalog) Attack(attacker, defender Player, win, forfeit bool, at time.Time) Result {
	bonus, keepWin := c.winStars(attacker), attacker.KeepWin
	attacker.TotalFight++
	switch {
	case win && c.Challenger(attacker.Star):
		attacker.Point += c.pointChange(attacker.Point, defender.Point, true)
	case win:
		attacker = attacker.setStar(c.addStars(attacker.Star, bonus), at)
	case c.Challenger(attacker.Star):
		attacker.Point += c.pointChange(attacker.Point, defender.Point, false)
	default:
		attacker = attacker.setStar(c.dropStars(attacker.Star, 1), at)
	}
	attacker.KeepWin = 0
	if win {
		attacker.WinTimes, attacker.KeepWin = attacker.WinTimes+1, keepWin+1
	}
	if forfeit {
		return Result{Attacker: attacker, Defender: defender}
	}
	var coins int64
	if attacker.DailyFights < c.DailyLimit {
		coins = c.DailyLossCoin
		if win {
			coins = c.DailyWinCoin
		}
	}
	attacker.DailyFights++
	return Result{Attacker: attacker, Defender: c.defend(defender, !win, at), Coins: coins}
}

// defend is rule 14: the third consecutive successful defense adds 1 gem and
// the third consecutive failed defense removes 3.
func (c Catalog) defend(p Player, held bool, at time.Time) Player {
	if held {
		p.DefenseWins, p.DefenseLosses = p.DefenseWins+1, 0
		if p.DefenseWins == 3 {
			p, p.DefenseWins = p.setStar(c.addStars(p.Star, 1), at), 0
		}
		return p
	}
	p.DefenseWins, p.DefenseLosses = 0, p.DefenseLosses+1
	if p.DefenseLosses == 3 {
		p, p.DefenseLosses = p.setStar(c.dropStars(p.Star, 3), at), 0
	}
	return p
}
