package campaign

import (
	"fmt"
	"math"

	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/player"
)

// Sweep applies C7 after the ordinary node/function admission. Crystal sweeps
// pay for every run and leave cards alone (SweepWindow, D106).
func (c Catalog) Sweep(p Progress, n Node, count, kind, day, vip int64, monthly bool) (Progress, error) {
	if kind != 1 && kind != 2 || count < 1 || count > c.NormalSweepMax {
		return p, ErrInvalid
	}
	limit := c.NormalSweepMax
	if n.Type == Super {
		limit = c.Remaining(p, n, day)
	}
	if vip < 0 || vip >= int64(len(c.VIP)) {
		return p, ErrUnavailable
	}
	if modes.AdmitSweep(p.State(n.ID).Star, count, limit) != nil || count > 1 && c.VIP[vip].QuickSweep == 0 && !monthly {
		return p, ErrRefused
	}
	state := p.State(n.ID)
	if state.ClearCountFloor > math.MaxInt64-count {
		return p, ErrUnavailable
	}
	state.ClearCountFloor += count
	if n.Type == Super {
		var err error
		state.Wins, err = state.Wins.Use(day, count, n.DailyLimit)
		if err != nil {
			return p, ErrRefused
		}
	}
	return p.with(state), nil
}

// Reset buys an exhausted Super block. An already-reset, unexhausted row
// reconciles a lost response without another charge (V1, D107).
func (c Catalog) Reset(p Progress, id, level, day, vip int64, superOpen, monthly bool) (Progress, int64, error) {
	n, ok := c.Node(id)
	if !ok || n.Type != Super {
		return p, 0, ErrInvalid
	}
	if !c.isOpened(p, Super, id, superOpen) || p.State(n.Related).Star == 0 || level < n.OpenLevel {
		return p, 0, ErrRefused
	}
	if vip < 0 || vip >= int64(len(c.VIP)) {
		return p, 0, ErrUnavailable
	}
	state := p.State(id)
	used := state.Resets.In(day).Used
	if c.Remaining(p, n, day) > 0 {
		if used > 0 {
			return p, 0, nil
		}
		return p, 0, ErrRefused
	}
	allowance := c.VIP[vip].NumElite
	if monthly {
		allowance += c.Monthly.NumElite
	}
	resets, err := state.Resets.Use(day, 1, allowance)
	if err != nil {
		return p, 0, ErrRefused
	}
	price, ok := (modes.Ladder{Prices: c.EliteResetCosts}).Price(resets.Used)
	if !ok || price < 0 {
		return p, 0, ErrUnavailable
	}
	state.Resets, state.Wins = resets, modes.Counter{Period: day}
	return p.with(state), price, nil
}

// SweepEXP mirrors SweepWindow's pre-request level simulation (D106 private
// compatibility policy); I5 remains the only writer of actual progression.
func (c Catalog) SweepEXP(n Node, count int64, start player.Progression, rule player.ProgressionPolicy) (int64, error) {
	level, exp, total := start.Level, start.Exp, int64(0)
	for range count {
		gain := n.EnergyCost * c.ExpMultiplier
		if level <= 10 {
			if level < 1 || level > int64(len(rule.Rows)) {
				return 0, fmt.Errorf("%w: sweep progression row %d", ErrUnavailable, level)
			}
			gain = n.EnergyCost
			exp += gain
			if exp >= rule.Rows[level-1].TotalExp {
				level++
			}
		}
		total += gain
	}
	return total, nil
}
