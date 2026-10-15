package inscription

import (
	"encoding/binary"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"strconv"
	"strings"
	"time"
)

var ErrInvalid = errors.New("inscription: invalid transition")
var ErrUnqualified = errors.New("inscription: unqualified input")
var ErrStaleTime = errors.New("inscription: stale decision")

const RootLockRank = 540
const HeroLockRank = 550
const Policy = "C2F_RECONSTRUCTION_V1"

type Catalog struct {
	SchemaVersion int                            `json:"schema_version"`
	PolicyID      string                         `json:"policy_id"`
	Tables        map[string][]map[string]string `json:"tables"`
}
type Family struct {
	ID, Level, Position, Special, Certificate, Compound, Heart, Hearts, ResolveCertificate, Resolve, Mana, Crystal int64
	Items, Weights                                                                                                 []int64
}
type Item struct {
	ID, Family, Position, Suit int64
	Display, Battle            map[int64]string
}

func ints(s string) []int64 {
	a := []int64{}
	for _, v := range strings.Split(s, "|") {
		n, e := strconv.ParseInt(v, 10, 64)
		if e == nil {
			a = append(a, n)
		}
	}
	return a
}
func num(r map[string]string, k string) int64 { n, _ := strconv.ParseInt(r[k], 10, 64); return n }
func (c Catalog) Family(id int64) (Family, bool) {
	for _, r := range c.Tables["inscription"] {
		if num(r, "id") == id {
			return Family{num(r, "id"), num(r, "level"), num(r, "item_pos"), num(r, "special"), num(r, "compound_material"), num(r, "compound_num"), num(r, "compound_item"), num(r, "compound_item_num"), num(r, "resolve_material"), num(r, "resolve_num"), num(r, "change_gold"), num(r, "change_crystal"), ints(r["item_id"]), ints(r["rand"])}, true
		}
	}
	return Family{}, false
}
func (c Catalog) Item(id int64) (Item, bool) {
	for _, r := range c.Tables["items"] {
		if num(r, "id") != id {
			continue
		}
		f, ok := c.Family(num(r, "inscript_id"))
		if !ok {
			return Item{}, false
		}
		pos := f.Position
		if pos == 0 {
			for _, p := range c.Tables["positions"] {
				for _, i := range ints(p["suit_items"]) {
					if i == id {
						pos = num(p, "id")
					}
				}
			}
		}
		o := Item{ID: id, Family: f.ID, Position: pos, Suit: num(r, "inscript_suit_id"), Display: map[int64]string{}, Battle: map[int64]string{}}
		ids := ints(r["attr_ids"])
		ds, bs := strings.Split(r["attr_values"], "|"), strings.Split(r["attr_battle"], "|")
		if len(ids) != len(ds) || len(ids) != len(bs) {
			return Item{}, false
		}
		for i, k := range ids {
			o.Display[k] = ds[i]
			o.Battle[k] = bs[i]
		}
		return o, true
	}
	return Item{}, false
}
func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != Policy || len(c.Tables["inscription"]) != 23 || len(c.Tables["items"]) != 240 || len(c.Tables["suits"]) != 12 || len(c.Tables["positions"]) != 3 || len(c.Tables["exchange_materials"]) != 3 {
		return ErrUnqualified
	}
	seen := map[int64]bool{}
	for _, r := range c.Tables["inscription"] {
		f, ok := c.Family(num(r, "id"))
		if !ok || len(f.Items) == 0 || len(f.Items) != len(f.Weights) || f.Level < 1 || f.Level > 7 {
			return ErrUnqualified
		}
		for i, id := range f.Items {
			it, ok := c.Item(id)
			if !ok || it.Family != f.ID || it.Position < 1 || it.Position > 3 || f.Weights[i] <= 0 || seen[id] {
				return ErrUnqualified
			}
			seen[id] = true
		}
	}
	if len(seen) != 240 {
		return ErrUnqualified
	}
	for _, r := range c.Tables["suits"] {
		slots := map[int64]bool{}
		for _, id := range ints(r["item_id"]) {
			it, ok := c.Item(id)
			if !ok || it.Suit != num(r, "id") || slots[it.Position] {
				return ErrUnqualified
			}
			slots[it.Position] = true
		}
		if len(slots) < 2 || len(slots) > 3 {
			return ErrUnqualified
		}
	}
	return nil
}
func Certificate(id int64) string {
	return map[int64]string{19: "degree_cer", 20: "graduate_cer", 21: "patent_cer"}[id]
}
func (c Catalog) Exchange() map[int64][2]int64 {
	o := map[int64][2]int64{}
	for _, r := range c.Tables["exchange_materials"] {
		v := ints(r["economic_value"])
		if len(v) == 2 && Certificate(v[0]) != "" {
			o[num(r, "id")] = [2]int64{v[0], v[1]}
		}
	}
	return o
}
func (c Catalog) RemoveCost() int64 {
	for _, r := range c.Tables["misc"] {
		if r["key"] == "remove_inscript_cost" {
			return num(r, "value")
		}
	}
	return 0
}
func (c Catalog) Support(f Family) []int64 {
	o := append([]int64{}, f.Items...)
	if f.Level == 7 {
		for _, id := range []int64{40001, 50001} {
			x, _ := c.Family(id)
			o = append(o, x.Items...)
		}
	}
	return o
}

// Draw uses stable operation labels/ordinals and unbiased bounded entropy. Lv1..6 never advance the special counter.
func below(op operation.Context, label string, ordinal uint64, n uint64) uint64 {
	for retry := uint64(0); ; retry++ {
		h := op.Derive(label+":"+strconv.FormatUint(retry, 10), ordinal)
		v := binary.BigEndian.Uint64(h[:8])
		limit := (-n) % n
		if v >= limit {
			return v % n
		}
	}
}
func weighted(op operation.Context, label string, ordinal uint64, ids, weights []int64, exclude int64) (int64, error) {
	sum := int64(0)
	for i, id := range ids {
		if id != exclude {
			sum += weights[i]
		}
	}
	if sum <= 0 {
		return 0, ErrUnqualified
	}
	v := int64(below(op, label, ordinal, uint64(sum)))
	for i, id := range ids {
		if id == exclude {
			continue
		}
		if v < weights[i] {
			return id, nil
		}
		v -= weights[i]
	}
	return 0, ErrUnqualified
}
func (c Catalog) Draw(f Family, lane string, misses, exclude int64, op operation.Context, ordinal uint64) (int64, int64, error) {
	if f.Special != 0 || misses < 0 {
		return 0, misses, ErrInvalid
	}
	step, ceiling := int64(10), int64(1000)
	if lane == "reforge" {
		step, ceiling = 100, 100
	} else if lane != "forge" {
		return 0, misses, ErrInvalid
	}
	if misses >= ceiling {
		return 0, misses, ErrUnqualified
	}
	prefix := "inscription." + lane
	next := misses
	if f.Level == 7 {
		attempt := misses + 1
		hit := attempt >= ceiling || int64(below(op, prefix+".gate", ordinal, 10000)) < attempt*step
		if hit {
			family, e := weighted(op, prefix+".family", ordinal, []int64{40001, 50001}, []int64{70, 30}, 0)
			if e != nil {
				return 0, misses, e
			}
			special, _ := c.Family(family)
			id, e := weighted(op, prefix+".special", ordinal, special.Items, special.Weights, 0)
			return id, 0, e
		}
		next++
	}
	id, e := weighted(op, prefix+".ordinary", ordinal, f.Items, f.Weights, exclude)
	return id, next, e
}

type Pending struct {
	Source                      int64
	Candidates                  []int64
	Generation                  int64
	Revision, Policy, Operation string
	Entropy                     [32]byte
	CreatedAt                   time.Time
}
type State struct {
	Policy                                 string
	ForgeMisses, ReforgeMisses, Generation int64
	Pending                                *Pending
}

func Seed() State { return State{Policy: Policy} }
func (s State) Clone() State {
	b, _ := json.Marshal(s)
	var o State
	_ = json.Unmarshal(b, &o)
	return o
}
func (s State) Validate(c Catalog) error {
	if s.Policy != Policy || s.ForgeMisses < 0 || s.ForgeMisses >= 1000 || s.ReforgeMisses < 0 || s.ReforgeMisses >= 100 || s.Generation < 0 {
		return ErrUnqualified
	}
	if p := s.Pending; p != nil {
		it, ok := c.Item(p.Source)
		f, _ := c.Family(it.Family)
		if !ok || f.Special != 0 || p.Generation != s.Generation || p.Generation <= 0 || len(p.Revision) != 64 || p.Policy != Policy || p.Operation == "" || p.CreatedAt.IsZero() || (len(p.Candidates) != 1 && len(p.Candidates) != 10) {
			return ErrUnqualified
		}
		support := map[int64]bool{}
		for _, id := range c.Support(f) {
			support[id] = true
		}
		for _, id := range p.Candidates {
			if !support[id] || id == p.Source {
				return ErrUnqualified
			}
		}
	}
	return nil
}

type HeroFacts struct{ Slots [3]int64 }

func SeedHero() HeroFacts { return HeroFacts{} }
func (h HeroFacts) Validate(c Catalog) error {
	for pos, id := range h.Slots {
		if id == 0 {
			continue
		}
		it, ok := c.Item(id)
		if !ok || it.Position != int64(pos+1) {
			return ErrUnqualified
		}
	}
	return nil
}
func (h HeroFacts) Wire() []int64 {
	o := []int64{}
	for _, id := range h.Slots {
		if id > 0 {
			o = append(o, id)
		}
	}
	return o
}
func (h HeroFacts) Suits(c Catalog) []int64 {
	o := []int64{}
	for _, r := range c.Tables["suits"] {
		on := true
		for _, id := range ints(r["item_id"]) {
			found := false
			for _, x := range h.Slots {
				found = found || x == id
			}
			on = on && found
		}
		if on {
			o = append(o, num(r, "id"))
		}
	}
	return o
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
