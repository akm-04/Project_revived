local var_0_0 = class("MessagePush", import(".BaseModel"))
local var_0_1 = xyd.tables.messagePush

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
	arg_1_0:init()
	arg_1_0:onRegister()
end

function var_0_0.init(arg_2_0)
	arg_2_0.states_ = {}
end

function var_0_0.onRegister(arg_3_0)
	arg_3_0:registerEvent(cc.mvc.AppBase.APP_ENTER_BACKGROUND_EVENT, handler(arg_3_0, arg_3_0.registerNotification))
	arg_3_0:registerEvent(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(arg_3_0, arg_3_0.unregisterNotification))
end

function var_0_0.title(arg_4_0, arg_4_1)
	return var_0_1:title(arg_4_1)
end

function var_0_0.tip(arg_5_0, arg_5_1)
	return var_0_1:tip(arg_5_1)
end

function var_0_0.update(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1 or {}

	arg_6_0.states_ = {}

	for iter_6_0, iter_6_1 in pairs(var_0_1.titles_) do
		arg_6_0.states_[iter_6_0] = 0
	end

	for iter_6_2, iter_6_3 in ipairs(var_6_0) do
		arg_6_0.states_[iter_6_3] = 1
	end
end

function var_0_0.getState(arg_7_0)
	return arg_7_0.states_
end

function var_0_0.setState(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if arg_8_2 > 0 then
		xyd.Backend.get():request(xyd.mid.MESSAGE_PUSH_ADD, {
			message_type = arg_8_1
		}, function(arg_9_0, arg_9_1, arg_9_2)
			if arg_9_0 == xyd.error.OK then
				arg_8_0.states_[arg_8_1] = arg_8_2
			end

			if arg_8_3 then
				arg_8_3(arg_9_0)
			end
		end)
	else
		xyd.Backend.get():request(xyd.mid.MESSAGE_PUSH_REMOVE, {
			message_type = arg_8_1
		}, function(arg_10_0, arg_10_1, arg_10_2)
			if arg_10_0 == xyd.error.OK then
				arg_8_0.states_[arg_8_1] = arg_8_2
			end

			if arg_8_3 then
				arg_8_3(arg_10_0)
			end
		end)
	end
end

function var_0_0.registerNotification(arg_11_0)
	arg_11_0:unregisterNotification()

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.states_) do
		if iter_11_1 > 0 then
			arg_11_0:scheduleLocalNotification(iter_11_0)
		end
	end
end

function var_0_0.unregisterNotification(arg_12_0)
	for iter_12_0, iter_12_1 in ipairs(arg_12_0.states_) do
		arg_12_0:unscheduleLocalNotification(iter_12_0)
	end
end

function var_0_0.scheduleLocalNotification(arg_13_0, arg_13_1)
	local var_13_0 = xyd.ServerTime.get():getNotificationDelay(arg_13_1)

	if var_13_0 < 1 then
		return
	end

	xyd.scheduleLocalNotification(xyd.getPackageName(), arg_13_1, arg_13_0:title(arg_13_1), arg_13_0:tip(arg_13_1), var_13_0)
end

function var_0_0.unscheduleLocalNotification(arg_14_0, arg_14_1)
	xyd.unscheduleLocalNotification(xyd.getPackageName(), arg_14_1)
end

return var_0_0
