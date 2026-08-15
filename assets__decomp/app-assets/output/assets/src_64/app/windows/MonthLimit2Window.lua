local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = class("MonthLimit2Window", import("app.windows.GardenSeedWindow"))
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityMonthLimit2
local var_0_4 = import("framework.scheduler")

function var_0_1.getActivityInfo(arg_1_0)
	arg_1_0.activity = arg_1_0.activitiesModel:getActivityInfo(xyd.Activities.MonthLimit2)
	arg_1_0.details = arg_1_0.activity.details
end

function var_0_1.willOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 0))

	local var_2_0 = arg_2_0:nodeByName("close_btn")
	local var_2_1 = var_2_0:getScale()

	var_2_0:addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(var_2_0, arg_3_1, nil, var_2_1)

		if arg_3_1 == ccui.TouchEventType.ended and arg_2_0.scrollViewMoved_ ~= true then
			xyd.WindowManager.get():closeWindow(arg_2_0)
		end
	end)
end

function var_0_1.loadItem(arg_4_0)
	return xyd.AssetLoader.get():loadNodeFromJson("windows/month_limit2/item.csb")
end

function var_0_1.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = tonumber(arg_5_0.details.base_info.award_ids[arg_5_1])
	local var_5_1 = tonumber(arg_5_0.details.base_info.buy_times[arg_5_1])
	local var_5_2 = display.newNode()
	local var_5_3 = arg_5_0:loadItem()
	local var_5_4 = var_5_3:getChildByName("container")
	local var_5_5 = var_0_3:charge(var_5_0)
	local var_5_6 = var_0_3:buyLimit(var_5_0)
	local var_5_7 = var_0_3:originalCharge(var_5_0)

	if var_0_3:vipLimit(var_5_0) > arg_5_0.selfPlayer.vip then
		return var_5_2
	end

	arg_5_0:rewardFormat(var_5_4:getChildByName("reward_container"), var_0_3:giftId(var_5_0), nil, 5)
	var_5_4:getChildByName("name_txt"):setString(var_0_3:name(var_5_0))
	var_5_4:getChildByName("name_txt"):enableOutline(cc.c4b(57, 104, 142, 255), 2)
	var_5_4:getChildByName("price_text"):setString(var_0_2:translation("PRICE_TEXT"))
	var_5_4:getChildByName("org_price_txt"):setString(string.format(var_0_2:translation("ACTIVITY_TIME_LIMIT_4"), var_5_7))
	var_5_4:getChildByName("price_txt"):setString(string.format(var_0_2:translation("ACTIVITY_TIME_LIMIT_4"), var_5_5))

	if var_5_6 > 0 then
		var_5_4:getChildByName("limit_time_txt"):setString(string.format(var_0_2:translation("STICK_BLESS_BUY_LIMIT"), var_5_1, var_5_6))
	else
		var_5_4:getChildByName("limit_time_txt"):setString("")
	end

	var_5_4:getChildByName("vip_txt"):setString(string.format(var_0_2:translation("ACTIVITY1150_VIP_TIP"), xyd.tables.gift:vipExp(var_0_3:giftId(var_5_0))))

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
		-- block empty
	else
		var_5_9:setTouchEnabled(false)
		var_5_9:setBright(false)
	end

	var_5_9:addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(var_5_9, arg_6_1)

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
			xyd.WindowManager.get():closeWindow("activity_balloon_buy_dart")
		end
	end)
	var_5_3:addTo(var_5_2)
	var_5_3:setAnchorPoint(cc.p(0, 0))
	var_5_2:setContentSize(var_5_4:getContentSize().width + 2, var_5_4:getContentSize().height + 4)
	var_5_3:setPosition(cc.p(1, 2))
	var_5_3:setName("source")

	return var_5_2
end

function var_0_1.purchaseGiftBag(arg_7_0, arg_7_1)
	local var_7_0 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_7_1
		}, {}, arg_7_1, false, var_0_3:charge(arg_7_1), var_0_3:name(arg_7_1))
	elseif device.platform == "ios" then
		local var_7_1 = var_0_3:iosProductId(arg_7_1)

		xyd.sdkPurchase(var_7_1, var_7_0, arg_7_1, {}, {}, {
			arg_7_1
		})
	end
end

function var_0_1.setTxt(arg_8_0)
	arg_8_0.container:getChildByName("rule_txt"):setString(xyd.tables.activities:desc(arg_8_0.activity.table_id))
	arg_8_0.container:getChildByName("down_time_text"):setString(var_0_2:translation("TEAM_DRINK_LEFT_TIME"))
end

function var_0_1.rewardFormat(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0 = arg_9_1:getContentSize().height - 10
	local var_9_1 = arg_9_4 or var_9_0 / 4
	local var_9_2 = xyd.tables.gift:items(arg_9_2)

	if #var_9_2 == 1 and var_9_2[1] == 0 then
		var_9_2 = {}
	end

	local var_9_3 = xyd.tables.gift:itemNum(arg_9_2)
	local var_9_4 = #var_9_2

	for iter_9_0 = 1, #var_9_2 do
		local var_9_5 = display.newNode()

		var_9_5:setContentSize(var_9_0, var_9_0)

		if xyd.tables.item:type(var_9_2[iter_9_0]) == -1 then
			xyd.setAvatarBorder(var_9_2[iter_9_0], var_9_5, 1, xyd.tables.hero:initialStar(var_9_2[iter_9_0]))
		else
			xyd.setItemBorder(var_9_5, var_9_2[iter_9_0], false, false, var_9_3[iter_9_0])
		end

		var_9_5:addTo(arg_9_1)
		var_9_5:setAnchorPoint(cc.p(0, 0))
		var_9_5:setPosition((iter_9_0 - 1) * (var_9_0 + var_9_1), 0)

		local var_9_6 = {
			id = var_9_2[iter_9_0],
			lev = xyd.tables.item:level(var_9_2[iter_9_0])
		}

		if xyd.tables.item:type(var_9_2[iter_9_0]) == -1 then
			var_9_6.tipsType = 0
			var_9_6.desc1 = xyd.tables.hero:getDes(var_9_2[iter_9_0])
		elseif specialItem then
			var_9_6.tipsType = 1
			var_9_6.id = -3
		else
			var_9_6.tipsType = 1
			var_9_6.desc1 = xyd.tables.item:desc1(var_9_2[iter_9_0])
			var_9_6.desc2 = xyd.tables.item:desc2(var_9_2[iter_9_0])
		end

		var_9_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_9_2[iter_9_0])
		var_9_6.name = xyd.tables.item:name(var_9_2[iter_9_0])

		var_0_0:addTips(var_9_5, var_9_6)
	end

	local var_9_7 = xyd.tables.gift:skinFragment(arg_9_2)

	if var_9_7 and var_9_7 > 0 then
		local var_9_8 = display.newNode()

		var_9_8:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_8, -101, false, false, var_9_7)
		var_9_8:addTo(arg_9_1)
		var_9_8:setAnchorPoint(cc.p(0, 0))
		var_9_8:setPosition(var_9_4 * (var_9_0 + var_9_1), 0)

		local var_9_9 = {}

		var_9_9.id = -101
		var_9_9.tipsType = 1

		var_0_0:addTips(var_9_8, var_9_9)

		var_9_4 = var_9_4 + 1
	end

	local var_9_10 = xyd.tables.gift:crystal(arg_9_2)

	if var_9_10 and var_9_10 > 0 then
		local var_9_11 = display.newNode()

		var_9_11:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_11, -1, false, false, var_9_10)
		var_9_11:addTo(arg_9_1)
		var_9_11:setAnchorPoint(cc.p(0, 0))
		var_9_11:setPosition(var_9_4 * (var_9_0 + var_9_1), 0)

		local var_9_12 = {}

		var_9_12.id = -1
		var_9_12.tipsType = 1

		var_0_0:addTips(var_9_11, var_9_12)

		var_9_4 = var_9_4 + 1
	end

	local var_9_13 = xyd.tables.gift:mana(arg_9_2)

	if var_9_13 and var_9_13 > 0 then
		local var_9_14 = display.newNode()

		var_9_14:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_14, -2, false, false, var_9_13)
		var_9_14:addTo(arg_9_1)
		var_9_14:setAnchorPoint(cc.p(0, 0))
		var_9_14:setPosition(var_9_4 * (var_9_0 + var_9_1), 0)

		local var_9_15 = {}

		var_9_15.id = -2
		var_9_15.tipsType = 1

		var_0_0:addTips(var_9_14, var_9_15)

		var_9_4 = var_9_4 + 1
	end

	local var_9_16 = xyd.tables.gift:skinCoin(arg_9_2)

	if var_9_16 and var_9_16 > 0 then
		local var_9_17 = display.newNode()

		var_9_17:setContentSize(var_9_0, var_9_0)
		xyd.setItemBorder(var_9_17, -17, false, false, var_9_16)
		var_9_17:addTo(arg_9_1)
		var_9_17:setAnchorPoint(cc.p(0, 0))
		var_9_17:setPosition(var_9_4 * (var_9_0 + var_9_1), 0)

		local var_9_18 = {}

		var_9_18.id = -17
		var_9_18.tipsType = 1

		var_0_0:addTips(var_9_17, var_9_18)

		local var_9_19 = var_9_4 + 1
	end

	return arg_9_1
end

return var_0_1
