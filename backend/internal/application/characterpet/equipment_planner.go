package characterpet

import (
	"errors"
	"fmt"
	"math"
	"sort"

	"gxb.local/backend/v2/internal/domain/character"
)

// Source literal sequence. src_64 traverses the Lua table with pairs, so this
// exact order is a Pass549 compatibility policy, not an original-server fact.
var petEquipmentPotionOrder = [...]int64{50001087, 50001088, 50001089}

type petEquipmentRecipeNode struct {
	Primitive character.EquipmentPrimitive
	Edges     []character.EquipmentRecipeEdge
}

type petEquipmentPlanningSnapshot struct {
	PlayerLevel int64
	Mana        int64
	Stacks      map[int64]int64
}

type petEquipmentPlan struct {
	Selected         []int64
	ManaDebit        int64
	StackDebits      map[int64]int64
	PotionDebits     map[int64]int64
	PotionEXPGranted int64
	MaxEXPShortfall  int64
}

func (p petEquipmentPlan) noWork() bool { return len(p.Selected) == 0 }

func petCheckedAdd64(a, b int64) (int64, error) {
	if b > 0 && a > math.MaxInt64-b {
		return 0, errors.New("character pet: equipment planner integer overflow")
	}
	if b < 0 && a < math.MinInt64-b {
		return 0, errors.New("character pet: equipment planner integer underflow")
	}
	return a + b, nil
}

func petCheckedMul64(a, b int64) (int64, error) {
	if a < 0 || b < 0 {
		return 0, errors.New("character pet: equipment planner negative multiplication")
	}
	if a != 0 && b > math.MaxInt64/a {
		return 0, errors.New("character pet: equipment planner multiplication overflow")
	}
	return a * b, nil
}

func validateCompatibilityThresholds(maxLevel int64, thresholds []character.EquipmentCompatibilityExpThreshold) error {
	return character.ValidateEquipmentCompatibilityExpThresholds(thresholds, maxLevel)
}

func petEquipmentExpShortfall(p character.Pet, requiredLevel, maxLevel int64, thresholds []character.EquipmentCompatibilityExpThreshold) (int64, error) {
	if requiredLevel <= p.Level {
		return 0, nil
	}
	if requiredLevel <= 1 || requiredLevel > maxLevel {
		return 0, errors.New("character pet: invalid equipment required level")
	}
	if err := validateCompatibilityThresholds(maxLevel, thresholds); err != nil {
		return 0, err
	}
	// partnerExp rows are cumulative EXP-to-next-level thresholds. To be level R,
	// the stock planner compares against the cumulative row for R-1.
	target := thresholds[requiredLevel-2].TotalExp
	if p.Exp >= target {
		return 0, nil
	}
	return target - p.Exp, nil
}

func petStackQuantity(stacks map[int64]int64, itemID int64) int64 {
	q := stacks[itemID]
	if q < 0 {
		return 0
	}
	return q
}

func reservePetEquipmentTarget(itemID int64, nodes map[int64]petEquipmentRecipeNode, stacks map[int64]int64, global, local map[int64]int64, path map[int64]bool) (int64, error) {
	if itemID <= 0 {
		return 0, errors.New("character pet: invalid equipment recipe item")
	}
	if path[itemID] {
		return 0, fmt.Errorf("character pet: equipment recipe cycle at %d", itemID)
	}
	node, ok := nodes[itemID]
	if !ok {
		return 0, fmt.Errorf("character pet: missing equipment primitive %d", itemID)
	}
	if err := node.Primitive.Validate(); err != nil {
		return 0, err
	}
	used, err := petCheckedAdd64(global[itemID], local[itemID])
	if err != nil {
		return 0, err
	}
	qty := petStackQuantity(stacks, itemID)
	// Source equality semantics: if an unreserved finished copy exists (qty !=
	// reservations at this step), reserve it. Only exact equality recurses.
	if len(node.Edges) == 0 || qty != used {
		local[itemID], err = petCheckedAdd64(local[itemID], 1)
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
			return 0, errors.New("character pet: non-canonical equipment recipe edge")
		}
		for n := int64(0); n < edge.ComponentCount; n++ {
			add, err := reservePetEquipmentTarget(int64(edge.ComponentItemID), nodes, stacks, global, local, path)
			if err != nil {
				return 0, err
			}
			mana, err = petCheckedAdd64(mana, add)
			if err != nil {
				return 0, err
			}
		}
	}
	return mana, nil
}

func petLocalReservationFits(local, global, stacks map[int64]int64) bool {
	for itemID, count := range local {
		available := petStackQuantity(stacks, itemID) - global[itemID]
		if count > available {
			return false
		}
	}
	return true
}

func totalPetPotionEXP(stacks map[int64]int64, potionEXP map[int64]int64) (int64, error) {
	var total int64
	for _, id := range petEquipmentPotionOrder {
		unit := potionEXP[id]
		if unit <= 0 {
			return 0, fmt.Errorf("character pet: missing EXP potion content %d", id)
		}
		v, err := petCheckedMul64(petStackQuantity(stacks, id), unit)
		if err != nil {
			return 0, err
		}
		total, err = petCheckedAdd64(total, v)
		if err != nil {
			return 0, err
		}
	}
	return total, nil
}

func planPetPotionDebit(shortfall int64, stacks map[int64]int64, potionEXP map[int64]int64) (map[int64]int64, int64, error) {
	out := map[int64]int64{}
	if shortfall <= 0 {
		return out, 0, nil
	}
	remaining := shortfall
	var granted int64
	for _, id := range petEquipmentPotionOrder {
		unit := potionEXP[id]
		if unit <= 0 {
			return nil, 0, fmt.Errorf("character pet: missing EXP potion content %d", id)
		}
		qty := petStackQuantity(stacks, id)
		if qty == 0 {
			continue
		}
		capacity, err := petCheckedMul64(qty, unit)
		if err != nil {
			return nil, 0, err
		}
		use := qty
		if remaining <= capacity {
			use = (remaining + unit - 1) / unit
		}
		if use <= 0 {
			continue
		}
		out[id] = use
		add, err := petCheckedMul64(use, unit)
		if err != nil {
			return nil, 0, err
		}
		granted, err = petCheckedAdd64(granted, add)
		if err != nil {
			return nil, 0, err
		}
		if remaining <= add {
			remaining = 0
			break
		}
		remaining -= add
	}
	if remaining != 0 {
		return nil, 0, errors.New("character pet: insufficient EXP potion value after planner precheck")
	}
	return out, granted, nil
}

func planPetOneKeyEquipment(p character.Pet, positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition, nodes map[int64]petEquipmentRecipeNode, snap petEquipmentPlanningSnapshot, maxLevel int64, compatibility []character.EquipmentCompatibilityExpThreshold, potionEXP map[int64]int64) (petEquipmentPlan, error) {
	if err := p.ValidatePersistent(); err != nil {
		return petEquipmentPlan{}, err
	}
	if !p.IsShow || snap.PlayerLevel <= 0 || snap.Mana < 0 || maxLevel <= 0 {
		return petEquipmentPlan{}, errors.New("character pet: invalid equipment planning snapshot")
	}
	if err := validateCompatibilityThresholds(maxLevel, compatibility); err != nil {
		return petEquipmentPlan{}, err
	}
	potionTotal, err := totalPetPotionEXP(snap.Stacks, potionEXP)
	if err != nil {
		return petEquipmentPlan{}, err
	}
	out := petEquipmentPlan{StackDebits: map[int64]int64{}, PotionDebits: map[int64]int64{}}
	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		if p.Equipment[slot-1] != 0 {
			continue
		}
		pos := positions[slot-1]
		if err := pos.Validate(); err != nil {
			return petEquipmentPlan{}, err
		}
		if pos.PetTableID != p.TableID || pos.Color != p.Color || pos.Slot != slot || !pos.ItemID.Valid() || pos.Classification != character.PetEquipmentOrdinary {
			continue
		}
		node, ok := nodes[int64(pos.ItemID)]
		if !ok {
			return petEquipmentPlan{}, fmt.Errorf("character pet: missing slot primitive %d", pos.ItemID)
		}
		if node.Primitive.SourceItemType != 8 || node.Primitive.RequiredLevel > maxLevel {
			continue
		}
		local := map[int64]int64{}
		candidateMana, err := reservePetEquipmentTarget(int64(pos.ItemID), nodes, snap.Stacks, out.StackDebits, local, map[int64]bool{})
		if err != nil {
			return petEquipmentPlan{}, err
		}
		if candidateMana > snap.Mana-out.ManaDebit || !petLocalReservationFits(local, out.StackDebits, snap.Stacks) {
			continue
		}
		shortfall, err := petEquipmentExpShortfall(p, node.Primitive.RequiredLevel, maxLevel, compatibility)
		if err != nil {
			return petEquipmentPlan{}, err
		}
		if shortfall > potionTotal {
			continue
		}
		out.Selected = append(out.Selected, slot)
		out.ManaDebit, err = petCheckedAdd64(out.ManaDebit, candidateMana)
		if err != nil {
			return petEquipmentPlan{}, err
		}
		for itemID, count := range local {
			out.StackDebits[itemID], err = petCheckedAdd64(out.StackDebits[itemID], count)
			if err != nil {
				return petEquipmentPlan{}, err
			}
		}
		if shortfall > out.MaxEXPShortfall {
			out.MaxEXPShortfall = shortfall
		}
	}
	if len(out.Selected) == 0 {
		return out, nil
	}
	potions, granted, err := planPetPotionDebit(out.MaxEXPShortfall, snap.Stacks, potionEXP)
	if err != nil {
		return petEquipmentPlan{}, err
	}
	out.PotionDebits = potions
	out.PotionEXPGranted = granted
	for id, count := range potions {
		out.StackDebits[id], err = petCheckedAdd64(out.StackDebits[id], count)
		if err != nil {
			return petEquipmentPlan{}, err
		}
	}
	return out, nil
}

func sortedPetEquipmentStackDebits(m map[int64]int64) []struct{ ItemID, Count int64 } {
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
