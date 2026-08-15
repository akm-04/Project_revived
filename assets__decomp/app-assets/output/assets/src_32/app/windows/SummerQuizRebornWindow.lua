local var_0_0 = class("SummerQuizRebornWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.misc.summerQuizReviveTime

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:createScheduler()
	arg_2_0:addBlockLayerWithNoTouchEvent()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)

	if arg_3_0.handle then
		var_0_2.unscheduleGlobal(arg_3_0.handle)

		arg_3_0.handle = nil
	end

	if arg_3_0.callback then
		arg_3_0.callback()
	end
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super.didClose(arg_4_0, arg_4_1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("tip_txt2"):setString(var_0_1:translation("QUIZ_REBORN_TIP2"))
	arg_5_0:nodeByName("tip_txt3"):setString(var_0_1:translation("QUIZ_REBORN_TIP3"))
	arg_5_0:nodeByName("tip_txt1"):setString(var_0_1:translation("QUIZ_REBORN_TIP1"))
	arg_5_0:nodeByName("cost_txt"):setString(xyd.tables.misc.summerQuizReviveCost)
	arg_5_0:nodeByName("reborn_text"):setString(var_0_1:translation("SUMMER_TEXT_6"))

	local var_5_0 = cc.c4b(34, 133, 209, 255)

	arg_5_0:nodeByName("tip_txt2"):enableOutline(var_5_0, 2)
	arg_5_0:nodeByName("tip_txt3"):enableOutline(var_5_0, 2)
	arg_5_0:nodeByName("tip_txt1"):enableOutline(var_5_0, 2)
	arg_5_0:nodeByName("cost_txt"):enableOutline(var_5_0, 2)
	arg_5_0:setButtonClick()

	arg_5_0.downTimeLabel = xyd.AssetLoader.get():loadLabel(nil, "summer_reborn_time")

	arg_5_0.downTimeLabel:setString(var_0_3)
	arg_5_0.downTimeLabel:setAnchorPoint(cc.p(0.5, 0))
	arg_5_0.downTimeLabel:addTo(arg_5_0:nodeByName("down_time_pos"))
end

function var_0_0.createScheduler(arg_6_0)
	if arg_6_0.handle then
		var_0_2.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	arg_6_0.startTime = xyd.ServerTime.get():getServerTime()
	arg_6_0.remainTime = var_0_3

	arg_6_0:setDownTime()

	arg_6_0.handle = var_0_2.scheduleGlobal(function()
		arg_6_0.remainTime = var_0_3 - (xyd.ServerTime.get():getServerTime() - arg_6_0.startTime)

		arg_6_0:setDownTime()

		if arg_6_0.remainTime <= 0 then
			if arg_6_0.handle then
				var_0_2.unscheduleGlobal(arg_6_0.handle)

				arg_6_0.handle = nil
			end

			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end, 1)
end

function var_0_0.setDownTime(arg_8_0)
	if arg_8_0 and arg_8_0.downTimeLabel and not tolua.isnull(arg_8_0.downTimeLabel) then
		arg_8_0.downTimeLabel:setString(arg_8_0.remainTime)
	end
end

function var_0_0.setButtonClick(arg_9_0)
	arg_9_0:nodeByName("reborn_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_9_0.selfPlayer.crystal < xyd.tables.misc.summerQuizReviveCost then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_11_0 = {}

					var_11_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
				end, nil, nil, arg_9_0.colorMode)

				return
			end

			local var_10_0 = {}

			arg_9_0.summer:quizRevive(var_10_0, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_9_0)
				end
			end)
		end
	end)
end

return var_0_0
