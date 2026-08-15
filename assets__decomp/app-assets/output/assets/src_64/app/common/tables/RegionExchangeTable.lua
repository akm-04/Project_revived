local var_0_0 = class("RegionExchangeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name = {}
	arg_1_0.cost = {}
	arg_1_0.icon = {}

	import("app.common.tables.TableParser").parse("region_exchange.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name[var_2_0] = arg_2_0.name
		arg_1_0.cost[var_2_0] = xyd.splitToNumber(arg_2_0.cost, "|")
		arg_1_0.icon[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.getName(arg_3_0, arg_3_1)
	return arg_3_0.name[arg_3_1] or ""
end

function var_0_0.getCost(arg_4_0, arg_4_1)
	return arg_4_0.cost[arg_4_1] or 0
end

function var_0_0.getIcon(arg_5_0, arg_5_1)
	return arg_5_0.icon[arg_5_1] or ""
end

return var_0_0
