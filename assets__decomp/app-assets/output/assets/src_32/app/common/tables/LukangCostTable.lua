local var_0_0 = class("LukangCostTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.cost_ = {}

	import("app.common.tables.TableParser").parse("activity_lukang_cost.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.progress)

		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.diamond)
	end)
end

function var_0_0.cost(arg_3_0, arg_3_1)
	return arg_3_0.cost_[arg_3_1] or 0
end

return var_0_0
