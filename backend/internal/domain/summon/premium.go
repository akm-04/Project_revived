package summon

import (
	"errors"
	"fmt"
	"slices"
)

// SXPolicy is V1 sx_private_v2: the dynamic sixth slot of a type 4 pull.
type SXPolicy struct {
	ClassWeights  map[string]int64 `json:"class_weights"`
	HotspotPity   int64            `json:"hotspot_pity"`
	HotspotShare  int64            `json:"hotspot_share_per_10000"`
	NewerSXWeight int64            `json:"newer_sx_weight"`
	VIPMin        int64            `json:"vip_min"`
}

// MagicPolicy is V1 magic v1: byproduct rolls and the single pull's fixed target fragments.
type MagicPolicy struct {
	SingleFragments int64 `json:"single_fragments"`
	SingleRolls     int64 `json:"single_rolls"`
	TenRolls        int64 `json:"ten_rolls"`
}

// Casket is a soul_casket.lua row: type 1 SX weights, 2 and 5 fragment bundles, 6 ordinary heroes.
type Casket struct {
	ID        int64   `json:"id"`
	PartnerID int64   `json:"partner_id"`
	Type      int64   `json:"type"`
	RollNums  []int64 `json:"roll_nums"`
	NumRates  []int64 `json:"num_rates"`
	Weight    int64   `json:"weight"`
}

// Vows is the MID306 exchange: essence per scroll of a super_partner (Vows) hero.
type Vows struct {
	EssenceItemID int64   `json:"essence_item_id"`
	ScrollCost    int64   `json:"super_scroll_cost"`
	TableIDs      []int64 `json:"table_ids"`
}

const sxFullHero = 1

// sxClasses lists the dynamic classes in a fixed order with the casket type each draws.
var sxClasses = []struct {
	name   string
	casket int64
}{{"sx_full_hero", sxFullHero}, {"normal_three_star_fragments", 2}, {"normal_two_star_fragments", 5}, {"ordinary_full_hero", 6}}

func (c *Catalog) validatePremium() error {
	for _, id := range append(slices.Clone(c.SXPools), c.MagicPool) {
		if c.pools[id].Kind != ItemKind {
			return fmt.Errorf("summon: premium pool %d", id)
		}
	}
	if err := validClassWeights(c.Policy.SX.ClassWeights); err != nil {
		return err
	}
	for _, class := range sxClasses[1:] {
		if len(c.caskets(class.casket)) == 0 {
			return fmt.Errorf("summon: soul casket type %d empty", class.casket)
		}
	}
	for _, row := range c.SoulCaskets {
		if row.Weight <= 0 || row.Type == sxFullHero {
			continue
		}
		if _, err := c.Fragments(row.PartnerID); err != nil {
			return err
		}
		if row.Type != 6 && casketQuantityTotal(row) <= 0 {
			return fmt.Errorf("summon: soul casket %d quantity", row.ID)
		}
	}
	for _, id := range c.MagicHeroes {
		if _, ok := c.MagicFragment(id); !ok {
			return fmt.Errorf("summon: magic target %d", id)
		}
	}
	for _, id := range c.Vows.TableIDs {
		if _, ok := c.VowsScroll(id); !ok {
			return fmt.Errorf("summon: Vows hero %d", id)
		}
	}
	m := c.Policy.Magic
	if len(c.SXPools) == 0 || m.SingleRolls <= 0 || m.TenRolls <= 0 || m.SingleFragments <= 0 || len(c.MagicRates) == 0 || len(c.Vows.TableIDs) == 0 || c.Vows.EssenceItemID <= 0 || c.Vows.ScrollCost <= 0 || c.Policy.SX.NewerSXWeight <= 0 || c.Policy.SX.VIPMin < 0 {
		return errors.New("summon: premium profile")
	}
	return nil
}

func validClassWeights(weights map[string]int64) error {
	total := int64(0)
	for _, class := range sxClasses {
		w, ok := weights[class.name]
		if !ok || w < 0 {
			return fmt.Errorf("summon: SX class %s", class.name)
		}
		total += w
	}
	if total <= 0 || len(weights) != len(sxClasses) {
		return errors.New("summon: SX class weights")
	}
	return nil
}

func casketQuantityTotal(row Casket) int64 {
	if len(row.RollNums) != len(row.NumRates) {
		return 0
	}
	total := int64(0)
	for i, n := range row.RollNums {
		if n > 0 {
			total += row.NumRates[i]
		}
	}
	return total
}

func (c *Catalog) caskets(kind int64) []Casket {
	out := []Casket{}
	for _, row := range c.SoulCaskets {
		if row.Type == kind && row.Weight > 0 {
			out = append(out, row)
		}
	}
	return out
}

// MagicFragment is the stone a Magic target's fragments are paid in; false when the id is not a target.
func (c *Catalog) MagicFragment(id int64) (int64, bool) {
	h, ok := c.heroes[id]
	if !ok || h.StoneItemID <= 0 || !slices.Contains(c.MagicHeroes, id) {
		return 0, false
	}
	return h.StoneItemID, true
}

// VowsScroll is the scroll MID306 pays for a Vows hero; false when the id is not one.
func (c *Catalog) VowsScroll(id int64) (int64, bool) {
	h, ok := c.heroes[id]
	if !ok || h.StoneItemID <= 0 || !slices.Contains(c.Vows.TableIDs, id) {
		return 0, false
	}
	return h.StoneItemID, true
}

// DrawSX is one type 4 purchase: one item from each static pool, then the
// dynamic slot. The hotspot pity counts purchases without the hotspot and
// restarts when the selected hotspot changes; the HotspotPity-th miss is forced.
func (c *Catalog) DrawSX(s State, hotspot int64, r Random) ([]Slot, State) {
	slots := make([]Slot, 0, len(c.SXPools)+1)
	for _, id := range c.SXPools {
		slots = append(slots, pick(c.pools[id], r))
	}
	if s.SXTarget != hotspot {
		s.SXTarget, s.SXPity = hotspot, 0
	}
	forced := s.SXPity+1 >= c.Policy.SX.HotspotPity
	class := int64(sxFullHero)
	if !forced {
		class = c.sxClass(r)
	}
	if class != sxFullHero {
		s.SXPity++
		return append(slots, c.casketSlot(class, r)), s
	}
	hero := hotspot
	if !forced && int64(r.Uniform(10000)) >= c.Policy.SX.HotspotShare {
		hero = pick(c.sxRoster(hotspot), r).ItemID
	}
	s.SXPity++
	if hero == hotspot {
		s.SXPity = 0
	}
	return append(slots, Slot{Kind: HeroKind, ItemID: hero, ItemNum: 1}), s
}

func (c *Catalog) sxClass(r Random) int64 {
	rows := make([][3]int64, 0, len(sxClasses))
	for _, class := range sxClasses {
		rows = append(rows, [3]int64{class.casket, 1, c.Policy.SX.ClassWeights[class.name]})
	}
	return pick(Pool{Rows: rows}, r).ItemID
}

// sxRoster is the SX cohort without the hotspot, weighted by soul_casket type 1 or the newer-SX fallback.
func (c *Catalog) sxRoster(hotspot int64) Pool {
	weights := map[int64]int64{}
	for _, row := range c.caskets(sxFullHero) {
		weights[row.PartnerID] = row.Weight
	}
	rows := [][3]int64{}
	for _, id := range c.Policy.Cohorts.SX {
		w, ok := weights[id]
		if !ok {
			w = c.Policy.SX.NewerSXWeight
		}
		if id != hotspot {
			rows = append(rows, [3]int64{id, 1, w})
		}
	}
	return Pool{Kind: HeroKind, Rows: rows}
}

// casketSlot draws a soul_casket row: type 6 is a whole hero, types 2 and 5 its stone fragments.
func (c *Catalog) casketSlot(kind int64, r Random) Slot {
	candidates := c.caskets(kind)
	rows := make([][3]int64, 0, len(candidates))
	for i, row := range candidates {
		rows = append(rows, [3]int64{int64(i), 1, row.Weight})
	}
	row := candidates[pick(Pool{Rows: rows}, r).ItemID]
	if kind == 6 {
		return Slot{Kind: HeroKind, ItemID: row.PartnerID, ItemNum: 1}
	}
	quantities := [][3]int64{}
	for i, n := range row.RollNums {
		if n > 0 {
			quantities = append(quantities, [3]int64{n, 1, row.NumRates[i]})
		}
	}
	return Slot{Kind: ItemKind, ItemID: c.heroes[row.PartnerID].StoneItemID, ItemNum: pick(Pool{Rows: quantities}, r).ItemID}
}

// DrawMagic is one Magic purchase: byproduct item slots and the target fragment count
// (fixed for a single pull, magic_drop_rate for ten).
func (c *Catalog) DrawMagic(b Button, r Random) ([]Slot, int64) {
	m := c.Policy.Magic
	rolls, fragments := m.SingleRolls, m.SingleFragments
	if b.Pulls == 10 {
		rows := make([][3]int64, 0, len(c.MagicRates))
		for _, rate := range c.MagicRates {
			rows = append(rows, [3]int64{rate[0], 1, rate[1]})
		}
		rolls, fragments = m.TenRolls, pick(Pool{Rows: rows}, r).ItemID
	}
	slots := make([]Slot, 0, rolls)
	for range rolls {
		slots = append(slots, pick(c.pools[c.MagicPool], r))
	}
	return slots, fragments
}
