package combat

import (
	"bytes"
	"encoding/json"
	"math/big"
	"sort"
	"strings"
)

// PartnerUse is one side's per-partner history fact from a persisted report.
type PartnerUse struct {
	PartnerID int64
	// TableID is the fighter's template id (Arena keys usage by girl).
	TableID int64
	Wins    int64
	Kills   int64
	// Harms is the exact decimal the report carried.
	Harms string
}

// PartnerTotals is one partner's accumulated usage row in a mode.
type PartnerTotals struct {
	PartnerID int64
	TableID   int64
	Fights    int64
	Wins      int64
	Kills     int64
	Harms     string
}

// History is one player's public performance in a mode (a 1829 HISTORY
// entry). Rank 0 is unranked; Points is the Arena season Lord points.
type History struct {
	Rank     int64
	Points   int64
	Fights   int64
	Wins     int64
	Version  int64
	Partners []PartnerTotals
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
				TableID   json.Number `json:"table_id"`
			} `json:"hero"`
		} `json:"fighter"`
	}
	decoder := json.NewDecoder(bytes.NewReader(report))
	decoder.UseNumber()
	if err := decoder.Decode(&body); err != nil {
		return nil, ErrIntegrity
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
			return nil, ErrIntegrity
		}
		harms, ok := new(big.Rat).SetString(defaultNumber(f.Harms))
		kills, err := json.Number(defaultNumber(f.KillCount)).Int64()
		if !ok || harms.Sign() < 0 || err != nil || kills < 0 {
			return nil, ErrIntegrity
		}
		table, err := json.Number(defaultNumber(f.Hero.TableID)).Int64()
		if err != nil || table < 0 {
			return nil, ErrIntegrity
		}
		out = append(out, PartnerUse{PartnerID: partner, TableID: table, Wins: wins, Kills: kills, Harms: harms.FloatString(6)})
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
