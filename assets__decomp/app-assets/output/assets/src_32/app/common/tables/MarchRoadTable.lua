local var_0_0 = class("MarchRoadTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.xs_ = {}
	arg_1_0.ys_ = {}
	arg_1_0.bxs_ = {}
	arg_1_0.bys_ = {}
	arg_1_0.icons_ = {}

	import("app.common.tables.TableParser").parse("march_road.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.xs_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.ys_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.bxs_[var_2_0] = tonumber(arg_2_0.bx)
		arg_1_0.bys_[var_2_0] = tonumber(arg_2_0.by)
		arg_1_0.icons_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.x(arg_3_0, arg_3_1)
	return arg_3_0.xs_[arg_3_1] or 0
end

function var_0_0.y(arg_4_0, arg_4_1)
	return arg_4_0.ys_[arg_4_1] or 0
end

function var_0_0.bx(arg_5_0, arg_5_1)
	return arg_5_0.bxs_[arg_5_1] or 0
end

function var_0_0.by(arg_6_0, arg_6_1)
	return arg_6_0.bys_[arg_6_1] or 0
end

function var_0_0.icon(arg_7_0, arg_7_1)
	return arg_7_0.icons_[arg_7_1]
end

return var_0_0
