local var_0_0 = class("BoardMissionItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView()

	arg_2_0.container = arg_2_0:contentView():nodeByName("container")

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:contentView():nodeByName("task_name_label"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_TASK_NAME_LABEL"))
	arg_2_0:contentView():nodeByName("character_label"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_CHARACTER_LABEL"))
	arg_2_0:contentView():nodeByName("task_time_label"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_TASK_TIME_LABEL"))
	arg_2_0:contentView():nodeByName("hours"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_HOURS"))
	arg_2_0:contentView():nodeByName("task_bonus_label"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_TASK_BONUS_LABEL"))

	arg_2_0.mission = arg_2_1

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:registerTouchEvent()
	arg_3_0:setMissionAward()
end

function var_0_0.registerTouchEvent(arg_4_0)
	arg_4_0:contentView():setTouchEnabled(true)
	arg_4_0:contentView():setTouchSwallowEnabled(false)

	local var_4_0 = arg_4_0.container

	arg_4_0:contentView():nodeByName("task_name"):setString(xyd.tables.eventCentreMissionTable:name(arg_4_0.mission.mission_id))
	arg_4_0:contentView():nodeByName("character_name"):setString(xyd.tables.eventCentreMissionTable:hero(arg_4_0.mission.mission_id))
	arg_4_0:contentView():nodeByName("task_time"):setString(xyd.tables.eventCentreMissionTable:time(arg_4_0.mission.mission_id) / 3600)
	xyd.setAvatarBorder(xyd.tables.eventCentreMissionTable:heroId(arg_4_0.mission.mission_id), arg_4_0:contentView():nodeByName("character_icon"), false, 0)
	arg_4_0:contentView():addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0:contentView():nodeByName("container"):setScale(0.95)

			arg_4_0.prevX_ = arg_5_0.x
			arg_4_0.prevY_ = arg_5_0.y
			arg_4_0.startClick_ = true
		elseif arg_5_0.name == "moved" then
			if math.abs(arg_5_0.y - arg_4_0.prevY_) > 10 or math.abs(arg_5_0.x - arg_4_0.prevX_) > 20 then
				arg_4_0.startClick_ = false

				arg_4_0:contentView():nodeByName("container"):setScale(1)
			end
		elseif arg_5_0.name == "ended" and arg_4_0.startClick_ then
			arg_4_0:contentView():nodeByName("container"):setScale(1)
			arg_4_0:taskInfoWindow(arg_4_0.mission)

			local var_5_0 = var_4_0:convertToNodeSpace(cc.p(arg_5_0.x, arg_5_0.y))
			local var_5_1
		end

		return true
	end)
end

function var_0_0.contentView(arg_6_0)
	if arg_6_0.contentView_ == nil then
		arg_6_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_6_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/board/board/board_task_item.csb"))
		arg_6_0.contentView_:addTo(arg_6_0)
		arg_6_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_6_0.contentView_
end

function var_0_0.taskInfoWindow(arg_7_0, arg_7_1)
	xyd.WindowManager:get():openWindow("board_task_info_window", arg_7_1)
end

function var_0_0.showAward(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	local var_8_0 = arg_8_0:contentView():nodeByName(arg_8_1)

	var_8_0:setVisible(true)

	if arg_8_5 ~= 0 then
		xyd.setItemBorder(var_8_0, tonumber(arg_8_5))
		var_8_0:setScale(0.8)
	end

	local var_8_1 = arg_8_0:contentView():nodeByName(arg_8_2)

	var_8_1:setVisible(true)
	var_8_1:setString("x" .. arg_8_3)

	if arg_8_4 > 0 then
		local var_8_2, var_8_3 = var_8_0:getPosition()
		local var_8_4, var_8_5 = var_8_1:getPosition()

		var_8_0:setPosition(cc.p(var_8_2 + arg_8_4, var_8_3))
		var_8_1:setPosition(cc.p(var_8_4 + arg_8_4, var_8_5))
	end

	var_8_0:setScale(0.8)
end

function var_0_0.setMissionAward(arg_9_0)
	if arg_9_0.mission.type == 1 then
		arg_9_0.missionAwardItem = xyd.tables.eventCentreMissionAwardTable:itemId(arg_9_0.mission.award_id)
		arg_9_0.missionAwardItemNumber = xyd.tables.eventCentreMissionAwardTable:itemNumber(arg_9_0.mission.award_id)
		arg_9_0.missionAwardRewardId = xyd.luaStringSplit(xyd.tables.eventCentreMissionAwardTable:rewardId(arg_9_0.mission.award_id), "|")
		arg_9_0.missionAwardRewardResource = xyd.luaStringSplit(xyd.tables.eventCentreMissionAwardTable:rewardResource(arg_9_0.mission.award_id), "|")

		local var_9_0 = 0

		if arg_9_0.missionAwardItem ~= "0" then
			arg_9_0:showAward("item", "item_num", arg_9_0.missionAwardItemNumber, var_9_0, arg_9_0.missionAwardItem)

			var_9_0 = var_9_0 + 200
		end

		for iter_9_0 = 1, #arg_9_0.missionAwardRewardId do
			if arg_9_0.missionAwardRewardId[iter_9_0] == "11" then
				arg_9_0:showAward("dust", "dust_num", arg_9_0.missionAwardRewardResource[iter_9_0], var_9_0, 0)
			elseif arg_9_0.missionAwardRewardId[iter_9_0] == "12" then
				arg_9_0:showAward("liquid", "liquid_num", arg_9_0.missionAwardRewardResource[iter_9_0], var_9_0, 0)
			elseif arg_9_0.missionAwardRewardId[iter_9_0] == "13" then
				arg_9_0:showAward("energy", "energy_num", arg_9_0.missionAwardRewardResource[iter_9_0], var_9_0, 0)
			elseif arg_9_0.missionAwardRewardId[iter_9_0] == "14" then
				-- block empty
			end

			var_9_0 = var_9_0 + 200
		end
	elseif arg_9_0.mission.type == 2 then
		arg_9_0:contentView():nodeByName("task_bonus_label"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_DEPOSIT"))
		arg_9_0:contentView():nodeByName("jinbi_bonus_label"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_REWARD_GOLD"))
		arg_9_0:contentView():nodeByName("jinbi_bonus_label"):setVisible(true)
		arg_9_0:contentView():nodeByName("jinbi_num"):setString("x" .. xyd.tables.eventCentreMissionTable:deposit(arg_9_0.mission.mission_id))
		arg_9_0:contentView():nodeByName("jinbi"):setVisible(true)
		arg_9_0:contentView():nodeByName("jinbi"):setScale(0.8)
		arg_9_0:contentView():nodeByName("jinbi_num"):setVisible(true)
		arg_9_0:contentView():nodeByName("award_jinbi"):setVisible(true)
		arg_9_0:contentView():nodeByName("award_jinbi"):setScale(0.8)
		arg_9_0:contentView():nodeByName("award_jinbi_num"):setVisible(true)
		arg_9_0:contentView():nodeByName("award_jinbi_num"):setString("x" .. xyd.tables.eventCentreMissionAwardTable:rewardGold(arg_9_0.mission.award_id))
	end
end

return var_0_0
