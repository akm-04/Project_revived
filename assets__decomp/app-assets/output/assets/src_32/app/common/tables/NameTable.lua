local var_0_0 = class("NameTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.names_ = {}

	local var_1_0 = 1

	import("app.common.tables.TableParser").parse("name.lua", function(arg_2_0)
		arg_1_0.names_[var_1_0] = arg_2_0.name
		var_1_0 = var_1_0 + 1
	end)
end

function var_0_0.getNames(arg_3_0)
	return arg_3_0.names_
end

return var_0_0
