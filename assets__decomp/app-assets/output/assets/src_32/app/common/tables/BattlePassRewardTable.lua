local var_0_0 = class("BattlePassRewardTable")
local var_0_1 = xyd.tables.gift
local var_0_2 = xyd.tables.misc:getValue("battle_pass_award_loop_range")
local var_0_3 = xyd.tables.misc:getValue("battle_pass_award_max_level")

function var_0_0.ctor(arg_1_0)
	arg_1_0.giftId_ = {}
	arg_1_0.advGiftId_ = {}
	arg_1_0.isImportant_ = {}

	import("app.common.tables.TableParser").parse("battlepass_reward", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.level)

		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.common_gift)
		arg_1_0.advGiftId_[var_2_0] = tonumber(arg_2_0.special_gift)
		arg_1_0.isImportant_[var_2_0] = tonumber(arg_2_0.id_important)
	end)
end

function var_0_0.giftId(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1

	if arg_3_1 > var_0_3 and (arg_3_1 - var_0_3) % var_0_2 == 0 then
		var_3_0 = var_0_3
	end

	return arg_3_0.giftId_[var_3_0] or 0
end

function var_0_0.advGiftId(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1

	if arg_4_1 > var_0_3 and (arg_4_1 - var_0_3) % var_0_2 == 0 then
		var_4_0 = var_0_3
	end

	return arg_4_0.advGiftId_[var_4_0] or 0
end

function var_0_0.isImportant(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1

	if arg_5_1 > var_0_3 and (arg_5_1 - var_0_3) % var_0_2 == 0 then
		var_5_0 = var_0_3
	end

	return arg_5_0.isImportant_[var_5_0] or 0
end

function var_0_0.getItem(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0

	if arg_6_2 then
		var_6_0 = arg_6_0:advGiftId(arg_6_1)
	else
		var_6_0 = arg_6_0:giftId(arg_6_1)
	end

	local var_6_1 = var_0_1:items(var_6_0)
	local var_6_2 = var_0_1:itemNum(var_6_0)

	if next(var_6_1) and var_6_1[1] > 0 then
		return var_6_1[1], var_6_2[1]
	end

	local var_6_3 = var_0_1:crystal(var_6_0)

	if var_6_3 > 0 then
		return -1, var_6_3
	end

	local var_6_4 = var_0_1:mana(var_6_0)

	if var_6_4 > 0 then
		return -2, var_6_4
	end

	local var_6_5 = var_0_1:skinCoin(var_6_0)

	if var_6_5 > 0 then
		return -17, var_6_5
	end
end

return var_0_0
