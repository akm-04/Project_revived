local var_0_0 = class("ChargeListTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.vipExp_ = {}
	arg_1_0.original_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.diamond_ = {}
	arg_1_0.iosProductId_ = {}

	import("app.common.tables.TableParser").parse("charge_list.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.charge_id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.vipExp_[var_2_0] = tonumber(arg_2_0.vip_exp)
		arg_1_0.original_[var_2_0] = tonumber(arg_2_0.original_charge)
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.diamond_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.iosProductId_[var_2_0] = arg_2_0.ios_product_id
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.vipExp(arg_5_0, arg_5_1)
	return arg_5_0.vipExp_[arg_5_1] or 0
end

function var_0_0.originalCharge(arg_6_0, arg_6_1)
	return arg_6_0.original_[arg_6_1] or 0
end

function var_0_0.charge(arg_7_0, arg_7_1)
	return arg_7_0.charge_[arg_7_1] or 0
end

function var_0_0.diamond(arg_8_0, arg_8_1)
	return arg_8_0.diamond_[arg_8_1] or 0
end

function var_0_0.iosProductId(arg_9_0, arg_9_1)
	return arg_9_0.iosProductId_[arg_9_1] or ""
end

return var_0_0
