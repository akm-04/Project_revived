local var_0_0 = class("ModelDefineTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("model_define.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.names(arg_4_0)
	return arg_4_0.name_
end

return var_0_0
