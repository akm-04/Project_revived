local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityTimeLimit
local var_0_3 = require("framework.scheduler")
local var_0_4 = {
	HAVE_BUY = 2,
	CAN_BUY = 1,
	NOT_BUY = 3
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0:layout(arg_2_0.activity, arg_2_0.idx)
end

function var_0_0.layout(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1191/limit_to_buy.csb")

	var_3_0:addTo(arg_3_0.parent)

	arg_3_0.isCanBuy = arg_3_1.details.is_can_buy or 0
	arg_3_0.chargeId = var_0_2:chargeId(3)

	local var_3_1 = var_3_0:getChildByName("container")
	local var_3_2 = var_3_1:getChildByName("btn_buy")

	var_3_2:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_2, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:purchaseGiftBag(arg_3_0.chargeId)
			xyd.WindowManager.get():closeWindow("activities")
		end
	end)

	local var_3_3 = var_3_2:getChildByName("txt")
	local var_3_4 = var_0_2:charge(arg_3_0.chargeId)

	var_3_3:setString(var_3_4 .. "USD")

	local var_3_5 = var_0_2:originalCharge(arg_3_0.chargeId)
	local var_3_6 = string.format(var_0_1:translation("ACTIVITY_TIME_LIMIT_4"), var_3_5)

	var_3_1:getChildByName("text_tips"):setString(var_0_1:translation("ACTIVITY_TIME_LIMIT_2"))
	var_3_1:getChildByName("text_price"):setString(var_0_1:translation("ACTIVITY_TIME_LIMIT_3") .. var_3_6)
	arg_3_0:updateTimeCount(var_3_1, arg_3_1)

	local var_3_7 = xyd.ServerTime.get():getServerTime()
	local var_3_8 = var_0_4.NOT_BUY

	if var_3_7 < arg_3_1.start_time or var_3_7 > arg_3_1.end_time then
		var_3_8 = var_0_4.NOT_BUY
	elseif arg_3_0.isCanBuy == 1 then
		var_3_8 = var_0_4.CAN_BUY
	else
		var_3_8 = var_0_4.HAVE_BUY
	end

	arg_3_0:updateBtnType(var_3_1:getChildByName("btn_buy"), var_3_8)
	arg_3_0:rewardFormat(var_3_1:getChildByName("item_list"), var_0_2:giftId(arg_3_0.chargeId))
end

function var_0_0.updateTimeCount(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1:getChildByName("text_time")

	if arg_5_0.handle_ then
		var_0_3.unscheduleGlobal(arg_5_0.handle_)
	end

	local var_5_1 = arg_5_2.end_time - xyd.ServerTime.get():getServerTime()

	if var_5_1 <= 0 then
		var_5_0:setString(var_0_1:translation("ACTIVITY_TIME_LIMIT_1") .. "00:00:00")

		return
	end

	var_5_0:setString(var_0_1:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_5_1))

	arg_5_0.handle_ = var_0_3.scheduleGlobal(function()
		if var_5_0 and not tolua.isnull(var_5_0) then
			var_5_1 = var_5_1 - 1

			var_5_0:setString(var_0_1:translation("ACTIVITY_TIME_LIMIT_1") .. xyd.secondsToString(var_5_1))

			if var_5_1 == 0 then
				if arg_5_0.handle_ then
					var_0_3.unscheduleGlobal(arg_5_0.handle_)

					arg_5_0.handle_ = nil
				end

				arg_5_0:updateBtnType(arg_5_1:getChildByName("btn_buy"), var_0_4.NOT_BUY)
			end
		elseif arg_5_0.handle_ then
			var_0_3.unscheduleGlobal(arg_5_0.handle_)

			arg_5_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.updateBtnType(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_2 == var_0_4.CAN_BUY then
		arg_7_1:setTouchEnabled(true)
	elseif arg_7_2 == var_0_4.HAVE_BUY then
		arg_7_1:setTouchEnabled(false)
		arg_7_1:getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT5"))
	else
		arg_7_1:setTouchEnabled(false)
	end
end

function var_0_0.purchaseGiftBag(arg_8_0, arg_8_1)
	local var_8_0 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_8_1
		}, {}, arg_8_1, false, var_0_2:charge(arg_8_1), var_0_2:chargeName(arg_8_1))
	elseif device.platform == "ios" then
		local var_8_1 = var_0_2:iosProductID(arg_8_1)

		xyd.sdkPurchase(var_8_1, var_8_0, arg_8_1, {}, {}, {
			arg_8_1
		})
	end
end

function var_0_0.release(arg_9_0)
	if arg_9_0.handle_ then
		var_0_3.unscheduleGlobal(arg_9_0.handle_)

		arg_9_0.handle_ = nil
	end
end

return var_0_0
