local var_0_0 = class("ActivityRichShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.item_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.costType_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.buyLimit_ = {}

	import("app.common.tables.TableParser").parse("activity_rich_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
		arg_1_0.costType_[var_2_0] = tonumber(arg_2_0.cost_type)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
	end)
end

function var_0_0.item(arg_3_0, arg_3_1)
	return arg_3_0.item_[arg_3_1] or 0
end

function var_0_0.cost(arg_4_0, arg_4_1)
	return arg_4_0.cost_[arg_4_1] or 0
end

function var_0_0.costType(arg_5_0, arg_5_1)
	return arg_5_0.costType_[arg_5_1] or 1
end

function var_0_0.itemNum(arg_6_0, arg_6_1)
	return arg_6_0.itemNum_[arg_6_1] or 1
end

function var_0_0.ids(arg_7_0)
	return table.keys(arg_7_0.item_)
end

function var_0_0.buyLimit(arg_8_0, arg_8_1)
	return arg_8_0.buyLimit_[arg_8_1] or 0
end

return var_0_0
