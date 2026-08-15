local var_0_0 = 0.1
local var_0_1 = 5
local var_0_2 = 3
local var_0_3 = "closed"
local var_0_4 = "Socket is not connected"
local var_0_5 = "already connected"
local var_0_6 = "Operation already in progress"
local var_0_7 = "timeout"
local var_0_8 = require("framework.scheduler")
local var_0_9 = require("socket")
local var_0_10 = class("SocketTCP")

var_0_10.EVENT_DATA = "SOCKET_TCP_DATA"
var_0_10.EVENT_CLOSE = "SOCKET_TCP_CLOSE"
var_0_10.EVENT_CLOSED = "SOCKET_TCP_CLOSED"
var_0_10.EVENT_CONNECTED = "SOCKET_TCP_CONNECTED"
var_0_10.EVENT_CONNECT_FAILURE = "SOCKET_TCP_CONNECT_FAILURE"
var_0_10._VERSION = var_0_9._VERSION
var_0_10._DEBUG = var_0_9._DEBUG

function var_0_10.getTime()
	return var_0_9.gettime()
end

function var_0_10.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	cc(arg_2_0):addComponent("components.behavior.EventProtocol"):exportMethods()

	arg_2_0.host = arg_2_1
	arg_2_0.port = arg_2_2
	arg_2_0.tickScheduler = nil
	arg_2_0.reconnectScheduler = nil
	arg_2_0.connectTimeTickScheduler = nil
	arg_2_0.name = "SocketTCP"
	arg_2_0.tcp = nil
	arg_2_0.isRetryConnect = arg_2_3
	arg_2_0.isConnected = false
end

function var_0_10.setName(arg_3_0, arg_3_1)
	arg_3_0.name = arg_3_1

	return arg_3_0
end

function var_0_10.setTickTime(arg_4_0, arg_4_1)
	var_0_0 = arg_4_1

	return arg_4_0
end

function var_0_10.setReconnTime(arg_5_0, arg_5_1)
	var_0_1 = arg_5_1

	return arg_5_0
end

function var_0_10.setConnFailTime(arg_6_0, arg_6_1)
	var_0_2 = arg_6_1

	return arg_6_0
end

function var_0_10.connect(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if arg_7_1 then
		arg_7_0.host = arg_7_1
	end

	if arg_7_2 then
		arg_7_0.port = arg_7_2
	end

	if arg_7_3 ~= nil then
		arg_7_0.isRetryConnect = arg_7_3
	end

	assert(arg_7_0.host or arg_7_0.port, "Host and port are necessary!")

	arg_7_0.tcp = var_0_9.tcp()

	arg_7_0.tcp:settimeout(0)

	local function var_7_0()
		local var_8_0 = arg_7_0:_connect()

		if var_8_0 then
			arg_7_0:_onConnected()
		end

		return var_8_0
	end

	if not var_7_0() then
		local function var_7_1()
			if arg_7_0.isConnected then
				return
			end

			arg_7_0.waitConnect = arg_7_0.waitConnect or 0
			arg_7_0.waitConnect = arg_7_0.waitConnect + var_0_0

			if arg_7_0.waitConnect >= var_0_2 then
				arg_7_0.waitConnect = nil

				arg_7_0:close()
				arg_7_0:_connectFailure()
			end

			var_7_0()
		end

		arg_7_0.connectTimeTickScheduler = var_0_8.scheduleGlobal(var_7_1, var_0_0)
	end
end

function var_0_10.send(arg_10_0, arg_10_1)
	assert(arg_10_0.isConnected, arg_10_0.name .. " is not connected.")
	arg_10_0.tcp:send(arg_10_1)
end

function var_0_10.close(arg_11_0, ...)
	arg_11_0.tcp:close()

	if arg_11_0.connectTimeTickScheduler then
		var_0_8.unscheduleGlobal(arg_11_0.connectTimeTickScheduler)
	end

	if arg_11_0.tickScheduler then
		var_0_8.unscheduleGlobal(arg_11_0.tickScheduler)
	end

	arg_11_0:dispatchEvent({
		name = var_0_10.EVENT_CLOSE
	})
end

function var_0_10.disconnect(arg_12_0)
	arg_12_0:_disconnect()

	arg_12_0.isRetryConnect = false
end

function var_0_10._connect(arg_13_0)
	local var_13_0, var_13_1 = arg_13_0.tcp:connect(arg_13_0.host, arg_13_0.port)

	return var_13_0 == 1 or var_13_1 == var_0_5
end

function var_0_10._disconnect(arg_14_0)
	arg_14_0.isConnected = false

	arg_14_0.tcp:shutdown()
	arg_14_0:dispatchEvent({
		name = var_0_10.EVENT_CLOSED
	})
end

function var_0_10._onDisconnect(arg_15_0)
	arg_15_0.isConnected = false

	arg_15_0:dispatchEvent({
		name = var_0_10.EVENT_CLOSED
	})
	arg_15_0:_reconnect()
end

function var_0_10._onConnected(arg_16_0)
	arg_16_0.isConnected = true

	arg_16_0:dispatchEvent({
		name = var_0_10.EVENT_CONNECTED
	})

	if arg_16_0.connectTimeTickScheduler then
		var_0_8.unscheduleGlobal(arg_16_0.connectTimeTickScheduler)
	end

	local function var_16_0()
		while true do
			local var_17_0, var_17_1, var_17_2 = arg_16_0.tcp:receive("*a")

			if var_17_1 == var_0_3 or var_17_1 == var_0_4 then
				arg_16_0:close()

				if arg_16_0.isConnected then
					arg_16_0:_onDisconnect()
				else
					arg_16_0:_connectFailure()
				end

				return
			end

			if var_17_0 and string.len(var_17_0) == 0 or var_17_2 and string.len(var_17_2) == 0 then
				return
			end

			if var_17_0 and var_17_2 then
				var_17_0 = var_17_0 .. var_17_2
			end

			arg_16_0:dispatchEvent({
				name = var_0_10.EVENT_DATA,
				data = var_17_2 or var_17_0,
				partial = var_17_2,
				body = var_17_0
			})
		end
	end

	arg_16_0.tickScheduler = var_0_8.scheduleGlobal(var_16_0, var_0_0)
end

function var_0_10._connectFailure(arg_18_0, arg_18_1)
	arg_18_0:dispatchEvent({
		name = var_0_10.EVENT_CONNECT_FAILURE
	})
	arg_18_0:_reconnect()
end

function var_0_10._reconnect(arg_19_0, arg_19_1)
	if not arg_19_0.isRetryConnect then
		return
	end

	printInfo("%s._reconnect", arg_19_0.name)

	if arg_19_1 then
		arg_19_0:connect()

		return
	end

	if arg_19_0.reconnectScheduler then
		var_0_8.unscheduleGlobal(arg_19_0.reconnectScheduler)
	end

	local function var_19_0()
		arg_19_0:connect()
	end

	arg_19_0.reconnectScheduler = var_0_8.performWithDelayGlobal(var_19_0, var_0_1)
end

return var_0_10
