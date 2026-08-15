local var_0_0 = class("AllNightDarkGachaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.gift
local var_0_6 = 5
local var_0_7 = var_0_4:getValue("activity_polar_night_gacha_coin")[1]
local var_0_8 = 1
local var_0_9 = var_0_8 * 10
local var_0_10 = var_0_4:getValue("activity_polar_night_gacha_times")
local var_0_11 = 0.02
local var_0_12 = {
	xyd.tables.activityPolarNightGacha,
	xyd.tables.activityPolarNightGacha2
}
local var_0_13 = {
	var_0_4:getValue("activity_polar_night_gacha_item")[1],
	var_0_4:getValue("activity_polar_night_gacha_item2")[1]
}
local var_0_14 = {
	blue = 1,
	purple = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.allNight = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.award_times = arg_1_2.award_times
	arg_1_0.pool = 1
	arg_1_0.isPlayingEffect = false
	arg_1_0.newIsOpen = var_0_4:getValue("activity_polar_night_gacha_new_is_open") ~= 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		ecoCount = 1,
		show_rule = true,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_7
		},
		ecoIcons = {
			"windows/activities/1199/gacha/coin_1.png"
		},
		callback = handler(arg_2_0, arg_2_0.close)
	})

	arg_2_0.ecoSidebar = arg_2_0:nodeByName("eco_sidebar")

	arg_2_0:addBuyButton()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_gift"):enableOutline(cc.c4b(52, 54, 55, 255), 2)
	arg_3_0:nodeByName("txt_num_one"):setString(var_0_8)
	arg_3_0:nodeByName("txt_num_ten"):setString(var_0_9)
	arg_3_0:nodeByName("txt_one"):setString(var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT3"))
	arg_3_0:nodeByName("txt_ten"):setString(var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT4"))

	local var_3_0 = arg_3_0:nodeByName("list"):getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0:updateList()
	xyd.nodeEventSample(arg_3_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function(arg_4_0)
		local var_4_0 = {}

		var_4_0.title_name = "ACTIVITY_POLAR_NIGHT_GACHA_TEXT11"
		var_4_0.rule = "ACTIVITY_POLAR_NIGHT_GACHA_TEXT12"
		var_4_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
	end)

	local var_3_1 = "skeletons/ui_effect/activity_all_night/anniudanji"

	arg_3_0.effect = xyd.createEffect(var_3_1)

	arg_3_0.effect:addTo(arg_3_0:nodeByName("pos_gacha"))

	local var_3_2 = "skeletons/ui_effect/activity_all_night/baoxiang"

	arg_3_0.giftEffect = xyd.createEffect(var_3_2)

	arg_3_0.giftEffect:addTo(arg_3_0:nodeByName("gift_pos"))
	arg_3_0.giftEffect:play(nil, true)
	arg_3_0:nodeByName("btn_switch"):setVisible(arg_3_0.newIsOpen)
	arg_3_0:updateGiftTip()
	arg_3_0:initButton()
	arg_3_0:updateEco()
	arg_3_0:updateGachaTimes()
end

function var_0_0.initButton(arg_5_0)
	arg_5_0:nodeByName("btn_one"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_5_0.isPlayingEffect then
				return
			end

			if arg_5_0.backpack:getItemNumByID(var_0_7) < var_0_8 then
				local var_6_0 = var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT24")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
					xyd.WindowManager.get():openWindow("all_night_dark_gacha_alert", {
						callback = handler(arg_5_0, arg_5_0.updateEco)
					})
				end)

				return
			end

			local var_6_1 = var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT20")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_1, function()
				arg_5_0.allNight:darkGachaDraw({
					times = 1,
					sub_id = arg_5_0.pool
				}, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						local var_9_0 = {
							itemNum = 1,
							itemID = var_0_7
						}

						arg_5_0.backpack:removeItem(var_9_0)

						arg_5_0.award_times = arg_9_1.award_times

						arg_5_0:updateEco()
						arg_5_0:updateGachaTimes()

						arg_5_0.awards = arg_9_1.awards

						local var_9_1 = arg_9_1.awards[1].table_id
						local var_9_2 = var_0_12[arg_5_0.pool]:getPurpleIds()
						local var_9_3

						for iter_9_0 = 1, #var_9_2 do
							if var_0_12[arg_5_0.pool]:itemId(var_9_2[iter_9_0]) == var_9_1 then
								if iter_9_0 == 1 then
									var_9_3 = "fenqiu"

									break
								else
									var_9_3 = "ziqiu"

									break
								end
							end
						end

						var_9_3 = var_9_3 or "lanqiu"
						arg_5_0.isPlayingEffect = true

						arg_5_0:nodeByName("btn_switch"):setVisible(false)
						arg_5_0.effect:play(function()
							arg_5_0.selfPlayer:handleRewards(arg_5_0.awards)

							arg_5_0.awards = nil
							arg_5_0.isPlayingEffect = false

							arg_5_0:nodeByName("btn_switch"):setVisible(arg_5_0.newIsOpen)
						end, false, 0.5, var_9_3)
					end
				end)
			end)
		end
	end)
	arg_5_0:nodeByName("btn_ten"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			if arg_5_0.isPlayingEffect then
				return
			end

			if arg_5_0.backpack:getItemNumByID(var_0_7) < var_0_9 then
				local var_11_0 = var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT24")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_0, function()
					xyd.WindowManager.get():openWindow("all_night_dark_gacha_alert", {
						callback = handler(arg_5_0, arg_5_0.updateEco)
					})
				end)

				return
			end

			local var_11_1 = var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT21")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_1, function()
				arg_5_0.allNight:darkGachaDraw({
					times = 10,
					sub_id = arg_5_0.pool
				}, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						local var_14_0 = {
							itemNum = 10,
							itemID = var_0_7
						}

						arg_5_0.backpack:removeItem(var_14_0)

						arg_5_0.award_times = arg_14_1.award_times

						arg_5_0:updateEco()
						arg_5_0:updateGachaTimes()

						arg_5_0.awards = arg_14_1.awards

						local var_14_1 = arg_14_1.awards
						local var_14_2 = var_0_12[arg_5_0.pool]:getPurpleIds()
						local var_14_3 = var_0_12[arg_5_0.pool]:itemId(var_14_2[1])
						local var_14_4 = {}

						for iter_14_0 = 2, #var_14_2 do
							var_14_4[var_0_12[arg_5_0.pool]:itemId(var_14_2[iter_14_0])] = 1
						end

						local var_14_5

						for iter_14_1 = 1, #var_14_1 do
							if var_14_1[iter_14_1].table_id == var_14_3 then
								var_14_5 = "fenqiu"

								break
							elseif var_14_4[var_14_1[iter_14_1].table_id] then
								var_14_5 = "ziqiu"
							end
						end

						var_14_5 = var_14_5 or "lanqiu"
						arg_5_0.isPlayingEffect = true

						arg_5_0:nodeByName("btn_switch"):setVisible(false)
						arg_5_0.effect:play(function()
							arg_5_0.selfPlayer:handleRewards(arg_5_0.awards)

							arg_5_0.awards = nil
							arg_5_0.isPlayingEffect = false

							arg_5_0:nodeByName("btn_switch"):setVisible(arg_5_0.newIsOpen)
						end, false, 0.5, var_14_5)
					end
				end)
			end)
		end
	end)

	arg_5_0.gift = arg_5_0:nodeByName("gift")

	arg_5_0.gift:setTouchEnabled(true)
	arg_5_0.gift:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			arg_5_0:nodeByName("gift_tip"):setVisible(true)

			return true
		elseif arg_16_0.name == "ended" then
			arg_5_0:nodeByName("gift_tip"):setVisible(false)
		end
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_switch"), nil, function()
		arg_5_0.pool = 3 - arg_5_0.pool

		arg_5_0:updateList(true)
		arg_5_0:updateGiftTip()
	end)

	local var_5_0 = display.newNode()

	var_5_0:setContentSize(arg_5_0:nodeByName("gift"):getContentSize())
	var_5_0:addTo(arg_5_0:nodeByName("gift_pos"))
	var_5_0:setAnchorPoint(0.5, 0.5)
	var_5_0:setTouchEnabled(true)
	var_5_0:setTouchSwallowEnabled(false)
	xyd.nodeEventSample(var_5_0, nil, function(arg_18_0)
		if arg_5_0.isPlayingEffect or arg_5_0.award_times < var_0_10 then
			return
		end

		arg_5_0.allNight:darkGachaGetExtra({
			sub_id = arg_5_0.pool
		}, function(arg_19_0, arg_19_1)
			if arg_19_0 == xyd.error.OK then
				arg_5_0.award_times = arg_19_1.award_times

				arg_5_0:updateGachaTimes()
				arg_5_0.selfPlayer:handleRewards(arg_19_1.awards[1])
			end
		end)
	end)
end

function var_0_0.updateGiftTip(arg_20_0)
	local var_20_0 = var_0_13[arg_20_0.pool]
	local var_20_1 = var_0_5:items(var_20_0)
	local var_20_2 = var_0_5:itemNum(var_20_0)
	local var_20_3 = arg_20_0:nodeByName("gift_tip"):getContentSize()

	arg_20_0:nodeByName("gift_tip"):removeAllChildren()
	arg_20_0:nodeByName("gift_tip"):setContentSize(var_20_3.width, 60 * #var_20_1 + 70)

	for iter_20_0, iter_20_1 in ipairs(var_20_1) do
		local var_20_4 = display.newNode()

		var_20_4:setContentSize(cc.size(60, 60))
		xyd.setItemBorder(var_20_4, iter_20_1)
		var_20_4:addTo(arg_20_0:nodeByName("gift_tip"))
		var_20_4:setPosition(cc.p(40, 70 * iter_20_0 - 40))

		local var_20_5 = {
			size = 20,
			color = cc.c3b(255, 255, 255)
		}
		local var_20_6 = xyd.AssetLoader.get():loadLabel(var_20_5)

		var_20_6:setMaxLineWidth(70)
		var_20_6:setLineHeight(49)
		var_20_6:setString("x " .. var_20_2[iter_20_0])
		var_20_6:addTo(arg_20_0:nodeByName("gift_tip"))
		var_20_6:setPosition(cc.p(110, 70 * iter_20_0 - 25))
	end
end

function var_0_0.updateList(arg_21_0, arg_21_1)
	local var_21_0 = var_0_12[arg_21_0.pool]:getPurpleIds()
	local var_21_1 = var_0_12[arg_21_0.pool]:getBlueIds()

	arg_21_0.list:removeAllItems()

	for iter_21_0 = 1, 2 + math.ceil(#var_21_0 / var_0_6) + math.ceil(#var_21_1 / var_0_6) do
		local var_21_2 = arg_21_0.list:dequeueItem()

		if not var_21_2 then
			var_21_2 = arg_21_0.list:newItem()
		else
			var_21_2:removeAllChildren(true)
		end

		local var_21_3 = arg_21_0:createListContent(iter_21_0, arg_21_1)
		local var_21_4 = var_21_3:getContentSize()

		var_21_2:addContent(var_21_3)
		var_21_2:setContentSize(var_21_4)
		var_21_2:setItemSize(var_21_4.width, var_21_4.height + 2)
		arg_21_0.list:addItem(var_21_2)
	end

	arg_21_0.list:reload()
end

function var_0_0.createListContent(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = display.newNode()
	local var_22_1 = arg_22_0.list:getViewRect().width
	local var_22_2 = var_0_12[arg_22_0.pool]:getPurpleIds()
	local var_22_3 = var_0_12[arg_22_0.pool]:getBlueIds()
	local var_22_4 = math.ceil(#var_22_2 / var_0_6)
	local var_22_5 = #var_22_2

	if arg_22_1 == 1 or arg_22_1 == 2 + var_22_4 then
		local var_22_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/gacha/reward_title.csb")
		local var_22_7 = var_22_6:getChildByName("container")
		local var_22_8 = var_22_7:getContentSize().height

		var_22_0:setContentSize(var_22_1, var_22_8)
		var_22_6:addTo(var_22_0)
		var_22_6:setPosition(2, 0)

		if arg_22_1 == 1 then
			var_22_7:getChildByName("bg_tag_blue"):setVisible(false)
			var_22_7:getChildByName("txt"):setString(var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT5"))

			if arg_22_2 then
				xyd.setItemAnimation(var_22_6, 1, var_0_11)
			end
		else
			var_22_7:getChildByName("bg_tag_purple"):setVisible(false)
			var_22_7:getChildByName("txt"):setString(var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT6"))

			if arg_22_2 then
				xyd.setItemAnimation(var_22_6, 2 + var_22_5, var_0_11)
			end
		end

		return var_22_0
	elseif arg_22_1 <= 1 + var_22_4 then
		local var_22_9 = 148
		local var_22_10 = 4
		local var_22_11 = 0
		local var_22_12 = 2

		var_22_0:setContentSize(var_22_1, var_22_9)

		for iter_22_0 = 1, var_0_6 do
			local var_22_13 = (arg_22_1 - 2) * var_0_6 + iter_22_0

			if not var_22_2[var_22_13] then
				break
			end

			local var_22_14 = var_22_2[var_22_13]
			local var_22_15 = var_0_12[arg_22_0.pool]:itemId(var_22_14)
			local var_22_16 = var_0_12[arg_22_0.pool]:itemNum(var_22_14)
			local var_22_17 = arg_22_0:createItem(var_22_15, var_22_16, var_0_14.purple)

			var_22_17:addTo(var_22_0)
			var_22_17:setPosition(var_22_10, var_22_11)

			if arg_22_2 then
				xyd.setItemAnimation(var_22_17, 1 + var_22_13, var_0_11)
			end

			var_22_10 = var_22_10 + var_22_17:getChildByName("container"):getContentSize().width + var_22_12
		end

		return var_22_0
	else
		local var_22_18 = 148
		local var_22_19 = 4
		local var_22_20 = 0
		local var_22_21 = 2

		var_22_0:setContentSize(var_22_1, var_22_18)

		for iter_22_1 = 1, var_0_6 do
			local var_22_22 = (arg_22_1 - 3 - var_22_4) * var_0_6 + iter_22_1

			if not var_22_3[var_22_22] then
				break
			end

			local var_22_23 = var_22_3[var_22_22]
			local var_22_24 = var_0_12[arg_22_0.pool]:itemId(var_22_23)
			local var_22_25 = var_0_12[arg_22_0.pool]:itemNum(var_22_23)
			local var_22_26 = arg_22_0:createItem(var_22_24, var_22_25, var_0_14.blue)

			var_22_26:addTo(var_22_0)
			var_22_26:setPosition(var_22_19, var_22_20)

			if arg_22_2 then
				xyd.setItemAnimation(var_22_26, 2 + var_22_5 + var_22_22, var_0_11)
			end

			var_22_19 = var_22_19 + var_22_26:getChildByName("container"):getContentSize().width + var_22_21
		end

		return var_22_0
	end
end

function var_0_0.createItem(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	local var_23_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/gacha/gacha_item.csb")
	local var_23_1 = var_23_0:getChildByName("container")
	local var_23_2 = var_23_1:getChildByName("item")
	local var_23_3 = display.newNode()

	var_23_3:setContentSize(var_23_2:getContentSize())
	xyd.setItemBorder(var_23_3, arg_23_1, nil, nil, arg_23_2)
	var_23_3:addTo(var_23_2)
	var_23_3:setAnchorPoint(0, 0)
	var_23_3:setPosition(0, 0)

	if arg_23_3 == var_0_14.blue then
		var_23_1:getChildByName("bg_purple"):setVisible(false)
	elseif arg_23_3 == var_0_14.purple then
		var_23_1:getChildByName("bg_blue"):setVisible(false)
	end

	local var_23_4 = var_0_3:name(arg_23_1)

	var_23_1:getChildByName("txt_name"):setString(var_23_4)

	local var_23_5 = {
		id = arg_23_1,
		lev = var_0_3:level(arg_23_1)
	}

	if var_0_3:type(arg_23_1) == -1 then
		var_23_5.tipsType = 0
		var_23_5.desc1 = xyd.tables.hero:getDes(arg_23_1)
	else
		var_23_5.tipsType = 1
		var_23_5.desc1 = var_0_3:desc1(arg_23_1)
		var_23_5.desc2 = var_0_3:desc2(arg_23_1)
	end

	var_23_5.hasNum = arg_23_0.backpack:getItemNumByID(arg_23_1)
	var_23_5.name = var_0_3:name(arg_23_1)

	arg_23_0:addTips(var_23_3, var_23_5)

	return var_23_0
end

function var_0_0.scrollListener(arg_24_0, arg_24_1)
	if arg_24_1.name == "began" then
		arg_24_0.scrollViewMoved_ = false
		arg_24_0.prevY_ = arg_24_1.y
	elseif arg_24_1.name == "moved" and 20 <= math.abs(arg_24_0.prevY_ - arg_24_1.y) then
		arg_24_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateEco(arg_25_0)
	local var_25_0 = {
		true
	}

	arg_25_0.ecoSidebar:update(var_25_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.ALL_NIGHT_ECONOMY_UPDATE
	})
end

function var_0_0.updateGachaTimes(arg_26_0)
	local var_26_0 = arg_26_0.award_times .. "/" .. var_0_10
	local var_26_1 = string.format(var_0_2:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT7"), var_26_0)

	arg_26_0:nodeByName("txt_gift"):setString(var_26_1)
	arg_26_0:nodeByName("gift"):setVisible(arg_26_0.award_times < var_0_10)
	arg_26_0.giftEffect:setVisible(arg_26_0.award_times >= var_0_10)
end

function var_0_0.addBuyButton(arg_27_0)
	local var_27_0 = "windows/button/btn_add_eco.png"
	local var_27_1 = xyd.tables.systemColor:btnColors(arg_27_0.colorMode)
	local var_27_2 = {
		sprite = var_27_0,
		colorModes = var_27_1
	}
	local var_27_3 = var_0_1.new(var_27_2)
	local var_27_4 = arg_27_0.ecoSidebar:nodeByName("eco_1"):getContentSize()

	var_27_3:setAnchorPoint(0.5, 0.5)
	var_27_3:addTo(arg_27_0.ecoSidebar:nodeByName("eco_1"))
	var_27_3:setPosition(var_27_4.width - 18, var_27_4.height / 2)

	local function var_27_5()
		arg_27_0:updateEco()
	end

	var_27_3:addTouchEvent(function(arg_29_0)
		if arg_29_0.name == "ended" then
			if arg_27_0.isPlayingEffect then
				return
			end

			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("all_night_dark_gacha_alert", {
				callback = var_27_5
			})
		end
	end)
end

function var_0_0.close(arg_30_0)
	if arg_30_0.awards then
		arg_30_0.selfPlayer:handleRewards(arg_30_0.awards)
	end

	xyd.WindowManager.get():closeWindow(arg_30_0)
end

return var_0_0
