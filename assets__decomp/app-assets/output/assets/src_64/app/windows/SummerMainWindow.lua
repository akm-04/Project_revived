local var_0_0 = class("SummerMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)

	if arg_3_0.handle then
		var_0_2.unscheduleGlobal(arg_3_0.handle)

		arg_3_0.handle = nil
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("down_time_text"):setString(var_0_1:translation("ACTIVITY_END_TIME"))
	arg_4_0:nodeByName("down_time_txt"):setString("")
	arg_4_0:nodeByName("fish_text"):setString(var_0_1:translation("SUMMER_TEXT_3"))
	arg_4_0:nodeByName("quiz_text"):setString(var_0_1:translation("SUMMER_TEXT_4"))

	local var_4_0 = cc.c4b(52, 58, 90, 255)

	arg_4_0:nodeByName("down_time_text"):enableOutline(var_4_0, 2)
	arg_4_0:createScheduler()
	arg_4_0:setButtonClick()
end

function var_0_0.createScheduler(arg_5_0)
	if arg_5_0.handle then
		var_0_2.unscheduleGlobal(arg_5_0.handle)

		arg_5_0.handle = nil
	end

	local var_5_0 = arg_5_0:getRemainTime()

	arg_5_0:nodeByName("down_time_txt"):setString(xyd.secondsToString1(var_5_0, 3))

	arg_5_0.handle = var_0_2.scheduleGlobal(function()
		var_5_0 = var_5_0 - 1

		if arg_5_0 and arg_5_0:nodeByName("down_time_txt") and not tolua.isnull(arg_5_0:nodeByName("down_time_txt")) then
			arg_5_0:nodeByName("down_time_txt"):setString(xyd.secondsToString1(var_5_0, 3))
		end

		if var_5_0 <= 0 and arg_5_0.handle then
			var_0_2.unscheduleGlobal(arg_5_0.handle)

			arg_5_0.handle = nil

			arg_5_0:nodeByName("down_time_txt"):setString("")
		end
	end, 1)
end

function var_0_0.getRemainTime(arg_7_0)
	local var_7_0 = arg_7_0.summer.activity.end_time - xyd.ServerTime.get():getServerTime()

	if var_7_0 < 0 then
		var_7_0 = 0
	end

	return var_7_0
end

function var_0_0.setButtonClick(arg_8_0)
	arg_8_0:nodeByName("fish"):setTouchEnabled(true)
	arg_8_0:nodeByName("fish"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			arg_8_0:nodeByName("fish"):setScale(0.9)

			return true
		elseif arg_9_0.name == "ended" then
			xyd.playButtonSound()
			arg_8_0:nodeByName("fish"):setScale(1)
			xyd.WindowManager.get():openWindow("summer_fishing")
		end
	end)
	arg_8_0:nodeByName("quiz"):setTouchEnabled(true)
	arg_8_0:nodeByName("quiz"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			arg_8_0:nodeByName("quiz"):setScale(0.9)

			return true
		elseif arg_10_0.name == "ended" then
			xyd.playButtonSound()
			arg_8_0:nodeByName("quiz"):setScale(1)
			xyd.WindowManager.get():openWindow("summer_quiz")
		end
	end)
end

return var_0_0
