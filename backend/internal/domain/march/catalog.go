package march

import (
	"encoding/hex"
	"math"
	"strconv"
	"strings"
)

type Advance struct {
	Level  int64     `json:"level"`
	Rates  []int64   `json:"rates"`
	Counts [][]int64 `json:"counts"`
}
type Policy struct {
	SuperChance    int64 `json:"super_chance_per_10000"`
	ManaPerLevel   int64 `json:"mana_per_academy_level"`
	MarchCoin      int64 `json:"march_coin_per_stage"`
	Reagents       int64 `json:"reagents_per_stage"`
	ResultWindow   int64 `json:"result_window_seconds"`
	CandidateLimit int64 `json:"candidate_limit"`
}
type Catalog struct {
	Schema          int64                 `json:"schema_version"`
	Contract        string                `json:"contract_id"`
	PolicyID        string                `json:"policy_id"`
	PolicySHA       string                `json:"policy_sha256"`
	Sources         map[string]string     `json:"source_sha256"`
	Advances        []Advance             `json:"advances"`
	Recommendations [][]int64             `json:"recommendations"`
	Pools           map[string][][3]int64 `json:"pools"`
	Misc            map[string]string     `json:"misc"`
	Milestones      []int64               `json:"milestones"`
	Policy          Policy                `json:"policy"`
}

func (c Catalog) Validate() error {
	if c.Schema != 1 || c.Contract != ContractID || c.PolicyID != PolicyID || len(c.PolicySHA) != 64 || len(c.Advances) != 36 || len(c.Recommendations) != 6 || len(c.Milestones) != 4 || len(c.Pools) != 8 {
		return ErrInvalid
	}
	if _, err := hex.DecodeString(c.PolicySHA); err != nil {
		return ErrInvalid
	}
	p := c.Policy
	if p.SuperChance < 0 || p.SuperChance > 10000 || p.ManaPerLevel <= 0 || p.ManaPerLevel > 1000000 || p.MarchCoin < 0 || p.MarchCoin > 10000 || p.Reagents < 0 || p.Reagents > 100 || p.ResultWindow < 60 || p.ResultWindow > 86400 || p.CandidateLimit < 15 || p.CandidateLimit > 1000 {
		return ErrInvalid
	}
	for i, a := range c.Advances {
		if a.Level != int64(i+65) || len(a.Rates) != 4 || len(a.Counts) != 5 {
			return ErrInvalid
		}
		last := int64(0)
		for _, r := range a.Rates {
			if r <= last {
				return ErrInvalid
			}
			last = r
		}
		for _, counts := range a.Counts {
			if len(counts) == 0 {
				return ErrInvalid
			}
			for _, n := range counts {
				if n < 1 || n >= Stages {
					return ErrInvalid
				}
			}
		}
	}
	for _, group := range c.Recommendations {
		if len(group) == 0 {
			return ErrInvalid
		}
		for _, id := range group {
			if id <= 0 {
				return ErrInvalid
			}
		}
	}
	expected := map[string]int{"130001": 1, "130002": 1, "130003": 1, "130004": 1, "200012": 226, "200013": 64, "200015": 165, "200016": 40}
	for id, n := range expected {
		rows := c.Pools[id]
		if len(rows) != n {
			return ErrInvalid
		}
		total := int64(0)
		for _, r := range rows {
			if r[0] <= 0 || r[1] <= 0 || r[2] < 0 || r[2] > 10000 {
				return ErrInvalid
			}
			total += r[2]
		}
		if total != 10000 {
			return ErrInvalid
		}
	}
	if len(c.Factors("expedition_rival_param")) != Stages || len(c.Factors("expedition_mana_param")) != Stages || len(c.Factors("expedition_init_mana")) != Stages {
		return ErrInvalid
	}
	return nil
}
func (c Catalog) Factors(key string) []float64 {
	out := []float64{}
	for _, token := range strings.Split(c.Misc[key], "|") {
		n, err := strconv.ParseFloat(token, 64)
		if err != nil || math.IsNaN(n) || math.IsInf(n, 0) || n < 0 {
			return nil
		}
		out = append(out, n)
	}
	return out
}

type Random interface{ Uniform(uint64) uint64 }

func (c Catalog) Draw(extra bool, lifetime int64, rng Random) [][2]int64 {
	out := [][2]int64{}
	count := 1
	if extra {
		count = 3
	}
	for i := 0; i < count; i++ {
		pool := "200012"
		if extra {
			pool = "200015"
		}
		if int64(rng.Uniform(10000)) < c.Policy.SuperChance {
			if extra {
				pool = "200016"
			} else {
				pool = "200013"
			}
		}
		if !extra {
			for j, m := range c.Milestones {
				if lifetime == m {
					pool = strconv.Itoa(130001 + j)
				}
			}
		}
		roll := int64(rng.Uniform(10000))
		for _, r := range c.Pools[pool] {
			if roll < r[2] {
				out = append(out, [2]int64{r[0], r[1]})
				break
			}
			roll -= r[2]
		}
	}
	return out
}
func (c Catalog) SweepCount(level, force int64, rng Random) (int64, error) {
	if level < 65 || level > 100 || force < 0 {
		return 0, ErrRefused
	}
	a := c.Advances[level-65]
	rating := 0
	for _, threshold := range a.Rates {
		if force >= threshold {
			rating++
		}
	}
	group := a.Counts[rating]
	return group[rng.Uniform(uint64(len(group)))], nil
}
