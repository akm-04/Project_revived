local var_0_0 = class("ActivitySkinWarmUpTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.price_ = {}
	arg_1_0.heatPoint_ = {}
	arg_1_0.discountPoint_ = {}
	arg_1_0.heatPointIncrease_ = {}
	arg_1_0.recharge_ = {}
	arg_1_0.exDiscount_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_skin_warmup_new.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.skin_item)

		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.heatPoint_[var_2_0] = xyd.splitToNumber(arg_2_0.heat_point, "|")
		arg_1_0.discountPoint_[var_2_0] = xyd.splitToNumber(arg_2_0.discount_point, "|")
		arg_1_0.heatPointIncrease_[var_2_0] = tonumber(arg_2_0.heat_point_increase)
		arg_1_0.recharge_[var_2_0] = tonumber(arg_2_0.recharge)
		arg_1_0.exDiscount_[var_2_0] = tonumber(arg_2_0.ex_discount)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.price(arg_3_0, arg_3_1)
	return arg_3_0.price_[arg_3_1] or 0
end

function var_0_0.heatPoint(arg_4_0, arg_4_1)
	return arg_4_0.heatPoint_[arg_4_1] or {}
end

function var_0_0.discountPoint(arg_5_0, arg_5_1)
	return arg_5_0.discountPoint_[arg_5_1] or {}
end

function var_0_0.heatPointIncrease(arg_6_0, arg_6_1)
	return arg_6_0.heatPointIncrease_[arg_6_1] or 0
end

function var_0_0.recharge(arg_7_0, arg_7_1)
	return arg_7_0.recharge_[arg_7_1] or 0
end

function var_0_0.exDiscount(arg_8_0, arg_8_1)
	return arg_8_0.exDiscount_[arg_8_1] or 0
end

function var_0_0.gift(arg_9_0, arg_9_1)
	return arg_9_0.gift_[arg_9_1] or 0
end

return var_0_0
