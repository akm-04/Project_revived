local var_0_0 = class("CountDown")
local var_0_1 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.seconds_ = arg_1_1

	if arg_1_0.seconds_ < 0 then
		arg_1_0.seconds_ = 0
	end
end

function var_0_0.start(arg_2_0, arg_2_1)
	if arg_2_0.isRunning_ then
		return
	end

	arg_2_0.isRunning_ = true
	arg_2_0.lastTime_ = os.time()
	arg_2_0.handle_ = var_0_1.scheduleGlobal(function(arg_3_0)
		local var_3_0 = os.time()

		arg_2_0.seconds_ = arg_2_0.seconds_ - (var_3_0 - arg_2_0.lastTime_)
		arg_2_0.lastTime_ = var_3_0

		if arg_2_1 then
			arg_2_1(arg_2_0.seconds_)
		end

		if arg_2_0.seconds_ <= 0 then
			arg_2_0:stop()
		end
	end, 1)
end

function var_0_0.stop(arg_4_0)
	if arg_4_0.handle_ then
		var_0_1.unscheduleGlobal(arg_4_0.handle_)

		arg_4_0.handle_ = nil
	end

	arg_4_0.isRunning_ = false
end

function var_0_0.setSeconds(arg_5_0, arg_5_1)
	arg_5_0.seconds_ = arg_5_1 or arg_5_0.seconds_
end

return var_0_0
