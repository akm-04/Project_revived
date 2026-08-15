local var_0_0 = require("socket")

if not var_0_0 then
	return
end

local var_0_1 = require("framework.scheduler")
local var_0_2 = class("SimpleTCP")
local var_0_3 = string
local var_0_4 = pairs
local var_0_5 = print
local var_0_6 = assert

var_0_2._VERSION = var_0_0._VERSION
var_0_2._DEBUG = var_0_0._DEBUG
var_0_2.CONNECT_TIMEOUT = 15
var_0_2.STAT_CONNECTING = 1
var_0_2.STAT_FAILED = 2
var_0_2.STAT_CONNECTED = 3
var_0_2.STAT_CLOSED = 4
var_0_2.EVENT_CONNECTING = "Connecting"
var_0_2.EVENT_FAILED = "Failed"
var_0_2.EVENT_CONNECTED = "Connected"
var_0_2.EVENT_CLOSED = "Closed"
var_0_2.EVENT_DATA = "Data"

function var_0_2.getTime()
	return var_0_0.gettime()
end

function var_0_2.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	if not arg_2_1 then
		var_0_5("Worning SimpleTCP:ctor() host is nil")
	end

	if not arg_2_2 then
		var_0_5("Worning SimpleTCP:ctor() port is nil")
	end

	arg_2_0.host = arg_2_1
	arg_2_0.port = arg_2_2
	arg_2_0.tcp = nil
	arg_2_0.callback = arg_2_3
end

function var_0_2.connect(arg_3_0)
	if arg_3_0.stat == var_0_2.STAT_CONNECTING or arg_3_0.stat == var_0_2.STAT_CONNECTED then
		var_0_5("Error: SimpleTCP:connect() call at wrong stat:", arg_3_0.stat)

		return
	end

	arg_3_0.stat = var_0_2.STAT_CONNECTING

	arg_3_0.callback(var_0_2.EVENT_CONNECTING)

	arg_3_0.connectingTime = 0

	if arg_3_0.tcp then
		arg_3_0:_connectAndCheck()
		var_0_6(not arg_3_0.globalUpdateHandler, "SimpleTCP:connect status wrong, need reviewing!")

		arg_3_0.globalUpdateHandler = var_0_1.scheduleUpdateGlobal(handler(arg_3_0, arg_3_0._update))
	else
		var_0_0.dns.isIpv6(arg_3_0.host, function(arg_4_0, arg_4_1)
			var_0_6(arg_4_0 == nil, "Error in socket.dns.isIpv6")

			if arg_4_1 then
				arg_3_0.tcp = var_0_0.tcp6()
			else
				arg_3_0.tcp = var_0_0.tcp()
			end

			arg_3_0.tcp:settimeout(0)
			arg_3_0:_connectAndCheck()
			var_0_6(not arg_3_0.globalUpdateHandler, "SimpleTCP:connect status wrong, need reviewing!")

			arg_3_0.globalUpdateHandler = var_0_1.scheduleUpdateGlobal(handler(arg_3_0, arg_3_0._update))
		end)
	end
end

function var_0_2.send(arg_5_0, arg_5_1)
	if arg_5_0.stat ~= var_0_2.STAT_CONNECTED then
		var_0_5("Error: SimpleTCP is not connected.")

		return
	end

	arg_5_0.tcp:send(arg_5_1)
end

function var_0_2.close(arg_6_0)
	if arg_6_0.stat == var_0_2.STAT_CONNECTING then
		var_0_5("Error: SimpleTCP is connecting, wait it end then you can call close()")

		return
	end

	arg_6_0.tcp:close()
end

function var_0_2._connectAndCheck(arg_7_0)
	local var_7_0, var_7_1 = arg_7_0.tcp:connectAsyn(arg_7_0.host, arg_7_0.port)

	return var_7_0 == 1 or var_7_1 == "already connected"
end

function var_0_2._update(arg_8_0, arg_8_1)
	if arg_8_0.stat == var_0_2.STAT_CONNECTED then
		local var_8_0, var_8_1, var_8_2 = arg_8_0.tcp:receive("*a")

		if var_8_0 and var_0_3.len(var_8_0) > 0 then
			arg_8_0.callback(var_0_2.EVENT_DATA, var_8_0)

			return
		end

		if var_8_2 and var_0_3.len(var_8_2) > 0 then
			arg_8_0.callback(var_0_2.EVENT_DATA, var_8_2)
		end

		if var_8_1 == "closed" or var_8_1 == "Socket is not connected" then
			arg_8_0.tcp:close()

			arg_8_0.tcp = nil

			var_0_1.unscheduleGlobal(arg_8_0.globalUpdateHandler)

			arg_8_0.globalUpdateHandler = nil
			arg_8_0.stat = var_0_2.STAT_CLOSED

			arg_8_0.callback(var_0_2.EVENT_CLOSED)
		end

		return
	end

	if arg_8_0.stat == var_0_2.STAT_CONNECTING then
		if arg_8_0:_connectAndCheck() then
			arg_8_0.stat = var_0_2.STAT_CONNECTED

			arg_8_0.callback(var_0_2.EVENT_CONNECTED)

			return
		else
			arg_8_0.connectingTime = arg_8_0.connectingTime + arg_8_1

			if arg_8_0.connectingTime >= var_0_2.CONNECT_TIMEOUT then
				var_0_1.unscheduleGlobal(arg_8_0.globalUpdateHandler)

				arg_8_0.globalUpdateHandler = nil
				arg_8_0.stat = var_0_2.STAT_FAILED

				arg_8_0.callback(var_0_2.EVENT_FAILED)
			end

			return
		end
	end
end

return var_0_2
