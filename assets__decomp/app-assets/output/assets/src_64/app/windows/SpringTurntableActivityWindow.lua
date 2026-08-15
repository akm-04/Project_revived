local var_0_0 = class("SpringTurntableActivityWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = import("app.model.Item")
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = require("framework.scheduler")
local var_0_7 = xyd.tables.item
local var_0_8 = xyd.tables.activityTurntableGift
local var_0_9 = 10001110
local var_0_10 = 46

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.startTime = arg_1_2.startTime
	arg_1_0.endTime = arg_1_2.endTime
	arg_1_0.leftTimes = arg_1_2.leftTimes or 0
	arg_1_0.lastIndex = 1

	if arg_1_2.lucky_star then
		arg_1_0.lucky_star = arg_1_2.lucky_star
	end

	arg_1_0.table_id = arg_1_2.table_id
	arg_1_0.is_open = arg_1_2.is_open or 0
	arg_1_0.serverTime = arg_1_2.serverTime or 0
	arg_1_0.modelState = xyd.ModelState.Walk
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:getRuleBtn()
	arg_4_0:getExchangeBtn()
	arg_4_0:setupLeftTimes()
	arg_4_0:setupDate()
	arg_4_0:setupHeroModel()
	arg_4_0:setupGoBtn()
	arg_4_0:addGiftsTips()
end

function var_0_0.getRuleBtn(arg_5_0)
	if not arg_5_0.ruleBtn_ then
		arg_5_0.ruleBtn_ = arg_5_0:nodeByName("rule_button")

		arg_5_0.ruleBtn_:addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.began then
				arg_5_0.ruleBtn_:setScale(0.9)
			elseif arg_6_1 == ccui.TouchEventType.canceled then
				arg_5_0.ruleBtn_:setScale(1)
			elseif arg_6_1 == ccui.TouchEventType.ended then
				arg_5_0:ruleClick()
				arg_5_0.ruleBtn_:setScale(1)
			end
		end)
	end

	return arg_5_0.ruleBtn_
end

function var_0_0.getExchangeBtn(arg_7_0)
	if not arg_7_0.exchangeBtn_ then
		arg_7_0.exchangeBtn_ = arg_7_0:nodeByName("shop_button")

		arg_7_0.exchangeBtn_:addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.began then
				arg_7_0.exchangeBtn_:setScale(0.9)
			elseif arg_8_1 == ccui.TouchEventType.canceled then
				arg_7_0.exchangeBtn_:setScale(1)
			elseif arg_8_1 == ccui.TouchEventType.ended then
				arg_7_0:exchangeClick()
				arg_7_0.exchangeBtn_:setScale(1)
			end
		end)
	end

	return arg_7_0.exchangeBtn_
end

function var_0_0.ruleClick(arg_9_0)
	xyd.WindowManager.get():openWindow("spring_dial_rule")
end

function var_0_0.exchangeClick(arg_10_0)
	xyd.WindowManager.get():openWindow("activity_exchange_shop", {
		lucky_star = arg_10_0.lucky_star,
		startTime = arg_10_0.startTime,
		endTime = arg_10_0.endTime,
		is_open = arg_10_0.is_open,
		serverTime = arg_10_0.serverTime,
		callback = function(arg_11_0)
			arg_10_0.lucky_star = arg_10_0.lucky_star - arg_11_0

			if arg_10_0.activitiesModel:getActivityInfo(1037).details.lucky_star then
				arg_10_0.activitiesModel:getActivityInfo(1037).details.lucky_star = arg_10_0.activitiesModel:getActivityInfo(1037).details.lucky_star - arg_11_0
			end
		end
	})
end

function var_0_0.setupLeftTimes(arg_12_0)
	local var_12_0 = arg_12_0:nodeByName("leftTimes")

	var_12_0:setString(arg_12_0.leftTimes)
	var_12_0:setVisible(true)
end

function var_0_0.setupDate(arg_13_0)
	return
end

function var_0_0.setupHeroModel(arg_14_0)
	local var_14_0 = arg_14_0:getHeroModel()

	arg_14_0:getHeroContainer():removeAllChildren()

	local var_14_1 = arg_14_0:getHeroContainer():getContentSize().width / 2

	var_14_0:setPosition(cc.p(var_14_1, 0))
	var_14_0:addTo(arg_14_0:getHeroContainer())
	var_14_0:idle()
	var_14_0:setTouchEnabled(true)
	arg_14_0:getHeroContainer():addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended and not arg_14_0.isShow then
			arg_14_0:resetModelState()
		end
	end)
end

function var_0_0.getHeroContainer(arg_16_0)
	if not arg_16_0.heroContainer_ then
		arg_16_0.heroContainer_ = arg_16_0:nodeByName("hero_container")
	end

	return arg_16_0.heroContainer_
end

function var_0_0.resetModelState(arg_17_0)
	local var_17_0 = arg_17_0:getHeroModel()

	if arg_17_0.modelState == 7 then
		arg_17_0.modelState = arg_17_0.modelState + 1
	end

	arg_17_0.modelState = arg_17_0.modelState % 7

	arg_17_0:npcSpeak(arg_17_0.modelState)

	arg_17_0.isShow = true

	local var_17_1

	if arg_17_0.modelState == xyd.ModelState.Walk then
		var_17_0:walk(true)

		arg_17_0.isShow = false
		var_17_1 = xyd.tables.model:getMoveSound(var_0_9)
	elseif arg_17_0.modelState == xyd.ModelState.Win then
		var_17_0:win(false, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getWinSound(var_0_9)
	elseif arg_17_0.modelState == xyd.ModelState.Attack1 then
		var_17_0:attack(1, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getNormalAttackSound(var_0_9)
	elseif arg_17_0.modelState == xyd.ModelState.Attack2 then
		var_17_0:attack(2, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getAttack1Sound(var_0_9)
	elseif arg_17_0.modelState == xyd.ModelState.Attack3 then
		var_17_0:attack(3, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getAttack2Sound(var_0_9)
	elseif arg_17_0.modelState == xyd.ModelState.Attack4 then
		var_17_0:attack(4, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getAttack4Sound(var_0_9)
	else
		arg_17_0:setIsShow()
	end

	if var_17_1 then
		audio.stopAllSounds()
		audio.playSound(var_17_1, false)
	end

	arg_17_0.modelState = arg_17_0.modelState + 1
end

function var_0_0.npcSpeak(arg_18_0, arg_18_1)
	if xyd.WindowManager.get():getWindow("toast") then
		xyd.WindowManager.get():closeWindow("toast")
	end

	local var_18_0 = {
		message = var_0_1:translation("TRUNTABLE_MONKEY" .. arg_18_1)
	}

	var_18_0.isAutoClose = 1
	var_18_0.txtSize = 24
	var_18_0.isOutLine = 0

	local var_18_1 = xyd.WindowManager.get():openWindow("toast", var_18_0)
	local var_18_2, var_18_3 = arg_18_0:nodeByName("npc_words"):getPosition()
	local var_18_4 = cc.p(var_18_2 + 20, var_18_3)

	var_18_1:setPosition(var_18_4)
end

function var_0_0.getHeroModel(arg_19_0)
	if not arg_19_0.heroModel_ then
		arg_19_0.heroModel_ = xyd.HeroAnimation.new(nil, var_0_9, 1, {})
	end

	return arg_19_0.heroModel_
end

function var_0_0.setupGoBtn(arg_20_0)
	if not arg_20_0.goBtn_ then
		arg_20_0.goBtn_ = arg_20_0:nodeByName("go_button")
	end

	if arg_20_0.is_open == 1 then
		arg_20_0.goBtn_:addTouchEventListener(function(arg_21_0, arg_21_1)
			if arg_21_1 == ccui.TouchEventType.began then
				arg_20_0.goBtn_:setScale(0.9)
			elseif arg_21_1 == ccui.TouchEventType.canceled then
				arg_20_0.goBtn_:setScale(1)
			elseif arg_21_1 == ccui.TouchEventType.ended then
				arg_20_0:goClick()
				arg_20_0.goBtn_:setScale(1)
			end
		end)
	elseif arg_20_0.is_open == 0 then
		arg_20_0.goBtn_:addTouchEventListener(function(arg_22_0, arg_22_1)
			if arg_22_1 == ccui.TouchEventType.began then
				arg_20_0.goBtn_:setScale(0.9)
			elseif arg_22_1 == ccui.TouchEventType.canceled then
				arg_20_0.goBtn_:setScale(1)
			elseif arg_22_1 == ccui.TouchEventType.ended then
				arg_20_0:checkActivity()
				arg_20_0.goBtn_:setScale(1)
			end
		end)
	end
end

function var_0_0.checkActivity(arg_23_0)
	if arg_23_0.startTime > arg_23_0.serverTime then
		local var_23_0 = var_0_1:translation("ACTIVITY_NO_OPEN")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_23_0
		})
	elseif arg_23_0.endTime < arg_23_0.serverTime then
		local var_23_1 = var_0_1:translation("ACTIVITY_FINISHED")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_23_1
		})
	end
end

function var_0_0.goClick(arg_24_0)
	if arg_24_0.leftTimes <= 0 then
		local var_24_0 = var_0_1:translation("NUMBER_HAS_FINISH")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_24_0
		})
	else
		arg_24_0.activitiesModel:getActivityReward(arg_24_0.table_id, nil, function(arg_25_0, arg_25_1)
			if arg_25_0 == xyd.error.OK then
				local var_25_0 = arg_25_1.gift_index
				local var_25_1
				local var_25_2 = var_25_0 - arg_24_0.lastIndex
				local var_25_3 = arg_25_1.awards

				if #var_25_3 ~= 0 and var_25_3[1].lucky_star and var_25_3[1].lucky_star >= 1 then
					arg_24_0.lucky_star = arg_24_0.lucky_star + var_25_3[1].lucky_star
				end

				arg_24_0.tmpLeftTimes = arg_25_1.times

				if not arg_24_0.giftCounts then
					arg_24_0.giftCounts = var_0_8:giftNums()
				end

				local var_25_4 = 360 / arg_24_0.giftCounts

				if var_25_2 >= 0 then
					var_25_1 = var_25_4 * var_25_2
				else
					var_25_1 = var_25_4 * (var_25_2 + arg_24_0.giftCounts)
				end

				arg_24_0:setBtn(false)

				arg_24_0.leftTimes = arg_24_0.leftTimes - 1

				local var_25_5 = xyd.WindowManager.get():getWindow("activities")

				if var_25_5 then
					var_25_5.openedActivities[xyd.Activities.SpringDial].springDialTimes = arg_24_0.leftTimes
				end

				arg_24_0:setupLeftTimes()

				arg_24_0.trueAngle = var_25_1
				arg_24_0.awards = var_25_3
				arg_24_0.giftIndex = var_25_0

				if not arg_24_0.blockLayer_ then
					arg_24_0:addBlockLayerTouchWithStop()
				else
					arg_24_0.blockLayer_:setTouchEnabled(true)
					arg_24_0.blockLayer_:setVisible(true)
				end

				arg_24_0:startTurn(var_25_1, var_25_3, var_25_0)
			end
		end)
	end
end

function var_0_0.setBtn(arg_26_0, arg_26_1)
	arg_26_0.goBtn_:setTouchEnabled(arg_26_1)
	arg_26_0.ruleBtn_:setTouchEnabled(arg_26_1)
	arg_26_0:getHeroContainer():setTouchEnabled(arg_26_1)
end

function var_0_0.startTurn(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local var_27_0 = cc.RotateBy:create(2.8, 1440)
	local var_27_1 = cc.RotateBy:create(4.4, 1440 - arg_27_1)
	local var_27_2 = cc.CallFunc:create(function()
		arg_27_0:getHeroModel():walk(true)

		soundFile = xyd.tables.model:getMoveSound(var_0_9)
	end)
	local var_27_3 = cc.CallFunc:create(function()
		arg_27_0:getAward()
	end)
	local var_27_4 = cc.Sequence:create(var_27_2, cc.EaseSineIn:create(var_27_0), cc.EaseSineOut:create(var_27_1), var_27_3)

	arg_27_0:nodeByName("yuanpan"):runActionOnce(var_27_4)
end

function var_0_0.setIsShow(arg_30_0)
	arg_30_0.isShow = false

	arg_30_0:getHeroModel():idle()
	arg_30_0:getHeroContainer():setTouchEnabled(true)
end

function var_0_0.addBlockLayerTouchWithStop(arg_31_0)
	local var_31_0 = cc.c4b(0, 0, 0, 0)
	local var_31_1 = 100

	arg_31_0.blockLayer_ = display.newColorLayer(var_31_0)

	local var_31_2 = arg_31_0:convertToWorldSpace(cc.p(0, 0))

	arg_31_0.blockLayer_:pos(-var_31_2.x, -var_31_2.y):addTo(arg_31_0, var_31_1)
	arg_31_0.blockLayer_:setTouchEnabled(true)
	arg_31_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_32_0)
		if arg_32_0.name == "began" then
			return true
		elseif arg_32_0.name == "ended" then
			arg_31_0:nodeByName("yuanpan"):stopAllActions()

			if arg_31_0.lastIndex >= arg_31_0.giftIndex then
				arg_31_0:nodeByName("yuanpan"):setRotation(-(arg_31_0.trueAngle + (arg_31_0.lastIndex - 1) * (360 / arg_31_0.giftCounts)))
			else
				arg_31_0:nodeByName("yuanpan"):setRotation(-(arg_31_0.trueAngle + (arg_31_0.lastIndex - 1) * (360 / arg_31_0.giftCounts) - 360))
			end

			arg_31_0:getAward()
		end
	end)
end

function var_0_0.getAward(arg_33_0)
	arg_33_0:getHeroModel():win(false, handler(arg_33_0, arg_33_0.setIsShow))

	soundFile = xyd.tables.model:getWinSound(var_0_9)

	local var_33_0 = xyd.WindowManager.get():getWindow("activities")

	if arg_33_0.leftTimes ~= arg_33_0.tmpLeftTimes then
		arg_33_0.leftTimes = arg_33_0.tmpLeftTimes

		if var_33_0 then
			var_33_0.openedActivities[xyd.Activities.SpringDial].springDialTimes = arg_33_0.leftTimes
		end

		arg_33_0:setupLeftTimes()
	end

	if arg_33_0.leftTimes == 0 then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):clearRedMarkState(xyd.Activities.SpringDial, 2)

		if var_33_0 then
			var_33_0:rightLayout()
		end
	end

	arg_33_0.lastIndex = arg_33_0.giftIndex

	arg_33_0.selfPlayer:handleRewards(arg_33_0.awards)
	arg_33_0:setBtn(true)
	arg_33_0.blockLayer_:setTouchEnabled(false)
	arg_33_0.blockLayer_:setVisible(false)
end

function var_0_0.addGiftsTips(arg_34_0)
	local var_34_0 = var_0_8:giftNums()

	for iter_34_0 = 1, var_34_0 do
		arg_34_0:nodeByName("gift_" .. iter_34_0):setTouchEnabled(false)

		local var_34_1 = xyd.AssetLoader.get():loadSprite(var_0_8:giftIcon(iter_34_0))

		arg_34_0:nodeByName("gift_" .. iter_34_0):setSpriteFrame(var_34_1:getSpriteFrame())

		local var_34_2 = display.newNode()
		local var_34_3 = arg_34_0:nodeByName("gift_" .. iter_34_0):getContentSize()

		var_34_2:addTo(arg_34_0:nodeByName("gift_" .. iter_34_0))
		var_34_2:setTouchEnabled(true)
		var_34_2:setContentSize(var_0_10, var_0_10)
		var_34_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_34_2:setPosition(cc.p(var_34_3.width / 2, var_34_3.height / 2))
		var_34_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_35_0)
			if arg_35_0.name == "began" then
				if xyd.WindowManager.get():getWindow("toast") then
					xyd.WindowManager.get():closeWindow("toast")
				end

				local var_35_0 = {
					message = var_0_8:desc(iter_34_0)
				}

				var_35_0.isAutoClose = 0
				var_35_0.txtSize = 24
				var_35_0.isOutLine = 0

				local var_35_1 = xyd.WindowManager.get():openWindow("toast", var_35_0)
				local var_35_2, var_35_3 = arg_34_0:nodeByName("npc_words"):getPosition()
				local var_35_4 = cc.p(var_35_2 + 20, var_35_3)

				var_35_1:setPosition(var_35_4)

				return true
			elseif arg_35_0.name == "ended" and xyd.WindowManager.get():getWindow("toast") then
				xyd.WindowManager.get():closeWindow("toast")
			end
		end)
	end
end

function var_0_0.didClose(arg_36_0)
	var_0_0.super.didClose()
end

return var_0_0
