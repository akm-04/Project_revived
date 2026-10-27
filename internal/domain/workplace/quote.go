// Package workplace owns timed district jobs, not the superseded manual raids.
package workplace

import (
	"errors"
	"math/big"
)

var ErrInvalid = errors.New("workplace invalid input")

type Rate struct {
	Numerator   int64 `json:"numerator"`
	Denominator int64 `json:"denominator"`
}

type Location struct {
	ID         int64   `json:"id"`
	Jobs       []int64 `json:"jobs"`
	MaxMembers int64   `json:"max_members"`
	BaseTime   int64   `json:"base_time"`
	BaseIce    int64   `json:"base_ice"`
	ChestRate  int64   `json:"chest_rate"`
	EnemyRate  int64   `json:"enemy_rate"`
}

type Job struct {
	ID          int64      `json:"id"`
	Product     int64      `json:"product"`
	Chests      [][2]int64 `json:"chests"`
	RequireType int64      `json:"require_type"`
	Require     int64      `json:"require"`
}

// Worker contains accepted owned identity and source inputs frozen at dispatch.
type Worker struct {
	PartnerID int64 `json:"partner_id"`
	BaseID    int64 `json:"base_id"`
	Level     int64 `json:"level"`
	Star      int64 `json:"star"`
	Color     int64 `json:"color"`
	Trait     int64 `json:"trait"`
	Power     int64 `json:"power"`
}

type Formula struct {
	Base         int64           `json:"base"`
	PerGirl      int64           `json:"per_girl"`
	Color        int64           `json:"color"`
	Star         int64           `json:"star"`
	Level        int64           `json:"level"`
	Products     map[int64]Rate  `json:"products"`
	TraitAmounts map[int64]int64 `json:"trait_amounts"`
}

type Quote struct {
	SP           int64 `json:"sp"`
	Seconds      int64 `json:"seconds"`
	BaseReward   int64 `json:"base_reward"`
	Quantity     int64 `json:"quantity"`
	TotalLevel   int64 `json:"total_level"`
	TotalStar    int64 `json:"total_star"`
	TotalColor   int64 `json:"total_color"`
	ChestPercent int64 `json:"chest_percent"`
	RivalPercent int64 `json:"rival_percent"`
}

func scaledFloor(value *big.Int, rate Rate) (int64, error) {
	if value.Sign() < 0 || rate.Numerator < 0 || rate.Denominator <= 0 {
		return 0, ErrInvalid
	}
	result := new(big.Int).Mul(value, big.NewInt(rate.Numerator))
	result.Quo(result, big.NewInt(rate.Denominator))
	if !result.IsInt64() {
		return 0, ErrInvalid
	}
	return result.Int64(), nil
}

// Calculate mirrors the two stock preview floors. Event rates are explicitly
// the versioned private policy; the client does not recover their equation.
func Calculate(location Location, job Job, workers []Worker, vip Rate, formula Formula) (Quote, error) {
	if location.ID <= 0 || location.MaxMembers > 1000 || len(workers) == 0 || int64(len(workers)) > location.MaxMembers || location.BaseIce < 0 || location.BaseTime <= 0 || location.ChestRate < 0 || location.ChestRate > 100 || location.EnemyRate < 0 || location.EnemyRate > 100 || vip.Numerator <= 0 || formula.Base < 0 || formula.PerGirl < 0 || formula.Color < 0 || formula.Star < 0 || formula.Level < 0 {
		return Quote{}, ErrInvalid
	}
	allowed := false
	for _, id := range location.Jobs {
		allowed = allowed || id == job.ID
	}
	productRate, ok := formula.Products[job.Product]
	if !allowed || !ok || job.Product < 1 || job.Product > 9 {
		return Quote{}, ErrInvalid
	}
	for trait := int64(1); trait <= 4; trait++ {
		if formula.TraitAmounts[trait] < 0 || formula.TraitAmounts[trait] > 36000 {
			return Quote{}, ErrInvalid
		}
	}
	quote := Quote{SP: location.BaseIce, Seconds: location.BaseTime}
	identities, bases := map[int64]bool{}, map[int64]bool{}
	traits := [5]int64{}
	base := big.NewInt(formula.Base)
	base.Add(base, new(big.Int).Mul(big.NewInt(formula.PerGirl), big.NewInt(int64(len(workers)))))
	for _, worker := range workers {
		if worker.PartnerID <= 0 || worker.BaseID <= 0 || identities[worker.PartnerID] || bases[worker.BaseID] || worker.Level <= 0 || worker.Star <= 0 || worker.Color < 0 || worker.Power < 0 || worker.Trait < 0 || worker.Trait > 4 {
			return Quote{}, ErrInvalid
		}
		identities[worker.PartnerID], bases[worker.BaseID] = true, true
		traits[worker.Trait]++
		for _, input := range [][2]int64{{worker.Level, formula.Level}, {worker.Star, formula.Star}, {worker.Color, formula.Color}} {
			base.Add(base, new(big.Int).Mul(big.NewInt(input[0]), big.NewInt(input[1])))
		}
		level := new(big.Int).Add(big.NewInt(quote.TotalLevel), big.NewInt(worker.Level))
		star := new(big.Int).Add(big.NewInt(quote.TotalStar), big.NewInt(worker.Star))
		color := new(big.Int).Add(big.NewInt(quote.TotalColor), big.NewInt(worker.Color))
		if !level.IsInt64() || !star.IsInt64() || !color.IsInt64() {
			return Quote{}, ErrInvalid
		}
		quote.TotalLevel, quote.TotalStar, quote.TotalColor = level.Int64(), star.Int64(), color.Int64()
	}
	quote.SP -= traits[1] * formula.TraitAmounts[1]
	quote.Seconds -= traits[3] * formula.TraitAmounts[3]
	if quote.SP < 0 || quote.Seconds <= 0 {
		return Quote{}, ErrInvalid
	}
	var err error
	quote.BaseReward, err = scaledFloor(base, vip)
	if err != nil {
		return Quote{}, err
	}
	quote.Quantity, err = scaledFloor(big.NewInt(quote.BaseReward), productRate)
	if err != nil {
		return Quote{}, err
	}
	if location.ChestRate > 0 {
		quote.ChestPercent = min(100, location.ChestRate+traits[2]*formula.TraitAmounts[2])
	}
	if location.EnemyRate > 0 {
		quote.RivalPercent = min(100, location.EnemyRate+traits[4]*formula.TraitAmounts[4])
	}
	return quote, nil
}
