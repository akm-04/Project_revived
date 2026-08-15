local var_0_0 = class("EventProxy")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.eventDispatcher_ = arg_1_1
	arg_1_0.handles_ = {}

	if arg_1_2 then
		cc(arg_1_2):addNodeEventListener(cc.NODE_EVENT, function(arg_2_0)
			if arg_2_0.name == "exit" then
				arg_1_0:removeAllEventListeners()
			end
		end)
	end
end

function var_0_0.addEventListener(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = arg_3_0.eventDispatcher_:addEventListener(arg_3_1, arg_3_2, arg_3_3)

	arg_3_0.handles_[#arg_3_0.handles_ + 1] = {
		arg_3_1,
		var_3_0
	}

	return arg_3_0, var_3_0
end

function var_0_0.removeEventListener(arg_4_0, arg_4_1)
	arg_4_0.eventDispatcher_:removeEventListener(arg_4_1)

	for iter_4_0, iter_4_1 in pairs(arg_4_0.handles_) do
		if iter_4_1[2] == arg_4_1 then
			table.remove(arg_4_0.handles_, iter_4_0)

			break
		end
	end

	return arg_4_0
end

function var_0_0.removeAllEventListenersForEvent(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.handles_) do
		if iter_5_1[1] == arg_5_1 then
			arg_5_0.eventDispatcher_:removeEventListenersByEvent(arg_5_1)

			arg_5_0.handles_[iter_5_0] = nil
		end
	end

	return arg_5_0
end

function var_0_0.getEventHandle(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.handles_) do
		if iter_6_1[1] == arg_6_1 then
			return iter_6_1[2]
		end
	end
end

function var_0_0.removeAllEventListeners(arg_7_0)
	for iter_7_0, iter_7_1 in pairs(arg_7_0.handles_) do
		arg_7_0.eventDispatcher_:removeEventListener(iter_7_1[2])
	end

	arg_7_0.handles_ = {}

	return arg_7_0
end

return var_0_0
