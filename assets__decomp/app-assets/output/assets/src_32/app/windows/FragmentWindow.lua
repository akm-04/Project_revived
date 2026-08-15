local var_0_0 = class("FragmentWindow", import("app.common.ui.BaseWindow"))

var_0_0.RETURN_BUTTON = "return_button"
var_0_0.ALL_BUTTON = "all_button"
var_0_0.EQUIP_BUTTON = "equip_button"
var_0_0.REEL_BUTTON = "reel_button"
var_0_0.STONE_BUTTON = "stone_button"
var_0_0.SELL_BUTTON = "sell_button"
var_0_0.MAKE_BUTTON = "make_button"
var_0_0.CONSUMABLES_BUTTON = "consumables_button"
var_0_0.ALL_TXT = "all_txt"
var_0_0.EQUIP_TXT = "equip_txt"
var_0_0.REEL_TXT = "reel_txt"
var_0_0.ITEM_DETAIL = "item_detail"
var_0_0.IMG_ICON = "img_icon"
var_0_0.NAME_TXT = "name_txt"
var_0_0.NUM_TXT = "num_txt"
var_0_0.DESC1_TXT = "desc1_txt"
var_0_0.DESC2_TXT = "desc2_txt"
var_0_0.IMG_CURRENCY = "img_currency"
var_0_0.PRICE = "price_txt"
var_0_0.PRICE_LABEL = "price_label"
var_0_0.SELL_TXT = "sell_txt"
var_0_0.MAKE_TXT = "make_txt"
var_0_0.PANEL_ATTR = "panel_attr"

local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.attr
local var_0_3 = 28
local var_0_4 = {
	{
		xyd.ItemType.EQUIPMENT_FRAGMENT,
		xyd.ItemType.REEL_FRAGMENT
	},
	{
		xyd.ItemType.EQUIPMENT_FRAGMENT
	},
	{
		xyd.ItemType.REEL_FRAGMENT
	}
}
local var_0_5 = {
	var_0_0.ALL_BUTTON,
	var_0_0.EQUIP_BUTTON,
	var_0_0.REEL_BUTTON
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)

	arg_1_0.itemDetailVisible = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.panelAttr_ = arg_2_0:nodeByName(var_0_0.PANEL_ATTR)

	arg_2_0:nodeByName("has_txt"):setString(var_0_1:translation("ITEM_OWN"))
	arg_2_0:nodeByName("jian_txt"):setString(var_0_1:translation("ITEM_OWN_SUFFIX"))
	arg_2_0:nodeByName("price_label"):setString(var_0_1:translation("SELL_UNIT_PRICE"))

	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.optionButtons_ = {}
	arg_2_0.optionTxts_ = {}

	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.ALL_BUTTON))
	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.EQUIP_BUTTON))
	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.REEL_BUTTON))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.ALL_TXT))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.EQUIP_TXT))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.REEL_TXT))

	local var_2_0 = {
		touchOnContent = true,
		async = true,
		viewRect = cc.rect(0, 0, 475, 515),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_2_0.listView_ = {}
	arg_2_0.listView_[var_0_0.ALL_BUTTON] = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	arg_2_0.listView_[var_0_0.EQUIP_BUTTON] = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	arg_2_0.listView_[var_0_0.REEL_BUTTON] = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listView_[var_0_0.ALL_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.allSourceDelegate))
	arg_2_0.listView_[var_0_0.EQUIP_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.equipSourceDelegate))
	arg_2_0.listView_[var_0_0.REEL_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.reelSourceDelegate))

	for iter_2_0 = 1, #arg_2_0.optionButtons_ do
		arg_2_0.optionButtons_[iter_2_0]:addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				arg_2_0.displayOption = iter_2_0

				arg_2_0:refreshDisplayOption()
			end
		end)
	end

	arg_2_0.list_ = {}

	arg_2_0.player_:loadBackpack(function(arg_4_0)
		if arg_4_0 == xyd.error.OK then
			arg_2_0.displayOption = 1

			arg_2_0:refreshDisplayOption()
			arg_2_0.listView_[var_0_5[arg_2_0.displayOption]]:reload()
		end
	end)
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
	elseif arg_5_1.name == "moved" and 20 <= math.abs(arg_5_1.x - arg_5_0.prevX_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.allSourceDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return (math.ceil(#arg_6_0.list_[var_0_0.ALL_BUTTON] / 4))
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1 = arg_6_0.listView_[var_0_0.ALL_BUTTON]:dequeueItem()

		if not var_6_1 then
			var_6_1 = arg_6_0.listView_[var_0_0.ALL_BUTTON]:newItem()
		else
			var_6_1:removeAllChildren(true)
		end

		local var_6_2 = 475
		local var_6_3 = 120

		var_6_1:setItemSize(var_6_2, var_6_3)

		local var_6_4 = display.newNode()

		var_6_4:setContentSize(var_6_2, var_6_3)

		local var_6_5 = 1

		for iter_6_0 = 0, 3 do
			if arg_6_3 * 4 - iter_6_0 <= #arg_6_0.list_[var_0_0.ALL_BUTTON] and arg_6_3 * 4 - iter_6_0 > 0 then
				local var_6_6 = import("app.windows.BackpackItem").new()

				var_6_6:setParams(arg_6_0.list_[var_0_0.ALL_BUTTON][arg_6_3 * 4 - iter_6_0])
				var_6_4:addChild(var_6_6)
				var_6_6:setPosition(var_6_3 * var_6_5 - var_6_3, 0)
				var_6_6:setAnchorPoint(cc.p(0.5, 0.5))
				var_6_6:ignoreAnchorPointForPosition(false)
				var_6_6:setTouchEnabled(true)
				var_6_6:setTouchSwallowEnabled(false)
				var_6_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
					if arg_7_0.name == "began" then
						var_6_6.contentView_:nodeByName("container"):setScale(0.9)

						return true
					elseif arg_7_0.name == "ended" then
						var_6_6.contentView_:nodeByName("container"):setScale(1)

						if not arg_6_0.scrollViewMoved_ then
							arg_6_0:updateItemDetail(var_6_6.params.itemID)
						end
					end
				end)

				var_6_5 = var_6_5 + 1
			end
		end

		var_6_1:addContent(var_6_4)

		return var_6_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_6_2 then
		-- block empty
	end
end

function var_0_0.equipSourceDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return (math.ceil(#arg_8_0.list_[var_0_0.EQUIP_BUTTON] / 4))
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0
		local var_8_1 = arg_8_0.listView_[var_0_0.EQUIP_BUTTON]:dequeueItem()

		if not var_8_1 then
			var_8_1 = arg_8_0.listView_[var_0_0.EQUIP_BUTTON]:newItem()
		else
			var_8_1:removeAllChildren(true)
		end

		local var_8_2 = 475
		local var_8_3 = 120

		var_8_1:setItemSize(var_8_2, var_8_3)

		local var_8_4 = display.newNode()

		var_8_4:setContentSize(var_8_2, var_8_3)

		local var_8_5 = 1

		for iter_8_0 = 0, 3 do
			if arg_8_3 * 4 - iter_8_0 <= #arg_8_0.list_[var_0_0.EQUIP_BUTTON] and arg_8_3 * 4 - iter_8_0 > 0 then
				local var_8_6 = import("app.windows.BackpackItem").new()

				var_8_6:setParams(arg_8_0.list_[var_0_0.EQUIP_BUTTON][arg_8_3 * 4 - iter_8_0])
				var_8_4:addChild(var_8_6)
				var_8_6:setPosition(var_8_3 * var_8_5 - var_8_3, 0)
				var_8_6:setAnchorPoint(cc.p(0.5, 0.5))
				var_8_6:ignoreAnchorPointForPosition(false)
				var_8_6:setTouchEnabled(true)
				var_8_6:setTouchSwallowEnabled(false)
				var_8_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
					if arg_9_0.name == "began" then
						var_8_6.contentView_:nodeByName("container"):setScale(0.9)

						return true
					elseif arg_9_0.name == "ended" then
						var_8_6.contentView_:nodeByName("container"):setScale(1)

						if not arg_8_0.scrollViewMoved_ then
							arg_8_0:updateItemDetail(var_8_6.params.itemID)
						end
					end
				end)

				var_8_5 = var_8_5 + 1
			end
		end

		var_8_1:addContent(var_8_4)

		return var_8_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_8_2 then
		-- block empty
	end
end

function var_0_0.reelSourceDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return (math.ceil(#arg_10_0.list_[var_0_0.REEL_BUTTON] / 4))
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.listView_[var_0_0.REEL_BUTTON]:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.listView_[var_0_0.REEL_BUTTON]:newItem()
		else
			var_10_1:removeAllChildren(true)
		end

		local var_10_2 = 475
		local var_10_3 = 120

		var_10_1:setItemSize(var_10_2, var_10_3)

		local var_10_4 = display.newNode()

		var_10_4:setContentSize(var_10_2, var_10_3)

		local var_10_5 = 1

		for iter_10_0 = 0, 3 do
			if arg_10_3 * 4 - iter_10_0 <= #arg_10_0.list_[var_0_0.REEL_BUTTON] and arg_10_3 * 4 - iter_10_0 > 0 then
				local var_10_6 = import("app.windows.BackpackItem").new()

				var_10_6:setParams(arg_10_0.list_[var_0_0.REEL_BUTTON][arg_10_3 * 4 - iter_10_0])
				var_10_4:addChild(var_10_6)
				var_10_6:setPosition(var_10_3 * var_10_5 - var_10_3, 0)
				var_10_6:setAnchorPoint(cc.p(0.5, 0.5))
				var_10_6:ignoreAnchorPointForPosition(false)
				var_10_6:setTouchEnabled(true)
				var_10_6:setTouchSwallowEnabled(false)
				var_10_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
					if arg_11_0.name == "began" then
						var_10_6.contentView_:nodeByName("container"):setScale(0.9)

						return true
					elseif arg_11_0.name == "ended" then
						var_10_6.contentView_:nodeByName("container"):setScale(1)

						if not arg_10_0.scrollViewMoved_ then
							arg_10_0:updateItemDetail(var_10_6.params.itemID)
						end
					end
				end)

				var_10_5 = var_10_5 + 1
			end
		end

		var_10_1:addContent(var_10_4)

		return var_10_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_10_2 then
		-- block empty
	end
end

function var_0_0.updateItems(arg_12_0)
	arg_12_0.listView_:removeAllItems()

	local var_12_0 = arg_12_0.player_:getBackpack():getItemsByTypes(var_0_4[arg_12_0.displayOption])
	local var_12_1 = math.ceil(#var_12_0 / 4)
	local var_12_2 = 1

	for iter_12_0 = 1, var_12_1 do
		local var_12_3 = arg_12_0.listView_:newItem()
		local var_12_4
		local var_12_5 = display.newNode()
		local var_12_6 = 4

		if var_12_1 == iter_12_0 then
			var_12_6 = #var_12_0 % 4
		end

		if var_12_6 == 0 then
			var_12_6 = 4
		end

		for iter_12_1 = 1, var_12_6 do
			local var_12_7 = (iter_12_0 - 1) * 4 + iter_12_1
			local var_12_8 = import("app.windows.BackpackItem").new()

			var_12_8:setParams(var_12_0[var_12_7])
			var_12_5:addChild(var_12_8)
			var_12_8:setPosition(120 * iter_12_1 - 120, 0)
			var_12_8:setAnchorPoint(cc.p(0.5, 0.5))
			var_12_8:ignoreAnchorPointForPosition(false)
			var_12_8:setTouchEnabled(true)
			var_12_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
				if arg_13_0.name == "began" then
					var_12_8.contentView_:nodeByName("container"):setScale(0.9)

					return true
				elseif arg_13_0.name == "ended" then
					var_12_8.contentView_:nodeByName("container"):setScale(1)

					if not arg_12_0.scrollViewMoved_ then
						arg_12_0:updateItemDetail(var_12_8.params.itemID)
					end
				end
			end)

			var_12_2 = var_12_2 + 1
		end

		var_12_5:setContentSize(475, 120)
		var_12_3:addContent(var_12_5)
		var_12_3:setItemSize(475, 120)
		arg_12_0.listView_:addItem(var_12_3)
	end

	arg_12_0.listView_:reload()
end

function var_0_0.updateItemDetail(arg_14_0, arg_14_1)
	if not arg_14_0.itemDetailVisible then
		arg_14_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(true)

		local var_14_0, var_14_1 = arg_14_0:nodeByName(var_0_0.ITEM_DETAIL):getPosition()

		arg_14_0:nodeByName(var_0_0.ITEM_DETAIL):setPosition(var_14_0 - 200, var_14_1)
		transition.moveTo(arg_14_0:nodeByName(var_0_0.ITEM_DETAIL), {
			time = 0.3,
			x = var_14_0
		})

		arg_14_0.itemDetailVisible = true
	end

	arg_14_0.itemID = arg_14_1

	local var_14_2 = xyd.tables.item:name(arg_14_1)
	local var_14_3 = xyd.tables.item:desc1(arg_14_1)
	local var_14_4 = xyd.tables.item:desc2(arg_14_1)

	arg_14_0:nodeByName(var_0_0.NAME_TXT):setString(var_14_2)
	arg_14_0:nodeByName(var_0_0.DESC1_TXT):setString(var_14_3)
	arg_14_0:nodeByName(var_0_0.DESC2_TXT):setString(var_14_4)

	local var_14_5 = arg_14_0.player_:getBackpack():getItemNumByID(arg_14_1)

	if var_14_5 <= 0 then
		arg_14_0.itemDetailVisible = false

		arg_14_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)
	end

	arg_14_0:nodeByName(var_0_0.NUM_TXT):setString(tostring(var_14_5))

	local var_14_6, var_14_7 = arg_14_0:nodeByName(var_0_0.NUM_TXT):getPosition()

	arg_14_0:nodeByName("jian_txt"):x(var_14_6 + arg_14_0:nodeByName("num_txt"):getContentSize().width + 5)

	local var_14_8 = xyd.tables.item:mana(arg_14_1)

	arg_14_0:nodeByName(var_0_0.PRICE):setString(var_14_8)

	local var_14_9 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")

	arg_14_0:nodeByName(var_0_0.IMG_CURRENCY):removeAllChildren()

	if var_14_9 then
		xyd.displaySpriteOnContainer(var_14_9, arg_14_0:nodeByName(var_0_0.IMG_CURRENCY), false)
	end

	arg_14_0.iconImg = arg_14_0:nodeByName(var_0_0.IMG_ICON)

	arg_14_0.iconImg:removeAllChildren()
	xyd.setItemBorder(arg_14_0.iconImg, arg_14_0.itemID)
	arg_14_0:nodeByName(var_0_0.SELL_TXT):setString(var_0_1:translation("BACKPACK_SELL"))
	arg_14_0:nodeByName(var_0_0.MAKE_TXT):setString(var_0_1:translation("FRAGMENT_COMPOSE"))
	arg_14_0.panelAttr_:removeAllChildren()

	local var_14_10 = xyd.tables.item:type(arg_14_1)

	if var_14_10 == xyd.ItemType.EQUIPMENT then
		local var_14_11 = xyd.tables.item:attrs(arg_14_1)
		local var_14_12 = {}

		if var_14_11[1] and var_14_11[2] and var_14_11[3] and var_14_11[1] == var_14_11[2] and var_14_11[2] == var_14_11[3] and false then
			local var_14_13 = {
				name = var_0_2:name(1) .. "," .. var_0_2:name(2) .. "," .. var_0_2:name(3),
				value = var_14_11[1]
			}

			table.insert(var_14_12, var_14_13)

			for iter_14_0, iter_14_1 in pairs(var_14_11) do
				if iter_14_0 > 3 then
					var_14_13.name = var_0_2:name(iter_14_0)
					var_14_13.value = iter_14_1

					table.insert(var_14_12, var_14_13)
				end
			end
		else
			for iter_14_2, iter_14_3 in pairs(var_14_11) do
				local var_14_14 = {
					name = var_0_2:name(iter_14_2),
					value = iter_14_3
				}

				table.insert(var_14_12, var_14_14)
			end
		end

		arg_14_0:nodeByName("desc_bg"):height((#var_14_12 + 1) * var_0_3)
		arg_14_0:nodeByName("desc2_txt"):y(arg_14_0:nodeByName("desc_bg"):getY() - arg_14_0:nodeByName("desc_bg"):getHeight())
		arg_14_0:createLabels(var_14_12)
		arg_14_0:nodeByName(var_0_0.DESC1_TXT):setVisible(false)
	elseif var_14_10 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_14_10 == xyd.ItemType.REEL_FRAGMENT then
		local var_14_15 = xyd.tables.item:itemNum(arg_14_1)
		local var_14_16 = xyd.tables.item:composeItem(arg_14_1)
		local var_14_17 = xyd.tables.item:name(var_14_16)
		local var_14_18 = string.format(var_0_1:translation("FRAGMENT_DESC1"), var_14_15, var_14_17)
		local var_14_19 = string.format(var_0_1:translation("FRAGMENT_DESC2"), var_14_5, var_14_15)

		arg_14_0:createStrLabel(var_14_18, var_14_19)
		arg_14_0:nodeByName(var_0_0.DESC1_TXT):setVisible(false)
		arg_14_0:nodeByName("desc_bg"):height(110)
		arg_14_0:nodeByName("desc2_txt"):y(arg_14_0:nodeByName("desc_bg"):getY() - arg_14_0:nodeByName("desc_bg"):getHeight())
	else
		arg_14_0:nodeByName(var_0_0.DESC1_TXT):setString(var_14_3)
		arg_14_0:nodeByName(var_0_0.DESC1_TXT):setVisible(true)
		arg_14_0:nodeByName("desc_bg"):height(110)
		arg_14_0:nodeByName("desc2_txt"):y(arg_14_0:nodeByName("desc_bg"):getY() - arg_14_0:nodeByName("desc_bg"):getHeight())
	end
end

function var_0_0.createStrLabel(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {
		size = 20,
		color = cc.c3b(143, 236, 20)
	}
	local var_15_1 = xyd.AssetLoader:get():loadLabel(var_15_0)

	var_15_1:setMaxLineWidth(310)
	var_15_1:setString(arg_15_1)
	var_15_1:y(90)
	var_15_1:setAnchorPoint(cc.p(0, 1))
	var_15_1:addTo(arg_15_0.panelAttr_)

	local var_15_2 = {
		size = 20,
		color = cc.c3b(143, 236, 20)
	}
	local var_15_3 = xyd.AssetLoader:get():loadLabel(var_15_2)

	var_15_3:setString(arg_15_2)
	var_15_3:setAnchorPoint(cc.p(0, 1))
	var_15_3:y(30)
	var_15_3:addTo(arg_15_0.panelAttr_)
end

function var_0_0.createLabels(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0.panelAttr_:getContentSize().height

	for iter_16_0, iter_16_1 in ipairs(arg_16_1) do
		local var_16_1 = {
			size = 20,
			color = cc.c3b(143, 236, 20)
		}
		local var_16_2 = xyd.AssetLoader:get():loadLabel(var_16_1)

		var_16_2:setString(iter_16_1.name)
		var_16_2:y(var_16_0 - (iter_16_0 - 1) * var_0_3)
		var_16_2:setAnchorPoint(cc.p(0, 1))
		var_16_2:addTo(arg_16_0.panelAttr_)

		local var_16_3 = {
			size = 20,
			color = cc.c3b(143, 236, 20)
		}
		local var_16_4 = xyd.AssetLoader:get():loadLabel(var_16_3)

		var_16_4:setString("+" .. iter_16_1.value)
		var_16_4:setAnchorPoint(cc.p(0, 1))
		var_16_4:y(var_16_0 - (iter_16_0 - 1) * var_0_3):x(var_16_2:getContentSize().width)
		var_16_4:addTo(arg_16_0.panelAttr_)
	end
end

function var_0_0.didOpen(arg_17_0)
	arg_17_0:nodeByName(var_0_0.RETURN_BUTTON):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_17_0:nodeByName(var_0_0.RETURN_BUTTON), arg_18_1)
		arg_17_0:buttonHandler(handler(arg_17_0, arg_17_0.returnCallBack), arg_18_0, arg_18_1)
	end)
	arg_17_0:nodeByName(var_0_0.SELL_BUTTON):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_17_0:nodeByName(var_0_0.SELL_BUTTON), arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("sell_detail", {
				itemID = arg_17_0.itemID
			})
		end
	end)
	arg_17_0:nodeByName(var_0_0.MAKE_BUTTON):addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_17_0:nodeByName(var_0_0.MAKE_BUTTON), arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("fragment_make", {
				itemID = arg_17_0.itemID
			})
		end
	end)
end

function var_0_0.refreshDisplayOption(arg_21_0)
	for iter_21_0 = 1, #arg_21_0.optionButtons_ do
		arg_21_0.list_[var_0_5[iter_21_0]] = arg_21_0.player_:getBackpack():getItemsByTypes(var_0_4[iter_21_0])

		if iter_21_0 == arg_21_0.displayOption then
			arg_21_0.optionButtons_[iter_21_0]:setBrightStyle(ccui.BrightStyle.highlight)
			arg_21_0.listView_[var_0_5[iter_21_0]]:setLocalZOrder(99)
			arg_21_0.listView_[var_0_5[iter_21_0]]:removeAllItems()
			arg_21_0.listView_[var_0_5[iter_21_0]]:reload()
		else
			arg_21_0.optionButtons_[iter_21_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_21_0.optionButtons_[iter_21_0]:setLocalZOrder(0)
			arg_21_0.listView_[var_0_5[iter_21_0]]:setLocalZOrder(1)
			arg_21_0.listView_[var_0_5[iter_21_0]]:removeAllItems()
		end

		arg_21_0.optionTxts_[iter_21_0]:setLocalZOrder(101)
	end

	arg_21_0:nodeByName("bg"):setLocalZOrder(1)
end

function var_0_0.buttonHandler(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	if arg_22_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_22_2)
		arg_22_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_22_1 then
			arg_22_1(arg_22_2, arg_22_3)
		end
	elseif arg_22_3 == ccui.TouchEventType.began then
		local var_22_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_22_1 = cc.RepeatForever:create(var_22_0)

		arg_22_2:runAction(var_22_1)

		return true
	elseif arg_22_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_22_2)
		arg_22_2:setScale(1)
	end
end

function var_0_0.returnCallBack(arg_23_0)
	xyd.WindowManager.get():closeWindow("fragment")
end

return var_0_0
