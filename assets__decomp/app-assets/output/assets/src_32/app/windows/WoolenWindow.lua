local var_0_0 = class("WoolenWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.gift

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.giftId = arg_1_2.giftId
	arg_1_0.price = arg_1_2.price
	arg_1_0.giftbagName = arg_1_2.giftbagName
	arg_1_0.chargeId = arg_1_2.chargeId
	arg_1_0.iosProductID = arg_1_2.iosProductID
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
		viewRect = cc.rect(0, 10, var_3_0.width, var_3_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("scroll")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(false)

	local var_3_1 = arg_3_0.price
	local var_3_2 = xyd.AssetLoader.get():loadLabel(nil, "chargePrice")

	var_3_2:setString(var_3_1)
	var_3_2:setAnchorPoint(cc.p(1, 0.5))
	var_3_2:addTo(arg_3_0:nodeByName("org_price_pos"))
	var_3_2:setPosition(cc.p(0, -3))

	local var_3_3 = arg_3_0.price - 60
	local var_3_4 = xyd.AssetLoader.get():loadLabel(nil, "chargePrice")

	var_3_4:setString(var_3_3)
	var_3_4:setAnchorPoint(cc.p(1, 0.5))
	var_3_4:addTo(arg_3_0:nodeByName("current_price_pos"))
	var_3_4:setPosition(cc.p(0, -3))

	local var_3_5 = "windows/activities/1163/number/" .. var_3_3 .. ".png"

	xyd.AssetLoader:get():loadSprite(var_3_5):addTo(arg_3_0:nodeByName("price_pos"))

	arg_3_0.giftItems = var_0_4:items(arg_3_0.giftId)
	arg_3_0.giftNums = var_0_4:itemNum(arg_3_0.giftId)

	for iter_3_0 = 1, #arg_3_0.giftItems do
		local var_3_6
		local var_3_7 = arg_3_0.list:dequeueItem()

		if not var_3_7 then
			var_3_7 = arg_3_0.list:newItem()
		else
			var_3_7:removeAllChildren(true)
		end

		local var_3_8 = arg_3_0:createGiftItemContent(iter_3_0)
		local var_3_9 = var_3_8:getWidth()
		local var_3_10 = var_3_8:getHeight()

		var_3_7:setItemSize(var_3_9, var_3_10)
		var_3_7:addContent(var_3_8)
		arg_3_0.list:addItem(var_3_7)
	end

	arg_3_0.list:reload()
	arg_3_0:nodeByName("buy_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local function var_4_0()
				local var_5_0 = true
				local var_5_1 = arg_3_0.player:getNewIDs()
				local var_5_2 = arg_3_0.chargeId
				local var_5_3 = xyd.tables.chargeList

				if device.platform == "android" then
					xyd.androidPurchase({
						var_5_2
					}, var_5_1, {
						var_5_2
					}, false, arg_3_0.price, arg_3_0.giftbagName)
				elseif device.platform == "ios" then
					xyd.sdkPurchase(arg_3_0.iosProductID, var_5_0, var_5_2, {}, var_5_1, {
						var_5_2
					})
				end
			end

			xyd.playButtonSound()

			if not arg_3_0.player.vipChargeData then
				arg_3_0.player:queryChargeData(function()
					var_4_0()
					xyd.WindowManager.get():closeWindow(arg_3_0)
				end)
			else
				var_4_0()
				xyd.WindowManager.get():closeWindow(arg_3_0)
			end
		end
	end)
end

function var_0_0.createGiftItemContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1163/view_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")

	arg_7_0:setItemAndAddTips(var_7_2:getChildByName("icon_container"), arg_7_0.giftItems[arg_7_1])
	var_7_2:getChildByName("num_txt"):setString("x" .. arg_7_0.giftNums[arg_7_1])
	var_7_2:getChildByName("name_txt"):setString(var_0_3:name(arg_7_0.giftItems[arg_7_1]))
	var_7_1:addTo(var_7_0)
	var_7_1:setAnchorPoint(cc.p(0, 0))
	var_7_0:setContentSize(var_7_2:getContentSize())
	var_7_1:setName("source")

	return var_7_0
end

function var_0_0.setItemAndAddTips(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = arg_8_1:getContentSize().height
	local var_8_1 = display.newNode()

	var_8_1:setContentSize(var_8_0, var_8_0)

	local var_8_2 = var_0_3:type(arg_8_2)

	xyd.setItemBorder(var_8_1, arg_8_2, nil, nil, arg_8_3)
	var_8_1:addTo(arg_8_1)
	var_8_1:setAnchorPoint(cc.p(0, 0))

	local var_8_3 = {
		id = arg_8_2,
		hasNum = arg_8_0.player:getBackpack():getItemNumByID(arg_8_2)
	}

	arg_8_0:addTips(var_8_1, var_8_3)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	arg_9_0:addBlockLayer()
end

return var_0_0
