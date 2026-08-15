local var_0_0 = class("ActivityStickerShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.point_ = {}
	arg_1_0.buyLimit_ = {}

	import("app.common.tables.TableParser").parse("activity_sticker_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.itemID(arg_4_0, arg_4_1)
	return arg_4_0.itemID_[arg_4_1] or 0
end

function var_0_0.itemNum(arg_5_0, arg_5_1)
	return arg_5_0.itemNum_[arg_5_1] or 0
end

function var_0_0.point(arg_6_0, arg_6_1)
	return arg_6_0.point_[arg_6_1] or 0
end

function var_0_0.buyLimit(arg_7_0, arg_7_1)
	return arg_7_0.buyLimit_[arg_7_1] or 0
end

return var_0_0
