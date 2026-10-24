package campaign

const rateScale = 10000

type Item struct {
	ItemID int64 `json:"item_id"`
	Num    int64 `json:"item_num"`
}

// Uniform is the frozen entropy a drop draws from (combat START package stream or operation Derive).
type Uniform interface {
	Uniform(n uint64) uint64
}

// Drop is the C6 law (D81): each row of increase_rate r yields r/10000 copies
// plus one more with probability (r mod 10000)/10000, one draw per fractional row.
func (c Catalog) Drop(boxID int64, source Uniform) []Item {
	box, ok := c.Box(boxID)
	if !ok {
		return []Item{}
	}
	out := []Item{}
	for _, row := range box.Rows {
		count, remainder := row[1]/rateScale, row[1]%rateScale
		if remainder > 0 && int64(source.Uniform(rateScale)) < remainder {
			count++
		}
		if count > 0 {
			out = append(out, Item{ItemID: row[0], Num: count})
		}
	}
	return out
}
