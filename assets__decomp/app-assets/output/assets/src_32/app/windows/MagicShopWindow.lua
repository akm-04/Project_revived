local var_0_0 = class("MagicShopItemCell", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.magicShop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.MAGIC_SHOP)
	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/shop_item.json"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0.tableID_ = arg_4_1

	arg_4_0:layout()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.SHOP_MAGIC_BUY, function(arg_5_0)
		if arg_4_0.tableID_ == arg_5_0.params.pos then
			arg_4_0:contentView():nodeByName("no_open"):setVisible(false)
			arg_4_0:contentView():nodeByName("already_buy_bg"):setVisible(true)
			arg_4_0:contentView():nodeByName("item_bg"):setVisible(false)
			arg_4_0:contentView():nodeByName("lock_bg"):setVisible(false)
			arg_4_0.headContainer:removeAllChildren()
		end
	end)
end

function var_0_0.onClick(arg_6_0)
	if arg_6_0.magicShop_.items[arg_6_0.tableID_].is_lock == 1 then
		local var_6_0 = ""
		local var_6_1 = xyd.tables.magicShop:price(arg_6_0.tableID_)

		if xyd.tables.magicShop:currency(arg_6_0.tableID_) == xyd.ItemType.MANA then
			var_6_0 = string.format(xyd.tables.translation:translation("SHOP_UNLOCK_PROMPT"), tostring(var_6_1), xyd.tables.translation:translation("MANA"))

			arg_6_0:setSelected(true)
		elseif xyd.tables.magicShop:currency(arg_6_0.tableID_) == xyd.ItemType.CRYSTAL then
			var_6_0 = string.format(xyd.tables.translation:translation("SHOP_UNLOCK_PROMPT"), tostring(var_6_1), xyd.tables.translation:translation("CRYSTAL"))

			arg_6_0:setSelected(true)
		end

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
			if arg_6_0.tableID_ - 1 > 1 and arg_6_0.magicShop_.items[arg_6_0.tableID_ - 1].is_lock == 1 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("UNLOCK_TIP"), nil, nil, nil, arg_6_0.colorMode)
			elseif xyd.tables.magicShop:currency(arg_6_0.tableID_) == xyd.ItemType.MANA and arg_6_0.player_.mana < var_6_1 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("LACK_OF_MANA"), function()
					xyd.WindowManager.get():openWindow("guide_market", {
						type = 1
					})
				end, nil, nil, arg_6_0.colorMode)
			elseif xyd.tables.magicShop:currency(arg_6_0.tableID_) == xyd.ItemType.CRYSTAL and arg_6_0.player_.crystal < var_6_1 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("LACK_OF_CRYSTAL"), function()
					xyd.WindowManager.get():openWindow("guide_market", {
						type = 2
					})
				end, nil, nil, arg_6_0.colorMode)
			else
				arg_6_0.magicShop_:unlock(function(arg_10_0)
					if arg_10_0 == xyd.error.OK then
						arg_6_0:layout()
						arg_6_0:setSelected(true)
					end
				end)
			end
		end, nil, 0, arg_6_0.colorMode)
	else
		xyd.WindowManager.get():openWindow("shop_item_details", {
			table_id = arg_6_0.tableID_
		})
		arg_6_0:setSelected(true)
	end
end

function var_0_0.setSelected(arg_11_0, arg_11_1)
	arg_11_0:contentView():nodeByName("selected_bg"):setVisible(arg_11_1)
end

function var_0_0.layout(arg_12_0)
	arg_12_0:contentView():nodeByName("no_open_label"):setString(xyd.tables.translation:translation("SHOP_LOCK"))
	arg_12_0:contentView():nodeByName("already_buy_label"):setString(xyd.tables.translation:translation("BOUGHT"))
	arg_12_0:setSelected(false)

	local var_12_0 = arg_12_0.magicShop_.items[arg_12_0.tableID_]

	if var_12_0 == nil then
		return
	end

	arg_12_0.headContainer = arg_12_0:contentView():nodeByName("head_container")

	arg_12_0.headContainer:removeAllChildren()

	if var_12_0.is_lock == 1 then
		arg_12_0:contentView():nodeByName("no_open"):setVisible(true)
		arg_12_0:contentView():nodeByName("already_buy_bg"):setVisible(false)
		arg_12_0:contentView():nodeByName("item_bg"):setVisible(false)
		arg_12_0:contentView():nodeByName("lock_bg"):setVisible(true)

		if xyd.tables.magicShop:currency(arg_12_0.tableID_) == xyd.ItemType.MANA then
			arg_12_0:contentView():nodeByName("open_mana"):setVisible(true)
			arg_12_0:contentView():nodeByName("open_crystal"):setVisible(false)
		elseif xyd.tables.magicShop:currency(arg_12_0.tableID_) == xyd.ItemType.CRYSTAL then
			arg_12_0:contentView():nodeByName("open_mana"):setVisible(false)
			arg_12_0:contentView():nodeByName("open_crystal"):setVisible(true)
		end

		arg_12_0:contentView():nodeByName("open_price"):setString(xyd.tables.magicShop:price(arg_12_0.tableID_))
	elseif var_12_0.is_bought == 1 then
		arg_12_0:contentView():nodeByName("no_open"):setVisible(false)
		arg_12_0:contentView():nodeByName("already_buy_bg"):setVisible(true)
		arg_12_0:contentView():nodeByName("item_bg"):setVisible(false)
		arg_12_0:contentView():nodeByName("lock_bg"):setVisible(false)
	else
		arg_12_0:contentView():nodeByName("no_open"):setVisible(false)
		arg_12_0:contentView():nodeByName("already_buy_bg"):setVisible(false)
		arg_12_0:contentView():nodeByName("item_bg"):setVisible(true)
		arg_12_0:contentView():nodeByName("lock_bg"):setVisible(false)
		arg_12_0:contentView():nodeByName("item_price"):setString(var_12_0.price)
		arg_12_0:contentView():nodeByName("name"):setString(arg_12_0.magicShop_:getItemName(arg_12_0.tableID_))

		if arg_12_0.magicShop_:getItemIcon(arg_12_0.tableID_) then
			local var_12_1 = xyd.AssetLoader:get():loadSprite(arg_12_0.magicShop_:getItemIcon(arg_12_0.tableID_))

			if var_12_1 then
				xyd.displaySpriteOnContainer(var_12_1, arg_12_0.headContainer, true)
			end
		end

		if arg_12_0.magicShop_:getItemType(arg_12_0.tableID_) == xyd.ItemType.RUNE then
			arg_12_0.rune_ = import("app.model.Rune").new()

			arg_12_0.rune_:populate(var_12_0.item)
			arg_12_0:contentView():nodeByName("name"):setTextColor(arg_12_0.rune_:getColor())

			for iter_12_0 = 1, var_12_0.item.star do
				local var_12_2

				if var_12_0.item.power_lev == 15 then
					var_12_2 = xyd.AssetLoader.get():loadSprite("star_middle_icon_purle.png")
				else
					var_12_2 = xyd.AssetLoader.get():loadSprite("star_middle_icon_yellow.png")
				end

				var_12_2:setAnchorPoint(0, 1)
				var_12_2:pos((iter_12_0 - 1) * 10, arg_12_0.headContainer:getContentSize().height):addTo(arg_12_0.headContainer, 5)
			end
		elseif arg_12_0.magicShop_:getItemType(arg_12_0.tableID_) == xyd.ItemType.HERO then
			local var_12_3 = var_12_0.item.star
			local var_12_4 = xyd.tables.hero:rarity(var_12_0.item.table_id)

			arg_12_0:contentView():nodeByName("name"):setTextColor(xyd.heroNameColor(var_12_4))

			for iter_12_1 = 1, var_12_3 do
				local var_12_5 = xyd.AssetLoader.get():loadSprite(xyd.heroStarMiddleIconName(var_12_4))

				if var_12_5 then
					var_12_5:setAnchorPoint(0, 1)
					var_12_5:pos((iter_12_1 - 1) * 10, arg_12_0.headContainer:getContentSize().height):addTo(arg_12_0.headContainer, 5)
				end
			end
		end
	end
end

local var_0_1 = class("MagicShopWindow", import("app.common.ui.BaseWindow"))

var_0_1.ITEM_HEIGHT = 100
var_0_1.ITEM_WIDTH = 410

function var_0_1.ctor(arg_13_0, arg_13_1, arg_13_2)
	var_0_1.super.ctor(arg_13_0, arg_13_1, arg_13_2)
end

function var_0_1.sourceDelegate(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	if cc.ui.UIListView.COUNT_TAG == arg_14_2 then
		return #arg_14_0.magicShop_.items
	elseif cc.ui.UIListView.CELL_TAG == arg_14_2 then
		if arg_14_3 > #arg_14_0.magicShop_.items then
			return
		end

		local var_14_0 = arg_14_0.listView_:dequeueItem()

		if not var_14_0 then
			local var_14_1 = var_0_0.new()

			var_14_0 = arg_14_0.listView_:newItem(var_14_1)
		end

		var_14_0:getContent():setParams(arg_14_3)
		var_14_0:setItemSize(var_0_1.ITEM_WIDTH, var_0_1.ITEM_HEIGHT, false)
		var_14_0:getContent():setContentSize(var_14_0:getItemSize())

		return var_14_0
	end
end

function var_0_1.willOpen(arg_15_0, arg_15_1)
	var_0_1.super.willOpen(arg_15_0, arg_15_1)

	local var_15_0 = arg_15_0:nodeByName("list")
	local var_15_1 = var_15_0:getContentSize().width
	local var_15_2 = var_15_0:getContentSize().height
	local var_15_3 = {
		touchOnContent = true,
		async = true,
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_VCENTER,
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		viewRect = {
			x = 0,
			y = 0,
			width = var_15_1 + 1,
			height = var_15_2 - 1
		}
	}

	arg_15_0.listView_ = cc.ui.UIListView.new(var_15_3):addTo(var_15_0):onTouch(function(arg_16_0)
		if arg_16_0.name == "clicked" then
			audio.playSound("sound/button.ogg", false)

			if xyd.WindowManager.get():isWindowOpen("shop_item_details") then
				xyd.WindowManager.get():closeWindow("shop_item_details")
			end

			local var_16_0 = arg_16_0.item:getContent()

			for iter_16_0 = 1, #arg_15_0.listView_.items_ do
				arg_15_0.listView_.items_[iter_16_0]:getContent():setSelected(false)
			end

			var_16_0:onClick()
		end
	end)

	arg_15_0.listView_:setDelegate(handler(arg_15_0, arg_15_0.sourceDelegate))
	arg_15_0.listView_:setTouchEnabled(false)

	arg_15_0.magicShop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.MAGIC_SHOP)
	arg_15_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_15_0:layout()
	arg_15_0.magicShop_:loadShopInfo(function(arg_17_0)
		if arg_17_0 == xyd.error.OK then
			arg_15_0:updateCountDown()
			arg_15_0:updateList()
		end
	end)

	if not arg_15_0.player_.runeBagLoaded_ then
		arg_15_0.player_:loadRuneBag(function(arg_18_0)
			return
		end)
	end

	display.getRunningScene():setContentVisible(false)
end

function var_0_1.didOpen(arg_19_0, arg_19_1)
	var_0_1.super.didOpen(arg_19_0, arg_19_1)
end

function var_0_1.layout(arg_20_0)
	arg_20_0:nodeByName("title"):setString(xyd.tables.translation:translation("MAGIC_SHOP"))
	arg_20_0:nodeByName("price_label"):setString(xyd.tables.misc.magicShopRefreshCrystal)
	arg_20_0:nodeByName("refresh_label"):setString(xyd.tables.translation:translation("REFRESH"))
end

function var_0_1.buyItemSuc(arg_21_0, arg_21_1)
	if arg_21_0.listView_.items_ and arg_21_0.listView_.items_[arg_21_1] then
		arg_21_0.listView_.items_[arg_21_1]:getContent():layout()
	end
end

function var_0_1.soundButtonClick(arg_22_0, arg_22_1, arg_22_2)
	var_0_1.super.soundButtonClick(arg_22_0, arg_22_1, arg_22_2)

	if arg_22_1:getName() == "refresh_button" then
		arg_22_0:refreshEvent(arg_22_1, arg_22_2)
	end
end

function var_0_1.updateList(arg_23_0)
	arg_23_0.listView_:removeAllItems()
	arg_23_0.listView_:reload()

	if xyd.WindowManager.get():isWindowOpen("shop_item_details") then
		xyd.WindowManager.get():closeWindow("shop_item_details")
	end
end

function var_0_1.updateCountDown(arg_24_0)
	if arg_24_0.countDown_ then
		arg_24_0.countDown_:stop()
	end

	arg_24_0.countDown_ = import("app.common.CountDown").new(arg_24_0.magicShop_.nextRefreshTime - xyd.ServerTime.get():getServerTime())

	arg_24_0.countDown_:start(handler(arg_24_0, arg_24_0.updateCountDownLabel))
end

function var_0_1.updateCountDownLabel(arg_25_0, arg_25_1)
	local var_25_0 = math.floor(arg_25_1 / 3600)
	local var_25_1 = math.floor(arg_25_1 % 3600 / 60)
	local var_25_2 = arg_25_1 % 60
	local var_25_3 = tostring(var_25_0) .. ":"

	if var_25_1 < 10 then
		var_25_3 = var_25_3 .. "0"
	end

	local var_25_4 = var_25_3 .. tostring(var_25_1) .. ":"

	if var_25_2 < 10 then
		var_25_4 = var_25_4 .. "0"
	end

	local var_25_5 = var_25_4 .. tostring(var_25_2)

	arg_25_0:nodeByName("countdown"):setString(var_25_5)

	if arg_25_1 <= 0 then
		arg_25_0.magicShop_:loadShopInfo(function(arg_26_0)
			if arg_26_0 == xyd.error.OK then
				arg_25_0:updateList()
				arg_25_0:updateCountDown()
			end
		end)
	end
end

function var_0_1.refreshEvent(arg_27_0, arg_27_1, arg_27_2)
	if arg_27_2 == ccui.TouchEventType.ended then
		if arg_27_0.player_.crystal < xyd.tables.misc.magicShopRefreshCrystal then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("LACK_OF_CRYSTAL"), function()
				xyd.WindowManager.get():openWindow("guide_market", {
					type = 2
				})
			end, nil, nil, arg_27_0.colorMode)
		else
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(xyd.tables.translation:translation("SHOP_REFRESH_PROMPT"), tostring(xyd.tables.misc.magicShopRefreshCrystal), xyd.tables.translation:translation("CRYSTAL")), function()
				arg_27_0.magicShop_:refresh(function(arg_30_0)
					if arg_30_0 == xyd.error.OK then
						arg_27_0:updateList()
						arg_27_0:updateCountDown()
					end
				end)
			end, nil, nil, arg_27_0.colorMode)
		end
	end
end

function var_0_1.willClose(arg_31_0)
	if arg_31_0.countDown_ then
		arg_31_0.countDown_:stop()
	end

	display.getRunningScene():setContentVisible(true)
end

return var_0_1
