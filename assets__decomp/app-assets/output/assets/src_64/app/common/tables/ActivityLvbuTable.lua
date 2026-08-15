local var_0_0 = class("ActivityLvbuTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.x_ = {}
	arg_1_0.y_ = {}

	import("app.common.tables.TableParser").parse("activity_lvbu.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.x_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.y_[var_2_0] = tonumber(arg_2_0.y)
	end)
end

function var_0_0.x(arg_3_0, arg_3_1)
	return arg_3_0.x_[arg_3_1] or 0
end

function var_0_0.y(arg_4_0, arg_4_1)
	return arg_4_0.y_[arg_4_1] or 0
end

function var_0_0.getCounts(arg_5_0)
	return #arg_5_0.x_
end

return var_0_0
