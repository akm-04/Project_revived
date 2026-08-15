local var_0_0 = class("ActivitySummerGoldfishTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.color_ = {}
	arg_1_0.showOrder_ = {}
	arg_1_0.orderToId_ = {}
	arg_1_0.appearRate_ = {}
	arg_1_0.catchRate_ = {}
	arg_1_0.pt_ = {}

	import("app.common.tables.TableParser").parse("activity_summer_goldfish.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.color_[var_2_0] = arg_2_0.color
		arg_1_0.showOrder_[var_2_0] = tonumber(arg_2_0.show_order)
		arg_1_0.appearRate_[var_2_0] = tonumber(arg_2_0.appear_rate)
		arg_1_0.catchRate_[var_2_0] = tonumber(arg_2_0.catch_rate)
		arg_1_0.pt_[var_2_0] = tonumber(arg_2_0.pt)
		arg_1_0.orderToId_[arg_1_0.showOrder_[var_2_0]] = var_2_0
	end)
end

function var_0_0.color(arg_3_0, arg_3_1)
	return arg_3_0.color_[arg_3_1] or ""
end

function var_0_0.showOrder(arg_4_0, arg_4_1)
	return arg_4_0.showOrder_[arg_4_1] or 0
end

function var_0_0.appearRate(arg_5_0, arg_5_1)
	return arg_5_0.appearRate_[arg_5_1] or 0
end

function var_0_0.catchRate(arg_6_0, arg_6_1)
	return arg_6_0.catchRate_[arg_6_1] or 0
end

function var_0_0.pt(arg_7_0, arg_7_1)
	return arg_7_0.pt_[arg_7_1] or 0
end

function var_0_0.fishCount(arg_8_0)
	return #arg_8_0.color_
end

function var_0_0.appearAccumulateRate(arg_9_0)
	local var_9_0 = {}
	local var_9_1 = 0

	for iter_9_0 = 1, #arg_9_0.appearRate_ do
		var_9_1 = var_9_1 + arg_9_0.appearRate_[iter_9_0]
		var_9_0[iter_9_0] = var_9_1
	end

	return var_9_0
end

function var_0_0.getIdByOrder(arg_10_0, arg_10_1)
	return arg_10_0.orderToId_[arg_10_1]
end

return var_0_0
