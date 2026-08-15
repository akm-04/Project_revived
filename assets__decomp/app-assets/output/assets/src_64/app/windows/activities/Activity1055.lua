local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = 0.5
local var_0_4 = 8
local var_0_5 = "skeletons/ui_effect/effect_scratch_card/scratch_light"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.scratchCard = xyd.ModelManager.get():loadModel(xyd.ModelType.SCRATCH_CARD)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.isInWashAction = false
	arg_1_0.autoSwitch = arg_1_0.details.auto_switch
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
		var_2_0:setPosition(2, 5)
		arg_2_0:setCardBtnTxtBasedOnCardState(arg_2_0.cardState)
		arg_2_0:setTouchBtn()
		arg_2_0.container:getChildByName("coin_num_own"):getChildByName("coin_num_txt"):setString(arg_2_0.player.luckyCoin)
		arg_2_0:showCard()
	end
end

function var_0_0.setTouchBtn(arg_3_0)
	local var_3_0 = arg_3_0.activity
	local var_3_1 = "open"
	local var_3_2 = xyd.ServerTime.get():getServerTime()

	if var_3_2 < var_3_0.start_time and var_3_0.is_open == 0 then
		var_3_1 = "not_open"
	elseif var_3_2 > var_3_0.end_time and var_3_0.is_open == 0 then
		var_3_1 = "expired"
	end

	arg_3_0.container:getChildByName("card_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			if var_3_1 == "not_open" then
				local var_4_0 = var_0_2:translation("ACTIVITY_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_4_0
				})

				return
			elseif var_3_1 == "expired" then
				local var_4_1 = var_0_2:translation("ACTIVITY_CLOSED")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_4_1
				})

				return
			end

			if arg_3_0.details.is_wash == 0 then
				arg_3_0.scratchCard:shuffleScratchCard({}, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						arg_3_0.details.is_wash = 1

						arg_3_0:showCard()
						arg_3_0:gatherAndThenDealAllCards()
						arg_3_0:setCardBtnTxtBasedOnCardState()
					end
				end)
			elseif arg_3_0.details.free_times > 0 then
				arg_3_0.scratchCard:changeCardsGroup({}, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						arg_3_0.details = arg_6_1

						arg_3_0:showCard()
						arg_3_0:setCardBtnTxtBasedOnCardState()
					end
				end)
			elseif arg_3_0.player.crystal < xyd.tables.misc.buyGroupCost then
				local var_4_2 = var_0_2:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_2, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			else
				local var_4_3 = string.format(var_0_2:translation("COST_TO_CHANGE_CARD_GROUP"), xyd.tables.misc.buyGroupCost)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_3, function()
					arg_3_0.scratchCard:changeCardsGroup({}, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							arg_3_0.details = arg_9_1

							arg_3_0:showCard()
							arg_3_0:setCardBtnTxtBasedOnCardState()
						end
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end
	end)
	arg_3_0.container:getChildByName("get_record_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			if var_3_1 == "not_open" then
				local var_10_0 = var_0_2:translation("ACTIVITY_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_10_0
				})

				return
			elseif var_3_1 == "expired" then
				local var_10_1 = var_0_2:translation("ACTIVITY_CLOSED")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_10_1
				})

				return
			end

			local var_10_2 = {
				rand_card_group = arg_3_0.details.rand_card_group,
				scratch_status = arg_3_0.details.scratch_status,
				card_group = arg_3_0.details.card_group
			}

			var_10_2.isShareJoy = true

			xyd.WindowManager.get():openWindow("scratch_card_record", var_10_2)
		end
	end)
	arg_3_0.container:getChildByName("buy_coin_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			if var_3_1 == "not_open" then
				local var_11_0 = var_0_2:translation("ACTIVITY_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})

				return
			elseif var_3_1 == "expired" then
				local var_11_1 = var_0_2:translation("ACTIVITY_CLOSED")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_1
				})

				return
			end

			local var_11_2 = {
				details = arg_3_0.details,
				coin_num_txt = arg_3_0.container:getChildByName("coin_num_own"):getChildByName("coin_num_txt")
			}

			xyd.WindowManager.get():openWindow("buy_coin", var_11_2)
		end
	end)
	arg_3_0.container:getChildByName("img_rule"):setTouchEnabled(true)
	arg_3_0.container:getChildByName("img_rule"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			arg_3_0.container:getChildByName("img_rule"):setScale(0.9)

			return true
		elseif arg_12_0.name == "ended" then
			arg_3_0.container:getChildByName("img_rule"):setScale(1)
			xyd.WindowManager.get():openWindow("scratch_card_rule")
		end
	end)
	arg_3_0.container:getChildByName("btn_auto"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			arg_3_0.scratchCard:changeAutoStatus(function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					arg_3_0.autoSwitch = arg_14_1.auto_switch

					if arg_3_0.autoSwitch == 1 then
						arg_3_0.container:getChildByName("btn_auto"):getChildByName("off_txt"):setVisible(false)
						arg_3_0.container:getChildByName("btn_auto"):getChildByName("on_txt"):setVisible(true)
					else
						arg_3_0.container:getChildByName("btn_auto"):getChildByName("off_txt"):setVisible(true)
						arg_3_0.container:getChildByName("btn_auto"):getChildByName("on_txt"):setVisible(false)
					end
				end
			end)
		end
	end)

	if arg_3_0.autoSwitch == 1 then
		arg_3_0.container:getChildByName("btn_auto"):getChildByName("off_txt"):setVisible(false)
		arg_3_0.container:getChildByName("btn_auto"):getChildByName("on_txt"):setVisible(true)
	else
		arg_3_0.container:getChildByName("btn_auto"):getChildByName("off_txt"):setVisible(true)
		arg_3_0.container:getChildByName("btn_auto"):getChildByName("on_txt"):setVisible(false)
	end
end

function var_0_0.setCardBtnTxtBasedOnCardState(arg_15_0)
	local var_15_0 = arg_15_0.container:getChildByName("card_btn")

	var_15_0:getChildByName("click_shuffle_txt"):setVisible(false)
	var_15_0:getChildByName("free_change_txt"):setVisible(false)
	var_15_0:getChildByName("change_card_txt"):setVisible(false)

	if arg_15_0.details.is_wash == 0 then
		var_15_0:getChildByName("click_shuffle_txt"):setVisible(true)
	elseif arg_15_0.details.free_times > 0 then
		var_15_0:getChildByName("free_change_txt"):setVisible(true)
	else
		var_15_0:getChildByName("change_card_txt"):setVisible(true)
	end
end

function var_0_0.gatherAndThenDealAllCards(arg_16_0)
	arg_16_0.isInWashAction = true

	for iter_16_0 = 1, var_0_4 do
		local var_16_0 = cc.MoveTo:create(var_0_3, cc.p(arg_16_0.card_container:getChildByName("gather_pos"):getPosition()))

		if iter_16_0 <= 4 then
			moveX = 40 + 140 * (iter_16_0 - 1)
			moveY = 168
		else
			moveX = 40 + 140 * (iter_16_0 - 5)
			moveY = 34
		end

		local var_16_1 = cc.MoveTo:create(var_0_3, cc.p(moveX, moveY))
		local var_16_2 = cc.CallFunc:create(function()
			if arg_16_0 then
				arg_16_0.isInWashAction = false
			end
		end)

		arg_16_0.card_container:getChildByName("card_" .. iter_16_0):runAction(cc.Sequence:create(var_16_0, cc.DelayTime:create(0.5), var_16_1, var_16_2))
	end
end

function var_0_0.showCard(arg_18_0)
	if arg_18_0 and not tolua.isnull(arg_18_0.card_container) then
		arg_18_0:creatPosToCardIDTable()
		arg_18_0:creatPosToScratchStausTable()

		if arg_18_0.details.is_wash == 0 then
			arg_18_0:showAllCardsInObverseSide()
		else
			arg_18_0:showAllCardsBasedOnIsScratched()
		end
	end
end

function var_0_0.showAllCardsBasedOnIsScratched(arg_19_0)
	local var_19_0 = arg_19_0.details.card_group

	if var_19_0 and next(var_19_0) then
		for iter_19_0 = 1, #var_19_0 do
			local var_19_1 = arg_19_0.card_container:getChildByName("card_" .. iter_19_0)

			if arg_19_0.cardPosToCardID[iter_19_0] then
				local var_19_2 = arg_19_0.cardPosToCardID[iter_19_0]

				arg_19_0:setCardInObverseSideAndAddTips(var_19_1, var_19_2)
			else
				arg_19_0:setCardInReverseSide(var_19_1, iter_19_0)
			end
		end
	end
end

function var_0_0.showAllCardsInObverseSide(arg_20_0)
	local var_20_0 = arg_20_0.details.rand_card_group

	if var_20_0 and next(var_20_0) then
		for iter_20_0 = 1, #var_20_0 do
			local var_20_1 = var_20_0[iter_20_0]
			local var_20_2 = arg_20_0.card_container:getChildByName("card_" .. iter_20_0)

			arg_20_0:setCardInObverseSideAndAddTips(var_20_2, var_20_1)
		end
	end
end

function var_0_0.setCardInObverseSideAndAddTips(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = display.newNode()

	var_21_0:setContentSize(arg_21_1:getHeight(), arg_21_1:getHeight())

	local var_21_1 = xyd.tables.activityScratchCard:getGiftID(arg_21_2)

	if xyd.tables.activityScratchCard:isMultiplierCard(arg_21_2) then
		local var_21_2 = xyd.tables.activityScratchCard:getIcon(arg_21_2)

		xyd.setSpriteBorder(var_21_0, var_21_2, 1)

		local var_21_3 = {}

		var_21_3.id = -11
		var_21_3.tipsType = 1

		arg_21_0:addTips(var_21_0, var_21_3)
	elseif xyd.tables.gift:crystal(var_21_1) and xyd.tables.gift:crystal(var_21_1) > 0 then
		xyd.setItemBorder(var_21_0, -1, false, false, xyd.tables.gift:crystal(var_21_1))

		local var_21_4 = {}

		var_21_4.id = -1
		var_21_4.tipsType = 1

		arg_21_0:addTips(var_21_0, var_21_4)
	elseif xyd.tables.gift:mana(var_21_1) and xyd.tables.gift:mana(var_21_1) > 0 then
		xyd.setItemBorder(var_21_0, -2, false, false, xyd.tables.gift:mana(var_21_1))

		local var_21_5 = {}

		var_21_5.id = -2
		var_21_5.tipsType = 1

		arg_21_0:addTips(var_21_0, var_21_5)
	elseif xyd.tables.gift:luckyCoin(var_21_1) and xyd.tables.gift:luckyCoin(var_21_1) > 0 then
		xyd.setItemBorder(var_21_0, -5, false, false, xyd.tables.gift:luckyCoin(var_21_1))

		local var_21_6 = {}

		var_21_6.id = -10
		var_21_6.tipsType = 1

		arg_21_0:addTips(var_21_0, var_21_6)
	else
		local var_21_7 = xyd.tables.gift:items(var_21_1)[1]
		local var_21_8 = xyd.tables.gift:itemNum(var_21_1)[1]

		xyd.setItemBorder(var_21_0, var_21_7, false, false, var_21_8)

		local var_21_9 = {
			id = var_21_7,
			lev = xyd.tables.item:level(var_21_7)
		}

		if xyd.tables.item:type(var_21_7) == -1 then
			var_21_9.tipsType = 0
			var_21_9.desc1 = xyd.tables.hero:getDes(var_21_7)
		elseif specialItem then
			var_21_9.tipsType = 1
			var_21_9.id = -3
		else
			var_21_9.tipsType = 1
			var_21_9.desc1 = xyd.tables.item:desc1(var_21_7)
			var_21_9.desc2 = xyd.tables.item:desc2(var_21_7)
		end

		var_21_9.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_21_7)
		var_21_9.name = xyd.tables.item:name(var_21_7)

		arg_21_0:addTips(var_21_0, var_21_9)
	end

	arg_21_1:removeAllChildren()
	var_21_0:addTo(arg_21_1)
	var_21_0:setPosition(0, 0)
	var_21_0:setAnchorPoint(cc.p(0, 0))

	if xyd.tables.activityScratchCard:isMultiplierCard(arg_21_2) and arg_21_0.details.is_wash == 0 then
		arg_21_0:playScratchEffect(arg_21_1)
	end
end

function var_0_0.setCardInReverseSide(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = display.newNode()

	var_22_0:setContentSize(arg_22_1:getHeight(), arg_22_1:getHeight())

	iconPath = "windows/activities/1055/card_back_side.png"

	xyd.setSpriteBorder(var_22_0, iconPath, 1)
	arg_22_1:removeAllChildren()
	var_22_0:addTo(arg_22_1)
	var_22_0:setPosition(0, 0)
	var_22_0:setAnchorPoint(cc.p(0, 0))
	var_22_0:setTouchEnabled(true)
	var_22_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "began" then
			return true
		elseif arg_23_0.name == "ended" then
			if arg_22_0.isInWashAction then
				return
			end

			local var_23_0 = xyd.tables.misc.scratchCardCost[arg_22_0.details.scratch_times + 1]
			local var_23_1 = string.format(var_0_2:translation("SCRATCH_CARD_COST"), var_23_0)

			if var_23_0 == 0 then
				var_23_1 = var_0_2:translation("FREE_TO_SCRATCH")
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_23_1, function()
				if arg_22_0.player.luckyCoin >= var_23_0 then
					arg_22_0:scratchCurrentCard(arg_22_1, arg_22_2)
				else
					local var_24_0 = var_0_2:translation("LUCKY_COIN_NOT_ENOUGH")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_24_0
					})
				end
			end, nil, nil, xyd.ColorMode.ACTIVITY)
		end
	end)
end

function var_0_0.scratchCurrentCard(arg_25_0, arg_25_1, arg_25_2)
	arg_25_0.activitiesModel:getActivityReward(arg_25_0.activity.table_id, arg_25_2, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			local function var_26_0()
				arg_25_0:showCard()
			end

			arg_25_0.container:getChildByName("coin_num_own"):getChildByName("coin_num_txt"):setString(arg_25_0.player.luckyCoin)

			arg_25_0.details.scratch_status = arg_26_1.scratch_status
			arg_25_0.details.card_pos = arg_26_1.card_pos
			arg_25_0.details.scratch_times = arg_26_1.scratch_times

			arg_25_0:creatPosToCardIDTable()
			arg_25_0:creatPosToScratchStausTable()

			local var_26_1 = {
				more_num_old = arg_25_0.details.more_num,
				more_num_new = arg_26_1.more_num,
				awards = arg_26_1.awards,
				card_id = arg_25_0.cardPosToCardID[arg_25_2],
				callback = var_26_0
			}

			if arg_25_0.autoSwitch == 1 then
				arg_25_0:showAward(var_26_1)
			else
				xyd.WindowManager.get():openWindow("scratch_card_wnd", var_26_1)
			end

			arg_25_0.details.more_num = arg_26_1.more_num
		end
	end)
end

function var_0_0.showAward(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_1.card_id
	local var_28_1 = arg_28_1.awards
	local var_28_2 = arg_28_1.callback

	if xyd.tables.activityScratchCard:isMultiplierCard(var_28_0) then
		local var_28_3 = xyd.tables.activityScratchCard:getMultiplier(var_28_0)
		local var_28_4 = {
			message = string.format(var_0_2:translation("MORE_CARD_TIPS"), var_28_3)
		}

		var_28_4.delay = 0.95
		var_28_4.textSize = 24

		xyd.WindowManager.get():openWindow("toast", var_28_4)

		if var_28_2 then
			var_28_2()
		end
	else
		arg_28_0.player:handleRewards(var_28_1, var_28_2)
	end
end

function var_0_0.creatPosToCardIDTable(arg_29_0)
	local var_29_0 = arg_29_0.details.card_pos
	local var_29_1 = arg_29_0.details.card_group

	arg_29_0.cardPosToCardID = {}

	if var_29_0 and next(var_29_0) then
		for iter_29_0 = 1, #var_29_0 do
			if var_29_0[iter_29_0] ~= 0 then
				arg_29_0.cardPosToCardID[var_29_0[iter_29_0]] = var_29_1[iter_29_0]
			end
		end
	end
end

function var_0_0.creatPosToScratchStausTable(arg_30_0)
	local var_30_0 = arg_30_0.details.scratch_status
	local var_30_1 = arg_30_0.details.card_group

	arg_30_0.cardPosToScratchStatus = {}

	if var_30_0 and next(var_30_0) then
		for iter_30_0 = 1, #var_30_0 do
			if var_30_0[iter_30_0] ~= 0 then
				arg_30_0.cardPosToScratchStatus[var_30_0[iter_30_0]] = var_30_1[iter_30_0]
			end
		end
	end
end

function var_0_0.playScratchEffect(arg_31_0, arg_31_1)
	local var_31_0 = var_0_5 .. ".json"
	local var_31_1 = var_0_5 .. ".atlas"

	arg_31_0.ScratchEffect = var_0_1.new(var_31_0, var_31_1, 1)

	arg_31_0.ScratchEffect:addTo(arg_31_1)
	arg_31_0.ScratchEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_31_0.ScratchEffect:setPosition(cc.p(49, 52))
	arg_31_0.ScratchEffect:play(nil, true)
end

return var_0_0
