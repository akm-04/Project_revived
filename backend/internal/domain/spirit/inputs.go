package spirit

import (
	"math/big"
	"sort"
)

type Inputs struct {
	Raw, Values            map[int64]string
	TwoPiece               []int64
	FourPiece              int64
	FourPieceDescription   string
	FourPieceKnownCombatID bool
}

// Evaluate follows the recovered Normal/Super helper. It materializes source
// contributions and suit descriptors; it does not implement combat effects.
func (c Catalog) Evaluate(s State, slots [6]int64) (Inputs, error) {
	out := Inputs{Raw: map[int64]string{}, Values: map[int64]string{}, TwoPiece: []int64{}}
	if e := s.Validate(c); e != nil {
		return out, e
	}
	if e := s.ValidateSlots(c, slots, false); e != nil {
		return out, e
	}
	raw := map[int64]*big.Rat{}
	counts := map[int64]int{}
	add := func(attr int64, v *big.Rat) {
		if raw[attr] == nil {
			raw[attr] = new(big.Rat)
		}
		raw[attr].Add(raw[attr], v)
	}
	for _, id := range slots {
		if id == 0 {
			continue
		}
		x := s.Instances[id]
		m, t, e := c.ModelFor(x.TemplateID)
		if e != nil {
			return out, e
		}
		counts[t.Suit]++
		v, e := Rat(x.MainValue.String())
		if e != nil {
			return out, e
		}
		add(m.Main[x.Main-1], v)
		for i, sel := range x.Sub {
			v, e := Rat(x.SubValues[i].String())
			if e != nil {
				return out, e
			}
			add(m.Sub[sel-1], v)
		}
	}
	for id, n := range counts {
		if n >= 2 {
			out.TwoPiece = append(out.TwoPiece, id)
			r := c.Suits[id]
			v, e := Rat(r.Value)
			if e != nil {
				return out, e
			}
			add(r.Attr, v)
		}
		if n >= 4 {
			out.FourPiece = id
			out.FourPieceDescription = c.Suits[id].Description
			out.FourPieceKnownCombatID = id >= 1001 && id <= 1010
		}
	}
	sort.Slice(out.TwoPiece, func(i, j int) bool { return out.TwoPiece[i] < out.TwoPiece[j] })
	for attr, v := range raw {
		out.Raw[attr] = v.RatString()
		value := new(big.Rat).Set(v)
		bonus := int64(0)
		switch attr {
		case 4:
			bonus = 47
		case 5, 6:
			bonus = 48
		case 7, 8:
			bonus = 49
		}
		if b := raw[bonus]; bonus != 0 && b != nil {
			factor := new(big.Rat).Add(big.NewRat(1, 1), new(big.Rat).Quo(b, big.NewRat(10000, 1)))
			value.Mul(value, factor)
		}
		out.Values[attr] = value.RatString()
	}
	return out, nil
}
