local var_0_0 = class("FourthAnniUfocatcherWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require(cc.PACKAGE_NAME .. ".scheduler")
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = import("app.common.ui.EcoDisplaySidebar")
local var_0_4 = xyd.tables.fourthAnniUfocatcherTable
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.item
local var_0_7 = xyd.tables.gift
local var_0_8 = xyd.tables.misc
local var_0_9 = xyd.tables.refreshCost
local var_0_10 = var_0_8:getValue("activity_ufocatcher_ticket")
local var_0_11 = var_0_8:getValue("activity_ufocatcher_coin")
local var_0_12 = {
	auto = 2,
	hand = 1
}
local var_0_13 = {
	rest = 1,
	work = 2
}
local var_0_14 = {
	cc.p(0.5, 0.5),
	cc.p(0.6, 0.5),
	cc.p(0.4, 0.32),
	cc.p(0.45, 0.4),
	cc.p(0.5, 0.5),
	cc.p(0.5, 0.55),
	cc.p(0.5, 0.45),
	cc.p(0.5, 0.5),
	cc.p(0.4, 0.45),
	cc.p(0.6, 0.45),
	cc.p(0.45, 0.55),
	cc.p(0.5, 0.5)
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)
	arg_1_0.speed = var_0_8:getValue("activity_ufocatcher_speed")
	arg_1_0.refreshTimes = arg_1_2.refresh_times
	arg_1_0.isGame = arg_1_2.is_catching
	arg_1_0.gameEndTime = arg_1_2.end_time
	arg_1_0.awardTimes_ = arg_1_2.award_times or 0
	arg_1_0.dolls_ = arg_1_2.pos_info
	arg_1_0.condition_ = var_0_13.rest
	arg_1_0.barrageInfos = {}
	arg_1_0.bottomTimes = var_0_8:getValue("activity_ufocatcher_bottom_times")
	arg_1_0.gameHandler = nil
	arg_1_0.showBarrageHandler = nil
	arg_1_0.loadBarrageHandler = nil
	arg_1_0.gameStartTime = 0
	arg_1_0.gameEndTime = 0
	arg_1_0.catcherIndex = 4
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()

	if arg_2_0.isGame == 1 and xyd.ServerTime.get():getServerTime() < arg_2_0.gameEndTime then
		arg_2_0:startGame()
	end
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_gift"):enableOutline(cc.c4b(30, 16, 38, 255), 2)
	arg_3_0:nodeByName("txt_coin_num"):enableOutline(cc.c4b(15, 32, 75, 255), 2)
	arg_3_0:nodeByName("txt_left_no_chose"):enableOutline(cc.c4b(53, 64, 139, 255), 2)
	arg_3_0:nodeByName("txt_left_chose"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_3_0:nodeByName("txt_right_no_chose"):enableOutline(cc.c4b(53, 64, 139, 255), 2)
	arg_3_0:nodeByName("txt_right_chose"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_3_0:nodeByName("txt_btn_one"):enableOutline(cc.c4b(228, 248, 249, 255), 2)
	arg_3_0:nodeByName("txt_btn_ten"):enableOutline(cc.c4b(255, 247, 230, 255), 2)
	arg_3_0:nodeByName("barrage"):setVisible(false)
	arg_3_0:nodeByName("txt_btn_reset"):setString(var_0_5:translation("SHOP_TIPS_REFRESH"))
	arg_3_0:nodeByName("txt_btn_one"):setString(var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP7"))
	arg_3_0:nodeByName("txt_btn_ten"):setString(var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP8"))

	arg_3_0.chargeCoin = arg_3_0:nodeByName("charge_coin")
	arg_3_0.goldCoin = arg_3_0:nodeByName("gold_coin")
	arg_3_0.btnOne = arg_3_0:nodeByName("btn_one")
	arg_3_0.btnTen = arg_3_0:nodeByName("btn_ten")
	arg_3_0.btnHandOff = arg_3_0:nodeByName("btn_left_no_chose")
	arg_3_0.btnHandOn = arg_3_0:nodeByName("btn_left_chose")
	arg_3_0.btnAutoOff = arg_3_0:nodeByName("btn_right_no_chose")
	arg_3_0.btnAutoOn = arg_3_0:nodeByName("btn_right_chose")
	arg_3_0.rocker = arg_3_0:nodeByName("rocker")

	arg_3_0.btnHandOff:setTouchEnabled(true)
	arg_3_0.btnHandOff:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			arg_3_0:setMode(var_0_12.hand)
		end
	end)
	arg_3_0.btnAutoOff:setTouchEnabled(true)
	arg_3_0.btnAutoOff:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_3_0:setMode(var_0_12.auto)
		end
	end)
	arg_3_0:nodeByName("btn_reset"):setTouchEnabled(true)
	arg_3_0:nodeByName("btn_reset"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			if arg_3_0.condition_ == var_0_13.work then
				return
			end

			local var_6_0

			if arg_3_0.refreshTimes + 1 <= 330 then
				var_6_0 = var_0_9:ufocatcherCost(arg_3_0.refreshTimes + 1)
			else
				var_6_0 = var_0_9:ufocatcherCost(330)
			end

			local var_6_1 = string.format(var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_REFRESH"), var_6_0)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_1, function()
				if arg_3_0.selfPlayer.crystal >= var_6_0 then
					arg_3_0.model:ufocatcherRefresh(nil, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							arg_3_0.dolls_ = arg_8_1.pos_info
							arg_3_0.refreshTimes = arg_8_1.refresh_times

							arg_3_0:updateNum()
							arg_3_0:refresh()
						end
					end)
				else
					local var_7_0 = var_0_5:translation("ZUANSHI_ABSENCE")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_0, function()
						xyd.WindowManager.get():openWindow("vip_recharge")
					end, nil, 0, arg_3_0.colorMode)
				end
			end, nil, 0, arg_3_0.colorMode)
		end
	end)
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_rule"), nil, function(arg_10_0)
		xyd.WindowManager.get():openWindow("new_text_rule", {
			title_name = "ACTIVITY_ANNI_UFOCATCHER_RULE_TITLE",
			rule = "ACTIVITY_ANNI_UFOCATCHER_RULE"
		})
	end)
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_switch"), nil, function(arg_11_0)
		if arg_3_0.isSwitching or arg_3_0.isCatching then
			return
		end

		arg_3_0:playSwitchMove()
	end)

	arg_3_0.gift = arg_3_0:nodeByName("gift")

	arg_3_0.gift:setTouchEnabled(true)
	arg_3_0.gift:setTouchSwallowEnabled(false)
	arg_3_0.gift:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			return true
		elseif arg_12_0.name == "ended" then
			if arg_3_0.awardTimes_ >= arg_3_0.bottomTimes then
				arg_3_0.model:ufocatcherCatchGetExtra({
					sub_id = arg_3_0.superRewardID
				}, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						arg_3_0.awardTimes_ = arg_13_1.award_times

						arg_3_0:updateNum()

						local var_13_0 = {}

						for iter_13_0 = 1, #arg_13_1.awards do
							table.insert(var_13_0, arg_13_1.awards[iter_13_0])
						end

						arg_3_0.selfPlayer:handleRewards(var_13_0)
					end
				end)
			else
				local var_12_0 = var_0_8:getValue("activity_ufocatcher_bottom_gift")[arg_3_0.superRewardID]
				local var_12_1 = var_0_7:items(var_12_0)
				local var_12_2 = var_0_7:itemNum(var_12_0)
				local var_12_3 = {}

				for iter_12_0 = 1, #var_12_1 do
					var_12_3[iter_12_0] = {}
					var_12_3[iter_12_0].item_id = var_12_1[iter_12_0]
					var_12_3[iter_12_0].item_num = var_12_2[iter_12_0]
				end

				xyd.WindowManager.get():openWindow("fourth_anni_award_items", {
					items = var_12_3
				})
			end
		end
	end)

	local var_3_0 = arg_3_0:nodeByName("list_reward")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.giftList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):pos(0, 0)

	arg_3_0.giftList:setDelegate(handler(arg_3_0, arg_3_0.rewardDelegate))
	arg_3_0.giftList:reload()

	arg_3_0.ufocatcherEffect = xyd.createEffect("skeletons/ui_effect/activity_anniversary_4th/ufocatcher/wawaji")

	arg_3_0.ufocatcherEffect:addTo(arg_3_0)
	arg_3_0.ufocatcherEffect:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)

	arg_3_0.catcherEffect = xyd.createEffect("skeletons/ui_effect/activity_anniversary_4th/ufocatcher/wawajizhuashou")

	arg_3_0.catcherEffect:addTo(arg_3_0:nodeByName("catcher_node"))

	arg_3_0.catcherOrgPosX = 0
	arg_3_0.catcherOrgPosY = -350
	arg_3_0.catcherScale = 0.75
	arg_3_0.catcherPosX = 0
	arg_3_0.catcherPosY = -350
	arg_3_0.catcherPosScale = 0.75

	arg_3_0.catcherEffect:setScale(arg_3_0.catcherScale)
	arg_3_0.catcherEffect:setPosition(arg_3_0.catcherOrgPosX, arg_3_0.catcherOrgPosY)
	arg_3_0.catcherEffect:play(nil, true, nil, "idle")

	arg_3_0.dollContainerPos = {}

	for iter_3_0 = 1, 12 do
		arg_3_0.dollContainerPos[iter_3_0] = {}
		arg_3_0.dollContainerPos[iter_3_0].x = arg_3_0:nodeByName("doll_" .. iter_3_0):getPositionX()
		arg_3_0.dollContainerPos[iter_3_0].y = arg_3_0:nodeByName("doll_" .. iter_3_0):getPositionY()
	end

	arg_3_0:addFirstReward()
	arg_3_0:catchOneBtn()
	arg_3_0:catchTenBtn()
	arg_3_0:setMode(var_0_12.hand)
	arg_3_0:setCondition(arg_3_0.condition_)
	arg_3_0:refresh()
	arg_3_0:updateNum()
	arg_3_0:initBarrageScreen()
	arg_3_0:initRocker()
end

function var_0_0.startGame(arg_14_0)
	arg_14_0:setCondition(var_0_13.work)
	arg_14_0:nodeByName("txt_btn_one"):setString(var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP9"))

	if arg_14_0.gameHandler then
		var_0_1.unscheduleGlobal(arg_14_0.gameHandler)

		arg_14_0.gameHandler = nil
	end

	arg_14_0.gameHandler = var_0_1.scheduleUpdateGlobal(function()
		arg_14_0:refreshChtcher(arg_14_0.catcherIndex)
		arg_14_0:updateTiming()
	end)
end

function var_0_0.endGame(arg_16_0)
	arg_16_0:setCondition(var_0_13.rest)
	arg_16_0:nodeByName("txt_btn_one"):setString(var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP7"))

	if arg_16_0.gameHandler then
		var_0_1.unscheduleGlobal(arg_16_0.gameHandler)

		arg_16_0.gameHandler = nil
	end

	arg_16_0:nodeByName("txt_time"):setString("00")

	arg_16_0.gameStartTime = 0
	arg_16_0.gameEndTime = 0
	arg_16_0.sucCatch = false
end

function var_0_0.updateTiming(arg_17_0)
	local var_17_0 = xyd.ServerTime.get():getServerTime()

	if var_17_0 > arg_17_0.gameEndTime and not arg_17_0.sucCatch then
		arg_17_0:endGame()
		arg_17_0.model:ufocatcherEndCatch(nil, function(arg_18_0, arg_18_1)
			if arg_18_0 == xyd.error.OK then
				arg_17_0.awards = {}
				arg_17_0.dolls_ = arg_18_1.pos_info

				for iter_18_0 = 1, #arg_18_1.awards do
					for iter_18_1 = 1, #arg_18_1.awards[iter_18_0] do
						table.insert(arg_17_0.awards, arg_18_1.awards[iter_18_0][iter_18_1])
					end
				end

				if not arg_17_0.isCatching then
					arg_17_0:timeOver()
				end
			end
		end)
	else
		arg_17_0:nodeByName("txt_time"):setString(string.format("%02d", math.max(0, arg_17_0.gameEndTime - var_17_0)))
	end
end

function var_0_0.rewardDelegate(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local var_19_0 = var_0_4:gifts()

	if cc.ui.UIListView.COUNT_TAG == arg_19_2 then
		return #var_19_0 - 1
	elseif cc.ui.UIListView.CELL_TAG == arg_19_2 then
		if not var_19_0[arg_19_3 + 1] then
			return nil
		end

		return arg_19_0:addRewardItem(arg_19_3 + 1, var_19_0[arg_19_3 + 1])
	end
end

function var_0_0.addRewardItem(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_0.giftList:dequeueItem()

	if not var_20_0 then
		var_20_0 = arg_20_0.giftList:newItem()
	else
		var_20_0:removeAllChildren(true)
	end

	local var_20_1 = display.newNode()
	local var_20_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th_ufocatcher/doll_item.csb")
	local var_20_3 = var_20_2:getChildByName("container")

	var_20_3:getChildByName("icon_2"):setVisible(false)
	var_20_3:getChildByName("icon_3"):setVisible(false)

	local var_20_4 = var_0_7:items(arg_20_2)
	local var_20_5 = var_0_7:itemNum(arg_20_2)
	local var_20_6 = var_20_3:getChildByName("gift_1"):getContentSize()
	local var_20_7 = #var_20_4

	for iter_20_0 = 1, var_20_7 do
		xyd.setItemAndAddTips(var_20_3:getChildByName("gift_" .. iter_20_0), var_20_4[iter_20_0], var_20_5[iter_20_0])
	end

	local var_20_8 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th_ufocatcher/icon_doll" .. arg_20_1 .. ".png")
	local var_20_9 = var_20_3:getChildByName("doll"):getContentSize()

	var_20_8:addTo(var_20_3:getChildByName("doll"))
	var_20_8:setAnchorPoint(0.5, 0.5)
	var_20_8:setPosition(var_20_9.width / 2, var_20_9.height / 2)
	var_20_8:setScale(0.85)
	var_20_1:setContentSize(arg_20_0.giftList.viewRect_.width, var_20_3:getContentSize().height)
	var_20_1:addChild(var_20_2)
	var_20_0:addContent(var_20_1)
	var_20_0:setItemSize(arg_20_0.giftList.viewRect_.width, var_20_3:getContentSize().height + 5)

	return var_20_0
end

function var_0_0.addFirstReward(arg_21_0)
	arg_21_0.superRewardID = 1

	local var_21_0 = var_0_8:getValue("activity_ufocatcher_jackpot_reward")[arg_21_0.superRewardID]
	local var_21_1 = var_0_7:items(var_21_0)
	local var_21_2 = var_0_7:itemNum(var_21_0)
	local var_21_3 = arg_21_0:createSuperReward(var_21_1, var_21_2)
	local var_21_4 = arg_21_0:nodeByName("super_reward_container"):getContentSize()

	arg_21_0.superReward = display.newClippingRectangleNode(cc.rect(0, 0, var_21_4.width + 2, var_21_4.height + 2))

	arg_21_0.superReward:addTo(arg_21_0:nodeByName("super_reward_container"))
	var_21_3:addTo(arg_21_0.superReward):pos(1, 1)
	var_21_3:setName("cell")

	local var_21_5 = xyd.AssetLoader.get():loadSprite("windows/anniversary4th_ufocatcher/icon_doll1.png")

	var_21_5:addTo(arg_21_0:nodeByName("super_reward_icon"))
	var_21_5:setAnchorPoint(0.5, 0.5)
	var_21_5:setPosition(0, 0)
end

function var_0_0.playSwitchMove(arg_22_0)
	arg_22_0.isSwitching = true
	arg_22_0.superRewardID = 3 - arg_22_0.superRewardID

	local var_22_0 = var_0_8:getValue("activity_ufocatcher_jackpot_reward")[arg_22_0.superRewardID]
	local var_22_1 = var_0_7:items(var_22_0)
	local var_22_2 = var_0_7:itemNum(var_22_0)
	local var_22_3 = arg_22_0.superReward:getChildByName("cell")
	local var_22_4 = arg_22_0:createSuperReward(var_22_1, var_22_2)

	var_22_4:addTo(arg_22_0.superReward):pos(1, -70)
	var_22_4:setName("cell")
	transition.moveBy(var_22_3, {
		easing = "sineOut",
		time = 0.5,
		y = 71,
		x = 0,
		onComplete = function()
			var_22_3:removeFromParent()

			arg_22_0.isSwitching = false
		end
	})
	transition.moveBy(var_22_4, {
		easing = "sineOut",
		time = 0.5,
		x = 0,
		y = 71
	})
end

function var_0_0.createSuperReward(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th_ufocatcher/super_reward_item.csb")
	local var_24_1 = var_24_0:getChildByName("container")

	for iter_24_0 = 1, 3 do
		if arg_24_1[iter_24_0] and arg_24_1[iter_24_0] ~= 0 then
			xyd.setItemAndAddTips(var_24_1:getChildByName("icon_" .. iter_24_0), arg_24_1[iter_24_0], arg_24_2[iter_24_0])
		end
	end

	return var_24_0
end

function var_0_0.catchOneBtn(arg_25_0)
	xyd.nodeEventSample(arg_25_0.btnOne, nil, function(arg_26_0)
		if arg_25_0.condition_ == var_0_13.rest then
			if arg_25_0.mode_ == var_0_12.hand and not arg_25_0.isCatching then
				local var_26_0

				if arg_25_0.selfPlayer:getBackpack():getItemNumByID(var_0_11) > 0 then
					var_26_0 = var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP3")
				else
					var_26_0 = string.format(var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP4"), var_0_8:getValue("activity_ufocatcher_crystal"))
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_26_0, function()
					if arg_25_0.selfPlayer:getBackpack():getItemNumByID(var_0_11) > 0 or arg_25_0.selfPlayer.crystal >= var_0_8:getValue("activity_ufocatcher_crystal") then
						arg_25_0.model:ufocatcherStartCatch(nil, function(arg_28_0, arg_28_1)
							if arg_28_0 == xyd.error.OK then
								if arg_25_0.selfPlayer:getBackpack():getItemNumByID(var_0_11) > 0 then
									local var_28_0 = {
										itemNum = 1,
										itemID = var_0_11
									}

									arg_25_0.selfPlayer:getBackpack():removeItem(var_28_0)
								end

								arg_25_0.awardTimes_ = arg_28_1.award_times

								arg_25_0:updateNum()

								arg_25_0.gameStartTime = arg_28_1.server_time
								arg_25_0.gameEndTime = arg_28_1.end_time

								if arg_25_0.gameStartTime ~= xyd.ServerTime.get():getServerTime() then
									xyd.ServerTime.get():resetServerTime(arg_25_0.gameStartTime)
								end

								arg_25_0:startGame()
							end
						end)
					else
						local var_27_0 = var_0_5:translation("ZUANSHI_ABSENCE")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_27_0, function()
							xyd.WindowManager.get():openWindow("vip_recharge")
						end, nil, 0, arg_25_0.colorMode)
					end
				end, nil, 0, arg_25_0.colorMode)
			elseif arg_25_0.mode_ == var_0_12.auto and not arg_25_0.isCatching then
				local var_26_1 = var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP1")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_26_1, function()
					if arg_25_0.selfPlayer:getBackpack():getItemNumByID(var_0_10) > 0 then
						arg_25_0.model:ufocatcherAutoCatch({
							times = 1,
							sub_id = arg_25_0.superRewardID
						}, function(arg_31_0, arg_31_1)
							if arg_31_0 == xyd.error.OK then
								local var_31_0 = {
									itemNum = 1,
									itemID = var_0_10
								}

								arg_25_0.selfPlayer:getBackpack():removeItem(var_31_0)

								arg_25_0.awardTimes_ = arg_31_1.award_times

								arg_25_0:updateNum()

								arg_25_0.dolls_ = arg_31_1.pos_info

								arg_25_0:setCondition(var_0_13.work)

								local var_31_1 = {}

								for iter_31_0 = 1, #arg_31_1.awards do
									for iter_31_1 = 1, #arg_31_1.awards[iter_31_0] do
										table.insert(var_31_1, arg_31_1.awards[iter_31_0][iter_31_1])
									end
								end

								arg_25_0:autoCatchOne(arg_31_1.first_pos, var_31_1)
							end
						end)
					else
						local var_30_0 = var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP6")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_30_0, function()
							xyd.WindowManager.get():openWindow("vip_recharge")
						end, nil, 0, arg_25_0.colorMode)
					end
				end, nil, 0, arg_25_0.colorMode)
			end
		elseif arg_25_0.condition_ == var_0_13.work and not arg_25_0.isCatching then
			arg_25_0.model:ufocatcherCatch({
				idx = arg_25_0.dollPos,
				sub_id = arg_25_0.superRewardID
			}, function(arg_33_0, arg_33_1)
				if arg_33_0 == xyd.error.OK then
					if arg_33_1.is_success == 1 then
						arg_25_0.dolls_ = arg_33_1.pos_info

						local var_33_0 = {}

						for iter_33_0 = 1, #arg_33_1.awards do
							for iter_33_1 = 1, #arg_33_1.awards[iter_33_0] do
								table.insert(var_33_0, arg_33_1.awards[iter_33_0][iter_33_1])
							end
						end

						arg_25_0:handCatchOne(arg_25_0.dollPos, true, var_33_0)

						arg_25_0.sucCatch = true
					else
						arg_25_0:handCatchOne(arg_25_0.dollPos, false)
					end
				end
			end)
		end
	end)
end

function var_0_0.catchTenBtn(arg_34_0)
	xyd.nodeEventSample(arg_34_0.btnTen, nil, function(arg_35_0)
		if arg_34_0.condition_ == var_0_13.rest and arg_34_0.mode_ == var_0_12.auto then
			local var_35_0 = var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP2")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_35_0, function()
				if arg_34_0.selfPlayer:getBackpack():getItemNumByID(var_0_10) >= 10 then
					arg_34_0.model:ufocatcherAutoCatch({
						times = 10,
						sub_id = arg_34_0.superRewardID
					}, function(arg_37_0, arg_37_1)
						if arg_37_0 == xyd.error.OK then
							local var_37_0 = {
								itemNum = 10,
								itemID = var_0_10
							}

							arg_34_0.selfPlayer:getBackpack():removeItem(var_37_0)

							arg_34_0.awardTimes_ = arg_37_1.award_times

							arg_34_0:updateNum()

							arg_34_0.dolls_ = arg_37_1.pos_info

							arg_34_0:setCondition(var_0_13.work)

							local var_37_1 = {}

							for iter_37_0 = 1, #arg_37_1.awards do
								for iter_37_1 = 1, #arg_37_1.awards[iter_37_0] do
									table.insert(var_37_1, arg_37_1.awards[iter_37_0][iter_37_1])
								end
							end

							arg_34_0:autoCatchOne(arg_37_1.first_pos, var_37_1)
						end
					end)
				else
					local var_36_0 = var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP6")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_36_0, function()
						xyd.WindowManager.get():openWindow("vip_recharge")
					end, nil, 0, arg_34_0.colorMode)
				end
			end, nil, 0, arg_34_0.colorMode)
		end
	end)
end

function var_0_0.autoCatchOne(arg_39_0, arg_39_1, arg_39_2)
	arg_39_0.isCatching = true

	local var_39_0
	local var_39_1
	local var_39_2, var_39_3 = arg_39_0:convertToSpace(arg_39_1)
	local var_39_4
	local var_39_5
	local var_39_6, var_39_7 = arg_39_0:convertToSpace(arg_39_1, true)
	local var_39_8 = (math.abs(var_39_6) + math.abs(1 - var_39_3) * arg_39_0.catcherScale * 1000) / arg_39_0.speed
	local var_39_9, var_39_10 = math.modf(var_39_8 * 0.75)
	local var_39_11 = cc.Spawn:create(cc.ScaleBy:create(math.abs(1 - var_39_3) * arg_39_0.catcherScale * 1000 / arg_39_0.speed, var_39_3), cc.MoveBy:create(math.abs(1 - var_39_3) * arg_39_0.catcherScale * 1000 / arg_39_0.speed, cc.p(0, arg_39_0.catcherScale * (1 - var_39_3) * 520)))
	local var_39_12 = cc.Sequence:create(var_39_11, cc.MoveBy:create(math.abs(var_39_2) / arg_39_0.speed, cc.p(var_39_2, 0)), cc.CallFunc:create(function()
		arg_39_0.catcherEffect:play(nil, false, nil, "start01")
	end), cc.DelayTime:create(2), cc.Spawn:create(cc.Sequence:create(cc.MoveBy:create(math.abs(var_39_6) / arg_39_0.speed, cc.p(var_39_6, 0)), var_39_11:reverse()), cc.CallFunc:create(function()
		arg_39_0.catcherEffect:play(nil, true, nil, "move01")
	end)), cc.DelayTime:create(4 * (1 - var_39_10) / 3), cc.CallFunc:create(function()
		arg_39_0.catcherEffect:play(nil, false, nil, "unlock")
	end))
	local var_39_13 = cc.Sequence:create(cc.DelayTime:create((math.abs(1 - var_39_3) * arg_39_0.catcherScale * 1000 + math.abs(var_39_2)) / arg_39_0.speed + 1.18), cc.MoveBy:create(0.4166666666666667, cc.p(0, 296 * arg_39_0.catcherScale * var_39_3)), cc.DelayTime:create(0.40333333333333327), cc.Spawn:create(cc.Sequence:create(cc.MoveBy:create(math.abs(var_39_6) / arg_39_0.speed, cc.p(var_39_6, 0)), cc.Spawn:create(cc.ScaleBy:create(math.abs(1 - var_39_3) * arg_39_0.catcherScale * 1000 / arg_39_0.speed, (1 - var_39_3) / 1.5 + 1), cc.MoveBy:create(math.abs(1 - var_39_3) * arg_39_0.catcherScale * 1000 / arg_39_0.speed, cc.p(0, arg_39_0.catcherScale * (var_39_3 - 1) * 150)))), cc.Sequence:create(cc.Repeat:create(cc.Sequence:create(cc.MoveBy:create(0.3333333333333333, cc.p(-10, 2)), cc.MoveBy:create(0.3333333333333333, cc.p(-10, 2)):reverse(), cc.MoveBy:create(0.3333333333333333, cc.p(10, 2)), cc.MoveBy:create(0.3333333333333333, cc.p(10, 2)):reverse()), var_39_9 + 1)), cc.Sequence:create(cc.Repeat:create(cc.Sequence:create(cc.RotateBy:create(0.3333333333333333, 10), cc.RotateBy:create(0.3333333333333333, 10):reverse(), cc.RotateBy:create(0.3333333333333333, -10), cc.RotateBy:create(0.3333333333333333, -10):reverse()), var_39_9 + 1))), cc.MoveBy:create(0.5, cc.p(0, -120 * arg_39_0.catcherScale)), cc.CallFunc:create(function()
		arg_39_0:showResult(arg_39_2)
		arg_39_0:refresh()
	end))
	local var_39_14 = cc.Sequence:create(cc.DelayTime:create((math.abs(1 - var_39_3) * arg_39_0.catcherScale * 1000 + math.abs(var_39_2)) / arg_39_0.speed), cc.CallFunc:create(function()
		arg_39_0:nodeByName("bg_doll_" .. arg_39_1):setVisible(false)
		arg_39_0:nodeByName("bg_doll_select_" .. arg_39_1):setVisible(true)
	end), cc.DelayTime:create(1.18), cc.Spawn:create(cc.ScaleBy:create(0.4166666666666667, 0.5), cc.FadeOut:create(0.4166666666666667)))

	arg_39_0.catcherEffect:runAction(var_39_12)
	arg_39_0:nodeByName("doll_" .. arg_39_1):runAction(var_39_13)
	arg_39_0:nodeByName("bg_doll_select_" .. arg_39_1):runAction(var_39_14)
end

function var_0_0.handCatchOne(arg_45_0, arg_45_1, arg_45_2, arg_45_3)
	arg_45_0.isCatching = true

	local var_45_0
	local var_45_1
	local var_45_2

	if arg_45_1 < 8 then
		var_45_0 = (arg_45_1 - 4) * 100
		var_45_2 = -210
	else
		var_45_0 = (arg_45_1 - 9) * 100
		var_45_2 = -310
	end

	if arg_45_2 then
		local var_45_3 = (math.abs(arg_45_0.catcherPosX + 250) + math.abs(arg_45_0.catcherPosScale - arg_45_0.catcherScale) * 1000) / arg_45_0.speed
		local var_45_4, var_45_5 = math.modf(var_45_3 * 0.75)
		local var_45_6 = cc.Sequence:create(cc.CallFunc:create(function()
			arg_45_0.catcherEffect:play(nil, false, nil, "start01")
		end), cc.DelayTime:create(2), cc.Spawn:create(cc.Sequence:create(cc.MoveBy:create(math.abs(arg_45_0.catcherPosX + 250) / arg_45_0.speed, cc.p(-250 - arg_45_0.catcherPosX, 0)), cc.Spawn:create(cc.ScaleBy:create(math.abs(arg_45_0.catcherPosScale - arg_45_0.catcherScale) * 1000 / arg_45_0.speed, arg_45_0.catcherScale / arg_45_0.catcherPosScale), cc.MoveBy:create(math.abs(arg_45_0.catcherPosScale - arg_45_0.catcherScale) * 1000 / arg_45_0.speed, cc.p(0, arg_45_0.catcherOrgPosY - arg_45_0.catcherPosY)))), cc.CallFunc:create(function()
			arg_45_0.catcherEffect:play(nil, true, nil, "move01")
		end)), cc.DelayTime:create(4 * (1 - var_45_5) / 3), cc.CallFunc:create(function()
			arg_45_0.catcherEffect:play(nil, false, nil, "unlock")
		end))
		local var_45_7 = cc.MoveBy:create(0, cc.p(arg_45_0.catcherPosX - var_45_0, -420 * arg_45_0.catcherPosScale - var_45_2))
		local var_45_8

		if arg_45_1 > 7 then
			var_45_8 = cc.ScaleBy:create(0, arg_45_0.catcherPosScale / arg_45_0.catcherScale)
		else
			var_45_8 = cc.ScaleBy:create(0, arg_45_0.catcherPosScale / 0.51)
		end

		local var_45_9 = cc.Sequence:create(cc.DelayTime:create(1.18), var_45_7, var_45_8, cc.MoveBy:create(0.4166666666666667, cc.p(0, 296 * arg_45_0.catcherPosScale)), cc.DelayTime:create(0.40333333333333327), cc.Spawn:create(cc.Sequence:create(cc.MoveBy:create(math.abs(arg_45_0.catcherPosX + 250) / arg_45_0.speed, cc.p(-250 - arg_45_0.catcherPosX, 0)), cc.Spawn:create(cc.ScaleBy:create(math.abs(arg_45_0.catcherPosScale - arg_45_0.catcherScale) * 1000 / arg_45_0.speed, 1 + 0.2 * ((arg_45_0.catcherScale - arg_45_0.catcherPosScale) / 0.24)), cc.MoveBy:create(math.abs(arg_45_0.catcherPosScale - arg_45_0.catcherScale) * 1000 / arg_45_0.speed, cc.p(0, (arg_45_0.catcherPosScale - arg_45_0.catcherScale) / 1.2 * 150)))), cc.Sequence:create(cc.Repeat:create(cc.Sequence:create(cc.MoveBy:create(0.3333333333333333, cc.p(-10, 2)), cc.MoveBy:create(0.3333333333333333, cc.p(-10, 2)):reverse(), cc.MoveBy:create(0.3333333333333333, cc.p(10, 2)), cc.MoveBy:create(0.3333333333333333, cc.p(10, 2)):reverse()), var_45_4 + 1)), cc.Sequence:create(cc.Repeat:create(cc.Sequence:create(cc.RotateBy:create(0.3333333333333333, 10), cc.RotateBy:create(0.3333333333333333, 10):reverse(), cc.RotateBy:create(0.3333333333333333, -10), cc.RotateBy:create(0.3333333333333333, -10):reverse()), var_45_4 + 1))), cc.MoveBy:create(0.5, cc.p(0, -120 * arg_45_0.catcherScale)), cc.CallFunc:create(function()
			arg_45_0:endGame()
			arg_45_0:showResult(arg_45_3)
			arg_45_0:refresh()
		end))
		local var_45_10 = cc.Sequence:create(cc.DelayTime:create(1.18), var_45_7, var_45_8, cc.Spawn:create(cc.ScaleBy:create(0.4166666666666667, 0.5), cc.FadeOut:create(0.4166666666666667)))

		arg_45_0.catcherEffect:runAction(var_45_6)
		arg_45_0:nodeByName("doll_" .. arg_45_1):runAction(var_45_9)
		arg_45_0:nodeByName("bg_doll_select_" .. arg_45_1):runAction(var_45_10)
	else
		local var_45_11 = cc.Sequence:create(cc.CallFunc:create(function()
			arg_45_0.catcherEffect:play(nil, false, nil, "start02")
		end), cc.DelayTime:create(2), cc.MoveBy:create(math.abs(arg_45_0.catcherPosX) / arg_45_0.speed, cc.p(-arg_45_0.catcherPosX, 0)), cc.Spawn:create(cc.ScaleBy:create(math.abs(arg_45_0.catcherPosScale - arg_45_0.catcherScale) * 1000 / arg_45_0.speed, arg_45_0.catcherScale / arg_45_0.catcherPosScale), cc.MoveBy:create(math.abs(arg_45_0.catcherPosScale - arg_45_0.catcherScale) * 1000 / arg_45_0.speed, cc.p(0, arg_45_0.catcherOrgPosY - arg_45_0.catcherPosY))), cc.CallFunc:create(function()
			arg_45_0.catcherPosX = arg_45_0.catcherOrgPosX
			arg_45_0.catcherPosScale = arg_45_0.catcherScale
			arg_45_0.catcherPosY = arg_45_0.catcherOrgPosY

			if arg_45_0.condition_ == var_0_13.work then
				arg_45_0.isCatching = false
			else
				arg_45_0:timeOver()
			end
		end))
		local var_45_12 = cc.MoveBy:create(0, cc.p(arg_45_0.catcherPosX - var_45_0, -420 * arg_45_0.catcherPosScale - var_45_2))
		local var_45_13

		if arg_45_1 > 7 then
			var_45_13 = cc.ScaleBy:create(0, arg_45_0.catcherPosScale / arg_45_0.catcherScale)
		else
			var_45_13 = cc.ScaleBy:create(0, arg_45_0.catcherPosScale / 0.51)
		end

		local var_45_14 = cc.MoveBy:create(0.2833333333333333, cc.p(0, 102 * arg_45_0.catcherPosScale))
		local var_45_15 = cc.Sequence:create(cc.DelayTime:create(1.18), var_45_12, var_45_13, var_45_14, var_45_14:reverse(), var_45_13:reverse(), var_45_12:reverse())
		local var_45_16 = cc.Sequence:create(cc.DelayTime:create(1.18), var_45_12, var_45_13, cc.ScaleBy:create(0.2833333333333333, 0.8), cc.ScaleBy:create(0.2833333333333333, 0.8):reverse(), var_45_13:reverse(), var_45_12:reverse())

		arg_45_0.catcherEffect:runAction(var_45_11)
		arg_45_0:nodeByName("doll_" .. arg_45_1):runAction(var_45_15)
		arg_45_0:nodeByName("bg_doll_select_" .. arg_45_1):runAction(var_45_16)
	end
end

function var_0_0.refresh(arg_52_0)
	local var_52_0 = "windows/anniversary4th_ufocatcher/doll"
	local var_52_1 = arg_52_0:nodeByName("doll_1"):getContentSize()

	for iter_52_0 = 1, 12 do
		local var_52_2 = arg_52_0.dolls_[iter_52_0]
		local var_52_3 = arg_52_0:nodeByName("doll_" .. iter_52_0)

		var_52_3:removeAllChildren(true)

		local var_52_4 = xyd.AssetLoader.get():loadSprite(var_52_0 .. var_52_2 .. ".png")

		var_52_4:addTo(var_52_3)
		var_52_4:setAnchorPoint(var_0_14[var_52_2])
		var_52_4:setPosition(var_52_1.width / 2, var_52_1.height / 2)
		var_52_3:setPosition(arg_52_0.dollContainerPos[iter_52_0])
		var_52_3:setScale(1)
		arg_52_0:nodeByName("bg_doll_select_" .. iter_52_0):setVisible(false)
		arg_52_0:nodeByName("bg_doll_select_" .. iter_52_0):runAction(cc.FadeIn:create(0))
		arg_52_0:nodeByName("bg_doll_select_" .. iter_52_0):setPosition(arg_52_0.dollContainerPos[iter_52_0].x, arg_52_0.dollContainerPos[iter_52_0].y - 35)
		arg_52_0:nodeByName("bg_doll_" .. iter_52_0):setVisible(true)

		if iter_52_0 < 8 then
			var_52_4:setScale(0.8)
			arg_52_0:nodeByName("bg_doll_" .. iter_52_0):setScale(0.8)
			arg_52_0:nodeByName("bg_doll_select_" .. iter_52_0):setScale(0.8)
		else
			arg_52_0:nodeByName("bg_doll_" .. iter_52_0):setScale(1)
			arg_52_0:nodeByName("bg_doll_select_" .. iter_52_0):setScale(1)
		end
	end

	arg_52_0:setCondition(var_0_13.rest)

	arg_52_0.catcherPosX = arg_52_0.catcherOrgPosX
	arg_52_0.catcherPosY = arg_52_0.catcherOrgPosY
	arg_52_0.catcherPosScale = arg_52_0.catcherScale

	arg_52_0.catcherEffect:setPosition(arg_52_0.catcherOrgPosX, arg_52_0.catcherOrgPosY)
	arg_52_0.catcherEffect:setScale(arg_52_0.catcherScale)

	arg_52_0.isCatching = false
	arg_52_0.awards = {}
	arg_52_0.dollPos = -1
end

function var_0_0.updateNum(arg_53_0)
	arg_53_0:updateEco()

	if arg_53_0.mode_ == var_0_12.hand then
		arg_53_0:nodeByName("txt_coin_num"):setString("x" .. arg_53_0.selfPlayer:getBackpack():getItemNumByID(var_0_11))
	elseif arg_53_0.mode_ == var_0_12.auto then
		arg_53_0:nodeByName("txt_coin_num"):setString("x" .. arg_53_0.selfPlayer:getBackpack():getItemNumByID(var_0_10))
	end

	arg_53_0:nodeByName("txt_gift"):setString(arg_53_0.awardTimes_ .. "/" .. arg_53_0.bottomTimes)
	arg_53_0:nodeByName("bar"):setPercent(math.min(arg_53_0.awardTimes_ / arg_53_0.bottomTimes * 100, 100))

	if arg_53_0.awardTimes_ >= arg_53_0.bottomTimes then
		arg_53_0.gift:stopAllActions()
		arg_53_0.gift:setRotation(0)

		local var_53_0 = var_0_8:getValue("activity_ufocatcher_gift_frequency")
		local var_53_1 = cc.RepeatForever:create(cc.Sequence:create(cc.RotateBy:create(var_53_0 / 4, -20), cc.RotateBy:create(var_53_0 / 4, -20):reverse(), cc.RotateBy:create(var_53_0 / 4, 20), cc.RotateBy:create(var_53_0 / 4, 20):reverse(), cc.RotateBy:create(var_53_0 / 4, -20), cc.RotateBy:create(var_53_0 / 4, -20):reverse(), cc.RotateBy:create(var_53_0 / 4, 20), cc.RotateBy:create(var_53_0 / 4, 20):reverse(), cc.DelayTime:create(1)))

		arg_53_0.gift:runAction(var_53_1)
	else
		arg_53_0.gift:stopAllActions()
		arg_53_0.gift:setRotation(0)
	end
end

function var_0_0.showResult(arg_54_0, arg_54_1)
	local var_54_0 = {}
	local var_54_1 = {}

	for iter_54_0, iter_54_1 in pairs(arg_54_1) do
		if var_54_0[iter_54_1.table_id] then
			var_54_0[iter_54_1.table_id].item_num = iter_54_1.item_num + var_54_0[iter_54_1.table_id].item_num
		else
			var_54_0[iter_54_1.table_id] = {}
			var_54_0[iter_54_1.table_id] = iter_54_1
		end
	end

	local var_54_2 = 1

	for iter_54_2, iter_54_3 in pairs(var_54_0) do
		var_54_1[var_54_2] = {}
		var_54_1[var_54_2] = iter_54_3
		var_54_2 = var_54_2 + 1
	end

	arg_54_0.selfPlayer:handleRewards(var_54_1)
end

function var_0_0.setMode(arg_55_0, arg_55_1)
	if arg_55_0.mode_ == arg_55_1 then
		return
	else
		arg_55_0.mode_ = arg_55_1
	end

	if var_0_12.hand == arg_55_1 then
		arg_55_0.btnHandOff:setVisible(false)
		arg_55_0.btnHandOn:setVisible(true)
		arg_55_0.btnAutoOff:setVisible(true)
		arg_55_0.btnAutoOn:setVisible(false)
		arg_55_0.chargeCoin:setVisible(false)
		arg_55_0.goldCoin:setVisible(true)
		arg_55_0.btnTen:setVisible(false)
		arg_55_0.rocker:setVisible(true)
		arg_55_0.btnOne:setPosition(arg_55_0.btnTen:getPosition())
		arg_55_0:nodeByName("txt_coin_num"):setString("x" .. arg_55_0.selfPlayer:getBackpack():getItemNumByID(var_0_11))
	elseif var_0_12.auto == arg_55_1 then
		arg_55_0.btnHandOff:setVisible(true)
		arg_55_0.btnHandOn:setVisible(false)
		arg_55_0.btnAutoOff:setVisible(false)
		arg_55_0.btnAutoOn:setVisible(true)
		arg_55_0.chargeCoin:setVisible(true)
		arg_55_0.goldCoin:setVisible(false)
		arg_55_0.btnTen:setVisible(true)
		arg_55_0.rocker:setVisible(false)
		arg_55_0.btnOne:setPosition(820, 90.5)
		arg_55_0:nodeByName("txt_coin_num"):setString("x" .. arg_55_0.selfPlayer:getBackpack():getItemNumByID(var_0_10))
	end
end

function var_0_0.setCondition(arg_56_0, arg_56_1)
	arg_56_0.condition_ = arg_56_1

	if var_0_13.rest == arg_56_1 then
		arg_56_0.ufocatcherEffect:stop()
		arg_56_0.ufocatcherEffect:play(nil, true, nil, "texiao01")
		arg_56_0.btnHandOff:setTouchEnabled(true)
		arg_56_0.btnAutoOff:setTouchEnabled(true)

		if arg_56_0.mode_ == var_0_12.auto then
			arg_56_0.btnOne:setTouchEnabled(true)
			arg_56_0.btnTen:setTouchEnabled(true)
		end

		arg_56_0:nodeByName("btn_reset"):setVisible(true)
	elseif var_0_13.work == arg_56_1 then
		arg_56_0.ufocatcherEffect:stop()
		arg_56_0.ufocatcherEffect:play(function()
			arg_56_0.ufocatcherEffect:play(nil, true, nil, "texiao04")
		end, false, nil, "texiao02")
		arg_56_0.btnHandOff:setTouchEnabled(false)
		arg_56_0.btnAutoOff:setTouchEnabled(false)

		if arg_56_0.mode_ == var_0_12.auto then
			arg_56_0.btnOne:setTouchEnabled(false)
			arg_56_0.btnTen:setTouchEnabled(false)
		end

		arg_56_0:nodeByName("btn_reset"):setVisible(false)
	end
end

function var_0_0.convertToSpace(arg_58_0, arg_58_1, arg_58_2)
	local var_58_0
	local var_58_1
	local var_58_2

	if arg_58_1 < 8 then
		if arg_58_2 then
			var_58_0 = (1.5 - arg_58_1) * 100
			var_58_2 = 1
		else
			var_58_0 = (arg_58_1 - 4) * 100
			var_58_2 = 0.7
		end
	elseif arg_58_2 then
		var_58_0 = (6.5 - arg_58_1) * 100
		var_58_2 = 1
	else
		var_58_0 = (arg_58_1 - 9) * 100
		var_58_2 = 1
	end

	return var_58_0, var_58_2
end

function var_0_0.timeOver(arg_59_0)
	local var_59_0 = xyd.createEffect("skeletons/ui_effect/activity_anniversary_4th/ufocatcher/wawajishijian")

	var_59_0:addTo(arg_59_0)
	var_59_0:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
	var_59_0:play(function()
		var_0_1.performWithDelayGlobal(function()
			arg_59_0:removeChild(var_59_0)
			arg_59_0.selfPlayer:handleRewards(arg_59_0.awards, function()
				arg_59_0:refresh()
			end)
		end, 0.1)
	end, false)
end

function var_0_0.initBarrageScreen(arg_63_0)
	local var_63_0 = arg_63_0:nodeByName("barrage")
	local var_63_1 = var_63_0:getContentSize()

	arg_63_0.clippingNode = display.newClippingRegionNode()

	arg_63_0.clippingNode:setClippingRegion(cc.rect(0, 0, var_63_1.width, var_63_1.height))
	var_63_0:addChild(arg_63_0.clippingNode)

	arg_63_0.newContainer = display.newNode()

	arg_63_0.newContainer:setContentSize(var_63_1)
	arg_63_0.newContainer:addTo(arg_63_0.clippingNode)
	arg_63_0:showBarrage()
end

function var_0_0.showBarrage(arg_64_0)
	if arg_64_0.loadBarrageHandler then
		var_0_1.unscheduleGlobal(arg_64_0.loadBarrageHandler)

		arg_64_0.loadBarrageHandler = nil
	end

	arg_64_0.loadBarrageHandler = var_0_1.scheduleGlobal(function()
		if arg_64_0.barrageInfos and #arg_64_0.barrageInfos < 10 and not arg_64_0.isLoadingBarrage then
			arg_64_0.isLoadingBarrage = true

			arg_64_0:getBarrage()
		end
	end, 10)

	if arg_64_0.showBarrageHandler then
		var_0_1.unscheduleGlobal(arg_64_0.showBarrageHandler)

		arg_64_0.showBarrageHandler = nil
	end

	arg_64_0.showBarrageHandler = var_0_1.scheduleGlobal(function()
		if not arg_64_0.isShowingBarrage then
			arg_64_0.isShowingBarrage = true

			arg_64_0:createBarrage()
		end
	end, 3)
end

function var_0_0.getBarrage(arg_67_0)
	arg_67_0.model:ufocatcherCatchList(nil, function(arg_68_0, arg_68_1)
		if arg_68_0 == xyd.error.OK then
			local var_68_0 = arg_68_1.messages

			for iter_68_0 = 1, #var_68_0 do
				table.insert(arg_67_0.barrageInfos, var_68_0[iter_68_0])
			end
		end

		arg_67_0.isLoadingBarrage = false
	end)
end

function var_0_0.createBarrage(arg_69_0)
	if not arg_69_0.barrageInfos or not next(arg_69_0.barrageInfos) then
		arg_69_0.isShowingBarrage = false

		return
	end

	local var_69_0 = var_0_8:getValue("activity_ufocatcher_barrage_length")
	local var_69_1 = var_0_8:getValue("activity_ufocatcher_barrage_speed")
	local var_69_2 = arg_69_0.barrageInfos[1].table_id
	local var_69_3

	if var_69_2 == 1 and arg_69_0.barrageInfos[1].sub_id then
		var_69_3 = var_0_8:getValue("activity_ufocatcher_jackpot_reward")[arg_69_0.barrageInfos[1].sub_id]
	else
		var_69_3 = var_0_4:gift(var_69_2)
	end

	local var_69_4 = var_0_7:items(var_69_3)
	local var_69_5 = var_0_7:itemNum(var_69_3)
	local var_69_6 = ""

	for iter_69_0 = 1, #var_69_4 do
		if iter_69_0 < #var_69_4 then
			var_69_6 = var_69_6 .. var_0_6:name(var_69_4[iter_69_0]) .. "*" .. var_69_5[iter_69_0] .. "、"
		else
			var_69_6 = var_69_6 .. var_0_6:name(var_69_4[iter_69_0]) .. "*" .. var_69_5[iter_69_0]
		end
	end

	local var_69_7 = {
		height = 5,
		isSelf = 0,
		parent = arg_69_0.newContainer,
		text = string.format(var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_BARRAGE"), arg_69_0.barrageInfos[1].name, arg_69_0.barrageInfos[1].table_id, var_69_6),
		duration = var_69_1,
		callback = function()
			var_0_1.performWithDelayGlobal(function()
				if arg_69_0 and not tolua.isnull(arg_69_0) then
					arg_69_0.isShowingBarrage = false

					arg_69_0:nodeByName("barrage"):setVisible(false)
				end
			end, var_69_1 - 1)
		end
	}

	arg_69_0:nodeByName("barrage"):setVisible(true)

	local var_69_8 = import("app.windows.TextBarrageItem").new()

	var_69_8:setParams(var_69_7)
	var_69_8:move()
	table.remove(arg_69_0.barrageInfos, 1)
end

function var_0_0.initRocker(arg_72_0)
	if arg_72_0.mode_ == var_0_12.auto then
		arg_72_0.rocker:setVisible(false)
	elseif arg_72_0.mode_ == var_0_12.hand then
		arg_72_0.rocker:setVisible(true)

		for iter_72_0 = 1, 9 do
			arg_72_0:nodeByName("rocker_" .. iter_72_0):setVisible(iter_72_0 == 5)
		end
	end

	local var_72_0 = display.newNode()
	local var_72_1 = arg_72_0.rocker:getContentSize()

	var_72_0:setContentSize(100, 200)
	var_72_0:addTo(arg_72_0.rocker)
	var_72_0:setAnchorPoint(0.5, 0.5)
	var_72_0:setPosition(var_72_1.width / 2, var_72_1.height / 2)
	var_72_0:setTouchEnabled(true)
	var_72_0:setTouchSwallowEnabled(false)
	var_72_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_73_0)
		if arg_73_0.name == "began" then
			arg_72_0.rockerOrgX = arg_73_0.x
			arg_72_0.rockerOrgY = arg_73_0.y

			return true
		elseif arg_73_0.name == "moved" then
			arg_72_0.catcherIndex = arg_72_0:refreshRockerAndGetIndex(arg_73_0.x, arg_73_0.y)

			return true
		elseif arg_73_0.name == "ended" then
			for iter_73_0 = 1, 9 do
				arg_72_0:nodeByName("rocker_" .. iter_73_0):setVisible(iter_73_0 == 5)
			end

			arg_72_0.catcherIndex = 4
		end
	end)
end

function var_0_0.refreshRockerAndGetIndex(arg_74_0, arg_74_1, arg_74_2)
	local var_74_0 = 0

	if arg_74_2 - arg_74_0.rockerOrgY < -40 then
		var_74_0 = var_74_0 + 6
	elseif arg_74_2 - arg_74_0.rockerOrgY >= -40 and arg_74_2 - arg_74_0.rockerOrgY < 40 then
		var_74_0 = var_74_0 + 3
	end

	if arg_74_1 - arg_74_0.rockerOrgX > 40 then
		var_74_0 = var_74_0 + 2
	elseif arg_74_1 - arg_74_0.rockerOrgX <= 40 and arg_74_1 - arg_74_0.rockerOrgX >= -40 then
		var_74_0 = var_74_0 + 1
	end

	for iter_74_0 = 1, 9 do
		arg_74_0:nodeByName("rocker_" .. iter_74_0):setVisible(iter_74_0 == var_74_0 + 1)
	end

	return var_74_0
end

function var_0_0.refreshChtcher(arg_75_0, arg_75_1)
	if not arg_75_1 or arg_75_0.isCatching then
		return
	end

	local var_75_0 = arg_75_1 % 3 - 1
	local var_75_1 = math.floor(arg_75_1 / 3) - 1
	local var_75_2 = arg_75_0.speed

	if var_75_0 ~= 0 and var_75_1 ~= 0 then
		var_75_2 = var_75_2 / math.sqrt(2)
	end

	if arg_75_0.catcherPosScale <= 0.63 then
		arg_75_0.catcherPosX = math.max(math.min(arg_75_0.catcherPosX + var_75_0 * var_75_2 / 30, 320), -320)
	else
		arg_75_0.catcherPosX = math.max(math.min(arg_75_0.catcherPosX + var_75_0 * var_75_2 / 30, 320), -120)
	end

	if arg_75_0.catcherPosX >= -120 then
		arg_75_0.catcherPosScale = math.max(math.min(arg_75_0.catcherPosScale + var_75_1 * 0.05 * var_75_2 / 1000, arg_75_0.catcherScale), 0.51)
	else
		arg_75_0.catcherPosScale = math.max(math.min(arg_75_0.catcherPosScale + var_75_1 * 0.05 * var_75_2 / 1000, 0.63), 0.51)
	end

	arg_75_0.catcherPosY = arg_75_0.catcherOrgPosY + (arg_75_0.catcherScale - arg_75_0.catcherPosScale) * 4 * arg_75_0.catcherScale * 170

	arg_75_0.catcherEffect:setPosition(arg_75_0.catcherPosX, arg_75_0.catcherPosY)
	arg_75_0.catcherEffect:setScale(arg_75_0.catcherPosScale)

	local var_75_3

	if arg_75_0.catcherPosScale <= 0.63 then
		var_75_3 = math.floor((arg_75_0.catcherPosX + 350) / 100) + 1
	else
		var_75_3 = math.floor((arg_75_0.catcherPosX + 150) / 100) + 8
	end

	if var_75_3 ~= arg_75_0.dollPos then
		if arg_75_0.dollPos ~= -1 then
			arg_75_0:nodeByName("bg_doll_" .. arg_75_0.dollPos):setVisible(true)
			arg_75_0:nodeByName("bg_doll_select_" .. arg_75_0.dollPos):setVisible(false)
		end

		arg_75_0:nodeByName("bg_doll_" .. var_75_3):setVisible(false)
		arg_75_0:nodeByName("bg_doll_select_" .. var_75_3):setVisible(true)

		arg_75_0.dollPos = var_75_3
	end
end

function var_0_0.addTopSidebar(arg_76_0)
	arg_76_0:nodeByName("title_txt"):setString(xyd.tables.window:title(arg_76_0.name))

	local var_76_0 = var_0_2.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(arg_76_0.colorMode)
	})

	var_76_0:addTo(arg_76_0:nodeByName("pos_top_sidebar"))
	var_76_0:setAnchorPoint(0.5, 0.5)
	var_76_0:setPosition(47, -23)
	var_76_0:addTouchEvent(function(arg_77_0)
		if arg_77_0.name == "ended" then
			if arg_76_0.condition_ == var_0_13.work then
				local var_77_0 = var_0_5:translation("ACTIVITY_ANNI_UFOCATCHER_TIP5")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_77_0, function()
					if arg_76_0.mode_ == var_0_12.hand then
						arg_76_0.model:ufocatcherEndCatch(nil, function(arg_79_0, arg_79_1)
							if arg_79_0 == xyd.error.OK then
								local var_79_0 = {}

								for iter_79_0 = 1, #arg_79_1.awards do
									for iter_79_1 = 1, #arg_79_1.awards[iter_79_0] do
										table.insert(var_79_0, arg_79_1.awards[iter_79_0][iter_79_1])
									end
								end

								arg_76_0.selfPlayer:handleRewards(var_79_0, function()
									arg_76_0:close()
								end)
							end
						end)
					else
						arg_76_0:close()
					end
				end, nil, 0, arg_76_0.colorMode)
			else
				arg_76_0:close()
			end
		end
	end)

	local var_76_1 = {
		ecoCount = 3,
		colorMode = arg_76_0.colorMode,
		ecoTypes = {
			var_0_10,
			2,
			var_0_11
		},
		ecoIcons = {
			"windows/anniversary4th_ufocatcher/icon_charge_coin.png",
			-1,
			"windows/anniversary4th_ufocatcher/icon_gold_coin.png"
		}
	}
	local var_76_2 = var_0_3.new(xyd.WidgetName.ecoDisplaySidebar, var_76_1)

	var_76_2:addTo(arg_76_0:nodeByName("eco_sidebar"))
	var_76_2:setAnchorPoint(0, 0)
	var_76_2:setPosition(-120, 0)
	var_76_2:setName("eco_sidebar")

	arg_76_0.children_.eco_sidebar = var_76_2
end

function var_0_0.updateEco(arg_81_0)
	local var_81_0 = arg_81_0:nodeByName("eco_sidebar")

	for iter_81_0 = 1, 3 do
		arg_81_0:updateEcoByIdx(var_81_0, iter_81_0)
	end
end

function var_0_0.updateEcoByIdx(arg_82_0, arg_82_1, arg_82_2)
	local var_82_0 = arg_82_1:nodeByName("txt_eco_val_" .. arg_82_2):getString()
	local var_82_1

	if arg_82_2 == 1 then
		var_82_1 = tostring(arg_82_0.selfPlayer:getBackpack():getItemNumByID(var_0_10))
	elseif arg_82_2 == 2 then
		var_82_1 = xyd.num2ThousandsStr(arg_82_0.selfPlayer.crystal)
	elseif arg_82_2 == 3 then
		var_82_1 = tostring(arg_82_0.selfPlayer:getBackpack():getItemNumByID(var_0_11))
	end

	if var_82_0 == var_82_1 then
		return
	end

	arg_82_1:nodeByName("txt_eco_val_" .. arg_82_2):setString(var_82_1)

	local var_82_2 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_82_3 = cc.Spawn:create(var_82_2)

	arg_82_1:nodeByName("txt_eco_val_" .. arg_82_2):runAction(var_82_3)
end

function var_0_0.scrollListener(arg_83_0, arg_83_1)
	if arg_83_1.name == "began" then
		arg_83_0.scrollViewMove_ = false
		arg_83_0.prevY_ = arg_83_1.y
	elseif arg_83_1.name == "moved" and 5 < math.abs(arg_83_1.y - arg_83_0.prevY_) then
		arg_83_0.scrollViewMove_ = true
	end
end

function var_0_0.willClose(arg_84_0)
	if arg_84_0.showBarrageHandler then
		var_0_1.unscheduleGlobal(arg_84_0.showBarrageHandler)

		arg_84_0.showBarrageHandler = nil
	end

	if arg_84_0.gameHandler then
		var_0_1.unscheduleGlobal(arg_84_0.gameHandler)

		arg_84_0.gameHandler = nil
	end

	if arg_84_0.loadBarrageHandler then
		var_0_1.unscheduleGlobal(arg_84_0.loadBarrageHandler)

		arg_84_0.loadBarrageHandler = nil
	end

	arg_84_0.barrageInfos = {}
	arg_84_0.isShowingBarrage = false
	arg_84_0.isCatching = false
end

return var_0_0
