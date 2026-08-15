local var_0_0 = class("DivineMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 100000
local var_0_4 = 1000000

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.is_ten = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	if arg_3_0.is_ten == false then
		arg_3_0:nodeByName("is_ten_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_3_0:nodeByName("coin_text"):setString(var_0_3)
	else
		arg_3_0:nodeByName("is_ten_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_3_0:nodeByName("coin_text"):setString(var_0_4)
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
	arg_4_0:nodeByName("coin_text_Copy"):setString(xyd.tables.translation:translation("TEN_TIMES"))
	arg_4_0:nodeByName("begin_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("divine_select")
		end
	end)
	arg_4_0:nodeByName("light"):setTouchEnabled(true)
	arg_4_0:nodeByName("light"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("divine_buy_light")
		end
	end)
	arg_4_0:nodeByName("close_dandan"):setTouchEnabled(true)
	arg_4_0:nodeByName("close_dandan"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("is_ten_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			if arg_4_0.is_ten == false then
				arg_4_0:nodeByName("is_ten_btn"):setBrightStyle(ccui.BrightStyle.highlight)
				arg_4_0:nodeByName("coin_text"):setString(var_0_4)

				arg_4_0.is_ten = true
			else
				arg_4_0:nodeByName("is_ten_btn"):setBrightStyle(ccui.BrightStyle.normal)
				arg_4_0:nodeByName("coin_text"):setString(var_0_3)

				arg_4_0.is_ten = false
			end
		end
	end)
end

return var_0_0
