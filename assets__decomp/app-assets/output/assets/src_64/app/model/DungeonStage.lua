local var_0_0 = class("DungeonStage")

function var_0_0.ctor(arg_1_0)
	return
end

function var_0_0.populate(arg_2_0, arg_2_1)
	arg_2_0.stageID_ = tonumber(arg_2_1.table_id)
	arg_2_0.playerID_ = tonumber(arg_2_1.player_id)
	arg_2_0.playerName_ = arg_2_1.player_name
	arg_2_0.startTime_ = tonumber(arg_2_1.start_time)
	arg_2_0.endTime_ = tonumber(arg_2_1.end_time)
end

return var_0_0
