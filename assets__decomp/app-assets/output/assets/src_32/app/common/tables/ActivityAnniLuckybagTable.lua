local var_0_0 = class("AnniLuckybagTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.key_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.item_ids_display_ = {}
	arg_1_0.item_nums_display_ = {}
	arg_1_0.rare_ = {}
	arg_1_0.getWayIcon_ = {}
	arg_1_0.text1_ = {}
	arg_1_0.text2_ = {}

	import("app.common.tables.TableParser").parse("activity_anniversary_luckbag.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.key_[var_2_0] = tonumber(arg_2_0.key)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.item_ids_display_[var_2_0] = xyd.splitToNumber(arg_2_0.item_ids_display, "|")
		arg_1_0.item_nums_display_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums_display, "|")
		arg_1_0.rare_[var_2_0] = xyd.splitToNumber(arg_2_0.rare, "|")
		arg_1_0.getWayIcon_[var_2_0] = arg_2_0.get_way_icon
		arg_1_0.text1_[var_2_0] = arg_2_0.text1
		arg_1_0.text2_[var_2_0] = arg_2_0.text2

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getAllIds(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.key(arg_4_0, arg_4_1)
	return arg_4_0.key_[arg_4_1] or ""
end

function var_0_0.getDisplayItemIds(arg_5_0, arg_5_1)
	return arg_5_0.item_ids_display_[arg_5_1] or ""
end

function var_0_0.getDisplayItemCount(arg_6_0, arg_6_1)
	return arg_6_0.item_nums_display_[arg_6_1] or ""
end

function var_0_0.getItemRare(arg_7_0, arg_7_1)
	return arg_7_0.rare_[arg_7_1] or ""
end

function var_0_0.getWayIcon(arg_8_0, arg_8_1)
	return arg_8_0.getWayIcon_[arg_8_1] or ""
end

function var_0_0.text1(arg_9_0, arg_9_1)
	return arg_9_0.text1_[arg_9_1] or ""
end

function var_0_0.text2(arg_10_0, arg_10_1)
	return arg_10_0.text2_[arg_10_1] or ""
end

return var_0_0
