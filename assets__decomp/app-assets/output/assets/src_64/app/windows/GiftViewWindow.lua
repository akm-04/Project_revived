local var_0_0 = class("GiftViewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.gift
local var_0_5 = xyd.tables.giftbag
local var_0_6 = 90002082
local var_0_7 = 90002112

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.giftData = arg_1_2.gift_data
	arg_1_0.chargeId = arg_1_0.giftData.charge_id

	if arg_1_2.is_push then
		var_0_5 = xyd.tables.giftPush
	else
		var_0_5 = xyd.tables.giftbag
	end

	local var_1_0 = var_0_5:giftId(arg_1_0.chargeId)

	arg_1_0.giftItems = clone(var_0_4:items(var_1_0))
	arg_1_0.giftNums = clone(var_0_4:itemNum(var_1_0))
	arg_1_0.skinCoin = var_0_4:skinCoin(var_1_0)

	local var_1_1 = var_0_4:mana(var_1_0)
	local var_1_2 = var_0_4:energy(var_1_0)

	if var_1_1 and var_1_1 > 0 then
		table.insert(arg_1_0.giftItems, -2)
		table.insert(arg_1_0.giftNums, var_1_1)
	end

	if var_1_2 and var_1_2 > 0 then
		table.insert(arg_1_0.giftItems, -13)
		table.insert(arg_1_0.giftNums, var_1_2)
	end

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 10 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0:nodeByName("scroll"):getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 10, var_3_0.width, var_3_0.height - 10),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("scroll")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(false)

	local var_3_1 = var_0_5:diamond(arg_3_0.chargeId)

	arg_3_0:nodeByName("txt_crystal"):setString(var_3_1)

	if arg_3_0.skinCoin > 0 then
		local var_3_2 = xyd.tables.ecoType:getEcoPath("skin_coin")
		local var_3_3 = xyd.AssetLoader.get():loadSprite(var_3_2)
		local var_3_4 = xyd.createLabel(22, cc.c3b(254, 115, 22))
		local var_3_5, var_3_6 = arg_3_0:nodeByName("yuanbao"):getPosition()
		local var_3_7 = arg_3_0:nodeByName("txt_crystal"):getPositionX()

		arg_3_0:nodeByName("yuanbao"):setPositionX(var_3_5 - 50)
		arg_3_0:nodeByName("txt_crystal"):setPositionX(var_3_7 - 50)
		var_3_3:setPosition(var_3_5 + 80, var_3_6)
		var_3_3:setScale(0.7)
		arg_3_0:nodeByName("container"):addChild(var_3_3)
		var_3_4:setString(arg_3_0.skinCoin)
		var_3_4:setPosition(var_3_5 + 110, var_3_6)
		arg_3_0:nodeByName("container"):addChild(var_3_4)
	end

	local var_3_8 = var_0_5:originalCharge(arg_3_0.chargeId)

	arg_3_0:nodeByName("txt_old_price"):setString(var_3_8 .. var_0_1:translation("VIP_WINDOW_TEXT_13"))

	local var_3_9 = var_0_5:charge(arg_3_0.chargeId)

	arg_3_0:nodeByName("txt_price"):setString(var_3_9 .. var_0_1:translation("VIP_WINDOW_TEXT_13"))
	arg_3_0:nodeByName("fnt_price"):setString(var_3_9)

	local var_3_10 = var_0_5:totalValue(arg_3_0.chargeId)

	arg_3_0:nodeByName("fnt_present"):setString(var_3_10)

	local var_3_11 = var_0_5:title(arg_3_0.chargeId)

	if var_3_11 then
		local var_3_12 = xyd.SpriteLoader.new(var_3_11, nil, nil, xyd.DefaultImageType.COMMON_TITLE)

		var_3_12:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_12:addTo(arg_3_0:nodeByName("bg_title"))
		var_3_12:setPosition(arg_3_0:nodeByName("img_title"):getPosition())
		arg_3_0:nodeByName("img_title"):setVisible(false)
	end

	if arg_3_0.chargeId == var_0_6 then
		local var_3_13 = arg_3_0.list:newItem()
		local var_3_14 = display.newNode()
		local var_3_15 = xyd.AssetLoader.get():loadNodeFromJson("windows/vipwindow/gift_view/view_item.csb")
		local var_3_16 = var_3_15:getChildByName("container")
		local var_3_17 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

		var_3_17:addTo(var_3_16:getChildByName("icon_container"))
		var_3_17:setAnchorPoint(cc.p(0, 0))
		var_3_17:setScale(0.66)
		var_3_16:getChildByName("num_txt"):setString("x1")
		var_3_16:getChildByName("name_txt"):setString(var_0_1:translation("RANDOM_3_STAR_GIRL"))
		var_3_15:addTo(var_3_14)
		var_3_15:setAnchorPoint(cc.p(0, 0))

		local var_3_18 = var_3_16:getContentSize()

		var_3_14:setContentSize(var_3_18)
		var_3_13:setItemSize(var_3_18.width, var_3_18.height + 5)
		var_3_13:addContent(var_3_14)
		arg_3_0.list:addItem(var_3_13)
	end

	if arg_3_0.chargeId == var_0_7 then
		local var_3_19 = arg_3_0.list:newItem()
		local var_3_20 = display.newNode()
		local var_3_21 = xyd.AssetLoader.get():loadNodeFromJson("windows/vipwindow/gift_view/view_item.csb")
		local var_3_22 = var_3_21:getChildByName("container")

		arg_3_0:setItemAndAddTips(var_3_22:getChildByName("icon_container"), 50001043)
		var_3_22:getChildByName("num_txt"):setString("x?")
		var_3_22:getChildByName("name_txt"):setString(var_0_1:translation("RANDOM_RED_PACKETS"))
		var_3_21:addTo(var_3_20)
		var_3_21:setAnchorPoint(cc.p(0, 0))

		local var_3_23 = var_3_22:getContentSize()

		var_3_20:setContentSize(var_3_23)
		var_3_19:setItemSize(var_3_23.width, var_3_23.height + 5)
		var_3_19:addContent(var_3_20)
		arg_3_0.list:addItem(var_3_19)
	end

	for iter_3_0 = 1, #arg_3_0.giftItems do
		local var_3_24
		local var_3_25 = arg_3_0.list:dequeueItem()

		if not var_3_25 then
			var_3_25 = arg_3_0.list:newItem()
		else
			var_3_25:removeAllChildren(true)
		end

		local var_3_26 = arg_3_0:createGiftItemContent(iter_3_0)
		local var_3_27 = var_3_26:getWidth()
		local var_3_28 = var_3_26:getHeight()

		var_3_25:setItemSize(var_3_27, var_3_28 + 5)
		var_3_25:addContent(var_3_26)
		arg_3_0.list:addItem(var_3_25)
	end

	arg_3_0.list:reload()
	arg_3_0:nodeByName("buy_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("buy_btn"):setScale(0.9, 0.9)
		end

		if arg_4_1 == ccui.TouchEventType.moved then
			arg_3_0:nodeByName("buy_btn"):setScale(1, 1)
		end

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("buy_btn"):setScale(1, 1)
			xyd.playButtonSound()
			arg_3_0:purchaseGiftBag(arg_3_0.chargeId)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)

	if arg_3_0.giftData.end_time == -1 then
		arg_3_0:nodeByName("down_time_txt"):setVisible(false)
	else
		arg_3_0:updateDownTime()
	end
end

function var_0_0.createGiftItemContent(arg_5_0, arg_5_1)
	local var_5_0 = display.newNode()
	local var_5_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/vipwindow/gift_view/view_item.csb")
	local var_5_2 = var_5_1:getChildByName("container")

	arg_5_0:setItemAndAddTips(var_5_2:getChildByName("icon_container"), arg_5_0.giftItems[arg_5_1])
	var_5_2:getChildByName("num_txt"):setString("x" .. arg_5_0.giftNums[arg_5_1])
	var_5_2:getChildByName("name_txt"):setString(var_0_3:name(arg_5_0.giftItems[arg_5_1]))

	if arg_5_0.giftItems[arg_5_1] == -2 then
		var_5_2:getChildByName("name_txt"):setString(var_0_1:translation("COIN"))
	end

	if arg_5_0.giftItems[arg_5_1] == -13 then
		var_5_2:getChildByName("name_txt"):setString(var_0_1:translation("ENERGY"))
	end

	var_5_1:addTo(var_5_0)
	var_5_1:setAnchorPoint(cc.p(0, 0))
	var_5_0:setContentSize(var_5_2:getContentSize())
	var_5_1:setName("source")

	return var_5_0
end

function var_0_0.setItemAndAddTips(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = arg_6_1:getContentSize().height
	local var_6_1 = display.newNode()

	var_6_1:setContentSize(var_6_0, var_6_0)

	local var_6_2 = var_0_3:type(arg_6_2)

	xyd.setItemBorder(var_6_1, arg_6_2, nil, nil, arg_6_3)
	var_6_1:addTo(arg_6_1)
	var_6_1:setAnchorPoint(cc.p(0, 0))

	local var_6_3 = {
		id = arg_6_2,
		hasNum = arg_6_0.player:getBackpack():getItemNumByID(arg_6_2)
	}

	arg_6_0:addTips(var_6_1, var_6_3)
end

function var_0_0.updateDownTime(arg_7_0)
	if arg_7_0.handler then
		var_0_2.unscheduleGlobal(arg_7_0.handler)

		arg_7_0.handler = nil
	end

	local var_7_0
	local var_7_1 = arg_7_0.giftData.end_time - xyd.ServerTime.get():getServerTime()

	if var_7_1 > 0 then
		arg_7_0:nodeByName("down_time_txt"):setString(var_0_1:translation("VIP_WINDOW_TEXT_16") .. ":" .. xyd.timeFormatAsHMS(var_7_1))

		arg_7_0.handler = var_0_2.scheduleGlobal(function()
			var_7_1 = var_7_1 - 1

			if not tolua.isnull(arg_7_0) then
				arg_7_0:nodeByName("down_time_txt"):setString(var_0_1:translation("VIP_WINDOW_TEXT_16") .. ":" .. xyd.timeFormatAsHMS(var_7_1))
			end

			if var_7_1 <= 0 and arg_7_0.handler then
				var_0_2.unscheduleGlobal(arg_7_0.handler)

				arg_7_0.handler = nil

				xyd.WindowManager.get():closeWindow(arg_7_0)
			end
		end, 1)
	else
		xyd.WindowManager.get():closeWindow(arg_7_0)
	end
end

function var_0_0.purchaseGiftBag(arg_9_0, arg_9_1)
	local var_9_0 = true
	local var_9_1 = arg_9_0:getNewIDs()

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_9_1
		}, var_9_1, arg_9_1, false, var_0_5:charge(arg_9_1), var_0_5:chargeName(arg_9_1))
	elseif device.platform == "ios" then
		local var_9_2 = var_0_5:iosProductID(arg_9_1)

		xyd.sdkPurchase(var_9_2, var_9_0, arg_9_1, {}, var_9_1, {
			arg_9_1
		})
	end
end

function var_0_0.getNewIDs(arg_10_0)
	local var_10_0 = 80001001
	local var_10_1 = {}

	for iter_10_0, iter_10_1 in pairs(arg_10_0.player.vipChargeData) do
		if tonumber(iter_10_1) == 0 and iter_10_0 ~= var_10_0 then
			table.insert(var_10_1, iter_10_0)
		end
	end

	return var_10_1
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	arg_11_0:addBlockLayer()
end

function var_0_0.didClose(arg_12_0, arg_12_1)
	if arg_12_0.handler then
		var_0_2.unscheduleGlobal(arg_12_0.handler)

		arg_12_0.handler = nil
	end
end

return var_0_0
