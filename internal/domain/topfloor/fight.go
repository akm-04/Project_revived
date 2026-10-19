package topfloor

import (
	"bytes"
	"encoding/json"
	"math/big"
	"sort"
	"strings"
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

// PartnerUse is one side's per-partner history fact from a persisted report.
type PartnerUse struct {
	PartnerID int64
	Wins      int64
	Kills     int64
	// Harms is the exact decimal the report carried.
	Harms string
}

// Usage reads the report's non-summon fighters of one side ("A" challenger,
// "B" defender) as BattleCreateReport.writeReport recorded them.
func Usage(report []byte, side string, won bool) ([]PartnerUse, error) {
	var body struct {
		Fighter map[string]struct {
			SummonType json.Number `json:"summon_type"`
			Harms      json.Number `json:"harms"`
			KillCount  json.Number `json:"kill_count"`
			Hero       struct {
				PartnerID json.Number `json:"partner_id"`
			} `json:"hero"`
		} `json:"fighter"`
	}
	decoder := json.NewDecoder(bytes.NewReader(report))
	decoder.UseNumber()
	if err := decoder.Decode(&body); err != nil {
		return nil, ErrConflict
	}
	wins := int64(0)
	if won {
		wins = 1
	}
	out := []PartnerUse{}
	for key, f := range body.Fighter {
		if !strings.HasPrefix(key, side+"|") || (f.SummonType != "" && f.SummonType != "0") {
			continue
		}
		partner, err := f.Hero.PartnerID.Int64()
		if err != nil || partner <= 0 {
			return nil, ErrConflict
		}
		harms, ok := new(big.Rat).SetString(defaultNumber(f.Harms))
		kills, err := json.Number(defaultNumber(f.KillCount)).Int64()
		if !ok || harms.Sign() < 0 || err != nil || kills < 0 {
			return nil, ErrConflict
		}
		out = append(out, PartnerUse{PartnerID: partner, Wins: wins, Kills: kills, Harms: harms.FloatString(6)})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].PartnerID < out[j].PartnerID })
	return out, nil
}

func defaultNumber(n json.Number) string {
	if n == "" {
		return "0"
	}
	return n.String()
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
