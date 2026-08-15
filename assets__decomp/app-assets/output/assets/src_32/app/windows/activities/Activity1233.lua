local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySelectGift
local var_0_3 = xyd.tables.gift
local var_0_4 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	local var_2_1 = var_2_0:getChildByName("container")

	arg_2_0:updateTimeCount(var_2_1)
	var_2_1:getChildByName("txt_tips"):setString(xyd.tables.activities:desc(arg_2_0.activity.table_id))

	local var_2_2 = var_2_1:getChildByName("list"):getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_2.width, var_2_2.height),
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_2_1:getChildByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0.list:reload()
end

function var_0_0.delegate(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	if cc.ui.UIListView.COUNT_TAG == arg_3_2 then
		return #var_0_2:ids()
	elseif cc.ui.UIListView.CELL_TAG == arg_3_2 then
		local var_3_0 = arg_3_0.list:dequeueItem()

		if var_3_0 then
			var_3_0:removeAllChildren()
		else
			var_3_0 = arg_3_0.list:newItem()
		end

		local var_3_1 = display.newNode()

		var_3_1:setContentSize(303, 350)
		var_3_1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_3_0:createItemContent(arg_3_3):addTo(var_3_1)
		var_3_0:addContent(var_3_1)
		var_3_0:setItemSize(303, 350)

		return var_3_0
	end
end

function var_0_0.createItemContent(arg_4_0, arg_4_1)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1233/gift_bag_item.csb")
	local var_4_1 = var_4_0:getChildByName("container")
	local var_4_2 = var_4_1:getContentSize()

	var_4_0:setContentSize(var_4_2)

	local var_4_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1233/icon_" .. arg_4_1 .. ".png")

	var_4_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_3:addTo(var_4_1:getChildByName("pos_icon"))

	local var_4_4 = var_0_2:chargeId(arg_4_1)

	var_4_1:getChildByName("txt_price"):setString(var_0_1:translation("PRICE_TEXT") .. var_0_2:charge(var_4_4))

	local var_4_5 = var_4_1:getChildByName("btn_buy")

	var_4_5:addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(var_4_5, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			if arg_4_0:checkIsOpen() then
				xyd.playButtonSound()
				arg_4_0:purchaseGiftBag(var_4_4)
				xyd.WindowManager.get():closeWindow("activities")
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_FINISHED")
				})
			end
		end
	end)

	if arg_4_0.details.buy_id ~= 0 then
		local var_4_6 = xyd.AssetLoader.get():loadSprite("windows/activities/1233/bg_grey" .. arg_4_1 .. ".png")

		var_4_6:setAnchorPoint(cc.p(0, 0))
		var_4_6:addTo(var_4_1:getChildByName("pos_grey"))
		var_4_5:setTouchEnabled(false)
		var_4_1:getChildByName("txt_buy"):setColor(cc.c3b(52, 54, 55))

		if var_4_4 == arg_4_0.details.buy_id then
			var_4_1:getChildByName("txt_buy"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT5"))
		else
			var_4_1:getChildByName("txt_buy"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT6"))
		end
	else
		var_4_5:setTouchEnabled(true)
		var_4_1:getChildByName("txt_buy"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT6"))
	end

	local var_4_7 = display.newNode()

	var_4_7:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_7:setContentSize(var_4_3:getContentSize())
	var_4_7:addTo(var_4_1)
	var_4_7:setPosition(var_4_1:getChildByName("pos_icon"):getPosition())
	xyd.nodeEventSample(var_4_7, nil, function()
		return
	end)
	var_4_7:setTouchEnabled(true)
	var_4_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			var_4_7:setScale(0.9)

			local var_7_0 = var_0_2:giftId(var_4_4)
			local var_7_1 = var_0_3:items(var_7_0)
			local var_7_2 = var_0_3:itemNum(var_7_0)
			local var_7_3 = xyd.getFormatItemsByIdNums(var_7_1, var_7_2)

			xyd.WindowManager.get():openWindow("common_award", {
				awards = var_7_3
			})

			local var_7_4 = var_4_7:convertToWorldSpace(cc.p(0, 0))

			xyd.WindowManager.get():getWindow("common_award"):setPosition(math.min(var_7_4.x - 342, 838), var_7_4.y + 150)

			return true
		elseif arg_7_0.name == "ended" then
			var_4_7:setScale(1)

			if xyd.WindowManager:get():getWindow("common_award") then
				xyd.WindowManager:get():closeWindow("common_award")
			end

			return
		elseif arg_7_0.name == "cancled" then
			var_4_7:setScale(1)

			if xyd.WindowManager:get():getWindow("common_award") then
				xyd.WindowManager:get():closeWindow("common_award")
			end
		end
	end)

	return var_4_0
end

function var_0_0.purchaseGiftBag(arg_8_0, arg_8_1)
	local var_8_0 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_8_1
		}, {}, arg_8_1, false, var_0_2:charge(arg_8_1), var_0_2:name(arg_8_1))
	elseif device.platform == "ios" then
		local var_8_1 = var_0_2:iosProductId(arg_8_1)

		xyd.sdkPurchase(var_8_1, var_8_0, arg_8_1, {}, {}, {
			arg_8_1
		})
	end
end

function var_0_0.updateTimeCount(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1:getChildByName("txt_countdown")

	if arg_9_0.handle_ then
		var_0_4.unscheduleGlobal(arg_9_0.handle_)
	end

	local var_9_1 = arg_9_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	if arg_9_0:checkIsOpen() then
		var_9_0:setVisible(true)
	else
		var_9_0:setVisible(false)
	end

	var_9_0:setString(var_0_1:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_9_1))

	arg_9_0.handle_ = var_0_4.scheduleGlobal(function()
		if var_9_0 and not tolua.isnull(var_9_0) then
			var_9_1 = var_9_1 - 1

			var_9_0:setString(var_0_1:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_9_1))

			if var_9_1 <= 0 then
				if arg_9_0.handle_ then
					var_0_4.unscheduleGlobal(arg_9_0.handle_)

					arg_9_0.handle_ = nil
				end

				var_9_0:setVisible(false)
			end
		elseif arg_9_0.handle_ then
			var_0_4.unscheduleGlobal(arg_9_0.handle_)

			arg_9_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.checkIsOpen(arg_11_0)
	if arg_11_0.activity.end_time - xyd.ServerTime.get():getServerTime() <= 0 or arg_11_0.activity.start_time - xyd.ServerTime.get():getServerTime() >= 0 then
		return false
	else
		return true
	end
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
	elseif arg_12_1.name == "moved" and 20 <= math.abs(arg_12_1.x - arg_12_0.prevX_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.release(arg_13_0)
	if arg_13_0.handle then
		var_0_4.unscheduleGlobal(arg_13_0.handle)

		arg_13_0.handle = nil
	end
end

return var_0_0
