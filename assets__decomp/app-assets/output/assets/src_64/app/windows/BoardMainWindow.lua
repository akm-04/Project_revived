local var_0_0 = class("BoardMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_2_0.levupBtn = arg_2_0:nodeByName("lv_up_flag")
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.lev = arg_2_0.eventCentre.boardLev

	arg_2_0:init()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.BOARD_MISSION_RECEIVE, function(arg_3_0)
		arg_2_0:refreshTaskList()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.BOARD_MISSION_GIVE_UP, function(arg_4_0)
		arg_2_0:refreshTaskList()
	end)
	arg_2_0:updateUpgradeTime()
	arg_2_0:registerUpgrade()
	arg_2_0:updateBoardLev()

	if arg_2_0.eventCentre.boardNewEvolve and arg_2_0.eventCentre.boardNewEvolve == 1 then
		arg_2_0:levupSucceed()
	end

	arg_2_0:nodeByName("refresh_time"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_REFRESH_TIME"))
end

function var_0_0.registerUpgrade(arg_5_0)
	arg_5_0.levupBtn:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_5_0.lev == 5 then
				local var_6_0 = xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.BOARD)
				local var_6_1 = string.format(xyd.tables.translation:translation("HIGHEST_LEV"), var_6_0)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_1
				})

				return
			end

			local var_6_2 = {
				type = xyd.EventCentreBuildingType.BOARD,
				lev = arg_5_0.lev
			}

			xyd.WindowManager.get():openWindow("event_centre_upgrade", var_6_2)
		end
	end)
	arg_5_0:nodeByName("speed_up_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = arg_5_0.eventCentre.boardNeedTime - (xyd.ServerTime.get():getServerTime() - arg_5_0.eventCentre.boardStartTime)
			local var_7_1

			if var_7_0 < 14400 then
				var_7_1 = var_7_0 / 72
			elseif var_7_0 < 43200 then
				var_7_1 = (var_7_0 - 14400) / 144 + 200
			else
				var_7_1 = (var_7_0 - 43200) / 432 + 400
			end

			local var_7_2 = math.ceil(var_7_1)
			local var_7_3 = string.format(var_0_1:translation("COST_TO_UPGRADE"), var_7_2, arg_5_0.lev + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_3, function()
				if var_7_2 > arg_5_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_9_0 = {}

						var_9_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
					end, nil, nil, arg_5_0.colorMode)
				else
					local var_8_0 = {
						type = xyd.EventCentreBuildingType.BOARD
					}

					arg_5_0.eventCentre:speedUpBuilding(var_8_0, function(arg_10_0, arg_10_1)
						if arg_10_0 == xyd.error.OK then
							arg_5_0.eventCentre.boardStartTime = 0
							arg_5_0.eventCentre.boardNeedTime = 0
							arg_5_0.eventCentre.boardLev = arg_10_1.lev
							arg_5_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.BOARD].lev = arg_5_0.eventCentre.boardLev

							arg_5_0:updateUpgradeTime()
							arg_5_0:levupSucceed()
						end
					end)
				end
			end, nil, 0, arg_5_0.colorMode)
		end
	end)
	arg_5_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = var_0_1:translation("CANCEL_UPGRADE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_0, function()
				local var_12_0 = {
					type = xyd.EventCentreBuildingType.BOARD
				}

				arg_5_0.eventCentre:cancelEvolveBuilding(var_12_0, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						arg_5_0.eventCentre.boardStartTime = arg_13_1.building_info.start_time
						arg_5_0.eventCentre.boardNeedTime = arg_13_1.building_info.need_time
						arg_5_0.eventCentre.boardLev = arg_13_1.building_info.lev
						arg_5_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.BOARD].lev = arg_5_0.eventCentre.boardLev

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.REFRESH_MAGIC_RES
						})
						arg_5_0:updateUpgradeTime()

						local var_13_0 = {
							resolve_types = arg_13_1.return_res_id,
							resolve_nums = arg_13_1.return_res_num,
							resolve_crits = {}
						}

						xyd.WindowManager.get():openWindow("recycle_award", var_13_0)
					end
				end)
			end, nil, nil, arg_5_0.colorMode)
		end
	end)
end

function var_0_0.updateUpgradeTime(arg_14_0)
	if arg_14_0.handle1 then
		var_0_2.unscheduleGlobal(arg_14_0.handle1)

		arg_14_0.handle1 = nil
	end

	local var_14_0

	if arg_14_0.eventCentre.boardStartTime > 0 then
		var_14_0 = arg_14_0.eventCentre.boardNeedTime - (xyd.ServerTime.get():getServerTime() - arg_14_0.eventCentre.boardStartTime)

		arg_14_0:nodeByName("upgrade_time_bg"):setVisible(true)
		arg_14_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_14_0))
		arg_14_0.levupBtn:setVisible(false)
	else
		var_14_0 = 0

		arg_14_0:nodeByName("upgrade_time_bg"):setVisible(false)
		arg_14_0.levupBtn:setVisible(true)
	end

	if var_14_0 > 0 then
		arg_14_0:nodeByName("upgrade_time_bg"):setVisible(true)

		arg_14_0.handle1 = var_0_2.scheduleGlobal(function()
			var_14_0 = var_14_0 - 1

			if not tolua.isnull(arg_14_0) then
				arg_14_0:nodeByName("upgrade_time_bg"):setVisible(true)
				arg_14_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_14_0))
				arg_14_0.levupBtn:setVisible(false)
			end

			if var_14_0 <= 0 and arg_14_0.handle1 then
				arg_14_0.eventCentre.boardLev = arg_14_0.eventCentre.boardLev + 1
				arg_14_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.BOARD].lev = arg_14_0.eventCentre.boardLev
				arg_14_0.eventCentre.boardNeedTime = 0
				arg_14_0.eventCentre.boardStartTime = 0

				var_0_2.unscheduleGlobal(arg_14_0.handle1)

				arg_14_0.handle1 = nil

				if not tolua.isnull(arg_14_0) then
					arg_14_0.levupBtn:setVisible(true)
					arg_14_0:nodeByName("upgrade_time_bg"):setVisible(false)
				end
			end
		end, 1)
	else
		arg_14_0:nodeByName("upgrade_time_bg"):setVisible(false)
		arg_14_0.levupBtn:setVisible(true)

		if arg_14_0.handle1 then
			var_0_2.unscheduleGlobal(arg_14_0.handle1)

			arg_14_0.handle1 = nil
		end
	end

	if arg_14_0.eventCentre.boardLev ~= arg_14_0.lev then
		arg_14_0.lev = arg_14_0.eventCentre.boardLev

		arg_14_0:updateBoardLev()
	end
end

function var_0_0.updateBoardLev(arg_16_0)
	arg_16_0:nodeByName("lv_num"):removeAllChildren()

	local var_16_0 = xyd.AssetLoader.get():loadSprite("windows/event_centre/num/words" .. arg_16_0.lev .. ".png")

	arg_16_0:nodeByName("lv_num"):addChild(var_16_0)
end

function var_0_0.levupSucceed(arg_17_0)
	local var_17_0 = {
		type = xyd.EventCentreBuildingType.BOARD
	}

	arg_17_0.eventCentre:confirmBuildingUpgrade(var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			local var_18_0 = {
				type = xyd.EventCentreBuildingType.BOARD,
				lev = arg_17_0.eventCentre.boardLev
			}

			xyd.WindowManager.get():openWindow("building_levelup", var_18_0)

			arg_17_0.eventCentre.boardNewEvolve = 0

			arg_17_0:refreshTaskList()
		end
	end)
end

function var_0_0.init(arg_19_0)
	arg_19_0.eventCentre:getNoticeBoardInfo({}, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			local var_20_0 = {}

			arg_19_0.missionInfos = arg_20_1.mission_list

			arg_19_0:sortMissions()

			arg_19_0.doingMissions = arg_20_1.doing_mission_list
			arg_19_0.finishMissions = arg_20_1.finish_mission_list
			arg_19_0.awardLog = arg_20_1.award_log

			if #arg_19_0.awardLog ~= 0 then
				xyd.WindowManager.get():openWindow("board_task_bonus_window", arg_19_0.awardLog)
				arg_19_0.eventCentre:confirmNewAwardLog({}, function(arg_21_0, arg_21_1)
					if arg_20_0 == xyd.error.OK then
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.REFRESH_MAGIC_RES
						})
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.ALERT_AWARD_CLOSE
						})
					end
				end)
			end
		end

		arg_19_0:drawMissionList()
	end)
end

function var_0_0.sortMissions(arg_22_0)
	local var_22_0 = {}
	local var_22_1 = {}

	for iter_22_0 = 1, #arg_22_0.missionInfos do
		if arg_22_0.missionInfos[iter_22_0].type == 2 then
			table.insert(var_22_0, clone(arg_22_0.missionInfos[iter_22_0]))
		else
			table.insert(var_22_1, clone(arg_22_0.missionInfos[iter_22_0]))
		end
	end

	arg_22_0.missionInfos = {}

	for iter_22_1 = 1, #var_22_1 do
		table.insert(arg_22_0.missionInfos, var_22_1[iter_22_1])
	end

	for iter_22_2 = 1, #var_22_0 do
		table.insert(arg_22_0.missionInfos, var_22_0[iter_22_2])
	end
end

function var_0_0.didOpen(arg_23_0, arg_23_1)
	var_0_0.super:didOpen(arg_23_1)

	arg_23_0.container = arg_23_0:nodeByName("main_container")

	arg_23_0:layout()
end

function var_0_0.drawMissionList(arg_24_0)
	if arg_24_0.attackList ~= nil then
		arg_24_0.attackList:removeAllItems()
	end

	if arg_24_0.taskList ~= nil then
		arg_24_0.taskList:removeAllItems()
	end

	if arg_24_0.historyList ~= nil then
		arg_24_0.historyList:removeAllItems()
	end

	arg_24_0:initTaskList()
	arg_24_0.taskList:reload()
end

function var_0_0.drawAttackList(arg_25_0)
	if arg_25_0.attackList ~= nil then
		arg_25_0.attackList:removeAllItems()
	end

	if arg_25_0.taskList ~= nil then
		arg_25_0.taskList:removeAllItems()
	end

	if arg_25_0.historyList ~= nil then
		arg_25_0.historyList:removeAllItems()
	end

	arg_25_0:initAttackList()
	arg_25_0.attackList:reload()
end

function var_0_0.drawHistoryList(arg_26_0)
	if arg_26_0.attackList ~= nil then
		arg_26_0.attackList:removeAllItems()
	end

	if arg_26_0.taskList ~= nil then
		arg_26_0.taskList:removeAllItems()
	end

	if arg_26_0.historyList ~= nil then
		arg_26_0.historyList:removeAllItems()
	end

	arg_26_0:initHistoryList()
	arg_26_0.historyList:reload()
end

function var_0_0.layout(arg_27_0)
	arg_27_0:registerListeners()
end

function var_0_0.registerListeners(arg_28_0)
	arg_28_0:nodeByName("request_button"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.began then
			-- block empty
		end

		if arg_29_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_28_0:drawMissionList()
		end

		if arg_29_1 == ccui.TouchEventType.canceled then
			-- block empty
		end
	end)
	arg_28_0:nodeByName("attack_button"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.began then
			-- block empty
		end

		if arg_30_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_28_0:drawAttackList()
		end

		if arg_30_1 == ccui.TouchEventType.canceled then
			-- block empty
		end
	end)
	arg_28_0:nodeByName("history_button"):addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.began then
			-- block empty
		end

		if arg_31_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_28_0:drawHistoryList()
		end

		if arg_31_1 == ccui.TouchEventType.canceled then
			-- block empty
		end
	end)
end

function var_0_0.initTaskList(arg_32_0)
	arg_32_0.taskList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(65, 15, arg_32_0:nodeByName("message_bottom"):getContentSize().width, arg_32_0:nodeByName("message_bottom"):getContentSize().height - 40),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_32_0:nodeByName("message_bottom")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_32_0.taskList:setDelegate(handler(arg_32_0, arg_32_0.taskListDelegate))
end

function var_0_0.scrollListener(arg_33_0, arg_33_1)
	if arg_33_1.name == "began" then
		arg_33_0.scrollViewMoved_ = false
		arg_33_0.prevY_ = arg_33_1.y
	elseif arg_33_1.name == "moved" then
		if 20 <= math.abs(arg_33_1.y - arg_33_0.prevY_) then
			arg_33_0.scrollViewMoved_ = true
		end

		arg_33_0.itemCellContent:setVisible(true)
	elseif arg_33_1.name == "ended" then
		arg_33_0.itemCellContent:setVisible(false)
	end
end

function var_0_0.taskListDelegate(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	local var_34_0
	local var_34_1 = 0
	local var_34_2 = arg_34_0.taskList

	if cc.ui.UIListView.COUNT_TAG == arg_34_2 then
		return #arg_34_0.missionInfos + 1
	elseif cc.ui.UIListView.CELL_TAG == arg_34_2 then
		if arg_34_3 == 1 then
			local var_34_3 = var_34_2:dequeueItem()

			if not var_34_3 then
				var_34_3 = var_34_2:newItem()
			else
				var_34_3:removeAllChildren(true)
			end

			arg_34_0.itemCellContent = xyd.AssetLoader.get():loadLabel({
				size = 30,
				text = xyd.tables.translation:translation("EVENT_CENTRE_BOARD_REFRESH_TIME")
			})

			local var_34_4 = {}

			arg_34_0.itemCellContent:setPosition(385, (var_34_1 - arg_34_3 - 1) * 150 + 34)
			arg_34_0.itemCellContent:setTextColor(cc.c4b(253, 207, 0, 255))

			local var_34_5 = arg_34_0.itemCellContent:getContentSize()

			var_34_3:addContent(arg_34_0.itemCellContent)
			var_34_3:setItemSize(993, var_34_5.height + 7)

			return var_34_3
		end

		local var_34_6 = var_34_2:dequeueItem()

		if not var_34_6 then
			var_34_6 = var_34_2:newItem()
		else
			var_34_6:removeAllChildren(true)
		end

		local var_34_7
		local var_34_8 = import("app.windows.BoardMissionItem").new(arg_34_0.missionInfos[arg_34_3 - 1])
		local var_34_9 = {}

		var_34_8:setPosition(0, (var_34_1 - arg_34_3 - 1) * 150 + 34)

		local var_34_10 = var_34_8:getContentSize()

		var_34_6:addContent(var_34_8)
		var_34_6:setItemSize(var_34_10.width + 5, var_34_10.height + 7)

		return var_34_6
	end
end

function var_0_0.initAttackList(arg_35_0)
	arg_35_0.attackList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(65, 15, arg_35_0:nodeByName("message_bottom"):getContentSize().width, arg_35_0:nodeByName("message_bottom"):getContentSize().height - 40),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_35_0:nodeByName("message_bottom")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_35_0.attackList:setDelegate(handler(arg_35_0, arg_35_0.attackListDelegate))
end

function var_0_0.attackListDelegate(arg_36_0, arg_36_1, arg_36_2, arg_36_3)
	local var_36_0
	local var_36_1 = 0
	local var_36_2 = arg_36_0.attackList

	if cc.ui.UIListView.COUNT_TAG == arg_36_2 then
		return #arg_36_0.doingMissions
	elseif cc.ui.UIListView.CELL_TAG == arg_36_2 then
		local var_36_3 = var_36_2:dequeueItem()

		if not var_36_3 then
			var_36_3 = var_36_2:newItem()
		else
			var_36_3:removeAllChildren(true)
		end

		local var_36_4
		local var_36_5 = import("app.windows.BoardAttackTaskItem").new(arg_36_0.doingMissions[arg_36_3])
		local var_36_6 = {}

		var_36_5:setPosition(0, (var_36_1 - arg_36_3) * 150)

		local var_36_7 = var_36_5:getContentSize()

		var_36_3:addContent(var_36_5)
		var_36_3:setItemSize(var_36_7.width + 5, var_36_7.height + 7)

		return var_36_3
	end
end

function var_0_0.initHistoryList(arg_37_0)
	arg_37_0.historyList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(65, 15, arg_37_0:nodeByName("message_bottom"):getContentSize().width, arg_37_0:nodeByName("message_bottom"):getContentSize().height - 40),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_37_0:nodeByName("message_bottom")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_37_0.historyList:setDelegate(handler(arg_37_0, arg_37_0.historyListDelegate))
end

function var_0_0.historyListDelegate(arg_38_0, arg_38_1, arg_38_2, arg_38_3)
	local var_38_0
	local var_38_1 = 0
	local var_38_2 = arg_38_0.historyList

	if cc.ui.UIListView.COUNT_TAG == arg_38_2 then
		return #arg_38_0.finishMissions
	elseif cc.ui.UIListView.CELL_TAG == arg_38_2 then
		local var_38_3 = var_38_2:dequeueItem()

		if not var_38_3 then
			var_38_3 = var_38_2:newItem()
		else
			var_38_3:removeAllChildren(true)
		end

		local var_38_4
		local var_38_5 = import("app.windows.BoardHistoryItem").new(arg_38_0.finishMissions[arg_38_3])
		local var_38_6 = {}

		var_38_5:setPosition(0, (var_38_1 - arg_38_3) * 150)

		local var_38_7 = var_38_5:getContentSize()

		var_38_3:addContent(var_38_5)
		var_38_3:setItemSize(var_38_7.width + 5, var_38_7.height + 7)

		return var_38_3
	end
end

function var_0_0.refreshTaskList(arg_39_0)
	arg_39_0:init()
	arg_39_0:drawMissionList()
end

function var_0_0.refreshAttackList(arg_40_0)
	arg_40_0:init()
	arg_40_0:drawAttackList()
end

return var_0_0
