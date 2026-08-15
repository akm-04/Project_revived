local var_0_0 = class("GiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.items_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.crystal_ = {}
	arg_1_0.soul_ = {}
	arg_1_0.mana_ = {}
	arg_1_0.drops_ = {}
	arg_1_0.arena_coin_ = {}
	arg_1_0.march_coin_ = {}
	arg_1_0.lucky_coin_ = {}
	arg_1_0.friend_coin_ = {}
	arg_1_0.skinFragment_ = {}
	arg_1_0.exp_ = {}
	arg_1_0.badge_ = {}
	arg_1_0.vip_ = {}
	arg_1_0.ex_badge_ = {}
	arg_1_0.soul_ = {}
	arg_1_0.vipExp_ = {}
	arg_1_0.skinCoin_ = {}
	arg_1_0.energy_ = {}

	import("app.common.tables.TableParser").parse("gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.items_[var_2_0] = xyd.splitToNumber(arg_2_0.items, "|")
		arg_1_0.itemNum_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums, "|")
		arg_1_0.crystal_[var_2_0] = tonumber(arg_2_0.crystal)
		arg_1_0.soul_[var_2_0] = tonumber(arg_2_0.soul)
		arg_1_0.arena_coin_[var_2_0] = tonumber(arg_2_0.arena_coin)
		arg_1_0.march_coin_[var_2_0] = tonumber(arg_2_0.march_coin)
		arg_1_0.lucky_coin_[var_2_0] = tonumber(arg_2_0.lucky_coin)
		arg_1_0.mana_[var_2_0] = tonumber(arg_2_0.mana)
		arg_1_0.drops_[var_2_0] = xyd.splitToNumber(arg_2_0.drops, "|")
		arg_1_0.friend_coin_[var_2_0] = tonumber(arg_2_0.friend_coin)
		arg_1_0.skinFragment_[var_2_0] = tonumber(arg_2_0.skin_fragment)
		arg_1_0.exp_[var_2_0] = tonumber(arg_2_0.exp)
		arg_1_0.badge_[var_2_0] = tonumber(arg_2_0.badge)
		arg_1_0.vip_[var_2_0] = tonumber(arg_2_0.vip)
		arg_1_0.ex_badge_[var_2_0] = tonumber(arg_2_0.ex_badge)
		arg_1_0.soul_[var_2_0] = tonumber(arg_2_0.soul)
		arg_1_0.vipExp_[var_2_0] = tonumber(arg_2_0.vip_exp)
		arg_1_0.skinCoin_[var_2_0] = tonumber(arg_2_0.skin_coin)
		arg_1_0.energy_[var_2_0] = tonumber(arg_2_0.energy)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or {}
end

function var_0_0.items(arg_4_0, arg_4_1)
	if arg_4_0.items_[arg_4_1] and arg_4_0.items_[arg_4_1][1] == 0 then
		return {}
	end

	return arg_4_0.items_[arg_4_1] or {}
end

function var_0_0.itemNum(arg_5_0, arg_5_1)
	if arg_5_0.itemNum_[arg_5_1] and arg_5_0.itemNum_[arg_5_1][1] == 0 then
		return {}
	end

	return arg_5_0.itemNum_[arg_5_1] or {}
end

function var_0_0.crystal(arg_6_0, arg_6_1)
	return arg_6_0.crystal_[arg_6_1] or 0
end

function var_0_0.mana(arg_7_0, arg_7_1)
	return arg_7_0.mana_[arg_7_1] or 0
end

function var_0_0.arenaCoin(arg_8_0, arg_8_1)
	return arg_8_0.arena_coin_[arg_8_1] or 0
end

function var_0_0.marchCoin(arg_9_0, arg_9_1)
	return arg_9_0.march_coin_[arg_9_1] or 0
end

function var_0_0.luckyCoin(arg_10_0, arg_10_1)
	return arg_10_0.lucky_coin_[arg_10_1] or 0
end

function var_0_0.drops(arg_11_0, arg_11_1)
	return arg_11_0.drops_[arg_11_1] or {}
end

function var_0_0.exp(arg_12_0, arg_12_1)
	return arg_12_0.exp_[arg_12_1] or 0
end

function var_0_0.soul(arg_13_0, arg_13_1)
	return arg_13_0.soul_[arg_13_1] or 0
end

function var_0_0.badge(arg_14_0, arg_14_1)
	return arg_14_0.badge_[arg_14_1]
end

function var_0_0.vip(arg_15_0, arg_15_1)
	return arg_15_0.vip_[arg_15_1]
end

function var_0_0.exBadge(arg_16_0, arg_16_1)
	return arg_16_0.ex_badge_[arg_16_1]
end

function var_0_0.skinFragment(arg_17_0, arg_17_1)
	return arg_17_0.skinFragment_[arg_17_1] or 0
end

function var_0_0.spiritStone(arg_18_0, arg_18_1)
	return arg_18_0.soul_[arg_18_1] or 0
end

function var_0_0.vipExp(arg_19_0, arg_19_1)
	return arg_19_0.vipExp_[arg_19_1] or 0
end

function var_0_0.skinCoin(arg_20_0, arg_20_1)
	return arg_20_0.skinCoin_[arg_20_1] or 0
end

function var_0_0.energy(arg_21_0, arg_21_1)
	return arg_21_0.energy_[arg_21_1] or 0
end

return var_0_0
