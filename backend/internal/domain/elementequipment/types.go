package elementequipment

import (
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	"math/big"
	"sort"
	"strconv"
	"strings"
	"time"
)

var ErrInvalid = errors.New("element: invalid transition")
var ErrUnqualified = errors.New("element: unqualified owner or content")
var ErrStaleTime = errors.New("element: stale time")

const RootLockRank = 560
const HeroLockRank = 570
const SeedPolicy = "C2G_EMPTY_PRESERVATION_SEED_V1"

type State struct {
	Policy string `json:"policy"`
}

func Seed() State { return State{SeedPolicy} }
func (s State) Validate(Catalog) error {
	if s.Policy != SeedPolicy {
		return ErrUnqualified
	}
	return nil
}

type Root struct {
	Player               identity.PlayerID
	Version              int64
	Revision             string
	Facts                State
	CreatedAt, UpdatedAt time.Time
}
type HeroRoot struct {
	Player               identity.PlayerID
	PartnerID, Version   int64
	Facts                HeroFacts
	CreatedAt, UpdatedAt time.Time
}
type HeroFacts struct {
	Slots  [4]int64        `json:"slots"`
	Levels [4]int64        `json:"levels"`
	Backup map[int64]int64 `json:"backup"`
	Policy string          `json:"policy"`
}

func SeedHero() HeroFacts { return HeroFacts{Backup: map[int64]int64{}, Policy: SeedPolicy} }
func (s HeroFacts) Clone() HeroFacts {
	o := s
	o.Backup = map[int64]int64{}
	for k, v := range s.Backup {
		o.Backup[k] = v
	}
	return o
}
func (s HeroFacts) Level(id int64) (int64, bool) {
	for i, v := range s.Slots {
		if v == id && id > 0 {
			return s.Levels[i], true
		}
	}
	v, ok := s.Backup[id]
	return v, ok
}
func (s HeroFacts) Validate(c Catalog) error {
	if s.Policy != SeedPolicy || s.Backup == nil {
		return ErrUnqualified
	}
	seen := map[int64]bool{}
	for i, id := range s.Slots {
		if id == 0 {
			if s.Levels[i] != 0 {
				return ErrInvalid
			}
			continue
		}
		r, ok := c.Item(id)
		if !ok || seen[id] || s.Levels[i] < 0 || s.Levels[i] > 10 || (i == 0 && r.Type == 1) || (i > 0 && r.Type != 1) {
			return ErrInvalid
		}
		seen[id] = true
	}
	for id, l := range s.Backup {
		if _, ok := c.Item(id); !ok || seen[id] || l < 0 || l > 10 {
			return ErrInvalid
		}
		seen[id] = true
	}
	return nil
}
func (s HeroFacts) Wire() map[string]any {
	ids := []int64{}
	lev := []int64{}
	for id := range s.Backup {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, id := range ids {
		lev = append(lev, s.Backup[id])
	}
	return map[string]any{"element_equips": s.Slots, "element_levels": s.Levels, "element_bak_equips": ids, "element_bak_levels": lev}
}
func (s HeroFacts) Pipe() map[string]any {
	o := map[string]any{}
	for k, v := range s.Wire() {
		var ids []int64
		switch x := v.(type) {
		case [4]int64:
			ids = x[:]
		case []int64:
			ids = x
		}
		ss := []string{}
		for _, id := range ids {
			ss = append(ss, strconv.FormatInt(id, 10))
		}
		o[k] = strings.Join(ss, "|")
	}
	return o
}

type Catalog struct {
	SchemaVersion int                            `json:"schema_version"`
	PolicyID      string                         `json:"policy_id"`
	Tables        map[string][]map[string]string `json:"tables"`
}
type Item struct {
	ID, ItemID, Type, Element, Attr, Partner int64
	Base                                     string
	Strength                                 []string
	Active, ActiveSP                         string
	Skills, Buffs                            string
}

func (c Catalog) Item(id int64) (Item, bool) {
	for _, r := range c.Tables["equipment"] {
		if r["id"] == strconv.FormatInt(id, 10) {
			num := func(k string) int64 { v, _ := strconv.ParseInt(r[k], 10, 64); return v }
			return Item{num("id"), num("item_id"), num("equip_type"), num("element"), num("attr"), num("partner_id"), r["battle_nums"], strings.Split(r["battle_strth"], "|"), r["active"], r["active_sp"], r["skill_id"], r["buff_id"]}, true
		}
	}
	return Item{}, false
}
func number(s string) (*big.Rat, bool, error) {
	p := strings.HasSuffix(s, "p")
	s = strings.TrimSuffix(s, "p")
	v, ok := new(big.Rat).SetString(s)
	if !ok {
		return nil, false, ErrUnqualified
	}
	if p {
		v.Quo(v, big.NewRat(10000, 1))
	}
	return v, p, nil
}
func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C2G_ELEMENT_SOURCE_V1" || len(c.Tables["equipment"]) != 80 || len(c.Tables["strengthen"]) != 11 {
		return ErrUnqualified
	}
	seen := map[int64]bool{}
	items := map[int64]bool{}
	for _, r := range c.Tables["equipment"] {
		id, e := strconv.ParseInt(r["id"], 10, 64)
		it, ok := c.Item(id)
		if e != nil || !ok || id <= 0 || it.ItemID <= 0 || seen[id] || items[it.ItemID] || it.Type < 1 || it.Type > 3 || it.Element < 1 || it.Element > 3 || len(it.Strength) != 10 {
			return ErrUnqualified
		}
		seen[id] = true
		items[it.ItemID] = true
		for _, v := range append(append([]string{it.Base}, it.Strength...), it.Active, it.ActiveSP) {
			if _, _, e := number(v); e != nil {
				return e
			}
		}
		if (it.Type == 3) != (it.Partner > 0) {
			return ErrUnqualified
		}
	}
	for l := int64(0); l <= 10; l++ {
		for t := int64(1); t <= 3; t++ {
			if _, e := c.Materials(l, t, true); e != nil {
				return e
			}
			if l < 10 {
				if _, e := c.Materials(l, t, false); e != nil {
					return e
				}
			}
		}
	}
	return nil
}
func (c Catalog) Materials(level, typ int64, refund bool) (map[int64]int64, error) {
	if level < 0 || level > 10 || typ < 1 || typ > 3 || (!refund && level == 10) {
		return nil, ErrInvalid
	}
	key := "strth"
	if refund {
		key = "dec"
	}
	for _, r := range c.Tables["strengthen"] {
		if r["strth_ranks"] != strconv.FormatInt(level, 10) {
			continue
		}
		ids := strings.Split(r[fmt.Sprintf("%s_mtrs%d", key, typ)], "|")
		ns := strings.Split(r[fmt.Sprintf("%s_nums%d", key, typ)], "|")
		if len(ids) != len(ns) {
			return nil, ErrUnqualified
		}
		out := map[int64]int64{}
		for i, s := range ids {
			id, e := strconv.ParseInt(s, 10, 64)
			n, f := strconv.ParseInt(ns[i], 10, 64)
			if e != nil || f != nil || id <= 0 || n <= 0 || out[id] != 0 {
				return nil, ErrUnqualified
			}
			out[id] = n
		}
		return out, nil
	}
	return nil, ErrUnqualified
}

// Exact rational values retain source decimal and p units; later3B owns final stat composition.
type Contribution struct {
	Value              string
	Percent            bool
	ElementRowID       int64
	Rate               string
	ExclusiveBookCount int64
}

func (c Catalog) Evaluate(s HeroFacts, normal bool, heroTable, books int64) (map[int64]Contribution, error) {
	if e := s.Validate(c); e != nil {
		return nil, e
	}
	out := map[int64]Contribution{}
	element := int64(0)
	if s.Slots[0] > 0 {
		r, _ := c.Item(s.Slots[0])
		element = r.Element
	}
	for i, id := range s.Slots {
		if id == 0 {
			continue
		}
		r, _ := c.Item(id)
		if r.Attr == 0 {
			continue
		}
		if _, ok := out[r.Attr]; ok {
			continue
		}
		v, p, e := number(r.Base)
		if e != nil {
			return nil, e
		}
		if s.Levels[i] > 0 {
			d, dp, e := number(r.Strength[s.Levels[i]-1])
			if e != nil || p != dp {
				return nil, ErrUnqualified
			}
			v.Add(v, d)
		}
		rate := big.NewRat(1, 1)
		if r.Type == 1 && r.Element == element {
			a, _, e := number(r.Active)
			if e != nil {
				return nil, e
			}
			rate.Add(rate, a)
		}
		count := int64(0)
		if normal && r.ItemID == 20001453 && (heroTable == 10001144 || heroTable == 11001144) {
			count = books
			if count < 0 || count > 25 {
				return nil, ErrUnqualified
			}
			v.Mul(v, big.NewRat(count, 1))
		}
		v.Mul(v, rate)
		out[r.Attr] = Contribution{v.RatString(), p, id, rate.RatString(), count}
	}
	return out, nil
}

// BattleValue preserves core effect parameters as well as nonzero stat attributes.
func (c Catalog) BattleValue(id, level int64) (string, bool, error) {
	r, ok := c.Item(id)
	if !ok || level < 0 || level > 10 {
		return "", false, ErrInvalid
	}
	v, p, e := number(r.Base)
	if e != nil {
		return "", false, e
	}
	if level > 0 {
		n, np, e := number(r.Strength[level-1])
		if e != nil || np != p {
			return "", false, ErrUnqualified
		}
		v.Add(v, n)
	}
	return v.RatString(), p, nil
}
