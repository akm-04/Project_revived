local var_0_0 = class("NonFriendPlayer", import(".Player"))

function var_0_0.ctor(arg_1_0)
	var_0_0.super.ctor(arg_1_0)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.populate(arg_3_0, arg_3_1)
	var_0_0.super.populate(arg_3_0, arg_3_1)

	arg_3_0.lastTime_ = tonumber(arg_3_1.last_time)
	arg_3_0.requestTime_ = tonumber(arg_3_1.request_time)
end

return var_0_0
