local var_0_0 = class("PetRoomWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = {
	CannotMake = 3,
	CanMake = 2,
	None = 1
}
local var_0_5 = 7

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.listItems = {}
	arg_1_0.nextLevItems = {}
	arg_1_0.itemState = var_0_4.None
	arg_1_0.petRoomInfo = arg_1_0.eventCentre.petRoomInfo

	if arg_1_0.petRoomInfo.pet_id > 0 then
		arg_1_0.currentHero = arg_1_0.selfPlayer:getPetByID(arg_1_0.petRoomInfo.pet_id)
	end

	arg_1_0.buildingName = xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.PETROOM)
end

function var_0_0.updateList(arg_2_0)
	arg_2_0:initialVariable()
	arg_2_0:initialListItems()
	arg_2_0.itemList:reload()
end

function var_0_0.initialVariable(arg_3_0)
	arg_3_0.lev = arg_3_0.petRoomInfo.building_info.lev
	arg_3_0.eventCentre.buidingInfo[tostring(xyd.EventCentreBuildingType.PETROOM)].lev = arg_3_0.lev
	arg_3_0.currentTime = xyd.ServerTime.get():getServerTime()
	arg_3_0.makingTime = 0

	if arg_3_0.petRoomInfo.is_making == 1 then
		arg_3_0.makingTime = arg_3_0.petRoomInfo.make_need_time - (arg_3_0.currentTime - arg_3_0.petRoomInfo.make_start_time)
	end
end

function var_0_0.updateAssetsShow(arg_4_0)
	arg_4_0:nodeByName("candy_num_txt1"):setString(arg_4_0.backPack:getItemNumByID(xyd.tables.misc.eventCentrePetCostItem[1]))
	arg_4_0:nodeByName("candy_num_txt2"):setString(arg_4_0.backPack:getItemNumByID(xyd.tables.misc.eventCentrePetCostItem[2]))
end

function var_0_0.initialListItems(arg_5_0)
	if not arg_5_0.currentHero then
		return
	end

	local var_5_0 = arg_5_0.lev

	arg_5_0.listItems = {}
	arg_5_0.nextLevItems = {}

	for iter_5_0 = 1, tonumber(var_5_0) do
		local var_5_1 = xyd.tables.hero:getTableItemId(arg_5_0.currentHero:getTableID(), iter_5_0)

		for iter_5_1 = 1, #var_5_1 do
			local var_5_2 = {
				itemID = var_5_1[iter_5_1]
			}

			var_5_2.itemNum = 0

			table.insert(arg_5_0.listItems, arg_5_0.backPack:getItemByID(var_5_1[iter_5_1]) or var_5_2)
		end
	end

	local var_5_3 = xyd.tables.hero:getTableItemId(arg_5_0.currentHero:getTableID(), var_5_0 + 1)

	for iter_5_2 = 1, #var_5_3 do
		local var_5_4 = {
			itemID = var_5_3[iter_5_2]
		}

		var_5_4.itemNum = 0

		table.insert(arg_5_0.nextLevItems, var_5_4)
	end

	table.sort(arg_5_0.listItems, function(arg_6_0, arg_6_1)
		return arg_6_0.itemID < arg_6_1.itemID
	end)
	table.sort(arg_5_0.nextLevItems, function(arg_7_0, arg_7_1)
		return arg_7_0.itemID < arg_7_1.itemID
	end)
end

function var_0_0.createTimeString(arg_8_0, arg_8_1)
	return xyd.secondsToString1(arg_8_1)
end

function var_0_0.willOpen(arg_9_0, arg_9_1)
	var_0_0.super.willOpen(arg_9_0, arg_9_1)
	arg_9_0:initialVariable()
	arg_9_0:updateAssetsShow()
	arg_9_0:layout()
end

function var_0_0.layout(arg_10_0)
	arg_10_0:nodeByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))
	arg_10_0:nodeByName("txt_speed_up"):setString(var_0_1:translation("EVENT_CENTRE_TIP2"))
	arg_10_0:nodeByName("txt_title"):setString(xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.PETROOM))
	arg_10_0:nodeByName("upgrade_txt"):setString(var_0_1:translation("HERO_MAIN_TEXT_13"))
	arg_10_0:nodeByName("txt_make"):setString(var_0_1:translation("EVENT_CENTRE_TIP1"))
	arg_10_0:nodeByName("txt_accelerate"):setString(var_0_1:translation("EVENT_CENTRE_TIP2"))
	arg_10_0:nodeByName("select_txt"):setString(var_0_1:translation("CLOUD_CITY_GUIDE_2"))
	arg_10_0:nodeByName("switch_txt"):setString(var_0_1:translation("EVENT_CENTRE_TIP3"))
	arg_10_0:nodeByName("txt_name"):setString(var_0_1:translation("EVENT_CENTRE_TIP4"))

	arg_10_0.scroll = arg_10_0:nodeByName("scroll")

	local var_10_0 = arg_10_0.scroll:getContentSize()

	if not arg_10_0.itemList then
		arg_10_0.itemList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 5, var_10_0.width, var_10_0.height - 5),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_10_0.scroll):onScroll(handler(arg_10_0, arg_10_0.scrollListener))
	else
		arg_10_0.nodeX = arg_10_0.itemList.scrollNode:getPositionX()
		arg_10_0.nodeY = arg_10_0.itemList.scrollNode:getPositionY()

		arg_10_0.itemList:removeAllItems()
	end

	arg_10_0.itemList:setDelegate(handler(arg_10_0, arg_10_0.itemListDelegate))
	arg_10_0.itemList:setBounceable(true)
	arg_10_0:updateCurrentPet(arg_10_0.currentHero)
	arg_10_0:nodeByName("equip_consum_text"):setString(var_0_1:translation("EQUIP_CONSUM_TEXT"))
	arg_10_0:nodeByName("own_text"):setString(var_0_1:translation("OWN_TEXT"))
	arg_10_0:setButtonClick()
	arg_10_0:update()
end

function var_0_0.update(arg_11_0)
	arg_11_0:updateMakingItemInfo()
	arg_11_0:updateBottomShow()
	arg_11_0:updateBottomLeftShow()
	arg_11_0:updateBottomRigthShow()
	arg_11_0:updateUpgradeTime()
	arg_11_0:updateLevShow()
	arg_11_0:updateAssetsShow()
end

function var_0_0.updateLevShow(arg_12_0)
	arg_12_0:nodeByName("txt_lv"):setString("LV" .. arg_12_0.lev)

	if arg_12_0.petRoomInfo.building_info.new_evolve == 1 then
		local var_12_0 = {
			type = xyd.EventCentreBuildingType.PETROOM
		}

		arg_12_0.eventCentre:confirmBuildingUpgrade(var_12_0, function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				arg_12_0.petRoomInfo.building_info.new_evolve = 0

				local var_13_0 = {
					lev = arg_12_0.lev,
					type = xyd.EventCentreBuildingType.PETROOM
				}

				arg_12_0:updateList()
				xyd.WindowManager.get():openWindow("building_levelup", var_13_0)
			end
		end)
	end
end

function var_0_0.updateUpgradeTime(arg_14_0)
	if arg_14_0.handle1 then
		var_0_2.unscheduleGlobal(arg_14_0.handle1)

		arg_14_0.handle1 = nil
	end

	local var_14_0

	if arg_14_0.petRoomInfo.building_info.start_time > 0 then
		var_14_0 = arg_14_0.petRoomInfo.building_info.need_time - (xyd.ServerTime.get():getServerTime() - arg_14_0.petRoomInfo.building_info.start_time)
	else
		var_14_0 = 0
	end

	if var_14_0 > 0 then
		arg_14_0:nodeByName("upgrade_btn"):setVisible(false)
		arg_14_0:nodeByName("upgrade_time"):setVisible(true)
		arg_14_0:nodeByName("txt_upgrade_time"):setString(xyd.secondsToString1(var_14_0))

		arg_14_0.handle1 = var_0_2.scheduleGlobal(function()
			var_14_0 = var_14_0 - 1

			if not tolua.isnull(arg_14_0) then
				arg_14_0:nodeByName("txt_upgrade_time"):setString(xyd.secondsToString1(var_14_0))
				arg_14_0:nodeByName("time_progress_bar"):setPercent(100 - 100 * var_14_0 / arg_14_0.petRoomInfo.building_info.need_time)
			end

			if var_14_0 <= 0 and arg_14_0.handle1 then
				var_0_2.unscheduleGlobal(arg_14_0.handle1)

				arg_14_0.handle1 = nil

				if not tolua.isnull(arg_14_0) then
					arg_14_0:nodeByName("upgrade_btn"):setVisible(true)
					arg_14_0:nodeByName("upgrade_time"):setVisible(false)
					arg_14_0:nodeByName("time_progress_bar"):setPercent(0)
				end
			end
		end, 1)
	else
		arg_14_0:nodeByName("upgrade_btn"):setVisible(true)
		arg_14_0:nodeByName("upgrade_time"):setVisible(false)
	end
end

function var_0_0.updateMakingItemInfo(arg_16_0)
	arg_16_0:nodeByName("item_container"):removeAllChildren(true)
	arg_16_0:nodeByName("item_container"):setVisible(true)

	if arg_16_0.makingTime > 0 and arg_16_0.petRoomInfo.is_making == 1 then
		arg_16_0:createScheduler()
		arg_16_0:nodeByName("bg_make_progress"):setVisible(true)
		arg_16_0:nodeByName("down_time_txt"):setVisible(true)
		arg_16_0:nodeByName("cancel_make"):setVisible(true)
		xyd.setItemBorder(arg_16_0:nodeByName("item_container"), arg_16_0.petRoomInfo.making_item, nil, nil, nil)
	elseif arg_16_0.currentItem then
		arg_16_0:nodeByName("bg_make_progress"):setVisible(true)
		arg_16_0:nodeByName("down_time_txt"):setVisible(false)
		arg_16_0:nodeByName("cancel_make"):setVisible(false)
		arg_16_0:nodeByName("make_progress_bar"):setPercent(0)
		xyd.setItemBorder(arg_16_0:nodeByName("item_container"), arg_16_0.currentItem.itemID, nil, nil, nil)
	else
		arg_16_0:nodeByName("item_container"):setVisible(false)
		arg_16_0:nodeByName("bg_make_progress"):setVisible(false)
		arg_16_0:nodeByName("down_time_txt"):setVisible(false)
		arg_16_0:nodeByName("cancel_make"):setVisible(false)
	end

	if arg_16_0.petRoomInfo.make_item and arg_16_0.petRoomInfo.make_item > 0 then
		arg_16_0:handleMakeItem(arg_16_0.petRoomInfo.make_item)
	end

	if arg_16_0.petRoomInfo.is_making == 0 then
		arg_16_0:nodeByName("accelerate"):setVisible(false)
	else
		arg_16_0:nodeByName("accelerate"):setVisible(true)
	end
end

function var_0_0.handleMakeItem(arg_17_0, arg_17_1)
	local var_17_0 = {
		building_type = xyd.EventCentreBuildingType.PETROOM
	}

	arg_17_0.eventCentre:confirmMakeItem(var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK and arg_17_0 then
			local var_18_0 = {
				resolve_types = {},
				resolve_nums = {},
				resolve_crits = {}
			}

			for iter_18_0 = 1, #arg_18_1.items do
				table.insert(var_18_0.resolve_types, arg_18_1.items[iter_18_0].table_id)
				table.insert(var_18_0.resolve_nums, arg_18_1.items[iter_18_0].item_num)
			end

			xyd.WindowManager.get():openWindow("recycle_award", var_18_0)

			local var_18_1 = xyd.WindowManager.get():getWindow("event_centre")

			if var_18_1 and not tolua.isnull(var_18_1) then
				var_18_1:updateRedPointShow()
			end

			if arg_17_0 and not tolua.isnull(arg_17_0.itemList) then
				arg_17_0.petRoomInfo.make_item = 0

				arg_17_0.itemList:refreshList()
			end
		end
	end)
end

function var_0_0.createScheduler(arg_19_0)
	if arg_19_0.handle then
		var_0_2.unscheduleGlobal(arg_19_0.handle)

		arg_19_0.handle = nil
	end

	arg_19_0.makingTime = arg_19_0.petRoomInfo.make_need_time - (xyd.ServerTime.get():getServerTime() - arg_19_0.petRoomInfo.make_start_time)

	arg_19_0:updateMakingTime()

	arg_19_0.handle = var_0_2.scheduleGlobal(function()
		arg_19_0.currentTime = arg_19_0.currentTime + 1
		arg_19_0.makingTime = arg_19_0.makingTime - 1

		if arg_19_0.makingTime <= 0 then
			if arg_19_0.handle then
				var_0_2.unscheduleGlobal(arg_19_0.handle)

				arg_19_0.handle = nil
			end

			arg_19_0.eventCentre:getPetRoomInfo({}, function(arg_21_0, arg_21_1)
				if arg_21_0 == xyd.error.OK then
					arg_19_0.petRoomInfo = arg_19_0.eventCentre.petRoomInfo

					arg_19_0:update()
				end
			end)
		end

		arg_19_0:updateMakingTime()
	end, 1)
end

function var_0_0.updateMakingTime(arg_22_0)
	local var_22_0 = arg_22_0.petRoomInfo.making_item

	if var_22_0 and var_22_0 > 0 and arg_22_0.currentHero then
		local var_22_1 = arg_22_0:createTimeString(arg_22_0.makingTime)

		arg_22_0:nodeByName("down_time_txt"):setString(var_22_1)

		local var_22_2 = (arg_22_0.currentHero:getColor() - 1) * xyd.tables.misc.eventCentrePetColorAccelerateTime
		local var_22_3 = xyd.tables.item:makeTime(var_22_0) - var_22_2

		arg_22_0:nodeByName("make_progress_bar"):setPercent(100 - 100 * arg_22_0.makingTime / var_22_3)
	end
end

function var_0_0.updateBottomShow(arg_23_0)
	arg_23_0:nodeByName("bottom_left_container"):setVisible(false)
	arg_23_0:nodeByName("bottom_right_container"):setVisible(false)
	arg_23_0:nodeByName("select_make_item"):setVisible(false)

	if arg_23_0.itemState == var_0_4.None then
		arg_23_0:nodeByName("select_make_item"):setString(var_0_1:translation("SELECT_MAKE_ITEM"))
		arg_23_0:nodeByName("select_make_item"):setVisible(true)
	elseif arg_23_0.itemState == var_0_4.CannotMake then
		arg_23_0:nodeByName("select_make_item"):setString(string.format(var_0_1:translation("LVN_CAN_MAKE"), arg_23_0.buildingName, arg_23_0.petRoomInfo.building_info.lev + 1))
		arg_23_0:nodeByName("select_make_item"):setVisible(true)
		arg_23_0:nodeByName("bottom_left_container"):setVisible(true)
	else
		arg_23_0:nodeByName("bottom_left_container"):setVisible(true)
		arg_23_0:nodeByName("bottom_right_container"):setVisible(true)
	end
end

function var_0_0.updateBottomLeftShow(arg_24_0)
	if arg_24_0.currentItem then
		arg_24_0:nodeByName("equip_name_text"):setString(xyd.tables.item:name(arg_24_0.currentItem.itemID))

		local var_24_0 = arg_24_0.backPack:getItemNumByID(arg_24_0.currentItem.itemID)

		arg_24_0:nodeByName("own_num_txt"):setString(var_24_0)

		local var_24_1 = (arg_24_0.currentHero:getColor() - 1) * xyd.tables.misc.eventCentrePetColorAccelerateTime
		local var_24_2 = arg_24_0:createTimeString(xyd.tables.item:makeTime(arg_24_0.currentItem.itemID) - var_24_1)

		arg_24_0:nodeByName("time_txt"):setString(var_24_2)
	end
end

function var_0_0.updateBottomRigthShow(arg_25_0)
	if arg_25_0.currentItem then
		arg_25_0:nodeByName("consum_pos"):removeAllChildren()

		local var_25_0 = xyd.tables.item:makeResType(arg_25_0.currentItem.itemID)
		local var_25_1 = xyd.tables.item:makeResNum(arg_25_0.currentItem.itemID)
		local var_25_2 = arg_25_0:createItemsContent(var_25_0, var_25_1)

		var_25_2:setAnchorPoint(cc.p(0, 0.5))
		var_25_2:addTo(arg_25_0:nodeByName("consum_pos"))
		var_25_2:setPosition(cc.p(-5, 0))

		if arg_25_0.resourceNotEnough then
			arg_25_0:nodeByName("make_btn"):setVisible(false)
		else
			arg_25_0:nodeByName("make_btn"):setVisible(true)
		end
	end
end

function var_0_0.createItemsContent(arg_26_0, arg_26_1, arg_26_2)
	arg_26_0.resourceNotEnough = false

	local var_26_0 = display.newNode()
	local var_26_1 = -32
	local var_26_2 = 25

	for iter_26_0 = 1, #arg_26_1 do
		var_26_1 = var_26_1 + 32

		local var_26_3
		local var_26_4 = arg_26_0.backPack:getItemNumByID(arg_26_1[iter_26_0])
		local var_26_5 = arg_26_1[iter_26_0] == xyd.tables.misc.eventCentrePetCostItem[1] and "windows/event_centre/pet_room/candy1.png" or arg_26_1[iter_26_0] == xyd.tables.misc.eventCentrePetCostItem[2] and "windows/event_centre/pet_room/candy2.png" or xyd.tables.item:icon(arg_26_1[iter_26_0])
		local var_26_6

		if var_26_5 then
			var_26_6 = xyd.AssetLoader.get():loadSprite(var_26_5)
		end

		var_26_6:addTo(var_26_0)
		var_26_6:setAnchorPoint(0, 0.5)
		var_26_6:setPosition(var_26_1, var_26_2)

		local var_26_7 = 60

		if var_26_7 > var_26_6:getContentSize().width then
			var_26_1 = var_26_1 + var_26_6:getContentSize().width + 10
		else
			var_26_6:setScale(var_26_7 / var_26_6:getContentSize().width)

			var_26_1 = var_26_1 + var_26_7 + 10
		end

		local var_26_8 = cc.c3b(28, 160, 31)

		if var_26_4 < arg_26_2[iter_26_0] then
			arg_26_0.resourceNotEnough = true
		end

		local var_26_9 = arg_26_0:createItemNumLabel(arg_26_2[iter_26_0], var_26_8)

		var_26_9:addTo(var_26_0)
		var_26_9:setAnchorPoint(0, 0.5)
		var_26_9:setPosition(var_26_1, var_26_2)

		var_26_1 = var_26_1 + var_26_9:getContentSize().width
	end

	var_26_0:setContentSize(var_26_1, 50)

	return var_26_0
end

function var_0_0.createItemNumLabel(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = {
		font = "fonts/main_font.ttf",
		size = 26,
		color = arg_27_2 or cc.c3b(255, 255, 255)
	}
	local var_27_1 = xyd.AssetLoader.get():loadLabel(var_27_0)

	var_27_1:setMaxLineWidth(250)
	var_27_1:setString(arg_27_1)

	return var_27_1
end

function var_0_0.itemListDelegate(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	if cc.ui.UIListView.COUNT_TAG == arg_28_2 then
		if #arg_28_0.nextLevItems > 0 then
			return math.ceil(#arg_28_0.listItems / var_0_5) + 1 + math.ceil(#arg_28_0.nextLevItems / var_0_5)
		else
			return math.ceil(#arg_28_0.listItems / var_0_5)
		end
	elseif cc.ui.UIListView.CELL_TAG == arg_28_2 then
		local var_28_0
		local var_28_1 = arg_28_0.itemList:dequeueItem()

		if not var_28_1 then
			var_28_1 = arg_28_0.itemList:newItem()
		else
			var_28_1:removeAllChildren(true)
		end

		local var_28_2

		if arg_28_3 <= math.ceil(#arg_28_0.listItems / var_0_5) then
			var_28_2 = arg_28_0:createListContent(arg_28_3)
		elseif arg_28_3 == math.ceil(#arg_28_0.listItems / var_0_5) + 1 then
			var_28_2 = arg_28_0:creatNextLevTitleContent()
		else
			var_28_2 = arg_28_0:createNextLevContent(arg_28_3 - math.ceil(#arg_28_0.listItems / var_0_5) - 1)
		end

		local var_28_3 = var_28_2:getWidth()
		local var_28_4 = var_28_2:getHeight()

		var_28_1:setItemSize(var_28_3, var_28_4)
		var_28_1:addContent(var_28_2)

		return var_28_1
	end
end

function var_0_0.createListContent(arg_29_0, arg_29_1)
	local var_29_0 = display.newNode()
	local var_29_1 = 105
	local var_29_2 = 50
	local var_29_3 = 10

	var_29_0:setContentSize(750, 100)

	for iter_29_0 = 1, var_0_5 do
		if (arg_29_1 - 1) * var_0_5 + iter_29_0 <= #arg_29_0.listItems then
			local var_29_4 = arg_29_0.listItems[(arg_29_1 - 1) * var_0_5 + iter_29_0]
			local var_29_5 = display.newNode()

			var_29_5:setContentSize(80, 80)
			var_29_5:setAnchorPoint(cc.p(0.5, 0))
			xyd.setItemBorder(var_29_5, var_29_4.itemID, nil, nil, var_29_4.itemNum, nil, true)
			var_29_5:addTo(var_29_0)
			var_29_5:setPosition(cc.p(var_29_2, var_29_3))

			var_29_2 = var_29_2 + var_29_1

			if arg_29_0.currentItem and arg_29_0.currentItem == var_29_4 then
				arg_29_0:addSelectEffectForItem(var_29_5)
			end

			var_29_5:setTouchEnabled(true)
			var_29_5:setTouchSwallowEnabled(false)
			var_29_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
				if arg_30_0.name == "began" and arg_29_0.scrollViewMoved_ ~= true then
					var_29_5:setScale(0.9)

					return true
				elseif arg_30_0.name == "ended" then
					var_29_5:setScale(1)

					if arg_29_0.currentItem ~= var_29_4 then
						arg_29_0.currentItem = var_29_4
						arg_29_0.itemState = var_0_4.CanMake

						arg_29_0:update()
					end

					arg_29_0:addSelectEffectForItem(var_29_5)
				end
			end)
		end
	end

	return var_29_0
end

function var_0_0.addSelectEffectForItem(arg_31_0, arg_31_1)
	if not tolua.isnull(arg_31_0.effect) and arg_31_0.effect then
		transition.stopTarget(arg_31_0.effect)
		arg_31_0.effect:removeSelf()

		arg_31_0.effect = nil
	end

	arg_31_0.effect = xyd.AssetLoader:get():loadSprite("windows/event_centre/bg_select.png")

	arg_31_0.effect:setAnchorPoint(0.5, 0.5)
	arg_31_0.effect:addTo(arg_31_1)
	arg_31_0.effect:setPosition(cc.p(arg_31_1:getContentSize().width / 2, arg_31_1:getContentSize().height / 2))
	arg_31_0.effect:setName("effect")
	arg_31_0.effect:setScale(0.75)

	local var_31_0 = transition.sequence({
		cc.ScaleTo:create(0.3, 0.78),
		cc.ScaleTo:create(0.3, 0.75)
	})
	local var_31_1 = cc.RepeatForever:create(var_31_0)

	arg_31_0.effect:runAction(var_31_1)
end

function var_0_0.creatNextLevTitleContent(arg_32_0)
	local var_32_0 = display.newNode()

	var_32_0:setContentSize(995, 40)

	local var_32_1 = arg_32_0:creatNextLevLabel()

	var_32_1:setAnchorPoint(cc.p(0, 0))
	var_32_1:addTo(var_32_0)
	var_32_1:setPosition(cc.p(10, 2))

	return var_32_0
end

function var_0_0.creatNextLevLabel(arg_33_0)
	local var_33_0 = string.format(var_0_1:translation("NEXT_LEV_MAKE"), arg_33_0.buildingName)
	local var_33_1 = {
		font = "fonts/main_font.ttf",
		size = 26,
		color = cc.c3b(68, 69, 77)
	}
	local var_33_2 = xyd.AssetLoader.get():loadLabel(var_33_1)

	var_33_2:setMaxLineWidth(500)
	var_33_2:setString(var_33_0)

	return var_33_2
end

function var_0_0.createNextLevContent(arg_34_0, arg_34_1)
	local var_34_0 = display.newNode()
	local var_34_1 = 105
	local var_34_2 = 50
	local var_34_3 = 10

	var_34_0:setContentSize(750, 100)

	for iter_34_0 = 1, var_0_5 do
		if (arg_34_1 - 1) * var_0_5 + iter_34_0 <= #arg_34_0.nextLevItems then
			local var_34_4 = arg_34_0.nextLevItems[(arg_34_1 - 1) * var_0_5 + iter_34_0]
			local var_34_5 = display.newNode()

			var_34_5:setContentSize(80, 80)
			var_34_5:setAnchorPoint(cc.p(0.5, 0))
			xyd.setItemBorder(var_34_5, var_34_4.itemID, nil, true, nil)
			var_34_5:addTo(var_34_0)
			var_34_5:setPosition(cc.p(var_34_2, var_34_3))

			var_34_2 = var_34_2 + var_34_1

			if arg_34_0.currentItem and arg_34_0.currentItem == var_34_4 then
				arg_34_0:addSelectEffectForItem(var_34_5)
			end

			var_34_5:setTouchEnabled(true)
			var_34_5:setTouchSwallowEnabled(false)
			var_34_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_35_0)
				if arg_35_0.name == "began" and arg_34_0.scrollViewMoved_ ~= true then
					var_34_5:setScale(0.9)

					return true
				elseif arg_35_0.name == "ended" then
					var_34_5:setScale(1)

					if arg_34_0.currentItem ~= var_34_4 then
						arg_34_0.currentItem = var_34_4
						arg_34_0.itemState = var_0_4.CannotMake

						arg_34_0:update()
					end

					arg_34_0:addSelectEffectForItem(var_34_5)
				end
			end)
		end
	end

	return var_34_0
end

function var_0_0.setButtonClick(arg_36_0)
	arg_36_0:nodeByName("make_btn"):addTouchEventListener(function(arg_37_0, arg_37_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("make_btn"), arg_37_1)

		if arg_37_1 == ccui.TouchEventType.ended and arg_36_0.currentItem then
			xyd.playButtonSound()
			arg_36_0:doMakingItem()
		end
	end)
	xyd.nodeEventSample(arg_36_0:nodeByName("switch_btn"), nil, function(arg_38_0)
		xyd.playButtonSound()
		arg_36_0:changeCurrentPet()
	end)
	arg_36_0:nodeByName("upgrade_btn"):addTouchEventListener(function(arg_39_0, arg_39_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("upgrade_btn"), arg_39_1)

		if arg_39_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_36_0.lev >= xyd.tables.eventCentreTable:maxLev(xyd.EventCentreBuildingType.PETROOM) then
				local var_39_0 = string.format(var_0_1:translation("HIGHEST_LEV"), arg_36_0.buildingName)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_39_0
				})

				return
			end

			if arg_36_0.petRoomInfo.is_making == 1 then
				local var_39_1 = var_0_1:translation("ON_MAKING_CANNOT_UPGRADE")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_39_1
				})

				return
			end

			local var_39_2 = {
				type = xyd.EventCentreBuildingType.PETROOM,
				lev = arg_36_0.lev
			}

			xyd.WindowManager.get():openWindow("event_centre_upgrade", var_39_2)
		end
	end)
	arg_36_0:nodeByName("speed_up_btn"):addTouchEventListener(function(arg_40_0, arg_40_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("speed_up_btn"), arg_40_1)

		if arg_40_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_40_0 = arg_36_0.petRoomInfo.building_info.need_time - (xyd.ServerTime.get():getServerTime() - arg_36_0.petRoomInfo.building_info.start_time)
			local var_40_1 = arg_36_0.eventCentre:getUpgradeCost(var_40_0)
			local var_40_2 = string.format(var_0_1:translation("COST_TO_UPGRADE"), var_40_1, arg_36_0.lev + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_40_2, function()
				arg_36_0:doSpeedUp(var_40_1)
			end, nil, 0, xyd.ColorMode.GREEN)
		end
	end)
	arg_36_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_42_0, arg_42_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("cancel_btn"), arg_42_1)

		if arg_42_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_42_0 = var_0_1:translation("CANCEL_UPGRADE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_42_0, function()
				arg_36_0:doCancelEvolve()
			end, nil, nil, xyd.ColorMode.GREEN)
		end
	end)
	arg_36_0:nodeByName("cancel_make"):setTouchEnabled(true)
	arg_36_0:nodeByName("cancel_make"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_44_0)
		if arg_44_0.name == "began" then
			return true
		elseif arg_44_0.name == "ended" then
			xyd.playButtonSound()

			if arg_36_0.petRoomInfo.is_making > 0 then
				local var_44_0 = var_0_1:translation("CANCEL_MAKING")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_44_0, function()
					arg_36_0:cancelMaking()
				end, nil, nil, xyd.ColorMode.GREEN)
			end
		end
	end)

	if arg_36_0.petRoomInfo.is_making == 0 then
		arg_36_0:nodeByName("accelerate"):setVisible(false)
	else
		arg_36_0:nodeByName("accelerate"):setVisible(true)
	end

	arg_36_0:nodeByName("accelerate"):setTouchEnabled(true)
	xyd.nodeEventSample(arg_36_0:nodeByName("accelerate"), nil, function(arg_46_0)
		xyd.playButtonSound()

		local function var_46_0(arg_47_0)
			arg_36_0:refreshMakeItem(arg_47_0)
		end

		local var_46_1 = {
			callback = var_46_0,
			building_type = xyd.EventCentreBuildingType.PETROOM,
			building_info = arg_36_0.eventCentre.petRoomInfo
		}

		xyd.WindowManager.get():openWindow("make_accelerate", var_46_1)
	end)

	local var_36_0 = display.newNode()

	var_36_0:setContentSize(arg_36_0:nodeByName("pet_show"):getContentSize())
	var_36_0:setAnchorPoint(0, 0)
	var_36_0:addTo(arg_36_0:nodeByName("pet_show"))
	var_36_0:setTouchEnabled(true)
	var_36_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_48_0)
		if arg_48_0.name == "began" then
			return true
		elseif arg_48_0.name == "ended" then
			xyd.playButtonSound()
			arg_36_0:changeCurrentPet()
		end
	end)
end

function var_0_0.changeCurrentPet(arg_49_0)
	if arg_49_0.petRoomInfo.is_making == 1 then
		local var_49_0 = var_0_1:translation("ON_MAKING_CANNOT_SWITCH_PET")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_49_0
		})

		return
	end

	local function var_49_1(arg_50_0)
		if arg_49_0.currentHero and arg_49_0.currentHero:getPetID() == arg_50_0:getPetID() then
			return
		end

		arg_49_0:updateCurrentPet(arg_50_0)

		arg_49_0.currentItem = nil
		arg_49_0.itemState = var_0_4.None

		if arg_49_0.effect and not tolua.isnull(arg_49_0.effect) then
			arg_49_0.effect:removeFromParent()
		end

		arg_49_0:update()
	end

	local var_49_2 = {
		callback = var_49_1
	}

	xyd.WindowManager.get():openWindow("pet_room_select_pet", var_49_2)
end

function var_0_0.updateCurrentPet(arg_51_0, arg_51_1)
	if not arg_51_1 then
		arg_51_0:nodeByName("select_pet_tip_text"):setString(var_0_1:translation("EVENT_CENTRE_PET_TABLE_TIP_1"))
		arg_51_0:nodeByName("select_pet_tip_text"):setVisible(true)
		arg_51_0:nodeByName("select_txt"):setVisible(true)
		arg_51_0:nodeByName("switch_txt"):setVisible(false)
		arg_51_0:nodeByName("pet_bg"):setVisible(true)

		return
	else
		arg_51_0:nodeByName("select_pet_tip_text"):setVisible(false)
		arg_51_0:nodeByName("select_txt"):setVisible(false)
		arg_51_0:nodeByName("switch_txt"):setVisible(true)
		arg_51_0:nodeByName("pet_bg"):setVisible(false)
	end

	arg_51_0.currentHero = arg_51_1

	arg_51_0:initialListItems()
	arg_51_0.itemList:reload()
	arg_51_0:nodeByName("pet_container"):removeAllChildren()
	arg_51_0:nodeByName("txt_name"):setString(arg_51_1:getName())
	xyd.setPetAvatar(arg_51_0:nodeByName("pet_container"), arg_51_1, nil, true)
end

function var_0_0.cancelMaking(arg_52_0)
	local var_52_0 = {
		building_type = xyd.EventCentreBuildingType.PETROOM
	}

	arg_52_0.eventCentre:cancelMaking(var_52_0, function(arg_53_0, arg_53_1)
		if arg_53_0 == xyd.error.OK then
			local var_53_0 = {
				resolve_types = arg_53_1.make_res_type,
				resolve_nums = arg_53_1.make_res_num,
				resolve_crits = {}
			}

			xyd.WindowManager.get():openWindow("recycle_award", var_53_0)
			arg_52_0:refreshMakeItem(arg_53_1)
		end
	end)
end

function var_0_0.doMakingItem(arg_54_0)
	if arg_54_0.petRoomInfo.is_making == 1 or arg_54_0.petRoomInfo.make_item and arg_54_0.petRoomInfo.make_item > 0 then
		local var_54_0 = var_0_1:translation("ON_MAKING_ITEM")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_54_0
		})

		return
	end

	if arg_54_0.petRoomInfo.building_info.need_time > 0 then
		local var_54_1 = string.format(var_0_1:translation("ON_UPGRADE_CANNOT_MAKE"), arg_54_0.buildingName)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_54_1
		})

		return
	end

	local var_54_2 = {
		item_id = arg_54_0.currentItem.itemID,
		pet_id = arg_54_0.currentHero:getPetID()
	}

	arg_54_0.eventCentre:makePetItem(var_54_2, function(arg_55_0, arg_55_1)
		if arg_55_0 == xyd.error.OK then
			local var_55_0 = xyd.tables.item:makeResType(arg_54_0.currentItem.itemID)
			local var_55_1 = xyd.tables.item:makeResNum(arg_54_0.currentItem.itemID)

			for iter_55_0 = 1, #var_55_0 do
				local var_55_2 = {
					itemID = var_55_0[iter_55_0],
					itemNum = var_55_1[iter_55_0]
				}

				arg_54_0.backPack:removeItem(var_55_2)
			end

			arg_54_0:refreshMakeItem(arg_55_1)
		end
	end)
end

function var_0_0.refreshMakeItem(arg_56_0, arg_56_1)
	arg_56_0.petRoomInfo.make_item = arg_56_1.make_item
	arg_56_0.petRoomInfo.is_making = arg_56_1.is_making
	arg_56_0.petRoomInfo.making_item = arg_56_1.making_item
	arg_56_0.petRoomInfo.make_need_time = arg_56_1.make_need_time
	arg_56_0.petRoomInfo.make_start_time = arg_56_1.make_start_time
	arg_56_0.petRoomInfo.pet_id = arg_56_1.pet_id
	arg_56_0.eventCentre.petRoomInfo = arg_56_0.petRoomInfo

	arg_56_0:initialVariable()
	arg_56_0:update()
end

function var_0_0.doSpeedUp(arg_57_0, arg_57_1)
	if arg_57_1 > arg_57_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
			local var_58_0 = {}

			var_58_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_58_0)
		end, nil, nil, xyd.ColorMode.GREEN)
	else
		local var_57_0 = {
			type = xyd.EventCentreBuildingType.PETROOM
		}

		arg_57_0.eventCentre:speedUpBuilding(var_57_0, function(arg_59_0, arg_59_1)
			if arg_59_0 == xyd.error.OK then
				arg_57_0.petRoomInfo.building_info.start_time = arg_59_1.start_time
				arg_57_0.petRoomInfo.building_info.need_time = arg_59_1.need_time
				arg_57_0.petRoomInfo.building_info.lev = arg_59_1.lev
				arg_57_0.petRoomInfo.building_info.new_evolve = arg_59_1.new_evolve

				arg_57_0:updateList()
				arg_57_0:update()
			end
		end)
	end
end

function var_0_0.doCancelEvolve(arg_60_0)
	local var_60_0 = {
		type = xyd.EventCentreBuildingType.PETROOM
	}

	arg_60_0.eventCentre:cancelEvolveBuilding(var_60_0, function(arg_61_0, arg_61_1)
		if arg_61_0 == xyd.error.OK then
			arg_60_0.petRoomInfo.building_info = arg_61_1.building_info

			arg_60_0:initialVariable()
			arg_60_0:update()

			local var_61_0 = {
				resolve_types = arg_61_1.return_res_id,
				resolve_nums = arg_61_1.return_res_num,
				resolve_crits = {}
			}

			xyd.WindowManager.get():openWindow("recycle_award", var_61_0)
		end
	end)
end

function var_0_0.didOpen(arg_62_0, arg_62_1)
	var_0_0.super:didOpen(arg_62_1)
	arg_62_0:addBlockLayer()
end

function var_0_0.didClose(arg_63_0, arg_63_1)
	var_0_0.super:didClose(arg_63_1)

	if arg_63_0.handle then
		var_0_2.unscheduleGlobal(arg_63_0.handle)

		arg_63_0.handle = nil
	end

	if arg_63_0.handle1 then
		var_0_2.unscheduleGlobal(arg_63_0.handle1)

		arg_63_0.handle1 = nil
	end
end

function var_0_0.scrollListener(arg_64_0, arg_64_1)
	if arg_64_1.name == "began" then
		arg_64_0.scrollViewMoved_ = false
		arg_64_0.prevX_ = arg_64_1.x
	elseif arg_64_1.name == "moved" and 5 <= math.abs(arg_64_1.x - arg_64_0.prevX_) then
		arg_64_0.scrollViewMoved_ = true
	end
end

return var_0_0
