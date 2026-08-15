local var_0_0 = class("GoldMapItemsTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ID_ = {}
	arg_1_0.type_ = {}

	import("app.common.tables.TableParser").parse("gold_map_items_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
	end)
end

function var_0_0.ID(arg_3_0, arg_3_1)
	return arg_3_0.ID_[arg_3_1] or 0
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

return var_0_0
