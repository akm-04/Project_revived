local var_0_0 = class("RagnarokShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemID_ = {}
	arg_1_0.num_ = {}
	arg_1_0.limitNum_ = {}
	arg_1_0.price_ = {}

	import("app.common.tables.TableParser").parse("activity_ragnarok_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.limitNum_[var_2_0] = tonumber(arg_2_0.limit_num)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
	end)
end

function var_0_0.items(arg_3_0)
	return arg_3_0.itemID_ or {}
end

function var_0_0.itemID(arg_4_0, arg_4_1)
	return arg_4_0.itemID_[arg_4_1] or 0
end

function var_0_0.num(arg_5_0, arg_5_1)
	return arg_5_0.num_[arg_5_1] or 0
end

function var_0_0.limitNum(arg_6_0, arg_6_1)
	return arg_6_0.limitNum_[arg_6_1] or 0
end

function var_0_0.price(arg_7_0, arg_7_1)
	return arg_7_0.price_[arg_7_1] or 0
end

return var_0_0
