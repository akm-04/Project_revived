local var_0_0 = class("ActivityFishingShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityFishingShop
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.ecoType
local var_0_7 = var_0_4:getValue("activity_fishing_coin_item_id")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.buyTimes = arg_1_2.info.buy_times
	arg_1_0.lev = arg_1_2.lev
end

function var_0_0.willOpen(arg_2_0)
	local var_2_0 = {
		ecoCount = 3,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_7,
			2,
			1
		},
		ecoIcons = {
			"windows/activities/1226/fishing/coin.png",
			-1,
			-1
		}
	}

	arg_2_0:addTopSidebar(var_2_0)
	arg_2_0:layout()
	arg_2_0:updateLeftHeroImg()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("type_list_bg"):setVisible(false)
	arg_3_0:nodeByName("cost_txt"):setVisible(false)
	arg_3_0:nodeByName("refresh_button"):setVisible(false)
	arg_3_0:nodeByName("txt_time"):setVisible(false)

	local var_3_0 = arg_3_0:nodeByName("list"):getContentSize()

	arg_3_0:nodeByName("list"):setPositionY(0)
	arg_3_0:nodeByName("list"):setContentSize(var_3_0.width, var_3_0.height + 70)

	arg_3_0.list = cc.ui.UITableView.new({
		size = cc.size(var_3_0.width, var_3_0.height + 70),
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(var_3_0.width, 260)
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0:loadList()

	arg_3_0.avatarNode = display.newNode()

	arg_3_0.avatarNode:setAnchorPoint(cc.p(0.5, 0.5))
	arg_3_0.avatarNode:setPosition(165, 300)
	arg_3_0.avatarNode:setContentSize(300, 300)
	arg_3_0.avatarNode:addTo(arg_3_0)
	arg_3_0.avatarNode:setTouchEnabled(true)
	arg_3_0.avatarNode:setLocalZOrder(1000)
	arg_3_0.avatarNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0:showDialog()
		end
	end)

	arg_3_0.dialog = arg_3_0:nodeByName("dialog")
	arg_3_0.dialogBg = arg_3_0:nodeByName("dialog_img")

	arg_3_0:showDialog()
end

function var_0_0.getShopItems(arg_5_0)
	arg_5_0.shopItems = {}

	local var_5_0 = {}

	for iter_5_0 = 1, var_0_3:getItemNum() do
		local var_5_1 = var_0_3:buyLimit(iter_5_0)
		local var_5_2 = var_5_1 - arg_5_0.buyTimes[iter_5_0]

		if var_5_1 < 0 or var_5_2 > 0 then
			arg_5_0:addShopItem(iter_5_0)
		else
			table.insert(var_5_0, iter_5_0)
		end
	end

	for iter_5_1, iter_5_2 in ipairs(var_5_0) do
		arg_5_0:addShopItem(iter_5_2)
	end
end

function var_0_0.addShopItem(arg_6_0, arg_6_1)
	local var_6_0 = var_0_3:needItem(arg_6_1)

	if var_6_0 and var_6_0 > 0 and arg_6_0.backpack:getItemNumByID(var_6_0) <= 0 then
		return
	end

	table.insert(arg_6_0.shopItems, arg_6_1)
end

function var_0_0.loadList(arg_7_0)
	arg_7_0:getShopItems()
	arg_7_0.list:removeAllItems()

	for iter_7_0 = 1, math.ceil(#arg_7_0.shopItems / 3) do
		local var_7_0 = arg_7_0.list:newItem()
		local var_7_1 = arg_7_0:createContent(iter_7_0)

		var_7_0:addContent(var_7_1)
		var_7_0:setItemSize(729, 260)
		arg_7_0.list:addItem(var_7_0)
	end

	arg_7_0.list:refreshList()
end

function var_0_0.createContent(arg_8_0, arg_8_1)
	local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/shop_window/shop_line_item.csb")

	for iter_8_0 = 1, 3 do
		local var_8_1 = arg_8_0.shopItems[(arg_8_1 - 1) * 3 + iter_8_0]
		local var_8_2 = var_0_3:itemID(var_8_1)

		if var_8_2 == 0 then
			break
		end

		local var_8_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1226/fishing/shop_item.csb")
		local var_8_4 = var_8_3:getChildByName("container")
		local var_8_5 = var_0_3:buyLimit(var_8_1)
		local var_8_6 = -1
		local var_8_7 = var_8_4:getContentSize()
		local var_8_8 = arg_8_0:checkLock(var_8_1)

		xyd.setItemBorder(var_8_4:getChildByName("img_icon"), var_8_2)

		local var_8_9 = var_0_5:name(var_8_2)

		var_8_4:getChildByName("name"):setString(var_8_9)

		local var_8_10 = var_0_3:costType(var_8_1)
		local var_8_11 = var_0_6:getEcoPathByID(var_8_10)
		local var_8_12

		if var_8_11 then
			var_8_12 = xyd.AssetLoader.get():loadSprite(var_8_11)
		else
			var_8_12 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fishing/coin.png")
		end

		var_8_12:setScale(0.8)
		var_8_12:setNormalizedPosition(cc.p(0.5, 0.5))
		var_8_4:getChildByName("img_currency"):addChild(var_8_12)
		var_8_4:getChildByName("price"):setString(var_0_3:price(var_8_1))

		if var_8_8 then
			var_8_4:getChildByName("buy_limit_bg"):setVisible(true)
			var_8_4:getChildByName("buy_limit_txt"):setVisible(true)
			var_8_4:getChildByName("mask"):setVisible(true)
			var_8_4:getChildByName("buy_limit_txt"):setString(var_8_8)
		elseif var_8_5 > 0 then
			var_8_4:getChildByName("buy_limit_bg"):setVisible(true)
			var_8_4:getChildByName("buy_limit_txt"):setVisible(true)

			if var_0_3:dailyRefresh(var_8_1) == 1 then
				var_8_4:getChildByName("buy_limit_txt"):setString(string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_21"), arg_8_0.buyTimes[var_8_1], var_0_3:buyLimit(var_8_1)))
			else
				var_8_4:getChildByName("buy_limit_txt"):setString(string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_22"), arg_8_0.buyTimes[var_8_1], var_0_3:buyLimit(var_8_1)))
			end

			var_8_6 = var_8_5 - arg_8_0.buyTimes[var_8_1]
		end

		if var_8_6 == 0 then
			var_8_4:getChildByName("block_bg"):setVisible(true)
		end

		var_8_4:getChildByName("img_icon"):setTouchEnabled(false)
		var_8_4:addTouchEventListener(function(arg_9_0, arg_9_1)
			xyd.buttonScaleAnim(arg_9_0, arg_9_1)

			if arg_9_1 == ccui.TouchEventType.ended then
				if arg_8_0.scrollViewMoved_ or var_8_8 then
					return
				end

				if var_8_6 == 0 then
					arg_8_0:showDialog(xyd.ShopMessageType.SOLD_OUT)

					return
				end

				local var_9_0

				if var_8_10 == 1 then
					var_9_0 = arg_8_0.selfPlayer.mana
				elseif var_8_10 == 2 then
					var_9_0 = arg_8_0.selfPlayer.crystal
				else
					var_9_0 = arg_8_0.backpack:getItemNumByID(var_0_7)
				end

				local var_9_1 = math.floor(var_9_0 / var_0_3:price(var_8_1))

				if var_8_6 and var_8_6 >= 0 then
					var_9_1 = math.min(var_9_1, var_8_6)
				else
					var_8_6 = -1
				end

				local var_9_2 = {
					item_num = 1,
					idx = var_8_1,
					item_id = var_8_2,
					max_num = var_9_1,
					left_num = var_8_6,
					price = var_0_3:price(var_8_1),
					cost_type = var_8_10,
					callback = handler(arg_8_0, arg_8_0.buyCallback)
				}

				xyd.WindowManager.get():openWindow("activity_fishing_shop_detail", var_9_2)
			end
		end)
		var_8_3:setPosition(55 + (iter_8_0 - 1) * 211, 14)
		var_8_0:getChildByName("container"):addChild(var_8_3)
	end

	return var_8_0
end

function var_0_0.checkLock(arg_10_0, arg_10_1)
	local var_10_0 = var_0_3:needLev(arg_10_1)

	if var_10_0 > arg_10_0.lev then
		return string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_20"), var_10_0)
	end
end

function var_0_0.buyCallback(arg_11_0, arg_11_1)
	arg_11_0.buyTimes[arg_11_1.id] = arg_11_0.buyTimes[arg_11_1.id] + arg_11_1.num

	arg_11_0:loadList()

	for iter_11_0 = 1, 3 do
		arg_11_0:updateEcoByIdx(iter_11_0)
	end

	local var_11_0 = xyd.WindowManager.get():getWindow("activity_fishing_main")

	if var_11_0 and not tolua.isnull(var_11_0) then
		var_11_0:updateEco()
		var_11_0:updateBaitNum()
	end

	arg_11_0:showDialog(xyd.ShopMessageType.BUY)
end

function var_0_0.updateEcoByIdx(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0:nodeByName("eco_sidebar")
	local var_12_1 = var_12_0:nodeByName("txt_eco_val_" .. arg_12_1):getString()
	local var_12_2

	if arg_12_1 == 1 then
		var_12_2 = xyd.num2ThousandsStr(arg_12_0.backpack:getItemNumByID(var_0_7))
	elseif arg_12_1 == 2 then
		var_12_2 = xyd.num2ThousandsStr(arg_12_0.selfPlayer.crystal)
	else
		var_12_2 = xyd.num2ThousandsStr(arg_12_0.selfPlayer.mana)
	end

	if var_12_1 == var_12_2 then
		return
	end

	var_12_0:nodeByName("txt_eco_val_" .. arg_12_1):setString(var_12_2)

	local var_12_3 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_12_4 = cc.Spawn:create(var_12_3)

	var_12_0:nodeByName("txt_eco_val_" .. arg_12_1):runAction(var_12_4)
end

function var_0_0.updateLeftHeroImg(arg_13_0)
	arg_13_0:nodeByName("pic_container"):removeAllChildren()

	local var_13_0 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(40001228), nil, nil, xyd.DefaultImageType.HOME_CARD)

	var_13_0:addTo(arg_13_0:nodeByName("pic_container"))
	var_13_0:setAnchorPoint(cc.p(0, 0))
	var_13_0:setPosition(-320, 0)
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevY_ = arg_14_1.y
	elseif arg_14_1.name == "moved" and 5 <= math.abs(arg_14_1.y - arg_14_0.prevY_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

function var_0_0.showDialog(arg_15_0, arg_15_1)
	if arg_15_0.dialogHandler then
		var_0_1.unscheduleGlobal(arg_15_0.dialogHandler)
	end

	arg_15_0:nodeByName("dialog"):removeAllChildren()

	local var_15_0

	if arg_15_1 == xyd.ShopMessageType.BUY then
		var_15_0 = var_0_2:translation("ACTIVITY_FISHING_TEXT_18")
	elseif arg_15_1 == xyd.ShopMessageType.SOLD_OUT then
		var_15_0 = var_0_2:translation("ACTIVITY_FISHING_TEXT_19")
	else
		local var_15_1 = var_0_2:translation("ACTIVITY_FISHING_TEXT_17")
		local var_15_2 = xyd.split(var_15_1, "\n")

		var_15_0 = var_15_2[math.random(#var_15_2)]
	end

	arg_15_0:updateDialogMessage(var_15_0)

	arg_15_0.dialogHandler = var_0_1.performWithDelayGlobal(function()
		if arg_15_0.dialog ~= nil and arg_15_0.dialogBg ~= nil then
			arg_15_0.dialog:setVisible(false)
			arg_15_0.dialogBg:setVisible(false)
		end
	end, 6)
end

function var_0_0.updateDialogMessage(arg_17_0, arg_17_1)
	local var_17_0 = {
		size = 24,
		color = cc.c3b(66, 91, 95)
	}
	local var_17_1 = xyd.AssetLoader.get():loadLabel(var_17_0)

	var_17_1:setMaxLineWidth(260)
	var_17_1:setString(arg_17_1)
	var_17_1:setAnchorPoint(cc.p(0.5, 1))
	var_17_1:addTo(arg_17_0:nodeByName("dialog"))
	arg_17_0:nodeByName("dialog"):setVisible(true)
	arg_17_0:nodeByName("dialog_img"):setVisible(true)

	local var_17_2 = var_17_1:getContentSize().height
	local var_17_3 = var_17_1:getContentSize().width

	arg_17_0:nodeByName("dialog_img"):width(var_17_3 + 65)
	arg_17_0:nodeByName("dialog_img"):height(var_17_2 + 70)

	local var_17_4, var_17_5 = arg_17_0:nodeByName("dialog"):getPosition()
	local var_17_6 = arg_17_0:nodeByName("dialog"):convertToNodeSpace(arg_17_0:nodeByName("dialog"):getParent():convertToWorldSpace(cc.p(var_17_4, var_17_5)))

	var_17_1:setPosition(var_17_6.x, var_17_6.y - 2)
end

return var_0_0
