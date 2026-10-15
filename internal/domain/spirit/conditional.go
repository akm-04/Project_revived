package spirit

// V1PreservationPolicy adopts the frozen V1 reconstruction policy. Its
// probabilities are implementation decisions, not recovered original-server math.
import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/foundation/operation"
	"math/big"
)

type MintPolicy interface {
	Revision() string
	Generate(Catalog, int64, operation.Context, string) (Instance, error)
}
type MilestonePolicy interface {
	Revision() string
	Advance(Catalog, Instance, int64, operation.Context, string) (Instance, error)
}
type V1PreservationPolicy struct{}

func (V1PreservationPolicy) Revision() string { return ReconstructionPolicy }

type stream struct {
	op       operation.Context
	salt     string
	ordinals map[string]uint64
}

func (s *stream) draw(namespace string, bound int64) (int64, error) {
	if bound <= 0 || s.op.ID.IsZero() || s.op.StartedAt.IsZero() {
		return 0, ErrUnqualified
	}
	if bound == 1 {
		return 0, nil
	}
	n := uint64(bound)
	threshold := -n % n
	for {
		if s.ordinals == nil {
			s.ordinals = map[string]uint64{}
		}
		ordinal := s.ordinals[namespace]
		s.ordinals[namespace]++
		b := s.op.Derive(namespace+"/"+s.salt, ordinal)
		for i := 0; i < len(b); i += 8 {
			v := binary.BigEndian.Uint64(b[i : i+8])
			if v >= threshold {
				return int64(v % n), nil
			}
		}
	}
}
func (p V1PreservationPolicy) Generate(c Catalog, template int64, op operation.Context, salt string) (Instance, error) {
	m, _, e := c.ModelFor(template)
	if e != nil {
		return Instance{}, e
	}
	s := stream{op: op, salt: salt + "/mint"}
	main, e := s.draw("horcrux.generate.main", int64(len(m.Main)))
	if e != nil {
		return Instance{}, e
	}
	x := Instance{TemplateID: template, Star: m.Star, Main: main + 1, Sub: []int64{}, SubValues: []json.Number{}, BirthSub: []int64{}, Policy: p.Revision()}
	x.MainValue, e = mainValue(m, x.Main, 0)
	if e != nil {
		return x, e
	}
	total := int64(0)
	for _, v := range m.Rates {
		total += v
	}
	count := int64(0)
	positive := 0
	for i, w := range m.Rates {
		if w > 0 {
			count = int64(i)
			positive++
		}
	}
	if positive != 1 {
		r, e := s.draw("horcrux.generate.sub_count", total)
		if e != nil {
			return x, e
		}
		for i, w := range m.Rates {
			if r < w {
				count = int64(i)
				break
			}
			r -= w
		}
	}
	available := []int64{}
	for i := range m.Sub {
		available = append(available, int64(i+1))
	}
	for i := int64(0); i < count; i++ {
		j, e := s.draw("horcrux.generate.sub_selector", int64(len(available)))
		if e != nil {
			return x, e
		}
		sel := available[j]
		available = append(available[:j], available[j+1:]...)
		x.Sub = append(x.Sub, sel)
		x.BirthSub = append(x.BirthSub, sel)
		v, e := Rat(m.SubBase[sel-1])
		if e != nil {
			return x, e
		}
		n, e := Num(v)
		if e != nil {
			return x, e
		}
		x.SubValues = append(x.SubValues, n)
	}
	return x, nil
}
func (p V1PreservationPolicy) Advance(c Catalog, x Instance, newLevel int64, op operation.Context, salt string) (Instance, error) {
	if e := x.Validate(c); e != nil {
		return x, e
	}
	m, _, _ := c.ModelFor(x.TemplateID)
	out := x.Clone()
	s := stream{op: op, salt: salt + "/milestone"}
	if newLevel < x.Level || newLevel > 15 {
		return x, ErrInvalid
	}
	for lev := x.Level + 1; lev <= newLevel; lev++ {
		if lev%3 != 0 {
			continue
		}
		add := len(out.Sub) == 0
		if len(out.Sub) > 0 && len(out.Sub) < int(m.SubNum) {
			v, e := s.draw("horcrux.enhance.action", 2)
			if e != nil {
				return x, e
			}
			add = v == 0
		}
		if add {
			seen := map[int64]bool{}
			for _, id := range out.Sub {
				seen[id] = true
			}
			available := []int64{}
			for i := range m.Sub {
				if !seen[int64(i+1)] {
					available = append(available, int64(i+1))
				}
			}
			j, e := s.draw("horcrux.enhance.new_sub", int64(len(available)))
			if e != nil {
				return x, e
			}
			sel := available[j]
			out.Sub = append(out.Sub, sel)
			base, _ := Rat(m.SubBase[sel-1])
			v, e := Num(base)
			if e != nil {
				return x, e
			}
			out.SubValues = append(out.SubValues, v)
		} else {
			j, e := s.draw("horcrux.enhance.improve_target", int64(len(out.Sub)))
			if e != nil {
				return x, e
			}
			sel := out.Sub[j]
			v, e := Rat(out.SubValues[j].String())
			if e != nil {
				return x, e
			}
			step, _ := Rat(m.SubStep[sel-1])
			n, e := Num(new(big.Rat).Add(v, step))
			if e != nil {
				return x, e
			}
			out.SubValues[j] = n
		}
	}
	out.Level = newLevel
	v, e := mainValue(m, out.Main, newLevel)
	out.MainValue = v
	return out, e
}
func (c Catalog) Enhancement(target Instance, fodder []Instance, policy MilestonePolicy, op operation.Context) (Instance, int64, int64, error) {
	if e := target.Validate(c); e != nil {
		return target, 0, 0, e
	}
	max, e := c.MaxEXP(target.Star)
	if e != nil || target.EXP >= max || len(fodder) == 0 {
		return target, 0, 0, ErrInvalid
	}
	gained := int64(0)
	seen := map[int64]bool{}
	for _, x := range fodder {
		if e := x.Validate(c); e != nil {
			return target, 0, 0, e
		}
		if seen[x.ID] || x.ID == target.ID {
			return target, 0, 0, ErrInvalid
		}
		seen[x.ID] = true
		m, _, _ := c.ModelFor(x.TemplateID)
		v := new(big.Rat).Mul(big.NewRat(x.EXP, 1), big.NewRat(3, 5))
		v.Add(v, big.NewRat(m.BaseEXP, 1))
		if !v.IsInt() || !v.Num().IsInt64() {
			return target, 0, 0, ErrUnqualified
		}
		n := v.Num().Int64()
		if n <= 0 || n > MaxID/25 || gained > MaxID/25-n {
			return target, 0, 0, ErrInvalid
		}
		gained += n
	}
	exp := target.EXP + gained
	if exp > max {
		exp = max
	}
	lev, e := c.Level(target.Star, exp)
	if e != nil {
		return target, 0, 0, e
	}
	out := target.Clone()
	if lev/3 > target.Level/3 {
		if policy == nil {
			return target, 0, 0, ErrUnavailable
		}
		out, e = policy.Advance(c, target, lev, op, fmt.Sprintf("target=%d", target.ID))
		if e != nil {
			return target, 0, 0, e
		}
	} else {
		out.Level = lev
		out.MainValue, e = mainValue(c.Models[c.Templates[target.TemplateID].Model], out.Main, lev)
		if e != nil {
			return target, 0, 0, e
		}
	}
	out.EXP = exp
	if e = out.Validate(c); e != nil {
		return target, 0, 0, e
	}
	return out, gained, gained * 25, nil
}
