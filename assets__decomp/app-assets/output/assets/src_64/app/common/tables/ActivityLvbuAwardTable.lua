local var_0_0 = class("ActivityLvbuAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.diamond_ = {}
	arg_1_0.mana_ = {}
	arg_1_0.item_ = {}
	arg_1_0.itemNum_ = {}

	import("app.common.tables.TableParser").parse("activity_lvbu_award.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.range_[var_2_0] = xyd.splitToNumber(arg_2_0.range, "|")
		arg_1_0.diamond_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.mana_[var_2_0] = tonumber(arg_2_0.mana)
		arg_1_0.item_[var_2_0] = xyd.splitToNumber(arg_2_0.item, "|")
		arg_1_0.itemNum_[var_2_0] = xyd.splitToNumber(arg_2_0.item_num, "|")
	end)
end

function var_0_0.range(arg_3_0, arg_3_1)
	return arg_3_0.range_[arg_3_1] or 0
end

function var_0_0.diamond(arg_4_0, arg_4_1)
	return arg_4_0.diamond_[arg_4_1] or 0
end

function var_0_0.mana(arg_5_0, arg_5_1)
	return arg_5_0.mana_[arg_5_1] or 0
end

function var_0_0.item(arg_6_0, arg_6_1)
	return arg_6_0.item_[arg_6_1] or ""
end

function var_0_0.itemNum(arg_7_0, arg_7_1)
	return arg_7_0.itemNum_[arg_7_1] or 0
end

function var_0_0.RewardCount(arg_8_0)
	return #arg_8_0.range_ or 0
end

return var_0_0
