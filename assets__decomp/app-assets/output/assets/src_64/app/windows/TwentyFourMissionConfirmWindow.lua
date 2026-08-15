local var_0_0 = class("TwentyFourMissionConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc:getValue("activity_twenty_four_mission_id")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.skinItemIndex = arg_1_2.skinItemIndex
	arg_1_0.skinItem = arg_1_2.skinItem
	arg_1_0.activity = arg_1_2.activity
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title"):setString(var_0_1:translation("TIP"))
	arg_3_0:nodeByName("text_1"):setString(var_0_1:translation("ACTIVITY_TWENTY_FOUR_TEXT_9"))
	arg_3_0:nodeByName("text_3"):setString(var_0_1:translation("ACTIVITY_TWENTY_FOUR_TEXT_10"))
	arg_3_0:nodeByName("confirm_text"):setString(var_0_1:translation("CONFIRM"))
	arg_3_0:nodeByName("close_text"):setString(var_0_1:translation("CANCEL"))
	arg_3_0:nodeByName("text_2"):setString(xyd.tables.item:name(arg_3_0.skinItem))
	arg_3_0:nodeByName("text_2"):setPositionX(arg_3_0:nodeByName("text_1"):getPositionX() + 20)
	arg_3_0:nodeByName("text_3"):setPositionX(arg_3_0:nodeByName("text_2"):getPositionX() + arg_3_0:nodeByName("text_2"):getWidth() + 20)
	arg_3_0:nodeByName("confirm_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("confirm_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0.activitiesModel:getActivityReward2(xyd.Activities.TwentyFourMission, var_0_2, arg_3_0.skinItemIndex, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK and arg_5_1.awards then
					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_5_1.awards)

					if arg_3_0.callback then
						arg_3_0.callback(arg_5_1)
					end

					local var_5_0 = xyd.WindowManager.get():getWindow("activity_twenty_four_mission_award")

					if var_5_0 then
						xyd.WindowManager.get():closeWindow(var_5_0)
					end

					if arg_3_0.activity then
						arg_3_0.activity:hideProgress()
					end

					xyd.WindowManager.get():closeWindow(arg_3_0)
				end
			end)
		end
	end)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
