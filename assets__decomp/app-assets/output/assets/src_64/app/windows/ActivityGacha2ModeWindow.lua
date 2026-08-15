local var_0_0 = class("ActivityGacha2ModeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 10
local var_0_2 = {
	TEN = 2,
	ONE = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.details = arg_1_2.details
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:initButtons()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.details.times < var_0_1 then
		arg_4_0:nodeByName("gacha_ten"):setVisible(false)
		arg_4_0:nodeByName("gacha_all"):setVisible(true)
	else
		arg_4_0:nodeByName("gacha_ten"):setVisible(true)
		arg_4_0:nodeByName("gacha_all"):setVisible(false)
	end
end

function var_0_0.initButtons(arg_5_0)
	arg_5_0:nodeByName("btn1"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0:getReward(var_0_2.ONE)
		end
	end)
	arg_5_0:nodeByName("btn2"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0:getReward(var_0_2.TEN)
		end
	end)
end

function var_0_0.getReward(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1

	arg_8_0.activitiesModel:getActivityReward2(xyd.Activities.GaCha2, nil, var_8_0, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ACTIVITY_GACHA2_GET_REWARD,
				params = {
					response = arg_9_1,
					sub_id = var_8_0
				}
			})
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
end

return var_0_0
