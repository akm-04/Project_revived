local var_0_0 = import("..Component")
local var_0_1 = class("EventProtocol", var_0_0)

function var_0_1.ctor(arg_1_0)
	var_0_1.super.ctor(arg_1_0, "EventProtocol")

	arg_1_0.listeners_ = {}
	arg_1_0.nextListenerHandleIndex_ = 0
end

function var_0_1.addEventListener(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	assert(type(arg_2_1) == "string" and arg_2_1 ~= "", "EventProtocol:addEventListener() - invalid eventName")

	arg_2_1 = string.upper(arg_2_1)

	if arg_2_0.listeners_[arg_2_1] == nil then
		arg_2_0.listeners_[arg_2_1] = {}
	end

	local var_2_0 = type(arg_2_3)

	if var_2_0 == "table" or var_2_0 == "userdata" then
		PRINT_DEPRECATED("EventProtocol:addEventListener(eventName, listener, target) is deprecated, please use EventProtocol:addEventListener(eventName, handler(target, listener), tag)")

		arg_2_2 = handler(arg_2_3, arg_2_2)
		arg_2_3 = ""
	end

	arg_2_0.nextListenerHandleIndex_ = arg_2_0.nextListenerHandleIndex_ + 1

	local var_2_1 = tostring(arg_2_0.nextListenerHandleIndex_)

	arg_2_3 = arg_2_3 or ""
	arg_2_0.listeners_[arg_2_1][var_2_1] = {
		arg_2_2,
		arg_2_3
	}

	if DEBUG > 1 then
		printInfo("%s [EventProtocol] addEventListener() - event: %s, handle: %s, tag: %s", tostring(arg_2_0.target_), arg_2_1, var_2_1, tostring(arg_2_3))
	end

	return var_2_1
end

function var_0_1.dispatchEvent(arg_3_0, arg_3_1)
	arg_3_1.name = string.upper(tostring(arg_3_1.name))

	local var_3_0 = arg_3_1.name

	if DEBUG > 1 then
		printInfo("%s [EventProtocol] dispatchEvent() - event %s", tostring(arg_3_0.target_), var_3_0)
	end

	if arg_3_0.listeners_[var_3_0] == nil then
		return
	end

	arg_3_1.target = arg_3_0.target_
	arg_3_1.stop_ = false

	function arg_3_1.stop(arg_4_0)
		arg_4_0.stop_ = true
	end

	for iter_3_0, iter_3_1 in pairs(arg_3_0.listeners_[var_3_0]) do
		if DEBUG > 1 then
			printInfo("%s [EventProtocol] dispatchEvent() - dispatching event %s to listener %s", tostring(arg_3_0.target_), var_3_0, iter_3_0)
		end

		arg_3_1.tag = iter_3_1[2]

		iter_3_1[1](arg_3_1)

		if arg_3_1.stop_ then
			if DEBUG > 1 then
				printInfo("%s [EventProtocol] dispatchEvent() - break dispatching for event %s", tostring(arg_3_0.target_), var_3_0)
			end

			break
		end
	end

	return arg_3_0.target_
end

function var_0_1.removeEventListener(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.listeners_) do
		for iter_5_2, iter_5_3 in pairs(iter_5_1) do
			if iter_5_2 == arg_5_1 then
				iter_5_1[iter_5_2] = nil

				if DEBUG > 1 then
					printInfo("%s [EventProtocol] removeEventListener() - remove listener [%s] for event %s", tostring(arg_5_0.target_), iter_5_2, iter_5_0)
				end

				return arg_5_0.target_
			end
		end
	end

	return arg_5_0.target_
end

function var_0_1.removeEventListenersByTag(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.listeners_) do
		for iter_6_2, iter_6_3 in pairs(iter_6_1) do
			if iter_6_3[2] == arg_6_1 then
				iter_6_1[iter_6_2] = nil

				if DEBUG > 1 then
					printInfo("%s [EventProtocol] removeEventListener() - remove listener [%s] for event %s", tostring(arg_6_0.target_), iter_6_2, iter_6_0)
				end
			end
		end
	end

	return arg_6_0.target_
end

function var_0_1.removeEventListenersByEvent(arg_7_0, arg_7_1)
	arg_7_0.listeners_[string.upper(arg_7_1)] = nil

	if DEBUG > 1 then
		printInfo("%s [EventProtocol] removeAllEventListenersForEvent() - remove all listeners for event %s", tostring(arg_7_0.target_), arg_7_1)
	end

	return arg_7_0.target_
end

function var_0_1.removeAllEventListeners(arg_8_0)
	arg_8_0.listeners_ = {}

	if DEBUG > 1 then
		printInfo("%s [EventProtocol] removeAllEventListeners() - remove all listeners", tostring(arg_8_0.target_))
	end

	return arg_8_0.target_
end

function var_0_1.hasEventListener(arg_9_0, arg_9_1)
	arg_9_1 = string.upper(tostring(arg_9_1))

	local var_9_0 = arg_9_0.listeners_[arg_9_1]

	for iter_9_0, iter_9_1 in pairs(var_9_0) do
		return true
	end

	return false
end

function var_0_1.dumpAllEventListeners(arg_10_0)
	print("---- EventProtocol:dumpAllEventListeners() ----")

	for iter_10_0, iter_10_1 in pairs(arg_10_0.listeners_) do
		printf("-- event: %s", iter_10_0)

		for iter_10_2, iter_10_3 in pairs(iter_10_1) do
			printf("--     listener: %s, handle: %s", tostring(iter_10_3[1]), tostring(iter_10_2))
		end
	end

	return arg_10_0.target_
end

function var_0_1.exportMethods(arg_11_0)
	arg_11_0:exportMethods_({
		"addEventListener",
		"dispatchEvent",
		"removeEventListener",
		"removeEventListenersByTag",
		"removeEventListenersByEvent",
		"removeAllEventListenersForEvent",
		"removeAllEventListeners",
		"hasEventListener",
		"dumpAllEventListeners"
	})

	return arg_11_0.target_
end

function var_0_1.onBind_(arg_12_0)
	return
end

function var_0_1.onUnbind_(arg_13_0)
	return
end

return var_0_1
