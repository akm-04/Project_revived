local var_0_0 = class("SocialSystemWaitingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.friendID = arg_1_2.friend_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("waiting_text"):setString(var_0_2:translation("WAITING_TEXT"))
	arg_4_0:nodeByName("cancle_text"):setString(var_0_2:translation("CANCEL"))
	arg_4_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:createPointsScheduler()
end

function var_0_0.setHasRefusedShow(arg_6_0)
	if arg_6_0.handle then
		var_0_1.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	arg_6_0:nodeByName("points_txt"):setVisible(false)
	arg_6_0:nodeByName("waiting_text"):setString(var_0_2:translation("SOCIAL_REJECT_TEXT"))
	arg_6_0:nodeByName("waiting_text"):setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0:nodeByName("waiting_text"):setPositionX(arg_6_0:nodeByName("container"):getContentSize().width / 2)
	arg_6_0:nodeByName("cancle_text"):setString(var_0_2:translation("OK"))
end

function var_0_0.createPointsScheduler(arg_7_0)
	local var_7_0 = 0

	arg_7_0:nodeByName("points_txt"):setString(arg_7_0:createPointsText(var_7_0))

	arg_7_0.handle = var_0_1.scheduleGlobal(function()
		if not arg_7_0 or tolua.isnull(arg_7_0) then
			var_0_1.unscheduleGlobal(arg_7_0.handle)

			arg_7_0.handle = nil
		end

		var_7_0 = (var_7_0 + 1) % (var_0_3 + 1)

		local var_8_0 = arg_7_0:createPointsText(var_7_0)

		arg_7_0:nodeByName("points_txt"):setString(var_8_0)
	end, 1)
end

function var_0_0.createPointsText(arg_9_0, arg_9_1)
	local var_9_0 = ""

	for iter_9_0 = 1, arg_9_1 do
		var_9_0 = var_9_0 .. "."
	end

	return var_9_0
end

function var_0_0.didClose(arg_10_0, arg_10_1)
	var_0_0.super:didClose(arg_10_1)

	if arg_10_0.handle then
		var_0_1.unscheduleGlobal(arg_10_0.handle)

		arg_10_0.handle = nil
	end
end

return var_0_0
