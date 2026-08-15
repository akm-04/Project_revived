local var_0_0 = class("ProductionTableWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = {
	CannotMake = 3,
	CanMake = 2,
	None = 1
}
local var_0_5 = 9

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.listItems = {}
	arg_1_0.nextLevItems = {}
	arg_1_0.itemState = var_0_4.None
	arg_1_0.deskInfo = arg_1_0.eventCentre.deskInfo
	arg_1_0.buildingName = xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.DESK)
end

function var_0_0.updateList(arg_2_0)
	arg_2_0:initialVariable()
	arg_2_0:initialListItems()
	arg_2_0.itemList:reload()
end

function var_0_0.initialVariable(arg_3_0)
	arg_3_0.lev = arg_3_0.deskInfo.building_info.lev
	arg_3_0.eventCentre.buidingInfo[tostring(xyd.EventCentreBuildingType.DESK)].lev = arg_3_0.lev
	arg_3_0.currentTime = xyd.ServerTime.get():getServerTime()
	arg_3_0.makingTime = 0

	if arg_3_0.deskInfo.is_making == 1 then
		arg_3_0.makingTime = arg_3_0.deskInfo.make_need_time - (arg_3_0.currentTime - arg_3_0.deskInfo.make_start_time)
	end
end

function var_0_0.initialListItems(arg_4_0)
	local var_4_0 = arg_4_0.lev

	arg_4_0.listItems = {}
	arg_4_0.nextLevItems = {}

	for iter_4_0 = 1, tonumber(var_4_0) do
		local var_4_1 = xyd.tables.eventCentreProductionTable:makeItem(iter_4_0)

		for iter_4_1 = 1, #var_4_1 do
			local var_4_2 = {
				itemID = var_4_1[iter_4_1]
			}

			var_4_2.itemNum = 0

			table.insert(arg_4_0.listItems, arg_4_0.backPack:getItemByID(var_4_1[iter_4_1]) or var_4_2)
		end
	end

	local var_4_3 = xyd.tables.eventCentreProductionTable:makeItem(var_4_0 + 1)

	for iter_4_2 = 1, #var_4_3 do
		local var_4_4 = {
			itemID = var_4_3[iter_4_2]
		}

		var_4_4.itemNum = 0

		table.insert(arg_4_0.nextLevItems, var_4_4)
	end

	table.sort(arg_4_0.listItems, function(arg_5_0, arg_5_1)
		return arg_5_0.itemID < arg_5_1.itemID
	end)
	table.sort(arg_4_0.nextLevItems, function(arg_6_0, arg_6_1)
		return arg_6_0.itemID < arg_6_1.itemID
	end)
end

function var_0_0.createTimeString(arg_7_0, arg_7_1)
	return xyd.secondsToString1(arg_7_1)
end

function var_0_0.willOpen(arg_8_0, arg_8_1)
	var_0_0.super.willOpen(arg_8_0, arg_8_1)
	arg_8_0:initialVariable()
	arg_8_0:initialListItems()
	arg_8_0:layout()
end

function var_0_0.layout(arg_9_0)
	arg_9_0:nodeByName("txt_title"):setString(xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.DESK))
	arg_9_0:nodeByName("txt_make"):setString(var_0_1:translation("EVENT_CENTRE_TIP1"))
	arg_9_0:nodeByName("txt_accelerate"):setString(var_0_1:translation("EVENT_CENTRE_TIP2"))
	arg_9_0:nodeByName("txt_upgrade"):setString(var_0_1:translation("HERO_MAIN_TEXT_13"))
	arg_9_0:nodeByName("txt_recommend"):setString(var_0_1:translation("HERO_LIST_BTN_RECOMMEND"))
	arg_9_0:nodeByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))
	arg_9_0:nodeByName("own_num_text"):setString(var_0_1:translation("OWN"))
	arg_9_0:nodeByName("time_text"):setString(var_0_1:translation("COST_TIME"))

	arg_9_0.scroll = arg_9_0:nodeByName("scroll")

	local var_9_0 = arg_9_0.scroll:getContentSize()

	if not arg_9_0.itemList then
		arg_9_0.itemList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_9_0.width, var_9_0.height - 5),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_9_0.scroll):onScroll(handler(arg_9_0, arg_9_0.scrollListener))
	else
		arg_9_0.nodeX = arg_9_0.itemList.scrollNode:getPositionX()
		arg_9_0.nodeY = arg_9_0.itemList.scrollNode:getPositionY()

		arg_9_0.itemList:removeAllItems()
	end

	arg_9_0.itemList:setDelegate(handler(arg_9_0, arg_9_0.itemListDelegate))
	arg_9_0.itemList:setBounceable(true)
	arg_9_0.itemList:reload()
	arg_9_0:nodeByName("equip_consum_text"):setString(var_0_1:translation("EQUIP_CONSUM_TEXT"))
	arg_9_0:nodeByName("own_text"):setString(var_0_1:translation("OWN_TEXT"))
	arg_9_0:setButtonClick()
	arg_9_0:update()
end

function var_0_0.update(arg_10_0)
	arg_10_0:updateMakingItemInfo()
	arg_10_0:updateBottomShow()
	arg_10_0:updateBottomLeftShow()
	arg_10_0:updateBottomRigthShow()
	arg_10_0:updateUpgradeTime()
	arg_10_0:updateLevShow()
end

function var_0_0.updateLevShow(arg_11_0)
	arg_11_0:nodeByName("txt_lv"):setString("LV" .. arg_11_0.lev)

	if arg_11_0.deskInfo.building_info.new_evolve == 1 then
		local var_11_0 = {
			type = xyd.EventCentreBuildingType.DESK
		}

		arg_11_0.eventCentre:confirmBuildingUpgrade(var_11_0, function(arg_12_0, arg_12_1)
			if arg_12_0 == xyd.error.OK then
				arg_11_0.deskInfo.building_info.new_evolve = 0

				local var_12_0 = {
					lev = arg_11_0.lev,
					type = xyd.EventCentreBuildingType.DESK
				}

				arg_11_0:updateList()
				xyd.WindowManager.get():openWindow("building_levelup", var_12_0)
			end
		end)
	end
end

function var_0_0.updateUpgradeTime(arg_13_0)
	if arg_13_0.handle1 then
		var_0_2.unscheduleGlobal(arg_13_0.handle1)

		arg_13_0.handle1 = nil
	end

	local var_13_0

	if arg_13_0.deskInfo.building_info.start_time > 0 then
		var_13_0 = arg_13_0.deskInfo.building_info.need_time - (xyd.ServerTime.get():getServerTime() - arg_13_0.deskInfo.building_info.start_time)
	else
		var_13_0 = 0
	end

	if var_13_0 > 0 then
		arg_13_0:nodeByName("upgrade_btn"):setVisible(false)
		arg_13_0:nodeByName("upgrade_time_bg"):setVisible(true)
		arg_13_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_13_0))
		arg_13_0:nodeByName("bar_time"):setPercent((1 - var_13_0 / arg_13_0.deskInfo.building_info.need_time) * 100)

		arg_13_0.handle1 = var_0_2.scheduleGlobal(function()
			var_13_0 = var_13_0 - 1

			if not tolua.isnull(arg_13_0) then
				arg_13_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_13_0))
				arg_13_0:nodeByName("bar_time"):setPercent((1 - var_13_0 / arg_13_0.deskInfo.building_info.need_time) * 100)
			end

			if var_13_0 <= 0 and arg_13_0.handle1 then
				var_0_2.unscheduleGlobal(arg_13_0.handle1)

				arg_13_0.handle1 = nil

				if not tolua.isnull(arg_13_0) then
					arg_13_0:nodeByName("upgrade_btn"):setVisible(true)
					arg_13_0:nodeByName("upgrade_time_bg"):setVisible(false)
					arg_13_0:nodeByName("bar_time"):setPercent(0)
				end
			end
		end, 1)
	else
		arg_13_0:nodeByName("upgrade_btn"):setVisible(true)
		arg_13_0:nodeByName("upgrade_time_bg"):setVisible(false)
		arg_13_0:nodeByName("bar_time"):setPercent(0)
	end
end

function var_0_0.updateMakingItemInfo(arg_15_0)
	arg_15_0:nodeByName("item_container"):removeAllChildren(true)
	arg_15_0:nodeByName("item_container"):setVisible(true)

	if arg_15_0.makingTime > 0 and arg_15_0.deskInfo.is_making == 1 then
		arg_15_0:createScheduler()
		arg_15_0:nodeByName("progress_bg"):setVisible(true)
		arg_15_0:nodeByName("down_time_txt"):setVisible(true)
		arg_15_0:nodeByName("cancel_make"):setVisible(true)
		xyd.setItemBorder(arg_15_0:nodeByName("item_container"), arg_15_0.deskInfo.making_item, nil, nil, nil)
	elseif arg_15_0.currentItem then
		arg_15_0:nodeByName("progress_bg"):setVisible(true)
		arg_15_0:nodeByName("down_time_txt"):setVisible(false)
		arg_15_0:nodeByName("cancel_make"):setVisible(false)
		arg_15_0:nodeByName("progress_bar"):setPercent(0)
		xyd.setItemBorder(arg_15_0:nodeByName("item_container"), arg_15_0.currentItem.itemID, nil, nil, nil)
	else
		arg_15_0:nodeByName("item_container"):setVisible(false)
		arg_15_0:nodeByName("progress_bg"):setVisible(false)
		arg_15_0:nodeByName("down_time_txt"):setVisible(false)
		arg_15_0:nodeByName("cancel_make"):setVisible(false)
	end

	if arg_15_0.deskInfo.make_item and arg_15_0.deskInfo.make_item > 0 then
		arg_15_0:handleMakeItem(arg_15_0.deskInfo.make_item)
	end

	if arg_15_0.deskInfo.is_making == 0 then
		arg_15_0:nodeByName("accelerate"):setVisible(false)
	else
		arg_15_0:nodeByName("accelerate"):setVisible(true)
	end
end

function var_0_0.handleMakeItem(arg_16_0, arg_16_1)
	local var_16_0 = {
		building_type = xyd.EventCentreBuildingType.DESK
	}

	arg_16_0.eventCentre:confirmMakeItem(var_16_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			local var_17_0 = {
				resolve_types = {},
				resolve_nums = {},
				resolve_crits = {}
			}

			for iter_17_0 = 1, #arg_17_1.items do
				table.insert(var_17_0.resolve_types, arg_17_1.items[iter_17_0].table_id)
				table.insert(var_17_0.resolve_nums, arg_17_1.items[iter_17_0].item_num)
			end

			xyd.WindowManager.get():openWindow("recycle_award", var_17_0)

			local var_17_1 = xyd.WindowManager.get():getWindow("event_centre")

			if var_17_1 and not tolua.isnull(var_17_1) then
				var_17_1:updateRedPointShow()
			end

			if arg_16_0 and not tolua.isnull(arg_16_0.itemList) then
				arg_16_0.deskInfo.make_item = 0

				arg_16_0.itemList:refreshList()
			end
		end
	end)
end

function var_0_0.createScheduler(arg_18_0)
	if arg_18_0.handle then
		var_0_2.unscheduleGlobal(arg_18_0.handle)

		arg_18_0.handle = nil
	end

	arg_18_0.makingTime = arg_18_0.deskInfo.make_need_time - (xyd.ServerTime.get():getServerTime() - arg_18_0.deskInfo.make_start_time)

	arg_18_0:updateMakingTime()

	arg_18_0.handle = var_0_2.scheduleGlobal(function()
		arg_18_0.currentTime = arg_18_0.currentTime + 1
		arg_18_0.makingTime = arg_18_0.makingTime - 1

		if arg_18_0.makingTime <= 0 then
			if arg_18_0.handle then
				var_0_2.unscheduleGlobal(arg_18_0.handle)

				arg_18_0.handle = nil
			end

			arg_18_0.eventCentre:getDeskpInfo({}, function(arg_20_0, arg_20_1)
				if arg_20_0 == xyd.error.OK then
					arg_18_0.deskInfo = arg_18_0.eventCentre.deskInfo

					arg_18_0:update()
				end
			end)
		end

		arg_18_0:updateMakingTime()
	end, 1)
end

function var_0_0.updateMakingTime(arg_21_0)
	local var_21_0 = arg_21_0.deskInfo.making_item

	if var_21_0 and var_21_0 > 0 then
		local var_21_1 = arg_21_0:createTimeString(arg_21_0.makingTime)

		arg_21_0:nodeByName("down_time_txt"):setString(var_21_1)

		local var_21_2 = xyd.tables.eventCentreProductionTable:cutMakeTime(arg_21_0.lev)
		local var_21_3 = xyd.tables.item:makeTime(var_21_0) - var_21_2

		arg_21_0:nodeByName("progress_bar"):setPercent(100 * (1 - arg_21_0.makingTime / var_21_3))
	end
end

function var_0_0.updateBottomShow(arg_22_0)
	arg_22_0:nodeByName("bottom_left_container"):setVisible(false)
	arg_22_0:nodeByName("bottom_right_container"):setVisible(false)
	arg_22_0:nodeByName("select_make_item"):setVisible(false)

	if arg_22_0.itemState == var_0_4.None then
		arg_22_0:nodeByName("select_make_item"):setString(var_0_1:translation("SELECT_MAKE_ITEM"))
		arg_22_0:nodeByName("select_make_item"):setVisible(true)
	elseif arg_22_0.itemState == var_0_4.CannotMake then
		arg_22_0:nodeByName("select_make_item"):setString(string.format(var_0_1:translation("LVN_CAN_MAKE"), arg_22_0.buildingName, arg_22_0.deskInfo.building_info.lev + 1))
		arg_22_0:nodeByName("select_make_item"):setVisible(true)
		arg_22_0:nodeByName("bottom_left_container"):setVisible(true)
	else
		arg_22_0:nodeByName("bottom_left_container"):setVisible(true)
		arg_22_0:nodeByName("bottom_right_container"):setVisible(true)
	end
end

function var_0_0.updateBottomLeftShow(arg_23_0)
	if arg_23_0.currentItem then
		arg_23_0:nodeByName("equip_name_text"):setString(xyd.tables.item:name(arg_23_0.currentItem.itemID))

		local var_23_0 = arg_23_0.backPack:getItemNumByID(arg_23_0.currentItem.itemID)

		arg_23_0:nodeByName("own_num_txt"):setString(var_23_0)

		local var_23_1 = xyd.tables.eventCentreProductionTable:cutMakeTime(arg_23_0.lev)
		local var_23_2 = arg_23_0:createTimeString(xyd.tables.item:makeTime(arg_23_0.currentItem.itemID) - var_23_1)

		arg_23_0:nodeByName("time_txt"):setString(var_23_2)
	end
end

function var_0_0.updateBottomRigthShow(arg_24_0)
	if arg_24_0.currentItem then
		arg_24_0:nodeByName("consum_pos"):removeAllChildren()

		local var_24_0 = xyd.tables.item:makeResType(arg_24_0.currentItem.itemID)
		local var_24_1 = xyd.tables.item:makeResNum(arg_24_0.currentItem.itemID)
		local var_24_2 = arg_24_0:createItemsContent(var_24_0, var_24_1)

		var_24_2:setAnchorPoint(cc.p(0, 0.5))
		var_24_2:addTo(arg_24_0:nodeByName("consum_pos"))
		var_24_2:setPosition(cc.p(0, 0))

		if arg_24_0.resourceNotEnough then
			arg_24_0:nodeByName("make_btn"):setVisible(false)
		else
			arg_24_0:nodeByName("make_btn"):setVisible(true)
		end
	end
end

function var_0_0.createItemsContent(arg_25_0, arg_25_1, arg_25_2)
	arg_25_0.resourceNotEnough = false

	local var_25_0 = display.newNode()
	local var_25_1 = -10
	local var_25_2 = 25

	for iter_25_0 = 1, #arg_25_1 do
		var_25_1 = var_25_1 + 10

		local var_25_3
		local var_25_4

		if arg_25_1[iter_25_0] == 11 then
			var_25_3 = "images/icon/eco/magic_dust_small.png"
			var_25_4 = arg_25_0.selfPlayer.magicDust
		elseif arg_25_1[iter_25_0] == 12 then
			var_25_3 = "images/icon/eco/magic_liquid_small.png"
			var_25_4 = arg_25_0.selfPlayer.magicLiquid
		elseif arg_25_1[iter_25_0] == 13 then
			var_25_3 = "images/icon/eco/magic_energy_small.png"
			var_25_4 = arg_25_0.selfPlayer.magicEnergy
		end

		local var_25_5

		if var_25_3 then
			var_25_5 = xyd.AssetLoader.get():loadSprite(var_25_3)
		end

		var_25_5:addTo(var_25_0)
		var_25_5:setAnchorPoint(0, 0.5)
		var_25_5:setPosition(var_25_1, var_25_2)

		var_25_1 = var_25_1 + var_25_5:getContentSize().width + 10

		local var_25_6

		if var_25_4 < arg_25_2[iter_25_0] then
			arg_25_0.resourceNotEnough = true
			var_25_6 = cc.c3b(255, 0, 0)
		end

		local var_25_7 = arg_25_0:createItemNumLabel(arg_25_2[iter_25_0], var_25_6)

		var_25_7:addTo(var_25_0)
		var_25_7:setAnchorPoint(0, 0.5)
		var_25_7:setPosition(var_25_1, var_25_2)

		var_25_1 = var_25_1 + var_25_7:getContentSize().width
	end

	var_25_0:setContentSize(var_25_1, 50)

	return var_25_0
end

function var_0_0.createItemNumLabel(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = {
		font = "fonts/main_font.ttf",
		size = 26,
		color = arg_26_2 or cc.c3b(47, 164, 53)
	}
	local var_26_1 = xyd.AssetLoader.get():loadLabel(var_26_0)

	var_26_1:setMaxLineWidth(250)
	var_26_1:setString(arg_26_1)

	return var_26_1
end

function var_0_0.itemListDelegate(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	if cc.ui.UIListView.COUNT_TAG == arg_27_2 then
		if #arg_27_0.nextLevItems > 0 then
			return math.ceil(#arg_27_0.listItems / var_0_5) + 1 + math.ceil(#arg_27_0.nextLevItems / var_0_5)
		else
			return math.ceil(#arg_27_0.listItems / var_0_5)
		end
	elseif cc.ui.UIListView.CELL_TAG == arg_27_2 then
		local var_27_0
		local var_27_1 = arg_27_0.itemList:dequeueItem()

		if not var_27_1 then
			var_27_1 = arg_27_0.itemList:newItem()
		else
			var_27_1:removeAllChildren(true)
		end

		local var_27_2

		if arg_27_3 <= math.ceil(#arg_27_0.listItems / var_0_5) then
			var_27_2 = arg_27_0:createListContent(arg_27_3)
		elseif arg_27_3 == math.ceil(#arg_27_0.listItems / var_0_5) + 1 then
			var_27_2 = arg_27_0:creatNextLevTitleContent()
		else
			var_27_2 = arg_27_0:createNextLevContent(arg_27_3 - math.ceil(#arg_27_0.listItems / var_0_5) - 1)
		end

		local var_27_3 = var_27_2:getWidth()
		local var_27_4 = var_27_2:getHeight()

		var_27_1:setItemSize(var_27_3, var_27_4)
		var_27_1:addContent(var_27_2)

		return var_27_1
	end
end

function var_0_0.createListContent(arg_28_0, arg_28_1)
	local var_28_0 = display.newNode()
	local var_28_1 = 110
	local var_28_2 = 55
	local var_28_3 = 7.5

	var_28_0:setContentSize(1010, 100)

	for iter_28_0 = 1, var_0_5 do
		if (arg_28_1 - 1) * var_0_5 + iter_28_0 <= #arg_28_0.listItems then
			local var_28_4 = arg_28_0.listItems[(arg_28_1 - 1) * var_0_5 + iter_28_0]
			local var_28_5 = display.newNode()

			var_28_5:setContentSize(85, 85)
			var_28_5:setAnchorPoint(cc.p(0.5, 0))
			xyd.setItemBorder(var_28_5, var_28_4.itemID, nil, nil, var_28_4.itemNum, nil, true)
			var_28_5:addTo(var_28_0)
			var_28_5:setPosition(cc.p(var_28_2, var_28_3))

			var_28_2 = var_28_2 + var_28_1

			if arg_28_0.currentItem and arg_28_0.currentItem == var_28_4 then
				arg_28_0:addSelectEffectForItem(var_28_5)
			end

			var_28_5:setTouchEnabled(true)
			var_28_5:setTouchSwallowEnabled(false)
			var_28_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
				if arg_29_0.name == "began" and arg_28_0.scrollViewMoved_ ~= true then
					var_28_5:setScale(0.9)

					return true
				elseif arg_29_0.name == "ended" then
					var_28_5:setScale(1)

					if arg_28_0.currentItem ~= var_28_4 then
						arg_28_0.currentItem = var_28_4
						arg_28_0.itemState = var_0_4.CanMake

						arg_28_0:update()
					end

					arg_28_0:addSelectEffectForItem(var_28_5)
				end
			end)
		end
	end

	return var_28_0
end

function var_0_0.addSelectEffectForItem(arg_30_0, arg_30_1)
	if not tolua.isnull(arg_30_0.effect) and arg_30_0.effect then
		transition.stopTarget(arg_30_0.effect)
		arg_30_0.effect:removeSelf()

		arg_30_0.effect = nil
	end

	arg_30_0.effect = xyd.AssetLoader:get():loadSprite("windows/event_centre/bg_select.png")

	arg_30_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_30_0.effect:addTo(arg_30_1)
	arg_30_0.effect:setPosition(cc.p(arg_30_1:getContentSize().width / 2, arg_30_1:getContentSize().height / 2))
	arg_30_0.effect:setName("effect")
	arg_30_0.effect:setScale(0.78)

	local var_30_0 = transition.sequence({
		cc.ScaleTo:create(0.3, 0.8112),
		cc.ScaleTo:create(0.3, 0.78)
	})
	local var_30_1 = cc.RepeatForever:create(var_30_0)

	arg_30_0.effect:runAction(var_30_1)
end

function var_0_0.creatNextLevTitleContent(arg_31_0)
	local var_31_0 = display.newNode()

	var_31_0:setContentSize(995, 40)

	local var_31_1 = arg_31_0:creatNextLevLabel()

	var_31_1:setAnchorPoint(cc.p(0, 0))
	var_31_1:addTo(var_31_0)
	var_31_1:setPosition(cc.p(20, 2))

	return var_31_0
end

function var_0_0.creatNextLevLabel(arg_32_0)
	local var_32_0 = string.format(var_0_1:translation("NEXT_LEV_MAKE"), arg_32_0.buildingName)
	local var_32_1 = {
		font = "fonts/main_font.ttf",
		size = 26,
		color = cc.c3b(255, 255, 255)
	}
	local var_32_2 = xyd.AssetLoader.get():loadLabel(var_32_1)

	var_32_2:setMaxLineWidth(500)
	var_32_2:setString(var_32_0)

	return var_32_2
end

function var_0_0.createNextLevContent(arg_33_0, arg_33_1)
	local var_33_0 = display.newNode()
	local var_33_1 = 110
	local var_33_2 = 55
	local var_33_3 = 7.5

	var_33_0:setContentSize(1010, 100)

	for iter_33_0 = 1, var_0_5 do
		if (arg_33_1 - 1) * var_0_5 + iter_33_0 <= #arg_33_0.nextLevItems then
			local var_33_4 = arg_33_0.nextLevItems[(arg_33_1 - 1) * var_0_5 + iter_33_0]
			local var_33_5 = display.newNode()

			var_33_5:setContentSize(85, 85)
			var_33_5:setAnchorPoint(cc.p(0.5, 0))
			xyd.setItemBorder(var_33_5, var_33_4.itemID, nil, true, nil)
			var_33_5:addTo(var_33_0)
			var_33_5:setPosition(cc.p(var_33_2, var_33_3))

			var_33_2 = var_33_2 + var_33_1

			if arg_33_0.currentItem and arg_33_0.currentItem == var_33_4 then
				arg_33_0:addSelectEffectForItem(var_33_5)
			end

			var_33_5:setTouchEnabled(true)
			var_33_5:setTouchSwallowEnabled(false)
			var_33_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
				if arg_34_0.name == "began" and arg_33_0.scrollViewMoved_ ~= true then
					var_33_5:setScale(0.9)

					return true
				elseif arg_34_0.name == "ended" then
					var_33_5:setScale(1)

					if arg_33_0.currentItem ~= var_33_4 then
						arg_33_0.currentItem = var_33_4
						arg_33_0.itemState = var_0_4.CannotMake

						arg_33_0:update()
					end

					arg_33_0:addSelectEffectForItem(var_33_5)
				end
			end)
		end
	end

	return var_33_0
end

function var_0_0.setButtonClick(arg_35_0)
	arg_35_0:nodeByName("make_btn"):addTouchEventListener(function(arg_36_0, arg_36_1)
		xyd.buttonScaleAnim(arg_35_0:nodeByName("make_btn"), arg_36_1)

		if arg_36_1 == ccui.TouchEventType.ended and arg_35_0.currentItem then
			xyd.playButtonSound()
			arg_35_0:doMakingItem()
		end
	end)
	arg_35_0:nodeByName("recommend_btn"):addTouchEventListener(function(arg_37_0, arg_37_1)
		xyd.buttonScaleAnim(arg_35_0:nodeByName("recommend_btn"), arg_37_1)

		if arg_37_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_37_0 = {
				listItems = arg_35_0.listItems,
				nextLevItems = arg_35_0.nextLevItems
			}

			xyd.WindowManager.get():openWindow("recommend_wnd", var_37_0)
		end
	end)
	arg_35_0:nodeByName("upgrade_btn"):addTouchEventListener(function(arg_38_0, arg_38_1)
		xyd.buttonScaleAnim(arg_35_0:nodeByName("upgrade_btn"), arg_38_1)

		if arg_38_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_35_0.lev >= xyd.tables.eventCentreTable:maxLev(xyd.EventCentreBuildingType.DESK) then
				local var_38_0 = string.format(var_0_1:translation("HIGHEST_LEV"), arg_35_0.buildingName)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_38_0
				})

				return
			end

			if arg_35_0.deskInfo.is_making == 1 then
				local var_38_1 = var_0_1:translation("ON_MAKING_CANNOT_UPGRADE")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_38_1
				})

				return
			end

			local var_38_2 = {
				type = xyd.EventCentreBuildingType.DESK,
				lev = arg_35_0.lev
			}

			xyd.WindowManager.get():openWindow("event_centre_upgrade", var_38_2)
		end
	end)
	arg_35_0:nodeByName("speed_up_btn"):addTouchEventListener(function(arg_39_0, arg_39_1)
		xyd.buttonScaleAnim(arg_35_0:nodeByName("speed_up_btn"), arg_39_1)

		if arg_39_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_39_0 = arg_35_0.deskInfo.building_info.need_time - (xyd.ServerTime.get():getServerTime() - arg_35_0.deskInfo.building_info.start_time)
			local var_39_1 = arg_35_0.eventCentre:getUpgradeCost(var_39_0)
			local var_39_2 = string.format(var_0_1:translation("COST_TO_UPGRADE"), var_39_1, arg_35_0.lev + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_39_2, function()
				arg_35_0:doSpeedUp(var_39_1)
			end, nil, 0, xyd.ColorMode.GREEN)
		end
	end)
	arg_35_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_41_0, arg_41_1)
		xyd.buttonScaleAnim(arg_35_0:nodeByName("cancel_btn"), arg_41_1)

		if arg_41_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_41_0 = var_0_1:translation("CANCEL_UPGRADE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_41_0, function()
				arg_35_0:doCancelEvolve()
			end, nil, nil, xyd.ColorMode.GREEN)
		end
	end)
	arg_35_0:nodeByName("cancel_make"):setTouchEnabled(true)
	arg_35_0:nodeByName("cancel_make"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_43_0)
		if arg_43_0.name == "began" then
			return true
		elseif arg_43_0.name == "ended" then
			xyd.playButtonSound()

			if arg_35_0.deskInfo.is_making > 0 then
				local var_43_0 = var_0_1:translation("CANCEL_MAKING")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_43_0, function()
					arg_35_0:cancelMaking()
				end, nil, nil, xyd.ColorMode.GREEN)
			end
		end
	end)

	if arg_35_0.deskInfo.is_making == 0 then
		arg_35_0:nodeByName("accelerate"):setVisible(false)
	end

	xyd.nodeEventSample(arg_35_0:nodeByName("accelerate"), nil, function(arg_45_0)
		xyd.playButtonSound()

		local function var_45_0(arg_46_0)
			arg_35_0:refreshMakeItem(arg_46_0)
		end

		local var_45_1 = {
			callback = var_45_0,
			building_type = xyd.EventCentreBuildingType.DESK,
			building_info = arg_35_0.eventCentre.deskInfo
		}

		xyd.WindowManager.get():openWindow("make_accelerate", var_45_1)
	end)
end

function var_0_0.cancelMaking(arg_47_0)
	local var_47_0 = {
		building_type = xyd.EventCentreBuildingType.DESK
	}

	arg_47_0.eventCentre:cancelMaking(var_47_0, function(arg_48_0, arg_48_1)
		if arg_48_0 == xyd.error.OK then
			arg_47_0:refreshMakeItem(arg_48_1)

			local var_48_0 = {
				resolve_types = arg_48_1.make_res_type,
				resolve_nums = arg_48_1.make_res_num,
				resolve_crits = {}
			}

			xyd.WindowManager.get():openWindow("recycle_award", var_48_0)
		end
	end)
end

function var_0_0.doMakingItem(arg_49_0)
	if arg_49_0.deskInfo.is_making == 1 or arg_49_0.deskInfo.make_item and arg_49_0.deskInfo.make_item > 0 then
		local var_49_0 = var_0_1:translation("ON_MAKING_ITEM")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_49_0
		})

		return
	end

	if arg_49_0.deskInfo.building_info.need_time > 0 then
		local var_49_1 = string.format(var_0_1:translation("ON_UPGRADE_CANNOT_MAKE"), arg_49_0.buildingName)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_49_1
		})

		return
	end

	local var_49_2 = {
		item_id = arg_49_0.currentItem.itemID
	}

	arg_49_0.eventCentre:makeItem(var_49_2, function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK then
			arg_49_0.deskInfo.making_item = arg_49_0.currentItem.itemID

			arg_49_0:refreshMakeItem(arg_50_1)
		end
	end)
end

function var_0_0.refreshMakeItem(arg_51_0, arg_51_1)
	if arg_51_1.make_item then
		arg_51_0.deskInfo.make_item = arg_51_1.make_item
	end

	if arg_51_1.is_making then
		arg_51_0.deskInfo.is_making = arg_51_1.is_making
	end

	if arg_51_1.making_item then
		arg_51_0.deskInfo.making_item = arg_51_1.making_item
	end

	if arg_51_1.make_need_time then
		arg_51_0.deskInfo.make_need_time = arg_51_1.make_need_time
	end

	if arg_51_1.make_start_time then
		arg_51_0.deskInfo.make_start_time = arg_51_1.make_start_time
	end

	arg_51_0.eventCentre.deskInfo = arg_51_0.deskInfo

	arg_51_0:initialVariable()
	arg_51_0:update()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_MAGIC_RES
	})
end

function var_0_0.doSpeedUp(arg_52_0, arg_52_1)
	if arg_52_1 > arg_52_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
			local var_53_0 = {}

			var_53_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_53_0)
		end, nil, nil, xyd.ColorMode.GREEN)
	else
		local var_52_0 = {
			type = xyd.EventCentreBuildingType.DESK
		}

		arg_52_0.eventCentre:speedUpBuilding(var_52_0, function(arg_54_0, arg_54_1)
			if arg_54_0 == xyd.error.OK then
				arg_52_0.deskInfo.building_info.start_time = arg_54_1.start_time
				arg_52_0.deskInfo.building_info.need_time = arg_54_1.need_time
				arg_52_0.deskInfo.building_info.lev = arg_54_1.lev
				arg_52_0.deskInfo.building_info.new_evolve = arg_54_1.new_evolve

				arg_52_0:updateList()
				arg_52_0:update()
			end
		end)
	end
end

function var_0_0.doCancelEvolve(arg_55_0)
	local var_55_0 = {
		type = xyd.EventCentreBuildingType.DESK
	}

	arg_55_0.eventCentre:cancelEvolveBuilding(var_55_0, function(arg_56_0, arg_56_1)
		if arg_56_0 == xyd.error.OK then
			arg_55_0.deskInfo.building_info = arg_56_1.building_info

			arg_55_0:initialVariable()
			arg_55_0:update()
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_MAGIC_RES
			})

			local var_56_0 = {
				resolve_types = arg_56_1.return_res_id,
				resolve_nums = arg_56_1.return_res_num,
				resolve_crits = {}
			}

			xyd.WindowManager.get():openWindow("recycle_award", var_56_0)
		end
	end)
end

function var_0_0.didOpen(arg_57_0, arg_57_1)
	var_0_0.super:didOpen(arg_57_1)
	arg_57_0:addBlockLayer()
end

function var_0_0.didClose(arg_58_0, arg_58_1)
	var_0_0.super:didClose(arg_58_1)

	if arg_58_0.handle then
		var_0_2.unscheduleGlobal(arg_58_0.handle)

		arg_58_0.handle = nil
	end

	if arg_58_0.handle1 then
		var_0_2.unscheduleGlobal(arg_58_0.handle1)

		arg_58_0.handle1 = nil
	end
end

function var_0_0.scrollListener(arg_59_0, arg_59_1)
	if arg_59_1.name == "began" then
		arg_59_0.scrollViewMoved_ = false
		arg_59_0.prevX_ = arg_59_1.x
	elseif arg_59_1.name == "moved" and 5 <= math.abs(arg_59_1.x - arg_59_0.prevX_) then
		arg_59_0.scrollViewMoved_ = true
	end
end

return var_0_0
