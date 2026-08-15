local var_0_0 = class("LoveLetterSummonWindow", import("app.windows.SummonResultWindow"))
local var_0_1 = xyd.WindowName.summonWnd
local var_0_2 = xyd.WindowName.summonResultWnd
local var_0_3 = xyd.tables.misc
local var_0_4 = xyd.tables.translation
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = import("app.model.Hero")
local var_0_7 = import("app.model.Pet")
local var_0_8 = import("framework.scheduler")
local var_0_9 = {
	crystal = 1,
	lover_letter = 2
}
local var_0_10 = 150

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.cost_type = arg_1_2.costType
	arg_1_0.useNum = arg_1_2.useNum
	arg_1_0.table_id = arg_1_2.table_id
	arg_1_0.keyID = var_0_3:getValue("activity_love_letter_id")
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.leave = arg_1_2.leave or false
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	local var_2_0
	local var_2_1 = "windows/activities/1183/loveletter"
	local var_2_2 = var_2_1 .. ".json"
	local var_2_3 = var_2_1 .. ".atlas"
	local var_2_4 = var_0_5.new(var_2_2, var_2_3, 1)

	var_2_4:addTo(arg_2_0, 1)
	var_2_4:pos(0, 0)

	local var_2_5 = display.newNode()

	var_2_5:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	var_2_5:setAnchorPoint(cc.p(0, 0))
	var_2_5:setPosition(cc.p(0, 0))
	var_2_5:setTouchEnabled(true)
	var_2_5:addTo(arg_2_0, 2)
	var_2_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
		if arg_3_0.name == "began" then
			return true
		elseif arg_3_0.name == "ended" then
			var_2_4:stop()
			var_2_4:setVisible(false)
			var_2_5:setVisible(false)
			arg_2_0.super.didOpen(arg_2_0, arg_2_1)
		end
	end)
	var_2_4:play(function()
		var_2_4:setVisible(false)
		var_2_4:stop()
		var_2_5:setVisible(false)
		arg_2_0.super.didOpen(arg_2_0, arg_2_1)
	end, false)
end

function var_0_0.layout(arg_5_0)
	arg_5_0.tmpNode = {}

	arg_5_0:getBackAnimation()
	arg_5_0:getAgainBtn()
	arg_5_0:getSkipBtn()
	arg_5_0:getCloseBtn()
	arg_5_0:setItems()
	arg_5_0:recordPosition()
	arg_5_0:setInitPosition()
	arg_5_0:getDesText():setVisible(false)

	local var_5_0, var_5_1, var_5_2, var_5_3 = arg_5_0:getPriceIcon()

	var_5_0:setVisible(false)
	var_5_1:setVisible(false)
	var_5_2:setVisible(false)
	var_5_3:setVisible(false)

	if arg_5_0.cost_type == 2 then
		local var_5_4 = xyd.AssetLoader.get():loadSprite("windows/activities/1183/icon_love_letter.png")
		local var_5_5, var_5_6 = var_5_3:getPosition()

		var_5_4:addTo(var_5_3:getParent())
		var_5_4:pos(var_5_5, var_5_6)
		var_5_4:setScale(0.6)
		var_5_4:setAnchorPoint(0.5, 0.5)

		local var_5_7 = arg_5_0.selfPlayer:getBackpack():getItemNumByID(arg_5_0.keyID) or 0

		arg_5_0:getPriceText():setString(var_5_7)
	else
		var_5_0:setVisible(true)

		local var_5_8

		if arg_5_0.useNum == 1 then
			var_5_8 = xyd.tables.misc:getValue("activity_love_letter_price")[1]
		else
			var_5_8 = xyd.tables.misc:getValue("activity_love_letter_price")[2]
		end

		arg_5_0:getPriceText():setString(var_5_8)
	end

	local var_5_9 = "windows/activities/1183/bg_chouka.png"
	local var_5_10 = display.newScale9Sprite(var_5_9, 0, 0, cc.size(1280, 424))

	var_5_10:addTo(arg_5_0:nodeByName("bg_pannel"))
	var_5_10:setAnchorPoint(0, 0)
	var_5_10:setPosition(0, 0)

	local var_5_11 = "windows/activities/1183/bg_background.png"
	local var_5_12 = display.newSprite(var_5_11, 0, 0)

	var_5_12:addTo(arg_5_0:nodeByName("bg_bottom"))
	var_5_12:setAnchorPoint(0, 0)
	var_5_12:setPosition(0, 0)
	var_5_12:setTouchEnabled(true)
	var_5_12:setTouchSwallowEnabled(false)
	arg_5_0:getBottomContainer():setVisible(false)
	arg_5_0:nodeByName("button_hundred"):setVisible(false)
	arg_5_0:nodeByName("price_hundred"):setVisible(false)
	arg_5_0:nodeByName("discount"):setVisible(false)
	arg_5_0:nodeByName("5"):setVisible(false)
	arg_5_0:nodeByName("3"):setVisible(false)
	arg_5_0:nodeByName("right_star"):setVisible(false)
	arg_5_0:nodeByName("left_star"):setVisible(false)
	arg_5_0:nodeByName("bg"):setVisible(false)
	arg_5_0:nodeByName("return"):getChildByName("txt"):setString(var_0_4:translation("SUMMON_EXIT"))

	if arg_5_0.leave == true then
		arg_5_0:nodeByName("price"):setVisible(false)
		arg_5_0:nodeByName("button_again"):setVisible(false)
		arg_5_0:nodeByName("button_hundred"):setVisible(false)
		arg_5_0:nodeByName("price_hundred"):setVisible(false)
		arg_5_0:nodeByName("return"):setVisible(true)
		arg_5_0:nodeByName("return"):setPosition(arg_5_0:nodeByName("button_again"):getPosition())
	end
end

function var_0_0.getBackAnimation(arg_6_0)
	return
end

function var_0_0.getAgainBtn(arg_7_0)
	if not arg_7_0.againBtn_ then
		arg_7_0.againBtn_ = arg_7_0:nodeByName("button_again")

		local var_7_0 = arg_7_0.useNum

		if var_7_0 == 1 then
			arg_7_0.againBtn_:getChildByName("txt"):setString(var_0_4:translation("LOVE_LETTER_SUMMON_BUY_AGAIN1"))
		else
			arg_7_0.againBtn_:getChildByName("txt"):setString(var_0_4:translation("LOVE_LETTER_SUMMON_BUY_AGAIN10"))
		end

		xyd.nodeEventSample(arg_7_0.againBtn_, nil, function(arg_8_0)
			xyd.playButtonSound()

			if not arg_7_0.isAnimated then
				local var_8_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

				if arg_7_0.cost_type == var_0_9.crystal then
					local var_8_1 = xyd.tables.misc:getValue("activity_love_letter_price")
					local var_8_2 = 0

					if var_7_0 == 1 then
						var_8_2 = var_8_1[1]
					else
						var_8_2 = var_8_1[2]
					end

					if var_8_2 > var_8_0.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
							local var_9_0 = {}

							var_9_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
							xyd.WindowManager.get():closeWindow(arg_7_0)
						end, nil, nil, arg_7_0.colorMode)
					else
						arg_7_0:summonAgain()
					end
				elseif arg_7_0.cost_type == var_0_9.lover_letter then
					if (arg_7_0.selfPlayer:getBackpack():getItemNumByID(arg_7_0.keyID) or 0) < var_7_0 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_4:translation("LOVA_LETTER_NOT_ENOUGH"), nil, nil, nil, arg_7_0.colorMode)
					else
						arg_7_0:summonAgain()
					end
				end
			end
		end)
	end

	return arg_7_0.againBtn_
end

function var_0_0.checkShowExtraReward(arg_10_0)
	return
end

function var_0_0.updateItemIcon(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	arg_11_0.super.updateItemIcon(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
end

function var_0_0.summonAgain(arg_12_0, arg_12_1)
	arg_12_0.isSkipAnimation = false

	local var_12_0 = {
		raffle_type = arg_12_0.cost_type,
		times = arg_12_0.useNum
	}

	xyd.Backend.get():request(xyd.mid.LOVE_LETTER_RAFFLE, var_12_0, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK and arg_13_1 and arg_13_1.awards and arg_13_1.award_times then
			arg_12_0.award_times = arg_13_1.award_times

			if var_12_0.raffle_type == 2 then
				local var_13_0 = arg_12_0.selfPlayer:getBackpack()
				local var_13_1 = {
					itemID = arg_12_0.keyID,
					itemNum = var_12_0.times
				}

				var_13_0:removeItem(var_13_1)

				local var_13_2 = var_13_0:getItemNumByID(arg_12_0.keyID) or 0

				arg_12_0:getPriceText():setString(var_13_2)
			end

			local var_13_3 = {}

			arg_12_0.selfPlayer:handleRewardsWithoutShow(arg_13_1.awards)

			for iter_13_0, iter_13_1 in pairs(arg_13_1.awards) do
				if tonumber(iter_13_0) then
					table.insert(var_13_3, iter_13_1)
				end
			end

			for iter_13_2, iter_13_3 in pairs(var_13_3) do
				arg_12_0.selfPlayer:heroUpdateEvent_({
					name = xyd.event.HERO_UPDATE,
					params = iter_13_3
				}, true)
			end

			arg_12_0:refresh(var_13_3, arg_13_1)
		end
	end)

	arg_12_0.isAnimated = true

	if arg_12_1 then
		arg_12_0.isAnimated = false
	end
end

function var_0_0.showAnimation(arg_14_0, arg_14_1, arg_14_2)
	arg_14_0.super.showAnimation(arg_14_0, arg_14_1, arg_14_2)
end

function var_0_0.summonHeroEvent(arg_15_0, arg_15_1)
	arg_15_0.super.summonHeroEvent(arg_15_0, arg_15_1)
end

function var_0_0.didClose(arg_16_0, arg_16_1)
	if arg_16_0.callback then
		arg_16_0.callback(arg_16_0.award_times)
	end
end

return var_0_0
