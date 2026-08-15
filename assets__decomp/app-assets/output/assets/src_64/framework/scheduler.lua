local var_0_0 = {}
local var_0_1 = cc.Director:getInstance():getScheduler()

function var_0_0.scheduleUpdateGlobal(arg_1_0)
	return var_0_1:scheduleScriptFunc(arg_1_0, 0, false)
end

function var_0_0.scheduleGlobal(arg_2_0, arg_2_1)
	return var_0_1:scheduleScriptFunc(arg_2_0, arg_2_1, false)
end

function var_0_0.unscheduleGlobal(arg_3_0)
	var_0_1:unscheduleScriptEntry(arg_3_0)
end

function var_0_0.performWithDelayGlobal(arg_4_0, arg_4_1)
	local var_4_0

	var_4_0 = var_0_1:scheduleScriptFunc(function()
		var_0_0.unscheduleGlobal(var_4_0)
		arg_4_0()
	end, arg_4_1, false)

	return var_4_0
end

return var_0_0
