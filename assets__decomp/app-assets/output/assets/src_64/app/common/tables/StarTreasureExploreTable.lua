local var_0_0 = class("StarTreasureExploreTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.special_item_ = {}
	arg_1_0.special_num_ = {}

	import("app.common.tables.TableParser").parse("activity_star_exploration.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.map_id)

		arg_1_0.special_item_[var_2_0] = xyd.splitToNumber(arg_2_0.special_item, "|")
		arg_1_0.special_num_[var_2_0] = xyd.splitToNumber(arg_2_0.special_num, "|")
	end)
end

function var_0_0.specialItem(arg_3_0, arg_3_1)
	return arg_3_0.special_item_[arg_3_1] or {}
end

function var_0_0.specialNum(arg_4_0, arg_4_1)
	return arg_4_0.special_num_[arg_4_1] or {}
end

return var_0_0
