local var_0_0 = class("SakuraMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("fruit_factory_bg"):setTouchEnabled(true)
	arg_3_0:nodeByName("fruit_factory_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			xyd.playButtonSound()

			if arg_3_0:getDownTime() > 0 then
				arg_3_0:activityNotOpenTips()

				return
			end

			xyd.WindowManager.get():openWindow("sakura_fruit_factory")
		end
	end)
	arg_3_0:nodeByName("enjoy_sakura_bg"):setTouchEnabled(true)
	arg_3_0:nodeByName("enjoy_sakura_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			xyd.playButtonSound()

			if arg_3_0:getDownTime() > 0 then
				arg_3_0:activityNotOpenTips()

				return
			end

			xyd.WindowManager.get():openWindow("sakura_enjoy")
		end
	end)
	arg_3_0:nodeByName("sakura_battle_bg"):setTouchEnabled(true)
	arg_3_0:nodeByName("sakura_battle_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			xyd.playButtonSound()

			if arg_3_0:getDownTime() > 0 then
				arg_3_0:activityNotOpenTips()

				return
			end

			xyd.WindowManager.get():openWindow("sakura_battle")
		end
	end)
	arg_3_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("sakura_rule")
		end
	end)
	arg_3_0:nodeByName("fruit_factory_txt"):setString(var_0_1:translation("SAKURA_BRANCH_TIP1"))
	arg_3_0:nodeByName("enjoy_sakura__txt"):setString(var_0_1:translation("SAKURA_BRANCH_TIP2"))
	arg_3_0:nodeByName("sakura_battle_txt"):setString(var_0_1:translation("SAKURA_BRANCH_TIP3"))
	arg_3_0:updateDownTime()
end

function var_0_0.activityNotOpenTips(arg_8_0)
	local var_8_0 = var_0_1:translation("SAKURA_NOT_OPEN")

	xyd.WindowManager.get():openWindow("toast", {
		message = var_8_0
	})
end

function var_0_0.updateDownTime(arg_9_0)
	if arg_9_0.handle then
		var_0_2.unscheduleGlobal(arg_9_0.handle)

		arg_9_0.handle = nil
	end

	local var_9_0 = arg_9_0.sakura.activity.end_time - xyd.ServerTime.get():getServerTime()

	arg_9_0:nodeByName("down_time_txt"):setString(xyd.secondsToString1(var_9_0, 3))

	arg_9_0.handle = var_0_2.scheduleGlobal(function()
		var_9_0 = var_9_0 - 1

		if arg_9_0:getDownTime() > 0 then
			arg_9_0:nodeByName("down_time_txt"):setString(var_0_1:translation("SAKURA_NOT_OPEN"))
		elseif var_9_0 <= 0 then
			arg_9_0:nodeByName("down_time_txt"):setString(var_0_1:translation("SAKURA_CLOSED"))
		else
			arg_9_0:nodeByName("down_time_txt"):setString(xyd.secondsToString1(var_9_0, 3))
		end
	end, 1)
end

function var_0_0.getDownTime(arg_11_0)
	return arg_11_0.sakura.activity.start_time - xyd.ServerTime.get():getServerTime()
end

function var_0_0.didClose(arg_12_0, arg_12_1)
	var_0_0.super:didClose(arg_12_1)

	if arg_12_0.handle then
		var_0_2.unscheduleGlobal(arg_12_0.handle)

		arg_12_0.handle = nil
	end
end

return var_0_0
