local var_0_0 = class("BlackFridayWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityTimeLimit
local var_0_4 = require("framework.scheduler")
local var_0_5 = {
	HAVE_BUY = 2,
	CAN_BUY = 1,
	NOT_BUY = 3
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_1_0:getActivityInfo()
end

function var_0_0.getActivityInfo(arg_2_0)
	arg_2_0.activity = arg_2_0.activitiesModel:getActivityInfo(xyd.Activities.BlackFriday)
	arg_2_0.details = arg_2_0.activity.details
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0.activity

	arg_5_0.isCanBuy = var_5_0.details.is_can_buy or 0
	arg_5_0.chargeId = var_0_3:chargeId(1)

	local var_5_1 = arg_5_0:nodeByName("container")

	buyBtn = var_5_1:getChildByName("btn_buy")

	buyBtn:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0:purchaseGiftBag(arg_5_0.chargeId)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)

	local var_5_2 = var_0_3:charge(arg_5_0.chargeId)
	local var_5_3 = xyd.AssetLoader.get():loadLabel(nil, "chargePrice")

	var_5_3:setString(var_5_2)
	var_5_3:setAnchorPoint(cc.p(1, 0.5))
	var_5_3:addTo(buyBtn)

	local var_5_4 = cc.p(buyBtn:getChildByName("current_price"):getPosition())

	var_5_3:setPosition(cc.p(var_5_4.x + 15, var_5_4.y - 2))
	var_5_3:setName("current_price_num")
	var_5_3:setScale(0.85)
	var_5_1:getChildByName("text_tips"):setString(var_0_2:translation("ACTIVITY_TIME_LIMIT_2"))
	var_5_1:getChildByName("text_price"):setString(var_0_2:translation("ACTIVITY_TIME_LIMIT_3"))

	local var_5_5 = var_0_3:originalCharge(arg_5_0.chargeId)
	local var_5_6 = string.format(var_0_2:translation("ACTIVITY_TIME_LIMIT_4"), var_5_5)

	var_5_1:getChildByName("text_price_num"):setString(var_5_6)
	var_5_1:getChildByName("text_time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_5_1:getChildByName("text_price"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_5_1:getChildByName("text_price_num"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_5_0:updateTimeCount(var_5_1, var_5_0)

	local var_5_7 = xyd.ServerTime.get():getServerTime()
	local var_5_8 = var_0_5.NOT_BUY

	if var_5_7 < var_5_0.start_time or var_5_7 > var_5_0.end_time then
		var_5_8 = var_0_5.NOT_BUY
	elseif arg_5_0.isCanBuy == 1 then
		var_5_8 = var_0_5.CAN_BUY
	else
		var_5_8 = var_0_5.HAVE_BUY
	end

	arg_5_0:updateBtnType(var_5_1:getChildByName("btn_buy"), var_5_8)
	var_0_1:rewardFormat(var_5_1:getChildByName("item_list"), var_0_3:giftId(arg_5_0.chargeId))
end

function var_0_0.updateTimeCount(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1:getChildByName("text_time")

	if arg_7_0.handle_ then
		var_0_4.unscheduleGlobal(arg_7_0.handle_)
	end

	local var_7_1 = arg_7_2.end_time - xyd.ServerTime.get():getServerTime()

	if var_7_1 <= 0 then
		var_7_0:setString(var_0_2:translation("ACTIVITY_TIME_LIMIT_1") .. "00:00:00")

		return
	end

	var_7_0:setString(var_0_2:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_7_1))

	arg_7_0.handle_ = var_0_4.scheduleGlobal(function()
		if var_7_0 and not tolua.isnull(var_7_0) then
			var_7_1 = var_7_1 - 1

			var_7_0:setString(var_0_2:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_7_1))

			if var_7_1 == 0 then
				if arg_7_0.handle_ then
					var_0_4.unscheduleGlobal(arg_7_0.handle_)

					arg_7_0.handle_ = nil
				end

				arg_7_0:updateBtnType(arg_7_1:getChildByName("btn_buy"), var_0_5.NOT_BUY)
			end
		elseif arg_7_0.handle_ then
			var_0_4.unscheduleGlobal(arg_7_0.handle_)

			arg_7_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.updateBtnType(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_2 == var_0_5.CAN_BUY then
		arg_9_1:setTouchEnabled(true)
		arg_9_1:setBright(true)
		arg_9_1:getChildByName("already_buy_gray"):setVisible(false)
	elseif arg_9_2 == var_0_5.HAVE_BUY then
		arg_9_1:setTouchEnabled(false)
		arg_9_1:setBright(false)
		arg_9_1:getChildByName("already_buy_gray"):setVisible(true)
		arg_9_1:getChildByName("current_price_num"):setVisible(false)
		arg_9_1:getChildByName("nts"):setVisible(false)
	else
		arg_9_1:setTouchEnabled(false)
		arg_9_1:setBright(false)
		arg_9_1:getChildByName("already_buy_gray"):setVisible(false)
	end
end

function var_0_0.purchaseGiftBag(arg_10_0, arg_10_1)
	local var_10_0 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_10_1
		}, {}, arg_10_1, false, var_0_3:charge(arg_10_1), var_0_3:chargeName(arg_10_1))
	elseif device.platform == "ios" then
		local var_10_1 = var_0_3:iosProductID(arg_10_1)

		xyd.sdkPurchase(var_10_1, var_10_0, arg_10_1, {}, {}, {
			arg_10_1
		})
	end
end

function var_0_0.willClose(arg_11_0, arg_11_1)
	var_0_0.super.willClose(arg_11_0, arg_11_1)

	if arg_11_0.handle_ then
		var_0_4.unscheduleGlobal(arg_11_0.handle_)

		arg_11_0.handle_ = nil
	end
end

return var_0_0
