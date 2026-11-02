package campaign

import (
	"fmt"
	"math"
)

// Outcome is one settled FIGHT_RESULT. Touched are the campaign ids the reply
// lists: the fought node and any node the result opened (star 0).
type Outcome struct {
	Progress   Progress
	Win        bool
	FirstClear bool
	Touched    []int64
	Energy     int64
	Mana       int64
	PlayerExp  int64
	PartnerExp int64
	Crystal    int64
}

// Settle applies C5: a loss costs defeat_cost; a win costs energy_cost, keeps the
// best star, spends one Super daily attempt, pays mana_gain, energy_cost x the
// exp multiplier, partner_exp and star_gift on the first 3-star, and opens the next node.
func (c Catalog) Settle(p Progress, n Node, star, day int64, superOpen bool) (Outcome, error) {
	if star < 0 || star > MaxStar {
		return Outcome{}, fmt.Errorf("%w: star %d", ErrInvalid, star)
	}
	if star == 0 {
		return Outcome{Progress: p, Touched: []int64{n.ID}, Energy: n.DefeatCost}, nil
	}
	state := p.State(n.ID)
	if state.ClearCountFloor == math.MaxInt64 {
		return Outcome{}, ErrUnavailable
	}
	state.ClearCountFloor++
	before := c.Opened(p, n.Type, superOpen)
	out := Outcome{Win: true, FirstClear: state.Star == 0, Energy: n.EnergyCost, Mana: n.ManaGain, PlayerExp: n.EnergyCost * c.ExpMultiplier, PartnerExp: n.PartnerExp}
	if state.Star < MaxStar && star == MaxStar {
		out.Crystal = n.StarGift
	}
	if n.Type == Super {
		wins, err := state.Wins.Use(day, 1, n.DailyLimit)
		if err != nil {
			return Outcome{}, fmt.Errorf("%w: super campaign %d daily limit", ErrRefused, n.ID)
		}
		state.Wins = wins
	}
	if _, trial := c.Group(n.Type); trial {
		var err error
		p, err = p.withTrialWin(n.Type, day)
		if err != nil {
			return Outcome{}, err
		}
	}
	state.Star = max(state.Star, star)
	out.Progress = p.with(state)
	out.Touched = []int64{n.ID}
	seen := make(map[int64]bool, len(before))
	for _, id := range before {
		seen[id] = true
	}
	for _, id := range c.Opened(out.Progress, n.Type, superOpen) {
		if !seen[id] && id != n.ID {
			out.Touched = append(out.Touched, id)
		}
	}
	return out, nil
}
