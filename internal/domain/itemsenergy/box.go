package itemsenergy

// BoxPlan is one validated MID 241 open before entropy is consumed. Units are
// the gift's repeated boxes in request order; each unit's DropGroups are the
// gift.drops entries in source order.
type BoxPlan struct {
	Item  Item
	Gift  Gift
	Num   int64
	Units [][]Dropbox
}

// StackReward, ScalarReward and TemporalReward are owner-neutral reward rows.
type StackReward struct{ ItemID, Amount int64 }
type ScalarReward struct {
	ResourceKey string
	Amount      int64
}
type TemporalReward struct {
	ResourceKey string
	Amount      int64
}
type FixedAward struct{ TableID, ItemNum int64 }

// Rewards is the union of one box's gift rows for every unit, plus the drops
// rolled by the caller in unit order.
type Rewards struct {
	Stacks    []StackReward
	Scalars   []ScalarReward
	Temporals []TemporalReward
	PlayerExp int64
	Heroes    []int64
	Awards    []FixedAward
}

func (r *Rewards) Add(other Rewards) {
	r.Stacks = append(r.Stacks, other.Stacks...)
	r.Scalars = append(r.Scalars, other.Scalars...)
	r.Temporals = append(r.Temporals, other.Temporals...)
	r.PlayerExp += other.PlayerExp
	r.Heroes = append(r.Heroes, other.Heroes...)
	r.Awards = append(r.Awards, other.Awards...)
}

// ResolveBox validates the choose-one gift, the stack bound, every fixed row
// and every dropbox group before any mutation (C11).
func (c Catalog) ResolveBox(itemID, giftID, num int64) (BoxPlan, error) {
	item, err := c.Item(itemID)
	if err != nil {
		return BoxPlan{}, err
	}
	if num <= 0 || item.Stack <= 0 || num > item.Stack {
		return BoxPlan{}, ErrRefused
	}
	if !containsID(item.Gifts, giftID) && !containsID(item.OneInMore, giftID) {
		return BoxPlan{}, ErrRefused
	}
	gift, ok := c.Gift(giftID)
	if !ok {
		return BoxPlan{}, ErrRefused
	}
	if _, err := c.giftRewards(gift, 1); err != nil {
		return BoxPlan{}, err
	}
	if len(gift.Items) != len(gift.ItemNums) {
		return BoxPlan{}, ErrRefused
	}
	units := make([][]Dropbox, 0, num)
	for unit := int64(0); unit < num; unit++ {
		groups := make([]Dropbox, 0, len(gift.Drops))
		for _, dropboxID := range gift.Drops {
			group, ok := c.Dropbox(dropboxID)
			if !ok || len(group.Rolls) == 0 {
				return BoxPlan{}, ErrRefused
			}
			total := int64(0)
			for _, roll := range group.Rolls {
				if roll.RollType != 1 {
					return BoxPlan{}, ErrRefused
				}
				total += roll.Rate
			}
			if total <= 0 {
				return BoxPlan{}, ErrRefused
			}
			groups = append(groups, group)
		}
		units = append(units, groups)
	}
	return BoxPlan{Item: item, Gift: gift, Num: num, Units: units}, nil
}

// RollBox resolves every unit's fixed gift rows and then draws each drop group
// in unit order, then gift.drops order (C10 entropy schedule).
func (c Catalog) RollBox(plan BoxPlan, stream UniformSource) (Rewards, error) {
	rewards, err := c.GiftRewards(plan.Gift, plan.Num)
	if err != nil {
		return Rewards{}, err
	}
	for _, groups := range plan.Units {
		for _, group := range groups {
			roll, err := c.DrawDrop(group, stream)
			if err != nil {
				return Rewards{}, err
			}
			drawn, err := c.DropReward(roll)
			if err != nil {
				return Rewards{}, err
			}
			rewards.Add(drawn)
		}
	}
	return rewards, nil
}

// GiftRewards expands one gift row, repeated num times.
func (c Catalog) GiftRewards(gift Gift, num int64) (Rewards, error) {
	if num <= 0 {
		return Rewards{}, ErrRefused
	}
	one, err := c.giftRewards(gift, 1)
	if err != nil {
		return Rewards{}, err
	}
	out := Rewards{}
	out.PlayerExp = one.PlayerExp * num
	for _, stack := range one.Stacks {
		out.Stacks = append(out.Stacks, StackReward{ItemID: stack.ItemID, Amount: stack.Amount * num})
	}
	for _, scalar := range one.Scalars {
		out.Scalars = append(out.Scalars, ScalarReward{ResourceKey: scalar.ResourceKey, Amount: scalar.Amount * num})
	}
	for _, temporal := range one.Temporals {
		out.Temporals = append(out.Temporals, TemporalReward{ResourceKey: temporal.ResourceKey, Amount: temporal.Amount * num})
	}
	for unit := int64(0); unit < num; unit++ {
		out.Awards = append(out.Awards, one.Awards...)
		out.Heroes = append(out.Heroes, one.Heroes...)
	}
	return out, nil
}

func (c Catalog) giftRewards(gift Gift, num int64) (Rewards, error) {
	var out Rewards
	if len(gift.Items) != len(gift.ItemNums) {
		return out, ErrRefused
	}
	for index, itemID := range gift.Items {
		amount := gift.ItemNums[index]
		if amount <= 0 {
			return Rewards{}, ErrRefused
		}
		reward, err := c.itemOutput(itemID, amount)
		if err != nil {
			return Rewards{}, err
		}
		mergeRewards(&out, reward)
	}
	scalars := []struct {
		key    string
		amount int64
	}{
		{"crystal", gift.Crystal}, {"mana", gift.Mana}, {"arena_coin", gift.ArenaCoin},
		{"friendship_coin", gift.FriendshipCoin}, {"march_coin", gift.MarchCoin},
	}
	for _, field := range scalars {
		if field.amount > 0 {
			out.Scalars = append(out.Scalars, ScalarReward{ResourceKey: field.key, Amount: field.amount * num})
		}
	}
	temporals := []struct {
		key    string
		amount int64
	}{{"energy", gift.Energy}, {"spirit_energy", gift.SpiritEnergy}}
	for _, field := range temporals {
		if field.amount > 0 {
			out.Temporals = append(out.Temporals, TemporalReward{ResourceKey: field.key, Amount: field.amount * num})
		}
	}
	if gift.Exp > 0 {
		out.PlayerExp += gift.Exp * num
	}
	blocked := []int64{gift.VipExp, gift.LuckyCoin, gift.SkinFragment, gift.Badge, gift.Soul, gift.Vip, gift.ExBadge, gift.TutorCoin, gift.SkinCoin}
	for _, amount := range blocked {
		if amount != 0 {
			return Rewards{}, ErrRefused
		}
	}
	if gift.SummonID != 0 || (gift.Equip != "" && gift.Equip != "0") {
		return Rewards{}, ErrRefused
	}
	return out, nil
}

// itemOutput classifies one item row as a hero entity, a stack item or a
// blocked entity instance.
func (c Catalog) itemOutput(itemID, amount int64) (Rewards, error) {
	item, ok := c.Items[itemID]
	if !ok || item.ID != itemID || amount <= 0 {
		return Rewards{}, ErrRefused
	}
	// Type 24 is the client's Horcrux row (item_type.lua:389); its owner is I10,
	// so C11/B6 refuses the whole box before any mutation.
	if item.Type == 24 {
		return Rewards{}, ErrRefused
	}
	if item.Type == -1 && item.Stack == 0 {
		return Rewards{Heroes: []int64{itemID}}, nil
	}
	if item.Stack <= 0 {
		return Rewards{}, ErrRefused
	}
	return Rewards{
		Stacks: []StackReward{{ItemID: itemID, Amount: amount}},
		Awards: []FixedAward{{TableID: itemID, ItemNum: amount}},
	}, nil
}

func mergeRewards(into *Rewards, other Rewards) {
	into.Stacks = append(into.Stacks, other.Stacks...)
	into.Scalars = append(into.Scalars, other.Scalars...)
	into.Temporals = append(into.Temporals, other.Temporals...)
	into.PlayerExp += other.PlayerExp
	into.Heroes = append(into.Heroes, other.Heroes...)
	into.Awards = append(into.Awards, other.Awards...)
}

// DropReward turns one drawn dropbox row into its reward.
func (c Catalog) DropReward(roll DropRoll) (Rewards, error) {
	if roll.ItemNum <= 0 {
		return Rewards{}, ErrRefused
	}
	return c.itemOutput(roll.ItemID, roll.ItemNum)
}

// DrawDrop picks one weighted row, normalised by the group's actual sum; a zero
// total never wins because ResolveBox rejects it before any draw.
func (c Catalog) DrawDrop(group Dropbox, stream UniformSource) (DropRoll, error) {
	total := int64(0)
	for _, roll := range group.Rolls {
		total += roll.Rate
	}
	if total <= 0 {
		return DropRoll{}, ErrRefused
	}
	value := int64(stream.Uniform(uint64(total)))
	for _, roll := range group.Rolls {
		if value < roll.Rate {
			return roll, nil
		}
		value -= roll.Rate
	}
	return DropRoll{}, ErrRefused
}

func containsID(ids []int64, id int64) bool {
	for _, candidate := range ids {
		if candidate == id {
			return true
		}
	}
	return false
}
