local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.misc.activityCardMatchCost
local var_0_5 = xyd.tables.activityCardMatch
local var_0_6 = 0.5
local var_0_7 = 18
local var_0_8 = 6
local var_0_9 = 3

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.isPlayOpenAction = arg_1_0.activitiesModel:isHasNewRedpoint(arg_1_0.activity.table_id)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")
		arg_2_0.card_container = arg_2_0.container:getChildByName("card_container")

		var_2_0:addTo(arg_2_0.parent)
		arg_2_0.container:getChildByName("start_btn"):getChildByName("start_text"):setString(var_0_2:translation("ACTIVITY_1161_TEXT_1"))
		arg_2_0.container:getChildByName("exchange_btn"):getChildByName("exchange_text"):setString(var_0_2:translation("ACTIVITY_1161_TEXT_2"))
		arg_2_0.container:getChildByName("memory_btn"):getChildByName("memory_text"):setString(var_0_2:translation("ACTIVITY_1161_TEXT_3"))

		if arg_2_0.handle1 then
			var_0_3.unscheduleGlobal(arg_2_0.handle1)
		end

		if arg_2_0.handle2 then
			var_0_3.unscheduleGlobal(arg_2_0.handle2)
		end

		if arg_2_0.isInWashAction then
			arg_2_0.isInWashAction = false
		end

		arg_2_0:setTouchBtn()
		arg_2_0:initCard()
		arg_2_0:updateTexts()
	end
end

function var_0_0.initCard(arg_3_0)
	arg_3_0.cardItems = {}

	arg_3_0.card_container:removeAllChildren(true)

	for iter_3_0 = 1, var_0_9 do
		for iter_3_1 = 1, var_0_8 do
			local var_3_0 = (iter_3_0 - 1) * var_0_8 + iter_3_1
			local var_3_1 = arg_3_0:getCardItem(var_3_0)

			arg_3_0.cardItems[var_3_0] = var_3_1

			var_3_1:addTo(arg_3_0.card_container)
			var_3_1:setPosition(cc.p((iter_3_1 - 1) * 110 + 10, (iter_3_0 - 1) * 135 + 5))
		end
	end

	if arg_3_0.isPlayOpenAction then
		arg_3_0.isPlayOpenAction = false

		arg_3_0:playWashAction()
		arg_3_0.activitiesModel:clearRedMarkState(arg_3_0.activity.table_id, 1)
	else
		arg_3_0:showCardAccordingFlip()
	end
end

function var_0_0.showCardAccordingFlip(arg_4_0)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.cardItems) do
		local var_4_0 = arg_4_0.details.record[iter_4_0]

		if var_4_0 > 0 then
			arg_4_0:initItemByCardID(iter_4_1, var_4_0)
			arg_4_0:showCardIsOberserve(iter_4_1, true)
		else
			arg_4_0:showCardIsOberserve(iter_4_1, false)
		end
	end
end

function var_0_0.getFlipNums(arg_5_0)
	local var_5_0 = arg_5_0.details.record
	local var_5_1 = 0

	for iter_5_0 = 1, #var_5_0 do
		if var_5_0[iter_5_0] > 0 then
			var_5_1 = var_5_1 + 1
		end
	end

	return var_5_1
end

function var_0_0.updateTexts(arg_6_0)
	local var_6_0 = arg_6_0:getFlipNums()
	local var_6_1 = xyd.tables.misc.activityCardMatchCost[var_6_0 + 1] or 0

	arg_6_0.container:getChildByName("cost_num_txt"):setString(var_6_1)
	arg_6_0.container:getChildByName("special_num_txt"):setString(arg_6_0.details.scores)
end

function var_0_0.playRoateAction(arg_7_0)
	for iter_7_0, iter_7_1 in pairs(arg_7_0.cardItems) do
		arg_7_0:cardRolling(iter_7_1, 0.25)
	end
end

function var_0_0.cardRolling(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_1:getChildByName("source"):getChildByName("container")

	local function var_8_1()
		arg_8_0.canSwitchCard = true
	end

	local function var_8_2()
		arg_8_0:showCardIsOberserve(arg_8_1, not arg_8_1.isObserveSide)
	end

	local var_8_3 = cc.OrbitCamera:create(arg_8_2, 1, 0, 0, 90, 0, 0)
	local var_8_4 = cc.OrbitCamera:create(arg_8_2, 1, 0, 270, 90, 0, 0)
	local var_8_5 = cc.CallFunc:create(var_8_2)
	local var_8_6 = cc.CallFunc:create(var_8_1)
	local var_8_7 = cc.Sequence:create(var_8_3, var_8_5, var_8_4, var_8_6)

	var_8_0:runAction(var_8_7)
end

function var_0_0.showCardIsOberserve(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1:getChildByName("source"):getChildByName("container")
	local var_11_1 = var_11_0:getChildByName("bg1")
	local var_11_2 = var_11_0:getChildByName("bg2")

	var_11_1:setVisible(not arg_11_2)
	var_11_2:setVisible(arg_11_2)

	arg_11_1.isObserveSide = arg_11_2
end

function var_0_0.getCardItem(arg_12_0, arg_12_1)
	local var_12_0 = display.newNode()
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1161/card_item.csb")
	local var_12_2 = var_12_1:getChildByName("container")

	var_12_1:addTo(var_12_0)
	var_12_1:setAnchorPoint(cc.p(0, 0))
	var_12_1:setTouchEnabled(true)
	var_12_1:setTouchSwallowEnabled(true)
	var_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "moved" then
			return true
		elseif arg_13_0.name == "ended" then
			if arg_12_0.isInWashAction then
				return
			end

			if arg_12_0.details.record[arg_12_1] > 0 then
				return
			end

			local var_13_0 = arg_12_0:getFlipNums()
			local var_13_1 = xyd.tables.misc.activityCardMatchCost[var_13_0 + 1] or 0

			if var_13_1 > arg_12_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
					local var_14_0 = {}

					var_14_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_14_0)
				end, nil, nil, xyd.ColorMode.ACTIVITY)

				return
			end

			if var_13_1 > 0 then
				local var_13_2 = string.format(var_0_2:translation("ACTIVITY_CARD_MATCH_TEXT6"), var_13_1)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_2, function()
					arg_12_0:filpCard(var_12_0, arg_12_1)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			else
				arg_12_0:filpCard(var_12_0, arg_12_1)
			end
		end
	end)
	var_12_0:setContentSize(var_12_2:getContentSize())
	var_12_1:setName("source")

	return var_12_0
end

function var_0_0.filpCard(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = {
		pos = arg_16_2
	}

	xyd.Backend.get():request(xyd.mid.CARD_MATCH_FLIP, var_16_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			local function var_17_0()
				if arg_17_1.awards then
					arg_16_0.selfPlayer:handleRewards(arg_17_1.awards)
				end
			end

			if arg_17_1.get_card and xyd.isInTable(arg_16_0.details.record, arg_17_1.get_card) then
				local var_17_1 = {
					card_id = arg_17_1.get_card,
					callback = var_17_0
				}

				xyd.WindowManager.get():openWindow("card_match_result", var_17_1)
			end

			if arg_17_1.base_info then
				arg_16_0.details = arg_17_1.base_info
			end

			arg_16_0:initItemByCardID(arg_16_1, arg_17_1.get_card)
			arg_16_0:cardRolling(arg_16_1, 0.25)
			arg_16_0:updateTexts()
		end
	end, nil, false, false)
end

function var_0_0.setTouchBtn(arg_19_0)
	local var_19_0 = arg_19_0.activity
	local var_19_1 = "open"
	local var_19_2 = xyd.ServerTime.get():getServerTime()

	if var_19_2 < var_19_0.start_time then
		var_19_1 = "not_open"
	elseif var_19_2 > var_19_0.end_time then
		var_19_1 = "expired"
	end

	arg_19_0.container:getChildByName("start_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_20_0, arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			if var_19_1 == "not_open" then
				local var_20_0 = var_0_2:translation("ACTIVITY_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_20_0
				})

				return
			elseif var_19_1 == "expired" then
				local var_20_1 = var_0_2:translation("ACTIVITY_CLOSED")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_20_1
				})

				return
			end

			if arg_19_0.isInWashAction then
				return
			end

			if arg_19_0:getFlipNums() <= 0 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ACTIVITY_CARD_MATCH_TEXT5"), function()
					arg_19_0:newMatchTurn()
				end, nil, nil, xyd.ColorMode.ACTIVITY)

				return
			elseif arg_19_0.selfPlayer.crystal < xyd.tables.misc.activitCardMatchResetCost then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
					local var_22_0 = {}

					var_22_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_22_0)
				end, nil, nil, xyd.ColorMode.ACTIVITY)

				return
			else
				local var_20_2 = string.format(var_0_2:translation("ACTIVITY_CARD_MATCH_TEXT3"), xyd.tables.misc.activitCardMatchResetCost)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_20_2, function()
					arg_19_0:newMatchTurn()
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end
	end)
	arg_19_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_24_0, arg_24_1)
		xyd.buttonScaleAnim(arg_24_0, arg_24_1)

		if arg_24_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_24_0 = {
				title_name = "BEACH_CARD_MATCH_RULE_TITLE",
				rule = "BEACH_CARD_MATCH_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_24_0)
		end
	end)
	arg_19_0.container:getChildByName("exchange_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
		xyd.buttonScaleAnim(arg_25_0, arg_25_1)

		if arg_25_1 == ccui.TouchEventType.ended then
			if var_19_1 == "not_open" then
				local var_25_0 = var_0_2:translation("ACTIVITY_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_25_0
				})

				return
			elseif var_19_1 == "expired" then
				local var_25_1 = var_0_2:translation("ACTIVITY_CLOSED")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_25_1
				})

				return
			end

			local function var_25_2()
				arg_19_0:updateTexts()
			end

			local var_25_3 = {
				details = arg_19_0.details,
				callback = var_25_2
			}

			xyd.WindowManager.get():openWindow("card_match_shop", var_25_3)
		end
	end)
	arg_19_0.container:getChildByName("memory_btn"):addTouchEventListener(function(arg_27_0, arg_27_1)
		xyd.buttonScaleAnim(arg_27_0, arg_27_1)

		if arg_27_1 == ccui.TouchEventType.ended then
			if var_19_1 == "not_open" then
				local var_27_0 = var_0_2:translation("ACTIVITY_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_27_0
				})

				return
			elseif var_19_1 == "expired" then
				local var_27_1 = var_0_2:translation("ACTIVITY_CLOSED")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_27_1
				})

				return
			end

			local var_27_2 = {
				details = arg_19_0.details
			}

			xyd.WindowManager.get():openWindow("card_match_memory", var_27_2)
		end
	end)
end

function var_0_0.newMatchTurn(arg_28_0)
	local var_28_0 = {}

	xyd.Backend.get():request(xyd.mid.CARD_MATCH_NEW_TURN, var_28_0, function(arg_29_0, arg_29_1)
		if arg_29_0 == xyd.error.OK then
			if arg_29_1.cards then
				arg_28_0.details.cards = arg_29_1.cards
			end

			if arg_29_1.nums then
				arg_28_0.details.nums = arg_29_1.nums
			end

			if arg_29_1.record then
				arg_28_0.details.record = arg_29_1.record
			end

			arg_28_0:playWashAction()
			arg_28_0:updateTexts()
		end
	end, nil, false, false)
end

function var_0_0.playWashAction(arg_30_0)
	arg_30_0.isInWashAction = true

	arg_30_0:showAllCardsInObverseSide()

	arg_30_0.handle1 = var_0_3.performWithDelayGlobal(function()
		if arg_30_0 and arg_30_0.cardItems[1] and not tolua.isnull(arg_30_0.cardItems[1]) then
			arg_30_0:playRoateAction()
		end
	end, 2)
	arg_30_0.handle2 = var_0_3.performWithDelayGlobal(function()
		if arg_30_0 and arg_30_0.cardItems[1] and not tolua.isnull(arg_30_0.cardItems[1]) then
			arg_30_0:gatherAndThenDealAllCards()
		end
	end, 2.6)
end

function var_0_0.gatherAndThenDealAllCards(arg_33_0)
	for iter_33_0 = 1, var_0_7 do
		local var_33_0 = arg_33_0.cardItems[iter_33_0]
		local var_33_1 = cc.p(var_33_0:getPosition())
		local var_33_2 = cc.MoveTo:create(var_0_6, cc.p(284, 139))
		local var_33_3 = cc.MoveTo:create(var_0_6, var_33_1)
		local var_33_4 = cc.CallFunc:create(function()
			if arg_33_0 then
				arg_33_0.isInWashAction = false
			end
		end)

		var_33_0:runAction(cc.Sequence:create(var_33_2, cc.DelayTime:create(0.5), var_33_3, var_33_4))
	end
end

function var_0_0.showAllCardsInObverseSide(arg_35_0, arg_35_1)
	for iter_35_0, iter_35_1 in pairs(arg_35_0.cardItems) do
		local var_35_0 = arg_35_0.details.cards[math.ceil(iter_35_0 / 2)]

		arg_35_0:initItemByCardID(iter_35_1, var_35_0)
		arg_35_0:showCardIsOberserve(iter_35_1, true)
	end
end

function var_0_0.initItemByCardID(arg_36_0, arg_36_1, arg_36_2)
	if not arg_36_1 or tolua.isnull(arg_36_1) then
		return
	end

	local var_36_0 = arg_36_1:getChildByName("source"):getChildByName("container"):getChildByName("bg2"):getChildByName("icon_container")

	var_36_0:removeAllChildren(true)

	local var_36_1 = var_0_5:itemId(arg_36_2)
	local var_36_2 = var_0_5:itemNum(arg_36_2)

	if var_36_1 > 0 then
		xyd.setItemAndAddTips(var_36_0, var_36_1, var_36_2)
	else
		local var_36_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1161/main/special_item.png")

		xyd.displaySpriteOnContainer(var_36_3, var_36_0)
	end
end

return var_0_0
