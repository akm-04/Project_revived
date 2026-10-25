// Package summon holds the pure Vending (gacha) rules (I9_GACHA_V1): the
// source buttons and pools, free timers, slot selection and the featured
// calendar. I9_GACHA_PRIVATE_POLICY_V1 (ported from V1) marks every rule the
// source does not carry; the original server math is UNKNOWN.
package summon

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
)

const (
	ContractID = "I9_GACHA_V1"
	PolicyID   = "I9_GACHA_PRIVATE_POLICY_V1"
)

// Families of summon.lua rows served by MID50 and MID70 (D138).
const (
	Small      = "small"
	MediumPaid = "medium_paid"
	MediumFree = "medium_free"
	Ticket     = "ticket"
	SX         = "sx"
	Magic      = "magic"
)

const (
	HeroKind = "hero"
	ItemKind = "item"
)

var (
	ErrUnavailable = errors.New("summon: unavailable")
	ErrInvalid     = errors.New("summon: invalid request")
	ErrRefused     = errors.New("summon: refused by rule")
)

type Button struct {
	Type    int64  `json:"type"`
	Index   int64  `json:"index"`
	Family  string `json:"family"`
	Pulls   int64  `json:"pulls"`
	Free    bool   `json:"free"`
	Mana    int64  `json:"mana"`
	Crystal int64  `json:"crystal"`
	ItemID  int64  `json:"item_id"`
	ItemNum int64  `json:"item_num"`
}

// Counter is a family's result-slot counter: slot n draws Pools[i] when n == Milestones[i].
type Counter struct {
	Milestones []int64 `json:"milestones"`
	Pools      []int64 `json:"pools"`
}

// Pool rows are [item_id, item_num, weight].
type Pool struct {
	ID   int64      `json:"id"`
	Kind string     `json:"kind"`
	Rows [][3]int64 `json:"rows"`
}

type Hero struct {
	TableID     int64 `json:"table_id"`
	InitialStar int64 `json:"initial_star"`
	StoneItemID int64 `json:"stone_item_id"`
	SX          bool  `json:"sx"`
}

type Family struct {
	BasePool     int64  `json:"base_pool"`
	SuperPool    int64  `json:"super_pool"`
	SuperChance  int64  `json:"super_chance_per_10000"`
	TenGuarantee string `json:"ten_guarantee"`
}

type Policy struct {
	Classic struct {
		Small          Family `json:"small"`
		Medium         Family `json:"medium"`
		MediumFeatured struct {
			Chance int64 `json:"chance_per_10000"`
			Pity   int64 `json:"pity_slots"`
		} `json:"medium_featured"`
		ExtensionWeight int64            `json:"medium_extension_weight"`
		Duplicates      map[string]int64 `json:"duplicate_fragments_by_initial_star"`
	} `json:"classic"`
	Tutorial struct {
		BirthCompanion          int64  `json:"birth_companion"`
		FirstSmallSlotRewardNum int64  `json:"first_small_slot_reward_num"`
		Rule                    string `json:"rule"`
	} `json:"tutorial"`
	// SX and Magic are typed by I9-3F, which serves them.
	SX      json.RawMessage `json:"sx"`
	Magic   json.RawMessage `json:"magic"`
	Display struct {
		ManaID int64 `json:"mana_id"`
		PetID  int64 `json:"pet_id"`
	} `json:"display"`
	Rotation struct {
		Seed       string `json:"seed"`
		SXMainDays int64  `json:"sx_main_days"`
	} `json:"rotation"`
	Cohorts struct {
		MediumFeatured  []int64 `json:"medium_featured"`
		MediumExtension []int64 `json:"medium_extension"`
		SX              []int64 `json:"sx"`
	} `json:"cohorts"`
}

type Catalog struct {
	SchemaVersion int64  `json:"schema_version"`
	ContractID    string `json:"contract_id"`
	PolicyID      string `json:"policy_id"`
	Free          struct {
		ManaPeriod    int64 `json:"mana_period"`
		ManaNum       int64 `json:"mana_num"`
		CrystalPeriod int64 `json:"crystal_period"`
		SXGuarantee   int64 `json:"sx_guarantee"`
	} `json:"free"`
	PolicySHA256 string `json:"policy_sha256"`
	// Reward is summon.lua row 1 summon_reward, paid with the first Small slot (D146).
	Reward struct {
		ItemID  int64 `json:"item_id"`
		ItemNum int64 `json:"item_num"`
	} `json:"reward"`
	Buttons  []Button           `json:"buttons"`
	Counters map[string]Counter `json:"counters"`
	Pools    []Pool             `json:"pools"`
	Heroes   []Hero             `json:"heroes"`
	Policy   Policy             `json:"policy"`
	// Soul caskets, the magic list and rates and vows are I9-3F inputs.
	SoulCaskets json.RawMessage `json:"soul_caskets"`
	MagicHeroes []int64         `json:"magic_heroes"`
	MagicRates  [][2]int64      `json:"magic_rates"`
	Vows        json.RawMessage `json:"vows"`

	pools  map[int64]Pool
	heroes map[int64]Hero
	tuning Tuning
}

// Validate indexes the catalog; installed revisions are immutable, so the
// cached copy shares its read-only indexes.
func (c *Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != ContractID || c.PolicyID != PolicyID || c.Free.ManaPeriod <= 0 || c.Free.ManaNum <= 0 || c.Free.CrystalPeriod <= 0 || c.Reward.ItemID <= 0 || c.Reward.ItemNum <= 0 {
		return errors.New("summon: catalog identity")
	}
	c.pools = make(map[int64]Pool, len(c.Pools))
	for _, p := range c.Pools {
		total := int64(0)
		for _, row := range p.Rows {
			total += row[2]
		}
		if total <= 0 || (p.Kind != HeroKind && p.Kind != ItemKind) {
			return fmt.Errorf("summon: pool %d profile", p.ID)
		}
		c.pools[p.ID] = p
	}
	c.heroes = make(map[int64]Hero, len(c.Heroes))
	for _, h := range c.Heroes {
		c.heroes[h.TableID] = h
	}
	for _, f := range []Family{c.Policy.Classic.Small, c.Policy.Classic.Medium} {
		if c.pools[f.BasePool].Kind != ItemKind || c.pools[f.SuperPool].Kind != HeroKind {
			return errors.New("summon: family pools")
		}
	}
	for _, counter := range c.Counters {
		if len(counter.Milestones) != len(counter.Pools) {
			return errors.New("summon: counter profile")
		}
		for _, id := range counter.Pools {
			if _, ok := c.pools[id]; !ok {
				return fmt.Errorf("summon: counter pool %d", id)
			}
		}
	}
	for _, p := range c.Pools {
		if p.Kind != HeroKind {
			continue
		}
		for _, row := range p.Rows {
			if _, err := c.Fragments(row[0]); err != nil {
				return err
			}
		}
	}
	if len(c.Policy.Cohorts.MediumFeatured) == 0 || c.Policy.Classic.MediumFeatured.Pity <= 0 || c.Policy.Rotation.SXMainDays <= 0 || len(c.Policy.Cohorts.SX) < 5 {
		return errors.New("summon: policy profile")
	}
	return nil
}

func (c *Catalog) Button(kind, index int64) (Button, bool) {
	for _, b := range c.Buttons {
		if b.Type == kind && b.Index == index {
			return b, true
		}
	}
	return Button{}, false
}

func (c *Catalog) Hero(id int64) (Hero, bool) {
	h, ok := c.heroes[id]
	return h, ok
}

// Fragments is the duplicate conversion of an owned hero: its stone, by initial star.
func (c *Catalog) Fragments(id int64) ([2]int64, error) {
	h, ok := c.heroes[id]
	count := c.Policy.Classic.Duplicates[strconv.FormatInt(h.InitialStar, 10)]
	if !ok || h.StoneItemID <= 0 || count <= 0 {
		return [2]int64{}, fmt.Errorf("summon: hero %d has no duplicate conversion", id)
	}
	return [2]int64{h.StoneItemID, count}, nil
}

// State is a player's summon row; NewState is the row of a player who never pulled.
type State struct {
	ManaFreeTime    int64
	ManaFreeNum     int64
	ManaFreeDay     int64
	CrystalFreeTime int64
	Counters        map[string]int64
	FeaturedTarget  int64
	FeaturedPity    int64
	SXTarget        int64
	SXPity          int64
	MagicTarget     int64
}

func (c *Catalog) NewState(day int64) State {
	return State{ManaFreeNum: c.Free.ManaNum, ManaFreeDay: day, Counters: map[string]int64{}}
}

// Refresh refills the Small free count on a new day (D140).
func (c *Catalog) Refresh(s State, day int64) State {
	if s.ManaFreeDay == day {
		return s
	}
	s.ManaFreeDay, s.ManaFreeNum = day, c.Free.ManaNum
	return s
}

// Admit spends a free button's allowance; paid buttons pass unchanged.
func (c *Catalog) Admit(b Button, s State, now, day int64) (State, error) {
	s = c.Refresh(s, day)
	if !b.Free {
		return s, nil
	}
	if b.Family == Small {
		if s.ManaFreeNum < 1 || !ready(s.ManaFreeTime, c.Free.ManaPeriod, now) {
			return s, ErrRefused
		}
		s.ManaFreeNum--
		s.ManaFreeTime = now
		return s, nil
	}
	if b.Family == MediumFree && ready(s.CrystalFreeTime, c.Free.CrystalPeriod, now) {
		s.CrystalFreeTime = now
		return s, nil
	}
	return s, ErrRefused
}

// ready follows SelfPlayer.recoverByTime: a zero time (never pulled) is ready.
func ready(last, period, now int64) bool {
	return last < 1 || now >= last+period
}

// Random is the per-operation derived stream (D145).
type Random interface {
	Uniform(uint64) uint64
}

// Slot is one result: a hero table id or an item stack. Special slots came from a milestone.
type Slot struct {
	Kind    string
	ItemID  int64
	ItemNum int64
	Special bool
}

func pick(p Pool, r Random) Slot {
	total := int64(0)
	for _, row := range p.Rows {
		total += row[2]
	}
	roll := int64(r.Uniform(uint64(total)))
	for _, row := range p.Rows {
		if roll < row[2] {
			return Slot{Kind: p.Kind, ItemID: row[0], ItemNum: row[1]}
		}
		roll -= row[2]
	}
	panic("summon: weighted pick overflow")
}

// extended adds the Medium extension cohort to the Medium hero pool (V1 Medium Legacy).
func (c *Catalog) extended(p Pool) Pool {
	present := make(map[int64]bool, len(p.Rows))
	rows := append([][3]int64(nil), p.Rows...)
	for _, row := range p.Rows {
		present[row[0]] = true
	}
	for _, id := range c.Policy.Cohorts.MediumExtension {
		if !present[id] {
			rows = append(rows, [3]int64{id, 1, c.Policy.Classic.ExtensionWeight})
		}
	}
	return Pool{ID: p.ID, Kind: p.Kind, Rows: rows}
}

func (c *Catalog) family(b Button) (Family, bool) {
	if b.Family == Small {
		return c.Policy.Classic.Small, false
	}
	return c.Policy.Classic.Medium, b.Family == MediumPaid || b.Family == Ticket
}

func (c *Catalog) ordinary(f Family, legacy bool, r Random) Slot {
	if int64(r.Uniform(10000)) >= f.SuperChance {
		return pick(c.pools[f.BasePool], r)
	}
	return c.guaranteed(f, HeroKind, legacy, r)
}

func (c *Catalog) guaranteed(f Family, kind string, legacy bool, r Random) Slot {
	if kind == ItemKind {
		return pick(c.pools[f.BasePool], r)
	}
	pool := c.pools[f.SuperPool]
	if legacy {
		pool = c.extended(pool)
	}
	return pick(pool, r)
}

// Draw selects the slots of one classic button (D141): a milestone special
// pool, else the Medium featured overlay (paid and tickets), else the two-stage
// ordinary pick; every full block of ten holds the family's guaranteed kind.
func (c *Catalog) Draw(b Button, s State, featured int64, r Random) ([]Slot, State, error) {
	if b.Family != Small && b.Family != MediumPaid && b.Family != MediumFree && b.Family != Ticket {
		return nil, s, ErrInvalid
	}
	f, legacy := c.family(b)
	counters := make(map[string]int64, len(s.Counters)+1)
	for k, v := range s.Counters {
		counters[k] = v
	}
	if legacy && s.FeaturedTarget != featured {
		s.FeaturedTarget, s.FeaturedPity = featured, 0
	}
	counter, counted := c.Counters[b.Family]
	overlay := c.Policy.Classic.MediumFeatured
	slots := make([]Slot, 0, b.Pulls)
	for i := int64(0); i < b.Pulls; i++ {
		if counted {
			counters[b.Family]++
			if pool, ok := counter.special(counters[b.Family]); ok {
				slot := pick(c.pools[pool], r)
				slot.Special = true
				slots = append(slots, slot)
				continue
			}
		}
		if legacy {
			hit := s.FeaturedPity+1 >= overlay.Pity || int64(r.Uniform(10000)) < overlay.Chance
			if hit {
				s.FeaturedPity = 0
				slots = append(slots, Slot{Kind: HeroKind, ItemID: featured, ItemNum: 1})
				continue
			}
			s.FeaturedPity++
		}
		slots = append(slots, c.ordinary(f, legacy, r))
	}
	if b.Pulls%10 == 0 {
		want := HeroKind
		if f.TenGuarantee == ItemKind {
			want = ItemKind
		}
		for start := 0; start < len(slots); start += 10 {
			guaranteeBlock(slots[start:start+10], want, func() Slot { return c.guaranteed(f, want, legacy, r) })
		}
	}
	s.Counters = counters
	return slots, s, nil
}

// guaranteeBlock replaces the last non-special slot when the block lacks the wanted kind.
func guaranteeBlock(block []Slot, want string, draw func() Slot) {
	for _, slot := range block {
		if slot.Kind == want {
			return
		}
	}
	for i := len(block) - 1; i >= 0; i-- {
		if !block[i].Special {
			block[i] = draw()
			return
		}
	}
}

func (c Counter) special(n int64) (int64, bool) {
	for i, m := range c.Milestones {
		if m == n {
			return c.Pools[i], true
		}
	}
	return 0, false
}

// Rotation is the featured calendar shown on MID56 (D142).
type Rotation struct {
	Partner int64
	Main    []int64
	Second  []int64
}

func (c *Catalog) Rotation(day int64) Rotation {
	block := day / c.Policy.Rotation.SXMainDays
	main := c.choose("sx-main", block, c.Policy.Cohorts.SX, 2, nil)
	r := Rotation{
		Partner: c.choose("medium-featured", day, c.Policy.Cohorts.MediumFeatured, 1, nil)[0],
		Main:    main,
		Second:  c.choose("sx-second", day, c.Policy.Cohorts.SX, 3, main),
	}
	if c.tuning.Partner > 0 {
		r.Partner = c.tuning.Partner
	}
	if len(c.tuning.Main) > 0 {
		r.Main, r.Second = c.tuning.Main, c.tuning.Second
	}
	return r
}

// choose draws n distinct cohort members by a fixed-seed hash of label and period.
func (c *Catalog) choose(label string, period int64, cohort []int64, n int, exclude []int64) []int64 {
	taken := map[int64]bool{}
	for _, id := range exclude {
		taken[id] = true
	}
	out := make([]int64, 0, n)
	for i := uint64(0); len(out) < n; i++ {
		var b [16]byte
		binary.BigEndian.PutUint64(b[:8], uint64(period))
		binary.BigEndian.PutUint64(b[8:], i)
		sum := sha256.Sum256(append([]byte(c.Policy.Rotation.Seed+"/"+label+"/"), b[:]...))
		id := cohort[binary.BigEndian.Uint64(sum[:8])%uint64(len(cohort))]
		if !taken[id] {
			taken[id] = true
			out = append(out, id)
		}
	}
	return out
}
