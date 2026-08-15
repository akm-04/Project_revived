local var_0_0 = import("..Component")
local var_0_1 = class("StateMachine", var_0_0)

var_0_1.VERSION = "2.2.0"
var_0_1.SUCCEEDED = 1
var_0_1.NOTRANSITION = 2
var_0_1.CANCELLED = 3
var_0_1.PENDING = 4
var_0_1.FAILURE = 5
var_0_1.INVALID_TRANSITION_ERROR = "INVALID_TRANSITION_ERROR"
var_0_1.PENDING_TRANSITION_ERROR = "PENDING_TRANSITION_ERROR"
var_0_1.INVALID_CALLBACK_ERROR = "INVALID_CALLBACK_ERROR"
var_0_1.WILDCARD = "*"
var_0_1.ASYNC = "ASYNC"

function var_0_1.ctor(arg_1_0)
	var_0_1.super.ctor(arg_1_0, "StateMachine")
end

function var_0_1.setupState(arg_2_0, arg_2_1)
	assert(type(arg_2_1) == "table", "StateMachine:ctor() - invalid config")

	if type(arg_2_1.initial) == "string" then
		arg_2_0.initial_ = {
			state = arg_2_1.initial
		}
	else
		arg_2_0.initial_ = clone(arg_2_1.initial)
	end

	arg_2_0.terminal_ = arg_2_1.terminal or arg_2_1.final
	arg_2_0.events_ = arg_2_1.events or {}
	arg_2_0.callbacks_ = arg_2_1.callbacks or {}
	arg_2_0.map_ = {}
	arg_2_0.current_ = "none"
	arg_2_0.inTransition_ = false

	if arg_2_0.initial_ then
		arg_2_0.initial_.event = arg_2_0.initial_.event or "startup"

		arg_2_0:addEvent_({
			from = "none",
			name = arg_2_0.initial_.event,
			to = arg_2_0.initial_.state
		})
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.events_) do
		arg_2_0:addEvent_(iter_2_1)
	end

	if arg_2_0.initial_ and not arg_2_0.initial_.defer then
		arg_2_0:doEvent(arg_2_0.initial_.event)
	end

	return arg_2_0.target_
end

function var_0_1.isReady(arg_3_0)
	return arg_3_0.current_ ~= "none"
end

function var_0_1.getState(arg_4_0)
	return arg_4_0.current_
end

function var_0_1.isState(arg_5_0, arg_5_1)
	if type(arg_5_1) == "table" then
		for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
			if iter_5_1 == arg_5_0.current_ then
				return true
			end
		end

		return false
	else
		return arg_5_0.current_ == arg_5_1
	end
end

function var_0_1.canDoEvent(arg_6_0, arg_6_1)
	return not arg_6_0.inTransition_ and (arg_6_0.map_[arg_6_1][arg_6_0.current_] ~= nil or arg_6_0.map_[arg_6_1][var_0_1.WILDCARD] ~= nil)
end

function var_0_1.cannotDoEvent(arg_7_0, arg_7_1)
	return not arg_7_0:canDoEvent(arg_7_1)
end

function var_0_1.isFinishedState(arg_8_0)
	return arg_8_0:isState(arg_8_0.terminal_)
end

function var_0_1.doEventForce(arg_9_0, arg_9_1, ...)
	local var_9_0 = arg_9_0.current_
	local var_9_1 = arg_9_0.map_[arg_9_1]
	local var_9_2 = var_9_1[var_9_0] or var_9_1[var_0_1.WILDCARD] or var_9_0
	local var_9_3 = {
		...
	}
	local var_9_4 = {
		name = arg_9_1,
		from = var_9_0,
		to = var_9_2,
		args = var_9_3
	}

	if arg_9_0.inTransition_ then
		arg_9_0.inTransition_ = false
	end

	arg_9_0:beforeEvent_(var_9_4)

	if var_9_0 == var_9_2 then
		arg_9_0:afterEvent_(var_9_4)

		return var_0_1.NOTRANSITION
	end

	arg_9_0.current_ = var_9_2

	arg_9_0:enterState_(var_9_4)
	arg_9_0:changeState_(var_9_4)
	arg_9_0:afterEvent_(var_9_4)

	return var_0_1.SUCCEEDED
end

function var_0_1.doEvent(arg_10_0, arg_10_1, ...)
	assert(arg_10_0.map_[arg_10_1] ~= nil, string.format("StateMachine:doEvent() - invalid event %s", tostring(arg_10_1)))

	local var_10_0 = arg_10_0.current_
	local var_10_1 = arg_10_0.map_[arg_10_1]
	local var_10_2 = var_10_1[var_10_0] or var_10_1[var_0_1.WILDCARD] or var_10_0
	local var_10_3 = {
		...
	}
	local var_10_4 = {
		name = arg_10_1,
		from = var_10_0,
		to = var_10_2,
		args = var_10_3
	}

	if arg_10_0.inTransition_ then
		arg_10_0:onError_(var_10_4, var_0_1.PENDING_TRANSITION_ERROR, "event " .. arg_10_1 .. " inappropriate because previous transition did not complete")

		return var_0_1.FAILURE
	end

	if arg_10_0:cannotDoEvent(arg_10_1) then
		arg_10_0:onError_(var_10_4, var_0_1.INVALID_TRANSITION_ERROR, "event " .. arg_10_1 .. " inappropriate in current state " .. arg_10_0.current_)

		return var_0_1.FAILURE
	end

	if arg_10_0:beforeEvent_(var_10_4) == false then
		return var_0_1.CANCELLED
	end

	if var_10_0 == var_10_2 then
		arg_10_0:afterEvent_(var_10_4)

		return var_0_1.NOTRANSITION
	end

	function var_10_4.transition()
		arg_10_0.inTransition_ = false
		arg_10_0.current_ = var_10_2

		arg_10_0:enterState_(var_10_4)
		arg_10_0:changeState_(var_10_4)
		arg_10_0:afterEvent_(var_10_4)

		return var_0_1.SUCCEEDED
	end

	function var_10_4.cancel()
		var_10_4.transition = nil

		arg_10_0:afterEvent_(var_10_4)
	end

	arg_10_0.inTransition_ = true

	local var_10_5 = arg_10_0:leaveState_(var_10_4)

	if var_10_5 == false then
		var_10_4.transition = nil
		var_10_4.cancel = nil
		arg_10_0.inTransition_ = false

		return var_0_1.CANCELLED
	elseif string.upper(tostring(var_10_5)) == var_0_1.ASYNC then
		return var_0_1.PENDING
	elseif var_10_4.transition then
		return var_10_4.transition()
	else
		arg_10_0.inTransition_ = false
	end
end

function var_0_1.exportMethods(arg_13_0)
	arg_13_0:exportMethods_({
		"setupState",
		"isReady",
		"getState",
		"isState",
		"canDoEvent",
		"cannotDoEvent",
		"isFinishedState",
		"doEventForce",
		"doEvent"
	})

	return arg_13_0.target_
end

function var_0_1.onBind_(arg_14_0)
	return
end

function var_0_1.onUnbind_(arg_15_0)
	return
end

function var_0_1.addEvent_(arg_16_0, arg_16_1)
	local var_16_0 = {}

	if type(arg_16_1.from) == "table" then
		for iter_16_0, iter_16_1 in ipairs(arg_16_1.from) do
			var_16_0[iter_16_1] = true
		end
	elseif arg_16_1.from then
		var_16_0[arg_16_1.from] = true
	else
		var_16_0[var_0_1.WILDCARD] = true
	end

	arg_16_0.map_[arg_16_1.name] = arg_16_0.map_[arg_16_1.name] or {}

	local var_16_1 = arg_16_0.map_[arg_16_1.name]

	for iter_16_2, iter_16_3 in pairs(var_16_0) do
		var_16_1[iter_16_2] = arg_16_1.to or iter_16_2
	end
end

local function var_0_2(arg_17_0, arg_17_1)
	if arg_17_0 then
		return arg_17_0(arg_17_1)
	end
end

function var_0_1.beforeAnyEvent_(arg_18_0, arg_18_1)
	return var_0_2(arg_18_0.callbacks_.onbeforeevent, arg_18_1)
end

function var_0_1.afterAnyEvent_(arg_19_0, arg_19_1)
	return var_0_2(arg_19_0.callbacks_.onafterevent or arg_19_0.callbacks_.onevent, arg_19_1)
end

function var_0_1.leaveAnyState_(arg_20_0, arg_20_1)
	return var_0_2(arg_20_0.callbacks_.onleavestate, arg_20_1)
end

function var_0_1.enterAnyState_(arg_21_0, arg_21_1)
	return var_0_2(arg_21_0.callbacks_.onenterstate or arg_21_0.callbacks_.onstate, arg_21_1)
end

function var_0_1.changeState_(arg_22_0, arg_22_1)
	return var_0_2(arg_22_0.callbacks_.onchangestate, arg_22_1)
end

function var_0_1.beforeThisEvent_(arg_23_0, arg_23_1)
	return var_0_2(arg_23_0.callbacks_["onbefore" .. arg_23_1.name], arg_23_1)
end

function var_0_1.afterThisEvent_(arg_24_0, arg_24_1)
	return var_0_2(arg_24_0.callbacks_["onafter" .. arg_24_1.name] or arg_24_0.callbacks_["on" .. arg_24_1.name], arg_24_1)
end

function var_0_1.leaveThisState_(arg_25_0, arg_25_1)
	return var_0_2(arg_25_0.callbacks_["onleave" .. arg_25_1.from], arg_25_1)
end

function var_0_1.enterThisState_(arg_26_0, arg_26_1)
	return var_0_2(arg_26_0.callbacks_["onenter" .. arg_26_1.to] or arg_26_0.callbacks_["on" .. arg_26_1.to], arg_26_1)
end

function var_0_1.beforeEvent_(arg_27_0, arg_27_1)
	if arg_27_0:beforeThisEvent_(arg_27_1) == false or arg_27_0:beforeAnyEvent_(arg_27_1) == false then
		return false
	end
end

function var_0_1.afterEvent_(arg_28_0, arg_28_1)
	arg_28_0:afterThisEvent_(arg_28_1)
	arg_28_0:afterAnyEvent_(arg_28_1)
end

function var_0_1.leaveState_(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_0:leaveThisState_(arg_29_1, arg_29_2)
	local var_29_1 = arg_29_0:leaveAnyState_(arg_29_1, arg_29_2)

	if var_29_0 == false or var_29_1 == false then
		return false
	elseif string.upper(tostring(var_29_0)) == var_0_1.ASYNC or string.upper(tostring(var_29_1)) == var_0_1.ASYNC then
		return var_0_1.ASYNC
	end
end

function var_0_1.enterState_(arg_30_0, arg_30_1)
	arg_30_0:enterThisState_(arg_30_1)
	arg_30_0:enterAnyState_(arg_30_1)
end

function var_0_1.onError_(arg_31_0, arg_31_1, arg_31_2, arg_31_3)
	printf("%s [StateMachine] ERROR: error %s, event %s, from %s to %s", tostring(arg_31_0.target_), tostring(arg_31_2), arg_31_1.name, arg_31_1.from, arg_31_1.to)
	printError(arg_31_3)
end

return var_0_1
