package arena

import (
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// Standing is one player's season position input.
type Standing struct {
	PlayerID   identity.PlayerID
	Server     identity.LogicalServerID
	Star       int64
	Point      int64
	StarAt     time.Time
	TotalFight int64
	WinTimes   int64
	Defended   bool
}

func (p Player) Standing() Standing {
	return Standing{PlayerID: p.PlayerID, Server: p.Server, Star: p.Star, Point: p.Point, StarAt: p.StarAt, TotalFight: p.TotalFight, WinTimes: p.WinTimes,
		Defended: len(p.Defense.Heroes) == TeamSize}
}

// Order is the season order (C5D policy): stars, then Lord points, then the
// earlier reach of the current stars, then player id.
func Order(standings []Standing) []Standing {
	out := slices.Clone(standings)
	slices.SortFunc(out, func(a, b Standing) int {
		switch {
		case a.Star != b.Star:
			return int(b.Star - a.Star)
		case a.Point != b.Point:
			return int(b.Point - a.Point)
		case !a.StarAt.Equal(b.StarAt):
			return a.StarAt.Compare(b.StarAt)
		}
		return int(a.PlayerID - b.PlayerID)
	})
	return out
}

// Rank is the 1-based position in an ordered list, 0 when absent.
func Rank(ordered []Standing, pid identity.PlayerID) int64 {
	return int64(slices.IndexFunc(ordered, func(s Standing) bool { return s.PlayerID == pid }) + 1)
}

// Pick offers one opponent with a saved defense (C5D policy, user decision
// 2026-10-20): ranked play looks in the star band [0.8 s, 1.2 s] and widens it
// by 0.1 on each side until someone is found; practice picks from everyone.
func (c Catalog) Pick(self Player, standings []Standing, practice bool) (identity.PlayerID, bool) {
	pool := slices.DeleteFunc(slices.Clone(standings), func(s Standing) bool { return s.PlayerID == self.PlayerID || !s.Defended })
	if len(pool) == 0 {
		return 0, false
	}
	seed := []int64{int64(self.PlayerID), self.Season, self.MatchCounter}
	if practice {
		return pool[roll(int64(len(pool)), seed...)].PlayerID, true
	}
	low, high, step := c.MatchHundredths[0], c.MatchHundredths[1], c.MatchHundredths[2]
	star := max(self.Star, 1)
	for {
		band := slices.DeleteFunc(slices.Clone(pool), func(s Standing) bool { return s.Star*100 < star*low || s.Star*100 > star*high })
		if len(band) > 0 {
			return band[roll(int64(len(band)), seed...)].PlayerID, true
		}
		if low <= 0 && star*high >= c.MaxStars()*100 {
			return pool[roll(int64(len(pool)), seed...)].PlayerID, true
		}
		low, high = max(0, low-step), high+step
	}
}

// Line is one player's season settlement: final level reward and, for the
// season's Challenger rank 1, the champion item.
type Line struct {
	Standing Standing
	Rank     int64
	Level    int64
	Reward   Reward
	Champion bool
}

// Settle lists the participants (at least one ranked fight) in season order.
func (c Catalog) Settle(participants []Standing) []Line {
	ordered := Order(slices.DeleteFunc(slices.Clone(participants), func(s Standing) bool { return s.TotalFight == 0 }))
	lines := make([]Line, 0, len(ordered))
	for i, s := range ordered {
		level := c.LevelOf(s.Star)
		reward, _ := c.RewardFor(level)
		lines = append(lines, Line{Standing: s, Rank: int64(i + 1), Level: level, Reward: reward, Champion: i == 0 && c.Challenger(s.Star)})
	}
	return lines
}
