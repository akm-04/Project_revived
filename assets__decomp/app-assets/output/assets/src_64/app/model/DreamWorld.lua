local var_0_0 = class("DreamWorld", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 6
local var_0_3 = {
	Challenge = 2,
	Story = 1
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.baseInfo = {}
	arg_1_0.mapDetail = {}
	arg_1_0.mapRoles = {}
	arg_1_0.mazeFog = {}
	arg_1_0.eventIndex = {}
	arg_1_0.coolTimeInfo = {}
	arg_1_0.ticketNum = 0
	arg_1_0.mapType = 0
	arg_1_0.now_pos = 0
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tempInfo = {}
	arg_1_0.lastEventInfo = {}
	arg_1_0.autoEvent = false
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.GET_DREAM_WORLD_INFO, {}, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.baseInfo = arg_4_1.base_info
			arg_3_0.mapType = arg_4_1.base_info.map_type or 0
			arg_3_0.ticketNum = arg_4_1.ticket_num

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.startExplore(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {
		map_type = arg_5_1
	}

	xyd.Backend.get():request(xyd.mid.START_DREAM_WORLD_EXPLORE, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0:dealWithMapDetail(arg_6_1.map_detail)

			arg_5_0.coolTimeInfo = arg_6_1.cooltime_info
			arg_5_0.mapRoles = arg_6_1.map_roles
			arg_5_0.baseInfo = arg_6_1.base_info or arg_5_0.baseInfo
			arg_5_0.mapType = arg_6_1.base_info.map_type or 0
			arg_5_0.ticketNum = arg_5_0.ticketNum - 1

			local var_6_0 = xyd.WindowManager.get():getWindow("dream_world_main")

			if var_6_0 and not tolua.isnull(var_6_0) then
				var_6_0:updateState()
			end

			if arg_5_2 then
				arg_5_2(arg_6_0, arg_6_1)
			end
		end
	end)
end

function var_0_0.getMap(arg_7_0, arg_7_1)
	local var_7_0 = {}

	xyd.Backend.get():request(xyd.mid.GET_DREAM_WORLD_MAP, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0:dealWithMapDetail(arg_8_1.map_detail)

			arg_7_0.coolTimeInfo = arg_8_1.cooltime_info
			arg_7_0.mapRoles = arg_8_1.map_roles
			arg_7_0.baseInfo = arg_8_1.base_info or arg_7_0.baseInfo
			arg_7_0.mapType = arg_8_1.base_info.map_type or 0

			if arg_7_1 then
				arg_7_1(arg_8_0, arg_8_1)
			end
		end
	end)
end

function var_0_0.dealWithMapDetail(arg_9_0, arg_9_1)
	arg_9_0.mapDetail = arg_9_1

	for iter_9_0 = 1, #arg_9_0.mapDetail do
		local var_9_0 = xyd.split(arg_9_0.mapDetail[iter_9_0], "@")

		arg_9_0.mazeFog[iter_9_0] = tonumber(var_9_0[1])
		arg_9_0.eventIndex[iter_9_0] = tonumber(var_9_0[2])
	end
end

function var_0_0.updateMapInfo(arg_10_0, arg_10_1)
	local function var_10_0(arg_11_0, arg_11_1)
		local var_11_0 = {}

		for iter_11_0 = 1, #arg_11_0 do
			if arg_11_0[iter_11_0] ~= arg_11_1[iter_11_0] then
				table.insert(var_11_0, iter_11_0)
			end
		end

		return var_11_0
	end

	local var_10_1 = arg_10_1.pos
	local var_10_2 = var_10_0(arg_10_1.map, arg_10_0.mazeFog)

	xyd.Backend.get():request(xyd.mid.DREAM_WORLD_UPDATE_MAP, {
		open_grid_ids = var_10_2,
		current_grid = var_10_1
	}, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			for iter_12_0 = 1, #var_10_2 do
				arg_10_0.mazeFog[var_10_2[iter_12_0]] = 0
			end

			if callback then
				callback(arg_12_0, arg_12_1)
			end
		end
	end)
end

function var_0_0.setMapInfo(arg_13_0, arg_13_1)
	if arg_13_1.grid_id then
		arg_13_0.tempInfo.grid_id = arg_13_1.grid_id
	end

	if arg_13_1.event_idx then
		arg_13_0.tempInfo.event_idx = arg_13_1.event_idx
	end

	if arg_13_1.map then
		arg_13_0.tempInfo.map = arg_13_1.map
	end

	if arg_13_1.pos then
		arg_13_0.tempInfo.pos = arg_13_1.pos
	end
end

function var_0_0.getMapInfo(arg_14_0)
	return arg_14_0.tempInfo
end

function var_0_0.dealEvent(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {}
	local var_15_1 = (function(arg_16_0, arg_16_1)
		local var_16_0 = {}

		for iter_16_0 = 1, #arg_16_0 do
			if arg_16_0[iter_16_0] ~= arg_16_1[iter_16_0] then
				table.insert(var_16_0, iter_16_0)
			end
		end

		return var_16_0
	end)(arg_15_1.map, arg_15_0.mazeFog)
	local var_15_2 = arg_15_1.pos

	var_15_0.grid_id = arg_15_1.grid_id
	var_15_0.event_idx = arg_15_1.event_idx
	var_15_0.open_grid_ids = var_15_1
	var_15_0.current_grid = var_15_2
	var_15_0.extra_data = arg_15_1.extra_data
	arg_15_0.lastEventInfo = {
		pos = arg_15_1.pos,
		grid_id = arg_15_1.grid_id
	}

	xyd.Backend.get():request(xyd.mid.DREAM_WORLD_DEAL_EVENT, var_15_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			arg_15_0.autoEvent = true
			arg_15_0.baseInfo = arg_17_1.base_info or arg_15_0.baseInfo
			arg_15_0.mapType = arg_17_1.base_info.map_type or 0
			arg_15_0.coolTimeInfo = arg_17_1.cooltime_info or arg_15_0.coolTimeInfo
			arg_15_0.eventIndex[arg_15_1.grid_id] = arg_17_1.grid_info.event_idx
			arg_15_0.mapRoles = arg_17_1.map_roles or arg_15_0.mapRoles

			local var_17_0 = xyd.WindowManager.get():getWindow("dream_world_explore")

			if var_17_0 and not tolua.isnull(var_17_0) then
				var_17_0:updateCell(arg_15_1.grid_id)
			end

			if arg_17_1.awards then
				arg_15_0.selfPlayer:handleRewards(arg_17_1.awards, arg_15_2)
			elseif arg_15_2 then
				arg_15_2(arg_17_0, arg_17_1)
			end

			if arg_15_0.baseInfo.is_going == 0 then
				arg_15_0.autoEvent = false

				local function var_17_1()
					var_17_0 = xyd.WindowManager.get():getWindow("dream_world_explore")

					if var_17_0 and not tolua.isnull(var_17_0) then
						var_17_0:close()
					end

					local var_18_0 = xyd.WindowManager.get():getWindow("dream_world_main")

					if var_18_0 and not tolua.isnull(var_18_0) then
						var_18_0:updateState()
					end
				end

				var_15_0 = {
					txt = var_0_1:translation("DREAM_WORLD_END_TIP"),
					type = xyd.CommonAlertType.ONE_BTN,
					align = xyd.ui_align.CENTER,
					rcallback = var_17_1
				}

				xyd.WindowManager.get():openWindow("common_alert", var_15_0)
			end
		end
	end)
end

function var_0_0.resetCoolTime(arg_19_0, arg_19_1, arg_19_2)
	xyd.Backend.get():request(xyd.mid.DREAM_WORLD_RESET_COOL_TIME, arg_19_1, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			arg_19_0.coolTimeInfo = arg_20_1.cooltime_info or arg_19_0.coolTimeInfo

			if arg_19_2 then
				arg_19_2(arg_20_0, arg_20_1)
			end
		end
	end)
end

function var_0_0.giveUpExplore(arg_21_0, arg_21_1)
	xyd.Backend.get():request(xyd.mid.DREAM_WORLD_GIVE_UP, {}, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0.baseInfo = arg_22_1.base_info or arg_21_0.baseInfo
			arg_21_0.mapType = arg_22_1.base_info.map_type or 0

			local var_22_0 = xyd.WindowManager.get():getWindow("dream_world_explore")

			if var_22_0 and not tolua.isnull(var_22_0) then
				var_22_0:close()
			end

			if arg_21_1 then
				arg_21_1(arg_22_0, arg_22_1)
			end
		end
	end)
end

function var_0_0.getTaskList(arg_23_0, arg_23_1)
	xyd.Backend.get():request(xyd.mid.DREAM_WORLD_GET_TASK_LIST, {}, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			arg_23_0.taskList = arg_24_1.task_list

			if arg_23_1 then
				arg_23_1(arg_24_0, arg_24_1)
			end
		end
	end)
end

function var_0_0.getTaskAward(arg_25_0, arg_25_1, arg_25_2, arg_25_3, arg_25_4)
	local var_25_0 = {
		map_type = arg_25_1,
		task_id = arg_25_2
	}

	xyd.Backend.get():request(xyd.mid.DREAM_WORLD_GET_TASK_AWARD, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			arg_25_0.taskList[arg_25_1][arg_25_3] = arg_26_1.task_info

			if arg_26_1.awards then
				arg_25_0.selfPlayer:handleRewards(arg_26_1.awards, arg_25_4)
			end

			if arg_26_1.is_get_title then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("DREAM_WORLD_TITLE_TIP")
				})
			end
		end
	end)
end

function var_0_0.formatNewHeros(arg_27_0, arg_27_1)
	for iter_27_0, iter_27_1 in pairs(arg_27_1) do
		local var_27_0 = xyd.tables.hero:isCanAwaken(iter_27_1:getFirstTableID())
		local var_27_1 = xyd.tables.hero:isCanAwakeTwice(iter_27_1:getFirstTableID())
		local var_27_2 = {
			100,
			100,
			80,
			60,
			0,
			0
		}
		local var_27_3 = {
			0,
			0,
			0,
			0,
			0,
			0
		}
		local var_27_4 = {
			0,
			0,
			0,
			0,
			0,
			0
		}

		if var_27_1 == 1 then
			var_27_2 = {
				100,
				100,
				80,
				60,
				40,
				40
			}
			var_27_3 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			var_27_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
		elseif var_27_0 == 1 then
			var_27_2 = {
				100,
				100,
				80,
				60,
				40,
				0
			}
			var_27_3 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			var_27_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
		else
			var_27_2 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			var_27_3 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			var_27_4 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
		end

		arg_27_0:renewNewHeroInfo(iter_27_1, var_27_2, var_27_3, var_27_4)
	end
end

function var_0_0.renewNewHeroInfo(arg_28_0, arg_28_1, arg_28_2, arg_28_3, arg_28_4)
	local var_28_0 = xyd.MAX_STAR_LEVEL

	if xyd.getPartnerTypeByTableID(arg_28_1:getTableID()) == xyd.PartnerType.SUPER then
		var_28_0 = 8
	end

	arg_28_1.star_ = var_28_0
	arg_28_1.color_ = 16
	arg_28_1.level_ = 100
	arg_28_1.skillLev_ = {}
	arg_28_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_28_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_28_1.color_ >= xyd.EquipQuality.GREEN then
		arg_28_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_28_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_28_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_28_1.color_ >= xyd.EquipQuality.BLUE then
		arg_28_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_28_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_28_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_28_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_28_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_28_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_28_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_28_1:isCanAwaken() then
		arg_28_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_28_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_28_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	if arg_28_1:isCanAwakeTwice() then
		arg_28_1:setAwakeTwiceStage(xyd.AwakeTwiceStage.COMPLETE)

		arg_28_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = tonumber(arg_28_2[xyd.SKILL_INDEX.AwakeTwice]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.AwakeTwice]
	else
		arg_28_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = false
	end

	arg_28_1.equips_ = {}

	for iter_28_0 = 1, var_0_2 do
		table.insert(arg_28_1.equips_, tonumber(arg_28_4[iter_28_0]))
	end

	arg_28_1.fumo_ = {}

	for iter_28_1 = 1, var_0_2 do
		table.insert(arg_28_1.fumo_, tonumber(arg_28_3[iter_28_1]))
	end

	arg_28_1.fumoLev_ = {}

	for iter_28_2 = 1, var_0_2 do
		local var_28_1 = arg_28_1:getEquipByIndex(iter_28_2)

		table.insert(arg_28_1.fumoLev_, tonumber(var_28_1:getMaxFumoStar()))
	end
end

function var_0_0.formatNewPets(arg_29_0, arg_29_1)
	local var_29_0 = {
		100,
		100,
		80,
		60,
		0
	}

	for iter_29_0, iter_29_1 in pairs(arg_29_1) do
		if iter_29_1:isCanAwaken() then
			local var_29_1 = {
				100,
				100,
				80,
				60,
				40
			}
			local var_29_2 = {
				1,
				1,
				1
			}

			arg_29_0:renewPetInfo(iter_29_1, var_29_1, var_29_2)
		else
			local var_29_3 = {
				100,
				100,
				80,
				60,
				0
			}
			local var_29_4 = {
				0,
				1,
				1
			}

			arg_29_0:renewPetInfo(iter_29_1, var_29_3, var_29_4)
		end

		iter_29_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewPetInfo(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	local var_30_0 = 16

	arg_30_1.level_, arg_30_1.color_ = 100, var_30_0
	arg_30_1.skillLev_ = {}
	arg_30_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_30_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_30_1.color_ >= xyd.EquipQuality.GREEN then
		arg_30_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_30_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_30_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_30_1.color_ >= xyd.EquipQuality.BLUE then
		arg_30_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_30_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_30_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_30_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_30_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_30_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_30_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_30_1:isCanAwaken() then
		arg_30_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_30_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_30_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_30_1.equips_ = {}

	for iter_30_0 = 1, var_0_2 do
		table.insert(arg_30_1.equips_, tonumber(arg_30_3[iter_30_0]))
	end
end

return var_0_0
