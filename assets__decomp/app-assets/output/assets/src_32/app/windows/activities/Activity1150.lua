local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityMonthLimit
local var_0_3 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(-25, 0)

		local var_2_1 = xyd.AssetLoader.get():loadLabel(nil, "down_time")

		var_2_1:setString(10)
		var_2_1:setAnchorPoint(cc.p(0, 0.5))
		var_2_1:addTo(arg_2_0.container:getChildByName("down_time_pos"))

		arg_2_0.downTimeLabel = var_2_1

		arg_2_0.container:getChildByName("down_time_text"):setString(var_0_1:translation("TEAM_DRINK_LEFT_TIME"))
		arg_2_0.container:getChildByName("rule_txt"):setString(xyd.tables.activities:desc(arg_2_0.activity.table_id))
		arg_2_0.container:getChildByName("rule_txt"):enableOutline(cc.c4b(25, 87, 166, 255), 2)
		arg_2_0:createTimeCount()

		arg_2_0.scroll = arg_2_0.container:getChildByName("scroll")

		local var_2_2 = arg_2_0.scroll:getContentSize()

		arg_2_0.awardedList = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, var_2_2.width, var_2_2.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_2_0.scroll)

		arg_2_0.awardedList:setBounceable(false)
		arg_2_0.awardedList:setTouchType(false)

		arg_2_0.awardedIdx = {}

		arg_2_0:update()
	end
end

function var_0_0.update(arg_3_0)
	arg_3_0:updateAwardScroll()
end

function var_0_0.updateAwardScroll(arg_4_0)
	arg_4_0.awardedList:removeAllItems()

	for iter_4_0 = 1, #arg_4_0.details.base_info.award_ids do
		local var_4_0
		local var_4_1 = arg_4_0.awardedList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.awardedList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(iter_4_0)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)
		arg_4_0.awardedList:addItem(var_4_1)
		arg_4_0.awardedList:reload()
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = tonumber(arg_5_0.details.base_info.award_ids[arg_5_1])
	local var_5_1 = tonumber(arg_5_0.details.base_info.buy_times[arg_5_1])
	local var_5_2 = display.newNode()
	local var_5_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1150/activity_item.csb")
	local var_5_4 = var_5_3:getChildByName("container")
	local var_5_5 = var_0_2:charge(var_5_0)
	local var_5_6 = var_0_2:buyLimit(var_5_0)
	local var_5_7 = var_0_2:originalCharge(var_5_0)

	if var_0_2:vipLimit(var_5_0) > arg_5_0.selfPlayer.vip then
		return var_5_2
	end

	arg_5_0:rewardFormat(var_5_4:getChildByName("reward_container"), var_0_2:giftId(var_5_0))
	var_5_4:getChildByName("name_txt"):setString(var_0_2:name(var_5_0))
	var_5_4:getChildByName("price_text"):setString(var_0_1:translation("PRICE_TEXT"))
	var_5_4:getChildByName("org_price_txt"):setString(string.format(var_0_1:translation("ACTIVITY_TIME_LIMIT_4"), var_5_7))
	var_5_4:getChildByName("price_txt"):setString(string.format(var_0_1:translation("ACTIVITY_TIME_LIMIT_4"), var_5_5))

	if var_5_6 > 0 then
		var_5_4:getChildByName("limit_time_txt"):setString(string.format(var_0_1:translation("STICK_BLESS_BUY_LIMIT"), var_5_1, var_5_6))
	else
		var_5_4:getChildByName("limit_time_txt"):setString("")
	end

	var_5_4:getChildByName("price_text"):enableShadow(xyd.color.FONT_SHADOW_A, cc.size(1, -1), 3)
	var_5_4:getChildByName("org_price_txt"):enableShadow(xyd.color.FONT_SHADOW_A, cc.size(1, -1), 3)
	var_5_4:getChildByName("price_txt"):enableShadow(xyd.color.FONT_SHADOW_A, cc.size(1, -1), 3)
	var_5_4:getChildByName("limit_time_txt"):enableShadow(xyd.color.FONT_SHADOW_A, cc.size(1, -1), 3)
	var_5_4:getChildByName("vip_txt"):setString(string.format(var_0_1:translation("ACTIVITY1150_VIP_TIP"), xyd.tables.gift:vipExp(var_0_2:giftId(var_5_0))))

	local var_5_8 = arg_5_0.activity.details
	local var_5_9 = var_5_4:getChildByName("btn")
	local var_5_10 = var_5_4:getChildByName("yilingqu")
	local var_5_11 = var_5_4:getChildByName("lingqu")
	local var_5_12 = var_5_4:getChildByName("get_gray")
	local var_5_13 = var_5_4:getChildByName("expired")
	local var_5_14 = var_5_4:getChildByName("not_begin")
	local var_5_15 = {
		btn = var_5_9,
		alreadyObtain = var_5_10,
		obtain_bright = var_5_11,
		obtain_gray = var_5_12,
		expired = var_5_13,
		notBegin = var_5_14
	}
	local var_5_16 = xyd.ServerTime.get():getServerTime()
	local var_5_17 = arg_5_0.activity.end_time - xyd.ServerTime.get():getServerTime()
	local var_5_18 = arg_5_0.activity.end_time - arg_5_0.activity.start_time

	if var_5_1 < var_5_6 or var_5_6 <= 0 then
		arg_5_0:setBtnGetState(1, var_5_15)
	else
		arg_5_0:setBtnGetState(-1, var_5_15)
	end

	var_5_4:getChildByName("btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_5_0.scrollViewMoved_ ~= true then
			if var_5_17 < 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("KITE_CLOSED")
				})

				return
			elseif var_5_17 > var_5_18 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("KITE_NOT_OPEN")
				})

				return
			end

			arg_5_0:purchaseGiftBag(var_5_0)
			xyd.WindowManager.get():closeWindow("activities")
		end
	end)
	var_5_3:addTo(var_5_2)
	var_5_3:setAnchorPoint(cc.p(0, 0))
	var_5_2:setContentSize(var_5_4:getContentSize().width + 2, var_5_4:getContentSize().height + 4)
	var_5_3:setPosition(cc.p(1, 2))
	var_5_3:setName("source")

	return var_5_2
end

function var_0_0.getBuyTimes(arg_7_0, arg_7_1)
	return arg_7_0.details.base_info[tostring(arg_7_1)] or 0
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

function var_0_0.createTimeCount(arg_9_0)
	if arg_9_0.handle then
		var_0_3.unscheduleGlobal(arg_9_0.handle)

		arg_9_0.handle = nil
	end

	local var_9_0 = arg_9_0.activity.end_time - xyd.ServerTime.get():getServerTime()
	local var_9_1 = arg_9_0.activity.end_time - arg_9_0.activity.start_time

	arg_9_0:updateDownTimeLabel(var_9_0, var_9_1)

	arg_9_0.handle = var_0_3.scheduleGlobal(function()
		var_9_0 = var_9_0 - 1

		if var_9_0 <= 0 then
			var_0_3.unscheduleGlobal(arg_9_0.handle)
			arg_9_0:update()
		elseif arg_9_0 and arg_9_0.downTimeLabel and not tolua.isnull(arg_9_0.downTimeLabel) and arg_9_0.container and not tolua.isnull(arg_9_0.container) then
			arg_9_0:updateDownTimeLabel(var_9_0, var_9_1)
		end
	end, 1)
end

function var_0_0.updateDownTimeLabel(arg_11_0, arg_11_1, arg_11_2)
	arg_11_0.downTimeLabel:setVisible(false)
	arg_11_0.container:getChildByName("time_tip_txt"):setVisible(false)

	if arg_11_2 < arg_11_1 then
		arg_11_0.container:getChildByName("time_tip_txt"):setVisible(true)
		arg_11_0.container:getChildByName("time_tip_txt"):setString(var_0_1:translation("KITE_NOT_OPEN"))
	elseif arg_11_1 < 0 then
		arg_11_0.container:getChildByName("time_tip_txt"):setVisible(true)
		arg_11_0.container:getChildByName("time_tip_txt"):setString(var_0_1:translation("KITE_CLOSED"))
	else
		arg_11_0.downTimeLabel:setVisible(true)

		local var_11_0 = xyd.timeFormatAsHMS(arg_11_1)

		if not tolua.isnull(arg_11_0.downTimeLabel) then
			arg_11_0.downTimeLabel:setString(var_11_0)
		else
			var_0_3.unscheduleGlobal(arg_11_0.handle)
		end
	end
end

function var_0_0.release(arg_12_0)
	if arg_12_0.handle then
		var_0_3.unscheduleGlobal(arg_12_0.handle)
	end

	var_0_0.super:release()
end

return var_0_0
