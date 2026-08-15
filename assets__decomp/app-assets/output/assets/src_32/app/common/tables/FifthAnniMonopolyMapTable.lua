local var_0_0 = class("FifthAnniMonopolyMapTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.typeId_ = {}

	import("app.common.tables.TableParser").parse("fifth_anni_monopoly_map.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.typeId_[var_2_0] = tonumber(arg_2_0.type_id)
	end)
end

function var_0_0.typeId(arg_3_0, arg_3_1)
	return arg_3_0.typeId_[arg_3_1] or 0
end

return var_0_0
