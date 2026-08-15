local var_0_0 = class("DormHouseKeyTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}

	import("app.common.tables.TableParser").parse("dorm_house_key.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.key)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.getAllKeysByType(arg_5_0, arg_5_1)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_0.ids_) do
		if arg_5_0:type(iter_5_1) == arg_5_1 then
			table.insert(var_5_0, iter_5_1)
		end
	end

	return var_5_0
end

return var_0_0
