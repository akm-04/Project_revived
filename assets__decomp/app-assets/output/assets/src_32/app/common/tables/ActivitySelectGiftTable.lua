local var_0_0 = class("ActivitySelectGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.chargeId_ = {}
	arg_1_0.name_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.originalCharge_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.iosProductId_ = {}

	import("app.common.tables.TableParser").parse("activity_select_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.charge_id)

		table.insert(arg_1_0.chargeId_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.originalCharge_[var_2_0] = tonumber(arg_2_0.original_charge)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.iosProductId_[var_2_0] = arg_2_0.ios_product_id
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.chargeId_ or {}
end

function var_0_0.chargeId(arg_4_0, arg_4_1)
	return arg_4_0.chargeId_[arg_4_1] or 0
end

function var_0_0.name(arg_5_0, arg_5_1)
	return arg_5_0.name_[arg_5_1] or ""
end

function var_0_0.charge(arg_6_0, arg_6_1)
	return arg_6_0.charge_[arg_6_1] or 0
end

function var_0_0.originalCharge(arg_7_0, arg_7_1)
	return arg_7_0.originalCharge_[arg_7_1] or 0
end

function var_0_0.giftId(arg_8_0, arg_8_1)
	return arg_8_0.giftId_[arg_8_1] or 0
end

function var_0_0.iosProductId(arg_9_0, arg_9_1)
	return arg_9_0.iosProductId_[arg_9_1] or ""
end

return var_0_0
