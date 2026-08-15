local var_0_0 = class("DiscountShopNormalTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.num_ = {}
	arg_1_0.type_ = {}
	arg_1_0.price_ = {}
	arg_1_0.discount_ = {}
	arg_1_0.rate_ = {}

	import("app.common.tables.TableParser").parse("activity_sp_shop_normal.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.item_id)

		arg_1_0.name_[var_2_0] = arg_2_0.item_name
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.type_[var_2_0] = arg_2_0.type
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.discount_[var_2_0] = tonumber(arg_2_0.discount)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.num(arg_4_0, arg_4_1)
	return arg_4_0.num_[arg_4_1] or ""
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or ""
end

function var_0_0.price(arg_6_0, arg_6_1)
	return arg_6_0.price_[arg_6_1] or ""
end

function var_0_0.discount(arg_7_0, arg_7_1)
	return arg_7_0.discount_[arg_7_1] or ""
end

function var_0_0.rate(arg_8_0, arg_8_1)
	return arg_8_0.rate_[arg_8_1] or ""
end

return var_0_0
