local var_0_0 = class("TeamCantJoinAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.time_ = arg_1_2.time_
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = (arg_3_0.time_ - 1) % 60
	local var_3_1 = math.floor((arg_3_0.time_ - 1) / 60)

	arg_3_0.handle_ = var_0_1.scheduleGlobal(function()
		var_3_0 = arg_3_0.time_ % 60
		var_3_1 = math.floor(arg_3_0.time_ / 60)

		if arg_3_0.time_ and arg_3_0.time_ > 0 then
			arg_3_0.time_ = arg_3_0.time_ - 1

			arg_3_0:nodeByName("text_2"):setString(string.format(var_0_2:translation("GUILD_CANT_JOIN_TIME_ALERT"), var_3_1, var_3_0))
		end
	end, 1)

	arg_3_0:nodeByName("text_1"):setString(var_0_2:translation("GUILD_CANT_JOIN_WORDS_ALERT"))
	arg_3_0:nodeByName("text_2"):setString(string.format(var_0_2:translation("GUILD_CANT_JOIN_TIME_ALERT"), var_3_1, var_3_0))
	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.willClose(arg_6_0, arg_6_1)
	var_0_0.super:willClose(arg_6_1)
	var_0_1.unscheduleGlobal(arg_6_0.handle_)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
