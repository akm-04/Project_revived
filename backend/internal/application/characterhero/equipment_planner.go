package characterhero

import (
	"errors"
	"fmt"
	"math"
	"sort"

	"gxb.local/backend/v2/internal/domain/character"
)

// Source literal order from HeroMainWindow.checkOneKeyEquips. The current Lua
// iterates this table with pairs, so the ordering is a CA4-2 compatibility
// decision rather than an original-server fact.
var heroEquipmentPotionOrder = [...]int64{50001001, 50001002, 50001004, 50001005, 50005182}

type heroEquipmentRecipeNode struct {
	Primitive character.EquipmentPrimitive
	Edges     []character.EquipmentRecipeEdge
}

type heroEquipmentPlanningSnapshot struct {
	PlayerLevel int64
	Mana        int64
	Stacks      map[int64]int64
}

type heroEquipmentPlan struct {
	Selected         []int64
	ManaDebit        int64
	StackDebits      map[int64]int64
	PotionDebits     map[int64]int64
	PotionEXPGranted int64
	MaxEXPShortfall  int64
}

func (p heroEquipmentPlan) noWork() bool { return len(p.Selected) == 0 }

func checkedAdd64(a, b int64) (int64, error) {
	if b > 0 && a > math.MaxInt64-b {
		return 0, errors.New("character hero: equipment planner integer overflow")
	}
	if b < 0 && a < math.MinInt64-b {
		return 0, errors.New("character hero: equipment planner integer underflow")
	}
	return a + b, nil
}

func checkedMul64(a, b int64) (int64, error) {
	if a < 0 || b < 0 {
		return 0, errors.New("character hero: equipment planner negative multiplication")
	}
	if a != 0 && b > math.MaxInt64/a {
		return 0, errors.New("character hero: equipment planner multiplication overflow")
	}
	return a * b, nil
}

func validateEquipmentThresholds(maxLevel int64, thresholds []character.HeroExpThreshold) error {
	if maxLevel <= 0 || int64(len(thresholds)) != maxLevel {
		return errors.New("character hero: invalid equipment EXP thresholds")
	}
	prev := int64(-1)
	for i, x := range thresholds {
		if x.Level != int64(i+1) || x.TotalExp < 0 || x.TotalExp < prev {
			return errors.New("character hero: invalid equipment EXP threshold ordering")
		}
		prev = x.TotalExp
	}
	return nil
}

func expShortfallForLevel(h character.Hero, requiredLevel int64, maxLevel int64, thresholds []character.HeroExpThreshold) (int64, error) {
	if requiredLevel <= h.Level {
		return 0, nil
	}
	if requiredLevel <= 1 || requiredLevel > maxLevel {
		return 0, errors.New("character hero: invalid equipment required level")
	}
	if err := validateEquipmentThresholds(maxLevel, thresholds); err != nil {
		return 0, err
	}
	// Existing progression thresholds are cumulative EXP needed to advance from
	// level N to N+1. To be level R, cumulative EXP must reach threshold R-1.
	target := thresholds[requiredLevel-2].TotalExp
	if h.Exp >= target {
		return 0, nil
	}
	return target - h.Exp, nil
}

func stackQuantity(stacks map[int64]int64, itemID int64) int64 {
	q := stacks[itemID]
	if q < 0 {
		return 0
	}
	return q
}

// reserveEquipmentTarget reproduces current src_64 recursion for one slot. It
// prefers an unreserved finished target copy; once finished stock equals prior
// reservations it recursively synthesizes one target, preserving ordered
// duplicate recipe edges and charging ComposeMana once per synthesized node.
func reserveEquipmentTarget(itemID int64, nodes map[int64]heroEquipmentRecipeNode, stacks map[int64]int64, global, local map[int64]int64, path map[int64]bool) (int64, error) {
	if itemID <= 0 {
		return 0, errors.New("character hero: invalid equipment recipe item")
	}
	if path[itemID] {
		return 0, fmt.Errorf("character hero: equipment recipe cycle at %d", itemID)
	}
	node, ok := nodes[itemID]
	if !ok {
		return 0, fmt.Errorf("character hero: missing equipment primitive %d", itemID)
	}
	if err := node.Primitive.Validate(); err != nil {
		return 0, err
	}
	used, err := checkedAdd64(global[itemID], local[itemID])
	if err != nil {
		return 0, err
	}
	qty := stackQuantity(stacks, itemID)
	if len(node.Edges) == 0 || qty != used {
		local[itemID], err = checkedAdd64(local[itemID], 1)
		return 0, err
	}

	path[itemID] = true
	defer delete(path, itemID)
	mana := node.Primitive.ComposeMana
	for i, edge := range node.Edges {
		if err := edge.Validate(); err != nil {
			return 0, err
		}
		if edge.ParentItemID != node.Primitive.ItemID || edge.Ordinal != int64(i+1) {
			return 0, errors.New("character hero: non-canonical equipment recipe edge")
		}
		for n := int64(0); n < edge.ComponentCount; n++ {
			add, err := reserveEquipmentTarget(int64(edge.ComponentItemID), nodes, stacks, global, local, path)
			if err != nil {
				return 0, err
			}
			mana, err = checkedAdd64(mana, add)
			if err != nil {
				return 0, err
			}
		}
	}
	return mana, nil
}

func localReservationFits(local, global, stacks map[int64]int64) bool {
	for itemID, count := range local {
		available := stackQuantity(stacks, itemID) - global[itemID]
		if count > available {
			return false
		}
	}
	return true
}

func totalPotionEXP(stacks map[int64]int64, potionEXP map[int64]int64) (int64, error) {
	var total int64
	for _, id := range heroEquipmentPotionOrder {
		unit := potionEXP[id]
		if unit <= 0 {
			return 0, fmt.Errorf("character hero: missing EXP potion content %d", id)
		}
		v, err := checkedMul64(stackQuantity(stacks, id), unit)
		if err != nil {
			return 0, err
		}
		total, err = checkedAdd64(total, v)
		if err != nil {
			return 0, err
		}
	}
	return total, nil
}

func planPotionDebit(shortfall int64, stacks map[int64]int64, potionEXP map[int64]int64) (map[int64]int64, int64, error) {
	out := map[int64]int64{}
	if shortfall <= 0 {
		return out, 0, nil
	}
	remaining := shortfall
	var granted int64
	for _, id := range heroEquipmentPotionOrder {
		unit := potionEXP[id]
		if unit <= 0 {
			return nil, 0, fmt.Errorf("character hero: missing EXP potion content %d", id)
		}
		qty := stackQuantity(stacks, id)
		if qty == 0 {
			continue
		}
		capacity, err := checkedMul64(qty, unit)
		if err != nil {
			return nil, 0, err
		}
		use := qty
		if remaining <= capacity {
			use = (remaining + unit - 1) / unit
		}
		if use > 0 {
			out[id] = use
			add, err := checkedMul64(use, unit)
			if err != nil {
				return nil, 0, err
			}
			granted, err = checkedAdd64(granted, add)
			if err != nil {
				return nil, 0, err
			}
			if remaining <= add {
				remaining = 0
				break
			}
			remaining -= add
		}
	}
	if remaining != 0 {
		return nil, 0, errors.New("character hero: insufficient EXP potion value after planner precheck")
	}
	return out, granted, nil
}

// planOneKeyEquipment is pure with respect to player state. Positions/nodes are
// immutable content and snap is the canonical I5 snapshot captured under locks.
func planOneKeyEquipment(h character.Hero, positions [character.HeroEquipmentSlotCount]character.HeroEquipmentPosition, nodes map[int64]heroEquipmentRecipeNode, snap heroEquipmentPlanningSnapshot, maxLevel int64, thresholds []character.HeroExpThreshold, potionEXP map[int64]int64) (heroEquipmentPlan, error) {
	if err := h.ValidatePersistent(); err != nil {
		return heroEquipmentPlan{}, err
	}
	if err := h.Equipment.ValidateNormal(); err != nil {
		return heroEquipmentPlan{}, err
	}
	if snap.PlayerLevel <= 0 || snap.Mana < 0 || maxLevel <= 0 {
		return heroEquipmentPlan{}, errors.New("character hero: invalid equipment planning snapshot")
	}
	if err := validateEquipmentThresholds(maxLevel, thresholds); err != nil {
		return heroEquipmentPlan{}, err
	}
	potionTotal, err := totalPotionEXP(snap.Stacks, potionEXP)
	if err != nil {
		return heroEquipmentPlan{}, err
	}

	out := heroEquipmentPlan{StackDebits: map[int64]int64{}, PotionDebits: map[int64]int64{}}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		cur, _ := h.Equipment.Value(slot)
		if cur != 0 {
			continue
		}
		pos := positions[slot-1]
		if err := pos.Validate(); err != nil {
			return heroEquipmentPlan{}, err
		}
		if pos.HeroTableID != h.TableID || pos.Color != h.Color || pos.Slot != slot || !pos.ItemID.Valid() || !pos.OrdinaryEligible {
			continue
		}
		node, ok := nodes[int64(pos.ItemID)]
		if !ok {
			return heroEquipmentPlan{}, fmt.Errorf("character hero: missing slot primitive %d", pos.ItemID)
		}
		if node.Primitive.RequiredLevel > maxLevel {
			continue
		}
		local := map[int64]int64{}
		candidateMana, err := reserveEquipmentTarget(int64(pos.ItemID), nodes, snap.Stacks, out.StackDebits, local, map[int64]bool{})
		if err != nil {
			return heroEquipmentPlan{}, err
		}
		if candidateMana > snap.Mana-out.ManaDebit || !localReservationFits(local, out.StackDebits, snap.Stacks) {
			continue
		}
		shortfall, err := expShortfallForLevel(h, node.Primitive.RequiredLevel, maxLevel, thresholds)
		if err != nil {
			return heroEquipmentPlan{}, err
		}
		if shortfall > potionTotal {
			continue
		}
		out.Selected = append(out.Selected, slot)
		out.ManaDebit, err = checkedAdd64(out.ManaDebit, candidateMana)
		if err != nil {
			return heroEquipmentPlan{}, err
		}
		for itemID, count := range local {
			out.StackDebits[itemID], err = checkedAdd64(out.StackDebits[itemID], count)
			if err != nil {
				return heroEquipmentPlan{}, err
			}
		}
		if shortfall > out.MaxEXPShortfall {
			out.MaxEXPShortfall = shortfall
		}
	}
	if len(out.Selected) == 0 {
		return out, nil
	}
	potions, granted, err := planPotionDebit(out.MaxEXPShortfall, snap.Stacks, potionEXP)
	if err != nil {
		return heroEquipmentPlan{}, err
	}
	out.PotionDebits = potions
	out.PotionEXPGranted = granted
	for id, count := range potions {
		out.StackDebits[id], err = checkedAdd64(out.StackDebits[id], count)
		if err != nil {
			return heroEquipmentPlan{}, err
		}
	}
	return out, nil
}

func sortedEquipmentStackDebits(m map[int64]int64) []struct{ ItemID, Count int64 } {
	ids := make([]int64, 0, len(m))
	for id, count := range m {
		if count > 0 {
			ids = append(ids, id)
		}
	}
	sort.Slice(ids, func(i, j int) bool { return fmt.Sprintf("%d", ids[i]) < fmt.Sprintf("%d", ids[j]) })
	out := make([]struct{ ItemID, Count int64 }, 0, len(ids))
	for _, id := range ids {
		out = append(out, struct{ ItemID, Count int64 }{id, m[id]})
	}
	return out
}
