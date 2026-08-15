local var_0_0 = class("ZhugeSweepExploreCostTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.cost_ = {}

	import("app.common.tables.TableParser").parse("zhuge_sweep_explore_cost.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
	end)
end

function var_0_0.range(arg_3_0, arg_3_1)
	return arg_3_0.range_[arg_3_1] or 0
end

function var_0_0.cost(arg_4_0, arg_4_1)
	return arg_4_0.cost_[arg_4_1] or 0
end

function var_0_0.getCost(arg_5_0, arg_5_1)
	for iter_5_0 = #arg_5_0.range_, 1, -1 do
		if arg_5_1 >= arg_5_0.range_[iter_5_0] then
			return arg_5_0:cost(iter_5_0)
		end
	end

	return 0
end

function var_0_0.getCostInfo(arg_6_0, arg_6_1)
	local var_6_0 = 0
	local var_6_1 = {}
	local var_6_2 = arg_6_0.range_[1]

	for iter_6_0 = arg_6_1 - 1, var_6_2, -1 do
		var_6_0 = var_6_0 + arg_6_0:getCost(iter_6_0)
		var_6_1[iter_6_0] = var_6_0
	end

	var_6_1[arg_6_1] = 0

	return var_6_1
end

return var_0_0
