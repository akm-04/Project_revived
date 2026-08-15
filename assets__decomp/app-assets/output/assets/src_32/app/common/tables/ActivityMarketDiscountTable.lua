local var_0_0 = class("ActivityMarketDiscountTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.discount_limit_ = {}
	arg_1_0.discount_num_ = {}

	import("app.common.tables.TableParser").parse("activity_market_discount.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.discount_limit_[var_2_0] = tonumber(arg_2_0.discount_limit)
		arg_1_0.discount_num_[var_2_0] = tonumber(arg_2_0.discount_num)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.discountLimit(arg_4_0, arg_4_1)
	return arg_4_0.discount_limit_[arg_4_1] or ""
end

function var_0_0.discountNum(arg_5_0, arg_5_1)
	return arg_5_0.discount_num_[arg_5_1] or ""
end

return var_0_0
