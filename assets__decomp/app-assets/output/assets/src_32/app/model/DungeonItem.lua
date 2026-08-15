local var_0_0 = class("DungeonItem")

function var_0_0.ctor(arg_1_0)
	return
end

function var_0_0.populate(arg_2_0, arg_2_1)
	arg_2_0.isOpen_ = tonumber(arg_2_1.is_open)
	arg_2_0.mapID_ = tonumber(arg_2_1.table_id)
	arg_2_0.passedStageID_ = tonumber(arg_2_1.passed_stage_id)
	arg_2_0.currentStageID_ = tonumber(arg_2_1.current_stage_id)
	arg_2_0.startTime_ = tonumber(arg_2_1.start_time)
	arg_2_0.endTime_ = tonumber(arg_2_1.end_time)

	if arg_2_1.stages then
		arg_2_0.stages_ = {}

		for iter_2_0, iter_2_1 in pairs(arg_2_1.stages) do
			local var_2_0 = import("app.model.DungeonStage").new()

			var_2_0:populate(iter_2_1)
			table.insert(arg_2_0.stages_, var_2_0)
		end
	end
end

function var_0_0.isOpen(arg_3_0)
	return arg_3_0.isOpen_
end

function var_0_0.getMapID(arg_4_0)
	return arg_4_0.mapID_
end

function var_0_0.getPassedStageID(arg_5_0)
	return arg_5_0.passedStageID_
end

function var_0_0.getCurrentStageID(arg_6_0)
	return arg_6_0.currentStageID_
end

function var_0_0.getStartTime(arg_7_0)
	return arg_7_0.startTime_
end

function var_0_0.getEndTime(arg_8_0)
	return arg_8_0.endTime_
end

function var_0_0.getNextOpenDay(arg_9_0)
	local var_9_0 = arg_9_0.startTime_ - xyd.ServerTime.get():getServerTime()

	if var_9_0 > 0 then
		return math.ceil(var_9_0 / 86400)
	else
		return 0
	end
end

function var_0_0.getDungeonType(arg_10_0)
	return xyd.tables.map:dungeonType(arg_10_0.mapID_)
end

function var_0_0.getStages(arg_11_0)
	if arg_11_0.stages_ then
		return arg_11_0.stages_
	else
		return xyd.tables.stage:stages(arg_11_0.mapID_, xyd.StageLevel.NORMAL)
	end
end

function var_0_0.getStageIdx(arg_12_0, arg_12_1)
	local var_12_0 = -1

	for iter_12_0, iter_12_1 in ipairs(arg_12_0:getStages()) do
		if iter_12_1 == arg_12_1 then
			var_12_0 = iter_12_0
		end
	end

	return var_12_0
end

function var_0_0.getDropInfo(arg_13_0)
	return xyd.tables.map:dropInfo(arg_13_0.mapID_)
end

return var_0_0
