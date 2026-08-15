local var_0_0 = class("AllNightLightGachaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.activityPolarNightPoolAward
local var_0_4 = xyd.tables.misc
local var_0_5 = 5
local var_0_6 = var_0_4:getValue("activity_polar_night_pool_coin")[1]
local var_0_7 = var_0_4:getValue("activity_polar_night_pool_cost_nums")
local var_0_8 = var_0_7 * 10
local var_0_9 = var_0_4:getValue("activity_polar_night_pool_last_pool")
local var_0_10 = 0.02
local var_0_11 = {
	blue = 1,
	purple = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.allNight = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.pool_info = arg_1_2
	arg_1_0.pool = math.min(arg_1_0.pool_info.base_info.pool_id, var_0_9)
	arg_1_0.drop_info = arg_1_0.pool_info.drop_info
	arg_1_0.isPlayingEffect = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		ecoCount = 1,
		show_rule = true,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_6
		},
		ecoIcons = {
			"windows/activities/1199/gacha/coin_2.png"
		},
		callback = handler(arg_2_0, arg_2_0.close)
	})

	arg_2_0.ecoSidebar = arg_2_0:nodeByName("eco_sidebar")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_num_one"):setString(var_0_7)
	arg_3_0:nodeByName("txt_num_ten"):setString(var_0_8)
	arg_3_0:nodeByName("txt_one"):setString(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT3"))
	arg_3_0:nodeByName("txt_ten"):setString(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT4"))

	local var_3_0 = arg_3_0:nodeByName("list"):getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	xyd.nodeEventSample(arg_3_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function(arg_4_0)
		local var_4_0 = {}

		var_4_0.title_name = "ACTIVITY_POLAR_NIGHT_GACHA_TEXT13"
		var_4_0.rule = "ACTIVITY_POLAR_NIGHT_GACHA_TEXT14"
		var_4_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
	end)

	local var_3_1 = "skeletons/ui_effect/activity_all_night/niudanji"

	arg_3_0.effect = xyd.createEffect(var_3_1)

	arg_3_0.effect:addTo(arg_3_0:nodeByName("pos_gacha"))
	arg_3_0:initButton()
	arg_3_0:updateLeft()
	arg_3_0:updateEco()
end

function var_0_0.initButton(arg_5_0)
	arg_5_0:nodeByName("btn_one"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_5_0.isPlayingEffect then
				return
			end

			if arg_5_0.backpack:getItemNumByID(var_0_6) < var_0_7 then
				local var_6_0 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT23")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_0
				})

				return
			end

			if arg_5_0.purpleShow.count + arg_5_0.blueShow.count > 0 then
				local var_6_1 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT20")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_1, function()
					arg_5_0.allNight:lightGachaDraw({
						times = 1
					}, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							local var_8_0 = {
								itemID = var_0_6,
								itemNum = var_0_7
							}

							arg_5_0.backpack:removeItem(var_8_0)
							arg_5_0:updateEco()

							arg_5_0.awards = arg_8_1.awards

							local var_8_1 = arg_8_1.awards[1].table_id
							local var_8_2 = var_0_3:getPurpleIds(arg_5_0.pool)
							local var_8_3

							for iter_8_0 = 1, #var_8_2 do
								if var_0_3:itemId(var_8_2[iter_8_0]) == var_8_1 then
									if iter_8_0 == 1 then
										var_8_3 = "fenqiu"

										break
									else
										var_8_3 = "ziqiu"

										break
									end
								end
							end

							var_8_3 = var_8_3 or "lanqiu"
							arg_5_0.isPlayingEffect = true

							arg_5_0.effect:play(function()
								arg_5_0.selfPlayer:handleRewards(arg_5_0.awards)

								arg_5_0.awards = nil
								arg_5_0.drop_info = arg_8_1.drop_info

								arg_5_0:updateLeft()

								arg_5_0.isPlayingEffect = false
							end, false, 0.5, var_8_3)
						end
					end)
				end)
			else
				local var_6_2 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT19")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_2
				})
			end
		end
	end)
	arg_5_0:nodeByName("btn_ten"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			if arg_5_0.isPlayingEffect then
				return
			end

			if arg_5_0.backpack:getItemNumByID(var_0_6) < var_0_8 then
				local var_10_0 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT23")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_10_0
				})

				return
			end

			if arg_5_0.purpleShow.count + arg_5_0.blueShow.count >= 10 then
				local var_10_1 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT21")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_1, function()
					arg_5_0.allNight:lightGachaDraw({
						times = 10
					}, function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							local var_12_0 = {
								itemID = var_0_6,
								itemNum = var_0_8
							}

							arg_5_0.backpack:removeItem(var_12_0)
							arg_5_0:updateEco()

							arg_5_0.awards = arg_12_1.awards

							local var_12_1 = arg_12_1.awards
							local var_12_2 = var_0_3:getPurpleIds(arg_5_0.pool)
							local var_12_3 = var_0_3:itemId(var_12_2[1])
							local var_12_4 = {}

							for iter_12_0 = 2, #var_12_2 do
								var_12_4[var_0_3:itemId(var_12_2[iter_12_0])] = 1
							end

							local var_12_5

							for iter_12_1 = 1, #var_12_1 do
								if var_12_1[iter_12_1].table_id == var_12_3 then
									var_12_5 = "fenqiu"

									break
								elseif var_12_4[var_12_1[iter_12_1].table_id] then
									var_12_5 = "ziqiu"
								end
							end

							var_12_5 = var_12_5 or "lanqiu"
							arg_5_0.isPlayingEffect = true

							arg_5_0.effect:play(function()
								arg_5_0.selfPlayer:handleRewards(arg_5_0.awards)

								arg_5_0.awards = nil
								arg_5_0.drop_info = arg_12_1.drop_info

								arg_5_0:updateLeft()

								arg_5_0.isPlayingEffect = false
							end, false, 0.5, var_12_5)
						end
					end)
				end)
			else
				local var_10_2 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT18")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_10_2
				})
			end
		end
	end)
	arg_5_0:nodeByName("btn_next"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			if arg_5_0.isPlayingEffect then
				return
			end

			if arg_5_0.purpleShow.count + arg_5_0.blueShow.count == 0 then
				arg_5_0.allNight:lightGachaNextPool(nil, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						arg_5_0.pool = math.min(arg_15_1.base_info.pool_id, var_0_9)
						arg_5_0.drop_info = arg_15_1.drop_info

						arg_5_0:updateLeft(true)
					else
						local var_15_0 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT22")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_15_0
						})
					end
				end)
			else
				local var_14_0 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT22")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_0
				})
			end
		end
	end)
end

function var_0_0.updateListItem(arg_16_0, arg_16_1)
	arg_16_0.list:removeAllItems()

	local var_16_0 = 2 + math.ceil(#arg_16_0.purpleShow / var_0_5) + math.ceil(#arg_16_0.blueShow / var_0_5)

	for iter_16_0 = 1, var_16_0 do
		local var_16_1 = arg_16_0.list:dequeueItem()

		if not var_16_1 then
			var_16_1 = arg_16_0.list:newItem()
		else
			var_16_1:removeAllChildren(true)
		end

		local var_16_2 = arg_16_0:createListContent(iter_16_0, arg_16_1)
		local var_16_3 = var_16_2:getContentSize()

		var_16_1:addContent(var_16_2)
		var_16_1:setContentSize(var_16_3)
		var_16_1:setItemSize(var_16_3.width, var_16_3.height + 2)
		arg_16_0.list:addItem(var_16_1)
	end

	arg_16_0.list:reload()
end

function var_0_0.createListContent(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = display.newNode()
	local var_17_1 = arg_17_0.list:getViewRect().width
	local var_17_2 = math.ceil(#arg_17_0.purpleShow / var_0_5)
	local var_17_3 = #arg_17_0.purpleShow

	if arg_17_1 == 1 or arg_17_1 == 2 + var_17_2 then
		local var_17_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/gacha/reward_title.csb")
		local var_17_5 = var_17_4:getChildByName("container")
		local var_17_6 = var_17_5:getContentSize().height

		var_17_0:setContentSize(var_17_1, var_17_6)
		var_17_4:addTo(var_17_0)
		var_17_4:setPosition(2, 0)

		local var_17_7
		local var_17_8

		if arg_17_1 == 1 then
			var_17_5:getChildByName("bg_tag_blue"):setVisible(false)

			local var_17_9 = arg_17_0.purpleShow.count .. "/" .. #arg_17_0.purpleShow

			var_17_8 = string.format(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT15"), var_17_9)

			if arg_17_2 then
				xyd.setItemAnimation(var_17_4, 1, var_0_10)
			end
		else
			var_17_5:getChildByName("bg_tag_purple"):setVisible(false)

			local var_17_10 = arg_17_0.blueShow.count .. "/" .. #arg_17_0.blueShow

			var_17_8 = string.format(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT16"), var_17_10)

			if arg_17_2 then
				xyd.setItemAnimation(var_17_4, 2 + var_17_3, var_0_10)
			end
		end

		var_17_5:getChildByName("txt"):setString(var_17_8)

		return var_17_0
	elseif arg_17_1 <= 1 + var_17_2 then
		local var_17_11 = 148
		local var_17_12 = 4
		local var_17_13 = 0
		local var_17_14 = 2

		var_17_0:setContentSize(var_17_1, var_17_11)

		for iter_17_0 = 1, var_0_5 do
			local var_17_15 = (arg_17_1 - 2) * var_0_5 + iter_17_0

			if not arg_17_0.purpleShow[var_17_15] then
				break
			end

			local var_17_16 = arg_17_0.purpleShow[var_17_15]
			local var_17_17 = var_0_3:itemId(var_17_16)
			local var_17_18 = var_0_3:itemNum(var_17_16)
			local var_17_19
			local var_17_20 = not (var_17_15 <= arg_17_0.purpleShow.count)
			local var_17_21 = arg_17_0:createItem(var_17_17, var_17_18, var_0_11.purple, var_17_20)

			var_17_21:addTo(var_17_0)
			var_17_21:setPosition(var_17_12, var_17_13)

			if arg_17_2 then
				xyd.setItemAnimation(var_17_21, 1 + var_17_15, var_0_10)
			end

			var_17_12 = var_17_12 + var_17_21:getChildByName("container"):getContentSize().width + var_17_14
		end

		return var_17_0
	else
		local var_17_22 = 148
		local var_17_23 = 4
		local var_17_24 = 0
		local var_17_25 = 2

		var_17_0:setContentSize(var_17_1, var_17_22)

		for iter_17_1 = 1, var_0_5 do
			local var_17_26 = (arg_17_1 - 3 - var_17_2) * var_0_5 + iter_17_1

			if not arg_17_0.blueShow[var_17_26] then
				break
			end

			local var_17_27 = arg_17_0.blueShow[var_17_26]
			local var_17_28 = var_0_3:itemId(var_17_27)
			local var_17_29 = var_0_3:itemNum(var_17_27)
			local var_17_30
			local var_17_31 = not (var_17_26 <= arg_17_0.blueShow.count)
			local var_17_32 = arg_17_0:createItem(var_17_28, var_17_29, var_0_11.blue, var_17_31)

			var_17_32:addTo(var_17_0)
			var_17_32:setPosition(var_17_23, var_17_24)

			if arg_17_2 then
				xyd.setItemAnimation(var_17_32, 2 + var_17_3 + var_17_26, var_0_10)
			end

			var_17_23 = var_17_23 + var_17_32:getChildByName("container"):getContentSize().width + var_17_25
		end

		return var_17_0
	end
end

function var_0_0.createItem(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4)
	local var_18_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/gacha/gacha_item.csb")
	local var_18_1 = var_18_0:getChildByName("container")
	local var_18_2 = var_18_1:getChildByName("item")
	local var_18_3 = display.newNode()

	var_18_3:setContentSize(var_18_2:getContentSize())
	xyd.setItemBorder(var_18_3, arg_18_1, nil, nil, arg_18_2)
	var_18_3:addTo(var_18_2)
	var_18_3:setAnchorPoint(0, 0)
	var_18_3:setPosition(0, 0)

	if arg_18_3 == var_0_11.blue then
		var_18_1:getChildByName("bg_purple"):setVisible(false)
	elseif arg_18_3 == var_0_11.purple then
		var_18_1:getChildByName("bg_blue"):setVisible(false)
	end

	local var_18_4 = var_0_2:name(arg_18_1)

	var_18_1:getChildByName("txt_name"):setString(var_18_4)

	local var_18_5 = {
		id = arg_18_1,
		lev = var_0_2:level(arg_18_1)
	}

	if var_0_2:type(arg_18_1) == -1 then
		var_18_5.tipsType = 0
		var_18_5.desc1 = xyd.tables.hero:getDes(arg_18_1)
	else
		var_18_5.tipsType = 1
		var_18_5.desc1 = var_0_2:desc1(arg_18_1)
		var_18_5.desc2 = var_0_2:desc2(arg_18_1)
	end

	var_18_5.hasNum = arg_18_0.backpack:getItemNumByID(arg_18_1)
	var_18_5.name = var_0_2:name(arg_18_1)

	arg_18_0:addTips(var_18_3, var_18_5)

	if arg_18_4 then
		var_18_1:getChildByName("gray"):setVisible(true)
	end

	return var_18_0
end

function var_0_0.updateEco(arg_19_0)
	local var_19_0 = {
		true
	}

	arg_19_0.ecoSidebar:update(var_19_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.ALL_NIGHT_ECONOMY_UPDATE
	})
end

function var_0_0.updateLeft(arg_20_0, arg_20_1)
	local var_20_0 = var_0_3:getPurpleIds(arg_20_0.pool)
	local var_20_1 = var_0_3:getBlueIds(arg_20_0.pool)

	arg_20_0.purpleShow = {}
	arg_20_0.blueShow = {}

	local var_20_2 = {}
	local var_20_3 = {}

	for iter_20_0, iter_20_1 in ipairs(var_20_0) do
		if arg_20_0.drop_info[tostring(iter_20_1)] then
			table.insert(var_20_3, iter_20_1)
		else
			table.insert(var_20_2, iter_20_1)
		end
	end

	local var_20_4 = #var_20_2

	for iter_20_2 = 1, var_20_4 do
		arg_20_0.purpleShow[iter_20_2] = var_20_2[iter_20_2]
	end

	for iter_20_3 = 1, #var_20_3 do
		arg_20_0.purpleShow[var_20_4 + iter_20_3] = var_20_3[iter_20_3]
	end

	arg_20_0.purpleShow.count = var_20_4

	local var_20_5 = {}
	local var_20_6 = {}

	for iter_20_4, iter_20_5 in ipairs(var_20_1) do
		if arg_20_0.drop_info[tostring(iter_20_5)] then
			table.insert(var_20_6, iter_20_5)
		else
			table.insert(var_20_5, iter_20_5)
		end
	end

	local var_20_7 = #var_20_5

	for iter_20_6 = 1, var_20_7 do
		arg_20_0.blueShow[iter_20_6] = var_20_5[iter_20_6]
	end

	for iter_20_7 = 1, #var_20_6 do
		arg_20_0.blueShow[var_20_7 + iter_20_7] = var_20_6[iter_20_7]
	end

	arg_20_0.blueShow.count = var_20_7

	arg_20_0:updateListItem(arg_20_1)
end

function var_0_0.scrollListener(arg_21_0, arg_21_1)
	if arg_21_1.name == "began" then
		arg_21_0.scrollViewMoved_ = false
		arg_21_0.prevY_ = arg_21_1.y
	elseif arg_21_1.name == "moved" and 20 <= math.abs(arg_21_0.prevY_ - arg_21_1.y) then
		arg_21_0.scrollViewMoved_ = true
	end
end

function var_0_0.close(arg_22_0)
	if arg_22_0.awards then
		arg_22_0.selfPlayer:handleRewards(arg_22_0.awards)
	end

	xyd.WindowManager.get():closeWindow(arg_22_0)
end

return var_0_0
