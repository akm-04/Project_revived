local var_0_0 = class("StarTreasureMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("app.model.Hero")
local var_0_4 = 5
local var_0_5 = 10001218

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.starTreasure = xyd.ModelManager.get():loadModel(xyd.ModelType.STAR_TREASURE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.canClick = true
	arg_1_0.selectItem = 0
end

function var_0_0.updateDownContainer(arg_2_0)
	arg_2_0.downList_:removeAllItems()

	local var_2_0 = true

	for iter_2_0, iter_2_1 in pairs(xyd.tables.starTreasureItem:getIds()) do
		local var_2_1 = xyd.tables.starTreasureItem:itemId(iter_2_1)
		local var_2_2 = arg_2_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.starTreasureItem:itemId(iter_2_1))

		if var_2_2 > 0 then
			if arg_2_0.selectItem == 0 then
				arg_2_0.selectItem = iter_2_1
			end

			var_2_0 = false

			arg_2_0:addCategory(var_2_1, var_2_2, nil, iter_2_1)
		end
	end

	if var_2_0 == true then
		arg_2_0.selectItem = 0
	end

	arg_2_0.downList_:reload()
end

function var_0_0.updateMidContainer(arg_3_0)
	arg_3_0.midList_:removeAllItems()

	for iter_3_0, iter_3_1 in pairs(xyd.tables.starTreasureExplore:specialItem(arg_3_0.starTreasure.currentFloor)) do
		local var_3_0 = xyd.tables.starTreasureExplore:specialNum(arg_3_0.starTreasure.currentFloor)[iter_3_0]
		local var_3_1 = 0

		for iter_3_2, iter_3_3 in pairs(arg_3_0.starTreasure.awardStatus) do
			if tonumber(iter_3_2) == iter_3_1 and iter_3_3 == 1 then
				var_3_1 = 1

				break
			end
		end

		arg_3_0:addCategory(iter_3_1, var_3_0, var_3_1)
	end

	arg_3_0.midList_:reload()
end

function var_0_0.addCategory(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0
	local var_4_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/star_treasure/star_treasure_main/gezi/item_block.csb")

	var_4_1:setAnchorPoint(cc.p(0, 0))
	var_4_1:setPosition(cc.p(0, 0))
	var_4_1:setContentSize(100, 100)

	local var_4_2 = {
		id = arg_4_1,
		hasNum = arg_4_0.selfPlayer:getBackpack():getItemNumByID(arg_4_1)
	}

	var_4_1:getChildByName("equip_bg"):setVisible(false)
	var_4_1:getChildByName("had_bg"):setVisible(false)

	if not arg_4_3 then
		var_4_0 = arg_4_0.downList_:newItem()

		if arg_4_4 == arg_4_0.selectItem then
			var_4_1:getChildByName("equip_bg"):setVisible(true)
		end
	else
		var_4_0 = arg_4_0.midList_:newItem()

		if arg_4_3 == 1 then
			var_4_1:getChildByName("had_bg"):setVisible(true)
		end
	end

	local var_4_3 = display.newNode()

	var_4_3:setContentSize(var_4_1:getChildByName("container"):getWidth(), var_4_1:getChildByName("container"):getHeight())
	var_4_3:setTouchEnabled(true)
	var_4_3:setTouchSwallowEnabled(false)
	var_4_3:setAnchorPoint(cc.p(0, 0))
	var_4_3:setPosition(0, 0)

	local var_4_4, var_4_5 = var_4_0:getPosition()
	local var_4_6 = xyd.tables.item:type(arg_4_1)
	local var_4_7 = "new_item_tips"

	var_4_1:getChildByName("container"):addChild(var_4_3)
	var_4_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			xyd.playButtonSound()

			local var_5_0 = xyd.WindowManager.get():getWindow(var_4_7)
			local var_5_1 = arg_4_0:convertToWorldSpace(cc.p(0, 0))

			if not var_5_0 then
				local var_5_2 = xyd.WindowManager.get():openWindow(var_4_7, var_4_2)

				xyd.adaptToWorldPosition(var_4_3, var_5_2)
			end

			return true
		elseif arg_5_0.name == "moved" then
			return true
		elseif arg_5_0.name == "ended" then
			if not arg_4_3 then
				arg_4_0.selectItem = arg_4_4

				arg_4_0:updateDownContainer()
			end

			xyd.WindowManager.get():closeWindow(var_4_7)

			return true
		end
	end)
	xyd.setItemBorder(var_4_1:getChildByName("container"), arg_4_1, false, false, arg_4_2)
	var_4_0:addContent(var_4_1)
	var_4_0:setItemSize(100, 100)

	if not arg_4_3 then
		arg_4_0.downList_:addItem(var_4_0)
	else
		arg_4_0.midList_:addItem(var_4_0)
	end
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
	elseif arg_6_1.name == "moved" and 10 <= math.abs(arg_6_1.x - arg_6_0.prevX_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	var_0_0.super.willOpen(arg_7_0, arg_7_1)

	arg_7_0.downList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_7_0:nodeByName("down_list"):getWidth(), arg_7_0:nodeByName("down_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_7_0:nodeByName("down_list")):onScroll(handler(arg_7_0, arg_7_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)
	arg_7_0.midList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_7_0:nodeByName("mid_list"):getWidth(), arg_7_0:nodeByName("mid_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_7_0:nodeByName("mid_list")):onScroll(handler(arg_7_0, arg_7_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.REFRESH_STAR_TREASURE_ITEM, function(arg_8_0)
		arg_7_0:updateDownContainer()
	end)
	arg_7_0:updateLeft()
	arg_7_0:updateDownContainer()
	arg_7_0:updateMidContainer()
	arg_7_0:layout()
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super.didOpen(arg_9_0, arg_9_1)
	arg_9_0:addBlockLayer()
end

function var_0_0.willClose(arg_10_0, arg_10_1)
	var_0_0.super.willClose(arg_10_0, arg_10_1)

	local var_10_0 = xyd.WindowManager.get():getWindow("sakura2018_main")

	if var_10_0 and not tolua.isnull(var_10_0) then
		var_10_0:updateStarTreasuerProgress()
	end
end

function var_0_0.updateLeft(arg_11_0)
	if not arg_11_0.starTreasure.shadowMap then
		return
	end

	arg_11_0:nodeByName("map_bg"):removeAllChildren()

	for iter_11_0 = 1, 5 do
		for iter_11_1 = 1, 6 do
			local var_11_0 = arg_11_0:initCell(iter_11_0, iter_11_1)

			var_11_0:addTo(arg_11_0:nodeByName("map_bg"))
			var_11_0:setPosition((iter_11_1 - 1) * 94 + 4, (iter_11_0 - 1) * 94 + 4)
		end
	end
end

function var_0_0.initCell(arg_12_0, arg_12_1, arg_12_2)
	local function var_12_0(arg_13_0, arg_13_1)
		if arg_12_0.starTreasure.shadowMap[arg_13_0] and arg_12_0.starTreasure.shadowMap[arg_13_0][arg_13_1] and arg_12_0.starTreasure.shadowMap[arg_13_0][arg_13_1] == 0 then
			return true
		else
			return false
		end
	end

	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/star_treasure/star_treasure_main/gezi/block.csb")

	if arg_12_0.starTreasure.shadowMap[arg_12_1][arg_12_2] == 0 then
		if var_12_0(arg_12_1, arg_12_2 - 1) == false and var_12_0(arg_12_1 - 1, arg_12_2) == false then
			var_12_1:getChildByName("ge1_1"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 - 1) == false and var_12_0(arg_12_1 - 1, arg_12_2) == true then
			var_12_1:getChildByName("ge1_3"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 - 1) == true and var_12_0(arg_12_1 - 1, arg_12_2) == false then
			var_12_1:getChildByName("ge1_2"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 - 1) == true and var_12_0(arg_12_1 - 1, arg_12_2) == true then
			if var_12_0(arg_12_1 - 1, arg_12_2 - 1) == false then
				var_12_1:getChildByName("ge1_4"):setVisible(true)
			else
				var_12_1:getChildByName("ge1_0"):setVisible(true)
			end
		end

		if var_12_0(arg_12_1, arg_12_2 + 1) == false and var_12_0(arg_12_1 - 1, arg_12_2) == false then
			var_12_1:getChildByName("ge2_1"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 + 1) == false and var_12_0(arg_12_1 - 1, arg_12_2) == true then
			var_12_1:getChildByName("ge2_3"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 + 1) == true and var_12_0(arg_12_1 - 1, arg_12_2) == false then
			var_12_1:getChildByName("ge2_2"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 + 1) == true and var_12_0(arg_12_1 - 1, arg_12_2) == true then
			if var_12_0(arg_12_1 - 1, arg_12_2 + 1) == false then
				var_12_1:getChildByName("ge2_4"):setVisible(true)
			else
				var_12_1:getChildByName("ge2_0"):setVisible(true)
			end
		end

		if var_12_0(arg_12_1, arg_12_2 - 1) == false and var_12_0(arg_12_1 + 1, arg_12_2) == false then
			var_12_1:getChildByName("ge3_1"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 - 1) == false and var_12_0(arg_12_1 + 1, arg_12_2) == true then
			var_12_1:getChildByName("ge3_3"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 - 1) == true and var_12_0(arg_12_1 + 1, arg_12_2) == false then
			var_12_1:getChildByName("ge3_2"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 - 1) == true and var_12_0(arg_12_1 + 1, arg_12_2) == true then
			if var_12_0(arg_12_1 + 1, arg_12_2 - 1) == false then
				var_12_1:getChildByName("ge3_4"):setVisible(true)
			else
				var_12_1:getChildByName("ge3_0"):setVisible(true)
			end
		end

		if var_12_0(arg_12_1, arg_12_2 + 1) == false and var_12_0(arg_12_1 + 1, arg_12_2) == false then
			var_12_1:getChildByName("ge4_1"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 + 1) == false and var_12_0(arg_12_1 + 1, arg_12_2) == true then
			var_12_1:getChildByName("ge4_3"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 + 1) == true and var_12_0(arg_12_1 + 1, arg_12_2) == false then
			var_12_1:getChildByName("ge4_2"):setVisible(true)
		elseif var_12_0(arg_12_1, arg_12_2 + 1) == true and var_12_0(arg_12_1 + 1, arg_12_2) == true then
			if var_12_0(arg_12_1 + 1, arg_12_2 + 1) == false then
				var_12_1:getChildByName("ge4_4"):setVisible(true)
			else
				var_12_1:getChildByName("ge4_0"):setVisible(true)
			end
		end
	elseif arg_12_0.starTreasure.shadowMap[arg_12_1][arg_12_2] == -1 then
		local var_12_2 = display.newNode()

		var_12_2:setContentSize(94, 94)
		var_12_2:setTouchEnabled(true)
		var_12_2:setTouchSwallowEnabled(false)
		var_12_2:setAnchorPoint(cc.p(0, 0))
		var_12_2:setPosition(0, 0)

		local var_12_3
		local var_12_4 = "skeletons/ui_effect/star_treasure_effect/zq_xuanwo"
		local var_12_5 = var_12_4 .. ".json"
		local var_12_6 = var_12_4 .. ".atlas"
		local var_12_7 = var_0_2.new(var_12_5, var_12_6, 1)

		var_12_7:align(display.CENTER, var_12_2:getWidth() / 2, var_12_2:getHeight() / 2)
		var_12_7:addTo(var_12_2)
		var_12_7:setScale(0.15, 0.15)
		var_12_7:play(nil, true)
		var_12_1:addChild(var_12_2)
		var_12_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "began" then
				return true
			elseif arg_14_0.name == "moved" then
				return true
			elseif arg_14_0.name == "ended" then
				xyd.playButtonSound()

				params = {}
				params.location = (arg_12_1 - 1) * 6 + arg_12_2

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ENTRE_NEXT_INFO"), function()
					arg_12_0.starTreasure:entreNextFloor(params, function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							arg_12_0:nodeByName("now_text"):setString(arg_12_0.starTreasure.currentFloor .. " / " .. xyd.tables.misc.starTreasureMaxFloor)
							arg_12_0:nodeByName("history_text"):setString(arg_12_0.starTreasure.maxFloor .. " / " .. xyd.tables.misc.starTreasureMaxFloor)
							arg_12_0:updateLeft()
							arg_12_0:updateDownContainer()
							arg_12_0:updateMidContainer()
						end
					end)
					xyd.playButtonSound()
				end, nil, nil, arg_12_0.colorMode)

				return true
			end
		end)
	end

	return var_12_1
end

function var_0_0.layout(arg_17_0)
	arg_17_0.heroModel = xyd.HeroAnimation.new(nil, var_0_5, 1, {})

	arg_17_0.heroModel:setScale(0.5)
	arg_17_0.heroModel:setTouchSwallowEnabled(false)
	arg_17_0.heroModel:setPosition(cc.p(0, 0))
	arg_17_0:nodeByName("pic_container"):removeAllChildren()
	arg_17_0.heroModel:addTo(arg_17_0:nodeByName("pic_container"))
	arg_17_0.heroModel:idle()
	arg_17_0:nodeByName("pic_container"):setPosition(282 + var_0_4, 188)
	arg_17_0:nodeByName("record"):setString(var_0_1:translation("ACTIVITY_SAKURA_TIP2"))
	xyd.nodeEventSample(arg_17_0:nodeByName("record_btn"), nil, function(arg_18_0)
		xyd.playButtonSound()
		arg_17_0.starTreasure:getAwardRecord(nil, function(arg_19_0, arg_19_1)
			if arg_19_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("star_treasure_record")
			end
		end)
	end)
	arg_17_0:nodeByName("buy"):setString(var_0_1:translation("ACTIVITY_SAKURA_TIP3"))
	xyd.nodeEventSample(arg_17_0:nodeByName("buy_btn"), nil, function(arg_20_0)
		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow("star_treasure_shop")
	end)
	arg_17_0:nodeByName("restart"):setString(var_0_1:translation("ACTIVITY_SAKURA_TIP1"))
	xyd.nodeEventSample(arg_17_0:nodeByName("restart_btn"), nil, function(arg_21_0)
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("STAR_TREASURE_RESTART"), function()
			arg_17_0.starTreasure:reStart(function(arg_23_0, arg_23_1)
				if arg_23_0 == xyd.error.OK then
					arg_17_0:nodeByName("now_text"):setString(arg_17_0.starTreasure.currentFloor .. " / " .. xyd.tables.misc.starTreasureMaxFloor)
					arg_17_0:nodeByName("history_text"):setString(arg_17_0.starTreasure.maxFloor .. " / " .. xyd.tables.misc.starTreasureMaxFloor)
					arg_17_0:updateLeft()
					arg_17_0:updateDownContainer()
					arg_17_0:updateMidContainer()
				end
			end)
			xyd.playButtonSound()
		end, nil, nil, arg_17_0.colorMode)
	end)
	xyd.nodeEventSample(arg_17_0:nodeByName("close_btn"), nil, function()
		xyd.playButtonSound()
		xyd.WindowManager.get():closeWindow(arg_17_0)
	end)
	arg_17_0:nodeByName("now_text"):setString(arg_17_0.starTreasure.currentFloor .. " / " .. xyd.tables.misc.starTreasureMaxFloor)
	arg_17_0:nodeByName("history_text"):setString(arg_17_0.starTreasure.maxFloor .. " / " .. xyd.tables.misc.starTreasureMaxFloor)
	arg_17_0:nodeByName("now_text"):enableOutline(cc.c4b(255, 96, 0, 255), 2)
	arg_17_0:nodeByName("history_text"):enableOutline(cc.c4b(245, 25, 82, 255), 2)
	arg_17_0:nodeByName("now_words"):setString(var_0_1:translation("CURRENT_POS"))
	arg_17_0:nodeByName("history_words"):setString(var_0_1:translation("HISTORY_MAX"))
	arg_17_0:nodeByName("des_text"):setString(var_0_1:translation("STAR_TREASURE_DES"))
	arg_17_0:nodeByName("may_words"):setString(var_0_1:translation("MAY_GET"))
	arg_17_0:nodeByName("own_words"):setString(var_0_1:translation("OWN_ITEM"))
	arg_17_0:nodeByName("may_words"):enableOutline(cc.c4b(202, 52, 0, 255), 2)
	arg_17_0:nodeByName("own_words"):enableOutline(cc.c4b(202, 52, 0, 255), 2)
	arg_17_0:nodeByName("map_bg"):setTouchEnabled(true)
	arg_17_0:nodeByName("map_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		if arg_25_0.name == "began" then
			return true
		elseif arg_25_0.name == "ended" then
			for iter_25_0 = 1, 5 do
				for iter_25_1 = 1, 6 do
					local var_25_0 = arg_17_0:nodeByName("map_bg"):convertToNodeSpace(cc.p(arg_25_0.x, arg_25_0.y))

					if var_25_0.x > (iter_25_1 - 1) * 94 + 4 and var_25_0.x < iter_25_1 * 94 + 4 and var_25_0.y > (iter_25_0 - 1) * 94 + 4 and var_25_0.y < iter_25_0 * 94 + 4 then
						local var_25_1 = (iter_25_0 - 1) * 6 + iter_25_1

						if arg_17_0.starTreasure.shadowMap[iter_25_0][iter_25_1] == 0 and arg_17_0.canClick == true then
							arg_17_0.canClick = false

							if arg_17_0.selectItem == 0 then
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("STAR_TREASURE_ITEM_NONE"), function()
									xyd.WindowManager.get():openWindow("star_treasure_shop")
									xyd.playButtonSound()
								end, nil, nil, arg_17_0.colorMode)

								arg_17_0.canClick = true
							else
								arg_17_0.activitiesModel:getActivityReward2(xyd.Activities.StarTreasure, arg_17_0.selectItem, var_25_1, function(arg_27_0, arg_27_1)
									if arg_27_0 == xyd.error.OK then
										local var_27_0
										local var_27_1 = "skeletons/ui_effect/star_treasure_effect/yun"
										local var_27_2 = var_27_1 .. ".json"
										local var_27_3 = var_27_1 .. ".atlas"
										local var_27_4 = var_0_2.new(var_27_2, var_27_3, 1)

										var_27_4:addTo(arg_17_0:nodeByName("left_container"))
										var_27_4:setPosition((iter_25_1 - 0.5) * 94 + var_0_4, (iter_25_0 - 0.5) * 94)
										var_27_4:setScale(0.5, 0.5)
										var_27_4:play(nil, false)
										arg_17_0:nodeByName("pic_container"):setPosition((iter_25_1 - 0.5) * 94 + 10, (iter_25_0 - 0.5) * 94 - 10)
										arg_17_0.heroModel:win(false, handler(arg_17_0, arg_17_0.setIsShow))
										arg_17_0.selfPlayer:handleRewards(arg_27_1.awards)
										arg_17_0.starTreasure:setShadowMap(arg_27_1.shadow_map)
										arg_17_0.starTreasure:setAwardStatus(arg_27_1.award_status)
										arg_17_0.selfPlayer:getBackpack():removeItem({
											itemNum = 1,
											itemID = xyd.tables.starTreasureItem:itemId(arg_17_0.selectItem)
										})

										if arg_17_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.starTreasureItem:itemId(arg_17_0.selectItem)) <= 0 then
											arg_17_0.selectItem = 0
										end

										if arg_27_1.hole_location then
											xyd.WindowManager.get():openWindow("star_treasure_entre")
										end

										arg_17_0:updateLeft()
										arg_17_0:updateDownContainer()
										arg_17_0:updateMidContainer()

										arg_17_0.canClick = true
									else
										arg_17_0.canClick = true
									end
								end)
							end
						end
					end
				end
			end
		end
	end)
end

function var_0_0.setIsShow(arg_28_0)
	arg_28_0.heroModel:idle()
end

function var_0_0.didClose(arg_29_0)
	var_0_0.super.didClose()
end

return var_0_0
