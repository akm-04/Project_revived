local var_0_0 = import("framework.scheduler")
local var_0_1 = class("BoardAttackTaskItem", function()
	return cc.Node:create()
end)

function var_0_1.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView()

	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:contentView():nodeByName("team_leader1"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_TEAM_LEADER1"))
	arg_2_0:contentView():nodeByName("team_leader2"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_TEAM_LEADER2"))
	arg_2_0:contentView():nodeByName("task_rest_time_label"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_TASK_REST_TIME_LABEL"))

	arg_2_0.mission = arg_2_1
	arg_2_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	arg_2_0:layout()
end

function var_0_1.layout(arg_3_0)
	arg_3_0:setCancelBtn()
	arg_3_0:registerTouchEvent()
	arg_3_0:refreshTime()
end

function var_0_1.refreshTime(arg_4_0)
	if arg_4_0.handle1 then
		var_0_0.unscheduleGlobal(arg_4_0.handle1)

		arg_4_0.handle1 = nil
	end

	local var_4_0

	if arg_4_0.mission.start_time > 0 then
		var_4_0 = xyd.tables.eventCentreMissionTable:time(arg_4_0.mission.mission_id) - (xyd.ServerTime.get():getServerTime() - arg_4_0.mission.start_time)

		arg_4_0:contentView():nodeByName("task_rest_time"):setString(xyd.secondsToString1(var_4_0))
		arg_4_0:contentView():nodeByName("task_progress"):setPercent(math.min((xyd.ServerTime.get():getServerTime() - arg_4_0.mission.start_time) / xyd.tables.eventCentreMissionTable:time(arg_4_0.mission.mission_id) * 100, 100))
	else
		var_4_0 = 0
	end

	if var_4_0 > 0 then
		arg_4_0.handle1 = var_0_0.scheduleGlobal(function()
			var_4_0 = var_4_0 - 1

			if not tolua.isnull(arg_4_0) then
				arg_4_0:contentView():nodeByName("task_rest_time"):setString(xyd.secondsToString1(var_4_0))
				arg_4_0:contentView():nodeByName("task_progress"):setPercent(math.min((xyd.ServerTime.get():getServerTime() - arg_4_0.mission.start_time) / xyd.tables.eventCentreMissionTable:time(arg_4_0.mission.mission_id) * 100, 100))
			end

			if var_4_0 <= 0 and arg_4_0.handle1 then
				xyd.WindowManager.get():getWindow("board_main_window"):refreshTaskList()
				var_0_0.unscheduleGlobal(arg_4_0.handle1)

				arg_4_0.handle1 = nil

				if not tolua.isnull(arg_4_0) then
					-- block empty
				end
			end
		end, 1)
	elseif arg_4_0.handle1 then
		var_0_0.unscheduleGlobal(arg_4_0.handle1)

		arg_4_0.handle1 = nil
	end
end

function var_0_1.registerTouchEvent(arg_6_0)
	arg_6_0:contentView():setTouchEnabled(true)
	arg_6_0:contentView():setTouchSwallowEnabled(false)
	arg_6_0:contentView():nodeByName("task_name"):setString(xyd.tables.eventCentreMissionTable:name(arg_6_0.mission.mission_id))
	xyd.setAvatarBorder(arg_6_0.selfPlayer:getHero(arg_6_0.mission.leader), arg_6_0:contentView():nodeByName("leader_icon"), false, 0)

	for iter_6_0 = 1, #arg_6_0.mission.partners do
		xyd.setAvatarBorder(arg_6_0.selfPlayer:getHero(arg_6_0.mission.partners[iter_6_0]), arg_6_0:contentView():nodeByName("character_icon" .. iter_6_0), false, 0)
	end

	local var_6_0 = arg_6_0.container

	arg_6_0:contentView():addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			arg_6_0.prevX_ = arg_7_0.x
			arg_6_0.prevY_ = arg_7_0.y
			arg_6_0.startClick_ = true
		elseif arg_7_0.name == "moved" then
			if math.abs(arg_7_0.y - arg_6_0.prevY_) > 10 or math.abs(arg_7_0.x - arg_6_0.prevX_) > 20 then
				arg_6_0.startClick_ = false
			end
		elseif arg_7_0.name == "ended" and arg_6_0.startClick_ then
			local var_7_0 = var_6_0:convertToNodeSpace(cc.p(arg_7_0.x, arg_7_0.y))
		end

		return true
	end)
end

function var_0_1.setCancelBtn(arg_8_0)
	arg_8_0.cancelButton = arg_8_0:contentView():nodeByName("cancel_button")

	arg_8_0.cancelButton:setTouchSwallowEnabled(true)
	arg_8_0.cancelButton:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			-- block empty
		end

		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = xyd.tables.translation:translation("EVENT_CENTRE_BOARD_WARNING_LABEL")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
				arg_8_0:giveUpMission()
			end)
		end
	end)
end

function var_0_1.giveUpMission(arg_11_0)
	params = {}
	params.mission_id = arg_11_0.mission.mission_id

	arg_11_0.eventCentre:giveUpMission(params, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			local var_12_0 = {}

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.BOARD_MISSION_GIVE_UP,
				params = {}
			})
			xyd.WindowManager.get():closeWindow(arg_11_0)
		end
	end)
end

function var_0_1.contentView(arg_13_0)
	if arg_13_0.contentView_ == nil then
		arg_13_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_13_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/board/board/attack_team_task_item.csb"))
		arg_13_0.contentView_:addTo(arg_13_0)
		arg_13_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_13_0.contentView_
end

return var_0_1
