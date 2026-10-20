package arena

import (
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const CompetitionID = "GLOBAL"

// Competition is the serialization root (lock 603); SettledThrough is the
// newest season whose settlement committed.
type Competition struct {
	ID              string
	ContentRevision string
	SettledThrough  int64
	StateVersion    int64
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

func (c Competition) Validate() error {
	if c.ID != CompetitionID || len(c.ContentRevision) != 64 || c.SettledThrough < 0 || c.StateVersion < 1 || c.UpdatedAt.Before(c.CreatedAt) {
		return fmt.Errorf("%w: competition", ErrConflict)
	}
	return nil
}

func (p Player) Validate() error {
	defense := len(p.Defense.Heroes) == 0 || len(p.Defense.Heroes) == TeamSize
	streaks := p.DefenseWins >= 0 && p.DefenseWins < 3 && p.DefenseLosses >= 0 && p.DefenseLosses < 3
	totals := p.TotalFight >= 0 && p.WinTimes >= 0 && p.WinTimes <= p.TotalFight && p.KeepWin >= 0 && p.KeepWin <= p.WinTimes
	if !p.PlayerID.Valid() || p.Season < 0 || p.Star < 0 || p.Point < 0 || !defense || !streaks || !totals || len(p.Missions) > Missions ||
		p.Opponent == p.PlayerID || p.DailyFights < 0 || p.StateVersion < 1 {
		return fmt.Errorf("%w: player %d", ErrConflict, p.PlayerID)
	}
	return nil
}

func (m Match) Validate() error {
	open := m.Status == StatusStarted || m.Status == StatusFighting
	known := open || m.Status == StatusSettled || m.Status == StatusClosed
	fighting := m.Status != StatusFighting || !m.AttemptID.IsZero() && len(m.Formation) > 0 && m.Fingerprint != ""
	if m.ID.IsZero() || !m.Attacker.Valid() || !m.Defender.Valid() || m.Attacker == m.Defender || m.Season < 1 || !known || !fighting ||
		len(m.DefenseHeroes) < 1 || len(m.DefenseHeroes) > TeamSize || len(m.Formation) > TeamSize || open != (m.SettledAt == nil) ||
		(m.Status == StatusSettled) != (m.Outcome != nil) || m.StartedAt.IsZero() || m.StateVersion < 1 {
		return fmt.Errorf("%w: match", ErrConflict)
	}
	return nil
}

// SettlementRow is one participant's immutable season result.
type SettlementRow struct {
	Player   identity.PlayerID
	Rank     int64
	Level    int64
	Star     int64
	Point    int64
	Champion bool
	Mail     *ids.UUID
}

type Settlement struct {
	Season             int64
	CutoffAt           time.Time
	SettledAt          time.Time
	CompetitionVersion int64
	ContentRevision    string
	Rows               []SettlementRow
}
