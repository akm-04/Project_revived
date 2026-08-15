local var_0_0 = class("ChristmasActivityWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Item")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.item
local var_0_5 = xyd.tables.translation
local var_0_6 = 50001025
local var_0_7 = 50001026
local var_0_8 = 50001027
local var_0_9 = 50001028
local var_0_10 = 50001029
local var_0_11 = 1027
local var_0_12 = 5
local var_0_13 = 11001054

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.startTime = arg_1_2.startTime
	arg_1_0.endTime = arg_1_2.endTime
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
	arg_4_0:getGiftBox()
	arg_4_0:getGiftSock()
	arg_4_0:getGiftBall()
	arg_4_0:getGiftFlower()
	arg_4_0:getGiftStar()
	arg_4_0:setupEffect()
	arg_4_0:getGiftHat()
	arg_4_0:update()
end

function var_0_0.getRuleBtn(arg_5_0)
	if not arg_5_0.ruleBtn_ then
		arg_5_0.ruleBtn_ = arg_5_0:nodeByName("button_rule")

		arg_5_0.ruleBtn_:addTouchEventListener(function(arg_6_0, arg_6_1)
			arg_5_0:buttonHandler(handler(arg_5_0, arg_5_0.ruleClick), arg_6_0, arg_6_1)
		end)
	end

	return arg_5_0.ruleBtn_
end

function var_0_0.ruleClick(arg_7_0)
	xyd.WindowManager.get():openWindow("christmas_rule")
end

function var_0_0.getGiftBox(arg_8_0)
	if not arg_8_0.giftBox_ then
		arg_8_0.giftBox_ = arg_8_0:nodeByName("gift_box")

		arg_8_0:nodeByName("text_box"):setString(var_0_4:name(var_0_6))
		arg_8_0.giftBox_:setTouchEnabled(true)
		arg_8_0.giftBox_:setTouchSwallowEnabled(false)
		arg_8_0.giftBox_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				arg_8_0.prevX_ = arg_9_0.x
				arg_8_0.prevY_ = arg_9_0.y
				arg_8_0.startClick_ = true

				arg_8_0.giftBox_:scale(1.3)
			elseif arg_9_0.name == "moved" then
				if math.abs(arg_9_0.y - arg_8_0.prevY_) > 5 or math.abs(arg_9_0.x - arg_8_0.prevX_) > 5 then
					arg_8_0.startClick_ = false
				end
			elseif arg_9_0.name == "ended" then
				arg_8_0.giftBox_:scale(1)

				local var_9_0 = xyd.ServerTime.get():getServerTime()

				if var_9_0 > arg_8_0.endTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_END")
					})

					return true
				elseif var_9_0 < arg_8_0.startTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_NO_OPEN")
					})

					return true
				end

				if arg_8_0.startClick_ then
					local var_9_1 = var_0_1.new()

					var_9_1:populate({
						table_id = var_0_6
					})
					xyd.WindowManager.get():openWindow("show_item_info", {
						item = var_9_1
					})
				end
			end

			return true
		end)
	end

	return arg_8_0.giftBox_
end

function var_0_0.getGiftSock(arg_10_0)
	if not arg_10_0.giftSock_ then
		arg_10_0.giftSock_ = arg_10_0:nodeByName("gift_sock")

		arg_10_0:nodeByName("text_sock"):setString(var_0_4:name(var_0_8))
		arg_10_0.giftSock_:setTouchEnabled(true)
		arg_10_0.giftSock_:setTouchSwallowEnabled(false)
		arg_10_0.giftSock_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				arg_10_0.prevX_ = arg_11_0.x
				arg_10_0.prevY_ = arg_11_0.y
				arg_10_0.startClick_ = true

				arg_10_0.giftSock_:scale(1.3)
			elseif arg_11_0.name == "moved" then
				if math.abs(arg_11_0.y - arg_10_0.prevY_) > 5 or math.abs(arg_11_0.x - arg_10_0.prevX_) > 5 then
					arg_10_0.startClick_ = false
				end
			elseif arg_11_0.name == "ended" then
				arg_10_0.giftSock_:scale(1)

				local var_11_0 = xyd.ServerTime.get():getServerTime()

				if var_11_0 > arg_10_0.endTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_END")
					})

					return true
				elseif var_11_0 < arg_10_0.startTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_NO_OPEN")
					})

					return true
				end

				if arg_10_0.startClick_ then
					local var_11_1 = var_0_1.new()

					var_11_1:populate({
						table_id = var_0_8
					})
					xyd.WindowManager.get():openWindow("show_item_info", {
						item = var_11_1
					})
				end
			end

			return true
		end)
	end

	return arg_10_0.giftSock_
end

function var_0_0.getGiftBall(arg_12_0)
	if not arg_12_0.giftBall_ then
		arg_12_0.giftBall_ = arg_12_0:nodeByName("gift_ball")

		arg_12_0:nodeByName("text_ball"):setString(var_0_4:name(var_0_7))
		arg_12_0.giftBall_:setTouchEnabled(true)
		arg_12_0.giftBall_:setTouchSwallowEnabled(false)
		arg_12_0.giftBall_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
			if arg_13_0.name == "began" then
				arg_12_0.prevX_ = arg_13_0.x
				arg_12_0.prevY_ = arg_13_0.y
				arg_12_0.startClick_ = true

				arg_12_0.giftBall_:scale(1.3)
			elseif arg_13_0.name == "moved" then
				if math.abs(arg_13_0.y - arg_12_0.prevY_) > 5 or math.abs(arg_13_0.x - arg_12_0.prevX_) > 5 then
					arg_12_0.startClick_ = false
				end
			elseif arg_13_0.name == "ended" then
				arg_12_0.giftBall_:scale(1)

				local var_13_0 = xyd.ServerTime.get():getServerTime()

				if var_13_0 > arg_12_0.endTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_END")
					})

					return true
				elseif var_13_0 < arg_12_0.startTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_NO_OPEN")
					})

					return true
				end

				if arg_12_0.startClick_ then
					local var_13_1 = var_0_1.new()

					var_13_1:populate({
						table_id = var_0_7
					})
					xyd.WindowManager.get():openWindow("show_item_info", {
						item = var_13_1
					})
				end
			end

			return true
		end)
	end

	return arg_12_0.giftBall_
end

function var_0_0.getGiftFlower(arg_14_0)
	if not arg_14_0.giftFlower_ then
		arg_14_0.giftFlower_ = arg_14_0:nodeByName("gift_flower")

		arg_14_0:nodeByName("text_flower"):setString(var_0_4:name(var_0_9))
		arg_14_0.giftFlower_:setTouchEnabled(true)
		arg_14_0.giftFlower_:setTouchSwallowEnabled(false)
		arg_14_0.giftFlower_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" then
				arg_14_0.prevX_ = arg_15_0.x
				arg_14_0.prevY_ = arg_15_0.y
				arg_14_0.startClick_ = true

				arg_14_0.giftFlower_:scale(1.3)
			elseif arg_15_0.name == "moved" then
				if math.abs(arg_15_0.y - arg_14_0.prevY_) > 5 or math.abs(arg_15_0.x - arg_14_0.prevX_) > 5 then
					arg_14_0.startClick_ = false
				end
			elseif arg_15_0.name == "ended" then
				arg_14_0.giftFlower_:scale(1)

				local var_15_0 = xyd.ServerTime.get():getServerTime()

				if var_15_0 > arg_14_0.endTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_END")
					})

					return true
				elseif var_15_0 < arg_14_0.startTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_NO_OPEN")
					})

					return true
				end

				if arg_14_0.startClick_ then
					local var_15_1 = var_0_1.new()

					var_15_1:populate({
						table_id = var_0_9
					})
					xyd.WindowManager.get():openWindow("show_item_info", {
						item = var_15_1
					})
				end
			end

			return true
		end)
	end

	return arg_14_0.giftFlower_
end

function var_0_0.getGiftStar(arg_16_0)
	if not arg_16_0.giftStar_ then
		arg_16_0.giftStar_ = arg_16_0:nodeByName("gift_star")

		arg_16_0.giftStar_:setTouchEnabled(true)
		arg_16_0.giftStar_:setTouchSwallowEnabled(false)
		arg_16_0.giftStar_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				arg_16_0.prevX_ = arg_17_0.x
				arg_16_0.prevY_ = arg_17_0.y
				arg_16_0.startClick_ = true

				arg_16_0.giftStar_:scale(1.3)
			elseif arg_17_0.name == "moved" then
				if math.abs(arg_17_0.y - arg_16_0.prevY_) > 5 or math.abs(arg_17_0.x - arg_16_0.prevX_) > 5 then
					arg_16_0.startClick_ = false
				end
			elseif arg_17_0.name == "ended" then
				arg_16_0.giftStar_:scale(1)

				local var_17_0 = xyd.ServerTime.get():getServerTime()

				if var_17_0 > arg_16_0.endTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_END")
					})

					return true
				elseif var_17_0 < arg_16_0.startTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_NO_OPEN")
					})

					return true
				end

				if arg_16_0.startClick_ then
					arg_16_0:getStarAward()
				end
			end

			return true
		end)
	end

	return arg_16_0.giftStar_
end

function var_0_0.getStarAward(arg_18_0)
	local var_18_0 = {
		var_0_7,
		var_0_9,
		var_0_6,
		var_0_8
	}
	local var_18_1 = true

	for iter_18_0 = 1, #var_18_0 do
		if arg_18_0.backpack_:getItemNumByID(var_18_0[iter_18_0]) < 1 then
			var_18_1 = false
		end
	end

	if not var_18_1 then
		local var_18_2 = string.format(var_0_5:translation("COLLECT_CHRISTMAS_GIFT"), var_0_4:name(var_0_7), var_0_4:name(var_0_9), var_0_4:name(var_0_6), var_0_4:name(var_0_8))

		xyd.WindowManager.get():openWindow("toast", {
			message = var_18_2
		})

		return
	end

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_5:translation("EXCHANGE_CHRISTMAS_STAR"), var_0_4:name(var_0_7), var_0_4:name(var_0_9), var_0_4:name(var_0_6), var_0_4:name(var_0_8)), function()
		arg_18_0.activitiesModel:getActivityReward(var_0_11, var_0_12, function(arg_20_0, arg_20_1)
			if arg_20_0 == xyd.error.OK then
				for iter_20_0, iter_20_1 in ipairs(var_18_0) do
					arg_18_0.backpack_:removeItem({
						itemNum = 1,
						itemID = iter_20_1
					})
				end

				if arg_20_1.awards and next(arg_20_1.awards) then
					for iter_20_2, iter_20_3 in ipairs(arg_20_1.awards) do
						if iter_20_3.table_id > 0 and iter_20_3.item_num > 0 then
							arg_18_0.backpack_:addItemsByID(iter_20_3.table_id, iter_20_3.item_num)
						end
					end

					xyd.WindowManager.get():openWindow("alert_award", {
						awards = arg_20_1.awards
					})
				end
			end
		end)
	end, nil, nil, arg_18_0.colorMode)
end

function var_0_0.getGiftHat(arg_21_0)
	if not arg_21_0.giftHat_ then
		arg_21_0.giftHat_ = arg_21_0:nodeByName("button_hat")

		arg_21_0.giftHat_:setTouchEnabled(true)
		arg_21_0.giftHat_:setTouchSwallowEnabled(false)
		arg_21_0.giftHat_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
			if arg_22_0.name == "began" then
				-- block empty
			elseif arg_22_0.name == "moved" then
				-- block empty
			elseif arg_22_0.name == "ended" then
				local var_22_0 = xyd.ServerTime.get():getServerTime()

				if var_22_0 > arg_21_0.endTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_END")
					})

					return true
				elseif var_22_0 < arg_21_0.startTime then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_5:translation("ACTIVITY_NO_OPEN")
					})

					return true
				end

				if not xyd.WindowManager.get():getWindow("exchange_item") then
					local var_22_1 = import("app.model.Item").new()

					var_22_1:populate({
						table_id = var_0_10
					})
					xyd.WindowManager.get():openWindow("exchange_item", {
						item = var_22_1
					})
				end
			end

			return true
		end)
	end

	return arg_21_0.giftHat_
end

function var_0_0.buttonHandler(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	if arg_23_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_23_2)
		arg_23_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_23_1 then
			arg_23_1(arg_23_2, arg_23_3)
		end
	elseif arg_23_3 == ccui.TouchEventType.began then
		local var_23_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.3),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_23_1 = cc.RepeatForever:create(var_23_0)

		arg_23_2:runAction(var_23_1)

		return true
	elseif arg_23_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_23_2)
		arg_23_2:setScale(1)
	end
end

function var_0_0.update(arg_24_0)
	local var_24_0 = {
		var_0_7,
		var_0_9,
		var_0_6,
		var_0_8
	}
	local var_24_1 = true

	for iter_24_0 = 1, #var_24_0 do
		if arg_24_0.backpack_:getItemNumByID(var_24_0[iter_24_0]) < 1 then
			var_24_1 = false
		end
	end

	if var_24_1 then
		arg_24_0.effects[1]:play(nil, true)
		arg_24_0.effects[1]:show()
		arg_24_0.effects[2]:show()
		arg_24_0.effects[2]:play(nil, true)
		arg_24_0:nodeByName("christmas_pic"):hide()
	else
		arg_24_0.effects[1]:stop()
		arg_24_0.effects[1]:hide()
		arg_24_0.effects[2]:stop()
		arg_24_0.effects[2]:hide()
		arg_24_0:nodeByName("christmas_pic"):show()
	end

	if arg_24_0.backpack_:getItemNumByID(var_0_10) > 0 then
		arg_24_0:getGiftHat():show()

		if not arg_24_0.action_ then
			local var_24_2 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))

			arg_24_0.action_ = cc.RepeatForever:create(var_24_2)

			arg_24_0:getGiftHat():runAction(arg_24_0.action_)
		end
	else
		arg_24_0:getGiftHat():hide()

		if arg_24_0.action_ then
			transition.removeAction(arg_24_0.action_)

			arg_24_0.action_ = nil
		end
	end
end

function var_0_0.setupEffect(arg_25_0)
	local var_25_0 = "skeletons/ui_effect/effect_christmas/"

	arg_25_0.effects = {}

	local var_25_1 = var_25_0 .. "effect_christmas2.json"
	local var_25_2 = var_25_0 .. "effect_christmas2.atlas"

	arg_25_0.effects[1] = var_0_2.new(var_25_1, var_25_2, 1)

	local var_25_3 = arg_25_0:nodeByName("christmas_small_back_type2"):getWidth() / 2
	local var_25_4 = arg_25_0:nodeByName("christmas_small_back_type2"):getHeight() / 2

	arg_25_0.effects[1]:align(display.CENTER, var_25_3, var_25_4):addTo(arg_25_0:nodeByName("christmas_small_back_type2"))

	local var_25_5, var_25_6 = var_25_0 .. "effect_christmas.json", var_25_0 .. "effect_christmas.atlas"

	arg_25_0.effects[2] = var_0_2.new(var_25_5, var_25_6, 1)

	arg_25_0.effects[2]:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_25_0:nodeByName("node_effect"))
end

function var_0_0.random(arg_26_0)
	arg_26_0.speakIndex = 0

	local var_26_0 = arg_26_0:nodeByName("christmas_pic")
	local var_26_1 = display.newNode()

	var_26_1:setContentSize(300, 300)
	var_26_1:align(display.CENTER, var_26_0:getWidth() / 2, var_26_0:getHeight() / 2)
	var_26_1:setTouchEnabled(true)
	var_26_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
		if arg_27_0.name == "began" then
			return true
		elseif arg_27_0.name == "ended" and not arg_26_0.playSound_ then
			local var_27_0 = xyd.tables.hero:clickDialog(var_0_13)
			local var_27_1 = xyd.tables.hero:dialogSounds(var_0_13)
			local var_27_2 = xyd.tables.hero:soundTimes(var_0_13)

			if var_27_0 ~= nil and #var_27_0 > 0 then
				if arg_26_0.speakIndex == 0 then
					arg_26_0.speakIndex = math.random(#var_27_0)
				else
					arg_26_0.speakIndex = xyd.randomIndex(arg_26_0.speakIndex, #var_27_0)
				end

				local var_27_3 = arg_26_0.speakIndex

				arg_26_0:npcSpeak(var_27_0[var_27_3], var_27_2[var_27_3])

				if var_27_1[var_27_3] ~= "" then
					if arg_26_0.npcSound_ then
						audio.stopSound(arg_26_0.npcSound_)
					end

					arg_26_0.npcSound_ = audio.playSound(var_27_1[var_27_3], false)
					arg_26_0.playSound_ = true

					arg_26_0:runAction(cc.Sequence:create({
						cc.DelayTime:create(var_27_2[var_27_3]),
						cc.CallFunc:create(function()
							if tolua.isnull(arg_26_0) then
								return
							end

							arg_26_0.playSound_ = false
						end)
					}))
				end
			end
		end
	end)
	var_26_0:addChild(var_26_1)
	arg_26_0:removeDelay()
end

function var_0_0.setMessageBoxVisible(arg_29_0, arg_29_1)
	if arg_29_1 then
		arg_29_0:nodeByName("message_node"):setVisible(true)
		arg_29_0:nodeByName("duihua_bg"):setVisible(true)
	else
		arg_29_0:nodeByName("message_node"):setVisible(false)
		arg_29_0:nodeByName("duihua_bg"):setVisible(false)
	end
end

function var_0_0.npcSpeak(arg_30_0, arg_30_1, arg_30_2)
	arg_30_0:nodeByName("message_node"):removeAllChildren()

	local var_30_0 = {
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_30_1 = xyd.AssetLoader.get():loadLabel(var_30_0)

	var_30_1:setMaxLineWidth(260)
	var_30_1:setString(arg_30_1)
	var_30_1:setAnchorPoint(cc.p(0, 1))
	var_30_1:addTo(arg_30_0:nodeByName("message_node"))

	local var_30_2 = var_30_1:getContentSize().height
	local var_30_3 = var_30_1:getContentSize().width

	arg_30_0:nodeByName("duihua_bg"):height(var_30_2 + 30)
	arg_30_0:nodeByName("duihua_bg"):width(var_30_3 + 55)
	arg_30_0:nodeByName("message_node"):height(var_30_2 + 55)

	local var_30_4, var_30_5 = arg_30_0:nodeByName("duihua_bg"):getPosition()

	var_30_1:setPositionY(25)
	arg_30_0:setMessageBoxVisible(true)

	arg_30_0.delay = var_0_3.performWithDelayGlobal(function()
		if arg_30_0 and arg_30_0.setMessageBoxVisible then
			arg_30_0:setMessageBoxVisible(false)
		end
	end, arg_30_2)
end

function var_0_0.removeDelay(arg_32_0)
	arg_32_0:setMessageBoxVisible(false)

	if arg_32_0.delay ~= nil then
		var_0_3.unscheduleGlobal(arg_32_0.delay)

		arg_32_0.delay = nil
	end
end

function var_0_0.didClose(arg_33_0)
	var_0_0.super.didClose()

	if arg_33_0.action_ then
		transition.removeAction(arg_33_0.action_)

		arg_33_0.action_ = nil
	end

	arg_33_0:removeDelay()
end

return var_0_0
