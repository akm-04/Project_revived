local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.activityGirlTraining
local var_0_4 = {
	PERSONAL = 1,
	SERVER = 2
}
local var_0_5 = 3
local var_0_6 = 1000
local var_0_7 = 5

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.btnState = var_0_4.PERSONAL
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))

	arg_2_0.container = var_2_0:getChildByName("bg")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:changeBtnState()
	arg_3_0:setButtonClick()
	arg_3_0.container:getChildByName("text_rule"):setString(var_0_1:translation("ACTIVITY_GIRL_TRAINING_TEXT1"))

	if arg_3_0.selfPlayer:getHeroByTableID(xyd.tables.misc.activityGirlTrainingPartner) or arg_3_0.selfPlayer:getHeroByTableID(xyd.tables.hero:afterAwaken(xyd.tables.misc.activityGirlTrainingPartner)) then
		arg_3_0.container:getChildByName("task_bg"):getChildByName("hero_container"):setVisible(false)
		arg_3_0.container:getChildByName("task_bg"):getChildByName("task_list"):setVisible(true)
	else
		arg_3_0.container:getChildByName("task_bg"):getChildByName("hero_container"):setVisible(true)
		arg_3_0.container:getChildByName("task_bg"):getChildByName("task_list"):setVisible(false)
	end

	arg_3_0.container:getChildByName("task_bg"):getChildByName("hero_container"):getChildByName("text_tips"):setString(var_0_1:translation("ACTIVITY_GIRL_TRAINING_TEXT3"))

	local var_3_0 = xyd.tables.hero:modelID(xyd.tables.misc.activityGirlTrainingPartner)
	local var_3_1 = xyd.HeroAnimation.new(nil, var_3_0, 0.9, {})
	local var_3_2 = xyd.tables.model:uiScale(var_3_0)

	var_3_1:addTo(arg_3_0.container:getChildByName("task_bg"):getChildByName("hero_container"):getChildByName("hero"))
	var_3_1:setScale(var_3_2 * 0.8)
	var_3_1:idle(true)

	local var_3_3 = display.newNode()

	var_3_3:setContentSize(arg_3_0.container:getChildByName("task_bg"):getChildByName("hero_container"):getContentSize())
	var_3_3:addTo(arg_3_0.container:getChildByName("task_bg"):getChildByName("hero_container"))
	var_3_3:setAnchorPoint(0, 0)
	var_3_3:setTouchEnabled(true)
	var_3_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0.container:getChildByName("task_bg"):getChildByName("hero_container"):setVisible(false)
			arg_3_0.container:getChildByName("task_bg"):getChildByName("task_list"):setVisible(true)
		end
	end)

	local var_3_4 = arg_3_0.container:getChildByName("task_bg"):getChildByName("task_list")
	local var_3_5 = var_3_4:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_5.width, var_3_5.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_4):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0:updateListInfo()
	arg_3_0.list:reload()
	arg_3_0:updateRedMark()

	arg_3_0.speakIndex = 0

	arg_3_0:setMessageBoxVisible(false)

	arg_3_0.autoCount = 0

	local var_3_6 = display.newNode()

	var_3_6:setContentSize(arg_3_0.container:getChildByName("talks_touch"):getContentSize())
	var_3_6:setTouchEnabled(true)
	var_3_6:setAnchorPoint(0, 0)
	arg_3_0.container:getChildByName("talks_touch"):addChild(var_3_6)
	var_3_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" and not arg_3_0.playSound_ then
			arg_3_0:playSound()
		end
	end)
	arg_3_0:removeDelay()
end

function var_0_0.updateRedMark(arg_6_0)
	arg_6_0.container:getChildByName("btn_personal"):getChildByName("red_mark"):setVisible(false)
	arg_6_0.container:getChildByName("btn_server"):getChildByName("red_mark"):setVisible(false)

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.details.base_info.is_awards) do
		if arg_6_0.details.base_info.is_awards[iter_6_0] == 0 and arg_6_0.details.mission_list[iter_6_0].is_complete == 1 and var_0_3:type(iter_6_0) == var_0_4.PERSONAL and (arg_6_0.selfPlayer:getHeroByTableID(xyd.tables.misc.activityGirlTrainingPartner) or arg_6_0.selfPlayer:getHeroByTableID(xyd.tables.hero:afterAwaken(xyd.tables.misc.activityGirlTrainingPartner))) then
			arg_6_0.container:getChildByName("btn_personal"):getChildByName("red_mark"):setVisible(true)
		end

		if arg_6_0.details.base_info.is_awards[iter_6_0] == 0 and arg_6_0.details.mission_list[iter_6_0].is_complete == 1 and var_0_3:type(iter_6_0) == var_0_4.SERVER and (arg_6_0.selfPlayer:getHeroByTableID(xyd.tables.misc.activityGirlTrainingPartner) or arg_6_0.selfPlayer:getHeroByTableID(xyd.tables.hero:afterAwaken(xyd.tables.misc.activityGirlTrainingPartner))) then
			arg_6_0.container:getChildByName("btn_server"):getChildByName("red_mark"):setVisible(true)
		end
	end
end

function var_0_0.updateListInfo(arg_7_0)
	arg_7_0.listInfo = {}

	local var_7_0 = var_0_3:ids()

	for iter_7_0, iter_7_1 in ipairs(var_7_0) do
		if var_0_3:type(iter_7_1) == arg_7_0.btnState then
			table.insert(arg_7_0.listInfo, iter_7_1)
		end
	end
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.listInfo
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.list:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.list:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = 667
		local var_8_2 = 166

		var_8_0:setItemSize(var_8_1, var_8_2)

		local var_8_3 = display.newNode()

		var_8_3:setContentSize(var_8_1, 166)
		arg_8_0:initCell(var_8_3, arg_8_3)
		var_8_0:addContent(var_8_3)

		return var_8_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_8_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0.listInfo[arg_9_2]
	local var_9_1 = var_0_3:gift(var_9_0)
	local var_9_2 = var_0_3:desc(var_9_0)
	local var_9_3 = var_0_3:req(var_9_0)
	local var_9_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1140/task_item.csb")

	var_9_4:setPosition(0, 0)
	var_9_4:setAnchorPoint(0, 0)
	arg_9_1:addChild(var_9_4)

	local var_9_5 = var_9_4:getChildByName("bg")

	var_9_5:getChildByName("text_task"):setString(string.format(var_0_3:desc(var_9_0), xyd.tables.hero:name(xyd.tables.misc.activityGirlTrainingPartner), var_0_3:req(var_9_0)))
	arg_9_0:rewardLayer(var_9_5:getChildByName("item_container"), var_9_1)
	var_9_5:getChildByName("btn_get"):setTouchEnabled(false)
	var_9_5:getChildByName("btn_get"):getChildByName("txt"):setString(var_0_1:translation("OBTAIN"))
	var_9_5:getChildByName("btn_not_get"):setTouchEnabled(false)
	var_9_5:getChildByName("btn_not_get"):getChildByName("txt"):setString(var_0_1:translation("OBTAIN"))
	var_9_5:getChildByName("btn_has_get"):setTouchEnabled(false)
	var_9_5:getChildByName("btn_get"):setVisible(false)
	var_9_5:getChildByName("btn_not_get"):setVisible(false)
	var_9_5:getChildByName("btn_has_get"):setVisible(false)
	var_9_5:getChildByName("task_count"):setVisible(false)

	if arg_9_0.details.base_info.is_awards[var_9_0] == 1 then
		var_9_5:getChildByName("btn_has_get"):setVisible(true)
	elseif arg_9_0.details.mission_list[var_9_0].is_complete == 1 and not arg_9_0.selfPlayer:getHeroByTableID(xyd.tables.misc.activityGirlTrainingPartner) and not arg_9_0.selfPlayer:getHeroByTableID(xyd.tables.hero:afterAwaken(xyd.tables.misc.activityGirlTrainingPartner)) then
		var_9_5:getChildByName("btn_not_get"):setVisible(true)
	elseif arg_9_0.details.mission_list[var_9_0].is_complete == 1 then
		var_9_5:getChildByName("btn_get"):setVisible(true)
		var_9_5:getChildByName("btn_get"):setTouchEnabled(true)
		var_9_5:getChildByName("btn_get"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.began then
				arg_10_0:setScale(0.9)
			elseif arg_10_1 == ccui.TouchEventType.moved then
				arg_10_0:setScale(1)
			elseif arg_10_1 == ccui.TouchEventType.ended then
				arg_10_0:setScale(1)
				xyd.playButtonSound()

				if xyd.ServerTime.get():getServerTime() >= arg_9_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_9_0.activity.end_time then
					local var_10_0 = var_9_0

					arg_9_0.activitiesModel:getActivityReward(xyd.Activities.GirlTraining, var_10_0, function(arg_11_0, arg_11_1)
						if arg_11_0 == xyd.error.OK then
							arg_9_0.selfPlayer:handleRewards(arg_11_1.awards)

							local var_11_0 = {
								activity_id = xyd.Activities.GirlTraining
							}

							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_11_0, function(arg_12_0, arg_12_1)
								if arg_12_0 == xyd.error.OK then
									arg_9_0.details = arg_12_1.details

									arg_9_0.list:refreshList()
									arg_9_0:updateRedMark()
									arg_9_0.activitiesModel:clearRedMarkState(xyd.Activities.GirlTraining, 2)

									local var_12_0 = xyd.WindowManager.get():getWindow("activities")

									if var_12_0 and var_12_0.rightItems then
										var_12_0:updateRightCell(xyd.Activities.GirlTraining)
									end
								end
							end)
						end
					end)
				else
					if xyd.ServerTime.get():getServerTime() < arg_9_0.activity.start_time then
						message = var_0_1:translation("ACTIVITY_NO_OPEN")
					elseif xyd.ServerTime.get():getServerTime() >= arg_9_0.activity.end_time then
						message = var_0_1:translation("ACTIVITY_END")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = message
					})
				end
			end
		end)
	elseif arg_9_0.details.mission_list[var_9_0].is_complete == 0 then
		var_9_5:getChildByName("task_count"):setVisible(true)

		if var_9_0 == 10 then
			var_9_5:getChildByName("task_count"):setString(var_0_1:translation("ACTIVITY_GIRL_TRAINING_TEXT2") .. "\n(0/1)")
		else
			var_9_5:getChildByName("task_count"):setString(var_0_1:translation("ACTIVITY_GIRL_TRAINING_TEXT2") .. "\n(" .. arg_9_0.details.mission_list[var_9_0].count .. "/" .. var_0_3:req(var_9_0) .. ")")
		end
	end
end

function var_0_0.changeBtnState(arg_13_0)
	if arg_13_0.btnState == var_0_4.SERVER then
		arg_13_0.container:getChildByName("btn_server"):setTouchEnabled(false)
		arg_13_0.container:getChildByName("btn_personal"):setTouchEnabled(true)
		arg_13_0.container:getChildByName("btn_server"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0.container:getChildByName("btn_personal"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_13_0.btnState == var_0_4.PERSONAL then
		arg_13_0.container:getChildByName("btn_server"):setTouchEnabled(true)
		arg_13_0.container:getChildByName("btn_personal"):setTouchEnabled(false)
		arg_13_0.container:getChildByName("btn_server"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0.container:getChildByName("btn_personal"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.setButtonClick(arg_14_0)
	arg_14_0.container:getChildByName("btn_server"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			arg_14_0.btnState = var_0_4.SERVER

			arg_14_0:changeBtnState()
			arg_14_0:updateListInfo()
			arg_14_0.list:reload()
		end
	end)
	arg_14_0.container:getChildByName("btn_personal"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			arg_14_0.btnState = var_0_4.PERSONAL

			arg_14_0:changeBtnState()
			arg_14_0:updateListInfo()
			arg_14_0.list:reload()
		end
	end)
end

function var_0_0.playSound(arg_17_0)
	if arg_17_0.playSound_ then
		return
	end

	local var_17_0 = xyd.tables.hero:clickDialog(xyd.tables.misc.activityGirlTrainingPartner)
	local var_17_1 = xyd.tables.hero:dialogSounds(xyd.tables.misc.activityGirlTrainingPartner)
	local var_17_2 = xyd.tables.hero:soundTimes(xyd.tables.misc.activityGirlTrainingPartner)
	local var_17_3 = xyd.tables.hero:name(xyd.tables.misc.activityGirlTrainingPartner)

	if var_17_0 ~= nil and #var_17_0 > 0 then
		if arg_17_0.speakIndex == 0 then
			arg_17_0.speakIndex = math.random(#var_17_0)
		else
			arg_17_0.speakIndex = xyd.randomIndex(arg_17_0.speakIndex, #var_17_0)
		end

		local var_17_4 = arg_17_0.speakIndex

		arg_17_0:npcSpeak(var_17_0[var_17_4], var_17_2[var_17_4], var_17_3)

		if var_17_1[var_17_4] ~= "" then
			arg_17_0.playSound_ = true

			var_0_2.performWithDelayGlobal(function()
				if tolua.isnull(arg_17_0.container) then
					return
				end

				arg_17_0.playSound_ = false
			end, var_17_2[var_17_4])
		end
	end
end

function var_0_0.setMessageBoxVisible(arg_19_0, arg_19_1)
	if arg_19_1 then
		arg_19_0.container:getChildByName("talks"):setVisible(true)
	else
		arg_19_0.container:getChildByName("talks"):setVisible(false)
	end
end

function var_0_0.npcSpeak(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	arg_20_0.container:getChildByName("talks"):getChildByName("message_node"):removeAllChildren()
	arg_20_0.container:getChildByName("talks"):getChildByName("name_node"):removeAllChildren()

	local var_20_0 = {
		size = 24,
		color = cc.c4b(86, 51, 19, 255)
	}
	local var_20_1 = xyd.AssetLoader.get():loadLabel(var_20_0)

	var_20_1:setMaxLineWidth(260)
	var_20_1:setString(arg_20_1)
	var_20_1:setAnchorPoint(cc.p(0, 1))
	var_20_1:addTo(arg_20_0.container:getChildByName("talks"):getChildByName("message_node"))

	local var_20_2 = {
		size = 24,
		color = xyd.color.RED,
		valign = cc.ui.TEXT_VALIGN_CENTER
	}
	local var_20_3 = xyd.AssetLoader.get():loadLabel(var_20_2)

	var_20_3:setMaxLineWidth(150)
	var_20_3:setString(arg_20_3)
	var_20_3:setAnchorPoint(cc.p(0.5, 1))
	var_20_3:addTo(arg_20_0.container:getChildByName("talks"):getChildByName("name_node"))

	local var_20_4 = var_20_1:getContentSize().height
	local var_20_5 = var_20_1:getContentSize().width

	arg_20_0.container:getChildByName("talks"):getChildByName("duihua_bg"):height(var_20_4 + 30)
	arg_20_0.container:getChildByName("talks"):getChildByName("duihua_bg"):width(var_20_5 + 55)
	arg_20_0.container:getChildByName("talks"):getChildByName("message_node"):height(var_20_4 + 55)
	var_20_1:setPositionY(25)
	var_20_3:setPosition(arg_20_0.container:getChildByName("talks"):getChildByName("name_node"):getWidth() / 2, 30)
	arg_20_0:setMessageBoxVisible(true)

	arg_20_0.delay = var_0_2.performWithDelayGlobal(function()
		if arg_20_0.container and not tolua.isnull(arg_20_0.container) then
			arg_20_0:setMessageBoxVisible(false)
		end
	end, arg_20_2)
end

function var_0_0.removeDelay(arg_22_0)
	if arg_22_0.container and not tolua.isnull(arg_22_0.container) then
		arg_22_0:setMessageBoxVisible(false)
	end

	arg_22_0.playSound_ = false
	arg_22_0.autoCount = 0

	if arg_22_0.delay ~= nil then
		var_0_2.unscheduleGlobal(arg_22_0.delay)

		arg_22_0.delay = nil
	end

	if arg_22_0.autoHandle ~= nil then
		var_0_2.unscheduleGlobal(arg_22_0.autoHandle)

		arg_22_0.autoHandle = nil
	end
end

function var_0_0.autoPlaySound(arg_23_0)
	if arg_23_0.autoHandle ~= nil then
		var_0_2.unscheduleGlobal(arg_23_0.autoHandle)

		arg_23_0.autoHandle = nil
	end

	arg_23_0.autoHandle = var_0_2.scheduleGlobal(function()
		if arg_23_0.container and not tolua.isnull(arg_23_0.container) then
			arg_23_0.autoCount = arg_23_0.autoCount + 1

			if arg_23_0.autoCount == var_0_7 and not arg_23_0.playSound_ then
				arg_23_0:playSound()
			end
		else
			var_0_2.unscheduleGlobal(arg_23_0.autoHandle)

			arg_23_0.autoHandle = nil
		end
	end, 1)
end

function var_0_0.rewardLayer(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = xyd.tables.gift:items(arg_25_2)

	if #var_25_0 == 1 and var_25_0[1] == 0 then
		var_25_0 = {}
	end

	local var_25_1 = xyd.tables.gift:itemNum(arg_25_2)
	local var_25_2 = #var_25_1
	local var_25_3 = arg_25_1:getContentSize().height
	local var_25_4 = var_25_3 / 4 - 1
	local var_25_5 = #var_25_0

	for iter_25_0 = 1, #var_25_0 do
		local var_25_6 = display.newNode()

		var_25_6:setContentSize(var_25_3, var_25_3)

		local var_25_7 = xyd.tables.item:type(var_25_0[iter_25_0])

		xyd.setItemBorder(var_25_6, var_25_0[iter_25_0], false, false, var_25_1[iter_25_0])
		var_25_6:addTo(arg_25_1)
		var_25_6:setAnchorPoint(cc.p(0, 0))
		var_25_6:setPosition((iter_25_0 - 1) * (var_25_3 + var_25_4), 0)

		local var_25_8 = {
			id = var_25_0[iter_25_0],
			lev = xyd.tables.item:level(var_25_0[iter_25_0])
		}

		if xyd.tables.item:type(var_25_0[iter_25_0]) == -1 then
			var_25_8.tipsType = 0
			var_25_8.desc1 = xyd.tables.hero:getDes(var_25_0[iter_25_0])
		elseif specialItem then
			var_25_8.tipsType = 1
			var_25_8.id = -3
		else
			var_25_8.tipsType = 1
			var_25_8.desc1 = xyd.tables.item:desc1(var_25_0[iter_25_0])
			var_25_8.desc2 = xyd.tables.item:desc2(var_25_0[iter_25_0])
		end

		var_25_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_25_0[iter_25_0])
		var_25_8.name = xyd.tables.item:name(var_25_0[iter_25_0])

		arg_25_0:addTips(var_25_6, var_25_8)
	end

	local var_25_9 = xyd.tables.gift:crystal(arg_25_2)

	if var_25_9 and var_25_9 > 0 then
		local var_25_10 = display.newNode()

		var_25_10:setContentSize(var_25_3, var_25_3)
		xyd.setItemBorder(var_25_10, -1, false, false, var_25_9)
		var_25_10:addTo(arg_25_1)
		var_25_10:setAnchorPoint(cc.p(0, 0))
		var_25_10:setPosition(var_25_5 * (var_25_3 + var_25_4), 0)

		local var_25_11 = {}

		var_25_11.id = -1
		var_25_11.tipsType = 1

		arg_25_0:addTips(var_25_10, var_25_11)

		var_25_5 = var_25_5 + 1
	end

	local var_25_12 = xyd.tables.gift:mana(arg_25_2)

	if var_25_12 and var_25_12 > 0 then
		local var_25_13 = display.newNode()

		var_25_13:setContentSize(var_25_3, var_25_3)
		xyd.setItemBorder(var_25_13, -2, false, false, var_25_12)
		var_25_13:addTo(arg_25_1)
		var_25_13:setAnchorPoint(cc.p(0, 0))
		var_25_13:setPosition(var_25_5 * (var_25_3 + var_25_4), 0)

		local var_25_14 = {}

		var_25_14.id = -2
		var_25_14.tipsType = 1

		arg_25_0:addTips(var_25_13, var_25_14)

		local var_25_15 = var_25_5 + 1
	end

	return arg_25_1
end

function var_0_0.release(arg_26_0)
	var_0_0.super.release(arg_26_0, params)
	arg_26_0:removeDelay()
end

return var_0_0
