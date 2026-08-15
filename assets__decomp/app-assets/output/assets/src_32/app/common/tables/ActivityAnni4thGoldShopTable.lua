local var_0_0 = class("ActivityAnni4thGoldShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.limitNum_ = {}
	arg_1_0.price_ = {}

	import("app.common.tables.TableParser").parse("activity_anni_4th_gold_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.limitNum_[var_2_0] = tonumber(arg_2_0.limit_num)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
	end)
end

function var_0_0.itemId(arg_3_0, arg_3_1)
	return arg_3_0.itemId_[arg_3_1] or 0
end

function var_0_0.itemNum(arg_4_0, arg_4_1)
	return arg_4_0.itemNum_[arg_4_1] or 0
end

function var_0_0.limitNum(arg_5_0, arg_5_1)
	return arg_5_0.limitNum_[arg_5_1] or 0
end

function var_0_0.price(arg_6_0, arg_6_1)
	return arg_6_0.price_[arg_6_1] or 0
end

function var_0_0.ids(arg_7_0, ...)
	return table.keys(arg_7_0.itemId_) or {}
end

return var_0_0
