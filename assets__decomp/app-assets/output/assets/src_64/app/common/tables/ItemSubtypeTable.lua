local var_0_0 = class("ItemSubtypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("item_subtype.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

return var_0_0
