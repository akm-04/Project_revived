local var_0_0 = class("TeamAfternoonTeaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	var_0_0.super:didOpen(arg_3_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.DRINK_NOTIF, handler(arg_3_0, arg_3_0.updateGuildNotif))
	arg_3_0:updateGuildNotif(nil)
	arg_3_0:nodeByName("drink_self_icon"):setTouchEnabled(true)
	arg_3_0:nodeByName("drink_self_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0.guild:loadDrinkInfo(function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					xyd.playButtonSound()
					xyd.WindowManager.get():openWindow("drink_self")
				end
			end)
		end
	end)
	arg_3_0:nodeByName("treat_icon"):setTouchEnabled(true)
	arg_3_0:nodeByName("treat_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("drink_others")
		end
	end)
	arg_3_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("tea_rule")
		end
	end)
	arg_3_0:nodeByName("close_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_8_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.updateGuildNotif(arg_9_0, arg_9_1)
	local var_9_0 = 0
	local var_9_1 = 0
	local var_9_2 = 0

	if arg_9_0.guild.normal_time and arg_9_0.guild.normal_time > 0 and arg_9_0.guild.normal_drink_times > 0 and arg_9_0.guild.normal_have_drink == 0 then
		var_9_0 = arg_9_0.guild.normal_time
	end

	if arg_9_0.guild.special_time and arg_9_0.guild.special_time > 0 and arg_9_0.guild.special_drink_times > 0 and arg_9_0.guild.special_have_drink == 0 then
		var_9_1 = arg_9_0.guild.special_time
	end

	if var_9_0 <= var_9_1 then
		var_9_2 = var_9_1
	else
		var_9_2 = var_9_0
	end

	if arg_9_0.handle_ then
		var_0_1.unscheduleGlobal(arg_9_0.handle_)
	elseif var_9_2 <= 0 then
		if arg_9_0.guild.free_have_drink == 0 then
			arg_9_0:nodeByName("guild_notif"):setVisible(true)
		else
			arg_9_0:nodeByName("guild_notif"):setVisible(false)
		end
	else
		arg_9_0:nodeByName("guild_notif"):setVisible(true)
	end

	arg_9_0.handle_ = var_0_1.scheduleGlobal(function()
		if var_9_2 <= 0 then
			if arg_9_0.guild.free_have_drink == 0 then
				arg_9_0:nodeByName("guild_notif"):setVisible(true)
			else
				arg_9_0:nodeByName("guild_notif"):setVisible(false)
			end

			var_0_1.unscheduleGlobal(arg_9_0.handle_)
		else
			var_9_2 = var_9_2 - 1

			arg_9_0:nodeByName("guild_notif"):setVisible(true)
		end
	end, 1)
end

function var_0_0.willClose(arg_11_0, arg_11_1)
	var_0_0.super:willClose(arg_11_1)

	if arg_11_0.handle_ then
		var_0_1.unscheduleGlobal(arg_11_0.handle_)
	end
end

return var_0_0
