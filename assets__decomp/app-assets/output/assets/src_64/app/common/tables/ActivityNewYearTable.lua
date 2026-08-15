local var_0_0 = class("ActivityNewYearTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.discount_ = {}
	arg_1_0.price_ = {}
	arg_1_0.buylimit_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.discount_price_ = {}
	arg_1_0.limit_type_ = {}
	arg_1_0.name_ = {}
	arg_1_0.giftlist_ = {}
	arg_1_0.levellimit_ = {}
	arg_1_0.pag_path_ = {}

	import("app.common.tables.TableParser").parse("activity_newyear.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.discount_[var_2_0] = tonumber(arg_2_0.discount)
		arg_1_0.price_[var_2_0] = arg_2_0.price
		arg_1_0.buylimit_[var_2_0] = arg_2_0.buy_limit
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.limit_type_[var_2_0] = tonumber(arg_2_0.limit_type)
		arg_1_0.discount_price_[var_2_0] = tonumber(arg_2_0.discount_price)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.giftlist_[var_2_0] = arg_2_0.gift_list
		arg_1_0.levellimit_[var_2_0] = arg_2_0.level_limit
		arg_1_0.pag_path_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.icon(arg_3_0, arg_3_1)
	return arg_3_0.pag_path_[arg_3_1]
end

function var_0_0.level_limit(arg_4_0, arg_4_1)
	return arg_4_0.levellimit_[arg_4_1]
end

function var_0_0.gift_list(arg_5_0, arg_5_1)
	return arg_5_0.giftlist_[arg_5_1] or " "
end

function var_0_0.name(arg_6_0, arg_6_1)
	return arg_6_0.name_[arg_6_1] or " "
end

function var_0_0.discount(arg_7_0, arg_7_1)
	return arg_7_0.discount_[arg_7_1] or 10
end

function var_0_0.price(arg_8_0, arg_8_1)
	return arg_8_0.price_[arg_8_1] or {}
end

function var_0_0.buylimit(arg_9_0, arg_9_1)
	return arg_9_0.buylimit_[arg_9_1] or 0
end

function var_0_0.gift(arg_10_0, arg_10_1)
	return arg_10_0.gift_[arg_10_1] or 0
end

function var_0_0.discount_price(arg_11_0, arg_11_1)
	return arg_11_0.discount_price_[arg_11_1] or arg_11_0.price_[arg_11_1]
end

function var_0_0.limit_type(arg_12_0, arg_12_1)
	return arg_12_0.limit_type_[arg_12_1] or 3
end

function var_0_0.allcount(arg_13_0)
	return arg_13_0.gift_
end

return var_0_0
