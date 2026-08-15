local var_0_0 = class("ChampionsLeagueAwardInfoTable")
local var_0_1 = 3

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.gift_ = {}

	for iter_1_0 = 1, var_0_1 do
		arg_1_0.range_[iter_1_0] = {}
		arg_1_0.gift_[iter_1_0] = {}
	end

	import("app.common.tables.TableParser").parse("cross_arena_daily_reward1.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)
		local var_2_1 = tonumber(arg_2_0.group)

		arg_1_0.range_[var_2_1][var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.gift_[var_2_1][var_2_0] = tonumber(arg_2_0.gift)
	end)
	import("app.common.tables.TableParser").parse("cross_arena_daily_reward2.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id)
		local var_3_1 = tonumber(arg_3_0.group)

		arg_1_0.range_[var_3_1][var_3_0] = tonumber(arg_3_0.range)
		arg_1_0.gift_[var_3_1][var_3_0] = tonumber(arg_3_0.gift)
	end)
	import("app.common.tables.TableParser").parse("cross_arena_daily_reward3.lua", function(arg_4_0)
		local var_4_0 = tonumber(arg_4_0.id)
		local var_4_1 = tonumber(arg_4_0.group)

		arg_1_0.range_[var_4_1][var_4_0] = tonumber(arg_4_0.range)
		arg_1_0.gift_[var_4_1][var_4_0] = tonumber(arg_4_0.gift)
	end)
end

function var_0_0.getGiftIdByInfo(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = 0

	for iter_5_0 = 1, #arg_5_0.range_[arg_5_1] do
		var_5_0 = iter_5_0

		if arg_5_2 <= arg_5_0.range_[arg_5_1][iter_5_0] then
			break
		end
	end

	return arg_5_0.gift_[arg_5_1][var_5_0]
end

return var_0_0
