local var_0_0 = class("ChocolateFruitsConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "chocolate_fruits_confirm"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.alertType = arg_1_2.alertType
	arg_1_0.message = arg_1_2.message
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.open(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	local var_2_0 = arg_2_3 or {}

	var_2_0.alertType = arg_2_0
	var_2_0.message = arg_2_1
	var_2_0.callback = arg_2_2

	return xyd.WindowManager.get():openWindow(var_0_2, var_2_0)
end

function var_0_0.close(arg_3_0)
	xyd.WindowManager.get():closeWindow(var_0_2, arg_3_0)
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
	arg_4_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("cost_tip_txt"):setString(arg_5_0.message[1])

	if arg_5_0.alertType == xyd.AlertType.CONFIRM then
		arg_5_0:nodeByName("close"):setVisible(false)
		arg_5_0:nodeByName("sure_btn"):setPositionX(263)
	end
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	local function var_6_0(arg_7_0)
		if arg_6_0.callback ~= nil then
			arg_6_0.callback(arg_7_0)
		end

		arg_6_0.callback = nil
	end

	arg_6_0:nodeByName("close"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			var_0_0.close(function()
				var_6_0(false)
			end)
		end
	end)
	arg_6_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_10_0, false)
			var_0_0.close(function()
				var_6_0(true)
			end)
		end
	end)
end

return var_0_0
