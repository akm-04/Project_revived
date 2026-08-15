local var_0_0 = class("ChampionsLeagueRankAwardInfoTable")
local var_0_1 = 3

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.items_ = {}
	arg_1_0.items_num_ = {}
	arg_1_0.crystal_ = {}

	for iter_1_0 = 1, var_0_1 do
		arg_1_0.range_[iter_1_0] = {}
		arg_1_0.items_[iter_1_0] = {}
		arg_1_0.items_num_[iter_1_0] = {}
		arg_1_0.crystal_[iter_1_0] = {}
	end

	import("app.common.tables.TableParser").parse("cross_arena_final_reward1.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)
		local var_2_1 = 1

		arg_1_0.range_[var_2_1][var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.items_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.item_id, "|")
		arg_1_0.items_num_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.item_num, "|")
		arg_1_0.crystal_[var_2_1][var_2_0] = tonumber(arg_2_0.crystal)
	end)
	import("app.common.tables.TableParser").parse("cross_arena_final_reward2.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id)
		local var_3_1 = 2

		arg_1_0.range_[var_3_1][var_3_0] = tonumber(arg_3_0.range)
		arg_1_0.items_[var_3_1][var_3_0] = xyd.splitToNumber(arg_3_0.item_id, "|")
		arg_1_0.items_num_[var_3_1][var_3_0] = xyd.splitToNumber(arg_3_0.item_num, "|")
		arg_1_0.crystal_[var_3_1][var_3_0] = tonumber(arg_3_0.crystal)
	end)
	import("app.common.tables.TableParser").parse("cross_arena_final_reward3.lua", function(arg_4_0)
		local var_4_0 = tonumber(arg_4_0.id)
		local var_4_1 = 3

		arg_1_0.range_[var_4_1][var_4_0] = tonumber(arg_4_0.range)
		arg_1_0.items_[var_4_1][var_4_0] = xyd.splitToNumber(arg_4_0.item_id, "|")
		arg_1_0.items_num_[var_4_1][var_4_0] = xyd.splitToNumber(arg_4_0.item_num, "|")
		arg_1_0.crystal_[var_4_1][var_4_0] = tonumber(arg_4_0.crystal)
	end)
end

function var_0_0.getItemsIdByInfo(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = 0

	for iter_5_0 = 1, #arg_5_0.range_[arg_5_1] do
		var_5_0 = iter_5_0

		if arg_5_2 <= arg_5_0.range_[arg_5_1][iter_5_0] then
			break
		end
	end

	return {
		ids = arg_5_0.items_[arg_5_1][var_5_0] or {},
		nums = arg_5_0.items_num_[arg_5_1][var_5_0] or {},
		crystal = arg_5_0.crystal_[arg_5_1][var_5_0] or 0
	}
end

function var_0_0.getItems(arg_6_0, arg_6_1)
	return {
		range = arg_6_0.range_[arg_6_1] or {},
		ids = arg_6_0.items_[arg_6_1] or {},
		nums = arg_6_0.items_num_[arg_6_1] or {},
		crystal = arg_6_0.crystal_[arg_6_1] or {}
	}
end

return var_0_0
