local var_0_0 = class("RecycleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = {
	CannotSolve = 3,
	CanSolve = 2,
	None = 1
}
local var_0_5 = 8

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.handler = {}
	arg_1_0.listItems = {}
	arg_1_0.nextLevItems = {}
	arg_1_0.itemState = var_0_4.None
	arg_1_0.recycleInfo = arg_1_2.recycleInfo
end

function var_0_0.updateList(arg_2_0)
	arg_2_0:initialVariable()
	arg_2_0:initialListItems()
	arg_2_0.itemList:reload()
end

function var_0_0.initialVariable(arg_3_0)
	arg_3_0.resovleNum = 1
	arg_3_0.energy = arg_3_0.recycleInfo.energy

	if arg_3_0.energy < arg_3_0.recycleInfo.energy_limit and arg_3_0.recycleInfo.energy_time == 0 or arg_3_0.recycleInfo.energy_time > xyd.ServerTime.get():getServerTime() then
		arg_3_0.recycleInfo.energy_time = xyd.ServerTime.get():getServerTime()
	end

	arg_3_0.energyTime = arg_3_0.recycleInfo.energy_time
	arg_3_0.lev = arg_3_0.recycleInfo.building_info.lev
	arg_3_0.eventCentre.buidingInfo[tostring(xyd.EventCentreBuildingType.TRASH)].lev = arg_3_0.lev
	arg_3_0.currentTime = xyd.ServerTime.get():getServerTime()
	arg_3_0.recoverTime = (arg_3_0.recycleInfo.energy_limit - arg_3_0.energy) * xyd.tables.misc.eventCentreSaturationTime - (arg_3_0.currentTime - arg_3_0.energyTime)
end

function var_0_0.initialListItems(arg_4_0)
	local var_4_0 = arg_4_0.lev

	arg_4_0.listItems = {}
	arg_4_0.nextLevItems = {}

	for iter_4_0 = 1, tonumber(var_4_0) do
		local var_4_1 = xyd.tables.eventCentreRecycleTable:recountItem(iter_4_0)

		for iter_4_1 = 1, #var_4_1 do
			if arg_4_0.backPack:getItemNumByID(var_4_1[iter_4_1]) > 0 then
				table.insert(arg_4_0.listItems, arg_4_0.backPack:getItemByID(var_4_1[iter_4_1]))
			end
		end
	end

	local var_4_2 = xyd.tables.eventCentreRecycleTable:recountItem(var_4_0 + 1)

	for iter_4_2 = 1, #var_4_2 do
		local var_4_3 = {
			itemID = var_4_2[iter_4_2]
		}

		var_4_3.itemNum = 0

		table.insert(arg_4_0.nextLevItems, var_4_3)
	end

	table.sort(arg_4_0.listItems, function(arg_5_0, arg_5_1)
		return arg_5_0.itemID < arg_5_1.itemID
	end)
	table.sort(arg_4_0.nextLevItems, function(arg_6_0, arg_6_1)
		return arg_6_0.itemID < arg_6_1.itemID
	end)
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	var_0_0.super.willOpen(arg_7_0, arg_7_1)
	arg_7_0:initialVariable()
	arg_7_0:initialListItems()
	arg_7_0:update()
	arg_7_0:layout()
end

function var_0_0.layout(arg_8_0)
	arg_8_0:nodeByName("txt_title"):setString(xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.TRASH))
	arg_8_0:nodeByName("txt_max"):setString(var_0_1:translation("MAX"))
	arg_8_0:nodeByName("txt_decompose"):setString(var_0_1:translation("EVENT_CENTRE_TIP9"))
	arg_8_0:nodeByName("txt_upgrade"):setString(var_0_1:translation("HERO_MAIN_TEXT_13"))
	arg_8_0:nodeByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))
	arg_8_0:nodeByName("txt_speed_up"):setString(var_0_1:translation("EVENT_CENTRE_TIP2"))
	arg_8_0:nodeByName("energy_info"):setVisible(false)

	arg_8_0.scroll = arg_8_0:nodeByName("scroll")

	local var_8_0 = arg_8_0.scroll:getContentSize()

	if not arg_8_0.itemList then
		arg_8_0.itemList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_8_0.width, var_8_0.height - 5),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_8_0.scroll):onScroll(handler(arg_8_0, arg_8_0.scrollListener))
	else
		arg_8_0.nodeX = arg_8_0.itemList.scrollNode:getPositionX()
		arg_8_0.nodeY = arg_8_0.itemList.scrollNode:getPositionY()

		arg_8_0.itemList:removeAllItems()
	end

	arg_8_0.itemList:setDelegate(handler(arg_8_0, arg_8_0.itemListDelegate))
	arg_8_0.itemList:reload()
	arg_8_0:initChatBox()
	arg_8_0:setButtonClick()
	arg_8_0:update()
end

function var_0_0.update(arg_9_0)
	arg_9_0:updateEnergyInfo()
	arg_9_0:updateBottomShow()
	arg_9_0:updateBottomLeftShow()
	arg_9_0:updateBottomRigthShow()
	arg_9_0:updateUpgradeTime()
	arg_9_0:updateLevShow()
end

function var_0_0.initChatBox(arg_10_0)
	local var_10_0 = xyd.AssetLoader.get()
	local var_10_1 = 24
	local var_10_2 = arg_10_0:nodeByName("num_bg")
	local var_10_3 = "windows/login/transparent.png"
	local var_10_4 = var_10_0:loadSprite(var_10_3)

	arg_10_0.chatBox_ = ccui.EditBox:create(var_10_2:getContentSize(), var_10_3)

	arg_10_0.chatBox_:setAnchorPoint(0, 0)
	arg_10_0.chatBox_:pos(0, 0):addTo(var_10_2)
	arg_10_0.chatBox_:setFont(var_10_0.FONT_NAME, var_10_1)
	arg_10_0.chatBox_:setPlaceholderFont(var_10_0.FONT_NAME, var_10_1)
	arg_10_0.chatBox_:setPlaceHolder(var_0_1:translation("CHAT_INPUT_MESSAGE"))
	arg_10_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_10_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_10_0.chatBox_:registerScriptEditBoxHandler(handler(arg_10_0, arg_10_0.inputboxEventHandler))
	arg_10_0.chatBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_11_0, arg_11_1)
	if arg_11_1 == "return" then
		local var_11_0 = arg_11_0.chatBox_:getText()

		arg_11_0.chatBox_:setText("")

		local var_11_1 = xyd.getTextLen(var_11_0)
		local var_11_2 = math.floor(tonumber(var_11_0) or 0)
		local var_11_3 = arg_11_0.backPack:getItemNumByID(arg_11_0.currentItem.itemID)

		arg_11_0:nodeByName("recycle_num_txt"):setVisible(true)

		if var_11_0 ~= "" then
			if var_11_2 then
				if var_11_2 <= var_11_3 and var_11_2 > 0 then
					arg_11_0.resovleNum = var_11_2

					arg_11_0:updateChangeNumBtnsState()
				else
					local var_11_4 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_11_4
					})

					return
				end

				return
			else
				local var_11_5 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_5
				})

				return
			end
		else
			return
		end
	elseif arg_11_1 == "began" then
		arg_11_0:nodeByName("recycle_num_txt"):setVisible(false)
		arg_11_0.chatBox_:setText("")
	end
end

function var_0_0.updateLevShow(arg_12_0)
	arg_12_0:nodeByName("txt_lv"):setString("LV" .. arg_12_0.lev)

	if arg_12_0.recycleInfo.building_info.new_evolve == 1 then
		arg_12_0.recycleInfo.energy_limit = xyd.tables.misc.saturationInit + xyd.tables.eventCentreRecycleTable:energyLimit(arg_12_0.lev)

		local var_12_0 = {
			type = xyd.EventCentreBuildingType.TRASH
		}

		arg_12_0.eventCentre:confirmBuildingUpgrade(var_12_0, function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				arg_12_0.recycleInfo.building_info.new_evolve = 0

				local var_13_0 = {
					type = xyd.EventCentreBuildingType.TRASH,
					lev = arg_12_0.lev
				}

				arg_12_0:updateList()
				xyd.WindowManager.get():openWindow("building_levelup", var_13_0)
			end
		end)
	end
end

function var_0_0.updateUpgradeTime(arg_14_0)
	if arg_14_0.handler[4] then
		var_0_2.unscheduleGlobal(arg_14_0.handler[4])

		arg_14_0.handler[4] = nil
	end

	local var_14_0

	if arg_14_0.recycleInfo.building_info.start_time > 0 then
		var_14_0 = arg_14_0.recycleInfo.building_info.need_time - (xyd.ServerTime.get():getServerTime() - arg_14_0.recycleInfo.building_info.start_time)
	else
		var_14_0 = 0
	end

	if var_14_0 > 0 then
		arg_14_0:nodeByName("loading_bar"):setPercent((1 - var_14_0 / arg_14_0.recycleInfo.building_info.need_time) * 100)
		arg_14_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_14_0))
		arg_14_0:nodeByName("upgrade_btn"):setVisible(false)

		arg_14_0.handler[4] = var_0_2.scheduleGlobal(function()
			var_14_0 = var_14_0 - 1

			if not tolua.isnull(arg_14_0) then
				arg_14_0:nodeByName("loading_bar"):setPercent((1 - var_14_0 / arg_14_0.recycleInfo.building_info.need_time) * 100)
				arg_14_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_14_0))
				arg_14_0:nodeByName("upgrade_time_bg"):setVisible(true)
			end

			if var_14_0 <= 0 and arg_14_0.handler[4] then
				var_0_2.unscheduleGlobal(arg_14_0.handler[4])

				arg_14_0.handler[4] = nil

				if not tolua.isnull(arg_14_0) then
					arg_14_0:nodeByName("upgrade_time_bg"):setVisible(false)
					arg_14_0:nodeByName("upgrade_btn"):setVisible(true)
				end

				arg_14_0.itemState = var_0_4.None

				arg_14_0.eventCentre:getRecycleInfo({}, function(arg_16_0, arg_16_1)
					if arg_16_0 == xyd.error.OK then
						arg_14_0.recycleInfo = arg_16_1

						arg_14_0:initialVariable()
						arg_14_0:initialListItems()
						arg_14_0:update()
					end
				end)
			end
		end, 1)
	else
		arg_14_0:nodeByName("loading_bar"):setPercent(0)
		arg_14_0:nodeByName("upgrade_time_bg"):setVisible(false)
		arg_14_0:nodeByName("upgrade_btn"):setVisible(true)
	end
end

function var_0_0.updateEnergyInfo(arg_17_0)
	arg_17_0:nodeByName("time_gap_txt"):setString(string.format(var_0_1:translation("EVETN_CENTRE_SATURATION_TIME"), xyd.tables.misc.eventCentreSaturationTime))
	arg_17_0:nodeByName("total_energy_txt"):setString(arg_17_0.energy)
	arg_17_0:createScheduler()
end

function var_0_0.createScheduler(arg_18_0)
	if arg_18_0.handler[3] then
		var_0_2.unscheduleGlobal(arg_18_0.handler[3])

		arg_18_0.handler[3] = nil
	end

	arg_18_0.currentTime = xyd.ServerTime.get():getServerTime()

	arg_18_0:updateEnergyShow()

	arg_18_0.handler[3] = var_0_2.scheduleGlobal(function()
		arg_18_0.currentTime = arg_18_0.currentTime + 1
		arg_18_0.recoverTime = arg_18_0.recoverTime - 1
		arg_18_0.energy = math.floor((arg_18_0.currentTime - arg_18_0.energyTime) / xyd.tables.misc.eventCentreSaturationTime + arg_18_0.recycleInfo.energy)

		if arg_18_0.energy > arg_18_0.recycleInfo.energy_limit then
			arg_18_0.energy = arg_18_0.recycleInfo.energy_limit
		end

		arg_18_0:updateEnergyShow()
		arg_18_0:updateBottomRigthShow()
	end, 1)
end

function var_0_0.updateEnergyShow(arg_20_0)
	arg_20_0:nodeByName("progress_bar"):setPercent(100 * arg_20_0.energy / arg_20_0.recycleInfo.energy_limit)
	arg_20_0:nodeByName("total_energy_txt"):setString(arg_20_0.energy)

	local var_20_0 = os.date("%X", arg_20_0.currentTime)

	arg_20_0:nodeByName("current_time_txt"):setString(string.format(var_0_1:translation("TIME_NOW"), var_20_0))

	local var_20_1 = arg_20_0:createRecoverTimeString(arg_20_0.recoverTime)

	arg_20_0:nodeByName("time_recover_txt"):setString(var_20_1)
end

function var_0_0.createRecoverTimeString(arg_21_0, arg_21_1)
	if arg_21_1 <= 0 then
		return var_0_1:translation("ENERGY_FULL")
	elseif arg_21_1 < 60 then
		return string.format(var_0_1:translation("TIME_TO_RECOVER"), var_0_1:translation("LESS_THAN_ONE_MINUTE"))
	else
		return string.format(var_0_1:translation("TIME_TO_RECOVER"), xyd.secondsToString1(arg_21_1))
	end
end

function var_0_0.updateBottomShow(arg_22_0)
	arg_22_0:nodeByName("bottom_left_container"):setVisible(false)
	arg_22_0:nodeByName("bottom_right_container"):setVisible(false)
	arg_22_0:nodeByName("lev_resolve_txt"):setVisible(false)

	if arg_22_0.itemState == var_0_4.None then
		arg_22_0:nodeByName("lev_resolve_txt"):setString(var_0_1:translation("SELECT_SOLVE_ITEM"))
		arg_22_0:nodeByName("lev_resolve_txt"):setVisible(true)
	elseif arg_22_0.itemState == var_0_4.CannotSolve then
		arg_22_0:nodeByName("lev_resolve_txt"):setString(string.format(var_0_1:translation("LVN_CAN_SOLVE"), arg_22_0.lev + 1))
		arg_22_0:nodeByName("lev_resolve_txt"):setVisible(true)
		arg_22_0:nodeByName("bottom_left_container"):setVisible(true)
	else
		arg_22_0:nodeByName("bottom_left_container"):setVisible(true)
		arg_22_0:nodeByName("bottom_right_container"):setVisible(true)
	end
end

function var_0_0.updateBottomLeftShow(arg_23_0)
	arg_23_0:nodeByName("can_get_pos"):removeAllChildren()

	if arg_23_0.currentItem then
		arg_23_0:nodeByName("equip_name_text"):setString(xyd.tables.item:name(arg_23_0.currentItem.itemID))

		local var_23_0 = xyd.tables.item:resolveResType(arg_23_0.currentItem.itemID)
		local var_23_1 = xyd.tables.item:resolveResNum(arg_23_0.currentItem.itemID)
		local var_23_2 = arg_23_0:createItemsContent(var_23_0, var_23_1)

		var_23_2:setAnchorPoint(cc.p(0, 0.5))
		var_23_2:addTo(arg_23_0:nodeByName("can_get_pos"))
		var_23_2:setPosition(cc.p(0, 0))
	end
end

function var_0_0.createItemsContent(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = display.newNode()
	local var_24_1 = -10
	local var_24_2 = 25

	for iter_24_0 = 1, #arg_24_1 do
		var_24_1 = var_24_1 + 20

		local var_24_3

		if arg_24_1[iter_24_0] == 11 then
			var_24_3 = "images/icon/eco/magic_dust_small.png"
		elseif arg_24_1[iter_24_0] == 12 then
			var_24_3 = "images/icon/eco/magic_liquid_small.png"
		elseif arg_24_1[iter_24_0] == 13 then
			var_24_3 = "images/icon/eco/magic_energy_small.png"
		end

		local var_24_4

		if var_24_3 then
			var_24_4 = xyd.AssetLoader.get():loadSprite(var_24_3)
		end

		var_24_4:addTo(var_24_0)
		var_24_4:setAnchorPoint(0, 0.5)
		var_24_4:setPosition(var_24_1, var_24_2)

		var_24_1 = var_24_1 + var_24_4:getContentSize().width
	end

	var_24_0:setContentSize(var_24_1, 50)

	return var_24_0
end

function var_0_0.createItemNumLabel(arg_25_0, arg_25_1)
	local var_25_0 = {
		font = "fonts/main_font.ttf",
		size = 18,
		color = cc.c3b(255, 255, 255)
	}
	local var_25_1 = xyd.AssetLoader.get():loadLabel(var_25_0)

	var_25_1:setMaxLineWidth(250)
	var_25_1:setString(arg_25_1)

	return var_25_1
end

function var_0_0.updateBottomRigthShow(arg_26_0)
	if arg_26_0.currentItem then
		arg_26_0:updateChangeNumBtnsState()

		local var_26_0 = xyd.tables.eventCentreRecycleTable:cutCostEnergy(arg_26_0.lev)
		local var_26_1 = arg_26_0.resovleNum * math.ceil(xyd.tables.item:resolveEnergy(arg_26_0.currentItem.itemID) * (1 - var_26_0))

		arg_26_0:nodeByName("cost_num_txt"):setString(var_26_1)

		if var_26_1 > arg_26_0.energy then
			arg_26_0:nodeByName("cost_num_txt"):setColor(cc.c3b(255, 0, 0))
			arg_26_0:nodeByName("recycle_btn"):setVisible(false)
		else
			arg_26_0:nodeByName("cost_num_txt"):setColor(cc.c3b(28, 160, 31))
			arg_26_0:nodeByName("recycle_btn"):setVisible(true)
		end
	end
end

function var_0_0.updateChangeNumBtnsState(arg_27_0)
	arg_27_0:nodeByName("sub_pos"):getChildByName("jiandian"):setButtonEnabled(true)
	arg_27_0:nodeByName("add_pos"):getChildByName("jiadian"):setButtonEnabled(true)
	arg_27_0:nodeByName("recycle_num_txt"):setString("" .. arg_27_0.resovleNum .. "/" .. arg_27_0.backPack:getItemNumByID(arg_27_0.currentItem.itemID))

	if arg_27_0.resovleNum <= 1 then
		if arg_27_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_27_0.handler[1])
		end

		if arg_27_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_27_0.handler[2])
		end

		arg_27_0:nodeByName("sub_pos"):getChildByName("jiandian"):setButtonEnabled(false)
		arg_27_0:nodeByName("sub_pos"):getChildByName("jiandian"):setScale(1)
	end

	if arg_27_0.resovleNum >= arg_27_0.backPack:getItemNumByID(arg_27_0.currentItem.itemID) then
		if arg_27_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_27_0.handler[1])
		end

		if arg_27_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_27_0.handler[2])
		end

		arg_27_0:nodeByName("add_pos"):getChildByName("jiadian"):setButtonEnabled(false)
		arg_27_0:nodeByName("add_pos"):getChildByName("jiadian"):setScale(1)
	end
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
	local var_29_1 = 55
	local var_29_2 = 7.5
	local var_29_3 = 110

	var_29_0:setContentSize(895, 100)

	for iter_29_0 = 1, var_0_5 do
		if (arg_29_1 - 1) * var_0_5 + iter_29_0 <= #arg_29_0.listItems then
			local var_29_4 = arg_29_0.listItems[(arg_29_1 - 1) * var_0_5 + iter_29_0]
			local var_29_5 = display.newNode()

			var_29_5:setContentSize(85, 85)
			var_29_5:setAnchorPoint(cc.p(0.5, 0))
			xyd.setItemBorder(var_29_5, var_29_4.itemID, nil, nil, var_29_4.itemNum, nil, true)
			var_29_5:addTo(var_29_0)
			var_29_5:setPosition(cc.p(var_29_1, var_29_2))

			var_29_1 = var_29_1 + var_29_3

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
						arg_29_0.resovleNum = 1
						arg_29_0.currentItem = var_29_4
						arg_29_0.currentNode = var_29_5
						arg_29_0.itemState = var_0_4.CanSolve

						arg_29_0:addSelectEffectForItem(var_29_5)
						arg_29_0:update()
					end
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

	arg_31_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_31_0.effect:addTo(arg_31_1)
	arg_31_0.effect:setPosition(cc.p(arg_31_1:getContentSize().width / 2, arg_31_1:getContentSize().height / 2))
	arg_31_0.effect:setName("effect")
	arg_31_0.effect:setScale(0.78)

	local var_31_0 = transition.sequence({
		cc.ScaleTo:create(0.3, 0.8112),
		cc.ScaleTo:create(0.3, 0.78)
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
	var_32_1:setPosition(cc.p(20, 2))

	return var_32_0
end

function var_0_0.creatNextLevLabel(arg_33_0)
	local var_33_0 = var_0_1:translation("NEXT_LEV_SOLVE")
	local var_33_1 = {
		font = "fonts/main_font.ttf",
		size = 26,
		color = cc.c3b(255, 255, 255)
	}
	local var_33_2 = xyd.AssetLoader.get():loadLabel(var_33_1)

	var_33_2:setMaxLineWidth(500)
	var_33_2:setString(var_33_0)

	return var_33_2
end

function var_0_0.createNextLevContent(arg_34_0, arg_34_1)
	local var_34_0 = display.newNode()
	local var_34_1 = 110
	local var_34_2 = 55
	local var_34_3 = 7.5

	var_34_0:setContentSize(895, 100)

	for iter_34_0 = 1, var_0_5 do
		if (arg_34_1 - 1) * var_0_5 + iter_34_0 <= #arg_34_0.nextLevItems then
			local var_34_4 = arg_34_0.nextLevItems[(arg_34_1 - 1) * var_0_5 + iter_34_0]
			local var_34_5 = display.newNode()

			var_34_5:setContentSize(85, 85)
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
						arg_34_0.resovleNum = 1
						arg_34_0.currentItem = var_34_4
						arg_34_0.currentNode = var_34_5
						arg_34_0.itemState = var_0_4.CannotSolve

						arg_34_0:addSelectEffectForItem(var_34_5)
						arg_34_0:update()
					end
				end
			end)
		end
	end

	return var_34_0
end

function var_0_0.setButtonClick(arg_36_0)
	local var_36_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_36_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_36_0:addTo(arg_36_0:nodeByName("sub_pos"))
	var_36_0:setName("jiandian")

	local var_36_1 = false

	var_36_0:onButtonPressed(function(arg_37_0)
		var_36_0:setScale(0.9)

		local var_37_0 = 0

		local function var_37_1()
			var_37_0 = var_37_0 + 0.03

			if arg_36_0.decreaseCurrentNum then
				arg_36_0:decreaseCurrentNum()
			end
		end

		local function var_37_2()
			var_37_0 = var_37_0 + 0.1

			if var_37_0 > 0.5 and var_37_0 <= 4 then
				var_36_1 = true

				if arg_36_0.decreaseCurrentNum then
					arg_36_0:decreaseCurrentNum()
				end
			elseif var_37_0 > 4 then
				arg_36_0.handler[2] = var_0_2.scheduleGlobal(var_37_1, 0.03)

				if arg_36_0.handler[1] then
					var_0_2.unscheduleGlobal(arg_36_0.handler[1])
				end
			else
				var_36_1 = false
			end
		end

		var_36_1 = false
		arg_36_0.handler[1] = var_0_2.scheduleGlobal(var_37_2, 0.1)
	end)
	var_36_0:onButtonRelease(function(arg_40_0)
		var_36_0:setScale(1)

		if arg_36_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_36_0.handler[1])
		end

		if arg_36_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_36_0.handler[2])
		end

		if var_36_1 == false and arg_36_0.decreaseCurrentNum then
			arg_36_0:decreaseCurrentNum()
		end
	end)

	local var_36_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_36_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_36_2:addTo(arg_36_0:nodeByName("add_pos"))
	var_36_2:setName("jiadian")

	local var_36_3 = false

	var_36_2:onButtonPressed(function(arg_41_0)
		var_36_2:setScale(0.9)

		local var_41_0 = 0

		local function var_41_1()
			var_41_0 = var_41_0 + 0.03

			if arg_36_0.addCurrentNum then
				arg_36_0:addCurrentNum()
			end
		end

		local function var_41_2()
			var_41_0 = var_41_0 + 0.1

			if var_41_0 > 0.5 and var_41_0 <= 4 then
				var_36_3 = true

				if arg_36_0.addCurrentNum then
					arg_36_0:addCurrentNum()
				end
			elseif var_41_0 > 4 then
				arg_36_0.handler[2] = var_0_2.scheduleGlobal(var_41_1, 0.03)

				if arg_36_0.handler[1] then
					var_0_2.unscheduleGlobal(arg_36_0.handler[1])
				end
			else
				var_36_3 = false
			end
		end

		var_36_3 = false
		arg_36_0.handler[1] = var_0_2.scheduleGlobal(var_41_2, 0.1)
	end)
	var_36_2:onButtonRelease(function(arg_44_0)
		var_36_2:setScale(1)

		if arg_36_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_36_0.handler[1])
		end

		if arg_36_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_36_0.handler[2])
		end

		if var_36_3 == false and arg_36_0.addCurrentNum then
			arg_36_0:addCurrentNum()
		end
	end)
	arg_36_0:nodeByName("max_btn"):addTouchEventListener(function(arg_45_0, arg_45_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("max_btn"), arg_45_1)

		if arg_45_1 == ccui.TouchEventType.ended and arg_36_0.currentItem then
			xyd.playButtonSound()

			local var_45_0 = xyd.tables.eventCentreRecycleTable:cutCostEnergy(arg_36_0.lev)
			local var_45_1 = math.ceil(xyd.tables.item:resolveEnergy(arg_36_0.currentItem.itemID) * (1 - var_45_0))

			arg_36_0.resovleNum = math.floor(arg_36_0.energy / var_45_1)

			if arg_36_0.backPack:getItemNumByID(arg_36_0.currentItem.itemID) < arg_36_0.resovleNum then
				arg_36_0.resovleNum = arg_36_0.backPack:getItemNumByID(arg_36_0.currentItem.itemID)
			end

			if arg_36_0.resovleNum < 1 then
				arg_36_0.resovleNum = 1
			end

			arg_36_0:updateBottomRigthShow()
		end
	end)
	arg_36_0:nodeByName("recycle_btn"):addTouchEventListener(function(arg_46_0, arg_46_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("recycle_btn"), arg_46_1)

		if arg_46_1 == ccui.TouchEventType.ended and arg_36_0.currentItem then
			xyd.playButtonSound()

			local var_46_0 = xyd.tables.item:quality(arg_36_0.currentItem.itemID)

			if var_46_0 >= xyd.ItemQuality.Purple then
				local var_46_1 = xyd.split(var_0_1:translation("COLOR_TABLE3"), ",")
				local var_46_2 = string.format(var_0_1:translation("SURE_SOLVE"), var_46_1[var_46_0])

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_46_2, function()
					arg_36_0:doRecycle()
				end, nil, nil, xyd.ColorMode.GREEN)
			else
				arg_36_0:doRecycle()
			end
		end
	end)
	arg_36_0:nodeByName("upgrade_btn"):addTouchEventListener(function(arg_48_0, arg_48_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("upgrade_btn"), arg_48_1)

		if arg_48_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_36_0.lev >= xyd.tables.eventCentreTable:maxLev(xyd.EventCentreBuildingType.TRASH) then
				local var_48_0 = xyd.tables.eventCentreTable:name(xyd.EventCentreBuildingType.TRASH)
				local var_48_1 = string.format(var_0_1:translation("HIGHEST_LEV"), var_48_0)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_48_1
				})

				return
			end

			local var_48_2 = {
				type = xyd.EventCentreBuildingType.TRASH,
				lev = arg_36_0.recycleInfo.building_info.lev
			}

			xyd.WindowManager.get():openWindow("event_centre_upgrade", var_48_2)
		end
	end)
	arg_36_0:nodeByName("speed_up_btn"):addTouchEventListener(function(arg_49_0, arg_49_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("speed_up_btn"), arg_49_1)

		if arg_49_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_49_0 = arg_36_0.recycleInfo.building_info.need_time - (xyd.ServerTime.get():getServerTime() - arg_36_0.recycleInfo.building_info.start_time)
			local var_49_1 = arg_36_0.eventCentre:getUpgradeCost(var_49_0)
			local var_49_2 = string.format(var_0_1:translation("COST_TO_UPGRADE"), var_49_1, arg_36_0.lev + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_49_2, function()
				arg_36_0:doSpeedUp(var_49_1)
			end, nil, 0, xyd.ColorMode.GREEN)
		end
	end)
	arg_36_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_51_0, arg_51_1)
		xyd.buttonScaleAnim(arg_36_0:nodeByName("cancel_btn"), arg_51_1)

		if arg_51_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_51_0 = var_0_1:translation("CANCEL_UPGRADE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_51_0, function()
				arg_36_0:doCancelEvolve()
			end, nil, nil, xyd.ColorMode.GREEN)
		end
	end)
	arg_36_0:nodeByName("progress_bg"):setTouchEnabled(true)
	arg_36_0:nodeByName("progress_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_53_0)
		if arg_53_0.name == "began" then
			arg_36_0:nodeByName("energy_info"):setVisible(true)

			return true
		elseif arg_53_0.name == "ended" then
			arg_36_0:nodeByName("energy_info"):setVisible(false)
		end
	end)
end

function var_0_0.addCurrentNum(arg_54_0)
	if arg_54_0.resovleNum + 1 >= arg_54_0.backPack:getItemNumByID(arg_54_0.currentItem.itemID) then
		arg_54_0.resovleNum = arg_54_0.backPack:getItemNumByID(arg_54_0.currentItem.itemID)
	else
		arg_54_0.resovleNum = arg_54_0.resovleNum + 1
	end

	arg_54_0:updateBottomRigthShow()
	arg_54_0:updateChangeNumBtnsState()
end

function var_0_0.decreaseCurrentNum(arg_55_0)
	if arg_55_0.resovleNum - 1 <= 0 then
		arg_55_0.resovleNum = 1
	else
		arg_55_0.resovleNum = arg_55_0.resovleNum - 1
	end

	arg_55_0:updateBottomRigthShow()
	arg_55_0:updateChangeNumBtnsState()
end

function var_0_0.doRecycle(arg_56_0)
	local var_56_0 = {
		item_id = arg_56_0.currentItem.itemID,
		item_num = arg_56_0.resovleNum
	}

	arg_56_0.eventCentre:recycleItems(var_56_0, function(arg_57_0, arg_57_1)
		if arg_57_0 == xyd.error.OK then
			arg_56_0.recycleInfo.energy = arg_57_1.energy
			arg_56_0.recycleInfo.energy_time = arg_57_1.energy_time

			arg_56_0:initialVariable()

			local var_57_0 = {
				itemNum = var_56_0.item_num,
				itemID = var_56_0.item_id
			}

			arg_56_0.selfPlayer:getBackpack():removeItem(var_57_0)

			if arg_56_0.backPack:getItemNumByID(var_56_0.item_id) <= 0 then
				arg_56_0.itemState = var_0_4.None
				arg_56_0.currentItem = nil

				arg_56_0:initialListItems()
				arg_56_0.itemList:reload()
			else
				arg_56_0.itemList:refreshList()
			end

			arg_56_0:update()
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_MAGIC_RES
			})

			local var_57_1 = {
				resolve_types = arg_57_1.resolve_types,
				resolve_nums = arg_57_1.resolve_nums,
				resolve_crits = arg_57_1.resolve_crits,
				title = var_0_1:translation("EVENT_CENTRE_TIP10")
			}

			xyd.WindowManager.get():openWindow("recycle_award", var_57_1)
		end
	end)
end

function var_0_0.doSpeedUp(arg_58_0, arg_58_1)
	if arg_58_1 > arg_58_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
			local var_59_0 = {}

			var_59_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_59_0)
		end, nil, nil, xyd.ColorMode.GREEN)
	else
		local var_58_0 = {
			type = xyd.EventCentreBuildingType.TRASH
		}

		arg_58_0.eventCentre:speedUpBuilding(var_58_0, function(arg_60_0, arg_60_1)
			if arg_60_0 == xyd.error.OK then
				arg_58_0.recycleInfo.building_info.start_time = arg_60_1.start_time
				arg_58_0.recycleInfo.building_info.need_time = arg_60_1.need_time
				arg_58_0.recycleInfo.building_info.lev = arg_60_1.lev
				arg_58_0.recycleInfo.building_info.new_evolve = arg_60_1.new_evolve
				arg_58_0.recycleInfo.energy = arg_60_1.trash_info.energy
				arg_58_0.recycleInfo.energy_time = arg_60_1.trash_info.energy_time

				arg_58_0:updateList()
				arg_58_0:update()
			end
		end)
	end
end

function var_0_0.doCancelEvolve(arg_61_0)
	local var_61_0 = {
		type = xyd.EventCentreBuildingType.TRASH
	}

	arg_61_0.eventCentre:cancelEvolveBuilding(var_61_0, function(arg_62_0, arg_62_1)
		if arg_62_0 == xyd.error.OK then
			arg_61_0.recycleInfo.building_info = arg_62_1.building_info

			arg_61_0:initialVariable()
			arg_61_0:update()
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_MAGIC_RES
			})

			local var_62_0 = {
				resolve_types = arg_62_1.return_res_id,
				resolve_nums = arg_62_1.return_res_num,
				resolve_crits = {},
				title = var_0_1:translation("EVENT_CENTRE_TIP10")
			}

			xyd.WindowManager.get():openWindow("recycle_award", var_62_0)
		end
	end)
end

function var_0_0.didOpen(arg_63_0, arg_63_1)
	var_0_0.super:didOpen(arg_63_1)
	arg_63_0:addBlockLayer()
end

function var_0_0.didClose(arg_64_0, arg_64_1)
	var_0_0.super:didClose(arg_64_1)

	local var_64_0 = 4

	for iter_64_0 = 1, 4 do
		if arg_64_0.handler[iter_64_0] then
			var_0_2.unscheduleGlobal(arg_64_0.handler[iter_64_0])

			arg_64_0.handler[iter_64_0] = nil
		end
	end
end

function var_0_0.scrollListener(arg_65_0, arg_65_1)
	if arg_65_1.name == "began" then
		arg_65_0.scrollViewMoved_ = false
		arg_65_0.prevX_ = arg_65_1.x
	elseif arg_65_1.name == "moved" and 5 <= math.abs(arg_65_1.x - arg_65_0.prevX_) then
		arg_65_0.scrollViewMoved_ = true
	end
end

return var_0_0
