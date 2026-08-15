local var_0_0 = class("DivineSelectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	return
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
	arg_4_0:nodeByName("select_item_1"):setTouchEnabled(true)
	arg_4_0:nodeByName("select_item_1"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("divine_result")
		end
	end)
	arg_4_0:nodeByName("select_item_2"):setTouchEnabled(true)
	arg_4_0:nodeByName("select_item_2"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("divine_result")
		end
	end)
	arg_4_0:nodeByName("select_item_3"):setTouchEnabled(true)
	arg_4_0:nodeByName("select_item_3"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("divine_result")
		end
	end)
end

function var_0_0.willClose(arg_8_0, arg_8_1)
	var_0_0.super:willClose(arg_8_1)
end

return var_0_0
