local var_0_0 = class("BeachMatchTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.matchGroup = {}

	import("app.common.tables.TableParser").parse("beach_matchup.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.matchGroup[var_2_0] = xyd.splitToNumber(arg_2_0.matchup, ";")
	end)
end

function var_0_0.getMatchGroup(arg_3_0, arg_3_1)
	return arg_3_0.matchGroup[arg_3_1] or {}
end

return var_0_0
