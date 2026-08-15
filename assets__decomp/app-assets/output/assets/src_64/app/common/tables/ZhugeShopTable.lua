local var_0_0 = class("ZhugeShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.types_ = {}
	arg_1_0.values_ = {}

	import("app.common.tables.TableParser").parse("zhuge_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
		arg_1_0.types_[var_2_0] = xyd.splitToNumber(arg_2_0.type, "|")
		arg_1_0.values_[var_2_0] = xyd.splitToNumber(arg_2_0.value, "|")
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.cost(arg_4_0, arg_4_1)
	return arg_4_0.cost_[arg_4_1] or 0
end

function var_0_0.types(arg_5_0, arg_5_1)
	return arg_5_0.types_[arg_5_1] or {}
end

function var_0_0.values(arg_6_0, arg_6_1)
	return arg_6_0.values_[arg_6_1] or {}
end

return var_0_0
