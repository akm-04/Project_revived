local var_0_0 = class("SingleDayWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	0.5,
	0.5,
	0.6,
	0.8,
	1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.singleDay = xyd.ModelManager.get():loadModel(xyd.ModelType.SINGLE_DAY)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

	arg_1_0:updateVariable()
end

function var_0_0.updateVariable(arg_2_0)
	arg_2_0.activity = arg_2_0.singleDay.activity
	arg_2_0.details = arg_2_0.singleDay.details
	arg_2_0.dailyInfos = arg_2_0.details.self_daily_infos
	arg_2_0.fellowDailyInfos = arg_2_0.details.fellow_daily_infos
	arg_2_0.currentDay = arg_2_0.details.day_count or 1

	if arg_2_0.currentDay > arg_2_0.activity.days then
		arg_2_0.currentDay = arg_2_0.activity.days
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:handleEnterAlert()
end

function var_0_0.handleEnterAlert(arg_4_0)
	local var_4_0 = tonumber(xyd.db.stateVariable:getState(arg_4_0.selfPlayer.playerID, xyd.state.LAST_FELLOW_ID))
	local var_4_1 = xyd.db.stateVariable:getState(arg_4_0.selfPlayer.playerID, xyd.state.LAST_FELLOW_NAME)
	local var_4_2 = tonumber(xyd.db.stateVariable:getState(arg_4_0.selfPlayer.playerID, xyd.state.REMOVE_APPLY_STATE))
	local var_4_3 = tonumber(xyd.db.stateVariable:getState(arg_4_0.selfPlayer.playerID, xyd.state.ADD_FELLOW_TIP_STATE)) or 0
	local var_4_4 = arg_4_0.details.self_base_info.remove_apply

	if var_4_4 == xyd.RemoveApplyState.Recieving then
		arg_4_0:handleAlertWindow(xyd.SingleDayNoticeType.SendRemove)
	end

	if var_4_2 ~= var_4_4 and var_4_4 == xyd.RemoveApplyState.Rejected then
		arg_4_0:handleAlertWindow(xyd.SingleDayNoticeType.DenyRemove)

		return
	end

	if var_4_0 ~= arg_4_0.details.self_base_info.fellow_id then
		if arg_4_0.details.self_base_info.fellow_id > 0 then
			arg_4_0:handleAlertWindow(xyd.SingleDayNoticeType.AcceptApply)
		else
			arg_4_0:handleAlertWindow(xyd.SingleDayNoticeType.AcceptRemove)
		end

		return
	end

	if var_4_3 == 0 and arg_4_0.details.self_base_info.fellow_id == 0 then
		arg_4_0:handleAlertWindow(xyd.SingleDayNoticeType.NoPartener)

		local var_4_5 = {
			playerID = arg_4_0.selfPlayer.playerID,
			name = xyd.state.ADD_FELLOW_TIP_STATE
		}

		var_4_5.state = 1

		xyd.db.stateVariable:setState(var_4_5)
	end
end

function var_0_0.handleAlertWindow(arg_5_0, arg_5_1)
	arg_5_0.details = arg_5_0.singleDay.details

	if arg_5_1 == xyd.SingleDayNoticeType.SendRemove then
		xyd.AlertWindow.open(xyd.AlertType.AGREE_REJECT, {
			string.format(var_0_1:translation("FELLOW_APPLY_SURE1"), arg_5_0.details.fellow_base_info.player_name),
			var_0_1:translation("FELLOW_APPLY_SURE2")
		}, function(arg_6_0)
			if arg_6_0 then
				arg_5_0.singleDay:acceptRemove({}, function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						arg_5_0:update()
					end
				end)
			else
				arg_5_0.singleDay:denyRemove({}, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_5_0:update()
					end
				end)
			end
		end)
	elseif arg_5_1 == xyd.SingleDayNoticeType.AcceptApply then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, string.format(var_0_1:translation("FELLOW_APPLY_RECIEVED"), arg_5_0.details.fellow_base_info.player_name), function()
			return
		end, nil, nil, arg_5_0.colorMode)
	elseif arg_5_1 == xyd.SingleDayNoticeType.AcceptRemove or arg_5_1 == xyd.SingleDayNoticeType.ForceRemove then
		local var_5_0 = xyd.db.stateVariable:getState(arg_5_0.selfPlayer.playerID, xyd.state.LAST_FELLOW_NAME)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, string.format(var_0_1:translation("FELLOW_REMOVED_SURE"), var_5_0), function()
			return
		end, nil, nil, arg_5_0.colorMode)
	elseif arg_5_1 == xyd.SingleDayNoticeType.DenyRemove then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, string.format(var_0_1:translation("FELLOW_APPLY_REJECTED"), arg_5_0.details.fellow_base_info.player_name), function()
			return
		end, nil, nil, arg_5_0.colorMode)
	elseif arg_5_1 == xyd.SingleDayNoticeType.NoPartener then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("NO_PARTENER_TEXT3"), function()
			arg_5_0.singleDay:getRecommendFellows({}, function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK then
					local var_13_0 = {
						data = arg_13_1 or {}
					}

					xyd.WindowManager.get():openWindow("single_day_add_partener", var_13_0)
				end
			end)
		end, nil, nil, arg_5_0.colorMode)
	else
		return
	end

	arg_5_0.singleDay:refreshStateInfo()
end

function var_0_0.update(arg_14_0)
	arg_14_0:updateVariable()
	arg_14_0:updateView()
	arg_14_0:switchDay()
	arg_14_0.dayList:reload()
	arg_14_0.singleDay:refreshStateInfo()
end

function var_0_0.layout(arg_15_0)
	arg_15_0:nodeByName("get_award_container"):setVisible(false)

	arg_15_0.taskContainer = arg_15_0:nodeByName("task_scroll")

	local var_15_0 = arg_15_0.taskContainer:getContentSize()

	arg_15_0.dayList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_15_0.width, var_15_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_15_0.taskContainer):onScroll(handler(arg_15_0, arg_15_0.scrollListener))

	arg_15_0.dayList:setBounceable(false)
	arg_15_0.dayList:setDelegate(handler(arg_15_0, arg_15_0.dayListDelegate))
	arg_15_0.dayList:reload()
	arg_15_0:updateVariable()
	arg_15_0:updateView()
	arg_15_0:switchDay()
	arg_15_0.dayList:reload()
	arg_15_0:setButtonClick()
end

function var_0_0.updateView(arg_16_0)
	arg_16_0:nodeByName("my_partener_text"):setString(var_0_1:translation("MY_PARTENER_TEXT"))
	arg_16_0:nodeByName("achieve_mission_text"):setString(var_0_1:translation("ACHIEVE_MISSION_TEXT"))
	arg_16_0:nodeByName("agreement_degree_text"):setString(var_0_1:translation("AGREEMENT_TEXT"))
	arg_16_0:nodeByName("agreement_degree_txt"):setString(math.ceil(arg_16_0.details.self_base_info.tacit))

	if arg_16_0.details.self_base_info.fellow_id > 0 then
		arg_16_0:nodeByName("name_txt"):setString(arg_16_0.details.fellow_base_info.player_name)
		arg_16_0:nodeByName("region_txt"):setString("S" .. arg_16_0.details.fellow_base_info.region)
		arg_16_0:nodeByName("have_partner_container"):setVisible(true)
		arg_16_0:nodeByName("no_partner_container"):setVisible(false)

		local var_16_0 = {
			avatar_id = arg_16_0.details.fellow_base_info.avatar_id,
			avatar_frame_id = arg_16_0.details.fellow_base_info.avatar_frame_id
		}

		xyd.setPlayerAvatar(arg_16_0:nodeByName("avtar_container"), var_16_0)
		arg_16_0.socialSystem:setOnlineState(arg_16_0:nodeByName("friend_state_txt"), arg_16_0.details.fellow_base_info)
		arg_16_0:nodeByName("have_partner_container"):setVisible(true)
		arg_16_0:nodeByName("no_partner_container"):setVisible(false)

		if arg_16_0.details.self_base_info.remove_apply == 1 then
			arg_16_0:nodeByName("in_removeing_text"):setVisible(true)
			arg_16_0:nodeByName("fellow_cover"):setVisible(true)
		else
			arg_16_0:nodeByName("in_removeing_text"):setVisible(false)
			arg_16_0:nodeByName("fellow_cover"):setVisible(false)
		end
	else
		arg_16_0:nodeByName("have_partner_container"):setVisible(false)
		arg_16_0:nodeByName("no_partner_container"):setVisible(true)
	end

	arg_16_0:refreshApllyRedMark()
end

function var_0_0.refreshApllyRedMark(arg_17_0)
	if arg_17_0.singleDay.isApplyRedMarkShow == true then
		arg_17_0:nodeByName("apply_list_btn"):getChildByName("red_point"):setVisible(true)
	else
		arg_17_0:nodeByName("apply_list_btn"):getChildByName("red_point"):setVisible(false)
	end
end

function var_0_0.switchDay(arg_18_0)
	local var_18_0 = arg_18_0.currentDay or 1

	if var_18_0 > arg_18_0.activity.days then
		var_18_0 = arg_18_0.activity.days
	elseif var_18_0 < 1 then
		var_18_0 = 1
	end

	local var_18_1
	local var_18_2
	local var_18_3

	if var_18_0 <= arg_18_0.details.day_count then
		var_18_2 = xyd.splitToNumber(arg_18_0.dailyInfos[var_18_0].missions_progress, "|")
		var_18_1 = xyd.splitToNumber(arg_18_0.dailyInfos[var_18_0].my_missions, "|")
		missionTacits = xyd.splitToNumber(arg_18_0.dailyInfos[var_18_0].missions_tacit, "|")
		var_18_3 = arg_18_0.dailyInfos[var_18_0].my_challenge_damage
		missionStatus = xyd.splitToNumber(arg_18_0.dailyInfos[var_18_0].missions_status, "|")
	end

	local var_18_4 = xyd.tables.activitySingleMission

	arg_18_0:nodeByName("day_text_left"):setString(var_0_1:translation("DAY_LEFT_TEXT"))
	arg_18_0:nodeByName("day_text_right"):setString(var_0_1:translation("DAY_RIGHT_TEXT"))
	arg_18_0:nodeByName("day_txt_pos"):removeAllChildren(true)
	xyd.AssetLoader.get():loadSprite("windows/single_day/" .. var_18_0 .. ".png"):addTo(arg_18_0:nodeByName("day_txt_pos"))

	for iter_18_0 = 1, 5 do
		arg_18_0:nodeByName("task_pos" .. iter_18_0):removeAllChildren(true)

		local var_18_5 = display.newNode()
		local var_18_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/single_day/task_item.csb")
		local var_18_7 = var_18_6:getChildByName("container")

		var_18_6:setAnchorPoint(cc.p(0, 0))
		var_18_6:addTo(var_18_5)
		var_18_5:setContentSize(var_18_7:getContentSize())
		var_18_5:setScale(var_0_2[iter_18_0])
		var_18_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_18_5:addTo(arg_18_0:nodeByName("task_pos" .. iter_18_0))
		var_18_6:setTouchEnabled(true)

		local var_18_8 = 0
		local var_18_9 = xyd.tables.activitySingleMission:req(var_18_1[iter_18_0])

		if #var_18_9 == 1 and var_18_3 > 0 or missionStatus[iter_18_0] == 1 then
			var_18_8 = 100
		elseif #var_18_9 > 1 and var_18_9[var_18_0] ~= 0 then
			var_18_8 = 100 * var_18_2[iter_18_0] / var_18_9[var_18_0]
		end

		var_18_7:getChildByName("progress_bar1"):setPercent(var_18_8)
		var_18_7:getChildByName("progress_bar2"):setPercent(var_18_8)

		if missionStatus[iter_18_0] == 1 then
			var_18_7:getChildByName("desc_txt"):setString(string.format(var_0_1:translation("GET_NAGREEMENT"), missionTacits[iter_18_0]))
			var_18_6:setTouchEnabled(false)
		elseif var_18_8 >= 100 then
			var_18_7:getChildByName("desc_txt"):setString(var_0_1:translation("WAITING_FELLOW"))
		elseif var_18_1[iter_18_0] == 0 then
			var_18_7:getChildByName("desc_txt"):setString(var_0_1:translation("SELECT_TASK_TEXT"))
		elseif var_18_4:battleId(var_18_1[iter_18_0]) > 0 then
			var_18_7:getChildByName("desc_txt"):setString(xyd.tables.activitySingleMission:desc(var_18_1[iter_18_0]))
		else
			local var_18_10 = xyd.tables.activitySingleMission:req(var_18_1[iter_18_0])[arg_18_0.currentDay]

			var_18_7:getChildByName("desc_txt"):setString(string.format(xyd.tables.activitySingleMission:desc(var_18_1[iter_18_0]), var_18_10))
		end

		var_18_7:getChildByName("desc_txt"):enableOutline(cc.c4b(0, 24, 87, 129), 2)
		var_18_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
			if arg_19_0.name == "began" and arg_18_0.canSelectMission == true then
				var_18_6:setScale(0.9)
				var_18_7:getChildByName("circle_gray2"):setVisible(false)
				var_18_7:getChildByName("progress_bar2"):setVisible(false)

				return true
			elseif arg_19_0.name == "ended" then
				var_18_6:setScale(1)
				var_18_7:getChildByName("circle_gray2"):setVisible(true)
				var_18_7:getChildByName("progress_bar2"):setVisible(true)

				local var_19_0 = {
					day = var_18_0,
					mission_count = iter_18_0,
					details = arg_18_0.details
				}
				local var_19_1 = xyd.splitToNumber(xyd.tables.activitySingle:mission(var_18_0)[iter_18_0], ",")
				local var_19_2 = xyd.tables.activitySingleMission:req(var_19_1[1])

				if #var_19_2 == 1 and var_19_2[1] == 0 then
					xyd.WindowManager.get():openWindow("single_day_battle_task", var_19_0)
				else
					xyd.WindowManager.get():openWindow("single_day_task", var_19_0)
				end
			end
		end)
	end

	arg_18_0:updateTipContainer(var_18_0)
end

function var_0_0.updateTipContainer(arg_20_0, arg_20_1)
	arg_20_0.canSelectMission = false

	arg_20_0:nodeByName("task_tip_container"):setVisible(true)
	arg_20_0:nodeByName("get_award_container"):setVisible(false)
	arg_20_0:nodeByName("tip_container"):setVisible(true)
	arg_20_0:nodeByName("task_tip_container"):setTouchEnabled(true)
	arg_20_0:nodeByName("task_tip_container"):setTouchSwallowEnabled(true)

	if arg_20_0.dailyInfos[arg_20_1].award_status == 1 then
		arg_20_0:nodeByName("get_award_container"):setVisible(true)
		arg_20_0:nodeByName("tip_container"):setVisible(false)
		arg_20_0:nodeByName("get_award_btn"):setBright(true)
		arg_20_0:nodeByName("get_award_btn"):setTouchEnabled(true)
		arg_20_0:nodeByName("get_reward_text"):setVisible(true)
		arg_20_0:nodeByName("already_get_gray"):setVisible(false)
		arg_20_0:nodeByName("get_award_btn"):getChildByName("red_point"):setVisible(true)
	elseif arg_20_0.dailyInfos[arg_20_1].award_status == -1 then
		arg_20_0:nodeByName("get_award_container"):setVisible(true)
		arg_20_0:nodeByName("tip_container"):setVisible(false)
		arg_20_0:nodeByName("get_award_btn"):setBright(false)
		arg_20_0:nodeByName("get_award_btn"):setTouchEnabled(false)
		arg_20_0:nodeByName("get_reward_text"):setVisible(false)
		arg_20_0:nodeByName("already_get_gray"):setVisible(true)
		arg_20_0:nodeByName("get_award_btn"):getChildByName("red_point"):setVisible(false)
	elseif arg_20_1 > arg_20_0.details.day_count then
		arg_20_0:nodeByName("tip_txt"):setString(var_0_1:translation("SAKURA_NOT_OPEN"))
	elseif arg_20_1 < arg_20_0.details.day_count then
		arg_20_0:nodeByName("tip_txt"):setString(string.format(var_0_1:translation("TASK_EXPRIED"), arg_20_1))
	elseif arg_20_0.details.self_base_info.fellow_id == 0 then
		arg_20_0:nodeByName("tip_txt"):setString(var_0_1:translation("NO_PARTENER_TEXT1"))
	else
		arg_20_0:nodeByName("task_tip_container"):setVisible(false)

		arg_20_0.canSelectMission = true
	end
end

function var_0_0.setButtonClick(arg_21_0)
	arg_21_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("single_day_rule")
		end
	end)
	arg_21_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_21_0.singleDay:getRankInfo({}, function(arg_24_0, arg_24_1)
				if arg_24_0 == xyd.error.OK then
					local var_24_0 = {
						data = arg_24_1.rank_list or {}
					}

					xyd.WindowManager.get():openWindow("single_day_rank", var_24_0)
				end
			end)
		end
	end)
	arg_21_0:nodeByName("add_partner_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_21_0.singleDay:getRecommendFellows({}, function(arg_26_0, arg_26_1)
				if arg_26_0 == xyd.error.OK then
					local var_26_0 = {
						data = arg_26_1 or {}
					}

					xyd.WindowManager.get():openWindow("single_day_add_partener", var_26_0)
				end
			end)
		end
	end)
	arg_21_0:nodeByName("apply_list_btn"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_21_0.singleDay:getApplyList({}, function(arg_28_0, arg_28_1)
				if arg_28_0 == xyd.error.OK then
					arg_21_0.singleDay.isApplyRedMarkShow = false

					arg_21_0:refreshApllyRedMark()
					xyd.WindowManager.get():openWindow("single_day_apply_list")
				end
			end)
		end
	end)
	arg_21_0:nodeByName("avtar_container"):setTouchEnabled(true)
	arg_21_0:nodeByName("avtar_container"):setTouchSwallowEnabled(false)
	arg_21_0:nodeByName("fellow_btn"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("single_day_partener_detail")
		end
	end)
	arg_21_0:nodeByName("get_award_btn"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_21_0.activitiesModel:getActivityReward(xyd.Activities.SingleDay, arg_21_0.currentDay, function(arg_31_0, arg_31_1)
				if arg_31_0 == xyd.error.OK then
					arg_21_0.selfPlayer:handleRewards(arg_31_1.awards)

					arg_21_0.dailyInfos[arg_21_0.currentDay].award_status = -1

					arg_21_0:update()
				end
			end)
		end
	end)
end

function var_0_0.dayListDelegate(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	if cc.ui.UIListView.COUNT_TAG == arg_32_2 then
		return xyd.tables.activitySingle:days()
	elseif cc.ui.UIListView.CELL_TAG == arg_32_2 then
		local var_32_0 = arg_32_0.dayList:dequeueItem()

		if not var_32_0 then
			var_32_0 = arg_32_0.dayList:newItem()
		else
			var_32_0:removeAllChildren(true)
		end

		local var_32_1 = arg_32_0:createDayItem(arg_32_3)
		local var_32_2 = var_32_1:getWidth()
		local var_32_3 = var_32_1:getHeight()

		var_32_0:setItemSize(var_32_2, var_32_3)
		var_32_0:addContent(var_32_1)

		return var_32_0
	end
end

function var_0_0.createDayItem(arg_33_0, arg_33_1)
	local var_33_0 = display.newNode()
	local var_33_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/single_day/day_item.csb")
	local var_33_2 = var_33_1:getChildByName("container")
	local var_33_3 = "windows/single_day/day" .. arg_33_1 .. ".png"

	if arg_33_1 > arg_33_0.details.day_count then
		var_33_3 = "windows/single_day/daygray" .. arg_33_1 .. ".png"

		var_33_2:getChildByName("select_btn"):setBright(false)
		var_33_2:getChildByName("select_btn"):setTouchEnabled(false)
	elseif arg_33_0.currentDay == arg_33_1 then
		var_33_2:getChildByName("select_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		var_33_2:getChildByName("select_btn"):setTouchEnabled(false)
	else
		var_33_2:getChildByName("select_btn"):setBrightStyle(ccui.BrightStyle.normal)
		var_33_2:getChildByName("select_btn"):setTouchEnabled(true)
	end

	if arg_33_0.dailyInfos[arg_33_1] and arg_33_0.dailyInfos[arg_33_1].award_status == 1 then
		var_33_2:getChildByName("red_point"):setVisible(true)
	else
		var_33_2:getChildByName("red_point"):setVisible(false)
	end

	xyd.AssetLoader.get():loadSprite(var_33_3):addTo(var_33_2:getChildByName("day_pos"))
	var_33_1:addTo(var_33_0)
	var_33_1:setAnchorPoint(cc.p(0, 0))
	var_33_2:getChildByName("select_btn"):addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_33_0.currentDay ~= arg_33_1 then
				var_33_2:getChildByName("select_btn"):setBrightStyle(ccui.BrightStyle.highlight)
				var_33_2:getChildByName("select_btn"):setTouchEnabled(false)

				arg_33_0.currentDay = arg_33_1

				arg_33_0:switchDay()
				arg_33_0.dayList:reload()
			end
		end
	end)
	var_33_0:setContentSize(var_33_2:getContentSize())
	var_33_1:setName("source")

	return var_33_0
end

function var_0_0.createItemNumLabel(arg_35_0, arg_35_1)
	local var_35_0 = {
		font = "fonts/main_font.ttf",
		size = 30,
		color = cc.c3b(255, 255, 255)
	}
	local var_35_1 = xyd.AssetLoader.get():loadLabel(var_35_0)

	var_35_1:setMaxLineWidth(250)
	var_35_1:setString("X" .. arg_35_1)

	return var_35_1
end

function var_0_0.scrollListener(arg_36_0, arg_36_1)
	if arg_36_1.name == "began" then
		arg_36_0.scrollViewMoved_ = false
		arg_36_0.prevY_ = arg_36_1.y
	elseif arg_36_1.name == "moved" and 10 <= math.abs(arg_36_1.y - arg_36_0.prevY_) then
		arg_36_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_37_0, arg_37_1)
	var_0_0.super.willClose(arg_37_1)
	arg_37_0.singleDay:refreshStateInfo()
end

return var_0_0
