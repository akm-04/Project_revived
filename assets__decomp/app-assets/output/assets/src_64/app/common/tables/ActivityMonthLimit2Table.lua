local var_0_0 = class("ActivityMonthLimit2Table")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.originalCharge_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.iosProductId_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.vipLimit_ = {}

	import("app.common.tables.TableParser").parse("activity_month_limit2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.charge_id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.originalCharge_[var_2_0] = tonumber(arg_2_0.original_charge)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.iosProductId_[var_2_0] = arg_2_0.ios_product_id
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.vipLimit_[var_2_0] = tonumber(arg_2_0.vip_limit)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.charge(arg_4_0, arg_4_1)
	return arg_4_0.charge_[arg_4_1] or 0
end

function var_0_0.originalCharge(arg_5_0, arg_5_1)
	return arg_5_0.originalCharge_[arg_5_1] or 0
end

function var_0_0.giftId(arg_6_0, arg_6_1)
	return arg_6_0.giftId_[arg_6_1] or 0
end

function var_0_0.iosProductId(arg_7_0, arg_7_1)
	return arg_7_0.iosProductId_[arg_7_1] or ""
end

function var_0_0.buyLimit(arg_8_0, arg_8_1)
	return arg_8_0.buyLimit_[arg_8_1] or 0
end

function var_0_0.ids(arg_9_0)
	return table.keys(arg_9_0.charge_)
end

function var_0_0.vipLimit(arg_10_0, arg_10_1)
	return arg_10_0.vipLimit_[arg_10_1] or 0
end

return var_0_0
