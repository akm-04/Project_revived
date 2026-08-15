local var_0_0 = class("StarTreasureItemTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.ratio_ = {}
	arg_1_0.item_id_ = {}
	arg_1_0.ids_ = {}

	import("app.common.tables.TableParser").parse("activity_star_exploration_item.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.ratio_[var_2_0] = tonumber(arg_2_0.ratio)
		arg_1_0.item_id_[var_2_0] = tonumber(arg_2_0.item_id)
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or 1
end

function var_0_0.ratio(arg_4_0, arg_4_1)
	return arg_4_0.ratio_[arg_4_1] or 1
end

function var_0_0.itemId(arg_5_0, arg_5_1)
	return arg_5_0.item_id_[arg_5_1] or 0
end

function var_0_0.getIds(arg_6_0)
	return arg_6_0.ids_
end

return var_0_0
