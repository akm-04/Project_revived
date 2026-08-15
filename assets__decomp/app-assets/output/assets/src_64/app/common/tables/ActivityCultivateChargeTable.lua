local var_0_0 = class("ActivityCultivateChargeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.chargeId_ = {}
	arg_1_0.name_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.vipExp_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.iosProductId_ = {}

	import("app.common.tables.TableParser").parse("activity_cultivate_charge.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.mission_id)

		arg_1_0.chargeId_[var_2_0] = tonumber(arg_2_0.charge_id)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.vipExp_[var_2_0] = tonumber(arg_2_0.vip_exp)
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.iosProductId_[var_2_0] = arg_2_0.ios_product_id
	end)
end

function var_0_0.chargeId(arg_3_0, arg_3_1)
	return arg_3_0.chargeId_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.vipExp(arg_6_0, arg_6_1)
	return arg_6_0.vipExp_[arg_6_1] or 0
end

function var_0_0.charge(arg_7_0, arg_7_1)
	return arg_7_0.charge_[arg_7_1] or 0
end

function var_0_0.iosProductId(arg_8_0, arg_8_1)
	return arg_8_0.iosProductId_[arg_8_1] or ""
end

return var_0_0
