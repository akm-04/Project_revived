local var_0_0 = class("ServerSelectTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.image_ = {}
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("server_select.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.image_[var_2_0] = arg_2_0.image
		arg_1_0.name_[var_2_0] = arg_2_0.server_name
	end)
end

function var_0_0.image(arg_3_0, arg_3_1)
	return arg_3_0.image_[arg_3_1] or ""
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

return var_0_0
