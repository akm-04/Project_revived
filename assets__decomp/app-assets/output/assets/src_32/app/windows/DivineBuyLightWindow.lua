local var_0_0 = class("DivineBuyLightWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 10
local var_0_3 = 1
local var_0_4 = 10
local var_0_5 = 100

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.is_ten = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("buy_words"):setString(var_0_1:translation("TURN_ON_LIGHT_ALERT"))
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	return
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
	arg_4_0:nodeByName("buy_1_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = string.format(var_0_1:translation("BUY_LIGHT_ALERT"), var_0_3, var_0_4)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_0, function()
				print("buy one")
				xyd.WindowManager.get():closeWindow(arg_4_0)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
	arg_4_0:nodeByName("buy_10_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = string.format(var_0_1:translation("BUY_LIGHT_ALERT"), var_0_2, var_0_5)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_0, function()
				print("buy ten")
				xyd.WindowManager.get():closeWindow(arg_4_0)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
end

return var_0_0
