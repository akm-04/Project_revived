local var_0_0 = class("ActivityLevelChargeGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.level_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.productID_ = {}
	arg_1_0.discountProductID_ = {}
	arg_1_0.chargeID_ = {}
	arg_1_0.discountChargeID_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.discountCharge_ = {}

	import("app.common.tables.TableParser").parse("activity_level_charge_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level_condition)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.productID_[var_2_0] = arg_2_0.ios_product_id
		arg_1_0.discountProductID_[var_2_0] = arg_2_0.discount_ios_product_id
		arg_1_0.chargeID_[var_2_0] = tonumber(arg_2_0.charge_id)
		arg_1_0.discountChargeID_[var_2_0] = tonumber(arg_2_0.discount_charge_id)
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.discountCharge_[var_2_0] = tonumber(arg_2_0.discount_charge)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.level(arg_5_0, arg_5_1)
	return arg_5_0.level_[arg_5_1] or 0
end

function var_0_0.gift(arg_6_0, arg_6_1)
	return arg_6_0.gift_[arg_6_1] or 0
end

function var_0_0.charge(arg_7_0, arg_7_1)
	return arg_7_0.charge_[arg_7_1] or 0
end

function var_0_0.discountCharge(arg_8_0, arg_8_1)
	return arg_8_0.discountCharge_[arg_8_1] or 0
end

function var_0_0.productID(arg_9_0, arg_9_1)
	return arg_9_0.productID_[arg_9_1] or ""
end

function var_0_0.discountProductID(arg_10_0, arg_10_1)
	return arg_10_0.discountProductID_[arg_10_1] or ""
end

function var_0_0.chargeID(arg_11_0, arg_11_1)
	return arg_11_0.chargeID_[arg_11_1] or 0
end

function var_0_0.discountChargeID(arg_12_0, arg_12_1)
	return arg_12_0.discountChargeID_[arg_12_1] or 0
end

return var_0_0
