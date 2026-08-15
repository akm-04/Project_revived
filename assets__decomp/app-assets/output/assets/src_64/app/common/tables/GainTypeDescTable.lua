local var_0_0 = class("GainTypeDescTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.descs_ = {}

	import("app.common.tables.TableParser").parse("gain_type_desc.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.type)

		arg_1_0.descs_[var_2_0] = arg_2_0.desc
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.descs_[arg_3_1]
end

return var_0_0
