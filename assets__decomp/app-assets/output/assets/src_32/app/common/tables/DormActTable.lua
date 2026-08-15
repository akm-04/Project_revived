local var_0_0 = class("DormActTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.name_ = {}
	arg_1_0.time_ = {}

	import("app.common.tables.TableParser").parse("dorm_act.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.type)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.time_[var_2_0] = xyd.splitToNumber(arg_2_0.time, "|")
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.time(arg_5_0, arg_5_1)
	return arg_5_0.time_[arg_5_1] or {}
end

return var_0_0
