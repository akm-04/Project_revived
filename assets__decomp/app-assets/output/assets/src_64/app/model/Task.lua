local var_0_0 = class("Task", import(".BaseModel"))
local var_0_1 = xyd.tables.mission

function var_0_0.ctor(arg_1_0)
	arg_1_0.curTaskType = xyd.TaskType.DAILY
	arg_1_0.tasks = {}
	arg_1_0.huoyueInfo = {}
	arg_1_0.taskLoadCache = {}
end

function var_0_0.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.UPDATE_MISSION_ONTIME, handler(arg_2_0, arg_2_0.loadTaskByType))
end

function var_0_0.onTaskBackendEvent(arg_3_0, arg_3_1)
	local var_3_0 = 0

	if arg_3_1.daily_mission_ then
		for iter_3_0, iter_3_1 in ipairs(arg_3_1.daily_mission_) do
			if not arg_3_0.tasks[xyd.TaskType.DAILY] then
				arg_3_0.tasks[xyd.TaskType.DAILY] = {}
			end

			arg_3_0.tasks[xyd.TaskType.DAILY][iter_3_1.table_id] = iter_3_1
		end

		var_3_0 = 1
	end

	if arg_3_1.mainline_mission_ then
		for iter_3_2, iter_3_3 in ipairs(arg_3_1.mainline_mission_) do
			if not arg_3_0.tasks[xyd.TaskType.GROW] then
				arg_3_0.tasks[xyd.TaskType.GROW] = {}
			end

			arg_3_0.tasks[xyd.TaskType.GROW][iter_3_3.table_id] = iter_3_3
		end

		var_3_0 = 1
	end

	if arg_3_1.partner_mission_ then
		for iter_3_4, iter_3_5 in pairs(arg_3_1.partner_mission_) do
			if not arg_3_0.tasks[xyd.TaskType.PARTNER] then
				arg_3_0.tasks[xyd.TaskType.PARTNER] = {}
			end

			if iter_3_5 and next(iter_3_5) then
				for iter_3_6, iter_3_7 in pairs(iter_3_5) do
					dump(iter_3_7)

					local var_3_1 = tonumber(iter_3_6)

					iter_3_7.hero_id = var_3_1

					if not arg_3_0.tasks[xyd.TaskType.PARTNER][var_3_1] then
						arg_3_0.tasks[xyd.TaskType.PARTNER][var_3_1] = {}
					else
						arg_3_0.tasks[xyd.TaskType.PARTNER][var_3_1][iter_3_7.table_id] = iter_3_7
					end
				end
			end
		end

		var_3_0 = 1
	end

	if arg_3_1.awake_mission_ then
		for iter_3_8, iter_3_9 in ipairs(arg_3_1.awake_mission_) do
			if not arg_3_0.tasks[xyd.TaskType.AWAKE] then
				arg_3_0.tasks[xyd.TaskType.AWAKE] = {}
			end

			arg_3_0.tasks[xyd.TaskType.AWAKE][iter_3_9.table_id] = iter_3_9
		end

		var_3_0 = 1
	end

	if arg_3_1.twice_awake_mission_ then
		for iter_3_10, iter_3_11 in ipairs(arg_3_1.twice_awake_mission_) do
			if not arg_3_0.tasks[xyd.TaskType.AWAKE] then
				arg_3_0.tasks[xyd.TaskType.AWAKE] = {}
			end

			arg_3_0.tasks[xyd.TaskType.AWAKE][iter_3_11.table_id] = iter_3_11
		end

		var_3_0 = 1
	end

	if arg_3_1.story_mission_ then
		for iter_3_12, iter_3_13 in ipairs(arg_3_1.story_mission_) do
			if not arg_3_0.tasks[xyd.TaskType.STORY] then
				arg_3_0.tasks[xyd.TaskType.STORY] = {}
			end

			arg_3_0.tasks[xyd.TaskType.STORY][iter_3_13.table_id] = iter_3_13
		end

		var_3_0 = 1
	end

	if arg_3_1.pet_awake_mission_ then
		for iter_3_14, iter_3_15 in ipairs(arg_3_1.pet_awake_mission_) do
			if not arg_3_0.tasks[xyd.TaskType.AWAKE] then
				arg_3_0.tasks[xyd.TaskType.AWAKE] = {}
			end

			arg_3_0.tasks[xyd.TaskType.AWAKE][iter_3_15.table_id] = iter_3_15
		end

		var_3_0 = 1
	end

	if var_3_0 > 0 then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.ON_MISSION_STATE_CHANGE
		})
	end
end

function var_0_0.loadTaskByType(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	arg_4_1 = arg_4_1 or arg_4_0.curTaskType
	arg_4_3 = arg_4_3 or false

	if arg_4_1 == xyd.TaskType.CHALLENGE then
		xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS):loadInfo(arg_4_2)

		return
	end

	if not arg_4_3 and arg_4_0.taskLoadCache[arg_4_1] then
		if arg_4_2 then
			arg_4_2(xyd.error.OK)
		end

		return
	end

	local var_4_0 = {
		mission_type = arg_4_1
	}

	xyd.Backend.get():request(xyd.mid.TASK_LOAD_BY_TYPE, var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0.taskLoadCache[arg_4_1] = 1

			arg_4_0:initData(arg_5_1, arg_4_1)

			if arg_4_2 then
				arg_4_2(arg_5_0)
			end
		end
	end)
end

function var_0_0.initData(arg_6_0, arg_6_1, arg_6_2)
	arg_6_0.tasks[arg_6_2] = {}

	if arg_6_1.mission_list and next(arg_6_1.mission_list) then
		if arg_6_2 == 6 then
			for iter_6_0, iter_6_1 in pairs(arg_6_1.mission_list) do
				if iter_6_1[1] and next(iter_6_1[1]) and iter_6_1[1].table_id then
					local var_6_0 = tonumber(iter_6_0)

					iter_6_1[1].hero_id = var_6_0
					arg_6_0.tasks[arg_6_2][var_6_0] = {}
					arg_6_0.tasks[arg_6_2][var_6_0][iter_6_1[1].table_id] = iter_6_1[1]
				end
			end
		else
			for iter_6_2, iter_6_3 in ipairs(arg_6_1.mission_list) do
				if iter_6_3 and next(iter_6_3) and iter_6_3.table_id then
					arg_6_0.tasks[arg_6_2][iter_6_3.table_id] = iter_6_3
				end
			end
		end
	end

	if arg_6_1.extra_info then
		arg_6_0.dailyLeftTime = arg_6_1.extra_info.daily_left_time

		local var_6_1 = arg_6_1.extra_info.huoyue_info

		if var_6_1 then
			arg_6_0.huoyueInfo.weekHuoyue = var_6_1.week_huoyue or 0
			arg_6_0.huoyueInfo.weekAward = var_6_1.week_award or {}
			arg_6_0.huoyueInfo.dayHuoyue = var_6_1.day_huoyue or 0
			arg_6_0.huoyueInfo.dayAward = var_6_1.day_award or {}
		end
	end
end

function var_0_0.getTaskReward(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if not arg_7_1 or not arg_7_2 then
		return
	end

	local var_7_0 = {
		table_id = arg_7_1
	}

	xyd.Backend.get():request(xyd.mid.TAKE_MISSION_AWARD, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			if arg_7_1 ~= xyd.MissionIDs.DAILY.MONTH_CARD and arg_7_1 ~= xyd.MissionIDs.DAILY.WEEK_CARD and arg_7_1 ~= xyd.MissionIDs.DAILY.ENERGY_MONTH_CARD and arg_7_1 ~= xyd.MissionIDs.DAILY.PRIVILEGE_MONTH_CARD then
				arg_7_0:removeTask(arg_7_1, arg_7_2)
			else
				arg_7_0.tasks[arg_7_2][arg_7_1].is_reward = 1
			end

			arg_7_0:addHuoyue(var_0_1:medal(arg_7_1))
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ON_MISSION_STATE_CHANGE
			})
		end

		if arg_7_3 then
			arg_7_3(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.getPartnerTaskReward(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	if not arg_9_1 or not arg_9_2 or not arg_9_3 then
		return
	end

	local var_9_0 = {
		table_id = arg_9_1,
		hero_table_id = arg_9_2
	}

	xyd.Backend.get():request(xyd.mid.TAKE_MISSION_AWARD, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0:removePartnerTask(arg_9_2, arg_9_1, arg_9_3)
			arg_9_0:addHuoyue(var_0_1:medal(arg_9_1))
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ON_MISSION_STATE_CHANGE
			})
		end

		if arg_9_4 then
			arg_9_4(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.getDailyHuoyueAward(arg_11_0, arg_11_1, arg_11_2)
	if not arg_11_1 or arg_11_1 <= 0 then
		return
	end

	local var_11_0 = {
		index = arg_11_1
	}

	xyd.Backend.get():request(xyd.mid.GET_DAY_HUOYUE_AWARD, var_11_0, function(arg_12_0, arg_12_1)
		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.getWeekHuoyueAward(arg_13_0, arg_13_1, arg_13_2)
	if not arg_13_1 or arg_13_1 <= 0 then
		return
	end

	local var_13_0 = {
		index = arg_13_1
	}

	xyd.Backend.get():request(xyd.mid.GET_WEEK_HUOYUE_AWARD, var_13_0, function(arg_14_0, arg_14_1)
		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.openAwakeTask(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if not arg_15_1 or not arg_15_2 then
		return
	end

	local var_15_0 = {
		mission_id = arg_15_1,
		awake_type = arg_15_2
	}

	xyd.Backend.get():request(xyd.mid.TASK_AWAKE_OPEN, var_15_0, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			if arg_15_2 == xyd.AwakeType.HERO_TWICE then
				local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_16_1 = var_0_1:beforeAwakenID(arg_15_1)
				local var_16_2 = var_16_0:getHeroByTableID(var_16_1)

				if var_16_2 then
					var_16_2:setAwakeTwiceStage(var_0_1:stage(arg_15_1))
				end
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ON_MISSION_STATE_CHANGE
			})
		end

		if arg_15_3 then
			arg_15_3(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.giveUpTask(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	if not arg_17_1 or not arg_17_2 then
		return
	end

	local var_17_0 = {
		mission_id = arg_17_1,
		awake_type = arg_17_2
	}

	xyd.Backend.get():request(xyd.mid.TASK_AWAKE_GIVE_UP, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			local var_18_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if arg_17_2 == xyd.AwakeType.HERO_TWICE then
				local var_18_1 = var_0_1:beforeAwakenID(arg_17_1)
				local var_18_2 = var_18_0:getHeroByTableID(var_18_1)

				if var_18_2 then
					var_18_2:setAwakeTwiceStage(0)
				end
			end

			local var_18_3 = var_0_1:getGiveUpDelItems(arg_17_1)

			if var_18_3 and next(var_18_3) then
				local var_18_4 = var_18_0:getBackpack()

				for iter_18_0, iter_18_1 in ipairs(var_18_3) do
					var_18_4:delItem(iter_18_1)
				end
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ON_MISSION_STATE_CHANGE
			})
		end

		if arg_17_3 then
			arg_17_3(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.getAwakeItem(arg_19_0, arg_19_1)
	local var_19_0 = {
		item_num = 1
	}

	xyd.Backend.get():request(xyd.mid.GET_AWAKE_ITEM, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			local var_20_0 = xyd.tables.misc.awakeItem

			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():removeItem({
				itemNum = 1,
				itemID = var_20_0
			})
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ON_MISSION_STATE_CHANGE
			})
		end

		if arg_19_1 then
			arg_19_1(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.clearTaskCache(arg_21_0)
	arg_21_0.curTaskType = xyd.TaskType.DAILY
	arg_21_0.taskLoadCache = {}
end

function var_0_0.getTaskByType(arg_22_0, arg_22_1)
	arg_22_1 = arg_22_1 or xyd.TaskType.DAILY

	return arg_22_0:sortTasks(arg_22_1)
end

function var_0_0.sortTasks(arg_23_0, arg_23_1)
	arg_23_1 = arg_23_1 or arg_23_0.curTaskType

	local var_23_0

	if arg_23_1 == xyd.TaskType.DAILY then
		var_23_0 = arg_23_0:filterDailyTask()
	elseif arg_23_1 == xyd.TaskType.PARTNER then
		var_23_0 = arg_23_0:getPartnerTaskList(arg_23_1)
	else
		var_23_0 = arg_23_0:getTaskList(arg_23_1)
	end

	if arg_23_1 == xyd.TaskType.DAILY then
		table.sort(var_23_0, function(arg_24_0, arg_24_1)
			if arg_24_0.is_reward ~= arg_24_1.is_reward then
				return arg_24_0.is_reward < arg_24_1.is_reward
			elseif arg_24_0.is_complete ~= arg_24_1.is_complete then
				return arg_24_0.is_complete > arg_24_1.is_complete
			else
				return arg_24_0.table_id > arg_24_1.table_id
			end
		end)
	elseif arg_23_1 == xyd.TaskType.AWAKE then
		table.sort(var_23_0, function(arg_25_0, arg_25_1)
			if arg_25_0.is_complete ~= arg_25_1.is_complete then
				return arg_25_0.is_complete > arg_25_1.is_complete
			elseif arg_25_0.is_going ~= arg_25_1.is_going then
				return arg_25_0.is_going > arg_25_1.is_going
			elseif arg_25_0.awake_type ~= arg_25_1.awake_type then
				return arg_25_0.awake_type < arg_25_1.awake_type
			end
		end)
	elseif arg_23_1 == xyd.TaskType.PARTNER then
		table.sort(var_23_0, function(arg_26_0, arg_26_1)
			if arg_26_0.is_complete ~= arg_26_1.is_complete then
				return arg_26_0.is_complete > arg_26_1.is_complete
			else
				return arg_26_0.table_id < arg_26_1.table_id
			end
		end)
	else
		table.sort(var_23_0, function(arg_27_0, arg_27_1)
			if arg_27_0.is_complete ~= arg_27_1.is_complete then
				return arg_27_0.is_complete > arg_27_1.is_complete
			else
				return arg_27_0.table_id > arg_27_1.table_id
			end
		end)
	end

	return var_23_0
end

function var_0_0.getTaskList(arg_28_0, arg_28_1)
	if not arg_28_0.tasks[arg_28_1] or not next(arg_28_0.tasks[arg_28_1]) then
		return {}
	end

	local var_28_0 = {}

	for iter_28_0, iter_28_1 in pairs(arg_28_0.tasks[arg_28_1]) do
		if iter_28_1 and next(iter_28_1) and var_0_1:display(iter_28_1.table_id) == 1 then
			table.insert(var_28_0, iter_28_1)
		end
	end

	return var_28_0
end

function var_0_0.getPartnerTaskList(arg_29_0, arg_29_1)
	if not arg_29_0.tasks[arg_29_1] or not next(arg_29_0.tasks[arg_29_1]) then
		return {}
	end

	local var_29_0 = {}

	for iter_29_0, iter_29_1 in pairs(arg_29_0.tasks[arg_29_1]) do
		if iter_29_1 and next(iter_29_1) then
			for iter_29_2, iter_29_3 in pairs(iter_29_1) do
				if iter_29_3 and next(iter_29_3) and var_0_1:display(iter_29_3.table_id) == 1 then
					table.insert(var_29_0, iter_29_3)
				end
			end
		end
	end

	return var_29_0
end

function var_0_0.getTaskIDs(arg_30_0, arg_30_1)
	if not arg_30_0.tasks[arg_30_1] or not next(arg_30_0.tasks[arg_30_1]) then
		return {}
	end

	local var_30_0 = {}

	for iter_30_0, iter_30_1 in pairs(arg_30_0.tasks[arg_30_1]) do
		if iter_30_1 and next(iter_30_1) and var_0_1:display(iter_30_1.table_id) == 1 then
			table.insert(var_30_0, iter_30_1.table_id)
		end
	end

	return var_30_0
end

function var_0_0.filterDailyTask(arg_31_0)
	local var_31_0 = {}

	if not arg_31_0.tasks[xyd.TaskType.DAILY] then
		return var_31_0
	end

	local var_31_1 = xyd.ServerTime.get():getSecondsOfDay()

	for iter_31_0, iter_31_1 in pairs(arg_31_0.tasks[xyd.TaskType.DAILY]) do
		if var_0_1:display(iter_31_1.table_id) == 1 then
			local var_31_2 = var_0_1:task_req(iter_31_1.table_id)

			if var_31_2 == 111 then
				local var_31_3 = var_0_1:task_num(iter_31_1.table_id)[1]
				local var_31_4 = var_0_1:task_num(iter_31_1.table_id)[2]

				if var_31_3 < var_31_1 and var_31_1 < var_31_4 then
					table.insert(var_31_0, iter_31_1)
				end
			elseif var_31_2 == 118 then
				local var_31_5 = false
				local var_31_6 = var_0_1:task_num(iter_31_1.table_id)[1]
				local var_31_7 = 18000

				if var_31_6 - var_31_1 > 0 and var_31_6 - var_31_1 < 7200 then
					var_31_5 = true
				end

				if var_31_6 < var_31_1 or var_31_1 < var_31_7 then
					var_31_5 = true
				end

				if var_31_5 then
					table.insert(var_31_0, iter_31_1)
				end
			else
				table.insert(var_31_0, iter_31_1)
			end
		end
	end

	return var_31_0
end

function var_0_0.setCurTaskType(arg_32_0, arg_32_1)
	if not arg_32_1 then
		return
	end

	arg_32_0.curTaskType = arg_32_1
end

function var_0_0.getCurTaskType(arg_33_0)
	return arg_33_0.curTaskType
end

function var_0_0.getDailyHuoyue(arg_34_0)
	return arg_34_0.huoyueInfo.dayHuoyue
end

function var_0_0.getDailyHuoyueAwards(arg_35_0)
	return arg_35_0.huoyueInfo.dayAward
end

function var_0_0.getWeekHuoyue(arg_36_0)
	return arg_36_0.huoyueInfo.weekHuoyue
end

function var_0_0.getWeeklyHuoyueAwards(arg_37_0)
	return arg_37_0.huoyueInfo.weekAward
end

function var_0_0.removeTask(arg_38_0, arg_38_1, arg_38_2)
	arg_38_2 = arg_38_2 or arg_38_0.curTaskType

	if arg_38_0.tasks[arg_38_2][arg_38_1] then
		arg_38_0.tasks[arg_38_2][arg_38_1] = nil
	end
end

function var_0_0.removePartnerTask(arg_39_0, arg_39_1, arg_39_2, arg_39_3)
	arg_39_3 = arg_39_3 or arg_39_0.curTaskType

	if arg_39_0.tasks[arg_39_3][arg_39_1] then
		arg_39_0.tasks[arg_39_3][arg_39_1][arg_39_2] = nil
	end
end

function var_0_0.addHuoyue(arg_40_0, arg_40_1)
	arg_40_0.huoyueInfo.dayHuoyue = (arg_40_0.huoyueInfo.dayHuoyue or 0) + arg_40_1
	arg_40_0.huoyueInfo.weekHuoyue = (arg_40_0.huoyueInfo.weekHuoyue or 0) + arg_40_1
end

function var_0_0.setDailyHuoyueAwards(arg_41_0, arg_41_1)
	arg_41_0.huoyueInfo.dayAward[arg_41_1] = 1
end

function var_0_0.setWeeklyHuoyueAwards(arg_42_0, arg_42_1)
	arg_42_0.huoyueInfo.weekAward[arg_42_1] = 1
end

function var_0_0.isHasAwakeOpen(arg_43_0, arg_43_1)
	local var_43_0 = arg_43_0.tasks[xyd.TaskType.AWAKE]

	if not var_43_0 or not next(var_43_0) then
		return false
	end

	for iter_43_0, iter_43_1 in pairs(var_43_0) do
		if iter_43_1.is_going == 1 and iter_43_1.awake_type == arg_43_1 and iter_43_1.is_reward == 0 then
			return iter_43_1.table_id
		end
	end

	return false
end

function var_0_0.isActiveAwake(arg_44_0, arg_44_1, arg_44_2)
	if not arg_44_0.tasks[xyd.TaskType.AWAKE] or not next(arg_44_0.tasks[xyd.TaskType.AWAKE]) then
		return false
	end

	for iter_44_0, iter_44_1 in pairs(arg_44_0.tasks[xyd.TaskType.AWAKE]) do
		if iter_44_1.awake_type == arg_44_2 and var_0_1:beforeAwakenID(iter_44_0) == arg_44_1 then
			return iter_44_0, iter_44_1.is_going == 1
		end
	end

	return false
end

function var_0_0.isAwaking(arg_45_0, arg_45_1, arg_45_2)
	if not arg_45_0.tasks[xyd.TaskType.AWAKE] or not next(arg_45_0.tasks[xyd.TaskType.AWAKE]) then
		return false
	end

	for iter_45_0, iter_45_1 in pairs(arg_45_0.tasks[xyd.TaskType.AWAKE]) do
		if iter_45_1.awake_type == arg_45_2 and var_0_1:beforeAwakenID(iter_45_0) == arg_45_1 and iter_45_1.is_going == 1 then
			return iter_45_0
		end
	end

	return false
end

function var_0_0.getTaskByID(arg_46_0, arg_46_1, arg_46_2)
	if arg_46_0.tasks[arg_46_2] and arg_46_0.tasks[arg_46_2][arg_46_1] then
		return arg_46_0.tasks[arg_46_2][arg_46_1]
	end

	return nil
end

return var_0_0
