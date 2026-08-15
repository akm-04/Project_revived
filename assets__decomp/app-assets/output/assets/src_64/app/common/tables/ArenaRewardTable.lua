local var_0_0 = class("ArenaRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.range_ = {}
	arg_1_0.dailyCrystal_ = {}
	arg_1_0.dailyMana_ = {}
	arg_1_0.dailyArenaCoin_ = {}
	arg_1_0.dailyItem_ = {}
	arg_1_0.dailyItemNum_ = {}
	arg_1_0.rankRewardCrystalNew_ = {}
	arg_1_0.rankRewardCrystal_ = {}
	arg_1_0.rangeTable_ = {}

	import("app.common.tables.TableParser").parse("arena_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.dailyCrystal_[var_2_0] = tonumber(arg_2_0.daily_diamond)
		arg_1_0.dailyMana_[var_2_0] = tonumber(arg_2_0.daily_mana)
		arg_1_0.dailyArenaCoin_[var_2_0] = tonumber(arg_2_0.daily_arena_coin)
		arg_1_0.dailyItem_[var_2_0] = xyd.splitToNumber(arg_2_0.daily_item, "|")
		arg_1_0.dailyItemNum_[var_2_0] = xyd.splitToNumber(arg_2_0.daily_item_num, "|")
		arg_1_0.rankRewardCrystalNew_[var_2_0] = tonumber(arg_2_0.rank_reward_diamond_new)
		arg_1_0.rankRewardCrystal_[var_2_0] = tonumber(arg_2_0.rank_reward_diamond)

		table.insert(arg_1_0.rangeTable_, arg_1_0.range_[var_2_0])
	end)
end

function var_0_0.getRangeTable(arg_3_0)
	return arg_3_0.rangeTable_ or {}
end

function var_0_0.ids(arg_4_0)
	return arg_4_0.ids_ or {}
end

function var_0_0.range(arg_5_0, arg_5_1)
	return arg_5_0.range_[arg_5_1] or 0
end

function var_0_0.dailyCrystal(arg_6_0, arg_6_1)
	return arg_6_0.dailyCrystal_[arg_6_1] or 0
end

function var_0_0.dailyMana(arg_7_0, arg_7_1)
	return arg_7_0.dailyMana_[arg_7_1] or 0
end

function var_0_0.dailyArenaCoin(arg_8_0, arg_8_1)
	return arg_8_0.dailyArenaCoin_[arg_8_1] or 0
end

function var_0_0.dailyItem(arg_9_0, arg_9_1)
	return arg_9_0.dailyItem_[arg_9_1]
end

function var_0_0.dailyItemNum(arg_10_0, arg_10_1)
	return arg_10_0.dailyItemNum_[arg_10_1]
end

function var_0_0.rankRewardCrystal(arg_11_0, arg_11_1)
	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 then
		return arg_11_0.rankRewardCrystalNew_[arg_11_1]
	else
		return arg_11_0.rankRewardCrystal_[arg_11_1]
	end
end

function var_0_0.getID2(arg_12_0, arg_12_1)
	local var_12_0 = 0
	local var_12_1 = #arg_12_0.ids_
	local var_12_2 = 1

	while var_12_1 > var_12_2 + 1 do
		local var_12_3 = math.floor((var_12_1 + var_12_2) / 2)

		if arg_12_1 > arg_12_0.range_[var_12_3] then
			var_12_2 = var_12_3
		elseif arg_12_1 < arg_12_0.range_[var_12_3] then
			var_12_1 = var_12_3
		else
			return var_12_3
		end
	end

	if var_12_2 == var_12_1 then
		if arg_12_1 <= arg_12_0.range[var_12_2] then
			return var_12_2
		else
			return var_12_0
		end
	elseif arg_12_1 <= arg_12_0.range[var_12_2] then
		return var_12_2
	elseif arg_12_1 <= arg_12_0.range[var_12_1] then
		return var_12_1
	else
		return var_12_0
	end
end

function var_0_0.getID(arg_13_0, arg_13_1)
	local var_13_0 = 0

	for iter_13_0 = 1, #arg_13_0.range_ do
		if arg_13_1 <= arg_13_0.range_[iter_13_0] then
			return iter_13_0
		end
	end

	return var_13_0
end

return var_0_0
