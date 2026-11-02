package modes

// Beyond says what a Ladder charges past its last row.
type Beyond int

const (
	// Refuse ends the ladder: client RefreshCostTable reads column[n] or 0 for most columns.
	Refuse Beyond = iota
	// ClampLast repeats the last price, as RefreshCostTable does for buy_skill_cost and treasure_match_mana.
	ClampLast
)

// Ladder is a fixed price column of refresh_cost.lua (F8, D76): Prices[0] is the price of the first buy.
type Ladder struct {
	Prices []int64
	Beyond Beyond
}

// Price is the price of the n-th buy (1-based); false when the ladder refuses it.
func (l Ladder) Price(n int64) (int64, bool) {
	if n < 1 || len(l.Prices) == 0 {
		return 0, false
	}
	last := int64(len(l.Prices))
	if n <= last {
		return l.Prices[n-1], true
	}
	if l.Beyond == ClampLast {
		return l.Prices[last-1], true
	}
	return 0, false
}
