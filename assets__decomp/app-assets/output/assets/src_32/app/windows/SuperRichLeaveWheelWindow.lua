local var_0_0 = class("SuperRichLeaveWheelWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("leave_text"):setString(var_0_1:translation("RICH_IS_GO"))
	arg_4_0:nodeByName("leave_text"):setContentSize(200, 60)
	arg_4_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_5_0)
	arg_5_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.callback(arg_5_0.selectPoint)
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:nodeByName("ensure_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.callback(arg_5_0.selectPoint)
			xyd.WindowManager.get():closeWindow(arg_5_0)
			xyd.WindowManager.get():closeWindow("super_rich_wheel")
		end
	end)
end

return var_0_0
