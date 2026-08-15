local var_0_0 = class("GiftPushWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.giftPush
local var_0_2 = xyd.tables.translation
local var_0_3 = require("framework.scheduler")
local var_0_4 = 86

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.giftPush = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.showIndex = arg_1_2 and arg_1_2.showIndex or 1
	arg_1_0.giftInfos = arg_1_0.giftPush:getGiftInfo()
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:nodeByName("text_tip"):setString(var_0_2:translation("GIFT_PUSH_TEXT_1"))
	arg_2_0:nodeByName("btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_3_0, arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_2_0:purchaseGiftBag()
			xyd.WindowManager.get():closeWindow(arg_2_0)
		end
	end)
	arg_2_0:nodeByName("right_container"):getChildByName("btn_arrow"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_2_0.showIndex = arg_2_0.showIndex + 1

			arg_2_0:layout()
		end
	end)
	arg_2_0:nodeByName("left_container"):getChildByName("btn_arrow"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_2_0.showIndex = arg_2_0.showIndex - 1

			arg_2_0:layout()
		end
	end)
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0.giftInfos[arg_6_0.showIndex].gift_id
	local var_6_1 = var_0_1:title(var_6_0)
	local var_6_2 = 1 - var_0_1:charge(var_6_0) / var_0_1:originalCharge(var_6_0)
	local var_6_3 = math.floor(var_6_2 * 100)
	local var_6_4 = var_0_1:chargeName(var_6_0)

	arg_6_0:nodeByName("text_desc"):setString(var_6_1)
	arg_6_0:nodeByName("text_off"):setString(var_6_3)
	arg_6_0:nodeByName("text_name"):setString(var_6_4)

	local var_6_5 = var_0_1:charge(var_6_0)

	arg_6_0:nodeByName("text_btn"):setString(var_6_5 .. var_0_2:translation("VIP_WINDOW_TEXT_13"))
	arg_6_0:nodeByName("node_item"):removeAllChildren()

	local var_6_6 = var_0_1:giftId(var_6_0)
	local var_6_7 = clone(xyd.tables.gift:items(var_6_6))
	local var_6_8 = clone(xyd.tables.gift:itemNum(var_6_6))

	if #var_6_7 == 1 and var_6_7[1] == 0 then
		var_6_7 = {}
		var_6_8 = {}
	end

	local var_6_9 = xyd.tables.gift:skinCoin(var_6_6)

	if var_6_9 and var_6_9 > 0 then
		table.insert(var_6_8, var_6_9)
		table.insert(var_6_7, -17)
	end

	local var_6_10 = xyd.tables.gift:crystal(var_6_6)

	if var_6_10 and var_6_10 > 0 then
		table.insert(var_6_8, var_6_10)
		table.insert(var_6_7, -1)
	end

	local var_6_11 = xyd.tables.gift:mana(var_6_6)

	if var_6_11 and var_6_11 > 0 then
		table.insert(var_6_8, var_6_11)
		table.insert(var_6_7, -2)
	end

	for iter_6_0 = 1, #var_6_7 do
		local var_6_12 = display.newNode()

		var_6_12:setContentSize(var_0_4, var_0_4)
		var_6_12:setAnchorPoint(cc.p(0.5, 0.5))
		xyd.setItemAndAddTips(var_6_12, var_6_7[iter_6_0], var_6_8[iter_6_0])
		var_6_12:addTo(arg_6_0:nodeByName("node_item"))
		var_6_12:setPosition(-(#var_6_7 - 1) * 112 / 2 + (iter_6_0 - 1) * 112, 0)
	end

	if arg_6_0.showIndex == 1 then
		arg_6_0:nodeByName("left_container"):setVisible(false)
	else
		arg_6_0:nodeByName("left_container"):setVisible(true)

		local var_6_13 = arg_6_0.showIndex - 1

		arg_6_0:nodeByName("left_container"):getChildByName("text"):setString(var_0_1:chargeName(arg_6_0.giftInfos[var_6_13].gift_id))
	end

	if arg_6_0.showIndex == #arg_6_0.giftInfos then
		arg_6_0:nodeByName("right_container"):setVisible(false)
	else
		arg_6_0:nodeByName("right_container"):setVisible(true)

		local var_6_14 = arg_6_0.showIndex + 1

		arg_6_0:nodeByName("right_container"):getChildByName("text"):setString(var_0_1:chargeName(arg_6_0.giftInfos[var_6_14].gift_id))
	end

	arg_6_0:updateTime()
	arg_6_0.giftPush:count(var_6_0)
end

function var_0_0.purchaseGiftBag(arg_7_0)
	local var_7_0 = arg_7_0.giftInfos[arg_7_0.showIndex].gift_id
	local var_7_1 = true
	local var_7_2 = arg_7_0:getNewIDs()

	if device.platform == "android" then
		xyd.androidPurchase({
			var_7_0
		}, var_7_2, var_7_0, false, var_0_1:charge(var_7_0), var_0_1:chargeName(var_7_0))
	elseif device.platform == "ios" then
		local var_7_3 = var_0_1:iosProductID(var_7_0)

		xyd.sdkPurchase(var_7_3, var_7_1, var_7_0, {}, var_7_2, {
			var_7_0
		})
	end
end

function var_0_0.getNewIDs(arg_8_0)
	local var_8_0 = 80001001
	local var_8_1 = {}

	for iter_8_0, iter_8_1 in pairs(arg_8_0.player.vipChargeData) do
		if tonumber(iter_8_1) == 0 and iter_8_0 ~= var_8_0 then
			table.insert(var_8_1, iter_8_0)
		end
	end

	return var_8_1
end

function var_0_0.updateTime(arg_9_0)
	arg_9_0.time = arg_9_0.giftInfos[arg_9_0.showIndex].push_time + var_0_1:time(arg_9_0.giftInfos[arg_9_0.showIndex].gift_id) - xyd.ServerTime.get():getServerTime()

	if arg_9_0.timeHandle then
		var_0_3.unscheduleGlobal(arg_9_0.timeHandle)

		arg_9_0.timeHandle = nil
	end

	local var_9_0 = xyd.timeFormatAsHMS(arg_9_0.time)

	arg_9_0:nodeByName("text_time"):setString(string.format(var_0_2:translation("GIFT_PUSH_TEXT_2"), var_9_0))

	arg_9_0.timeHandle = var_0_3.scheduleGlobal(function()
		arg_9_0.time = arg_9_0.time - 1

		local var_10_0 = xyd.timeFormatAsHMS(arg_9_0.time)

		arg_9_0:nodeByName("text_time"):setString(string.format(var_0_2:translation("GIFT_PUSH_TEXT_2"), var_10_0))

		if arg_9_0.time <= 0 and arg_9_0.timeHandle then
			arg_9_0:nodeByName("text_time"):setString("")
			var_0_3.unscheduleGlobal(arg_9_0.timeHandle)

			arg_9_0.timeHandle = nil
		end
	end, 1)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super.didOpen(arg_11_0, arg_11_1)
	arg_11_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.willClose(arg_12_0, arg_12_1)
	var_0_0.super.willClose(arg_12_0, arg_12_1)

	if arg_12_0.timeHandle then
		var_0_3.unscheduleGlobal(arg_12_0.timeHandle)

		arg_12_0.timeHandle = nil
	end
end

return var_0_0
