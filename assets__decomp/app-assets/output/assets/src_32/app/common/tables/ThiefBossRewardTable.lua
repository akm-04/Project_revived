local var_0_0 = class("ThiefBossRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.range = {}
	arg_1_0.diamond = {}
	arg_1_0.mana = {}
	arg_1_0.culture = {}
	arg_1_0.items = {}
	arg_1_0.itemNums = {}

	import("app.common.tables.TableParser").parse("anniversary_boss_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.range[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.diamond[var_2_0] = tonumber(arg_2_0.defeat_diamond)
		arg_1_0.mana[var_2_0] = tonumber(arg_2_0.defeat_mana)
		arg_1_0.culture[var_2_0] = tonumber(arg_2_0.defeat_culture)
		arg_1_0.items[var_2_0] = xyd.splitToNumber(arg_2_0.defeat_item, "|")
		arg_1_0.itemNums[var_2_0] = xyd.splitToNumber(arg_2_0.defeat_item_num, "|")
	end)
end

function var_0_0.words(arg_3_0, arg_3_1)
	return arg_3_0.words_[arg_3_1] or nil
end

function var_0_0.getDiamond(arg_4_0, arg_4_1)
	if arg_4_1 == 0 then
		return 0
	end

	local var_4_0 = 0

	for iter_4_0, iter_4_1 in pairs(arg_4_0.range) do
		local var_4_1 = iter_4_0

		if arg_4_1 <= iter_4_1 then
			return arg_4_0.diamond[var_4_1]
		end
	end

	return 0
end

function var_0_0.getMana(arg_5_0, arg_5_1)
	if arg_5_1 == 0 then
		return 0
	end

	local var_5_0 = 0

	for iter_5_0, iter_5_1 in pairs(arg_5_0.range) do
		local var_5_1 = iter_5_0

		if arg_5_1 <= iter_5_1 then
			return arg_5_0.mana[var_5_1]
		end
	end

	return 0
end

function var_0_0.getCulture(arg_6_0, arg_6_1)
	if arg_6_1 == 0 then
		return 0
	end

	local var_6_0 = 0

	for iter_6_0, iter_6_1 in pairs(arg_6_0.range) do
		local var_6_1 = iter_6_0

		if arg_6_1 <= iter_6_1 then
			return arg_6_0.culture[var_6_1]
		end
	end

	return 0
end

function var_0_0.getItems(arg_7_0, arg_7_1)
	if arg_7_1 == 0 then
		return 0
	end

	local var_7_0 = 0

	for iter_7_0, iter_7_1 in pairs(arg_7_0.range) do
		local var_7_1 = iter_7_0

		if arg_7_1 <= iter_7_1 then
			return arg_7_0.items[var_7_1]
		end
	end

	return 0
end

function var_0_0.getItemNums(arg_8_0, arg_8_1)
	if arg_8_1 == 0 then
		return 0
	end

	local var_8_0 = 0

	for iter_8_0, iter_8_1 in pairs(arg_8_0.range) do
		local var_8_1 = iter_8_0

		if arg_8_1 <= iter_8_1 then
			return arg_8_0.itemNums[var_8_1]
		end
	end

	return 0
end

return var_0_0
