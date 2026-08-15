local var_0_0 = class("ActivityZhangheDollShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.dollCost_ = {}

	import("app.common.tables.TableParser").parse("activity_zhanghe_doll_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.dollCost_[var_2_0] = tonumber(arg_2_0.doll_cost)

		table.insert(arg_1_0.ids_, var_2_0)
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

function var_0_0.buyLimit(arg_6_0, arg_6_1)
	return arg_6_0.buyLimit_[arg_6_1] or -1
end

function var_0_0.dollCost(arg_7_0, arg_7_1)
	return arg_7_0.dollCost_[arg_7_1] or 0
end

return var_0_0
