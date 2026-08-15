local var_0_0 = class("ActivityRichRangeRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.crystal_ = {}
	arg_1_0.itemIds_ = {}
	arg_1_0.itemNums_ = {}

	import("app.common.tables.TableParser").parse("activity_rich_range_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.crystal_[var_2_0] = tonumber(arg_2_0.crystal)
		arg_1_0.itemIds_[var_2_0] = xyd.splitToNumber(arg_2_0.item_ids, "|")
		arg_1_0.itemNums_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums, "|")
	end)
end

function var_0_0.range(arg_3_0, arg_3_1)
	return arg_3_0.range_[arg_3_1] or 0
end

function var_0_0.crystal(arg_4_0, arg_4_1)
	return arg_4_0.crystal_[arg_4_1] or 0
end

function var_0_0.itemIds(arg_5_0, arg_5_1)
	return arg_5_0.itemIds_[arg_5_1] or {}
end

function var_0_0.itemNums(arg_6_0, arg_6_1)
	return arg_6_0.itemNums_[arg_6_1] or {}
end

function var_0_0.ids(arg_7_0)
	return table.keys(arg_7_0.range_) or {}
end

function var_0_0.getID(arg_8_0, arg_8_1)
	for iter_8_0, iter_8_1 in ipairs(arg_8_0.range_) do
		if arg_8_1 <= iter_8_1 then
			return iter_8_0
		end
	end

	return 0
end

return var_0_0
