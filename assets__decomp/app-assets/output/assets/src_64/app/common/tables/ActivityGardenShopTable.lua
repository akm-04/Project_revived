local var_0_0 = class("ActivityGardenShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.sellPrice_ = {}
	arg_1_0.isHide_ = {}

	import("app.common.tables.TableParser").parse("activity_garden_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.sellPrice_[var_2_0] = tonumber(arg_2_0.sell_price)
		arg_1_0.isHide_[var_2_0] = tonumber(arg_2_0.is_hide)
	end)
end

function var_0_0.itemId(arg_3_0, arg_3_1)
	return arg_3_0.itemId_[arg_3_1] or 0
end

function var_0_0.itemNum(arg_4_0, arg_4_1)
	return arg_4_0.itemNum_[arg_4_1] or 0
end

function var_0_0.buyLimit(arg_5_0, arg_5_1)
	return arg_5_0.buyLimit_[arg_5_1] or 0
end

function var_0_0.sellPrice(arg_6_0, arg_6_1)
	return arg_6_0.sellPrice_[arg_6_1] or 0
end

function var_0_0.isHide(arg_7_0, arg_7_1)
	return arg_7_0.isHide_[arg_7_1] or 0
end

function var_0_0.ids(arg_8_0)
	return table.keys(arg_8_0.itemId_)
end

return var_0_0
