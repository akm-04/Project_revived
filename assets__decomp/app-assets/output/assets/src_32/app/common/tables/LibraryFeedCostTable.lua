local var_0_0 = class("LibraryFeedCostTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.costType_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.initRate_ = {}
	arg_1_0.rateChangeStep_ = {}

	import("app.common.tables.TableParser").parse("library_feed_cost.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.costType_[var_2_0] = tonumber(arg_2_0.cost_type)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
		arg_1_0.initRate_[var_2_0] = xyd.splitToNumber(arg_2_0.init_rate, "|")
		arg_1_0.rateChangeStep_[var_2_0] = tonumber(arg_2_0.rate_change_step)
	end)
end

function var_0_0.costType(arg_3_0, arg_3_1)
	return arg_3_0.costType_[arg_3_1] or 0
end

function var_0_0.cost(arg_4_0, arg_4_1)
	return arg_4_0.cost_[arg_4_1] or 0
end

function var_0_0.initRate(arg_5_0, arg_5_1)
	return arg_5_0.initRate_[arg_5_1] or {}
end

function var_0_0.rateChangeStep(arg_6_0, arg_6_1)
	return arg_6_0.rateChangeStep_[arg_6_1] or 0
end

function var_0_0.getCostTypeNums(arg_7_0)
	return #arg_7_0.costType_
end

return var_0_0
