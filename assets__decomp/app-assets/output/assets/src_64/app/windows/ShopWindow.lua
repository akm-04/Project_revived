local var_0_0 = class("ShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.model
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.misc

var_0_0.REFRESH_BUTTON = "refresh_button"
var_0_0.TIME = "txt_time"

local var_0_6 = xyd.tables.translation
local var_0_7 = xyd.tables.shop
local var_0_8 = {
	var_0_6:translation("SHOP_REFRESH"),
	var_0_6:translation("ARENA_SHOP_REFRESH"),
	var_0_6:translation("MARCH_SHOP_REFRESH"),
	var_0_6:translation("SHOP_REFRESH"),
	var_0_6:translation("SHOP_REFRESH"),
	var_0_6:translation("TOP_SHOP_REFRESH"),
	var_0_6:translation("GUILD_SHOP_REFRESH"),
	var_0_6:translation("SHOP_REFRESH"),
	var_0_6:translation("REGION_SHOP_REFRESH"),
	var_0_6:translation("SHOP_REFRESH"),
	var_0_6:translation("HONOR_SHOP_REFRESH"),
	var_0_6:translation("PARADISE_SHOP_REFRESH"),
	var_0_6:translation("LIBRARY_SHOP_REFRESH"),
	var_0_6:translation("GAY_SHOP_REFRESH")
}

var_0_8[xyd.ShopType.ACADEMY_ARENA] = var_0_6:translation("ACADEMY_SHOP_REFRESH")
var_0_8[xyd.ShopType.SUMMON] = var_0_6:translation("SHOP_REFRESH")

local var_0_9 = -50
local var_0_10 = 2
local var_0_11 = {
	SUB_SHOP = 2,
	MAIN_SHOP = 1
}
local var_0_12 = {
	OFF = 2,
	ON = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.shop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.openList = arg_1_0:getOpenList()
	arg_1_0.shopType_ = arg_1_2.shop_type
	arg_1_0.scrollNodePosX = arg_1_2.scrollNodePosX or 10
	arg_1_0.scrollNodePosY = arg_1_2.scrollNodePosY or 0
	arg_1_0.shopSubType = var_0_11.MAIN_SHOP
	arg_1_0.itemList = {}
	arg_1_0.selectState = {}
	arg_1_0.selectTotalPrice = {}
end

function var_0_0.getOpenList(arg_2_0)
	local var_2_0 = arg_2_0.shop_:getOpenList()

	return xyd.removeByValues(var_2_0, {
		xyd.ShopType.SKIN,
		xyd.ShopType.ULTRA_SKIN
	})
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	arg_3_0:addTopSidebar()

	arg_3_0.dialog = arg_3_0:nodeByName("dialog")
	arg_3_0.dialogBg = arg_3_0:nodeByName("dialog_img")
	arg_3_0.ItemPanel = arg_3_0:nodeByName("list")

	arg_3_0:createShopTypeList()

	arg_3_0.isRefresh = false
	arg_3_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_3_0:loadOpenList()

	if not arg_3_0.shop_:isOpen(arg_3_0.shopType_) and xyd.tables.shop:isTeamShop(arg_3_0.shopType_) ~= 1 and xyd.tables.shop:isAlone(arg_3_0.shopType_) == 0 then
		print("shop type is not open!")

		arg_3_0.shopType_ = xyd.ShopType.NORMAL
	end

	arg_3_0:nodeByName("refresh_button"):setTouchSwallowEnabled(true)
	arg_3_0:nodeByName("buy_text"):setString(var_0_6:translation("BUY"))
	arg_3_0:nodeByName("reset_text"):setString(var_0_6:translation("SHOP_RESET"))

	arg_3_0.can_click = true

	arg_3_0:layout()
	arg_3_0:updateLeftHeroImg()

	if not arg_3_0.player_.backpackLoaded_ then
		arg_3_0.player_:loadBackpack(function(arg_4_0)
			if arg_4_0 == xyd.error.OK then
				arg_3_0.backpack_ = arg_3_0.player_:getBackpack()

				arg_3_0:loadShopInfo()
			end
		end)
	else
		arg_3_0.backpack_ = arg_3_0.player_:getBackpack()

		arg_3_0:loadShopInfo()
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.SHOP_COST_REFRESH, function(arg_5_0)
		if arg_3_0 and arg_3_0.updateCost then
			arg_3_0:updateCost()
		end
	end)
	arg_3_0:initSubSpaceShop()
	arg_3_0:resetSelect()
end

function var_0_0.updateAssetsContainer(arg_6_0)
	if not arg_6_0.assetContainer then
		local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_widgets/eco_display_sidebar.csb")

		arg_6_0:addChild(var_6_0)
		var_6_0:setPosition(cc.p(440, 674))
		var_6_0:setName("asset_container")
		arg_6_0:parseChildren_(var_6_0)
		var_6_0:setVisible(false)

		for iter_6_0 = 2, 4 do
			arg_6_0:nodeByName("eco_" .. iter_6_0):setVisible(false)
		end

		arg_6_0.assetContainer = var_6_0
	end

	local var_6_1, var_6_2 = arg_6_0:getShopCostInfo(arg_6_0.shopType_)

	if var_6_1 and var_6_2 then
		local var_6_3 = xyd.tables.ecoType:getEcoPath(var_6_2)
		local var_6_4 = xyd.AssetLoader.get():loadSprite(var_6_3)

		arg_6_0:nodeByName("pos_icon_1"):removeAllChildren()
		var_6_4:addTo(arg_6_0:nodeByName("pos_icon_1"))

		local var_6_5 = display.newNode()

		var_6_5:setContentSize(50, 50)
		var_6_5:addTo(arg_6_0)
		var_6_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_5:setPosition(arg_6_0:nodeByName("pos_icon_1"):getPosition())
		arg_6_0:addTips(var_6_4, var_6_1, var_6_2)
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0):addEventListener(xyd.event.ECONOMY_AFTER, function(arg_7_0)
			if arg_6_0 then
				local var_7_0, var_7_1 = arg_6_0:getShopCostInfo(arg_6_0.shopType_)

				arg_6_0:updateAssetsShow(var_7_0, var_7_1)
			end
		end)
		arg_6_0:updateAssetsShow(var_6_1, var_6_2)
	end

	arg_6_0:updateAssetsShowState()
end

function var_0_0.addTips(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	arg_8_1:setTouchEnabled(true)

	local var_8_0
	local var_8_1 = "eco_tips"
	local var_8_2 = {
		backendName = arg_8_3,
		name = xyd.tables.ecoType:getDes(arg_8_3),
		des = xyd.tables.ecoType:getGainDes(arg_8_3),
		num = arg_8_0.player_[arg_8_2]
	}

	arg_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			var_8_0 = arg_9_0.y

			if not xyd.WindowManager.get():getWindow(var_8_1) then
				local var_9_0 = xyd.WindowManager.get():openWindow(var_8_1, var_8_2)
				local var_9_1, var_9_2 = arg_8_1:getPosition()
				local var_9_3 = var_9_0:getTipHeight()
				local var_9_4 = arg_8_1:getParent():convertToWorldSpace(cc.p(var_9_1 - 20, var_9_2 + var_9_3 / 2 + 10))

				if var_9_4.x > 900 then
					var_9_4.x = 900
				end

				if var_9_4.y > 530 then
					var_9_4.y = 530
				end

				var_9_4.x, var_9_4.y = xyd.convertWorldPos(var_9_4.x, var_9_4.y)

				var_9_0:setPosition(var_9_4.x, var_9_4.y)
			end

			return true
		elseif arg_9_0.name == "moved" then
			local var_9_5 = arg_9_0.y

			if math.abs(var_9_5 - var_8_0) > 30 then
				xyd.WindowManager.get():closeWindow(var_8_1)
			end
		elseif arg_9_0.name == "ended" then
			xyd.WindowManager.get():closeWindow(var_8_1)
		end
	end)
end

function var_0_0.getShopCostInfo(arg_10_0, arg_10_1)
	local var_10_0
	local var_10_1

	if arg_10_1 == xyd.ShopType.ARENA then
		var_10_0 = "arena_coin"
		var_10_1 = "arena_coin"
	elseif arg_10_1 == xyd.ShopType.MARCH then
		var_10_0 = "march_coin"
		var_10_1 = "march_coin"
	elseif arg_10_1 == xyd.ShopType.TOP then
		var_10_0 = "top_coin"
		var_10_1 = "top_coin"
	elseif arg_10_1 == xyd.ShopType.GUILD then
		var_10_0 = "guild_coin"
		var_10_1 = "guild_coin"
	elseif arg_10_1 == xyd.ShopType.REGION then
		var_10_0 = "region_coin"
		var_10_1 = "region_coin"
	elseif arg_10_1 == xyd.ShopType.HONOR then
		var_10_0 = "honorCoin"
		var_10_1 = "honor_coin"
	elseif arg_10_1 == xyd.ShopType.ILLUSION then
		var_10_0 = "illusionCoin"
		var_10_1 = "illusion_coin"
	elseif arg_10_1 == xyd.ShopType.MAGIC then
		var_10_0 = "crystal"
		var_10_1 = "crystal"
	elseif arg_10_1 == xyd.ShopType.TEATALK then
		var_10_0 = "friendMedal"
		var_10_1 = "friend_medal"
	elseif arg_10_1 == xyd.ShopType.ACADEMY_ARENA then
		var_10_0 = "academyCoin"
		var_10_1 = "academy_coin"
	elseif arg_10_1 == xyd.ShopType.ULTRA_SKIN then
		var_10_0 = "skinFragment"
		var_10_1 = "skin_fragment"
	elseif arg_10_1 == xyd.ShopType.SUMMON then
		var_10_0 = "summonCoin"
		var_10_1 = "summon_coin"
	elseif arg_10_1 == xyd.ShopType.TUTOR then
		var_10_0 = "tutorCoin"
		var_10_1 = "tutor_coin"
	end

	if xyd.tables.shop:isTeamShop(arg_10_1) == 1 then
		var_10_0 = "teamDungeonCoin"
		var_10_1 = "team_dungeon_coin"
	end

	return var_10_0, var_10_1
end

function var_0_0.updateAssetsShow(arg_11_0, arg_11_1, arg_11_2)
	arg_11_0:nodeByName("txt_eco_val_1"):setString(arg_11_0.player_[arg_11_1])
end

function var_0_0.updateAssetsShowState(arg_12_0)
	if (arg_12_0.shopType_ == xyd.ShopType.NORMAL or arg_12_0.shopType_ == xyd.ShopType.GNOME or arg_12_0.shopType_ == xyd.ShopType.BLACK or arg_12_0.shopType_ == xyd.ShopType.SPACE or arg_12_0.shopType_ == xyd.ShopType.SKIN) and xyd.tables.shop:isTeamShop(arg_12_0.shopType_) == 0 then
		arg_12_0.children_.eco_sidebar:setVisible(true)
		arg_12_0:getChildByName("asset_container"):setVisible(false)
	else
		arg_12_0.children_.eco_sidebar:setVisible(false)
		arg_12_0:getChildByName("asset_container"):setVisible(true)
	end
end

function var_0_0.createShopTypeList(arg_13_0)
	local var_13_0 = arg_13_0:nodeByName("type_scroll"):getContentSize()

	arg_13_0.shopList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_13_0.width, var_13_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_13_0:nodeByName("type_scroll")):onScroll(handler(arg_13_0, arg_13_0.scrollListener))

	arg_13_0.shopList:setDelegate(handler(arg_13_0, arg_13_0.shopListDelegate))
	arg_13_0.shopList:reload()
end

function var_0_0.shopListDelegate(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	if cc.ui.UIListView.COUNT_TAG == arg_14_2 then
		return #arg_14_0.openList
	elseif cc.ui.UIListView.CELL_TAG == arg_14_2 then
		local var_14_0 = arg_14_0.shopList:dequeueItem()

		if not var_14_0 then
			var_14_0 = arg_14_0.shopList:newItem()
		else
			var_14_0:removeAllChildren(true)
		end

		local var_14_1 = arg_14_0:createShopListContent(arg_14_3)
		local var_14_2 = var_14_1:getWidth()
		local var_14_3 = var_14_1:getHeight()

		var_14_0:setItemSize(var_14_2, var_14_3)
		var_14_0:addContent(var_14_1)

		return var_14_0
	end
end

function var_0_0.createShopListContent(arg_15_0, arg_15_1)
	local var_15_0 = display.newNode()
	local var_15_1 = arg_15_0.openList[arg_15_1]
	local var_15_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/shop_window/shop_type_item.csb")
	local var_15_3 = var_15_2:getChildByName("container")
	local var_15_4 = var_15_3:getChildByName("name_txt")

	var_15_4:setString(var_0_7:shopChangeName(var_15_1))
	var_15_2:addTo(var_15_0)
	var_15_2:setAnchorPoint(cc.p(0, 0))

	if var_15_1 == arg_15_0.shopType_ then
		var_15_3:getChildByName("selected_box"):setVisible(true)
		var_15_4:setColor(cc.c3b(246, 223, 101))
	else
		var_15_3:getChildByName("selected_box"):setVisible(false)
		var_15_4:setColor(cc.c3b(230, 230, 230))
	end

	var_15_2:setTouchEnabled(true)
	var_15_2:setTouchSwallowEnabled(false)
	var_15_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			return true
		elseif arg_16_0.name == "moved" then
			return true
		elseif arg_16_0.name == "ended" and not arg_15_0.scrollViewMoved_ then
			arg_15_0:updateView(var_15_1)
		end
	end)
	var_15_0:setContentSize(var_15_3:getContentSize())
	var_15_2:setName("source")

	return var_15_0
end

function var_0_0.loadOpenList(arg_17_0)
	arg_17_0.openList = arg_17_0:getOpenList()
	arg_17_0.countDowns_ = {}

	local var_17_0 = false

	for iter_17_0, iter_17_1 in pairs(arg_17_0.openList) do
		if iter_17_1 == arg_17_0.shopType_ then
			var_17_0 = true

			break
		end
	end

	if var_17_0 == false then
		arg_17_0.shopType_ = xyd.ShopType.NORMAL
	end
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevX_ = arg_18_1.x
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" then
		local var_18_0 = 20

		if var_18_0 <= math.abs(arg_18_1.x - arg_18_0.prevX_) or var_18_0 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
			arg_18_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.updateItems(arg_19_0)
	local var_19_0 = arg_19_0:nodeByName("list"):getContentSize().height
	local var_19_1 = cc.MoveBy:create(0.4, cc.p(0, -var_19_0))
	local var_19_2

	if not arg_19_0.oldContainer then
		arg_19_0.oldContainer = arg_19_0:createContainer(false)
	elseif arg_19_0.isRefresh then
		var_19_2 = arg_19_0:createContainer(arg_19_0.isRefresh)

		transition.moveBy(var_19_2, {
			time = 0.4,
			x = 0,
			y = -var_19_0,
			onComplete = function()
				arg_19_0.isRefresh = false

				arg_19_0.oldContainer:removeAllItems()

				arg_19_0.oldContainer = var_19_2

				transition.moveBy(arg_19_0.oldContainer, {
					time = 0.2,
					x = 0,
					y = 50,
					onComplete = function()
						transition.moveBy(arg_19_0.oldContainer, {
							time = 0.2,
							x = 0,
							y = -50,
							onComplete = function()
								return
							end
						})
					end
				})
			end
		})
		arg_19_0.oldContainer:runAction(var_19_1)
	else
		arg_19_0.oldContainer:removeAllItems()

		arg_19_0.oldContainer = arg_19_0:createContainer(arg_19_0.isRefresh)
	end
end

function var_0_0.createContainer(arg_23_0, arg_23_1)
	local var_23_0 = arg_23_0.ItemPanel:getContentSize()
	local var_23_1 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_23_0.width, var_23_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_23_0.ItemPanel):onScroll(handler(arg_23_0, arg_23_0.scrollListener))
	local var_23_2 = math.ceil(#arg_23_0.shop_.items_[arg_23_0.shopType_] / 3)
	local var_23_3 = 1

	arg_23_0.skinItems = {}
	arg_23_0.itemList = {}
	arg_23_0.selectState = {}

	for iter_23_0 = 1, var_23_2 do
		local var_23_4 = var_23_1:newItem()
		local var_23_5 = display.newNode()
		local var_23_6 = 211
		local var_23_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/shop_window/shop_line_item.csb")
		local var_23_8 = var_23_7:getChildByName("container")

		for iter_23_1 = 1, 3 do
			local var_23_9 = (iter_23_0 - 1) * 2 + iter_23_1
			local var_23_10

			if arg_23_0.shopType_ == xyd.ShopType.SKIN or arg_23_0.shopType_ == xyd.ShopType.ULTRA_SKIN then
				var_23_10 = import("app.windows.SkinShopItem").new()
			else
				var_23_10 = import("app.windows.ShopItem").new()
			end

			local var_23_11 = arg_23_0.shop_.items_[arg_23_0.shopType_][var_23_3]

			if not var_23_11 then
				break
			end

			local var_23_12 = {
				index = var_23_11.index,
				itemID = var_23_11.item_id,
				itemNum = var_23_11.item_num,
				isBuy = var_23_11.isbuy,
				sellPrice = var_23_11.sell_price,
				sellType = var_23_11.sell_type,
				shopType = arg_23_0.shopType_,
				disCount = var_23_11.discount,
				stoneID = var_23_11.stone_id,
				buyTimes = var_23_11.buy_times
			}

			var_23_10:setParams(var_23_12)
			var_23_8:addChild(var_23_10)
			var_23_10:setPosition(var_23_6 * (iter_23_1 - 1) + 55, 14)
			var_23_10:setAnchorPoint(cc.p(0.5, 0.5))
			var_23_10:ignoreAnchorPointForPosition(false)

			arg_23_0.selectState[var_23_3] = 0

			if arg_23_0.shopType_ == xyd.ShopType.SPACE or arg_23_0.shopType_ == xyd.ShopType.BATTLE_PASS_SHOP or arg_23_0.shopType_ == xyd.ShopType.FISH_GAMBLING or arg_23_0.shopType_ == xyd.ShopType.TUTOR then
				var_23_10.contentView_:nodeByName("check_box"):setVisible(false)
				var_23_10.contentView_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
					if arg_24_0.name == "began" then
						var_23_10.contentView_:nodeByName("container"):setScale(0.9)

						return true
					elseif arg_24_0.name == "ended" then
						var_23_10.contentView_:nodeByName("container"):setScale(1)

						if arg_23_0.can_click == true then
							xyd.playButtonSound()

							if not arg_23_0.scrollViewMoved_ then
								if var_23_10.isBuy == 0 then
									arg_23_0.scrollNodePosX = var_23_1.scrollNode:getPositionX()
									arg_23_0.scrollNodePosY = var_23_1.scrollNode:getPositionY()

									if arg_23_0.shopType_ == xyd.ShopType.TUTOR then
										xyd.WindowManager.get():openWindow("shop_buy_detail", var_23_10.params)
									elseif arg_23_0.shopType_ == xyd.ShopType.FISH_GAMBLING then
										xyd.WindowManager.get():openWindow("fish_gambling_shop_detail", var_23_10.params)
									else
										xyd.WindowManager.get():openWindow("shop_detail_window", var_23_10.params)
									end
								elseif var_23_10.isBuy == 1 then
									arg_23_0:showDialog(xyd.ShopMessageType.SOLD_OUT)
								end
							end
						end
					end
				end)
			else
				var_23_10.contentView_:nodeByName("check_box"):setVisible(true)
				var_23_10.buyOne:addTouchEventListener(function(arg_25_0, arg_25_1)
					xyd.buttonScaleAnim(arg_25_0, arg_25_1)

					if arg_25_1 == ccui.TouchEventType.began then
						var_23_10.contentView_:nodeByName("container"):setScale(0.9)

						return true
					elseif arg_25_1 == ccui.TouchEventType.ended then
						var_23_10.contentView_:nodeByName("container"):setScale(1)

						if arg_23_0.can_click == true then
							xyd.playButtonSound()

							if not arg_23_0.scrollViewMoved_ then
								if var_23_10.isBuy == 0 then
									arg_23_0.scrollNodePosX = var_23_1.scrollNode:getPositionX()
									arg_23_0.scrollNodePosY = var_23_1.scrollNode:getPositionY()

									if arg_23_0.shopType_ == xyd.ShopType.TUTOR then
										xyd.WindowManager.get():openWindow("shop_buy_detail", var_23_10.params)
									elseif arg_23_0.shopType_ == xyd.ShopType.FISH_GAMBLING then
										xyd.WindowManager.get():openWindow("fish_gambling_shop_detail", var_23_10.params)
									else
										xyd.WindowManager.get():openWindow("shop_detail_window", var_23_10.params)
									end
								elseif var_23_10.isBuy == 1 then
									arg_23_0:showDialog(xyd.ShopMessageType.SOLD_OUT)
								end
							end
						end
					elseif arg_25_1 == ccui.TouchEventType.canceled then
						var_23_10.contentView_:nodeByName("container"):setScale(1)
					end
				end)
				var_23_10.buySelect:addTouchEventListener(function(arg_26_0, arg_26_1)
					if arg_26_1 == ccui.TouchEventType.began then
						var_23_10.contentView_:nodeByName("container"):setScale(0.9)

						return true
					elseif arg_26_1 == ccui.TouchEventType.ended then
						var_23_10.contentView_:nodeByName("container"):setScale(1)

						if arg_23_0.can_click == true then
							xyd.playButtonSound()

							if not arg_23_0.scrollViewMoved_ then
								if var_23_10.isBuy == 0 then
									arg_23_0.scrollNodePosX = var_23_1.scrollNode:getPositionX()
									arg_23_0.scrollNodePosY = var_23_1.scrollNode:getPositionY()

									if arg_23_0.shopType_ == xyd.ShopType.TUTOR then
										xyd.WindowManager.get():openWindow("shop_buy_detail", var_23_10.params)
									else
										local var_26_0 = {}
										local var_26_1 = var_23_11.index

										var_26_0.index = var_26_1

										if not arg_23_0.selectState[var_26_1] or arg_23_0.selectState[var_26_1] == 0 then
											var_23_10.checkgou:setVisible(true)
											var_23_10.bgSelect:setVisible(true)

											arg_23_0.selectState[var_26_1] = 1
											var_26_0.selectType = var_0_12.ON
										elseif arg_23_0.selectState[var_26_1] == 1 then
											var_23_10.checkgou:setVisible(false)
											var_23_10.bgSelect:setVisible(false)

											arg_23_0.selectState[var_26_1] = 0
											var_26_0.selectType = var_0_12.OFF
										end

										arg_23_0:updateSelectState(var_26_0)
									end
								elseif var_23_10.isBuy == 1 then
									arg_23_0:showDialog(xyd.ShopMessageType.SOLD_OUT)
								end
							end
						end
					elseif arg_26_1 == ccui.TouchEventType.canceled then
						var_23_10.contentView_:nodeByName("container"):setScale(1)
					end
				end)
			end

			arg_23_0.itemList[var_23_3] = var_23_10
			var_23_3 = var_23_3 + 1
		end

		var_23_7:addTo(var_23_5)
		var_23_4:addContent(var_23_5)
		var_23_5:setContentSize(var_23_8:getContentSize().width, var_23_8:getContentSize().height)
		var_23_4:setItemSize(var_23_0.width, 260)
		var_23_1:addItem(var_23_4)
	end

	var_23_1:reload()

	return var_23_1
end

function var_0_0.updateHeroModel(arg_27_0, arg_27_1)
	local var_27_0 = var_0_2.new()
	local var_27_1 = xyd.tables.item:skinPartner(arg_27_1)

	arg_27_0:nodeByName("hero_name"):setString(xyd.tables.hero:name(var_27_1))

	arg_27_0.modelID = xyd.tables.item:skinModel(arg_27_1)

	local var_27_2 = xyd.HeroAnimation.new(var_27_1, arg_27_0.modelID, var_0_3:uiScale(arg_27_0.modelID), {})

	if var_27_2 then
		var_27_2:idle()
	end

	arg_27_0.heroModel = var_27_2

	var_27_2:setTouchSwallowEnabled(false)

	arg_27_0.modelState = xyd.ModelState.Walk

	var_27_2:setPosition(cc.p(0, 0))
	arg_27_0:nodeByName("model"):removeAllChildren()
	var_27_2:addTo(arg_27_0:nodeByName("model"))
	var_27_2:setTouchEnabled(true)

	arg_27_0.isShow = false
end

function var_0_0.updateSelectState(arg_28_0, arg_28_1)
	if arg_28_1 then
		local var_28_0 = arg_28_0.shop_.items_[arg_28_0.shopType_][arg_28_1.index]

		if not arg_28_0.selectTotalPrice[var_28_0.sell_type] then
			arg_28_0.selectTotalPrice[var_28_0.sell_type] = 0
		end

		if arg_28_1.selectType == var_0_12.ON then
			arg_28_0.selectTotalPrice[var_28_0.sell_type] = arg_28_0.selectTotalPrice[var_28_0.sell_type] + tonumber(arg_28_0.itemList[arg_28_1.index].params.sellPrice)
		elseif arg_28_1.selectType == var_0_12.OFF then
			arg_28_0.selectTotalPrice[var_28_0.sell_type] = arg_28_0.selectTotalPrice[var_28_0.sell_type] - tonumber(arg_28_0.itemList[arg_28_1.index].params.sellPrice)
		end
	end

	local var_28_1 = 1
	local var_28_2 = false

	arg_28_0.canBuyMulti = true
	arg_28_0.notEnough = nil

	local var_28_3 = import("app.windows.ShopItem").new()

	for iter_28_0, iter_28_1 in pairs(arg_28_0.selectTotalPrice) do
		if iter_28_1 and iter_28_1 > 0 then
			var_28_2 = true

			local var_28_4 = var_28_3:getCurrencyPic(iter_28_0)
			local var_28_5 = arg_28_0:nodeByName("img_" .. var_28_1)

			var_28_5:setVisible(true)
			var_28_5:removeAllChildren()

			local var_28_6 = arg_28_0:nodeByName("cost_txt_" .. var_28_1)

			var_28_6:setVisible(true)
			var_28_6:setString(iter_28_1)

			if var_28_4 then
				var_28_4:setScale(var_28_5:getContentSize().height / var_28_4:getContentSize().height)
				xyd.displaySpriteOnContainer(var_28_4, var_28_5, false)
			elseif iter_28_0 == xyd.currencyType.STONE or iter_28_0 == xyd.currencyType.PET_STONE then
				local var_28_7 = var_28_5
				local var_28_8 = var_28_7:getContentSize().height

				var_28_7:setContentSize(var_28_8, var_28_8)

				if iter_28_0 == xyd.currencyType.STONE and iter_28_1 <= stoneReplaceNum then
					xyd.setItemBorder(var_28_7, stoneReplaceId, false, false)
				else
					xyd.setItemBorder(var_28_7, arg_28_0.stoneID, false, false)
				end
			end

			if not arg_28_0.notEnough then
				if iter_28_1 > arg_28_0.selfPlayer.mana and iter_28_0 == xyd.currencyType.MANA or iter_28_1 > arg_28_0.selfPlayer.crystal and iter_28_0 == xyd.currencyType.CRYSTAL or iter_28_1 > arg_28_0.selfPlayer.arena_coin and iter_28_0 == xyd.currencyType.ARENA_COIN or iter_28_1 > arg_28_0.selfPlayer.march_coin and iter_28_0 == xyd.currencyType.MARCH_COIN or iter_28_1 > arg_28_0.selfPlayer.top_coin and iter_28_0 == xyd.currencyType.TOP_COIN or iter_28_1 > arg_28_0.selfPlayer.guild_coin and iter_28_0 == xyd.currencyType.GUILD_COIN or iter_28_1 > arg_28_0.selfPlayer.region_coin and iter_28_0 == xyd.currencyType.REGION_COIN or iter_28_1 > arg_28_0.selfPlayer.illusionCoin and iter_28_0 == xyd.currencyType.ILLUSION_COIN or iter_28_1 > arg_28_0.selfPlayer.academyCoin and iter_28_0 == xyd.currencyType.ACADEMY_COIN or iter_28_1 > arg_28_0.selfPlayer.friendMedal and iter_28_0 == xyd.currencyType.TEA_TALK or iter_28_0 == xyd.currencyType.STONE and iter_28_1 > stoneNum and iter_28_1 > stoneReplaceNum or iter_28_0 == xyd.currencyType.HONOR_COIN and iter_28_1 > arg_28_0.selfPlayer.honorCoin or iter_28_0 == xyd.currencyType.TEAM_DUNGEON and iter_28_1 > arg_28_0.selfPlayer.teamDungeonCoin or iter_28_0 == xyd.currencyType.SUMMON_COIN and iter_28_1 > arg_28_0.selfPlayer.summonCoin or iter_28_0 == xyd.currencyType.PET_STONE and iter_28_1 > stoneNum then
					var_28_6:setColor(cc.c4b(255, 0, 0, 150))

					arg_28_0.canBuyMulti = false
					arg_28_0.notEnough = iter_28_0
				else
					var_28_6:setColor(cc.c4b(0, 0, 0, 255))
				end
			end

			var_28_1 = var_28_1 + 1
		end
	end

	dump(var_28_1)
	dump(var_28_2)

	for iter_28_2 = var_28_1, var_0_10 do
		arg_28_0:nodeByName("img_" .. iter_28_2):setVisible(false)
		arg_28_0:nodeByName("cost_txt_" .. iter_28_2):setVisible(false)
	end

	arg_28_0:nodeByName("count_container"):setVisible(var_28_2)
end

function var_0_0.resetModelState(arg_29_0, arg_29_1)
	if arg_29_0.modelState == 8 then
		arg_29_0.modelState = arg_29_0.modelState + 1
	end

	arg_29_0.modelState = arg_29_0.modelState % 8
	arg_29_0.isShow = true

	local var_29_0

	if arg_29_0.modelState == xyd.ModelState.Walk then
		arg_29_1:walk(true)

		arg_29_0.isShow = false
		var_29_0 = xyd.tables.model:getMoveSound(arg_29_0.modelID)
	elseif arg_29_0.modelState == xyd.ModelState.Win then
		arg_29_1:win(false, handler(arg_29_0, arg_29_0.setIsShow))

		var_29_0 = xyd.tables.model:getWinSound(arg_29_0.modelID)
	elseif arg_29_0.modelState == xyd.ModelState.Attack1 then
		arg_29_1:attack(1, nil, nil, handler(arg_29_0, arg_29_0.setIsShow))

		var_29_0 = xyd.tables.model:getNormalAttackSound(arg_29_0.modelID)
	elseif arg_29_0.modelState == xyd.ModelState.Attack2 then
		arg_29_1:attack(2, nil, nil, handler(arg_29_0, arg_29_0.setIsShow))

		var_29_0 = xyd.tables.model:getAttack1Sound(arg_29_0.modelID)
	elseif arg_29_0.modelState == xyd.ModelState.Attack3 then
		arg_29_1:attack(3, nil, nil, handler(arg_29_0, arg_29_0.setIsShow))

		var_29_0 = xyd.tables.model:getAttack2Sound(arg_29_0.modelID)
	elseif arg_29_0.modelState == xyd.ModelState.Attack4 then
		if not arg_29_1:hasAnimation("gongji04") then
			arg_29_0.modelState = arg_29_0.modelState + 1

			arg_29_0:resetModelState(arg_29_1)

			return
		end

		arg_29_1:attack(4, nil, nil, handler(arg_29_0, arg_29_0.setIsShow))

		var_29_0 = xyd.tables.model:getAttack4Sound(arg_29_0.modelID)
	elseif arg_29_0.modelState == xyd.ModelState.Attack5 then
		if not arg_29_1:hasAnimation("gongji05") then
			arg_29_0.modelState = arg_29_0.modelState + 1

			arg_29_0:resetModelState(arg_29_1)

			return
		end

		arg_29_1:attack(5, nil, nil, handler(arg_29_0, arg_29_0.setIsShow))

		var_29_0 = xyd.tables.model:getAttack4Sound(arg_29_0.modelID)
	else
		arg_29_0:setIsShow()
	end

	if var_29_0 and var_29_0 ~= "" then
		audio.stopAllSounds()
		audio.playSound(var_29_0, false)
	end

	arg_29_0.modelState = arg_29_0.modelState + 1
end

function var_0_0.setIsShow(arg_30_0)
	arg_30_0.isShow = false

	arg_30_0.heroModel:idle()
end

function var_0_0.loadShopInfo(arg_31_0, arg_31_1)
	arg_31_0.shop_:loadShopInfo({
		shop_type = arg_31_1 or arg_31_0.shopType_
	}, function(arg_32_0)
		if arg_32_0 == xyd.error.OK then
			arg_31_0:updateView_(arg_31_1 or arg_31_0.shopType_)
		end
	end)
end

function var_0_0.didOpen(arg_33_0)
	arg_33_0:nodeByName(var_0_0.REFRESH_BUTTON):addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended then
			arg_33_0.can_click = true

			xyd.playButtonSound()

			local var_34_0 = arg_33_0.shop_.refreshTimes_[arg_33_0.shopType_]
			local var_34_1 = xyd.tables.refreshCost:shopRefreshCost(var_34_0 + 1, arg_33_0.shopType_)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_8[arg_33_0.shopType_], var_34_1),
				string.format(var_0_6:translation("SHOP_REFRESH_CONTINUE"), var_34_0)
			}, function()
				if not arg_33_0 or tolua.isnull(arg_33_0) then
					return
				end

				if (arg_33_0.shopType_ == xyd.ShopType.NORMAL or arg_33_0.shopType_ == xyd.ShopType.GMONE or arg_33_0.shopType_ == xyd.ShopType.BLACK or arg_33_0.shopType_ == xyd.ShopType.SPACE or arg_33_0.shopType_ == xyd.ShopType.MAGIC or arg_33_0.shopType_ == xyd.ShopType.SUMMON) and arg_33_0.player_.crystal < var_34_1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_6:translation("ZUANSHI_ABSENCE"), function()
						local var_36_0 = {}

						var_36_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_36_0)
					end, nil, nil, arg_33_0.colorMode)
				elseif arg_33_0.shopType_ == xyd.ShopType.MARCH and arg_33_0.player_.march_coin < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("MARCH_COIN_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.ARENA and arg_33_0.player_.arena_coin < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("ARENA_COIN_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.TOP and arg_33_0.player_.top_coin < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("TOP_COIN_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.GUILD and arg_33_0.player_.guild_coin < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("GUILD_COIN_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.HONOR and arg_33_0.player_.honorCoin < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("HONOR_COIN_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.REGION and arg_33_0.player_.region_coin < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("REGION_COIN_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.ILLUSION and arg_33_0.player_.illusionCoin < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("PARADISE_COIN_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.ACADEMY_ARENA and arg_33_0.player_.academyCoin < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("ACADEMY_COIN_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.MAGIC and arg_33_0.player_.crystal < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("LIBRARY_YUANBAO_REFRESH_ABSENCE")
					})
				elseif arg_33_0.shopType_ == xyd.ShopType.TEATALK and arg_33_0.player_.friendMedal < var_34_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_6:translation("GAY_COIN_REFRESH_ABSENCE")
					})
				else
					arg_33_0.shop_:refreshShop({
						shop_type = arg_33_0.shopType_
					}, function(arg_37_0)
						if arg_37_0 == xyd.error.OK then
							arg_33_0:resetScrollNode()
							arg_33_0:updateItems()
							arg_33_0:updateCost()
						end
					end)
				end
			end, nil, 0, arg_33_0.colorMode)
		elseif arg_34_1 == ccui.TouchEventType.began then
			arg_33_0.can_click = false
		elseif arg_34_1 == ccui.TouchEventType.canceled then
			arg_33_0.can_click = true
		end
	end)
	arg_33_0:nodeByName("reset_button"):addTouchEventListener(function(arg_38_0, arg_38_1)
		if arg_38_1 == ccui.TouchEventType.ended then
			arg_33_0.can_click = true

			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				var_0_6:translation("SHOP_RESET_SELECT")
			}, function()
				if not arg_33_0 or tolua.isnull(arg_33_0) then
					return
				end

				arg_33_0:resetSelect()
			end, nil, 0, arg_33_0.colorMode)
		elseif arg_38_1 == ccui.TouchEventType.began then
			arg_33_0.can_click = false
		elseif arg_38_1 == ccui.TouchEventType.canceled then
			arg_33_0.can_click = true
		end
	end)
	arg_33_0:nodeByName("buy_button"):addTouchEventListener(function(arg_40_0, arg_40_1)
		if arg_40_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_33_0.can_click = true

			if arg_33_0.canBuyMulti then
				local var_40_0 = var_0_6:translation("SHOP_BUY_SELECT")
				local var_40_1 = 0

				for iter_40_0, iter_40_1 in pairs(arg_33_0.selectTotalPrice) do
					if iter_40_1 > 0 then
						local var_40_2 = arg_33_0:getCostString(iter_40_0)

						var_40_0 = var_40_0 .. iter_40_1 .. var_40_2
						var_40_1 = iter_40_1
					end
				end

				local var_40_3 = {}
				local var_40_4 = {}

				for iter_40_2, iter_40_3 in pairs(arg_33_0.selectState) do
					if iter_40_3 and iter_40_3 == 1 then
						table.insert(var_40_3, iter_40_2)

						if arg_33_0.shopType_ == xyd.ShopType.MAGIC then
							table.insert(var_40_4, tonumber(arg_33_0.itemList[iter_40_2].params.sellPrice))
						end
					end
				end

				local var_40_5 = {
					list = var_40_3,
					client_prices = var_40_4,
					nums = {},
					shop_type = arg_33_0.shopType_
				}

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_40_0,
					var_0_6:translation("SHOP_BUY_SELECT_CONTINUE")
				}, function()
					if not arg_33_0 or tolua.isnull(arg_33_0) then
						return
					end

					arg_33_0.shop_:buyMulti(var_40_5, function(arg_42_0)
						if arg_42_0 == xyd.error.OK then
							arg_33_0:multiBuyRefresh(var_40_1, var_40_3)
						end
					end)
				end, {
					showBegin = true
				}, 0, arg_33_0.colorMode)
			else
				local var_40_6 = arg_33_0:getCostString(arg_33_0.notEnough)

				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_6:translation("SHOP_BUY_SELECT_ABSENCE"), var_40_6)
				})
			end
		elseif arg_40_1 == ccui.TouchEventType.began then
			arg_33_0.can_click = false
		elseif arg_40_1 == ccui.TouchEventType.canceled then
			arg_33_0.can_click = true
		end
	end)

	local var_33_0 = {
		50001008,
		50001009,
		50001010,
		50001011,
		50001012,
		50001041,
		50001683
	}
	local var_33_1 = {}

	for iter_33_0, iter_33_1 in ipairs(var_33_0) do
		local var_33_2 = arg_33_0.backpack_:getItemNumByID(iter_33_1)

		if var_33_2 > 0 then
			table.insert(var_33_1, {
				item_id = iter_33_1,
				item_num = var_33_2
			})
		end
	end

	if #var_33_1 > 0 then
		xyd.WindowManager.get():openWindow("shop_sell", {
			itemType = "MANA",
			items = var_33_1
		})
	end

	local var_33_3 = xyd.WindowManager.get():getWindow("library_hero_favor")

	if var_33_3 then
		var_33_3:nodeByName("container"):setVisible(false)
	end
end

function var_0_0.multiBuyRefresh(arg_43_0, arg_43_1, arg_43_2)
	if arg_43_0.shopType_ == xyd.ShopType.SKIN and arg_43_0.backpack_:getItemNumByID(xyd.tables.misc.skinTicketId) > 0 then
		local var_43_0 = {
			itemID = xyd.tables.misc.skinTicketId
		}

		var_43_0.itemNum = 1

		arg_43_0.backpack_:removeItem(var_43_0)
	end

	if arg_43_0.shopType_ == xyd.ShopType.SKIN or arg_43_0.shopType == xyd.ShopType.ULTRA_SKIN then
		local var_43_1 = xyd.WindowManager.get():getWindow("skin_shop")

		if var_43_1 then
			var_43_1.shopList:refreshList()
		end
	end

	if arg_43_0.shopType_ == xyd.ShopType.MAGIC then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REFRESH_MAGIC_GIFT
		})
	end

	if arg_43_0.shopType_ == xyd.ShopType.COURSE then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REFRESH_COURSE_BOOK
		})
	end

	if arg_43_0.shopType_ == xyd.ShopType.CHAMPIONS_LEAGUE then
		arg_43_0.backpack_:addItemsByID(var_0_5:getValue("cross_arena_magic_cube_new"), -arg_43_1)

		for iter_43_0, iter_43_1 in pairs(arg_43_2) do
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.CHAMPIONS_ECONOMY_AFTER,
				messageType = arg_43_0.itemList[iter_43_1].sellType
			})
		end
	end

	if arg_43_0.shopType_ == xyd.ShopType.BATTLE_PASS_SHOP then
		arg_43_0.backpack_:addItemsByID(var_0_5:getValue("battle_pass_shop_coin_id"), -arg_43_1)

		local var_43_2 = xyd.WindowManager.get():getWindow("battle_pass_shop")

		if var_43_2 and not tolua.isnull(var_43_2) then
			var_43_2:upadteEco()
		end
	end

	if arg_43_0.shopType_ == xyd.ShopType.COURSE then
		local var_43_3 = xyd.WindowManager.get():getWindow("course")

		if var_43_3 and not tolua.isnull(var_43_3) then
			var_43_3:updateLevelUpItems()
		end
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.SHOP_DIALOG,
		messageType = xyd.ShopMessageType.BUY
	})
	arg_43_0:resetSelect()
end

function var_0_0.willClose(arg_44_0)
	if arg_44_0.dialogHandler then
		var_0_1.unscheduleGlobal(arg_44_0.dialogHandler)
	end

	if arg_44_0.handle_ then
		var_0_1.unscheduleGlobal(arg_44_0.handle_)
	end

	if arg_44_0.specialDialogHandler then
		var_0_1.unscheduleGlobal(arg_44_0.specialDialogHandler)
	end

	local var_44_0 = xyd.WindowManager.get():getWindow("library_hero_favor")

	if var_44_0 then
		var_44_0:nodeByName("container"):setVisible(true)
	end
end

function var_0_0.getCostString(arg_45_0, arg_45_1)
	local var_45_0 = ""

	if arg_45_1 == xyd.currencyType.MANA then
		var_45_0 = var_0_6:translation("COIN")
	elseif arg_45_1 == xyd.currencyType.CRYSTAL then
		var_45_0 = var_0_6:translation("CRYSTAL")
	elseif arg_45_1 == xyd.currencyType.ARENA_COIN then
		var_45_0 = var_0_6:translation("ARENA_COIN")
	elseif arg_45_1 == xyd.currencyType.MARCH_COIN then
		var_45_0 = var_0_6:translation("MARCH_COIN")
	elseif arg_45_1 == xyd.currencyType.TOP_COIN then
		var_45_0 = var_0_6:translation("TOP_COIN")
	elseif arg_45_1 == xyd.currencyType.GUILD_COIN then
		var_45_0 = var_0_6:translation("GUILD_COIN")
	elseif arg_45_1 == xyd.currencyType.REGION_COIN then
		var_45_0 = var_0_6:translation("REGION_COIN")
	elseif arg_45_1 == xyd.currencyType.HONOR_COIN then
		var_45_0 = var_0_6:translation("HONOR_COIN")
	elseif arg_45_1 == xyd.currencyType.ACADEMY_COIN then
		var_45_0 = var_0_6:translation("ACADEMY_COIN")
	elseif arg_45_1 == xyd.currencyType.ILLUSION_COIN then
		var_45_0 = var_0_6:translation("PARADISE_COIN")
	elseif sleeType == xyd.currencyType.TEAM_DUNGEON then
		var_45_0 = var_0_6:translation("TEAM_DUNGEON_COIN")
	elseif arg_45_1 == xyd.currencyType.SUMMON_COIN then
		var_45_0 = var_0_6:translation("SUMMON_COIN")
	elseif arg_45_1 == xyd.currencyType.TEA_TALK then
		var_45_0 = var_0_6:translation("GAY_COIN")
	elseif sleeType == xyd.currencyType.TUTOR_COIN then
		var_45_0 = var_0_6:translation("TUTOR_COIN")
	end

	return var_45_0
end

function var_0_0.didClose(arg_46_0)
	for iter_46_0, iter_46_1 in pairs(arg_46_0.countDowns_ or {}) do
		iter_46_1:stop()
	end

	if arg_46_0.dialogHandler then
		var_0_1.unscheduleGlobal(arg_46_0.dialogHandler)
	end

	if arg_46_0.sound_ then
		audio.stopSound(arg_46_0.sound_)
	end

	xyd.WindowManager.get():closeWindow("alert")
	var_0_0.super.didClose()
end

function var_0_0.layout(arg_47_0)
	arg_47_0.timeLabel = arg_47_0:nodeByName(var_0_0.TIME)

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_47_0):addEventListener(xyd.event.SHOP_DIALOG, function(arg_48_0)
		arg_47_0.shopList:refreshList()
		arg_47_0:resetSelect()

		if arg_47_0.shopType_ ~= xyd.ShopType.SKIN then
			arg_47_0:showDialog(arg_48_0.messageType)
		end
	end)

	if arg_47_0.avatarNode then
		arg_47_0.avatarNode:removeSelf()
	end

	arg_47_0.avatarNode = display.newNode()

	arg_47_0.avatarNode:setAnchorPoint(cc.p(0.5, 0.5))
	arg_47_0.avatarNode:setPosition(165, 300)
	arg_47_0.avatarNode:setContentSize(300, 300)
	arg_47_0.avatarNode:addTo(arg_47_0)
	arg_47_0.avatarNode:setTouchEnabled(true)
	arg_47_0.avatarNode:setLocalZOrder(1000)
	arg_47_0.avatarNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_49_0)
		if arg_49_0.name == "began" then
			return true
		elseif arg_49_0.name == "ended" then
			arg_47_0:showDialog()
		end
	end)
	arg_47_0:resetSelect()
end

function var_0_0.resetSelect(arg_50_0)
	for iter_50_0, iter_50_1 in pairs(arg_50_0.selectTotalPrice) do
		arg_50_0.selectTotalPrice[iter_50_0] = 0
	end

	for iter_50_2, iter_50_3 in pairs(arg_50_0.selectState) do
		arg_50_0.selectState[iter_50_2] = 0
	end

	for iter_50_4, iter_50_5 in pairs(arg_50_0.itemList) do
		arg_50_0.itemList[iter_50_4].checkgou:setVisible(false)
		arg_50_0.itemList[iter_50_4].bgSelect:setVisible(false)
	end

	dump("1111111")
	arg_50_0:updateSelectState()
end

function var_0_0.updateView(arg_51_0, arg_51_1)
	arg_51_1 = arg_51_1 or arg_51_0.shopType_

	if arg_51_0.shop_:isLoaded(arg_51_1) then
		arg_51_0:updateView_(arg_51_1)
	else
		arg_51_0:loadShopInfo(arg_51_1)
	end

	arg_51_0:resetSelect()
end

function var_0_0.updateView_(arg_52_0, arg_52_1)
	arg_52_0.shopType_ = arg_52_1 or arg_52_0.shopType_

	arg_52_0:resetScrollNode()
	arg_52_0:updateItems()
	arg_52_0:checkShowDialog()
	arg_52_0:updateLeftHeroImg()
	arg_52_0:updateItemVisible(true)
	arg_52_0.shopList:refreshList()
	arg_52_0:updateAssetsContainer()

	if arg_52_0.shop_:isCountDown(arg_52_0.shopType_) == true then
		arg_52_0.timeLabel:setString("")
		arg_52_0:addTimer()
	else
		local var_52_0 = xyd.tables.shop:refreshTime(arg_52_0.shopType_)

		if var_52_0 then
			local var_52_1 = tonumber(xyd.ServerTime.get():getSecondsOfDay())
			local var_52_2
			local var_52_3

			for iter_52_0, iter_52_1 in pairs(var_52_0) do
				if var_52_1 < iter_52_1 then
					var_52_2 = true
					var_52_3 = iter_52_1

					break
				end
			end

			if var_52_2 == true then
				local var_52_4 = math.floor(var_52_3 / 3600)

				arg_52_0.timeLabel:setString(var_0_6:translation("SHOP_AUTO_REFRESH_TODAY") .. " " .. var_52_4 .. ":00")
			else
				local var_52_5 = var_52_0[1]
				local var_52_6 = math.floor(var_52_5 / 3600)

				arg_52_0.timeLabel:setString(var_0_6:translation("SHOP_AUTO_REFRESH_TOMORROW") .. " " .. var_52_6 .. ":00")
			end
		else
			arg_52_0.timeLabel:setString("")
		end
	end

	arg_52_0:nodeByName("dialog_img"):setVisible(true)
	arg_52_0:nodeByName("dialog"):setVisible(true)
	arg_52_0:nodeByName("pic_container"):setVisible(true)
	arg_52_0:nodeByName("skin_container"):setVisible(false)
	arg_52_0:nodeByName("refresh_button"):setVisible(true)
	arg_52_0.avatarNode:setVisible(true)
end

function var_0_0.updateLeftHeroImg(arg_53_0, arg_53_1)
	arg_53_0:nodeByName("pic_container"):removeAllChildren()

	local var_53_0 = xyd.tables.shop:isDynamic(arg_53_0.shopType_)
	local var_53_1 = xyd.tables.shop:location(arg_53_0.shopType_)
	local var_53_2 = xyd.tables.shop:scaling(arg_53_0.shopType_)
	local var_53_3 = xyd.tables.shop:isFlip(arg_53_0.shopType_)

	if var_53_0 == 1 then
		local var_53_4 = xyd.tables.shop:dynamicImagePath(arg_53_0.shopType_)

		xyd.EffectLoader.new(var_53_4, 3, var_53_2, {
			x = var_53_1.x,
			y = var_53_1.y
		}, var_53_3):addTo(arg_53_0:nodeByName("pic_container"))
	else
		local var_53_5 = xyd.tables.shop:imagePath(arg_53_0.shopType_, arg_53_1)
		local var_53_6 = xyd.AssetLoader.get():loadSprite(var_53_5)

		var_53_6:addTo(arg_53_0:nodeByName("pic_container"))
		var_53_6:setAnchorPoint(cc.p(0, 0))
		var_53_6:setPosition(var_53_1)
		var_53_6:setScale(var_53_2)
	end
end

function var_0_0.showDialog(arg_54_0, arg_54_1)
	if arg_54_0.dialogHandler then
		var_0_1.unscheduleGlobal(arg_54_0.dialogHandler)
	end

	arg_54_0:nodeByName("dialog"):removeAllChildren()

	if arg_54_0.shopType_ == xyd.ShopType.SKIN then
		return
	end

	local var_54_0
	local var_54_1
	local var_54_2

	if arg_54_1 == xyd.ShopMessageType.BUY then
		var_54_0, var_54_1, var_54_2 = var_0_7:dialogBuy(arg_54_0.shopType_)
	elseif arg_54_1 == xyd.ShopMessageType.SOLD_OUT then
		var_54_0, var_54_1, var_54_2 = var_0_7:dialogSoldOut(arg_54_0.shopType_)
	else
		var_54_0, var_54_1, var_54_2 = var_0_7:dialogClick(arg_54_0.shopType_)
	end

	xyd.AssetDownload.get():downloadResByPath(var_54_1, function()
		return
	end)

	if var_54_2 and var_54_2 > 0 then
		arg_54_0.player_:playHeroSound(var_54_1, var_54_2)
	end

	arg_54_0:updateDialogMessage(var_54_0)

	arg_54_0.dialogHandler = var_0_1.performWithDelayGlobal(function()
		if arg_54_0.dialog ~= nil and arg_54_0.dialogBg ~= nil then
			arg_54_0.dialog:setVisible(false)
			arg_54_0.dialogBg:setVisible(false)
		end
	end, 6)
end

function var_0_0.showSpecialDialog(arg_57_0, arg_57_1, arg_57_2)
	if arg_57_0.specialDialogHandler then
		var_0_1.unscheduleGlobal(arg_57_0.specialDialogHandler)
	end

	arg_57_0:nodeByName("dialog"):removeAllChildren()

	if arg_57_0.shopSubType == var_0_11.MAIN_SHOP then
		arg_57_1 = false
	elseif arg_57_0.shopSubType == var_0_11.SUB_SHOP then
		arg_57_1 = true
	end

	local var_57_0 = var_0_7:specialDialog(arg_57_0.shopType_, arg_57_1)
	local var_57_1 = var_0_7:specialSound(arg_57_0.shopType_, arg_57_1)

	if arg_57_0.sound_ then
		audio.stopSound(arg_57_0.sound_)
	end

	xyd.AssetDownload.get():downloadResByPath(var_57_1, function()
		return
	end)

	if var_57_1 and var_57_1 ~= 0 then
		arg_57_0.sound_ = audio.playSound(var_57_1, false)
	end

	arg_57_0:updateDialogMessage(var_57_0)

	if not arg_57_2 then
		arg_57_0.specialDialogHandler = var_0_1.performWithDelayGlobal(function()
			if arg_57_0.dialog ~= nil and arg_57_0.dialogBg ~= nil then
				arg_57_0.dialog:setVisible(false)
				arg_57_0.dialogBg:setVisible(false)
			end
		end, 6)
	end
end

function var_0_0.updateDialogMessage(arg_60_0, arg_60_1)
	local var_60_0 = {
		size = 24,
		color = cc.c3b(66, 91, 95)
	}
	local var_60_1 = xyd.AssetLoader.get():loadLabel(var_60_0)

	var_60_1:setMaxLineWidth(260)
	var_60_1:setString(arg_60_1)
	var_60_1:setAnchorPoint(cc.p(0.5, 1))
	var_60_1:addTo(arg_60_0:nodeByName("dialog"))
	arg_60_0:nodeByName("dialog"):setVisible(true)
	arg_60_0:nodeByName("dialog_img"):setVisible(true)

	local var_60_2 = var_60_1:getContentSize().height
	local var_60_3 = var_60_1:getContentSize().width

	arg_60_0:nodeByName("dialog_img"):width(var_60_3 + 65)
	arg_60_0:nodeByName("dialog_img"):height(var_60_2 + 70)

	local var_60_4, var_60_5 = arg_60_0:nodeByName("dialog"):getPosition()
	local var_60_6 = arg_60_0:nodeByName("dialog"):convertToNodeSpace(arg_60_0:nodeByName("dialog"):getParent():convertToWorldSpace(cc.p(var_60_4, var_60_5)))

	var_60_1:setPosition(var_60_6.x, var_60_6.y - 2)
end

function var_0_0.addTimer(arg_61_0)
	local var_61_0 = arg_61_0.shop_:getLastTime(arg_61_0.shopType_)

	if var_61_0 > 0 and var_61_0 < xyd.TMP_SHOP_LAST_TIME and arg_61_0.countDowns_[arg_61_0.shopType_] == nil then
		local var_61_1 = xyd.TMP_SHOP_LAST_TIME - var_61_0
		local var_61_2 = xyd.secondsToString(var_61_1)

		arg_61_0.timeLabel:setString(var_0_6:translation("TRADER_STAY_TIME") .. var_61_2)
		print("last time: " .. var_61_0)

		local var_61_3 = import("app.common.CountDown").new(var_61_1)

		arg_61_0.countDowns_[arg_61_0.shopType_] = var_61_3

		var_61_3:start(handler(arg_61_0.shopType_, handler(arg_61_0, arg_61_0.updateCountDownLabel)))
	end
end

function var_0_0.updateCountDownLabel(arg_62_0, arg_62_1)
	local var_62_0 = arg_62_0.countDowns_[arg_62_1].seconds_

	if var_62_0 <= 0 then
		arg_62_0.countDowns_[arg_62_1]:stop()
		arg_62_0.shop_:closeShop(arg_62_1)
		arg_62_0:loadOpenList()
		arg_62_0:updateView()
	else
		local var_62_1 = xyd.secondsToString(var_62_0)

		if arg_62_0.shopType_ == arg_62_1 then
			arg_62_0.timeLabel:setString(var_0_6:translation("TRADER_STAY_TIME") .. var_62_1)
		end
	end
end

function var_0_0.buttonHandler(arg_63_0, arg_63_1, arg_63_2, arg_63_3)
	if arg_63_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_63_2)
		arg_63_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.wav", false)

		if arg_63_1 then
			arg_63_1(arg_63_2, arg_63_3)
		end
	elseif arg_63_3 == ccui.TouchEventType.began then
		local var_63_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_63_1 = cc.RepeatForever:create(var_63_0)

		arg_63_2:runAction(var_63_1)

		return true
	elseif arg_63_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_63_2)
		arg_63_2:setScale(1)
	end
end

function var_0_0.refreshCallBack(arg_64_0)
	arg_64_0.shop_:refreshShop({
		shop_type = arg_64_0.shopType_
	}, function(arg_65_0)
		if arg_65_0 == xyd.error.OK then
			arg_64_0:updateItems()
			arg_64_0:resetSelect()
		end
	end)
end

function var_0_0.resetScrollNode(arg_66_0)
	if #arg_66_0.shop_.items_[arg_66_0.shopType_] / 2 <= 3 then
		arg_66_0.scrollNodePosX = 10
	else
		arg_66_0.scrollNodePosX = 0
	end

	arg_66_0.scrollNodePosY = 0
end

function var_0_0.updateItemVisible(arg_67_0, arg_67_1)
	arg_67_0.ItemPanel:setVisible(arg_67_1)
	arg_67_0:nodeByName("space_sub_shop"):setVisible(not arg_67_1)
	arg_67_0:updateCost()

	local var_67_0 = xyd.tables.shop:refreshType(arg_67_0.shopType_)
	local var_67_1, var_67_2 = arg_67_0:getShopCostInfo(arg_67_0.shopType_)

	if not var_67_1 or var_67_0 == 2 then
		var_67_1 = "crystal"
		var_67_2 = "crystal"
	end

	if var_67_1 and var_67_2 then
		local var_67_3 = xyd.tables.ecoType:getEcoPath(var_67_2)
		local var_67_4 = xyd.AssetLoader.get():loadSprite(var_67_3)
		local var_67_5 = arg_67_0:nodeByName("img_currency")

		var_67_5:removeAllChildren()
		xyd.displaySpriteOnContainer(var_67_4, var_67_5, false)
	end

	arg_67_0:nodeByName("fresh_container"):setVisible(arg_67_1)

	if arg_67_1 then
		arg_67_0.shopSubType = var_0_11.MAIN_SHOP
	else
		arg_67_0.shopSubType = var_0_11.SUB_SHOP
	end
end

function var_0_0.updateCost(arg_68_0)
	local var_68_0 = arg_68_0.shop_.refreshTimes_[arg_68_0.shopType_]
	local var_68_1 = xyd.tables.refreshCost:shopRefreshCost(var_68_0 + 1, arg_68_0.shopType_)

	arg_68_0:nodeByName("cost_txt"):setString(var_68_1)
end

function var_0_0.changeShop(arg_69_0)
	if arg_69_0.shopType_ ~= xyd.ShopType.SPACE then
		arg_69_0:showDialog()

		return
	end

	if arg_69_0.shop_.hotHero_[arg_69_0.shopType_].hot_hero then
		if arg_69_0.shopSubType == var_0_11.MAIN_SHOP then
			arg_69_0:updateItemVisible(false)
			arg_69_0:updateLeftHeroImg(true)
			arg_69_0:initSubSpaceShop()
			arg_69_0:showSpecialDialog(false, true)
		else
			arg_69_0:updateItemVisible(true)
			arg_69_0:updateLeftHeroImg()
			arg_69_0:showSpecialDialog(true, true)
		end
	else
		arg_69_0:showDialog()

		return
	end
end

function var_0_0.createSubShopItem(arg_70_0, arg_70_1, arg_70_2)
	local var_70_0 = display.newNode()
	local var_70_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/shop_window/sub_shop_item.csb")
	local var_70_2 = var_70_1:getChildByName("container")
	local var_70_3 = arg_70_1.is_awarded
	local var_70_4 = arg_70_1.cost_stone
	local var_70_5 = xyd.tables.misc.shopExclusiveCostArray
	local var_70_6 = xyd.split(var_0_4:translation("SHOP_TODAY_HOT_NAMES"), ":")

	var_70_2:getChildByName("price"):setString(xyd.tables.item:name(var_70_4[arg_70_2]) .. "*" .. var_70_5[arg_70_2])
	var_70_2:getChildByName("price"):setScale(0.8)

	local var_70_7, var_70_8 = var_70_2:getChildByName("price"):getPosition()

	var_70_2:getChildByName("price"):setPosition(var_70_7, var_70_8)
	var_70_2:getChildByName("name"):setString(var_70_6[arg_70_2])
	xyd.setItemBorder(var_70_2:getChildByName("img_currency"), var_70_4[arg_70_2], false, false)

	local var_70_9, var_70_10 = var_70_2:getChildByName("img_currency"):getPosition()

	var_70_2:getChildByName("img_currency"):setPosition(var_70_9 - 20, var_70_10)

	local function var_70_11()
		if arg_70_0.backpack_:getItemNumByID(var_70_4[arg_70_2]) < var_70_5[arg_70_2] then
			var_70_2:getChildByName("price"):setColor(cc.c3b(255, 0, 0))
		end

		var_70_2:getChildByName("image_pos"):removeAllChildren()

		if var_70_3[arg_70_2] == 1 then
			local var_71_0 = xyd.AssetLoader.get():loadSprite("windows/shop_window/sub_item_gray_" .. arg_70_2 .. ".png")

			var_71_0:addTo(var_70_2:getChildByName("image_pos"))
			var_70_2:getChildByName("sell_out"):setVisible(true)
			var_71_0:setScale(0.7)
			var_70_1:setTouchEnabled(false)
		else
			local var_71_1 = xyd.AssetLoader.get():loadSprite("windows/shop_window/sub_item_" .. arg_70_2 .. ".png")

			var_71_1:addTo(var_70_2:getChildByName("image_pos"))
			var_70_2:getChildByName("sell_out"):setVisible(false)
			var_71_1:setScale(0.7)
			var_70_1:setTouchEnabled(true)
		end
	end

	var_70_11()
	var_70_1:setTouchSwallowEnabled(false)
	var_70_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_72_0)
		if arg_72_0.name == "began" then
			return true
		elseif arg_72_0.name == "moved" then
			return true
		elseif arg_72_0.name == "ended" then
			if arg_70_0.backpack_:getItemNumByID(var_70_4[arg_70_2]) < var_70_5[arg_70_2] then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_6:translation("TRAVEL_SHOP_HOT_TIP_3")
				})

				return
			end

			local function var_72_0()
				local var_73_0 = {
					shop_type = xyd.ShopType.SPACE,
					index = arg_70_2
				}

				arg_70_0.shop_:buyExclusiveShop(var_73_0, function(arg_74_0, arg_74_1)
					if arg_74_0 == xyd.error.OK then
						local var_74_0 = {
							items = arg_74_1.items
						}

						for iter_74_0, iter_74_1 in ipairs(arg_74_1.items) do
							arg_70_0.backpack_:addItemsByID(tonumber(iter_74_1.item_id), tonumber(iter_74_1.item_num))
						end

						local var_74_1 = arg_70_0.backpack_:getItemNumByID(var_70_4[arg_70_2]) - var_70_5[arg_70_2]

						arg_70_0.backpack_:setItemNumByID(var_70_4[arg_70_2], var_74_1)

						arg_70_0.shop_.hotHero_[arg_70_0.shopType_].is_awarded[arg_70_2] = 1

						var_70_11()
						xyd.WindowManager.get():openWindow("exclusive_buy_esult", var_74_0)
					end
				end)
			end

			local var_72_1 = {
				callback = var_72_0,
				item_num = var_70_5[arg_70_2],
				item_id = var_70_4[arg_70_2],
				index = arg_70_2
			}

			xyd.WindowManager.get():openWindow("shop_confirm", var_72_1)
		end
	end)
	var_70_1:addTo(var_70_0)
	var_70_1:setAnchorPoint(cc.p(0, 0))
	var_70_0:setContentSize(var_70_2:getContentSize())
	var_70_1:setName("source")

	return var_70_0
end

function var_0_0.initSubSpaceShop(arg_75_0)
	if arg_75_0.shopType_ ~= xyd.ShopType.SPACE then
		return
	end

	local var_75_0 = arg_75_0:nodeByName("space_sub_shop")

	var_75_0:getChildByName("sub_item_pos"):removeAllChildren()

	local var_75_1 = arg_75_0.shop_.hotHero_[arg_75_0.shopType_]

	if not var_75_1 then
		return
	end

	local var_75_2 = xyd.tables.misc.shopExclusiveCostArray

	for iter_75_0 = 1, #var_75_2 do
		local var_75_3 = arg_75_0:createSubShopItem(var_75_1, iter_75_0)

		var_75_3:addTo(var_75_0:getChildByName("sub_item_pos"))
		var_75_3:setPosition(cc.p(219 * (iter_75_0 - 1), 0))
	end

	local var_75_4 = var_75_1.hot_hero
	local var_75_5 = var_0_2.new()

	var_75_5 = arg_75_0.player_:getHeroIgnoreAwaken(var_75_4) or var_75_5:populateWithTableID(var_75_4)

	var_75_0:getChildByName("sub_avatar"):removeAllChildren()
	xyd.setAvatarBorder(var_75_5, var_75_0:getChildByName("sub_avatar"))
	var_75_0:getChildByName("hot_name_txt"):setString(xyd.tables.hero:name(var_75_4))
	var_75_0:getChildByName("today_hot_tip"):setString(var_0_4:translation("TRAVEL_SHOP_HOT_TIP"))
end

function var_0_0.checkShowDialog(arg_76_0)
	if arg_76_0.shopType_ ~= xyd.ShopType.SPACE then
		arg_76_0:showDialog()

		return
	end

	if arg_76_0.shop_.hotHero_[arg_76_0.shopType_].hot_hero then
		arg_76_0:showSpecialDialog(true, true)
	else
		arg_76_0:showDialog()
	end
end

return var_0_0
