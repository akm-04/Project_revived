package oneonone

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const (
	StatusStarted = "STARTED"
	StatusSettled = "SETTLED"
	StatusClosed  = "CLOSED"
)

// Round is one battle of a match: attacker team i against defender team i.
// A round without an attempt is forfeited by a defender who lacks team i.
type Round struct {
	AttemptID ids.UUID `json:"attempt_id"`
	Star      int64    `json:"star"`
	Resolved  bool     `json:"resolved"`
}

func (r Round) Forfeit() bool { return r.AttemptID.IsZero() }

type Match struct {
	ID           ids.UUID
	Attacker     identity.PlayerID
	Defender     identity.PlayerID
	Mode         int64
	Fingerprint  string
	AttackTeams  []Team
	DefenseTeams []Team
	Rounds       []Round
	StartedAt    time.Time
	Status       string
	Outcome      *Outcome
	SettledAt    *time.Time
	StateVersion int64
}

func (m Match) Validate() error {
	settled := m.Status == StatusSettled
	known := m.Status == StatusStarted || settled || m.Status == StatusClosed
	if m.ID.IsZero() || !m.Attacker.Valid() || !m.Defender.Valid() || m.Attacker == m.Defender || (m.Mode != ModeNormal && m.Mode != ModePromotion) || len(m.Fingerprint) != 64 ||
		len(m.Rounds) < 1 || len(m.Rounds) != len(m.AttackTeams) || len(m.DefenseTeams) > len(m.Rounds) || m.StartedAt.IsZero() || !known || settled != (m.Outcome != nil) ||
		(m.Status == StatusStarted) != (m.SettledAt == nil) || m.StateVersion < 1 {
		return ErrConflict
	}
	return nil
}

// Wins plays rounds in order until one side holds a majority (best of n; the
// source PeakArena.checkBattleResult stops at two of three, STRONG_INFERENCE).
// Star > 0 is a round win for the attacker; a forfeit is an attacker win.
func Wins(rounds []Round) ([]int64, bool, bool) {
	need := len(rounds)/2 + 1
	out := []int64{}
	won, lost := 0, 0
	for _, r := range rounds {
		if !r.Forfeit() && !r.Resolved {
			return out, false, false
		}
		win := r.Forfeit() || r.Star > 0
		if win {
			won++
			out = append(out, 1)
		} else {
			lost++
			out = append(out, 0)
		}
		if won == need || lost == need {
			return out, won == need, true
		}
	}
	return out, won == need, true
}

type Outcome struct {
	Wins           []int64  `json:"wins"`
	Win            bool     `json:"win"`
	AttackerBefore Position `json:"attacker_before"`
	DefenderBefore Position `json:"defender_before"`
	AttackerAfter  Position `json:"attacker_after"`
	DefenderAfter  Position `json:"defender_after"`
	Promoted       bool     `json:"promoted"`
}

// Decide applies a finished match to the players' current positions.
// Master/Senior: a win against a better slot swaps slots. Junior: Elo points
// move between the two, the loser never below the floor. Promotion: chances
// and wins accrue; reaching the wins swaps slot, level and points (source
// LEGEND_ARENA_RULE_TEXT 7/8).
func (c Catalog) Decide(m Match, attacker, defender Player, wins []int64, win bool, at time.Time) (Player, Player, Outcome) {
	o := Outcome{Wins: wins, Win: win, AttackerBefore: attacker.Position, DefenderBefore: defender.Position}
	stamp := at.UTC()
	if win {
		attacker.WinStreak++
	} else {
		attacker.WinStreak = 0
	}
	switch {
	case m.Mode == ModePromotion:
		attacker.Challenges++
		if win {
			attacker.PromotionWins++
		}
		if attacker.PromotionWins >= c.PromotionWins {
			attacker.Position, defender.Position = defender.Position, attacker.Position
			if defender.Slot == 0 {
				defender.Level = c.JuniorLevel(defender.Points)
			}
			o.Promoted = true
		}
		if o.Promoted || attacker.Challenges >= c.PromotionChances {
			attacker = endPromotion(attacker)
		}
	case Group(attacker.Level) != LevelJunior1:
		if win && defender.Slot < attacker.Slot {
			attacker.Slot, defender.Slot = defender.Slot, attacker.Slot
		}
	default:
		winner, loser := &attacker, &defender
		if !win {
			winner, loser = &defender, &attacker
		}
		gain := c.Gain(winner.Points, loser.Points)
		winner.Points += gain
		loser.Points = max(c.PointsFloor, loser.Points-gain)
		for _, p := range []*Player{winner, loser} {
			p.PointsAt = stamp
			p.Level = c.JuniorLevel(p.Points)
		}
	}
	o.AttackerAfter, o.DefenderAfter = attacker.Position, defender.Position
	return attacker, defender, o
}

func endPromotion(p Player) Player {
	p.Mode, p.Candidates, p.Opponent, p.Challenges, p.PromotionWins = ModeNormal, []identity.PlayerID{}, 0, 0, 0
	return p
}

// EndPromotion returns a player to normal mode when the promotion window closes.
func EndPromotion(p Player) Player { return endPromotion(p) }

type Record struct {
	ID      int64
	Owner   identity.PlayerID
	MatchID ids.UUID
	Attack  bool
	Win     bool
	Mode    int64
	At      time.Time
}
