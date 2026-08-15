local var_0_0 = class("DreamWorldResourceTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.path_ = {}

	import("app.common.tables.TableParser").parse("dreamworld_map_resource.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.path_[var_2_0] = xyd.split(arg_2_0.png_path, "|")
	end)
end

function var_0_0.path(arg_3_0, arg_3_1)
	return arg_3_0.path_[arg_3_1] or {}
end

return var_0_0
