local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = class("GardenSeedWindow", import("app.common.ui.BaseWindow"))
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityMonthLimit
local var_0_4 = import("framework.scheduler")

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_1.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_1_0:getActivityInfo()
end

function var_0_1.getActivityInfo(arg_2_0)
	arg_2_0.activity = arg_2_0.activitiesModel:getActivityInfo(xyd.Activities.END_MONTH)
	arg_2_0.details = arg_2_0.activity.details
end

function var_0_1.willOpen(arg_3_0)
	arg_3_0:layout()
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))

	local var_3_0 = arg_3_0:nodeByName("close_btn")

	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended and arg_3_0.scrollViewMoved_ ~= true then
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_1.layout(arg_5_0)
	arg_5_0.container = arg_5_0:nodeByName("container")

	local var_5_0 = xyd.AssetLoader.get():loadLabel(nil, "down_time")

	var_5_0:setString(10)
	var_5_0:setAnchorPoint(cc.p(0, 0.5))
	var_5_0:addTo(arg_5_0.container:getChildByName("down_time_pos"))

	arg_5_0.downTimeLabel = var_5_0

	arg_5_0:setTxt()
	arg_5_0.container:getChildByName("time_tip_txt"):enableOutline(cc.c4b(116, 27, 52, 255), 2)
	arg_5_0:createTimeCount()

	arg_5_0.scroll = arg_5_0.container:getChildByName("scroll")

	local var_5_1 = arg_5_0.scroll:getContentSize()

	arg_5_0.awardedList = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0.scroll)

	arg_5_0.awardedList:setTouchType(false)
	arg_5_0:updateAwardScroll()
end

function var_0_1.setTxt(arg_6_0)
	arg_6_0.container:getChildByName("rule_txt"):setString(xyd.tables.activities:desc(arg_6_0.activity.table_id))
	arg_6_0.container:getChildByName("down_time_text"):setString(var_0_2:translation("TEAM_DRINK_LEFT_TIME"))
	arg_6_0.container:getChildByName("down_time_text"):enableOutline(cc.c4b(74, 60, 123, 255), 2)
end

function var_0_1.updateAwardScroll(arg_7_0)
	arg_7_0.awardedList:removeAllItems()

	for iter_7_0 = 1, #arg_7_0.details.base_info.award_ids do
		local var_7_0
		local var_7_1 = arg_7_0.awardedList:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.awardedList:newItem()
		else
			var_7_1:removeAllChildren(true)
		end

		local var_7_2 = arg_7_0:createListContent(iter_7_0)
		local var_7_3 = var_7_2:getWidth()
		local var_7_4 = var_7_2:getHeight()

		var_7_1:setItemSize(var_7_3, var_7_4)
		var_7_1:addContent(var_7_2)
		arg_7_0.awardedList:addItem(var_7_1)
		arg_7_0.awardedList:reload()
	end
end

function var_0_1.loadItem(arg_8_0)
	return xyd.AssetLoader.get():loadNodeFromJson("windows/garden_seed/item.csb")
end

function var_0_1.createListContent(arg_9_0, arg_9_1)
	local var_9_0 = tonumber(arg_9_0.details.base_info.award_ids[arg_9_1])
	local var_9_1 = tonumber(arg_9_0.details.base_info.buy_times[arg_9_1])
	local var_9_2 = display.newNode()
	local var_9_3 = arg_9_0:loadItem()
	local var_9_4 = var_9_3:getChildByName("container")
	local var_9_5 = var_0_3:charge(var_9_0)
	local var_9_6 = var_0_3:buyLimit(var_9_0)
	local var_9_7 = var_0_3:originalCharge(var_9_0)

	if var_0_3:vipLimit(var_9_0) > arg_9_0.selfPlayer.vip then
		return var_9_2
	end

	arg_9_0:rewardFormat(var_9_4:getChildByName("reward_container"), var_0_3:giftId(var_9_0), nil, 5)
	var_9_4:getChildByName("name_txt"):setString(var_0_3:name(var_9_0))
	var_9_4:getChildByName("name_txt"):enableOutline(cc.c4b(55, 82, 115, 255), 2)
	var_9_4:getChildByName("price_text"):setString(var_0_2:translation("PRICE_TEXT"))
	var_9_4:getChildByName("org_price_txt"):setString(string.format(var_0_2:translation("ACTIVITY_TIME_LIMIT_4"), var_9_7))
	var_9_4:getChildByName("price_txt"):setString(string.format(var_0_2:translation("ACTIVITY_TIME_LIMIT_4"), var_9_5))
	arg_9_0.container:getChildByName("rule_txt"):enableOutline(cc.c4b(70, 85, 111, 255), 2)

	if var_9_6 > 0 then
		var_9_4:getChildByName("limit_time_txt"):setString(string.format(var_0_2:translation("STICK_BLESS_BUY_LIMIT"), var_9_1, var_9_6))
	else
		var_9_4:getChildByName("limit_time_txt"):setString("")
	end

	var_9_4:getChildByName("vip_txt"):setString(string.format(var_0_2:translation("ACTIVITY1150_VIP_TIP"), xyd.tables.gift:vipExp(var_0_3:giftId(var_9_0))))

	local var_9_8 = arg_9_0.activity.details
	local var_9_9 = var_9_4:getChildByName("btn")
	local var_9_10 = var_9_4:getChildByName("yilingqu")
	local var_9_11 = var_9_4:getChildByName("lingqu")
	local var_9_12 = var_9_4:getChildByName("get_gray")
	local var_9_13 = var_9_4:getChildByName("expired")
	local var_9_14 = var_9_4:getChildByName("not_begin")
	local var_9_15 = {
		btn = var_9_9,
		alreadyObtain = var_9_10,
		obtain_bright = var_9_11,
		obtain_gray = var_9_12,
		expired = var_9_13,
		notBegin = var_9_14
	}
	local var_9_16 = xyd.ServerTime.get():getServerTime()
	local var_9_17 = arg_9_0.activity.end_time - xyd.ServerTime.get():getServerTime()
	local var_9_18 = arg_9_0.activity.end_time - arg_9_0.activity.start_time

	if var_9_1 < var_9_6 or var_9_6 <= 0 then
		-- block empty
	else
		var_9_9:setTouchEnabled(false)
		var_9_9:setBright(false)
	end

	var_9_4:getChildByName("btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(var_9_9, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended and arg_9_0.scrollViewMoved_ ~= true then
			if var_9_17 < 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("KITE_CLOSED")
				})

				return
			elseif var_9_17 > var_9_18 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("KITE_NOT_OPEN")
				})

				return
			end

			arg_9_0:purchaseGiftBag(var_9_0)
			xyd.WindowManager.get():closeWindow("activities")
		end
	end)
	var_9_3:addTo(var_9_2)
	var_9_3:setAnchorPoint(cc.p(0, 0))
	var_9_2:setContentSize(var_9_4:getContentSize().width + 2, var_9_4:getContentSize().height - 12)
	var_9_3:setPosition(cc.p(1, 2))
	var_9_3:setName("source")

	return var_9_2
end

function var_0_1.getBuyTimes(arg_11_0, arg_11_1)
	return arg_11_0.details.base_info[tostring(arg_11_1)] or 0
end

function var_0_1.purchaseGiftBag(arg_12_0, arg_12_1)
	local var_12_0 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_12_1
		}, {}, arg_12_1, false, var_0_3:charge(arg_12_1), var_0_3:name(arg_12_1))
	elseif device.platform == "ios" then
		local var_12_1 = var_0_3:iosProductId(arg_12_1)

		xyd.sdkPurchase(var_12_1, var_12_0, arg_12_1, {}, {}, {
			arg_12_1
		})
	end
end

function var_0_1.update(arg_13_0)
	arg_13_0:updateAwardScroll()
end

function var_0_1.createTimeCount(arg_14_0)
	if arg_14_0.handle then
		var_0_4.unscheduleGlobal(arg_14_0.handle)

		arg_14_0.handle = nil
	end

	local var_14_0 = arg_14_0.activity.end_time - xyd.ServerTime.get():getServerTime()
	local var_14_1 = arg_14_0.activity.end_time - arg_14_0.activity.start_time

	arg_14_0:updateDownTimeLabel(var_14_0, var_14_1)

	arg_14_0.handle = var_0_4.scheduleGlobal(function()
		var_14_0 = var_14_0 - 1

		if var_14_0 <= 0 then
			if arg_14_0 and arg_14_0.handle then
				var_0_4.unscheduleGlobal(arg_14_0.handle)
			end

			if arg_14_0 and not tolua.isnull(arg_14_0) then
				arg_14_0:update()
			end
		elseif arg_14_0 and arg_14_0.downTimeLabel and not tolua.isnull(arg_14_0.downTimeLabel) and arg_14_0.container and not tolua.isnull(arg_14_0.container) then
			arg_14_0:updateDownTimeLabel(var_14_0, var_14_1)
		end
	end, 1)
end

function var_0_1.updateDownTimeLabel(arg_16_0, arg_16_1, arg_16_2)
	arg_16_0.downTimeLabel:setVisible(false)
	arg_16_0.container:getChildByName("time_tip_txt"):setVisible(false)

	if arg_16_2 < arg_16_1 then
		arg_16_0.container:getChildByName("time_tip_txt"):setVisible(true)
		arg_16_0.container:getChildByName("time_tip_txt"):setString(var_0_2:translation("KITE_NOT_OPEN"))
	elseif arg_16_1 < 0 then
		arg_16_0.container:getChildByName("time_tip_txt"):setVisible(true)
		arg_16_0.container:getChildByName("time_tip_txt"):setString(var_0_2:translation("KITE_CLOSED"))
	else
		arg_16_0.downTimeLabel:setVisible(true)

		local var_16_0 = xyd.timeFormatAsHMS(arg_16_1)

		if not tolua.isnull(arg_16_0.downTimeLabel) then
			arg_16_0.downTimeLabel:setString(var_16_0)
		else
			var_0_4.unscheduleGlobal(arg_16_0.handle)
		end
	end
end

function var_0_1.rewardFormat(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4)
	local var_17_0 = arg_17_1:getContentSize().height - 10
	local var_17_1 = arg_17_4 or var_17_0 / 4
	local var_17_2 = xyd.tables.gift:items(arg_17_2)

	if #var_17_2 == 1 and var_17_2[1] == 0 then
		var_17_2 = {}
	end

	local var_17_3 = xyd.tables.gift:itemNum(arg_17_2)
	local var_17_4 = #var_17_2

	for iter_17_0 = 1, #var_17_2 do
		local var_17_5 = display.newNode()

		var_17_5:setContentSize(var_17_0, var_17_0)

		if xyd.tables.item:type(var_17_2[iter_17_0]) == -1 then
			xyd.setAvatarBorder(var_17_2[iter_17_0], var_17_5, 1, xyd.tables.hero:initialStar(var_17_2[iter_17_0]))
		else
			xyd.setItemBorder(var_17_5, var_17_2[iter_17_0], false, false, var_17_3[iter_17_0])
		end

		var_17_5:addTo(arg_17_1)
		var_17_5:setAnchorPoint(cc.p(0, 0))
		var_17_5:setPosition((iter_17_0 - 1) * (var_17_0 + var_17_1), 0)

		local var_17_6 = {
			id = var_17_2[iter_17_0],
			lev = xyd.tables.item:level(var_17_2[iter_17_0])
		}

		if xyd.tables.item:type(var_17_2[iter_17_0]) == -1 then
			var_17_6.tipsType = 0
			var_17_6.desc1 = xyd.tables.hero:getDes(var_17_2[iter_17_0])
		elseif specialItem then
			var_17_6.tipsType = 1
			var_17_6.id = -3
		else
			var_17_6.tipsType = 1
			var_17_6.desc1 = xyd.tables.item:desc1(var_17_2[iter_17_0])
			var_17_6.desc2 = xyd.tables.item:desc2(var_17_2[iter_17_0])
		end

		var_17_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_17_2[iter_17_0])
		var_17_6.name = xyd.tables.item:name(var_17_2[iter_17_0])

		var_0_0:addTips(var_17_5, var_17_6)
	end

	local var_17_7 = xyd.tables.gift:skinFragment(arg_17_2)

	if var_17_7 and var_17_7 > 0 then
		local var_17_8 = display.newNode()

		var_17_8:setContentSize(var_17_0, var_17_0)
		xyd.setItemBorder(var_17_8, -101, false, false, var_17_7)
		var_17_8:addTo(arg_17_1)
		var_17_8:setAnchorPoint(cc.p(0, 0))
		var_17_8:setPosition(var_17_4 * (var_17_0 + var_17_1), 0)

		local var_17_9 = {}

		var_17_9.id = -101
		var_17_9.tipsType = 1

		var_0_0:addTips(var_17_8, var_17_9)

		var_17_4 = var_17_4 + 1
	end

	local var_17_10 = xyd.tables.gift:crystal(arg_17_2)

	if var_17_10 and var_17_10 > 0 then
		local var_17_11 = display.newNode()

		var_17_11:setContentSize(var_17_0, var_17_0)
		xyd.setItemBorder(var_17_11, -1, false, false, var_17_10)
		var_17_11:addTo(arg_17_1)
		var_17_11:setAnchorPoint(cc.p(0, 0))
		var_17_11:setPosition(var_17_4 * (var_17_0 + var_17_1), 0)

		local var_17_12 = {}

		var_17_12.id = -1
		var_17_12.tipsType = 1

		var_0_0:addTips(var_17_11, var_17_12)

		var_17_4 = var_17_4 + 1
	end

	local var_17_13 = xyd.tables.gift:mana(arg_17_2)

	if var_17_13 and var_17_13 > 0 then
		local var_17_14 = display.newNode()

		var_17_14:setContentSize(var_17_0, var_17_0)
		xyd.setItemBorder(var_17_14, -2, false, false, var_17_13)
		var_17_14:addTo(arg_17_1)
		var_17_14:setAnchorPoint(cc.p(0, 0))
		var_17_14:setPosition(var_17_4 * (var_17_0 + var_17_1), 0)

		local var_17_15 = {}

		var_17_15.id = -2
		var_17_15.tipsType = 1

		var_0_0:addTips(var_17_14, var_17_15)

		var_17_4 = var_17_4 + 1
	end

	local var_17_16 = xyd.tables.gift:skinCoin(arg_17_2)

	if var_17_16 and var_17_16 > 0 then
		local var_17_17 = display.newNode()

		var_17_17:setContentSize(var_17_0, var_17_0)
		xyd.setItemBorder(var_17_17, -17, false, false, var_17_16)
		var_17_17:addTo(arg_17_1)
		var_17_17:setAnchorPoint(cc.p(0, 0))
		var_17_17:setPosition(var_17_4 * (var_17_0 + var_17_1), 0)

		local var_17_18 = {}

		var_17_18.id = -17
		var_17_18.tipsType = 1

		var_0_0:addTips(var_17_17, var_17_18)

		local var_17_19 = var_17_4 + 1
	end

	return arg_17_1
end

return var_0_1
