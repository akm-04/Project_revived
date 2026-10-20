package topfloor

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

type Fight struct {
	AttemptID      ids.UUID
	Server         identity.LogicalServerID
	Challenger     identity.PlayerID
	Defender       Occupant
	Avenge         bool
	Fingerprint    string
	Formation      []int64
	PetID          int64
	ChallengerRank int64
	DefenderRank   int64
	StartedAt      time.Time
	Status         string
	Outcome        *Outcome
	SettledAt      *time.Time
	StateVersion   int64
}

func (f Fight) Validate() error {
	settled := f.Status == StatusSettled
	known := f.Status == StatusStarted || settled || f.Status == StatusClosed
	if f.AttemptID.IsZero() || !f.Server.Valid() || !f.Challenger.Valid() || !f.Defender.Valid() || f.Defender.Player == f.Challenger || len(f.Fingerprint) != 64 || len(f.Formation) < 1 || len(f.Formation) > DefenseSlots ||
		f.PetID < 0 || f.ChallengerRank < 1 || f.DefenderRank < 1 || f.StartedAt.IsZero() || !known || settled != (f.Outcome != nil) || (f.Status == StatusStarted) != (f.SettledAt == nil) || f.StateVersion < 1 {
		return ErrConflict
	}
	return nil
}

type Record struct {
	ID        int64
	Owner     identity.PlayerID
	AttemptID ids.UUID
	Attack    bool
	Win       bool
	Opponent  Occupant
	At        time.Time
}

type DayRank struct {
	Player identity.PlayerID
	Rank   int64
	Mail   *ids.UUID
}

type DaySettlement struct {
	Server          identity.LogicalServerID
	Day             int64
	CutoffAt        time.Time
	SettledAt       time.Time
	LadderVersion   int64
	ContentRevision string
	Ranks           []DayRank
}
