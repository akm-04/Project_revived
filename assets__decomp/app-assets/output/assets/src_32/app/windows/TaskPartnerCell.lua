local var_0_0 = class("TaskPartnerCell", import("app.common.ui.BaseNode"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.mission
local var_0_5 = xyd.tables.hero
local var_0_6 = "#44505B"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0)

	arg_1_0.taskInfo = arg_1_1.taskInfo
	arg_1_0.heroID = arg_1_0.taskInfo.hero_id
	arg_1_0.tableID = arg_1_0.taskInfo.table_id
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)

	arg_1_0:loadRes("windows/task/task_grow_cell.csb")
end

function var_0_0.layout(arg_2_0)
	if arg_2_0.taskInfo.is_complete == 1 then
		arg_2_0:nodeByName("bg_highlight"):setVisible(true)
		arg_2_0:nodeByName("bg_normal"):setVisible(false)
	else
		arg_2_0:nodeByName("bg_highlight"):setVisible(false)
		arg_2_0:nodeByName("bg_normal"):setVisible(true)
	end

	local var_2_0 = var_0_5:name(arg_2_0.heroID)
	local var_2_1 = string.format(var_0_4:name(arg_2_0.tableID), var_2_0)
	local var_2_2 = xyd.createAutoFixLabel({
		height = 40,
		fontSize = 30,
		txtColor = "#4fa6fe",
		width = 505,
		text = var_2_1,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_2_2:addTo(arg_2_0:background())
	var_2_2:setAnchorPoint(0, 0.5)
	var_2_2:setPosition(arg_2_0:nodeByName("pos_txt_name"):getPosition())

	local var_2_3 = var_0_5:name(arg_2_0.heroID)
	local var_2_4 = string.format(var_0_4:des(arg_2_0.tableID), var_2_3)
	local var_2_5 = xyd.createAutoFixLabel({
		height = 50,
		fontSize = 26,
		txtColor = "#6A6977",
		width = 505,
		text = var_2_4,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	var_2_5:addTo(arg_2_0:background())
	var_2_5:setAnchorPoint(0, 1)

	local var_2_6, var_2_7 = arg_2_0:nodeByName("pos_txt_desc"):getPosition()

	var_2_5:setPosition(var_2_6, var_2_7 + 15)

	local var_2_8 = var_0_1.new({
		size = 503,
		color = var_0_6
	})

	var_2_8:addTo(arg_2_0:background())
	var_2_8:setAnchorPoint(0, 0.5)
	var_2_8:setPosition(arg_2_0:nodeByName("pos_splitline"):getPosition())
	arg_2_0:setAwardDisplay()

	if arg_2_0.taskInfo.is_complete == 0 then
		local var_2_9 = arg_2_0:getTaskCondition() or 1
		local var_2_10
		local var_2_11 = var_0_4:getDetailType(arg_2_0.tableID)

		if var_2_11 == xyd.TaskDetailType.COLLEGE_BUILD or var_2_11 == xyd.TaskDetailType.GROWTH_RETURN then
			var_2_10 = arg_2_0.selfPlayer.lev
		elseif var_2_11 == xyd.TaskDetailType.UPGRADE_HERO then
			if arg_2_0.taskInfo.count < var_0_4:task_num(arg_2_0.tableID) then
				var_2_10 = 0
				var_2_9 = 1
			else
				var_2_10 = 1
			end
		else
			var_2_10 = arg_2_0.taskInfo.count
		end

		local var_2_12 = var_2_10 .. "/" .. var_2_9
		local var_2_13 = xyd.createAutoFixLabel({
			height = 30,
			fontSize = 24,
			txtColor = "#4fa6fe",
			width = 150,
			text = var_2_12,
			align = cc.ui.TEXT_VALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_CENTER
		})

		var_2_13:addTo(arg_2_0:background())
		var_2_13:setAnchorPoint(0.5, 0.5)

		local var_2_14, var_2_15 = arg_2_0:nodeByName("pos_txt_progress"):getPosition()

		var_2_13:setPosition(var_2_14, var_2_15 + 6)

		arg_2_0.children_.progress_label = var_2_13

		local var_2_16 = var_0_4:goto_type(arg_2_0.tableID)

		if var_2_16 and var_2_16 > 0 then
			local var_2_17 = "windows/button/btn127_2.png"
			local var_2_18 = var_0_2.new({
				titleSize = 24,
				sprite = var_2_17,
				title = var_0_3:translation("BUTTON_NAME_GO"),
				clickMode = xyd.ButtonClickMode.SCALE
			})

			var_2_18:addTo(arg_2_0:nodeByName("background"))
			var_2_18:setAnchorPoint(0.5, 0.5)
			var_2_18:setPosition(arg_2_0:nodeByName("pos_btn_go"):getPosition())

			arg_2_0.children_.goto_btn = var_2_18
		else
			var_2_13:setPositionY(var_2_15 - 30)
		end
	else
		local var_2_19 = xyd.AssetLoader.get():loadSprite("windows/common/icons/icon_completed.png")

		var_2_19:addTo(arg_2_0:background())
		var_2_19:setAnchorPoint(0.5, 0.5)
		var_2_19:setPosition(arg_2_0:nodeByName("pos_btn_get"):getPosition())
	end

	arg_2_0:onRegister()
end

function var_0_0.setAwardDisplay(arg_3_0)
	local var_3_0 = var_0_4:getDetailType(arg_3_0.tableID)
	local var_3_1 = 85
	local var_3_2 = 36

	if var_3_0 == xyd.TaskDetailType.ADVANCE then
		local var_3_3 = display.newNode()

		var_3_3:setContentSize(var_3_1, var_3_1)
		var_3_3:addTo(arg_3_0:nodeByName("award_container"))
		var_3_3:setAnchorPoint(0, 0)
		var_3_3:setPosition(0, 0)
		xyd.setItemAndAddTips(var_3_3, -2, var_0_4:gold(arg_3_0.tableID))
	elseif var_3_0 == xyd.TaskDetailType.GROWTH_RETURN then
		local var_3_4 = display.newNode()

		var_3_4:setContentSize(var_3_1, var_3_1)
		var_3_4:addTo(arg_3_0:nodeByName("award_container"))
		var_3_4:setAnchorPoint(0, 0)
		var_3_4:setPosition(0, 0)

		if arg_3_0.selfPlayer:isMaxLev() then
			xyd.setItemAndAddTips(var_3_4, -4, var_0_4:marchCoin(arg_3_0.tableID))
		else
			xyd.setItemAndAddTips(var_3_4, -7, var_0_4:exp(arg_3_0.tableID))
		end

		local var_3_5 = display.newNode()

		var_3_5:setContentSize(var_3_1, var_3_1)
		var_3_5:addTo(arg_3_0:nodeByName("award_container"))
		var_3_5:setAnchorPoint(0, 0)
		var_3_5:setPosition(var_3_1 + var_3_2, 0)
		xyd.setItemAndAddTips(var_3_5, tonumber(var_0_4:award(arg_3_0.tableID)), var_0_4:award_num(arg_3_0.tableID))
	elseif var_3_0 == xyd.TaskDetailType.SUMMON and arg_3_0.tableID == xyd.MissionIDs.SUMMON_ZHANGJIAO then
		local var_3_6 = display.newNode()

		var_3_6:setContentSize(var_3_1, var_3_1)
		var_3_6:addTo(arg_3_0:nodeByName("award_container"))
		var_3_6:setAnchorPoint(0, 0)
		var_3_6:setPosition(0, 0)
		xyd.setItemAndAddTips(var_3_6, -2, var_0_4:gold(arg_3_0.tableID))

		local var_3_7 = display.newNode()

		var_3_7:setContentSize(var_3_1, var_3_1)
		var_3_7:addTo(arg_3_0:nodeByName("award_container"))
		var_3_7:setAnchorPoint(0, 0)
		var_3_7:setPosition(var_3_1 + var_3_2, 0)
		xyd.setItemAndAddTips(var_3_7, tonumber(var_0_4:award(arg_3_0.tableID)), var_0_4:award_num(arg_3_0.tableID))
	else
		local var_3_8 = display.newNode()

		var_3_8:setContentSize(var_3_1, var_3_1)
		var_3_8:addTo(arg_3_0:nodeByName("award_container"))
		var_3_8:setAnchorPoint(0, 0)
		var_3_8:setPosition(0, 0)
		xyd.setItemAndAddTips(var_3_8, tonumber(var_0_4:award(arg_3_0.tableID)), var_0_4:award_num(arg_3_0.tableID))
	end
end

function var_0_0.getTaskCondition(arg_4_0)
	if var_0_4:getDetailType(arg_4_0.tableID) == xyd.TaskDetailType.SUMMON then
		if var_0_4:task_req(arg_4_0.tableID) == xyd.TaskReq.SUMMON_SPECIFIC_HERO then
			return 1
		else
			return var_0_4:task_num(arg_4_0.tableID)
		end
	else
		return var_0_4:task_num(arg_4_0.tableID)
	end
end

function var_0_0.setGotoBtn(arg_5_0)
	local var_5_0 = var_0_4:task_req(arg_5_0.tableID)

	if var_5_0 == xyd.TaskReq.CENTER_ACTIVITY_UPGRADE then
		local var_5_1 = var_0_4:goto_type(arg_5_0.tableID)
		local var_5_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

		var_5_2:getBuildingList({}, function(arg_6_0)
			if arg_6_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("event_centre")

				if var_5_1 == xyd.EventCentreBuildingType.CABINET then
					var_5_2:getCabinetInfo(function(arg_7_0)
						if arg_7_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("junk_chest")
						end
					end)
				elseif var_5_1 == xyd.EventCentreBuildingType.DESK then
					var_5_2:getDeskpInfo({}, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							local var_8_0 = {
								deskInfo = arg_8_1
							}

							xyd.WindowManager.get():openWindow("production_table", var_8_0)
						end
					end)
				elseif var_5_1 == xyd.EventCentreBuildingType.TRASH then
					var_5_2:getRecycleInfo({}, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							local var_9_0 = {
								recycleInfo = arg_9_1
							}

							xyd.WindowManager.get():openWindow("recycle", var_9_0)
						end
					end)
				end
			end
		end)
	elseif var_5_0 == xyd.TaskReq.CENTER_ACTIVITY_MISSION then
		local var_5_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

		var_5_3:getBuildingList({}, function(arg_10_0)
			if arg_10_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("event_centre")
				var_5_3:getCabinetInfo(function(arg_11_0)
					if arg_11_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("junk_chest")
					end
				end)
			end
		end)
	end
end

function var_0_0.onRegister(arg_12_0)
	local var_12_0 = arg_12_0:nodeByName("goto_btn")

	if var_12_0 and not tolua.isnull(var_12_0) then
		var_12_0:addTouchEvent(function(arg_13_0)
			if arg_13_0.name == "ended" then
				arg_12_0:setGotoBtn()
			end
		end)
	end

	if arg_12_0.taskInfo.is_complete == 1 then
		local var_12_1 = false
		local var_12_2 = 0
		local var_12_3 = 0

		arg_12_0:setTouchEnabled(true)
		arg_12_0:setTouchSwallowEnabled(false)
		arg_12_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "began" then
				arg_12_0:setScale(0.95)

				var_12_2 = arg_14_0.x
				var_12_3 = arg_14_0.y
				var_12_1 = false
			elseif arg_14_0.name == "moved" then
				if math.abs(arg_14_0.y - var_12_3) > 10 or math.abs(arg_14_0.x - var_12_2) > 10 then
					var_12_1 = true
				end
			elseif arg_14_0.name == "ended" then
				arg_12_0:setScale(1)

				if var_12_1 then
					return
				end

				arg_12_0.task:getPartnerTaskReward(arg_12_0.tableID, arg_12_0.heroID, xyd.TaskType.PARTNER, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK and arg_15_1 and arg_15_1.awards then
						xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_15_1.awards)
					end
				end)
			end

			return true
		end)
	end
end

return var_0_0
