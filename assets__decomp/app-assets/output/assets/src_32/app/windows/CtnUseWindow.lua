local var_0_0 = class("CtnUseWindow", import("app.common.ui.BaseWindow"))

var_0_0.USE_TIME = "ctn_use_num_txt"
var_0_0.COST = "cost_total_txt"
var_0_0.GAIN = "gain_total_txt"
var_0_0.OK = "ok_btn"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.costTotal = arg_1_2.costTotal
	arg_1_0.gainTotal = arg_1_2.gainTotal
	arg_1_0.useTimes = arg_1_2.useTimes
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = xyd.tables.translation

	arg_2_0:nodeByName(arg_2_0.USE_TIME):setString(var_2_0:translation("GOLDEN_HAND_DES_1") .. arg_2_0.useTimes .. var_2_0:translation("GOLDEN_HAND_DES_2"))
	arg_2_0:nodeByName(arg_2_0.GAIN):setString("×" .. arg_2_0.gainTotal)
	arg_2_0:nodeByName(arg_2_0.COST):setString("×" .. arg_2_0.costTotal)
	arg_2_0:nodeByName("text_need_cost"):setString(var_2_0:translation("NEED_TO_COST"))
	arg_2_0:nodeByName("text_least_get"):setString(var_2_0:translation("GET_AT_LEAST"))
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName(var_0_0.OK):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName(var_0_0.OK), arg_4_1)
		arg_3_0:buttonHandler(handler(arg_3_0, arg_3_0.confirmCallBack), arg_4_0, arg_4_1)
	end)
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("close"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.buttonHandler(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if arg_6_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_6_2)
		arg_6_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_6_1 then
			arg_6_1(arg_6_2, arg_6_3)
		end
	elseif arg_6_3 == ccui.TouchEventType.began then
		return true
	elseif arg_6_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_6_2)
		arg_6_2:setScale(1)
	end
end

function var_0_0.returnCallBack(arg_7_0)
	xyd.WindowManager.get():closeWindow("ctn_use_window")
end

function var_0_0.confirmCallBack(arg_8_0)
	xyd.WindowManager.get():closeWindow("ctn_use_window")
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CTN_USE_GOLDEN_HAND
	})
end

return var_0_0
