local var_0_0 = class("ActivityStickerTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.set_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.rarity_ = {}
	arg_1_0.point_ = {}

	import("app.common.tables.TableParser").parse("activity_sticker.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.set_[var_2_0] = tonumber(arg_2_0.set)
		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.rarity_[var_2_0] = tonumber(arg_2_0.rarity)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.set(arg_4_0, arg_4_1)
	return arg_4_0.set_[arg_4_1] or 0
end

function var_0_0.itemID(arg_5_0, arg_5_1)
	return arg_5_0.itemID_[arg_5_1] or 0
end

function var_0_0.itemNum(arg_6_0, arg_6_1)
	return arg_6_0.itemNum_[arg_6_1] or 0
end

function var_0_0.rarity(arg_7_0, arg_7_1)
	return arg_7_0.rarity_[arg_7_1] or 0
end

function var_0_0.point(arg_8_0, arg_8_1)
	return arg_8_0.point_[arg_8_1] or 0
end

return var_0_0
