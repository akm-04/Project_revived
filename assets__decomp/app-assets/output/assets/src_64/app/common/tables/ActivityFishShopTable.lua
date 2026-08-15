local var_0_0 = class("ActivityFishShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.dailyRefresh_ = {}
	arg_1_0.costType_ = {}
	arg_1_0.needItem_ = {}
	arg_1_0.needLev_ = {}
	arg_1_0.price_ = {}

	import("app.common.tables.TableParser").parse("activity_fish_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.dailyRefresh_[var_2_0] = tonumber(arg_2_0.daily_refresh)
		arg_1_0.costType_[var_2_0] = tonumber(arg_2_0.cost_type)
		arg_1_0.needItem_[var_2_0] = tonumber(arg_2_0.need_item)
		arg_1_0.needLev_[var_2_0] = tonumber(arg_2_0.need_lev)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
	end)
end

function var_0_0.getItemNum(arg_3_0)
	return #arg_3_0.itemId_
end

function var_0_0.itemID(arg_4_0, arg_4_1)
	return arg_4_0.itemId_[arg_4_1] or 0
end

function var_0_0.buyLimit(arg_5_0, arg_5_1)
	return arg_5_0.buyLimit_[arg_5_1] or -1
end

function var_0_0.dailyRefresh(arg_6_0, arg_6_1)
	return arg_6_0.dailyRefresh_[arg_6_1] or 0
end

function var_0_0.costType(arg_7_0, arg_7_1)
	return arg_7_0.costType_[arg_7_1] or 1
end

function var_0_0.needItem(arg_8_0, arg_8_1)
	return arg_8_0.needItem_[arg_8_1] or 0
end

function var_0_0.needLev(arg_9_0, arg_9_1)
	return arg_9_0.needLev_[arg_9_1] or 1
end

function var_0_0.price(arg_10_0, arg_10_1)
	return arg_10_0.price_[arg_10_1] or -1
end

return var_0_0
