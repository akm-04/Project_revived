local var_0_0 = class("NewTermWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:registerListeners()
end

function var_0_0.registerListeners(arg_5_0)
	arg_5_0:nodeByName("make_present_container"):getChildByName("photo"):setTouchEnabled(true)
	arg_5_0:nodeByName("make_present_container"):getChildByName("photo"):setTouchSwallowEnabled(false)
	arg_5_0:nodeByName("make_present_container"):getChildByName("photo"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.WindowManager.get():openWindow("new_term_make_present")
		end

		return true
	end)
	arg_5_0:nodeByName("give_present_container"):getChildByName("photo"):setTouchEnabled(true)
	arg_5_0:nodeByName("give_present_container"):getChildByName("photo"):setTouchSwallowEnabled(false)
	arg_5_0:nodeByName("give_present_container"):getChildByName("photo"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "ended" then
			xyd.WindowManager.get():openWindow("new_term_give_gift")
		end

		return true
	end)
	arg_5_0:nodeByName("bonus_container"):getChildByName("photo"):setTouchEnabled(true)
	arg_5_0:nodeByName("bonus_container"):getChildByName("photo"):setTouchSwallowEnabled(false)
	arg_5_0:nodeByName("bonus_container"):getChildByName("photo"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "ended" then
			xyd.ModelManager.get():loadModel(xyd.ModelType.NEW_TERMS):loadInfo({}, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("new_term_bonus")
				end
			end)
		end

		return true
	end)
end

function var_0_0.willClose(arg_10_0)
	if arg_10_0.handle then
		var_0_3.unscheduleGlobal(arg_10_0.handle)

		arg_10_0.handle = nil
	end
end

return var_0_0
