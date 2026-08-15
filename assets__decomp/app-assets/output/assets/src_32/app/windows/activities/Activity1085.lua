local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.model
local var_0_3 = import("framework.scheduler")
local var_0_4 = 10
local var_0_5 = 30
local var_0_6 = 10
local var_0_7 = 10001015
local var_0_8 = 40001015
local var_0_9 = 2
local var_0_10 = {
	OPEN = 2,
	IS_OVER = 3,
	NOT_OPEN = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.dispatcher = nil
	arg_1_0.loadBarrageHandler = nil
	arg_1_0.showBarrageHandler = nil
	arg_1_0.timeHandler = nil
	arg_1_0.showDialogHandler = nil
	arg_1_0.heroModel = nil
	arg_1_0.barrageInfos = {}
	arg_1_0.unusedBallistic = {}
	arg_1_0.ballisticNums = 0
	arg_1_0.isLoadingBarrage = false
	arg_1_0.clippingNode = nil
	arg_1_0.showDialogTime = 0
	arg_1_0.isShowBarrage = false
	arg_1_0.activityPrayTime = xyd.tables.misc.activityPrayTime
	arg_1_0.activityPrayAwardTime = xyd.tables.misc.activityPrayAwardTime
	arg_1_0.dialogDefaultTime = xyd.tables.misc.dialogDefaultTime
	arg_1_0.timeText = ""
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	arg_2_0.parent:removeAllChildren()

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:initHeroModel()
	arg_3_0:initTimeCount()
	arg_3_0:showDialog()

	if arg_3_0:checkBarrageIsShow() then
		arg_3_0:initBarrage()
	end

	local var_3_0 = display.newNode()
	local var_3_1 = arg_3_0.container:getChildByName("hero"):getContentSize()

	var_3_0:setContentSize(var_3_1)
	var_3_0:addTo(arg_3_0.container:getChildByName("hero"))
	var_3_0:setLocalZOrder(99)
	var_3_0:setTouchEnabled(true)
	var_3_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			if arg_3_0.showDialogTime and arg_3_0.showDialogTime > 0 then
				arg_3_0.showDialogTime = arg_3_0.dialogDefaultTime
			else
				arg_3_0:showDialog()
			end
		end
	end)
	arg_3_0.container:getChildByName("img_ling"):setTouchEnabled(true)
	arg_3_0.container:getChildByName("img_ling"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			if arg_3_0:checkCanGetAward() then
				arg_3_0:showLingAnimation(function()
					arg_3_0.activitiesModel:getActivityReward(arg_3_0.activity.table_id, nil, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							arg_3_0.activity.details.is_awarded = 1

							local var_7_0 = arg_7_1.awards

							xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(var_7_0, function()
								arg_3_0:showDialog()
							end)

							local var_7_1 = {
								pray_msg = arg_7_1.pray_msg,
								pray_player = arg_7_1.pray_player
							}

							xyd.WindowManager.get():openWindow("new_year_blessing", var_7_1)
						end
					end)
				end)
			else
				arg_3_0:showDialog()
			end
		end
	end)
	arg_3_0.container:getChildByName("img_altar"):setTouchEnabled(true)
	arg_3_0.container:getChildByName("img_altar"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			arg_3_0.container:getChildByName("img_altar"):setScale(0.9)

			return true
		elseif arg_9_0.name == "ended" then
			arg_3_0.container:getChildByName("img_altar"):setScale(1)

			local var_9_0 = arg_3_0:checkActivityStatus()
			local var_9_1 = xyd.ServerTime.get():getServerTime()

			if var_9_0 ~= var_0_10.OPEN then
				arg_3_0:showDialog()

				return
			elseif arg_3_0.activity.details.is_send ~= 0 and var_9_1 < arg_3_0.activityPrayTime then
				local var_9_2 = var_0_1:translation("NEW_YEAR_BLESSING_TIPS_9")

				arg_3_0:showDialog(var_9_2)

				return
			end

			local var_9_3 = {
				callback = function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						arg_3_0.activity.details.is_send = 1

						local var_10_0 = var_0_1:translation("NEW_YEAR_BLESSING_TIPS_8")

						arg_3_0:showDialog(var_10_0)
					end
				end
			}

			xyd.WindowManager.get():openWindow("input_new_year_blessing", var_9_3)
		end
	end)
	arg_3_0.container:getChildByName("btn_rule"):setLocalZOrder(99)
	arg_3_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = {
				title_name = "NEW_YEAR_BLESSING_RULE_TITLE",
				rule = "NEW_YEAR_BLESSING_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_11_0)
		end
	end)

	arg_3_0.dispatcher = xyd.EventDispatcher.get():addEventListener(xyd.event.WORLD_NOTICE, function(arg_12_0)
		if arg_12_0.params and arg_12_0.params.notice_type == xyd.NoticeType.NEW_YEAR_BLESSING then
			local var_12_0 = arg_12_0.params.params.message

			if var_12_0 then
				table.insert(arg_3_0.barrageInfos, 1, var_12_0)
			end
		end
	end)
end

function var_0_0.checkActivityStatus(arg_13_0)
	local var_13_0 = xyd.ServerTime.get():getServerTime()

	if var_13_0 < arg_13_0.activity.start_time then
		return var_0_10.NOT_OPEN
	elseif var_13_0 >= arg_13_0.activity.end_time then
		return var_0_10.IS_OVER
	else
		return var_0_10.OPEN
	end
end

function var_0_0.showLingAnimation(arg_14_0, arg_14_1)
	if arg_14_0.lingIsAnimation then
		return
	end

	arg_14_0.container:getChildByName("img_ling"):setRotation(-10)

	local var_14_0 = cc.RotateBy:create(0.1, 20)
	local var_14_1 = cc.RotateBy:create(0.1, -20)
	local var_14_2 = cc.RepeatForever:create(transition.sequence({
		var_14_0,
		var_14_1
	}))
	local var_14_3 = cc.DelayTime:create(var_0_9)
	local var_14_4 = cc.CallFunc:create(function()
		arg_14_0.lingIsAnimation = false

		if arg_14_0.container and not tolua.isnull(arg_14_0.container) then
			arg_14_0.container:getChildByName("img_ling"):setRotation(0)
			transition.removeAction(var_14_2)

			if arg_14_1 then
				arg_14_1()
			end
		end
	end)
	local var_14_5 = transition.sequence({
		var_14_3,
		var_14_4
	})

	arg_14_0.container:getChildByName("img_ling"):runAction(var_14_2)
	arg_14_0.container:getChildByName("img_ling"):runAction(var_14_5)

	arg_14_0.lingIsAnimation = true
end

function var_0_0.initHeroModel(arg_16_0)
	arg_16_0.heroModel = xyd.HeroAnimation.new(var_0_7, var_0_8, var_0_2:uiScale(var_0_8), {})

	if arg_16_0.heroModel then
		arg_16_0.heroModel:idle()
	end

	local var_16_0 = arg_16_0.container:getChildByName("hero"):getContentSize()

	arg_16_0.heroModel:addTo(arg_16_0.container:getChildByName("hero"))
	arg_16_0.heroModel:setScale(0.9)
	arg_16_0.heroModel:setPositionX(var_16_0.width / 2)
end

function var_0_0.checkCanGetAward(arg_17_0)
	local var_17_0 = xyd.ServerTime.get():getServerTime()

	if arg_17_0.activity.details.is_awarded == 0 then
		if var_17_0 < arg_17_0.activityPrayTime then
			return false
		elseif var_17_0 >= arg_17_0.activityPrayTime and var_17_0 <= arg_17_0.activityPrayAwardTime then
			return true
		elseif var_17_0 > arg_17_0.activityPrayAwardTime then
			return true
		end
	else
		return false
	end
end

function var_0_0.checkBarrageIsShow(arg_18_0)
	local var_18_0 = xyd.ServerTime.get():getServerTime()

	if var_18_0 >= arg_18_0.activityPrayTime and var_18_0 < arg_18_0.activity.end_time then
		return true
	else
		return false
	end
end

function var_0_0.initBarrage(arg_19_0)
	if arg_19_0.isShowBarrage then
		return
	end

	local var_19_0 = arg_19_0.container:getChildByName("barrage")
	local var_19_1 = var_19_0:getContentSize()

	arg_19_0.ballisticNums = math.floor(var_19_1.height / var_0_5) - 1

	for iter_19_0 = 1, arg_19_0.ballisticNums do
		table.insert(arg_19_0.unusedBallistic, iter_19_0)
	end

	arg_19_0.clippingNode = display.newClippingRegionNode()

	arg_19_0.clippingNode:setClippingRegion(cc.rect(0, 0, var_19_1.width, var_19_1.height))
	var_19_0:addChild(arg_19_0.clippingNode)

	arg_19_0.newBarrage = display.newNode()

	arg_19_0.newBarrage:setContentSize(var_19_1.width, var_19_1.height)
	arg_19_0.newBarrage:addTo(arg_19_0.clippingNode)
	arg_19_0:showBarrage()
end

function var_0_0.getRandomBallistic(arg_20_0)
	if #arg_20_0.unusedBallistic <= 0 then
		return 0
	end

	local var_20_0 = math.random(1, #arg_20_0.unusedBallistic)
	local var_20_1 = arg_20_0.unusedBallistic[var_20_0]

	table.remove(arg_20_0.unusedBallistic, var_20_0)

	return var_20_1
end

function var_0_0.getBulletScreen(arg_21_0)
	if not arg_21_0:checkBarrageIsShow() then
		if arg_21_0.loadBarrageHandler then
			var_0_3.unscheduleGlobal(arg_21_0.loadBarrageHandler)

			arg_21_0.loadBarrageHandler = nil
		end

		return
	end

	xyd.Backend.get():request(xyd.mid.GET_BULLET_SCREEN, {}, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			local var_22_0 = arg_22_1.messages

			for iter_22_0 = 1, #var_22_0 do
				table.insert(arg_21_0.barrageInfos, var_22_0[iter_22_0])
			end
		end

		if callback then
			callback(arg_22_0, arg_22_1)
		end

		arg_21_0.isLoadingBarrage = false
	end, nil, nil, false)
end

function var_0_0.showBarrage(arg_23_0)
	arg_23_0.isShowBarrage = true

	if arg_23_0.loadBarrageHandler then
		var_0_3.unscheduleGlobal(arg_23_0.loadBarrageHandler)

		arg_23_0.loadBarrageHandler = nil
	end

	arg_23_0:getBulletScreen()

	arg_23_0.loadBarrageHandler = var_0_3.scheduleGlobal(function()
		if arg_23_0.container and not tolua.isnull(arg_23_0.container) and arg_23_0.barrageInfos and #arg_23_0.barrageInfos <= var_0_4 and not arg_23_0.isLoadingBarrage then
			arg_23_0.isLoadingBarrage = true

			arg_23_0:getBulletScreen()
		end
	end, 2)

	if arg_23_0.showBarrageHandler then
		var_0_3.unscheduleGlobal(arg_23_0.showBarrageHandler)

		arg_23_0.showBarrageHandler = nil
	end

	arg_23_0.showBarrageHandler = var_0_3.scheduleGlobal(function()
		if arg_23_0.container and not tolua.isnull(arg_23_0.container) then
			arg_23_0:createBullet()
		end
	end, 2)
end

function var_0_0.createBullet(arg_26_0)
	local var_26_0 = math.random(5, var_0_6)

	for iter_26_0 = 1, var_26_0 do
		if arg_26_0.barrageInfos and next(arg_26_0.barrageInfos) then
			local var_26_1 = arg_26_0.barrageInfos[1]
			local var_26_2 = arg_26_0:getRandomBallistic()

			if var_26_2 == 0 then
				break
			end

			local var_26_3 = {
				parent = arg_26_0.newBarrage,
				text = var_26_1.name,
				text_2 = var_26_1.msg,
				ballistic = var_26_2,
				height = var_26_2 * var_0_5,
				callback = function()
					if arg_26_0.container and not tolua.isnull(arg_26_0.container) then
						table.insert(arg_26_0.unusedBallistic, var_26_2)
					end
				end
			}
			local var_26_4 = import("app.windows.TextBarrageItem").new()

			var_26_4:setParams(var_26_3)
			var_26_4:move()
			table.remove(arg_26_0.barrageInfos, 1)
		end
	end
end

function var_0_0.initTimeCount(arg_28_0)
	local var_28_0 = arg_28_0.container:getChildByName("text_time")

	if arg_28_0.activity.details.is_awarded == 0 then
		local var_28_1 = xyd.ServerTime.get():getServerTime()
		local var_28_2 = 0

		if var_28_1 < arg_28_0.activityPrayTime then
			arg_28_0.timeText = var_0_1:translation("NEW_YEAR_BLESSING_COUNT_1")
			var_28_2 = arg_28_0.activityPrayTime - var_28_1
		elseif var_28_1 >= arg_28_0.activityPrayTime and var_28_1 <= arg_28_0.activityPrayAwardTime then
			arg_28_0.timeText = var_0_1:translation("NEW_YEAR_BLESSING_COUNT_2")
			var_28_2 = arg_28_0.activityPrayAwardTime - var_28_1
		elseif var_28_1 > arg_28_0.activityPrayAwardTime then
			arg_28_0.timeText = var_0_1:translation("NEW_YEAR_BLESSING_COUNT_2")
			var_28_2 = 0
		end

		arg_28_0:updateTimeCount(var_28_2)
	else
		var_28_0:setVisible(false)
	end
end

function var_0_0.updateTimeCount(arg_29_0, arg_29_1)
	local var_29_0 = arg_29_0.container:getChildByName("text_time")

	if arg_29_1 <= 0 then
		var_29_0:setString(arg_29_0.timeText .. xyd.secondsToString(arg_29_1))

		return
	end

	local function var_29_1(arg_30_0)
		if arg_30_0 > 86400 then
			return xyd.secondsToString1(arg_30_0)
		else
			return xyd.secondsToString(arg_30_0)
		end
	end

	if arg_29_0.timeHandler then
		var_0_3.unscheduleGlobal(arg_29_0.timeHandler)

		arg_29_0.timeHandler = nil
	end

	if arg_29_1 > 0 then
		var_29_0:setString(arg_29_0.timeText .. var_29_1(arg_29_1))

		arg_29_0.timeHandler = var_0_3.scheduleGlobal(function()
			arg_29_1 = arg_29_1 - 1

			if var_29_0 and not tolua.isnull(var_29_0) then
				var_29_0:setString(arg_29_0.timeText .. var_29_1(arg_29_1))
			end

			if arg_29_1 <= 0 then
				if arg_29_0.timeHandler then
					var_0_3.unscheduleGlobal(arg_29_0.timeHandler)

					arg_29_0.timeHandler = nil
				end

				if arg_29_0.container and not tolua.isnull(arg_29_0.container) then
					arg_29_0:initTimeCount()
					arg_29_0:showDialog()

					if arg_29_0:checkBarrageIsShow() and not arg_29_0.isShowBarrage then
						arg_29_0:initBarrage()
					end
				end
			end
		end, 1)
	end
end

function var_0_0.getDialogText(arg_32_0)
	local var_32_0
	local var_32_1 = xyd.ServerTime.get():getServerTime()
	local var_32_2 = arg_32_0:checkActivityStatus()

	if var_32_2 == var_0_10.NOT_OPEN then
		var_32_0 = var_0_1:translation("NEW_YEAR_BLESSING_NOT_OPEN")
	elseif var_32_2 == var_0_10.IS_OVER then
		var_32_0 = var_0_1:translation("NEW_YEAR_BLESSING_IS_OVER")
	elseif arg_32_0.activity.details.is_awarded == 0 then
		if var_32_1 < arg_32_0.activityPrayTime then
			var_32_0 = var_0_1:translation("NEW_YEAR_BLESSING_TIPS_1")
		elseif var_32_1 >= arg_32_0.activityPrayTime and var_32_1 <= arg_32_0.activityPrayAwardTime then
			var_32_0 = var_0_1:translation("NEW_YEAR_BLESSING_TIPS_2")
		elseif var_32_1 > arg_32_0.activityPrayAwardTime then
			var_32_0 = var_0_1:translation("NEW_YEAR_BLESSING_TIPS_3")
		end
	else
		var_32_0 = var_0_1:translation("NEW_YEAR_BLESSING_TIPS_4")
	end

	return var_32_0
end

function var_0_0.showDialog(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_0.container:getChildByName("dialog")
	local var_33_1

	if arg_33_1 then
		var_33_1 = arg_33_1
	else
		var_33_1 = arg_33_0:getDialogText()
	end

	arg_33_0:createDialog(var_33_1)
	var_33_0:setVisible(true)

	arg_33_0.showDialogTime = arg_33_0.dialogDefaultTime

	if arg_33_0.showDialogHandler then
		var_0_3.unscheduleGlobal(arg_33_0.showDialogHandler)

		arg_33_0.showDialogHandler = nil
	end

	arg_33_0.showDialogHandler = var_0_3.scheduleGlobal(function()
		arg_33_0.showDialogTime = arg_33_0.showDialogTime - 1

		if arg_33_0.showDialogTime <= 0 then
			if arg_33_0.showDialogHandler then
				var_0_3.unscheduleGlobal(arg_33_0.showDialogHandler)

				arg_33_0.showDialogHandler = nil
			end

			if var_33_0 and not tolua.isnull(var_33_0) then
				var_33_0:setVisible(false)
			end
		end
	end, 1)
end

function var_0_0.createDialog(arg_35_0, arg_35_1)
	local var_35_0 = arg_35_0.container:getChildByName("dialog")

	var_35_0:removeAllChildren()

	local var_35_1 = {
		size = 22,
		text = arg_35_1,
		align = cc.ui.TEXT_ALIGN_LEFT,
		color = cc.c3b(56, 2, 2),
		dimensions = cc.size(264, 0)
	}
	local var_35_2 = xyd.AssetLoader.get():loadLabel(var_35_1)
	local var_35_3 = var_35_2:getContentSize().height
	local var_35_4 = math.max(var_35_3 - 25, 0)

	var_35_2:addTo(var_35_0)
	var_35_2:setAnchorPoint(cc.p(0, 0))
	var_35_2:setPosition(cc.p(20, 35))
	var_35_0:setContentSize(296, 74 + var_35_4)
end

function var_0_0.release(arg_36_0)
	if arg_36_0.loadBarrageHandler then
		var_0_3.unscheduleGlobal(arg_36_0.loadBarrageHandler)

		arg_36_0.loadBarrageHandler = nil
	end

	if arg_36_0.showBarrageHandler then
		var_0_3.unscheduleGlobal(arg_36_0.showBarrageHandler)

		arg_36_0.showBarrageHandler = nil
	end

	if arg_36_0.timeHandler then
		var_0_3.unscheduleGlobal(arg_36_0.timeHandler)

		arg_36_0.timeHandler = nil
	end

	if arg_36_0.showDialogHandler then
		var_0_3.unscheduleGlobal(arg_36_0.showDialogHandler)

		arg_36_0.showDialogHandler = nil
	end

	if arg_36_0.dispatcher then
		xyd.EventDispatcher.get():removeEventListener(arg_36_0.dispatcher)
	end

	arg_36_0.barrageInfos = {}
	arg_36_0.unusedBallistic = {}
	arg_36_0.ballisticNums = 0
	arg_36_0.isLoadingBarrage = false
	arg_36_0.showDialogTime = 0
	arg_36_0.heroModel = nil
	arg_36_0.isShowBarrage = false
	arg_36_0.lingIsAnimation = false
end

return var_0_0
