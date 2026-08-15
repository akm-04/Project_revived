local var_0_0 = class("GiftPushTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.originalCharge_ = {}
	arg_1_0.diamond_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.startTime_ = {}
	arg_1_0.time_ = {}
	arg_1_0.requireCharge_ = {}
	arg_1_0.nextCharge_ = {}
	arg_1_0.totalValue_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.banner_ = {}
	arg_1_0.title_ = {}
	arg_1_0.iosProductID_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.recommend_ = {}
	arg_1_0.chargeIds_ = {}
	arg_1_0.isOpen_ = {}
	arg_1_0.chargeSum_ = {}
	arg_1_0.chargeSumLimit_ = {}
	arg_1_0.conditionMap_ = {}

	import("app.common.tables.TableParser").parse("giftpush2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.charge_id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.originalCharge_[var_2_0] = tonumber(arg_2_0.original_charge)
		arg_1_0.diamond_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.startTime_[var_2_0] = tonumber(arg_2_0.start)
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.requireCharge_[var_2_0] = tonumber(arg_2_0.require_charge)
		arg_1_0.nextCharge_[var_2_0] = tonumber(arg_2_0.next_charge)
		arg_1_0.totalValue_[var_2_0] = tonumber(arg_2_0.total_value)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.banner_[var_2_0] = arg_2_0.banner
		arg_1_0.title_[var_2_0] = arg_2_0.title
		arg_1_0.iosProductID_[var_2_0] = arg_2_0.ios_product_id
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.recommend_[var_2_0] = tonumber(arg_2_0.recommend)

		if tonumber(arg_2_0.is_front) == 1 then
			arg_1_0.condition_[var_2_0] = xyd.split(arg_2_0.condition, "|")

			arg_1_0:dealCondition(var_2_0, arg_1_0.condition_[var_2_0])
		end

		arg_1_0.isOpen_[var_2_0] = tonumber(arg_2_0.is_open)
		arg_1_0.chargeSum_[var_2_0] = tonumber(arg_2_0.chargesum)
		arg_1_0.chargeSumLimit_[var_2_0] = tonumber(arg_2_0.chargesumlimit)
	end)
end

function var_0_0.chargeName(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or 0
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
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

function var_0_0.condition(arg_8_0, arg_8_1)
	return arg_8_0.condition_[arg_8_1] or {}
end

function var_0_0.startTime(arg_9_0, arg_9_1)
	return arg_9_0.startTime_[arg_9_1] or 0
end

function var_0_0.time(arg_10_0, arg_10_1)
	return arg_10_0.time_[arg_10_1] or 0
end

function var_0_0.requireCharge(arg_11_0, arg_11_1)
	return arg_11_0.requireCharge_[arg_11_1] or 0
end

function var_0_0.nextCharge(arg_12_0, arg_12_1)
	return arg_12_0.nextCharge_[arg_12_1] or 0
end

function var_0_0.totalValue(arg_13_0, arg_13_1)
	return arg_13_0.totalValue_[arg_13_1] or 0
end

function var_0_0.icon(arg_14_0, arg_14_1)
	return arg_14_0.icon_[arg_14_1] or ""
end

function var_0_0.banner(arg_15_0, arg_15_1)
	return arg_15_0.banner_[arg_15_1] or 0
end

function var_0_0.title(arg_16_0, arg_16_1)
	return arg_16_0.title_[arg_16_1] or ""
end

function var_0_0.giftId(arg_17_0, arg_17_1)
	return arg_17_0.giftId_[arg_17_1] or 0
end

function var_0_0.recommend(arg_18_0, arg_18_1)
	return arg_18_0.recommend_[arg_18_1] or 0
end

function var_0_0.iosProductID(arg_19_0, arg_19_1)
	return arg_19_0.iosProductID_[arg_19_1] or 0
end

function var_0_0.isOpen(arg_20_0, arg_20_1)
	return arg_20_0.isOpen_[arg_20_1] or 0
end

function var_0_0.dealCondition(arg_21_0, arg_21_1, arg_21_2)
	for iter_21_0, iter_21_1 in ipairs(arg_21_2) do
		local var_21_0 = xyd.splitToNumber(iter_21_1, ":")[1]

		if not arg_21_0.conditionMap_[var_21_0] then
			arg_21_0.conditionMap_[var_21_0] = {}
		end

		table.insert(arg_21_0.conditionMap_[var_21_0], arg_21_1)
	end
end

function var_0_0.conditionMap(arg_22_0)
	return arg_22_0.conditionMap_
end

function var_0_0.chargeSum(arg_23_0, arg_23_1)
	return arg_23_0.chargeSum_[arg_23_1]
end

function var_0_0.chargeSumLimit(arg_24_0, arg_24_1)
	return arg_24_0.chargeSumLimit_[arg_24_1]
end

return var_0_0
