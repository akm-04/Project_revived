local var_0_0 = class("BackpackWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.EcoSidebar")

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

local var_0_2 = 50001024
local var_0_3 = 50001039
local var_0_4 = 50001046
local var_0_5 = 50001047
local var_0_6 = 50001049
local var_0_7 = {
	50001025,
	50001026,
	50001027,
	50001028
}
local var_0_8 = {
	50001091,
	50001092,
	50001093
}
local var_0_9 = 128
local var_0_10 = 200
local var_0_11 = 0.2
local var_0_12 = 0.12
local var_0_13 = 5
local var_0_14 = 1.04
local var_0_15 = 0.008333333333333333
local var_0_16 = 0.03333333333333333
local var_0_17 = xyd.tables.translation
local var_0_18 = xyd.tables.attr
local var_0_19 = 28
local var_0_20 = xyd.tables.item
local var_0_21 = {
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
local var_0_22 = import("framework.scheduler")
local var_0_23 = {
	10,
	30,
	80,
	180,
	330
}
local var_0_24 = {
	var_0_0.ALL_BUTTON,
	var_0_0.EQUIP_BUTTON,
	var_0_0.REEL_BUTTON,
	var_0_0.STONE_BUTTON,
	var_0_0.CONSUMABLES_BUTTON,
	var_0_0.FRAGMENT_BUTTON,
	var_0_0.INSCRIPTION_BUTTON
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.inscription_ = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack_ = arg_1_0.player_:getBackpack()
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.actionNum = 7
	arg_1_0.leftOnShow = 1
	arg_1_0.firstPlayEffect = 1
	arg_1_0.changeEffect = false
	arg_1_0.sortChange = false
	arg_1_0.playAction = {
		1,
		5,
		2,
		3,
		4,
		6,
		7
	}
	arg_1_0.add = true
	arg_1_0.scale = 1
	arg_1_0.ecoBarType = xyd.EcoSidebarType.MAIN
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()

	if arg_2_0.changeBG and not tolua.isnull(arg_2_0.changeBG) then
		arg_2_0.changeBG:setPositionX(200)
	end

	arg_2_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)

	arg_2_0.itemDetailVisible = false
	arg_2_0.panelAttr_ = arg_2_0:nodeByName(var_0_0.PANEL_ATTR)

	arg_2_0:nodeByName("has_txt"):setString(var_0_17:translation("ITEM_OWN"))
	arg_2_0:nodeByName("jian_txt"):setString(var_0_17:translation("ITEM_OWN_SUFFIX"))
	arg_2_0:nodeByName("price_label"):setString(var_0_17:translation("SELL_UNIT_PRICE"))
	arg_2_0:setTouchSwallowEnabled(false)

	arg_2_0.leftTxt = {
		var_0_17:translation("BACKPACK_TEXT_7"),
		var_0_17:translation("BACKPACK_TEXT_8"),
		var_0_17:translation("BACKPACK_TEXT_9"),
		var_0_17:translation("BACKPACK_TEXT_10"),
		var_0_17:translation("BACKPACK_TEXT_11"),
		var_0_17:translation("BACKPACK_TEXT_12"),
		var_0_17:translation("BACKPACK_TEXT_13")
	}
	arg_2_0.leftList = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("scroll"):getContentSize().width, arg_2_0:nodeByName("scroll"):getContentSize().height + 10),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("scroll")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.leftList:setDelegate(handler(arg_2_0, arg_2_0.leftDelegate))
	arg_2_0.leftList:reload()

	arg_2_0.backpackHandle = var_0_22.scheduleGlobal(function()
		arg_2_0:updateScale()
	end, var_0_16)
	arg_2_0.flag = false
	arg_2_0.optionButtons_ = {}
	arg_2_0.optionTxts_ = {}

	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.ALL_BUTTON))
	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.EQUIP_BUTTON))
	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.REEL_BUTTON))
	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.STONE_BUTTON))
	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.CONSUMABLES_BUTTON))
	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.FRAGMENT_BUTTON))
	table.insert(arg_2_0.optionButtons_, arg_2_0:nodeByName(var_0_0.INSCRIPTION_BUTTON))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.ALL_TXT))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.EQUIP_TXT))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.REEL_TXT))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.STONE_TXT))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.CONSUMABLES_TXT))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.FRAGMENT_TXT))
	table.insert(arg_2_0.optionTxts_, arg_2_0:nodeByName(var_0_0.INSCRIPTION_TXT))

	local var_2_0 = {
		touchOnContent = true,
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list"):getContentSize().width, arg_2_0:nodeByName("list"):getContentSize().height + 10),
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
	arg_2_0.listView_[var_0_0.STONE_BUTTON] = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	arg_2_0.listView_[var_0_0.CONSUMABLES_BUTTON] = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	arg_2_0.listView_[var_0_0.FRAGMENT_BUTTON] = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
	arg_2_0.listView_[var_0_0.INSCRIPTION_BUTTON] = cc.ui.UIListView.new(var_2_0):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listView_[var_0_0.ALL_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.allSourceDelegate))
	arg_2_0.listView_[var_0_0.EQUIP_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.equipSourceDelegate))
	arg_2_0.listView_[var_0_0.REEL_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.reelSourceDelegate))
	arg_2_0.listView_[var_0_0.STONE_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.stoneSourceDelegate))
	arg_2_0.listView_[var_0_0.CONSUMABLES_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.consumablesSourceDelegate))
	arg_2_0.listView_[var_0_0.FRAGMENT_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.fragmentSourceDelegate))
	arg_2_0.listView_[var_0_0.INSCRIPTION_BUTTON]:setDelegate(handler(arg_2_0, arg_2_0.inscriptionSourceDelegate))

	for iter_2_0 = 1, #arg_2_0.optionButtons_ do
		arg_2_0.optionButtons_[iter_2_0]:addTouchEventListener(function(arg_4_0, arg_4_1)
			if arg_4_1 == ccui.TouchEventType.ended then
				local var_4_0

				if iter_2_0 == arg_2_0.displayOption then
					var_4_0 = false
				end

				xyd.playButtonSound()

				arg_2_0.displayOption = iter_2_0

				arg_2_0:refreshDisplayOption(var_4_0)
			end
		end)
	end

	arg_2_0.list_ = {}
	arg_2_0.filterTypeTxt = xyd.split(var_0_17:translation("BACKPACK_FILTER_TYPE"), ",")

	arg_2_0.player_:loadBackpack(function(arg_5_0)
		if arg_5_0 == xyd.error.OK then
			arg_2_0.displayOption = 1

			arg_2_0:refreshDisplayOption()
		end
	end)
	arg_2_0:addInscriptionAssetsContainer()
	arg_2_0:runTagBtnAction()
end

function var_0_0.leftDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #var_0_24
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.leftList:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.leftList:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/backpack_window/left_btn.csb")
		local var_6_2 = var_6_1:getChildByName("container")

		var_6_1:setPosition(10, 0)
		var_6_1:setAnchorPoint(cc.p(0, 0))

		if arg_6_0.leftOnShow == arg_6_3 then
			arg_6_0.skipBtn_ = var_6_2

			var_6_2:getChildByName("left_button"):setBrightStyle(ccui.BrightStyle.highlight)
		else
			var_6_2:getChildByName("left_button"):setBrightStyle(ccui.BrightStyle.normal)
		end

		var_6_2:getChildByName("left_button"):addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				arg_6_0.firstPlayEffect = 1

				if arg_6_0.skipBtn_ and not tolua.isnull(arg_6_0.skipBtn_) then
					arg_6_0.skipBtn_:getChildByName("left_button"):setBrightStyle(ccui.BrightStyle.normal)
				end

				arg_6_0.skipBtn_ = var_6_2

				var_6_2:getChildByName("left_button"):setBrightStyle(ccui.BrightStyle.highlight)

				local var_7_0

				if arg_6_0.playAction[arg_6_3] == arg_6_0.displayOption then
					var_7_0 = false
				end

				if var_7_0 == nil then
					arg_6_0.changeEffect = true
				end

				arg_6_0.displayOption = arg_6_0.playAction[arg_6_3]

				arg_6_0:refreshDisplayOption(var_7_0)

				arg_6_0.leftOnShow = arg_6_3

				if var_7_0 == nil then
					local var_7_1 = import("app.windows.BackpackItem").new()

					if #arg_6_0.list_[var_0_24[arg_6_0.displayOption]] >= 1 then
						var_7_1:setParams(arg_6_0.list_[var_0_24[arg_6_0.displayOption]][1])
						arg_6_0:updateItemDetail(var_7_1.params.itemID)

						arg_6_0.flag = arg_6_0:isTiliItem(var_7_1.params.itemID)

						arg_6_0:updateAssetsShowState(var_7_1.params.itemID)
						arg_6_0.listView_[var_0_24[arg_6_0.displayOption]]:getScrollNode():setPositionY(630)

						if not tolua.isnull(arg_6_0.itemCellContent) and arg_6_0.backpackHandle == nil then
							arg_6_0.backpackHandle = var_0_22.scheduleGlobal(function()
								arg_6_0:updateScale()
							end, var_0_16)
						end
					else
						arg_6_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)
					end
				end
			end
		end)
		var_6_2:getChildByName("txt"):setString(arg_6_0.leftTxt[arg_6_3])
		var_6_0:setItemSize(191, 81)
		var_6_0:addContent(var_6_1)

		if arg_6_0.actionNum > 0 then
			local var_6_3 = cc.p(var_6_2:getPosition())

			var_6_2:pos(var_6_3.x - var_0_10, var_6_3.y)
			var_6_2:runAction(cc.Sequence:create({
				cc.DelayTime:create(var_0_12 * (arg_6_3 - 1)),
				cc.Spawn:create({
					cc.MoveBy:create(var_0_11, cc.p(var_0_10, 0)),
					cc.FadeIn:create(var_0_11)
				}),
				cc.CallFunc:create(function()
					arg_6_0.actionNum = arg_6_0.actionNum - 1
				end)
			}))
		end

		return var_6_0
	end
end

function var_0_0.runTagBtnAction(arg_10_0)
	local var_10_0 = import("app.windows.BackpackItem").new()

	if #arg_10_0.list_[var_0_0.ALL_BUTTON] >= 1 then
		var_10_0:setParams(arg_10_0.list_[var_0_0.ALL_BUTTON][1])
		arg_10_0:updateItemDetail(var_10_0.params.itemID)

		arg_10_0.flag = arg_10_0:isTiliItem(var_10_0.params.itemID)

		arg_10_0:updateAssetsShowState(var_10_0.params.itemID)
	end
end

function var_0_0.addInscriptionAssetsContainer(arg_11_0)
	local var_11_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_widgets/eco_display_sidebar.csb")

	arg_11_0:addChild(var_11_0)
	var_11_0:setPosition(cc.p(440, 674))
	arg_11_0:parseChildren_(var_11_0)
	var_11_0:setName("asset_container")
	var_11_0:setVisible(false)

	local var_11_1 = xyd.AssetLoader.get():loadSprite("windows/common/red_star.png")

	var_11_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_11_1:addTo(arg_11_0:nodeByName("pos_icon_4"))

	local var_11_2 = xyd.AssetLoader.get():loadSprite("windows/common/blue_star.png")

	var_11_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_11_2:addTo(arg_11_0:nodeByName("pos_icon_3"))

	local var_11_3 = xyd.AssetLoader.get():loadSprite("windows/common/green_star.png")

	var_11_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_11_3:addTo(arg_11_0:nodeByName("pos_icon_2"))

	local var_11_4 = xyd.AssetLoader.get():loadSprite("windows/common/solid_heart.png")

	var_11_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_11_4:addTo(arg_11_0:nodeByName("pos_icon_1"))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.ECONOMY_AFTER, function(arg_12_0)
		if arg_11_0 then
			arg_11_0:updateAssetsShow()
		end
	end)
	arg_11_0:updateAssetsShow()
end

function var_0_0.updateAssetsShow(arg_13_0)
	arg_13_0:nodeByName("txt_eco_val_4"):setString(arg_13_0.player_.degreeCer)
	arg_13_0:nodeByName("txt_eco_val_3"):setString(arg_13_0.player_.graduateCer)
	arg_13_0:nodeByName("txt_eco_val_2"):setString(arg_13_0.player_.patentCer)
	arg_13_0:nodeByName("txt_eco_val_1"):setString(arg_13_0.player_:getBackpack():getItemNumByID(xyd.tables.misc.speacialItemID))
end

function var_0_0.updateAssetsShowState(arg_14_0, arg_14_1)
	local var_14_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.mainSceneTopWnd)

	if var_0_20:type(arg_14_1) == xyd.ItemType.INSCRIPTION then
		arg_14_0:getChildByName("asset_container"):setVisible(true)

		if var_14_0 and not tolua.isnull(var_14_0) then
			arg_14_0.children_.eco_sidebar:setVisible(false)
		end
	else
		arg_14_0:getChildByName("asset_container"):setVisible(false)

		if var_14_0 and not tolua.isnull(var_14_0) then
			arg_14_0.children_.eco_sidebar:setVisible(true)
		end
	end
end

function var_0_0.scrollListener(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.scrollViewMoved_ = false
		arg_15_0.prevY_ = arg_15_1.y
	elseif arg_15_1.name == "moved" then
		if 1 <= math.abs(arg_15_1.y - arg_15_0.prevY_) then
			arg_15_0.scrollViewMoved_ = true
		end

		if arg_15_0.scrollViewMoved_ == true and not tolua.isnull(arg_15_0.itemCellContent) and arg_15_0.backpackHandle == nil then
			arg_15_0.backpackHandle = var_0_22.scheduleGlobal(function()
				arg_15_0:updateScale()
			end, var_0_16)
		end
	end
end

function var_0_0.updateListView(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	local var_17_0
	local var_17_1 = arg_17_0.listView_[arg_17_3]:dequeueItem()

	if not var_17_1 then
		var_17_1 = arg_17_0.listView_[arg_17_3]:newItem()
	else
		var_17_1:removeAllChildren(true)
	end

	local var_17_2 = 600
	local var_17_3 = var_0_9

	var_17_1:setItemSize(var_17_2, var_17_3)

	local var_17_4 = display.newNode()

	var_17_4:setContentSize(var_17_2, var_17_3)

	local var_17_5 = 1

	for iter_17_0 = var_0_13 - 1, 0, -1 do
		if arg_17_2 * var_0_13 - iter_17_0 <= #arg_17_0.list_[arg_17_3] and arg_17_2 * var_0_13 - iter_17_0 > 0 then
			local var_17_6 = import("app.windows.BackpackItem").new()

			var_17_6:setParams(arg_17_0.list_[arg_17_3][arg_17_2 * var_0_13 - iter_17_0])
			var_17_4:addChild(var_17_6)
			var_17_6:setPosition(var_17_3 * var_17_5 - var_17_3 + 5, 0)
			var_17_6:setAnchorPoint(cc.p(0.5, 0.5))
			var_17_6:ignoreAnchorPointForPosition(false)
			var_17_6:setTouchEnabled(true)
			var_17_6:setTouchSwallowEnabled(false)

			if arg_17_0.cells == nil then
				arg_17_0.cells = {}
			end

			if arg_17_0.cells[arg_17_3] == nil then
				arg_17_0.cells[arg_17_3] = {}
			end

			arg_17_0.cells[arg_17_3][arg_17_2 * var_0_13 - iter_17_0] = var_17_6

			if arg_17_0.itemID == var_17_6.params.itemID and arg_17_0.changeEffect == false then
				if arg_17_0.itemCellContent and not tolua.isnull(arg_17_0.itemCellContent) then
					arg_17_0.itemCellContent:removeChild(arg_17_0.bg, true)
				end

				arg_17_0.itemCellContent = var_17_6

				arg_17_0:addClickEffects(var_17_6)

				arg_17_0.firstPlayEffect = arg_17_0.firstPlayEffect + 1
			end

			if tolua.isnull(arg_17_0.itemCellContent) and arg_17_2 == 1 and arg_17_0.firstPlayEffect == 1 then
				if arg_17_0.itemCellContent and not tolua.isnull(arg_17_0.itemCellContent) then
					arg_17_0.itemCellContent:removeChild(arg_17_0.bg, true)
				end

				arg_17_0.itemID = var_17_6.params.itemID
				arg_17_0.itemCellContent = var_17_6

				arg_17_0:addClickEffects(var_17_6)

				arg_17_0.firstPlayEffect = arg_17_0.firstPlayEffect + 1
			end

			if arg_17_0.changeEffect == true and arg_17_2 == 1 then
				if arg_17_0.itemCellContent and not tolua.isnull(arg_17_0.itemCellContent) then
					arg_17_0.itemCellContent:removeChild(arg_17_0.bg, true)
				end

				arg_17_0.itemID = var_17_6.params.itemID
				arg_17_0.itemCellContent = var_17_6

				arg_17_0:addClickEffects(var_17_6)

				arg_17_0.changeEffect = false
				arg_17_0.firstPlayEffect = arg_17_0.firstPlayEffect + 1
			end

			if arg_17_0.sortChange == true and arg_17_2 == 1 then
				if arg_17_0.itemCellContent and not tolua.isnull(arg_17_0.itemCellContent) then
					arg_17_0.itemCellContent:removeChild(arg_17_0.bg, true)
				end

				arg_17_0.itemID = var_17_6.params.itemID
				arg_17_0.itemCellContent = var_17_6

				arg_17_0:addClickEffects(var_17_6)

				arg_17_0.sortChange = false
				arg_17_0.firstPlayEffect = arg_17_0.firstPlayEffect + 1
			end

			if not tolua.isnull(arg_17_0.itemCellContent) and arg_17_0.backpackHandle == nil then
				arg_17_0.backpackHandle = var_0_22.scheduleGlobal(function()
					arg_17_0:updateScale()
				end, var_0_16)
			end

			var_17_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
				if arg_19_0.name == "began" then
					var_17_6.contentView_:nodeByName("container"):setScale(0.9)

					return true
				elseif arg_19_0.name == "ended" then
					xyd.playButtonSound()
					var_17_6.contentView_:nodeByName("container"):setScale(1)

					arg_17_0.changeEffect = false

					if not arg_17_0.scrollViewMoved_ then
						arg_17_0:updateItemDetail(var_17_6.params.itemID)

						arg_17_0.flag = arg_17_0:isTiliItem(var_17_6.params.itemID)

						arg_17_0:updateAssetsShowState(var_17_6.params.itemID)

						if arg_17_0.itemCellContent and not tolua.isnull(arg_17_0.itemCellContent) then
							arg_17_0.itemCellContent:removeChild(arg_17_0.bg, true)
						end

						arg_17_0.itemCellContent = var_17_6

						arg_17_0:addClickEffects(var_17_6)

						if not tolua.isnull(arg_17_0.itemCellContent) and arg_17_0.backpackHandle == nil then
							arg_17_0.backpackHandle = var_0_22.scheduleGlobal(function()
								arg_17_0:updateScale()
							end, var_0_16)
						end
					end
				end
			end)

			var_17_5 = var_17_5 + 1
		end
	end

	var_17_1:addContent(var_17_4)

	return var_17_1
end

function var_0_0.addClickEffects(arg_21_0, arg_21_1)
	local var_21_0 = "windows/backpack_window/click_on.png"
	local var_21_1 = xyd.AssetLoader:get():loadSprite(var_21_0)

	arg_21_1:addChild(var_21_1)

	local var_21_2 = 55

	var_21_1:setPosition(var_21_2 + 1, var_21_2)
	var_21_1:setAnchorPoint(cc.p(0.5, 0.5))

	arg_21_0.bg = var_21_1
end

function var_0_0.updateScale(arg_22_0)
	if arg_22_0.add == false then
		if arg_22_0.scale <= 1 then
			arg_22_0.add = true
		end

		arg_22_0.scale = arg_22_0.scale - var_0_15
	else
		if arg_22_0.scale >= var_0_14 then
			arg_22_0.add = false
		end

		arg_22_0.scale = arg_22_0.scale + var_0_15
	end

	if not tolua.isnull(arg_22_0.itemCellContent) then
		arg_22_0.bg:setScale(arg_22_0.scale)
	end

	if tolua.isnull(arg_22_0.itemCellContent) then
		var_0_22.unscheduleGlobal(arg_22_0.backpackHandle)

		arg_22_0.backpackHandle = nil
	end
end

function var_0_0.allSourceDelegate(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	if cc.ui.UIListView.COUNT_TAG == arg_23_2 then
		return (math.ceil(#arg_23_0.list_[var_0_0.ALL_BUTTON] / var_0_13))
	elseif cc.ui.UIListView.CELL_TAG == arg_23_2 then
		return arg_23_0:updateListView(arg_23_2, arg_23_3, var_0_0.ALL_BUTTON)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_23_2 then
		-- block empty
	end
end

function var_0_0.equipSourceDelegate(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	if cc.ui.UIListView.COUNT_TAG == arg_24_2 then
		return (math.ceil(#arg_24_0.list_[var_0_0.EQUIP_BUTTON] / var_0_13))
	elseif cc.ui.UIListView.CELL_TAG == arg_24_2 then
		return arg_24_0:updateListView(arg_24_2, arg_24_3, var_0_0.EQUIP_BUTTON)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_24_2 then
		-- block empty
	end
end

function var_0_0.reelSourceDelegate(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	if cc.ui.UIListView.COUNT_TAG == arg_25_2 then
		return (math.ceil(#arg_25_0.list_[var_0_0.REEL_BUTTON] / var_0_13))
	elseif cc.ui.UIListView.CELL_TAG == arg_25_2 then
		return arg_25_0:updateListView(arg_25_2, arg_25_3, var_0_0.REEL_BUTTON)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_25_2 then
		-- block empty
	end
end

function var_0_0.stoneSourceDelegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		return (math.ceil(#arg_26_0.list_[var_0_0.STONE_BUTTON] / var_0_13))
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		return arg_26_0:updateListView(arg_26_2, arg_26_3, var_0_0.STONE_BUTTON)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_26_2 then
		-- block empty
	end
end

function var_0_0.consumablesSourceDelegate(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	if cc.ui.UIListView.COUNT_TAG == arg_27_2 then
		return (math.ceil(#arg_27_0.list_[var_0_0.CONSUMABLES_BUTTON] / var_0_13))
	elseif cc.ui.UIListView.CELL_TAG == arg_27_2 then
		return arg_27_0:updateListView(arg_27_2, arg_27_3, var_0_0.CONSUMABLES_BUTTON)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_27_2 then
		-- block empty
	end
end

function var_0_0.fragmentSourceDelegate(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	if cc.ui.UIListView.COUNT_TAG == arg_28_2 then
		return (math.ceil(#arg_28_0.list_[var_0_0.FRAGMENT_BUTTON] / var_0_13))
	elseif cc.ui.UIListView.CELL_TAG == arg_28_2 then
		return arg_28_0:updateListView(arg_28_2, arg_28_3, var_0_0.FRAGMENT_BUTTON)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_28_2 then
		-- block empty
	end
end

function var_0_0.inscriptionSourceDelegate(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	if cc.ui.UIListView.COUNT_TAG == arg_29_2 then
		return (math.ceil(#arg_29_0.list_[var_0_0.INSCRIPTION_BUTTON] / var_0_13))
	elseif cc.ui.UIListView.CELL_TAG == arg_29_2 then
		return arg_29_0:updateListView(arg_29_2, arg_29_3, var_0_0.INSCRIPTION_BUTTON)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_29_2 then
		-- block empty
	end
end

function var_0_0.updateItemDetail(arg_30_0, arg_30_1)
	local var_30_0 = var_0_20:type(arg_30_1)

	arg_30_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(true)

	if not arg_30_0.itemDetailVisible then
		local var_30_1, var_30_2 = arg_30_0:nodeByName(var_0_0.ITEM_DETAIL):getPosition()

		arg_30_0:nodeByName(var_0_0.ITEM_DETAIL):setPosition(var_30_1 + 200, var_30_2)
		transition.moveTo(arg_30_0:nodeByName(var_0_0.ITEM_DETAIL), {
			time = 0.3,
			x = var_30_1
		})

		arg_30_0.itemDetailVisible = true
	end

	arg_30_0.itemID = arg_30_1

	local var_30_3 = var_0_20:name(arg_30_1)
	local var_30_4 = var_0_20:desc1(arg_30_1)
	local var_30_5 = var_0_20:desc2(arg_30_1)

	arg_30_0:nodeByName(var_0_0.NAME_TXT):setString(var_30_3)

	local var_30_6 = arg_30_0.player_:getBackpack():getItemNumByID(arg_30_1)

	if var_30_6 <= 0 then
		arg_30_0.itemDetailVisible = false

		arg_30_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)
	end

	arg_30_0:nodeByName(var_0_0.NUM_TXT):setString(tostring(var_30_6))

	local var_30_7, var_30_8 = arg_30_0:nodeByName(var_0_0.NUM_TXT):getPosition()

	arg_30_0:nodeByName("jian_txt"):x(var_30_7 + arg_30_0:nodeByName("num_txt"):getContentSize().width + 5)

	local var_30_9 = var_0_20:mana(arg_30_1)
	local var_30_10 = var_0_20:crystal(arg_30_1)

	arg_30_0:nodeByName("price_label"):setString(var_0_17:translation("SELL_UNIT_PRICE"))

	if var_30_0 == xyd.ItemType.INSCRIPTION then
		arg_30_0:nodeByName("price_label"):setString(var_0_17:translation("RESOLVE_GET_TEXT"))
	end

	local var_30_11

	if var_30_10 ~= 0 then
		var_30_11 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
	else
		var_30_11 = xyd.AssetLoader:get():loadSprite("windows/common/jinbi1.png")
	end

	arg_30_0:nodeByName(var_0_0.IMG_CURRENCY):removeAllChildren()

	if var_30_11 then
		xyd.displaySpriteOnContainer(var_30_11, arg_30_0:nodeByName(var_0_0.IMG_CURRENCY), false)
	end

	arg_30_0.iconImg = arg_30_0:nodeByName(var_0_0.IMG_ICON)

	arg_30_0.iconImg:removeAllChildren()

	if var_30_9 ~= 0 then
		arg_30_0:nodeByName(var_0_0.PRICE):setString(var_30_9)
	else
		arg_30_0:nodeByName(var_0_0.PRICE):setString(var_30_10)
	end

	xyd.setItemBorder(arg_30_0.iconImg, arg_30_1)

	if var_30_0 == xyd.ItemType.INSCRIPTION then
		arg_30_0:nodeByName("txt_sell"):setVisible(false)
		arg_30_0:nodeByName("decompose_text"):setVisible(true)
		arg_30_0:nodeByName(var_0_0.IMG_CURRENCY):removeAllChildren()

		local var_30_12 = var_0_20:inscriptId(arg_30_1)
		local var_30_13 = arg_30_0.inscription_:getMaterialIcon(xyd.tables.inscription:resolveMaterial(var_30_12))

		xyd.displaySpriteOnContainer(var_30_13, arg_30_0:nodeByName(var_0_0.IMG_CURRENCY), false)
		arg_30_0:nodeByName(var_0_0.PRICE):setString(xyd.tables.inscription:resolveNum(var_30_12))
	elseif arg_30_0:isCanResolveRoomKey(arg_30_0.itemID) then
		arg_30_0:nodeByName("txt_sell"):setVisible(false)
		arg_30_0:nodeByName("decompose_text"):setVisible(true)
		arg_30_0:nodeByName(var_0_0.IMG_CURRENCY):removeAllChildren()

		if xyd.isInTable(xyd.tables.misc.houseKeyBlueId, arg_30_0.itemID) then
			arg_30_0.unitPrice = xyd.tables.misc.houseKeyBlue
		else
			arg_30_0.unitPrice = xyd.tables.misc.houseKeyGreen
		end

		local var_30_14 = xyd.AssetLoader:get():loadSprite("windows/dorm/expand/cement.png")

		var_30_14:setScale(0.5)
		xyd.displaySpriteOnContainer(var_30_14, arg_30_0:nodeByName(var_0_0.IMG_CURRENCY), false)
		arg_30_0:nodeByName(var_0_0.PRICE):setString(xyd.tables.inscription:resolveNum(inscriptId))
		arg_30_0:nodeByName(var_0_0.PRICE):setString(arg_30_0.unitPrice)
	else
		arg_30_0:nodeByName("txt_sell"):setVisible(true)
		arg_30_0:nodeByName("decompose_text"):setVisible(false)
	end

	arg_30_0.panelAttr_:removeAllChildren()

	if var_30_0 == xyd.ItemType.EQUIPMENT or var_30_0 == xyd.ItemType.PET_EQUIP or var_30_0 == xyd.ItemType.INSCRIPTION then
		local var_30_15 = var_0_20:attrs(arg_30_1)
		local var_30_16 = {}

		if var_30_15[1] and var_30_15[2] and var_30_15[3] and var_30_15[1] == var_30_15[2] and var_30_15[2] == var_30_15[3] then
			local var_30_17 = {
				name = var_0_18:name(1) .. "," .. var_0_18:name(2) .. "," .. var_0_18:name(3),
				value = var_30_15[1]
			}

			table.insert(var_30_16, var_30_17)

			for iter_30_0, iter_30_1 in pairs(var_30_15) do
				if iter_30_0 > 3 then
					local var_30_18 = {
						name = var_0_18:name(iter_30_0),
						value = iter_30_1
					}

					table.insert(var_30_16, var_30_18)
				end
			end
		else
			for iter_30_2, iter_30_3 in pairs(var_30_15) do
				local var_30_19 = {
					name = var_0_18:name(iter_30_2),
					value = iter_30_3
				}

				table.insert(var_30_16, var_30_19)
			end
		end

		if var_30_0 == xyd.ItemType.INSCRIPTION then
			var_30_16 = {}

			local var_30_20
			local var_30_21
			local var_30_22
			local var_30_23 = {}
			local var_30_24, var_30_25, var_30_26 = arg_30_0.inscription_:getInscriptionAttrLabelText(arg_30_1)

			var_30_23.suffix, var_30_23.value, var_30_23.name = var_30_26, var_30_25, var_30_24

			table.insert(var_30_16, var_30_23)

			if var_0_20:inscriptSuitId(arg_30_1) ~= 0 then
				local var_30_27 = {
					name = xyd.tables.inscriptionSuit:name(var_0_20:inscriptSuitId(arg_30_1))
				}

				var_30_27.value = nil
				var_30_27.color = cc.c4b(160, 28, 28, 255)

				table.insert(var_30_16, var_30_27)

				local var_30_28 = {
					name = var_0_18:name(xyd.tables.inscriptionSuit:attr(var_0_20:inscriptSuitId(arg_30_1))[1]),
					value = xyd.tables.inscriptionSuit:attr_num(var_0_20:inscriptSuitId(arg_30_1))[1]
				}

				table.insert(var_30_16, var_30_28)
			end
		end

		arg_30_0:nodeByName("desc_bg"):height((#var_30_16 + 1) * var_0_19)
		arg_30_0:nodeByName("desc2_txt"):y(arg_30_0:nodeByName("desc_bg"):getY() - arg_30_0:nodeByName("desc_bg"):getHeight() - 10)
		arg_30_0:createLabels(var_30_16)
		arg_30_0:nodeByName(var_0_0.DESC1_TXT):setVisible(false)
	elseif var_30_0 == xyd.ItemType.STONE then
		local var_30_29 = var_0_20:heroID(arg_30_1)
		local var_30_30 = xyd.tables.hero:name(var_30_29)
		local var_30_31 = xyd.tables.hero:initialStar(var_30_29)
		local var_30_32 = var_0_23[var_30_31]
		local var_30_33

		if xyd.isSuperHero(var_30_29) then
			var_30_33 = string.format(xyd.tables.translation:translation("BACKPACK_SUPER_STONE_DESC"), var_30_30)
		else
			var_30_33 = string.format(xyd.tables.translation:translation("BACKPACK_STONE_DESC"), var_30_32, var_30_30, var_30_30)
		end

		arg_30_0:nodeByName(var_0_0.DESC1_TXT):setString(var_30_33)
		arg_30_0:nodeByName(var_0_0.DESC1_TXT):setVisible(true)
		arg_30_0:nodeByName("desc_bg"):height(110)
		arg_30_0:nodeByName("desc2_txt"):y(arg_30_0:nodeByName("desc_bg"):getY() - arg_30_0:nodeByName("desc_bg"):getHeight() - 10)
	elseif var_30_0 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_30_0 == xyd.ItemType.REEL_FRAGMENT or var_30_0 == xyd.ItemType.BOOK_FRAGMENT then
		local var_30_34 = var_0_20:itemNum(arg_30_1)
		local var_30_35 = var_0_20:composeItem(arg_30_1)
		local var_30_36 = var_0_20:name(var_30_35)
		local var_30_37 = string.format(var_0_17:translation("FRAGMENT_DESC1"), var_30_34, var_30_36)
		local var_30_38 = string.format(var_0_17:translation("FRAGMENT_DESC2"), var_30_6, var_30_34)

		arg_30_0:createStrLabel(var_30_37, var_30_38)
		arg_30_0:nodeByName(var_0_0.DESC1_TXT):setVisible(false)
		arg_30_0:nodeByName("desc_bg"):height(110)
		arg_30_0:nodeByName("desc2_txt"):y(arg_30_0:nodeByName("desc_bg"):getY() - arg_30_0:nodeByName("desc_bg"):getHeight())
	elseif var_30_0 == xyd.ItemType.CONSUMABLES then
		arg_30_0:createDescLabel(var_30_4)
		arg_30_0:nodeByName(var_0_0.DESC1_TXT):setVisible(false)

		if arg_30_0.descHeight >= 110 then
			arg_30_0:nodeByName("desc_bg"):height(arg_30_0.descHeight + 20)
		else
			arg_30_0:nodeByName("desc_bg"):height(110)
		end

		arg_30_0:nodeByName("desc2_txt"):y(arg_30_0:nodeByName("desc_bg"):getY() - arg_30_0:nodeByName("desc_bg"):getHeight())
	else
		arg_30_0:nodeByName(var_0_0.DESC1_TXT):setString(var_30_4)
		arg_30_0:nodeByName(var_0_0.DESC1_TXT):setVisible(true)
		arg_30_0:nodeByName("desc_bg"):height(110)
		arg_30_0:nodeByName("desc2_txt"):y(arg_30_0:nodeByName("desc_bg"):getY() - arg_30_0:nodeByName("desc_bg"):getHeight() - 10)
	end

	arg_30_0:nodeByName(var_0_0.DESC2_TXT):setString(var_30_5)
	arg_30_0:nodeByName(var_0_0.DESC2_TXT):setVisible(true)

	if arg_30_0:isDetailItem() then
		arg_30_0:nodeByName("detail_txt"):setString(var_0_17:translation("BACKPACK_TEXT_1"))
	elseif var_30_0 == xyd.ItemType.REEL_FRAGMENT or var_30_0 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_30_0 == xyd.ItemType.BOOK_FRAGMENT then
		arg_30_0:nodeByName("detail_txt"):setString(var_0_17:translation("BACKPACK_TEXT_2"))
	elseif arg_30_0:isExchangeItem() or arg_30_0:isChristmasAward() then
		arg_30_0:nodeByName("detail_txt"):setString(var_0_17:translation("BACKPACK_TEXT_3"))
	else
		arg_30_0:nodeByName("detail_txt"):setString(var_0_17:translation("BACKPACK_TEXT_4"))
	end
end

function var_0_0.isDetailItem(arg_31_0)
	if arg_31_0:isExpItem() then
		return true
	end

	local var_31_0 = var_0_20:type(arg_31_0.itemID)
	local var_31_1 = var_0_20:subType(arg_31_0.itemID)

	if arg_31_0.itemID == xyd.tables.misc.awakeItem then
		return false
	end

	if var_31_0 == xyd.ItemType.CONSUMABLES and (var_31_1 == 13 or var_31_1 == 7) then
		return true
	end

	if var_31_0 == xyd.ItemType.EQUIPMENT or var_31_0 == xyd.ItemType.REEL or var_31_0 == xyd.ItemType.STONE or var_31_0 == xyd.ItemType.INSCRIPTION or arg_31_0.itemID == xyd.tables.misc.skyCitySuperPaper or arg_31_0:isFumoItem() or arg_31_0:isSweepItem() or arg_31_0:isManaItem() or arg_31_0:isShowDetailItem() or arg_31_0:isPetItem() or arg_31_0:isInscriptionMaterialItem() or arg_31_0:isOccultExpItem() then
		return true
	else
		return false
	end
end

function var_0_0.isCanResolveRoomKey(arg_32_0, arg_32_1)
	return xyd.isInTable(xyd.tables.misc.houseKeyBlueId, arg_32_1) or xyd.isInTable(xyd.tables.misc.housekeyGreenId, arg_32_1)
end

function var_0_0.updateItems(arg_33_0)
	arg_33_0:updateItemDetail(arg_33_0.itemID)
	arg_33_0:refreshDisplayOption()
end

function var_0_0.createStrLabel(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = {
		size = 22,
		color = cc.c3b(54, 90, 84)
	}
	local var_34_1 = xyd.AssetLoader:get():loadLabel(var_34_0)

	var_34_1:setMaxLineWidth(310)
	var_34_1:setString(arg_34_1)
	var_34_1:y(90)
	var_34_1:setAnchorPoint(cc.p(0, 1))
	var_34_1:addTo(arg_34_0.panelAttr_)

	local var_34_2 = {
		size = 22,
		color = cc.c3b(54, 90, 84)
	}
	local var_34_3 = xyd.AssetLoader:get():loadLabel(var_34_2)

	var_34_3:setString(arg_34_2)
	var_34_3:setAnchorPoint(cc.p(0, 1))
	var_34_3:y(30)
	var_34_3:addTo(arg_34_0.panelAttr_)
end

function var_0_0.createDescLabel(arg_35_0, arg_35_1)
	local var_35_0 = {
		size = 22,
		color = cc.c3b(54, 90, 84)
	}
	local var_35_1 = xyd.AssetLoader:get():loadLabel(var_35_0)

	var_35_1:setMaxLineWidth(310)
	var_35_1:setString(arg_35_1)
	var_35_1:y(90)

	arg_35_0.descHeight = var_35_1:getContentSize().height

	var_35_1:setAnchorPoint(cc.p(0, 1))
	var_35_1:addTo(arg_35_0.panelAttr_)
end

function var_0_0.createLabels(arg_36_0, arg_36_1)
	local var_36_0 = arg_36_0.panelAttr_:getContentSize().height

	for iter_36_0, iter_36_1 in ipairs(arg_36_1) do
		local var_36_1 = {
			size = 22,
			color = cc.c3b(54, 90, 84)
		}
		local var_36_2 = xyd.AssetLoader:get():loadLabel(var_36_1)
		local var_36_3 = ""

		if iter_36_1.value then
			var_36_3 = iter_36_1.value < 0 and "" or "+"
		end

		if iter_36_1.value then
			var_36_2:setString(iter_36_1.name .. var_36_3 .. iter_36_1.value .. (iter_36_1.suffix or ""))
		else
			var_36_2:setString(iter_36_1.name)
		end

		if not iter_36_1.value then
			var_36_2:setString(iter_36_1.name)
		end

		if iter_36_1.color then
			var_36_2:setColor(iter_36_1.color)
		end

		var_36_2:y(var_36_0 - (iter_36_0 - 1) * var_0_19)
		var_36_2:setAnchorPoint(cc.p(0, 1))
		var_36_2:addTo(arg_36_0.panelAttr_)
	end
end

function var_0_0.useAwakeItem(arg_37_0)
	local var_37_0 = arg_37_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)

	if var_37_0 then
		local var_37_1 = xyd.tables.mission:awakeMaterial(var_37_0)
		local var_37_2 = xyd.tables.mission:items(var_37_0)

		for iter_37_0, iter_37_1 in pairs(xyd.tables.misc.awakeItemWishNots) do
			if var_37_1 == iter_37_1 then
				break
			end
		end

		if var_37_2 == 0 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_17:translation("AWAKEN_HERO_NOT_NEED")
			})
		else
			local function var_37_3()
				local var_38_0 = {}

				var_38_0.item_num = 1

				xyd.Backend.get():request(xyd.mid.GET_AWAKE_ITEM, var_38_0, function(arg_39_0, arg_39_1)
					if arg_39_0 == xyd.error.OK then
						arg_37_0.backpack_:removeItem({
							itemNum = 1,
							itemID = arg_37_0.itemID
						})

						local var_39_0 = {
							table_id = arg_39_1.item_id,
							item_num = arg_39_1.item_num
						}

						arg_37_0.backpack_:addItemsByID(arg_39_1.item_id, arg_39_1.item_num)
						arg_37_0:updateItems()
						xyd.WindowManager.get():openWindow("alert_award", {
							awards = {
								var_39_0
							}
						})
					end
				end)
			end

			local var_37_4 = {
				rcallBefore = 0,
				title = var_0_17:translation("TIP"),
				txt = var_0_17:translation("GET_AWAKEN_ITEM_NOW"),
				rcallback = function(arg_40_0)
					if arg_40_0.name == "ended" then
						if arg_37_0.player_:getBackpack():getItemNumByID(var_37_2) > 0 or arg_37_0.player_:getBackpack():getItemNumByID(var_37_1) > 0 then
							local var_40_0 = {
								title = var_0_17:translation("TIP"),
								txt = var_0_17:translation("ALREADY_GET_AWAKEN_ITEM"),
								rcallback = function(arg_41_0)
									if arg_41_0.name == "ended" then
										var_37_3()
									end
								end
							}

							xyd.WindowManager.get():openWindow("alert_green", var_40_0)
						else
							var_37_3()
						end
					end
				end
			}

			xyd.WindowManager.get():openWindow("alert_green", var_37_4)
		end
	else
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_17:translation("NO_AWAKING_HERO")
		})
	end
end

function var_0_0.didOpen(arg_42_0)
	arg_42_0:nodeByName(var_0_0.SELL_BUTTON):addTouchEventListener(function(arg_43_0, arg_43_1)
		xyd.buttonScaleAnim(arg_42_0:nodeByName(var_0_0.SELL_BUTTON), arg_43_1)

		if arg_43_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("sell_detail", {
				itemID = arg_42_0.itemID
			})
		end
	end)
	arg_42_0:nodeByName(var_0_0.MAKE_BUTTON):addTouchEventListener(function(arg_44_0, arg_44_1)
		xyd.buttonScaleAnim(arg_42_0:nodeByName(var_0_0.MAKE_BUTTON), arg_44_1)

		if arg_44_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_44_0 = var_0_20:type(arg_42_0.itemID)

			if arg_42_0:isDetailItem() then
				xyd.WindowManager.get():openWindow("backpack_item_detail_window", {
					itemID = arg_42_0.itemID
				})
			elseif arg_42_0.itemID == xyd.tables.misc.awakeItem then
				arg_42_0:useAwakeItem()
			elseif arg_42_0:isTiliItem() then
				if xyd.tables.misc.energyMaxLimit < arg_42_0.player_.energy and arg_42_0.flag == true then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_17:translation("TILI_LIMIT_INFO")
					})
				else
					local var_44_1 = {
						item_id = arg_42_0.itemID,
						item_type = xyd.ConsumeItemType.ENERGY_ITEM
					}

					xyd.WindowManager.get():openWindow("giftbag_use", var_44_1)
				end
			elseif var_44_0 == xyd.ItemType.REEL_FRAGMENT or var_44_0 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_44_0 == xyd.ItemType.BOOK_FRAGMENT then
				xyd.WindowManager.get():openWindow("fragment_make", {
					itemID = arg_42_0.itemID
				})
			elseif arg_42_0:isSummonItem() > 0 then
				arg_42_0:summonHero(arg_42_0:isSummonItem())
			elseif arg_42_0:isExchangeItem() then
				arg_42_0:exchangeItem()
			elseif arg_42_0:isChristmasAward() then
				arg_42_0:getChristmasAward()
			elseif arg_42_0:isDiscountCard() > 0 then
				if arg_42_0:isDiscountCard() == 1 then
					if xyd.tables.summon:crystal(10) > arg_42_0.player_.crystal then
						local function var_44_2()
							local var_45_0 = {}

							var_45_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_45_0)
						end

						local var_44_3 = {
							rcallBefore = 0,
							title = var_0_17:translation("TIP"),
							txt = var_0_17:translation("ZUANSHI_ABSENCE"),
							rcallback = var_44_2
						}

						xyd.WindowManager.get():openWindow("alert_green", var_44_3)
					else
						local function var_44_4()
							arg_42_0:summonDiscountHero(arg_42_0:isDiscountCard())
						end

						local var_44_5 = {
							rcallBefore = 0,
							title = var_0_17:translation("TIP"),
							txt = var_0_17:translation("LOW_DISCOUNT"),
							rcallback = var_44_4
						}

						xyd.WindowManager.get():openWindow("alert_green", var_44_5)
					end
				elseif xyd.tables.summon:crystal(11) > arg_42_0.player_.crystal then
					local function var_44_6()
						local var_47_0 = {}

						var_47_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_47_0)
					end

					local var_44_7 = {
						rcallBefore = 0,
						title = var_0_17:translation("TIP"),
						txt = var_0_17:translation("ZUANSHI_ABSENCE"),
						rcallback = var_44_6
					}

					xyd.WindowManager.get():openWindow("alert_green", var_44_7)
				else
					local function var_44_8()
						arg_42_0:summonDiscountHero(arg_42_0:isDiscountCard())
					end

					local var_44_9 = {
						rcallBefore = 0,
						title = var_0_17:translation("TIP"),
						txt = var_0_17:translation("HIGH_DISCOUNT"),
						rcallback = var_44_8
					}

					xyd.WindowManager.get():openWindow("alert_green", var_44_9)
				end
			elseif arg_42_0:isSkinItem() then
				local var_44_10 = var_0_20:skinPartner(arg_42_0.itemID)
				local var_44_11 = arg_42_0.player_:getHeroIgnoreAwaken(var_44_10)
				local var_44_12 = false

				if var_44_11 then
					local var_44_13 = var_44_11.skinIds_

					for iter_44_0 = 1, #var_44_13 do
						if var_44_13[iter_44_0] == var_0_20:skinModel(arg_42_0.itemID) then
							var_44_12 = true
						end
					end
				end

				if var_44_11 and not var_44_12 then
					local var_44_14 = {
						partner_id = var_44_11:getHeroID(),
						item_id = arg_42_0.itemID
					}

					xyd.Backend.get():request(xyd.mid.SKIN_ON, var_44_14, function(arg_49_0, arg_49_1)
						if arg_49_0 == xyd.error.OK then
							var_44_11:setSkinInfo(arg_49_1.current_skin_id, arg_49_1.skin_ids)

							if arg_49_1.remove_item == 1 then
								local var_49_0 = {
									itemID = arg_42_0.itemID
								}

								var_49_0.itemNum = 1

								arg_42_0.backpack_:removeItem(var_49_0)
								arg_42_0:updateItems()

								local var_49_1 = xyd.tables.skinSkill:getSkillID(arg_42_0.itemID)

								if var_49_1 and var_49_1 > 0 then
									xyd.db.skinSkillRedMark:updateSkinSkillRedMark(arg_42_0.player_.playerID, var_44_11:getHeroID(), 1)
								end
							end

							if arg_49_1.server_time then
								xyd.ServerTime.get():resetServerTime(arg_49_1.server_time)
							end
						end
					end)
				elseif var_44_11 == nil then
					local var_44_15 = var_0_17:translation("SKIN_NO_PARTNER")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_44_15
					})
				elseif var_44_12 then
					local var_44_16 = var_0_17:translation("ACTIVITY_SKIN_ALREADYHAVA")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_44_16
					})
				end
			elseif arg_42_0:isPetHomeStyleItem() then
				local var_44_17 = var_0_20:stylePet(arg_42_0.itemID)
				local var_44_18 = arg_42_0.player_:getPetIgnoreAwaken(var_44_17)

				if var_44_18 and not var_44_18:checkHomeStyleIsUsed(arg_42_0.itemID) then
					local var_44_19 = {
						item_id = arg_42_0.itemID
					}

					xyd.Backend.get():request(xyd.mid.GET_PET_STYLE_FORM_ITEM, var_44_19, function(arg_50_0, arg_50_1)
						if arg_50_0 == xyd.error.OK then
							var_44_18:setHomeSkinID(arg_50_1.active_style)
							var_44_18:setHomeStyles(arg_50_1.pet_styles)

							local var_50_0 = {
								itemID = arg_42_0.itemID
							}

							var_50_0.itemNum = 1

							arg_42_0.backpack_:removeItem(var_50_0)
							arg_42_0:updateItems()
						end
					end)
				elseif var_44_18 == nil then
					local var_44_20 = var_0_17:translation("HOME_STYLE_NO_PARTNER")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_44_20
					})
				elseif var_44_18:checkHomeStyleIsUsed(arg_42_0.itemID) then
					local var_44_21 = var_0_17:translation("HOME_STYLE_ALREADYHAVA")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_44_21
					})
				end
			elseif arg_42_0.itemID == var_0_6 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_FINISHED")
				})
			elseif arg_42_0.itemID == 50001188 or arg_42_0.itemID == 50001304 or arg_42_0.itemID == 50001310 or arg_42_0.itemID == 50001335 or arg_42_0.itemID == 50001342 or arg_42_0.itemID == 50001495 or arg_42_0.itemID == 50001502 or arg_42_0.itemID == 50009004 then
				local var_44_22 = {
					itemID = arg_42_0.itemID
				}

				xyd.WindowManager.get():openWindow("select_sx", var_44_22)
			elseif arg_42_0:isGiftItem() then
				local var_44_23 = var_0_20:level(arg_42_0.itemID)

				if var_44_23 <= arg_42_0.player_.lev then
					local var_44_24 = {
						itemID = arg_42_0.itemID
					}

					xyd.WindowManager.get():openWindow("exchage_code_hero", var_44_24, callback)
				else
					local var_44_25 = string.format(var_0_17:translation("EXCHANGE_CODE_ITEM_TIP"), var_44_23)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_44_25
					})
				end
			elseif arg_42_0:isOpenGiftPakage() then
				local var_44_26 = var_0_20:gifts(arg_42_0.itemID)[1]

				arg_42_0:openGiftPakage(arg_42_0.itemID, var_44_26)
			elseif arg_42_0:isKiteItem() then
				if xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):isActivityOpen(xyd.RedEnvelope.KITE_ID) then
					xyd.WindowManager.get():openWindow("kite")
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_17:translation("ACTIVITY_END")
					})
				end
			elseif arg_42_0:isMagicItem() then
				local var_44_27 = {}

				var_44_27[#var_44_27 + 1] = {
					item_num = 1,
					item_id = arg_42_0.itemID
				}

				arg_42_0.player_:useMagicItems({
					items = var_44_27
				}, function(arg_51_0, arg_51_1)
					if arg_51_0 == xyd.error.OK then
						arg_42_0:updateItems()
					end
				end)
			elseif arg_42_0:isSkillPointItem() then
				local var_44_28 = {
					item_id = arg_42_0.itemID,
					item_type = xyd.ConsumeItemType.SKILL_POINT
				}

				xyd.WindowManager.get():openWindow("giftbag_use", var_44_28)
			elseif arg_42_0:isFavorItem() then
				xyd.WindowManager.get():openWindow("tujian_hero", {
					hero_show_type = 8
				})
			elseif var_0_20:subType(arg_42_0.itemID) == xyd.ConsumeItemType.OPEN_ACTIVITY then
				xyd.WindowManager.get():openWindow("open_activity_item", {
					itemId = arg_42_0.itemID
				})
			end
		end
	end)
	arg_42_0:nodeByName(var_0_0.SORT_BOTTON):addTouchEventListener(function(arg_52_0, arg_52_1)
		xyd.buttonScaleAnim(arg_42_0:nodeByName(var_0_0.SORT_BOTTON), arg_52_1)

		if arg_52_1 == ccui.TouchEventType.ended then
			local var_52_0 = {
				filterType = arg_42_0.filterType,
				filterOrder = arg_42_0.filterOrder
			}

			xyd.WindowManager.get():openWindow("backpack_sort", var_52_0)
		end
	end)
	arg_42_0.inscription_:handleExchangeMaterials()
end

function var_0_0.isKiteItem(arg_53_0)
	for iter_53_0, iter_53_1 in ipairs(var_0_8) do
		if arg_53_0.itemID == iter_53_1 then
			return true
		end
	end

	return false
end

function var_0_0.openGiftPakage(arg_54_0, arg_54_1, arg_54_2)
	if not arg_54_1 or not arg_54_2 then
		return
	end

	local var_54_0 = {
		item_id = arg_54_1,
		gift_id = arg_54_2
	}

	xyd.WindowManager.get():openWindow("giftbag_use", var_54_0)
end

function var_0_0.exchangeItem(arg_55_0)
	local var_55_0 = import("app.model.Item").new()

	var_55_0:populate({
		table_id = arg_55_0.itemID
	})
	xyd.WindowManager.get():openWindow("exchange_item", {
		item = var_55_0
	})
end

function var_0_0.getChristmasAward(arg_56_0)
	local var_56_0 = xyd.tables.christmasGift
	local var_56_1 = xyd.Activities.Christmas

	arg_56_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

	local function var_56_2()
		for iter_57_0 = 1, var_56_0:totalGiftCount() do
			if table.nums(var_56_0:items(iter_57_0)) == 1 and var_56_0:items(iter_57_0)[1] == arg_56_0.itemID then
				arg_56_0.activitiesModel:getActivityReward(var_56_1, iter_57_0, function(arg_58_0, arg_58_1)
					if arg_58_0 == xyd.error.OK then
						arg_56_0.backpack_:removeItem({
							itemNum = 1,
							itemID = arg_56_0.itemID
						})

						if arg_58_1.awards and next(arg_58_1.awards) then
							for iter_58_0, iter_58_1 in ipairs(arg_58_1.awards) do
								if iter_58_1.table_id > 0 and iter_58_1.item_num > 0 then
									arg_56_0.backpack_:addItemsByID(iter_58_1.table_id, iter_58_1.item_num)
								end
							end

							arg_56_0:updateItems()
							xyd.WindowManager.get():openWindow("alert_award", {
								awards = arg_58_1.awards
							})
						end
					end
				end)

				break
			end
		end
	end

	local var_56_3 = {
		rcallBefore = 0,
		title = var_0_17:translation("TIP"),
		txt = string.format(var_0_17:translation("EXCHANGE_CHRISTMAS_ITEM"), var_0_20:name(arg_56_0.itemID), var_0_20:name(var_0_7[2]), var_0_20:name(var_0_7[4]), var_0_20:name(var_0_7[1]), var_0_20:name(var_0_7[3])),
		rcallback = var_56_2
	}

	xyd.WindowManager.get():openWindow("alert_green", var_56_3)
end

function var_0_0.summonHero(arg_59_0, arg_59_1)
	local var_59_0 = {
		summon_index = xyd.SummonType.CouponTypeOne
	}

	if arg_59_1 == 1 then
		var_59_0.summon_type = xyd.SummonType.CouponType1
	elseif arg_59_1 > 1 then
		var_59_0.summon_type = xyd.SummonType.CouponType2
	end

	local var_59_1 = var_59_0.summon_type

	local function var_59_2(arg_60_0, arg_60_1)
		if arg_60_0 ~= xyd.error.OK then
			return
		end

		local var_60_0 = {}
		local var_60_1 = {}

		for iter_60_0, iter_60_1 in pairs(arg_60_1.result) do
			if tonumber(iter_60_0) then
				table.insert(var_60_1, iter_60_1)
			end
		end

		var_60_0.items = var_60_1
		var_60_0.reward = arg_60_1.reward
		var_60_0.lastType = var_59_1
		var_60_0.extraAward = arg_60_1.items
		var_60_0.extraReward = arg_60_1.extra_reward
		var_60_0.sakuraItems = arg_60_1.sakura_items
		var_60_0.stick_items = arg_60_1.stick_items

		arg_59_0.backpack_:removeItem({
			itemNum = 1,
			itemID = arg_59_0.itemID
		})
		xyd.WindowManager.get():openWindow(xyd.WindowName.summonResultWnd, var_60_0)
		arg_59_0:updateItems()
	end

	arg_59_0.player_:summonHero(var_59_0, var_59_2)
end

function var_0_0.summonDiscountHero(arg_61_0, arg_61_1)
	local var_61_0 = {
		summon_index = xyd.SummonType.CrystalDiscountIndex
	}

	if arg_61_1 == 1 then
		var_61_0.summon_type = xyd.SummonType.CrystalDiscountOne
	elseif arg_61_1 == 10 then
		var_61_0.summon_type = xyd.SummonType.CrystalDiscountTen
	end

	local var_61_1 = var_61_0.summon_type

	local function var_61_2(arg_62_0, arg_62_1)
		if arg_62_0 ~= xyd.error.OK then
			return
		end

		local var_62_0 = {}
		local var_62_1 = {}

		for iter_62_0, iter_62_1 in pairs(arg_62_1.result) do
			if tonumber(iter_62_0) then
				table.insert(var_62_1, iter_62_1)
			end
		end

		var_62_0.items = var_62_1
		var_62_0.reward = arg_62_1.reward
		var_62_0.lastType = var_61_1
		var_62_0.extraAward = arg_62_1.items
		var_62_0.extraReward = arg_62_1.extra_reward
		var_62_0.sakuraItems = arg_62_1.sakura_items
		var_62_0.stick_items = arg_62_1.stick_items

		arg_61_0.backpack_:removeItem({
			itemNum = 1,
			itemID = arg_61_0.itemID
		})
		xyd.WindowManager.get():openWindow(xyd.WindowName.summonResultWnd, var_62_0)
		arg_61_0:updateItems()
	end

	arg_61_0.player_:summonHero(var_61_0, var_61_2)
end

function var_0_0.isExpItem(arg_63_0)
	if var_0_20:exp(arg_63_0.itemID) > 0 then
		return true
	end

	return false
end

function var_0_0.isSweepItem(arg_64_0)
	return arg_64_0.itemID == 50001013
end

function var_0_0.isShowDetailItem(arg_65_0)
	if arg_65_0.itemID == 50001056 or arg_65_0.itemID == 50001057 then
		return true
	else
		return false
	end
end

function var_0_0.isManaItem(arg_66_0)
	return var_0_20:subType(arg_66_0.itemID) == xyd.ConsumeItemType.MANA_ITEM
end

function var_0_0.isGiftItem(arg_67_0)
	return var_0_20:gifts(arg_67_0.itemID) and next(var_0_20:gifts(arg_67_0.itemID)) and not arg_67_0:isOpenGiftPakage()
end

function var_0_0.isMagicItem(arg_68_0)
	if var_0_20:subType(arg_68_0.itemID) == xyd.ConsumeItemType.ACTIVITY_CENTER_ITEM then
		return true
	else
		return false
	end
end

function var_0_0.isSkillPointItem(arg_69_0)
	if xyd.tables.item:subType(arg_69_0.itemID) == xyd.ConsumeItemType.SKILL_POINT then
		return true
	else
		return false
	end
end

function var_0_0.isFumoItem(arg_70_0)
	local var_70_0 = var_0_20:moneng(arg_70_0.itemID)
	local var_70_1 = var_0_20:type(arg_70_0.itemID)

	if var_70_0 ~= nil and var_70_0 > 0 and var_70_1 == xyd.ItemType.CONSUMABLES then
		return true
	end

	return false
end

function var_0_0.isTiliItem(arg_71_0)
	return var_0_20:energy(arg_71_0.itemID) > 0
end

function var_0_0.isSummonItem(arg_72_0)
	if arg_72_0.itemID == var_0_2 then
		return 1
	end

	if arg_72_0.itemID == var_0_3 then
		return 10
	end

	return -1
end

function var_0_0.isChristmasAward(arg_73_0)
	for iter_73_0, iter_73_1 in ipairs(var_0_7) do
		if arg_73_0.itemID == iter_73_1 then
			return true
		end
	end

	return false
end

function var_0_0.isSkinItem(arg_74_0)
	if var_0_20:skinPartner(arg_74_0.itemID) == 0 then
		return false
	else
		return true
	end
end

function var_0_0.isPetHomeStyleItem(arg_75_0)
	if var_0_20:stylePet(arg_75_0.itemID) ~= 0 and var_0_20:subType(arg_75_0.itemID) == xyd.ConsumeItemType.PET_HOME_STYLE then
		return true
	end

	return false
end

function var_0_0.isPetItem(arg_76_0)
	local var_76_0 = false

	if var_0_20:subType(arg_76_0.itemID) == xyd.ConsumeItemType.PET_ITEM or var_0_20:subType(arg_76_0.itemID) == xyd.ConsumeItemType.PET_DRINK_ITEM or var_0_20:type(arg_76_0.itemID) == xyd.ItemType.PET_STONE or var_0_20:type(arg_76_0.itemID) == xyd.ItemType.PET_EQUIP then
		var_76_0 = true
	elseif arg_76_0.itemID == xyd.tables.misc.skillBookItem then
		var_76_0 = true
	end

	return var_76_0
end

function var_0_0.isInscriptionMaterialItem(arg_77_0)
	return arg_77_0.itemID == xyd.tables.misc.speacialItemID
end

function var_0_0.isFavorItem(arg_78_0)
	return var_0_20:subType(arg_78_0.itemID) == xyd.ConsumeItemType.LOVE_ITEM
end

function var_0_0.isExchangeItem(arg_79_0)
	return next(var_0_20:canExchangeItem(arg_79_0.itemID)) ~= nil and var_0_20:canExchangeItem(arg_79_0.itemID)[1] > 0
end

function var_0_0.isOccultExpItem(arg_80_0)
	return xyd.isInTable(xyd.tables.misc.objectBoxBooks, arg_80_0.itemID)
end

function var_0_0.isDiscountCard(arg_81_0)
	if arg_81_0.itemID == var_0_4 then
		return 1
	elseif arg_81_0.itemID == var_0_5 then
		return 10
	end

	return -1
end

function var_0_0.isOpenGiftPakage(arg_82_0)
	if #var_0_20:gifts(arg_82_0.itemID) > 0 and #var_0_20:chooseGift(arg_82_0.itemID) == 0 then
		return true
	else
		return false
	end
end

function var_0_0.refreshDisplayOption(arg_83_0, arg_83_1)
	for iter_83_0 = 1, #arg_83_0.optionButtons_ do
		arg_83_0.list_[var_0_24[iter_83_0]] = arg_83_0.player_:getBackpack():getItemsByTypes(var_0_21[iter_83_0])

		if iter_83_0 == arg_83_0.displayOption then
			arg_83_0.optionButtons_[iter_83_0]:setBrightStyle(ccui.BrightStyle.highlight)
			arg_83_0.optionButtons_[iter_83_0]:setLocalZOrder(100)

			if arg_83_1 == nil then
				arg_83_0.filterType = arg_83_0.filterType or math.ceil((arg_83_0.player_.backpack_sort_type + 1) / 2)
				arg_83_0.filterOrder = arg_83_0.player_.backpack_sort_type % 2 == 0

				arg_83_0:updateFilter()
			end
		else
			arg_83_0.optionButtons_[iter_83_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_83_0.optionButtons_[iter_83_0]:setLocalZOrder(0)
			arg_83_0.listView_[var_0_24[iter_83_0]]:setLocalZOrder(1)
			arg_83_0.listView_[var_0_24[iter_83_0]]:removeAllItems()
		end

		arg_83_0.optionTxts_[iter_83_0]:setLocalZOrder(101)
	end

	arg_83_0:nodeByName("bg"):setLocalZOrder(1)
end

function var_0_0.updateFilter(arg_84_0)
	local var_84_0 = arg_84_0.displayOption

	arg_84_0:filterSort(var_84_0)

	local var_84_1 = arg_84_0.listView_[var_0_24[var_84_0]].scrollNode:getPositionY()

	arg_84_0.listView_[var_0_24[var_84_0]]:setLocalZOrder(99)
	arg_84_0.listView_[var_0_24[var_84_0]]:removeAllItems()
	arg_84_0.listView_[var_0_24[var_84_0]]:reload()

	if var_84_1 > 0 then
		if var_84_1 > var_0_9 * math.ceil(#arg_84_0.list_[var_0_24[var_84_0]] / var_0_13) and var_84_1 > arg_84_0.listView_[var_0_24[var_84_0]]:getViewRectInWorldSpace().height + 2 then
			var_84_1 = var_0_9 * math.ceil(#arg_84_0.list_[var_0_24[var_84_0]] / var_0_13)
		end

		arg_84_0.listView_[var_0_24[var_84_0]].scrollNode:setPosition(0, var_84_1)
	end
end

function var_0_0.filterSort(arg_85_0, arg_85_1)
	if arg_85_0.filterType == xyd.BackPackFilterType.DEFAULT then
		table.sort(arg_85_0.list_[var_0_24[arg_85_1]], function(arg_86_0, arg_86_1)
			if arg_85_0.filterOrder then
				return arg_86_0.itemID > arg_86_1.itemID
			else
				return arg_86_0.itemID < arg_86_1.itemID
			end
		end)
	elseif arg_85_0.filterType == xyd.BackPackFilterType.QUALITY then
		table.sort(arg_85_0.list_[var_0_24[arg_85_1]], function(arg_87_0, arg_87_1)
			if arg_85_0.filterOrder then
				return arg_87_0.itemQuality > arg_87_1.itemQuality
			else
				return arg_87_0.itemQuality < arg_87_1.itemQuality
			end
		end)
	elseif arg_85_0.filterType == xyd.BackPackFilterType.NUM then
		table.sort(arg_85_0.list_[var_0_24[arg_85_1]], function(arg_88_0, arg_88_1)
			if arg_85_0.filterOrder then
				return arg_88_0.itemNum > arg_88_1.itemNum
			else
				return arg_88_0.itemNum < arg_88_1.itemNum
			end
		end)
	elseif arg_85_0.filterType == xyd.BackPackFilterType.LEVEL then
		table.sort(arg_85_0.list_[var_0_24[arg_85_1]], function(arg_89_0, arg_89_1)
			if arg_85_0.filterOrder then
				return var_0_20:level(arg_89_0.itemID) > var_0_20:level(arg_89_1.itemID)
			else
				return var_0_20:level(arg_89_0.itemID) < var_0_20:level(arg_89_1.itemID)
			end
		end)
	elseif arg_85_0.filterType == xyd.BackPackFilterType.TIME then
		table.sort(arg_85_0.list_[var_0_24[arg_85_1]], function(arg_90_0, arg_90_1)
			if arg_85_0.filterOrder then
				return arg_90_0.itemTime > arg_90_1.itemTime
			else
				return arg_90_0.itemTime < arg_90_1.itemTime
			end
		end)
	end
end

function var_0_0.refreshDisplayOptionAfterSell(arg_91_0)
	for iter_91_0 = 1, #arg_91_0.optionButtons_ do
		arg_91_0.list_[var_0_24[iter_91_0]] = arg_91_0.player_:getBackpack():getItemsByTypes(var_0_21[iter_91_0])

		if iter_91_0 == arg_91_0.displayOption then
			arg_91_0:filterSort(iter_91_0)

			local var_91_0 = 0
			local var_91_1 = arg_91_0.listView_[var_0_24[iter_91_0]].scrollNode:getPositionY()
			local var_91_2 = import("app.windows.BackpackItem").new()

			if arg_91_0.player_:getBackpack():getItemNumByID(arg_91_0.itemID) <= 0 then
				if #arg_91_0.list_[var_0_24[arg_91_0.displayOption]] >= 1 then
					var_91_2:setParams(arg_91_0.list_[var_0_24[arg_91_0.displayOption]][1])
					arg_91_0:updateItemDetail(var_91_2.params.itemID)

					arg_91_0.flag = arg_91_0:isTiliItem(var_91_2.params.itemID)

					arg_91_0:updateAssetsShowState(var_91_2.params.itemID)
				else
					arg_91_0:nodeByName(var_0_0.ITEM_DETAIL):setVisible(false)
				end
			end

			arg_91_0.listView_[var_0_24[iter_91_0]]:reload()

			if var_91_1 > 0 then
				if var_91_1 > var_0_9 * math.ceil(#arg_91_0.list_[var_0_24[iter_91_0]] / var_0_13) and var_91_1 > arg_91_0.listView_[var_0_24[iter_91_0]]:getViewRectInWorldSpace().height + 2 then
					var_91_1 = var_0_9 * math.ceil(#arg_91_0.list_[var_0_24[iter_91_0]] / var_0_13)
				end

				arg_91_0.listView_[var_0_24[iter_91_0]].scrollNode:setPosition(0, var_91_1)
			end
		else
			arg_91_0.optionButtons_[iter_91_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_91_0.optionButtons_[iter_91_0]:setLocalZOrder(0)
			arg_91_0.listView_[var_0_24[iter_91_0]]:setLocalZOrder(1)
			arg_91_0.listView_[var_0_24[iter_91_0]]:removeAllItems()
		end

		arg_91_0.optionTxts_[iter_91_0]:setLocalZOrder(101)
	end

	arg_91_0:nodeByName("bg"):setLocalZOrder(1)
end

function var_0_0.buttonHandler(arg_92_0, arg_92_1, arg_92_2, arg_92_3)
	if arg_92_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_92_2)
		arg_92_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_92_1 then
			arg_92_1(arg_92_2, arg_92_3)
		end
	elseif arg_92_3 == ccui.TouchEventType.began then
		local var_92_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_92_1 = cc.RepeatForever:create(var_92_0)

		arg_92_2:runAction(var_92_1)

		return true
	elseif arg_92_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_92_2)
		arg_92_2:setScale(1)
	end
end

function var_0_0.changeSort(arg_93_0)
	arg_93_0.sortChange = true
end

function var_0_0.getSortOrder(arg_94_0, arg_94_1)
	arg_94_0.filterType = arg_94_1.filterType
	arg_94_0.filterOrder = arg_94_1.filterOrder

	arg_94_0:updateFilter()

	local var_94_0 = import("app.windows.BackpackItem").new()

	if #arg_94_0.list_[var_0_24[arg_94_0.displayOption]] >= 1 then
		var_94_0:setParams(arg_94_0.list_[var_0_24[arg_94_0.displayOption]][1])
		arg_94_0:updateItemDetail(var_94_0.params.itemID)

		arg_94_0.flag = arg_94_0:isTiliItem(var_94_0.params.itemID)

		arg_94_0:updateAssetsShowState(var_94_0.params.itemID)
		arg_94_0.listView_[var_0_24[arg_94_0.displayOption]]:getScrollNode():setPositionY(630)
	end

	if not tolua.isnull(arg_94_0.itemCellContent) and arg_94_0.backpackHandle == nil then
		arg_94_0.backpackHandle = var_0_22.scheduleGlobal(function()
			arg_94_0:updateScale()
		end, var_0_16)
	end
end

function var_0_0.willClose(arg_96_0)
	arg_96_0.player_:saveFilterType(arg_96_0.filterType * 2 + (arg_96_0.filterOrder and -2 or -1))

	if arg_96_0.backpackHandle ~= nil then
		var_0_22.unscheduleGlobal(arg_96_0.backpackHandle)

		arg_96_0.backpackHandle = nil
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

function var_0_0.returnCallBack(arg_97_0)
	xyd.WindowManager.get():closeWindow("backpack")
end

return var_0_0
