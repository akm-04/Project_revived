local var_0_0 = class("ActivityNewServerPushWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.newServerPush
local var_0_4 = xyd.tables.gift

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.timesTxt = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_0:nodeByName("scroll"):getContentSize()

	arg_2_0.scrollList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 10, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("scroll"))

	arg_2_0.scrollList:setBounceable(true)

	local var_2_1 = var_0_3:getIds()

	for iter_2_0, iter_2_1 in ipairs(var_2_1) do
		local var_2_2 = arg_2_0.scrollList:newItem()
		local var_2_3 = display.newNode()
		local var_2_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1155/new_push_item.csb")
		local var_2_5 = var_2_4:getChildByName("container")

		var_2_5:getChildByName("price1"):setString(var_0_3:originalCharge(iter_2_1))
		var_2_5:getChildByName("price2"):setString(var_0_3:charge(iter_2_1))
		var_2_5:getChildByName("limite_txt2"):setString(var_0_3:buyLimit(iter_2_1))
		var_2_5:getChildByName("name_txt"):setString(var_0_3:name(iter_2_1))
		table.insert(arg_2_0.timesTxt, var_2_5:getChildByName("limite_txt"))

		local var_2_6 = var_0_3:icon(iter_2_1)
		local var_2_7 = xyd.AssetLoader:get():loadSprite(var_2_6)

		var_2_7:setAnchorPoint(cc.p(0, 0.5))
		var_2_7:addTo(var_2_5:getChildByName("item_node"))

		local var_2_8, var_2_9 = var_2_5:getChildByName("percent"):getPosition()
		local var_2_10 = var_2_8 - 30
		local var_2_11 = var_2_9 - 3
		local var_2_12 = var_0_3:discount(iter_2_1)

		while var_2_12 > 0 do
			local var_2_13 = "windows/activities/1155/number/" .. var_2_12 % 10 .. ".png"
			local var_2_14 = xyd.AssetLoader:get():loadSprite(var_2_13)

			var_2_14:addTo(var_2_5)
			var_2_14:setPosition(cc.p(var_2_10, var_2_11))

			var_2_10 = var_2_10 - 23
			var_2_11 = var_2_11 - 3
			var_2_12 = math.floor(var_2_12 / 10)
		end

		var_2_5:getChildByName("buy_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				if xyd.splitToNumber(arg_2_0.activity.details.buy_times, "|")[iter_2_0] >= var_0_3:buyLimit(iter_2_1) then
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("FIREWORK_TEXT_16")
					})

					return
				end

				xyd.playButtonSound()

				local var_3_0 = true
				local var_3_1 = arg_2_0:getNewIDs()
				local var_3_2 = var_0_3:giftId(iter_2_1)

				if device.platform == "android" then
					xyd.androidPurchase({
						iter_2_1
					}, var_3_1, iter_2_1, false, var_0_3:charge(iter_2_1), var_0_3:name(iter_2_1))
				elseif device.platform == "ios" then
					local var_3_3 = var_0_3:iosProductID(iter_2_1)

					xyd.sdkPurchase(var_3_3, var_3_0, iter_2_1, {}, var_3_1, {
						iter_2_1
					})
				end
			end
		end)

		local var_2_15 = 225
		local var_2_16 = 10
		local var_2_17 = var_0_3:giftId(iter_2_1)
		local var_2_18 = var_0_4:items(var_2_17)
		local var_2_19 = var_0_4:itemNum(var_2_17)

		for iter_2_2, iter_2_3 in ipairs(var_2_18) do
			local var_2_20 = display.newNode()

			var_2_20:setContentSize(100, 100)
			xyd.setItemAndAddTips(var_2_20, iter_2_3, var_2_19[iter_2_2])
			var_2_20:addTo(var_2_5)
			var_2_20:setAnchorPoint(cc.p(0, 0))
			var_2_20:setPosition(var_2_15, var_2_16)

			var_2_15 = var_2_15 + 105
		end

		local var_2_21 = display.newNode()

		var_2_21:setContentSize(100, 100)
		xyd.setItemAndAddTips(var_2_21, -1, var_0_3:diamond(iter_2_1))
		var_2_21:addTo(var_2_5)
		var_2_21:setAnchorPoint(cc.p(0, 0))
		var_2_21:setPosition(var_2_15, var_2_16)
		var_2_4:addTo(var_2_3)
		var_2_4:setAnchorPoint(cc.p(0, 0))
		var_2_3:setContentSize(1024, 162)
		var_2_2:setItemSize(1024, 162)
		var_2_2:addContent(var_2_3)
		arg_2_0.scrollList:addItem(var_2_2)
	end

	arg_2_0.scrollList:reload()
	arg_2_0:updateTimes()
end

function var_0_0.getNewIDs(arg_4_0)
	local var_4_0 = 80001001
	local var_4_1 = {}

	for iter_4_0, iter_4_1 in pairs(arg_4_0.player.vipChargeData) do
		if tonumber(iter_4_1) == 0 and iter_4_0 ~= var_4_0 then
			table.insert(var_4_1, iter_4_0)
		end
	end

	return var_4_1
end

function var_0_0.updateTimes(arg_5_0)
	arg_5_0.activity = arg_5_0.activityModel:getActivityInfo(xyd.Activities.NewServerPush)
	arg_5_0.buyTimes = xyd.splitToNumber(arg_5_0.activity.details.buy_times, "|")

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.timesTxt) do
		iter_5_1:setString(arg_5_0.buyTimes[iter_5_0])
	end
end

return var_0_0
