local var_0_0 = class("MazeFloorTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.arenaPlayerModel_ = {}
	arg_1_0.campaignDesc_ = {}
	arg_1_0.fightID_ = {}
	arg_1_0.modelID_ = {}
	arg_1_0.tiliCost_ = {}
	arg_1_0.tableID_ = {}

	import("app.common.tables.TableParser").parse("maze_floor.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.arenaPlayerModel_[var_2_0] = tonumber(arg_2_0.arena_player_display)
		arg_1_0.tiliCost_[var_2_0] = xyd.splitToNumber(arg_2_0.energy_cost, "|")
		arg_1_0.tableID_[var_2_0] = tonumber(arg_2_0.table_id)
	end)
end

function var_0_0.arenaPlayerModel(arg_3_0, arg_3_1)
	return arg_3_0.arenaPlayerModel_[arg_3_1] or 0
end

function var_0_0.tiliCost(arg_4_0, arg_4_1)
	return arg_4_0.tiliCost_[arg_4_1]
end

function var_0_0.tableID(arg_5_0, arg_5_1)
	return arg_5_0.tableID_[arg_5_1]
end

return var_0_0
