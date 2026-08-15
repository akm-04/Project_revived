local var_0_0 = class("ActivityFusionMaterialTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.item_ = {}
	arg_1_0.consumeDropRate_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.itemIcon_ = {}

	import("app.common.tables.TableParser").parse("activity_fusion_material.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.consumeDropRate_[var_2_0] = tonumber(arg_2_0.consume_drop_rate)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.itemIcon_[tonumber(arg_2_0.item)] = arg_2_0.icon
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.item(arg_4_0, arg_4_1)
	return arg_4_0.item_[arg_4_1] or 0
end

function var_0_0.consumeDropRate(arg_5_0, arg_5_1)
	return arg_5_0.consumeDropRate_[arg_5_1] or 0
end

function var_0_0.icon(arg_6_0, arg_6_1)
	return arg_6_0.icon_[arg_6_1] or ""
end

function var_0_0.itemIcon(arg_7_0, arg_7_1)
	return arg_7_0.itemIcon_[arg_7_1] or ""
end

return var_0_0
