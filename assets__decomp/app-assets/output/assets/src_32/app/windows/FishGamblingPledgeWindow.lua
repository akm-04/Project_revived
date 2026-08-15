local var_0_0 = class("BackpackWindow", import("app.windows.BackpackWindow"))
local var_0_1 = import("app.common.ui.EcoSidebar")
local var_0_2 = import("app.common.ui.SpriteNodeButton")

var_0_0.ALL_BUTTON = "all_button"
var_0_0.EQUIP_BUTTON = "equip_button"
var_0_0.REEL_BUTTON = "reel_button"
var_0_0.STONE_BUTTON = "stone_button"
var_0_0.SELL_BUTTON = "sell_button"
var_0_0.MAKE_BUTTON = "make_button"
var_0_0.CONSUMABLES_BUTTON = "consumables_button"
var_0_0.FRAGMENT_BUTTON = "fragment_button"
var_0_0.INSCRIPTION_BUTTON = "badges_button"
var_0_0.SORT_BOTTON = "sort_button"
var_0_0.ALL_TXT = "txt_all"
var_0_0.EQUIP_TXT = "txt_equip"
var_0_0.REEL_TXT = "txt_reel"
var_0_0.STONE_TXT = "txt_stone"
var_0_0.CONSUMABLES_TXT = "txt_consume"
var_0_0.FRAGMENT_TXT = "txt_fragment"
var_0_0.ITEM_DETAIL = "item_detail"
var_0_0.INSCRIPTION_TXT = "txt_badges"
var_0_0.NORMAL = "normal"
var_0_0.PRESSED = "pressed"
var_0_0.DISABLED = "disabled"
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
var_0_0.PANEL_DESC = "panel_desc"
var_0_0.PANEL_ATTR = "panel_attr"

local var_0_3 = 50001024
local var_0_4 = 50001039
local var_0_5 = 50001046
local var_0_6 = 50001047
local var_0_7 = 50001049
local var_0_8 = {
	50001025,
	50001026,
	50001027,
	50001028
}
local var_0_9 = {
	50001091,
	50001092,
	50001093
}
local var_0_10 = 128
local var_0_11 = 200
local var_0_12 = 0.2
local var_0_13 = 0.12
local var_0_14 = 5
local var_0_15 = 1.04
local var_0_16 = 0.008333333333333333
local var_0_17 = 0.03333333333333333
local var_0_18 = xyd.tables.translation
local var_0_19 = xyd.tables.attr
local var_0_20 = 28
local var_0_21 = xyd.tables.item
local var_0_22 = {
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
local var_0_23 = xyd.tables.activityFishGamblingPledge
local var_0_24 = import("framework.scheduler")
local var_0_25 = xyd.tables.misc:getValue("activity_fish_gambling_silver_coin")
local var_0_26 = {
	10,
	30,
	80,
	180,
	330
}
local var_0_27 = {
	var_0_0.ALL_BUTTON,
	var_0_0.EQUIP_BUTTON,
	var_0_0.REEL_BUTTON,
	var_0_0.STONE_BUTTON,
	var_0_0.CONSUMABLES_BUTTON,
	var_0_0.FRAGMENT_BUTTON,
	var_0_0.INSCRIPTION_BUTTON
}

function var_0_0.willOpen(arg_1_0, arg_1_1)
	arg_1_0:addTopSidebar({
		ecoCount = 2,
		show_rule = false,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_25,
			2
		},
		ecoIcons = {
			"windows/fish_gambling/fish_silver_coin.png",
			-1
		},
		ecoScale = {
			0.55,
			1
		},
		callback = handler(arg_1_0, arg_1_0.close)
	})

	arg_1_0.ecoSidebar = arg_1_0:nodeByName("eco_sidebar")

	if arg_1_0.changeBG and not tolua.isnull(arg_1_0.changeBG) then
		arg_1_0.changeBG:setPositionX(200)
	end

	arg_1_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)

	arg_1_0.itemDetailVisible = false
	arg_1_0.panelAttr_ = arg_1_0:nodeByName(var_0_0.PANEL_ATTR)

	arg_1_0:nodeByName("has_txt"):setString(var_0_18:translation("ITEM_OWN"))
	arg_1_0:nodeByName("jian_txt"):setString(var_0_18:translation("ITEM_OWN_SUFFIX"))
	arg_1_0:nodeByName("price_label"):setString(var_0_18:translation("SELL_UNIT_PRICE"))
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.leftTxt = {
		var_0_18:translation("BACKPACK_TEXT_7"),
		var_0_18:translation("BACKPACK_TEXT_8"),
		var_0_18:translation("BACKPACK_TEXT_9"),
		var_0_18:translation("BACKPACK_TEXT_10"),
		var_0_18:translation("BACKPACK_TEXT_11"),
		var_0_18:translation("BACKPACK_TEXT_12"),
		var_0_18:translation("BACKPACK_TEXT_13")
	}
	arg_1_0.leftList = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_1_0:nodeByName("scroll"):getContentSize().width, arg_1_0:nodeByName("scroll"):getContentSize().height + 10),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_1_0:nodeByName("scroll")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))

	arg_1_0.leftList:setDelegate(handler(arg_1_0, arg_1_0.leftDelegate))
	arg_1_0.leftList:reload()

	arg_1_0.backpackHandle = var_0_24.scheduleGlobal(function()
		arg_1_0:updateScale()
	end, var_0_17)
	arg_1_0.flag = false
	arg_1_0.optionButtons_ = {}
	arg_1_0.optionTxts_ = {}

	table.insert(arg_1_0.optionButtons_, arg_1_0:nodeByName(var_0_0.ALL_BUTTON))
	table.insert(arg_1_0.optionButtons_, arg_1_0:nodeByName(var_0_0.EQUIP_BUTTON))
	table.insert(arg_1_0.optionButtons_, arg_1_0:nodeByName(var_0_0.REEL_BUTTON))
	table.insert(arg_1_0.optionButtons_, arg_1_0:nodeByName(var_0_0.STONE_BUTTON))
	table.insert(arg_1_0.optionButtons_, arg_1_0:nodeByName(var_0_0.CONSUMABLES_BUTTON))
	table.insert(arg_1_0.optionButtons_, arg_1_0:nodeByName(var_0_0.FRAGMENT_BUTTON))
	table.insert(arg_1_0.optionButtons_, arg_1_0:nodeByName(var_0_0.INSCRIPTION_BUTTON))
	table.insert(arg_1_0.optionTxts_, arg_1_0:nodeByName(var_0_0.ALL_TXT))
	table.insert(arg_1_0.optionTxts_, arg_1_0:nodeByName(var_0_0.EQUIP_TXT))
	table.insert(arg_1_0.optionTxts_, arg_1_0:nodeByName(var_0_0.REEL_TXT))
	table.insert(arg_1_0.optionTxts_, arg_1_0:nodeByName(var_0_0.STONE_TXT))
	table.insert(arg_1_0.optionTxts_, arg_1_0:nodeByName(var_0_0.CONSUMABLES_TXT))
	table.insert(arg_1_0.optionTxts_, arg_1_0:nodeByName(var_0_0.FRAGMENT_TXT))
	table.insert(arg_1_0.optionTxts_, arg_1_0:nodeByName(var_0_0.INSCRIPTION_TXT))

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
	arg_1_0.listView_[var_0_0.EQUIP_BUTTON] = cc.ui.UIListView.new(var_1_0):addTo(arg_1_0:nodeByName("list")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))
	arg_1_0.listView_[var_0_0.REEL_BUTTON] = cc.ui.UIListView.new(var_1_0):addTo(arg_1_0:nodeByName("list")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))
	arg_1_0.listView_[var_0_0.STONE_BUTTON] = cc.ui.UIListView.new(var_1_0):addTo(arg_1_0:nodeByName("list")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))
	arg_1_0.listView_[var_0_0.CONSUMABLES_BUTTON] = cc.ui.UIListView.new(var_1_0):addTo(arg_1_0:nodeByName("list")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))
	arg_1_0.listView_[var_0_0.FRAGMENT_BUTTON] = cc.ui.UIListView.new(var_1_0):addTo(arg_1_0:nodeByName("list")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))
	arg_1_0.listView_[var_0_0.INSCRIPTION_BUTTON] = cc.ui.UIListView.new(var_1_0):addTo(arg_1_0:nodeByName("list")):onScroll(handler(arg_1_0, arg_1_0.scrollListener))

	arg_1_0.listView_[var_0_0.ALL_BUTTON]:setDelegate(handler(arg_1_0, arg_1_0.allSourceDelegate))
	arg_1_0.listView_[var_0_0.EQUIP_BUTTON]:setDelegate(handler(arg_1_0, arg_1_0.equipSourceDelegate))
	arg_1_0.listView_[var_0_0.REEL_BUTTON]:setDelegate(handler(arg_1_0, arg_1_0.reelSourceDelegate))
	arg_1_0.listView_[var_0_0.STONE_BUTTON]:setDelegate(handler(arg_1_0, arg_1_0.stoneSourceDelegate))
	arg_1_0.listView_[var_0_0.CONSUMABLES_BUTTON]:setDelegate(handler(arg_1_0, arg_1_0.consumablesSourceDelegate))
	arg_1_0.listView_[var_0_0.FRAGMENT_BUTTON]:setDelegate(handler(arg_1_0, arg_1_0.fragmentSourceDelegate))
	arg_1_0.listView_[var_0_0.INSCRIPTION_BUTTON]:setDelegate(handler(arg_1_0, arg_1_0.inscriptionSourceDelegate))

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
	arg_1_0.filterTypeTxt = xyd.split(var_0_18:translation("BACKPACK_FILTER_TYPE"), ",")

	arg_1_0.player_:loadBackpack(function(arg_4_0)
		if arg_4_0 == xyd.error.OK then
			arg_1_0.displayOption = 1

			arg_1_0:refreshDisplayOption()
		end
	end)
	arg_1_0:addInscriptionAssetsContainer()
	arg_1_0:runTagBtnAction()
	arg_1_0:nodeByName("price_label"):setString(var_0_18:translation("ACTIVITY_FISH_GAMBLING_TEXT_17"))
end

function var_0_0.updateItemDetail(arg_5_0, arg_5_1)
	var_0_0.super.updateItemDetail(arg_5_0, arg_5_1)
	arg_5_0:nodeByName("detail_txt"):setString(var_0_18:translation("ACTIVITY_FISH_GAMBLING_TEXT_18"))
	arg_5_0:nodeByName(var_0_0.MAKE_BUTTON):setPositionX(178.5)
	arg_5_0:nodeByName(var_0_0.SELL_BUTTON):setVisible(false)
	arg_5_0:nodeByName(var_0_0.IMG_CURRENCY):removeAllChildren()

	local var_5_0 = var_0_21:inscriptId(arg_5_1)
	local var_5_1 = xyd.SpriteLoader.new("windows/fish_gambling/fish_silver_coin.png", nil, nil, xyd.DefaultImageType.CHARGE)

	xyd.displaySpriteOnContainer(var_5_1, arg_5_0:nodeByName(var_0_0.IMG_CURRENCY), true)
	arg_5_0:nodeByName(var_0_0.PRICE):setString(var_0_23:coinNumByItem(arg_5_1))
end

function var_0_0.didOpen(arg_6_0)
	var_0_0.super.didOpen(arg_6_0)
	arg_6_0:nodeByName(var_0_0.MAKE_BUTTON):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName(var_0_0.MAKE_BUTTON), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = arg_6_0.itemID

			xyd.WindowManager.get():openWindow("fish_gambling_sell_detail", {
				itemID = arg_6_0.itemID
			})
		end
	end)
end

function var_0_0.filterList(arg_8_0, arg_8_1)
	for iter_8_0 = #arg_8_1, 1, -1 do
		if not var_0_23:isMortageItem(arg_8_1[iter_8_0].itemID) then
			table.remove(arg_8_1, iter_8_0)
		end
	end

	return arg_8_1
end

function var_0_0.refreshDisplayOption(arg_9_0, arg_9_1)
	for iter_9_0 = 1, #arg_9_0.optionButtons_ do
		local var_9_0 = arg_9_0.player_:getBackpack():getItemsByTypes(var_0_22[iter_9_0])

		arg_9_0.list_[var_0_27[iter_9_0]] = arg_9_0:filterList(var_9_0)

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
			arg_9_0.listView_[var_0_27[iter_9_0]]:setLocalZOrder(1)
			arg_9_0.listView_[var_0_27[iter_9_0]]:removeAllItems()
		end

		arg_9_0.optionTxts_[iter_9_0]:setLocalZOrder(101)
	end

	arg_9_0:nodeByName("bg"):setLocalZOrder(1)
end

function var_0_0.refreshDisplayOptionAfterSell(arg_10_0)
	for iter_10_0 = 1, #arg_10_0.optionButtons_ do
		local var_10_0 = arg_10_0.player_:getBackpack():getItemsByTypes(var_0_22[iter_10_0])

		arg_10_0.list_[var_0_27[iter_10_0]] = arg_10_0:filterList(var_10_0)

		if iter_10_0 == arg_10_0.displayOption then
			arg_10_0:filterSort(iter_10_0)

			local var_10_1 = 0
			local var_10_2 = arg_10_0.listView_[var_0_27[iter_10_0]].scrollNode:getPositionY()
			local var_10_3 = import("app.windows.BackpackItem").new()

			if arg_10_0.player_:getBackpack():getItemNumByID(arg_10_0.itemID) <= 0 then
				if #arg_10_0.list_[var_0_27[arg_10_0.displayOption]] >= 1 then
					var_10_3:setParams(arg_10_0.list_[var_0_27[arg_10_0.displayOption]][1])
					arg_10_0:updateItemDetail(var_10_3.params.itemID)

					arg_10_0.flag = arg_10_0:isTiliItem(var_10_3.params.itemID)

					arg_10_0:updateAssetsShowState(var_10_3.params.itemID)
				else
					arg_10_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)
				end
			end

			arg_10_0.listView_[var_0_27[iter_10_0]]:reload()

			if var_10_2 > 0 then
				if var_10_2 > var_0_10 * math.ceil(#arg_10_0.list_[var_0_27[iter_10_0]] / var_0_14) and var_10_2 > arg_10_0.listView_[var_0_27[iter_10_0]]:getViewRectInWorldSpace().height + 2 then
					var_10_2 = var_0_10 * math.ceil(#arg_10_0.list_[var_0_27[iter_10_0]] / var_0_14)
				end

				arg_10_0.listView_[var_0_27[iter_10_0]].scrollNode:setPosition(0, var_10_2)
			end
		else
			arg_10_0.optionButtons_[iter_10_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_10_0.optionButtons_[iter_10_0]:setLocalZOrder(0)
			arg_10_0.listView_[var_0_27[iter_10_0]]:setLocalZOrder(1)
			arg_10_0.listView_[var_0_27[iter_10_0]]:removeAllItems()
		end

		arg_10_0.optionTxts_[iter_10_0]:setLocalZOrder(101)
	end

	arg_10_0:nodeByName("bg"):setLocalZOrder(1)
end

function var_0_0.addInscriptionAssetsContainer(arg_11_0)
	arg_11_0:addTopSidebar({
		ecoCount = 2,
		show_rule = false,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_25,
			2
		},
		ecoIcons = {
			"windows/fish_gambling/fish_silver_coin.png",
			-1
		},
		ecoScale = {
			0.55,
			1
		},
		callback = handler(arg_11_0, arg_11_0.close)
	})

	arg_11_0.ecoSidebar = arg_11_0:nodeByName("eco_sidebar")

	local var_11_0 = "windows/button/btn_add_eco.png"
	local var_11_1 = xyd.tables.systemColor:btnColors(arg_11_0.colorMode)
	local var_11_2 = {
		sprite = var_11_0,
		colorModes = var_11_1
	}
	local var_11_3 = var_0_2.new(var_11_2)

	var_11_3:setAnchorPoint(0.5, 0.5)
	var_11_3:addTo(arg_11_0.ecoSidebar:nodeByName("eco_1"))

	arg_11_0.oldCoinTxt = arg_11_0.ecoSidebar:nodeByName("eco_1"):getChildByName("txt_eco_val_1")

	var_11_3:setPositionX(arg_11_0.ecoSidebar:nodeByName("pos_icon_1"):getPositionX() + 140)
	var_11_3:setPositionY(arg_11_0.ecoSidebar:nodeByName("pos_icon_1"):getPositionY())
	var_11_3:setName("coin_btn")

	arg_11_0.children_.coin_btn = var_11_3

	var_11_3:addTouchEvent(function(arg_12_0)
		if arg_12_0.name == "ended" then
			xyd.playButtonSound()

			local var_12_0 = arg_11_0.itemID

			function callback()
				return
			end

			xyd.WindowManager.get():openWindow("fish_gambling_sell_detail", {
				itemID = arg_11_0.itemID
			})
		end
	end)

	local var_11_4 = var_0_2.new(var_11_2)

	var_11_4:setAnchorPoint(0.5, 0.5)
	var_11_4:addTo(arg_11_0.ecoSidebar:nodeByName("eco_2"))

	arg_11_0.crystalTxt = arg_11_0.ecoSidebar:nodeByName("eco_2"):getChildByName("txt_eco_val_2")

	var_11_4:setPositionX(arg_11_0.ecoSidebar:nodeByName("pos_icon_2"):getPositionX() + 140)
	var_11_4:setPositionY(arg_11_0.ecoSidebar:nodeByName("pos_icon_1"):getPositionY())
	var_11_4:setName("crystal_btn")

	arg_11_0.children_.crystal_btn = var_11_4

	var_11_4:addTouchEvent(function(arg_14_0)
		if arg_14_0.name == "ended" then
			xyd.playButtonSound()
			arg_11_0.player_:sendFunctionClick(xyd.FunctionClick.CHARGE)
			xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
		end
	end)
	arg_11_0:updateEco()
end

function var_0_0.updateEco(arg_15_0)
	local var_15_0 = arg_15_0.crystalTxt:getString()
	local var_15_1 = xyd.num2ThousandsStr(arg_15_0.player_.crystal)

	if var_15_0 ~= var_15_1 then
		arg_15_0.crystalTxt:setString(var_15_1)

		local var_15_2 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_15_3 = cc.Spawn:create(var_15_2)

		arg_15_0.crystalTxt:runAction(var_15_3)
	end

	if arg_15_0.oldCoinTxt then
		local var_15_4 = arg_15_0.oldCoinTxt:getString()
		local var_15_5 = xyd.num2ThousandsStr(arg_15_0.player_:getBackpack():getItemNumByID(var_0_25))

		if var_15_4 ~= var_15_5 then
			arg_15_0.oldCoinTxt:setString(var_15_5)

			local var_15_6 = transition.sequence({
				cc.ScaleTo:create(0.3, 1.5),
				cc.ScaleTo:create(0.3, 1)
			})
			local var_15_7 = cc.Spawn:create(var_15_6)

			arg_15_0.oldCoinTxt:runAction(var_15_7)
		end
	end
end

function var_0_0.updateAssetsShowState(arg_16_0, arg_16_1)
	return
end

return var_0_0
