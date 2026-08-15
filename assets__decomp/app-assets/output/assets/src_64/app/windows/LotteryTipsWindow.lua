local var_0_0 = class("LotteryTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.info = arg_1_2
	arg_1_0.delay = arg_1_2.delay or 2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("container")

	var_3_0:getChildByName("text_name"):setString(arg_3_0.info.player_info.player_name)
	var_3_0:getChildByName("text_region"):setString("S" .. xyd.getPlayerRegion(arg_3_0.info.player_info.player_id))
	xyd.setPlayerAvatar(var_3_0:getChildByName("avatar"), arg_3_0.info.player_info)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)

	arg_4_0.schedulerHandler = var_0_1.performWithDelayGlobal(function()
		xyd.WindowManager.get():closeWindow("lottery_tips")
	end, arg_4_0.delay)
end

function var_0_0.didClose(arg_6_0)
	var_0_0.super.didClose()

	if arg_6_0.schedulerHandler ~= nil then
		var_0_1.unscheduleGlobal(arg_6_0.schedulerHandler)
	end
end

function var_0_0.willClose(arg_7_0, arg_7_1)
	var_0_0.super:willClose(arg_7_1)
end

return var_0_0
