local var_0_0 = class("DragonBoatWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
	arg_3_0:getResumeBtn()
	arg_3_0:getExitBtn()
end

function var_0_0.layout(arg_4_0)
	return
end

function var_0_0.getResumeBtn(arg_5_0)
	if not arg_5_0.resumeBtn_ then
		arg_5_0.resumeBtn_ = arg_5_0:nodeByName("btn_resume")

		arg_5_0.resumeBtn_:addTouchEventListener(function(arg_6_0, arg_6_1)
			arg_5_0:buttonHandler(handler(arg_5_0, arg_5_0.resumeClick), arg_6_0, arg_6_1)
		end)
	end

	return arg_5_0.resumeBtn_
end

function var_0_0.getExitBtn(arg_7_0)
	if not arg_7_0.exitBtn_ then
		arg_7_0.exitBtn_ = arg_7_0:nodeByName("btn_exit")

		arg_7_0.exitBtn_:addTouchEventListener(function(arg_8_0, arg_8_1)
			arg_7_0:buttonHandler(handler(arg_7_0, arg_7_0.exitClick), arg_8_0, arg_8_1)
		end)
	end

	return arg_7_0.exitBtn_
end

function var_0_0.buttonHandler(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if arg_9_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_9_2)
		arg_9_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_9_1 then
			arg_9_1(arg_9_2, arg_9_3)
		end
	elseif arg_9_3 == ccui.TouchEventType.began then
		local var_9_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_9_1 = cc.RepeatForever:create(var_9_0)

		arg_9_2:runAction(var_9_1)

		return true
	elseif arg_9_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_9_2)
		arg_9_2:setScale(1)
	end
end

function var_0_0.resumeClick(arg_10_0)
	arg_10_0:dispatchEvent({
		name = xyd.event.BATTLE_RESUMED
	})
	xyd.WindowManager.get():closeWindow(arg_10_0)
end

function var_0_0.exitClick(arg_11_0)
	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("DRAGONBOAT_QUIT_TIP"), function()
		arg_11_0:dispatchEvent({
			name = xyd.event.EXIT_BATTLE
		})
		xyd.WindowManager.get():closeWindow(arg_11_0)
	end, nil, nil, arg_11_0.colorMode)
end

return var_0_0
