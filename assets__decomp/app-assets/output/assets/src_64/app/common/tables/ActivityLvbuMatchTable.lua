local var_0_0 = class("ActivityLvbuMatchTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.dollars_ = {}
	arg_1_0.point_ = {}

	import("app.common.tables.TableParser").parse("activity_lvbu_match.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.dollars_[var_2_0] = tonumber(arg_2_0.dollars)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.dollars(arg_4_0, arg_4_1)
	return arg_4_0.dollars_[arg_4_1] or 0
end

function var_0_0.point(arg_5_0, arg_5_1)
	return arg_5_0.point_[arg_5_1] or 0
end

return var_0_0
