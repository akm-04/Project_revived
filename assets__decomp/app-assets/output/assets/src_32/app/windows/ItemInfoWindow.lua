local var_0_0 = class("ItemInfoWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:confirmButton_():addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			audio.playSound("sound/button.ogg")
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.willClose(arg_5_0)
	var_0_0.super.willClose(arg_5_0)
	arg_5_0:dispatchEvent({
		name = xyd.event.ITEM_WINDOW_WILL_CLOSE
	})
end

function var_0_0.confirmButton_(arg_6_0)
	return arg_6_0:nodeByName("confirm_button")
end

return var_0_0
