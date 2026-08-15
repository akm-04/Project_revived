local var_0_0 = class("WarCampMissionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.warCampMission
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.warCampTimeline

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.camp_ = arg_1_0.warCamp_:getCampType()
	arg_1_0.activity = arg_1_0.warCamp_.activity
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayerWithNoTouchEvent()

	arg_2_0.wins = arg_2_0.warCamp_:getWins()
	arg_2_0.fight_times = arg_2_0.warCamp_:getFightTimes()
	arg_2_0.missionInfo = arg_2_0.warCamp_:getMissionInfo()

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	if arg_3_0.camp_ == xyd.WarCampSelectType.LEFT then
		arg_3_0:nodeByName("bg_1"):setVisible(true)
		arg_3_0:nodeByName("bg_2"):setVisible(false)
		arg_3_0:nodeByName("title_1"):setVisible(true)
		arg_3_0:nodeByName("title_2"):setVisible(false)
		arg_3_0:nodeByName("close_2"):setVisible(false)
	else
		arg_3_0:nodeByName("bg_1"):setVisible(false)
		arg_3_0:nodeByName("bg_2"):setVisible(true)
		arg_3_0:nodeByName("title_1"):setVisible(false)
		arg_3_0:nodeByName("title_2"):setVisible(true)
		arg_3_0:nodeByName("close_2"):addTouchEventListener(function(arg_4_0, arg_4_1)
			if arg_4_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():closeWindow(arg_3_0)
			end
		end)
	end

	arg_3_0:initMission()
end

function var_0_0.initMission(arg_5_0)
	local var_5_0 = var_0_2:ids()

	for iter_5_0 = 1, #var_5_0 do
		local var_5_1 = var_5_0[iter_5_0]
		local var_5_2 = arg_5_0:createMissionItem(var_5_1)
		local var_5_3 = var_5_2:getContentSize()

		var_5_2:addTo(arg_5_0:nodeByName("item_pos" .. iter_5_0))
		var_5_2:setPosition(-var_5_3.width / 2, -var_5_3.height / 2)
	end
end

function var_0_0.createMissionItem(arg_6_0, arg_6_1)
	local var_6_0 = var_0_2:showItem(arg_6_1)
	local var_6_1 = var_0_2:showItemNums(arg_6_1)
	local var_6_2 = var_0_2:desc(arg_6_1)
	local var_6_3 = var_0_2:name(arg_6_1)
	local var_6_4 = display.newNode()
	local var_6_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/mission/mission_item.csb")
	local var_6_6 = var_6_5:getChildByName("container")

	var_6_6:getChildByName("text_title"):setString(var_6_3)
	var_6_6:getChildByName("text_title"):enableOutline(cc.c4b(214, 55, 70, 255), 2)
	var_6_6:getChildByName("text_desc"):setString(var_6_2)
	var_6_6:getChildByName("text_item_num"):setString("x" .. var_6_1)
	xyd.setItemAndAddTips(var_6_6:getChildByName("item"), var_6_0)

	local var_6_7 = var_0_2:req(arg_6_1)
	local var_6_8 = string.format(var_0_3:translation("WAR_CAMP_MISSION_TIPS_1"), arg_6_0.wins, var_6_7)

	if arg_6_1 == 1 then
		var_6_8 = string.format(var_0_3:translation("WAR_CAMP_MISSION_TIPS_1"), arg_6_0.fight_times, var_6_7)
	end

	var_6_6:getChildByName("text_progress"):setString(var_6_8)

	local var_6_9 = false

	if var_6_7 <= arg_6_0.wins and arg_6_1 ~= 1 or arg_6_1 == 1 and var_6_7 <= arg_6_0.fight_times then
		var_6_9 = true
	end

	local var_6_10 = var_6_6:getChildByName("btn_go")

	var_6_10:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and arg_6_0:checkCanClick() then
			if var_6_9 then
				local var_7_0 = arg_6_1

				arg_6_0.activities:getActivityReward(xyd.Activities.WarCamp, var_7_0, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_6_0.selfPlayer:handleRewards(arg_8_1.awards)

						arg_6_0.warCamp_.baseInfo.missions[arg_6_1] = 1
						arg_6_0.missionInfo = arg_6_0.warCamp_:getMissionInfo()

						arg_6_0:updateBtnType(var_6_10, var_6_9, arg_6_1)
					end
				end)
			else
				arg_6_0.warCamp_:getInfos(function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("war_camp_map")
						xyd.WindowManager.get():closeWindow(arg_6_0)
					end
				end)
			end
		end
	end)
	arg_6_0:updateBtnType(var_6_10, var_6_9, arg_6_1)

	if arg_6_0.camp_ == xyd.WarCampSelectType.LEFT then
		var_6_6:getChildByName("concent_bg_1"):setVisible(true)
		var_6_6:getChildByName("concent_bg_2"):setVisible(false)
	else
		var_6_6:getChildByName("concent_bg_1"):setVisible(false)
		var_6_6:getChildByName("concent_bg_2"):setVisible(true)
	end

	var_6_5:addTo(var_6_4)
	var_6_5:setAnchorPoint(cc.p(0, 0))
	var_6_4:setContentSize(var_6_6:getContentSize())
	var_6_5:setName("source")

	return var_6_4
end

function var_0_0.checkCanClick(arg_10_0)
	local var_10_0 = xyd.ServerTime.get():getServerTime()
	local var_10_1 = arg_10_0.warCamp_:getDayCount()

	if var_10_0 < arg_10_0.activity.start_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("ACTIVITY_NO_OPEN")
		})

		return false
	elseif var_10_0 > arg_10_0.activity.end_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("ACTIVITY_END")
		})

		return false
	end

	if var_0_4:isOpenWar(var_10_1) == 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("WAR_CAMP_ENTRANCE_TIPS_4")
		})

		return false
	end

	return true
end

function var_0_0.updateBtnType(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if arg_11_2 then
		arg_11_1:getChildByName("word_go"):setVisible(false)

		if arg_11_0.missionInfo[arg_11_3] == 1 then
			arg_11_1:getChildByName("word_get"):setVisible(false)
			arg_11_1:setTouchEnabled(false)
			arg_11_1:setBright(false)
			arg_11_1:getChildByName("word_is_get"):setVisible(true)
		else
			arg_11_1:setBright(true)
			arg_11_1:getChildByName("word_get"):setVisible(true)
			arg_11_1:getChildByName("word_is_get"):setVisible(false)
		end
	else
		arg_11_1:getChildByName("word_get"):setVisible(false)
		arg_11_1:getChildByName("word_is_get"):setVisible(false)
	end
end

return var_0_0
