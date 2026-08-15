local var_0_0 = class("BackpackWindow", import("app.windows.BackpackWindow"))
local var_0_1 = 50001024
local var_0_2 = 50001039
local var_0_3 = 50001046
local var_0_4 = 50001047
local var_0_5 = 50001049
local var_0_6 = {
	50001025,
	50001026,
	50001027,
	50001028
}
local var_0_7 = {
	50001091,
	50001092,
	50001093
}
local var_0_8 = 128
local var_0_9 = 200
local var_0_10 = 0.2
local var_0_11 = 0.12
local var_0_12 = 5
local var_0_13 = 1.04
local var_0_14 = 0.008333333333333333
local var_0_15 = 0.03333333333333333
local var_0_16 = xyd.tables.translation
local var_0_17 = xyd.tables.attr
local var_0_18 = 28
local var_0_19 = xyd.tables.item
local var_0_20 = {
	{
		xyd.ItemType.EQUIPMENT,
		xyd.ItemType.STONE,
		xyd.ItemType.CONSUMABLES,
		xyd.ItemType.REEL,
		xyd.ItemType.EQUIPMENT_FRAGMENT,
		xyd.ItemType.REEL_FRAGMENT,
		xyd.ItemType.PET_STONE,
		xyd.ItemType.PET_EQUIP,
		xyd.ItemType.INSCRIPTION
	},
	{
		xyd.ItemType.EQUIPMENT,
		xyd.ItemType.PET_EQUIP
	},
	{
		xyd.ItemType.REEL
	},
	{
		xyd.ItemType.STONE
	},
	{
		xyd.ItemType.CONSUMABLES
	},
	{
		xyd.ItemType.EQUIPMENT_FRAGMENT,
		xyd.ItemType.REEL_FRAGMENT
	},
	{
		xyd.ItemType.INSCRIPTION
	}
}
local var_0_21 = import("framework.scheduler")
local var_0_22 = {
	10,
	30,
	80,
	180,
	330
}
local var_0_23 = {
	var_0_0.ALL_BUTTON
}

function var_0_0.willOpen(arg_1_0, arg_1_1)
	arg_1_0:addTopSidebar({
		isEcoBar = 0
	})

	if arg_1_0.changeBG and not tolua.isnull(arg_1_0.changeBG) then
		arg_1_0.changeBG:setPositionX(200)
	end

	arg_1_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)

	arg_1_0.itemDetailVisible = false
	arg_1_0.panelAttr_ = arg_1_0:nodeByName(var_0_0.PANEL_ATTR)

	arg_1_0:nodeByName("has_txt"):setString(var_0_16:translation("ITEM_OWN"))
	arg_1_0:nodeByName("jian_txt"):setString(var_0_16:translation("ITEM_OWN_SUFFIX"))
	arg_1_0:nodeByName("price_label"):setString(var_0_16:translation("SELL_UNIT_PRICE"))
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.leftTxt = {
		var_0_16:translation("BACKPACK_TEXT_7"),
		var_0_16:translation("BACKPACK_TEXT_8"),
		var_0_16:translation("BACKPACK_TEXT_9"),
		var_0_16:translation("BACKPACK_TEXT_10"),
		var_0_16:translation("BACKPACK_TEXT_11"),
		var_0_16:translation("BACKPACK_TEXT_12"),
		var_0_16:translation("BACKPACK_TEXT_13")
	}
	arg_1_0.leftList = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_1_0:nodeByName("scroll"):getContentSize().width, arg_1_0:nodeByName("scroll"):getContentSize().height + 10),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_1_0:nodeByName("scroll")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))

	arg_1_0.leftList:setDelegate(handler(arg_1_0, arg_1_0.leftDelegate))
	arg_1_0.leftList:reload()

	arg_1_0.backpackHandle = var_0_21.scheduleGlobal(function()
		arg_1_0:updateScale()
	end, var_0_15)
	arg_1_0.flag = false
	arg_1_0.optionButtons_ = {}
	arg_1_0.optionTxts_ = {}

	table.insert(arg_1_0.optionButtons_, arg_1_0:nodeByName(var_0_0.ALL_BUTTON))
	table.insert(arg_1_0.optionTxts_, arg_1_0:nodeByName(var_0_0.ALL_TXT))

	local var_1_0 = {
		touchOnContent = true,
		async = true,
		viewRect = cc.rect(0, 0, arg_1_0:nodeByName("list"):getContentSize().width, arg_1_0:nodeByName("list"):getContentSize().height + 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_1_0.listView_ = {}
	arg_1_0.listView_[var_0_0.ALL_BUTTON] = cc.ui.UIListView.new(var_1_0):addTo(arg_1_0:nodeByName("list")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))

	arg_1_0.listView_[var_0_0.ALL_BUTTON]:setDelegate(handler(arg_1_0, arg_1_0.allSourceDelegate))

	for iter_1_0 = 1, #arg_1_0.optionButtons_ do
		arg_1_0.optionButtons_[iter_1_0]:addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				local var_3_0

				if iter_1_0 == arg_1_0.displayOption then
					var_3_0 = false
				end

				xyd.playButtonSound()

				arg_1_0.displayOption = iter_1_0

				arg_1_0:refreshDisplayOption(var_3_0)
			end
		end)
	end

	arg_1_0.list_ = {}
	arg_1_0.filterTypeTxt = xyd.split(var_0_16:translation("BACKPACK_FILTER_TYPE"), ",")

	arg_1_0.player_:loadBackpack(function(arg_4_0)
		if arg_4_0 == xyd.error.OK then
			arg_1_0.displayOption = 1

			arg_1_0:refreshDisplayOption()
		end
	end)
	arg_1_0:addInscriptionAssetsContainer()
	arg_1_0:runTagBtnAction()
end

function var_0_0.leftDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #var_0_23
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0 = arg_5_0.leftList:dequeueItem()

		if not var_5_0 then
			var_5_0 = arg_5_0.leftList:newItem()
		else
			var_5_0:removeAllChildren(true)
		end

		local var_5_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/backpack_window/left_btn.csb")
		local var_5_2 = var_5_1:getChildByName("container")

		var_5_1:setPosition(10, 0)
		var_5_1:setAnchorPoint(cc.p(0, 0))

		if arg_5_0.leftOnShow == arg_5_3 then
			arg_5_0.skipBtn_ = var_5_2

			var_5_2:getChildByName("left_button"):setBrightStyle(ccui.BrightStyle.highlight)
		else
			var_5_2:getChildByName("left_button"):setBrightStyle(ccui.BrightStyle.normal)
		end

		var_5_2:getChildByName("left_button"):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				arg_5_0.firstPlayEffect = 1

				if arg_5_0.skipBtn_ and not tolua.isnull(arg_5_0.skipBtn_) then
					arg_5_0.skipBtn_:getChildByName("left_button"):setBrightStyle(ccui.BrightStyle.normal)
				end

				arg_5_0.skipBtn_ = var_5_2

				var_5_2:getChildByName("left_button"):setBrightStyle(ccui.BrightStyle.highlight)

				local var_6_0

				if arg_5_0.playAction[arg_5_3] == arg_5_0.displayOption then
					var_6_0 = false
				end

				if var_6_0 == nil then
					arg_5_0.changeEffect = true
				end

				arg_5_0.displayOption = arg_5_0.playAction[arg_5_3]

				arg_5_0:refreshDisplayOption(var_6_0)

				arg_5_0.leftOnShow = arg_5_3

				if var_6_0 == nil then
					local var_6_1 = import("app.windows.BackpackItem").new()

					if #arg_5_0.list_[var_0_23[arg_5_0.displayOption]] >= 1 then
						var_6_1:setParams(arg_5_0.list_[var_0_23[arg_5_0.displayOption]][1])
						arg_5_0:updateItemDetail(var_6_1.params.itemID)

						arg_5_0.flag = arg_5_0:isTiliItem(var_6_1.params.itemID)

						arg_5_0:updateAssetsShowState(var_6_1.params.itemID)
						arg_5_0.listView_[var_0_23[arg_5_0.displayOption]]:getScrollNode():setPositionY(630)

						if not tolua.isnull(arg_5_0.itemCellContent) and arg_5_0.backpackHandle == nil then
							arg_5_0.backpackHandle = var_0_21.scheduleGlobal(function()
								arg_5_0:updateScale()
							end, var_0_15)
						end
					else
						arg_5_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)
					end
				end
			end
		end)
		var_5_2:getChildByName("txt"):setString(arg_5_0.leftTxt[arg_5_3])
		var_5_0:setItemSize(191, 81)
		var_5_0:addContent(var_5_1)

		if arg_5_0.actionNum > 0 then
			local var_5_3 = cc.p(var_5_2:getPosition())

			var_5_2:pos(var_5_3.x - var_0_9, var_5_3.y)
			var_5_2:runAction(cc.Sequence:create({
				cc.DelayTime:create(var_0_11 * (arg_5_3 - 1)),
				cc.Spawn:create({
					cc.MoveBy:create(var_0_10, cc.p(var_0_9, 0)),
					cc.FadeIn:create(var_0_10)
				}),
				cc.CallFunc:create(function()
					arg_5_0.actionNum = arg_5_0.actionNum - 1
				end)
			}))
		end

		return var_5_0
	end
end

function var_0_0.refreshDisplayOption(arg_9_0, arg_9_1)
	for iter_9_0 = 1, #arg_9_0.optionButtons_ do
		arg_9_0.list_[var_0_23[iter_9_0]] = arg_9_0:getItemsByTypes()

		if iter_9_0 == arg_9_0.displayOption then
			arg_9_0.optionButtons_[iter_9_0]:setBrightStyle(ccui.BrightStyle.highlight)
			arg_9_0.optionButtons_[iter_9_0]:setLocalZOrder(100)

			if arg_9_1 == nil then
				arg_9_0.filterType = arg_9_0.filterType or math.ceil((arg_9_0.player_.backpack_sort_type + 1) / 2)
				arg_9_0.filterOrder = arg_9_0.player_.backpack_sort_type % 2 == 0

				arg_9_0:updateFilter()
			end
		else
			arg_9_0.optionButtons_[iter_9_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_9_0.optionButtons_[iter_9_0]:setLocalZOrder(0)
			arg_9_0.listView_[var_0_23[iter_9_0]]:setLocalZOrder(1)
			arg_9_0.listView_[var_0_23[iter_9_0]]:removeAllItems()
		end

		arg_9_0.optionTxts_[iter_9_0]:setLocalZOrder(101)
	end

	arg_9_0:nodeByName("bg"):setLocalZOrder(1)
end

function var_0_0.refreshDisplayOptionAfterSell(arg_10_0)
	for iter_10_0 = 1, #arg_10_0.optionButtons_ do
		arg_10_0.list_[var_0_23[iter_10_0]] = arg_10_0:getItemsByTypes()

		if iter_10_0 == arg_10_0.displayOption then
			arg_10_0:filterSort(iter_10_0)

			local var_10_0 = 0
			local var_10_1 = arg_10_0.listView_[var_0_23[iter_10_0]].scrollNode:getPositionY()
			local var_10_2 = import("app.windows.BackpackItem").new()

			if arg_10_0.player_:getBackpack():getItemNumByID(arg_10_0.itemID) <= 0 then
				if #arg_10_0.list_[var_0_23[arg_10_0.displayOption]] >= 1 then
					var_10_2:setParams(arg_10_0.list_[var_0_23[arg_10_0.displayOption]][1])
					arg_10_0:updateItemDetail(var_10_2.params.itemID)

					arg_10_0.flag = arg_10_0:isTiliItem(var_10_2.params.itemID)

					arg_10_0:updateAssetsShowState(var_10_2.params.itemID)
				else
					arg_10_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)
				end
			end

			arg_10_0.listView_[var_0_23[iter_10_0]]:reload()

			if var_10_1 > 0 then
				if var_10_1 > var_0_8 * math.ceil(#arg_10_0.list_[var_0_23[iter_10_0]] / var_0_12) and var_10_1 > arg_10_0.listView_[var_0_23[iter_10_0]]:getViewRectInWorldSpace().height + 2 then
					var_10_1 = var_0_8 * math.ceil(#arg_10_0.list_[var_0_23[iter_10_0]] / var_0_12)
				end

				arg_10_0.listView_[var_0_23[iter_10_0]].scrollNode:setPosition(0, var_10_1)
			end
		else
			arg_10_0.optionButtons_[iter_10_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_10_0.optionButtons_[iter_10_0]:setLocalZOrder(0)
			arg_10_0.listView_[var_0_23[iter_10_0]]:setLocalZOrder(1)
			arg_10_0.listView_[var_0_23[iter_10_0]]:removeAllItems()
		end

		arg_10_0.optionTxts_[iter_10_0]:setLocalZOrder(101)
	end

	arg_10_0:nodeByName("bg"):setLocalZOrder(1)
end

function var_0_0.getItemsByTypes(arg_11_0)
	local var_11_0 = {}
	local var_11_1 = arg_11_0.backpack_:getItems()

	for iter_11_0, iter_11_1 in ipairs(var_11_1) do
		if var_0_19:isEquipment(iter_11_1.itemID) == 1 then
			table.insert(var_11_0, iter_11_1)
		end
	end

	return var_11_0
end

function var_0_0.willClose(arg_12_0)
	var_0_0.super.willClose(arg_12_0)

	local var_12_0 = xyd.WindowManager.get():getWindow("equip_confirm")

	if var_12_0 and not tolua.isnull(var_12_0) then
		var_12_0:update()
	end

	local var_12_1 = xyd.WindowManager.get():getWindow("item_compose")

	if var_12_1 and not tolua.isnull(var_12_1) then
		var_12_1:setIcons()
	end
end

return var_0_0
