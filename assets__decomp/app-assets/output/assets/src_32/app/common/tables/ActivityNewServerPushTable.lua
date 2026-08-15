local var_0_0 = class("ActivityNewServerPushTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.chargeIds_ = {}
	arg_1_0.name_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.originalCharge_ = {}
	arg_1_0.diamond_ = {}
	arg_1_0.discount_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.iosProductID_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("activity_new_server_push.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.charge_id)

		table.insert(arg_1_0.chargeIds_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.originalCharge_[var_2_0] = tonumber(arg_2_0.original_charge)
		arg_1_0.diamond_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.discount_[var_2_0] = tonumber(arg_2_0.discount)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.iosProductID_[var_2_0] = arg_2_0.ios_product_id
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.chargeIds_
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or 0
end

function var_0_0.charge(arg_5_0, arg_5_1)
	return arg_5_0.charge_[arg_5_1] or 0
end

function var_0_0.originalCharge(arg_6_0, arg_6_1)
	return arg_6_0.originalCharge_[arg_6_1] or 0
end

function var_0_0.diamond(arg_7_0, arg_7_1)
	return arg_7_0.diamond_[arg_7_1] or 0
end

function var_0_0.discount(arg_8_0, arg_8_1)
	return arg_8_0.discount_[arg_8_1] or 0
end

function var_0_0.buyLimit(arg_9_0, arg_9_1)
	return arg_9_0.buyLimit_[arg_9_1] or 0
end

function var_0_0.giftId(arg_10_0, arg_10_1)
	return arg_10_0.giftId_[arg_10_1] or 0
end

function var_0_0.iosProductID(arg_11_0, arg_11_1)
	return arg_11_0.iosProductID_[arg_11_1] or 0
end

function var_0_0.icon(arg_12_0, arg_12_1)
	return arg_12_0.icon_[arg_12_1] or 0
end

return var_0_0
