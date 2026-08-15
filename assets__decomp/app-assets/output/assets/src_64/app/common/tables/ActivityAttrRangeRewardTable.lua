local var_0_0 = class("ActivityAttrRangeRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.crystal_ = {}
	arg_1_0.item_ids_ = {}
	arg_1_0.item_nums_ = {}

	import("app.common.tables.TableParser").parse("activity_attr_range_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.crystal_[var_2_0] = tonumber(arg_2_0.crystal)
		arg_1_0.item_ids_[var_2_0] = xyd.splitToNumber(arg_2_0.item_ids, "|")
		arg_1_0.item_nums_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums, "|")
	end)
end

function var_0_0.getRange(arg_3_0)
	return arg_3_0.range_ or {}
end

function var_0_0.range(arg_4_0, arg_4_1)
	return arg_4_0.range_[arg_4_1] or 0
end

function var_0_0.crystal(arg_5_0, arg_5_1)
	return arg_5_0.crystal_[arg_5_1] or 0
end

function var_0_0.itemIds(arg_6_0, arg_6_1)
	return arg_6_0.item_ids_[arg_6_1] or {}
end

function var_0_0.itemNums(arg_7_0, arg_7_1)
	return arg_7_0.item_nums_[arg_7_1] or {}
end

return var_0_0
