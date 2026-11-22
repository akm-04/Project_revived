-- HTTP polling overlay inserted before the final `return var_0_1` of Backend.lua.
-- It changes only the stock socket factory: every stock socket shares one HTTP
-- transport that keeps one held poll open and acknowledges delivered frames.

local GXB_HTTP_POLL = __GXB_HTTP_POLL__
local GXB_HTTP_POLL_PATH = "/realtime/poll"
local GXB_HTTP_REQUEST_TIMEOUT_SECONDS = 10
local GXB_HTTP_POLL_TIMEOUT_SECONDS = 30
local GXB_HTTP_POLL_BACKOFF_MS = 500
local GXB_HTTP_POLL_BACKOFF_MAX_MS = 8000
local GXB_HTTP_POLL_MAX_FAILURES = 6
local GXB_HTTP_SEND_MAX_RETRIES = 4
local GXB_HTTP_MAX_PENDING = 64

local GXB_SOCKET_IDLE = "idle"
local GXB_SOCKET_CONNECTING = "connecting"
local GXB_SOCKET_OPEN = "open"
local GXB_SOCKET_CLOSED = "closed"
local GXB_SOCKET_RELEASED = "released"

local gxbCjson = require("cjson")

local function gxbNormalizeIncomingJSON(value)
	local nullSentinel = gxbCjson.null
	if nullSentinel ~= nil and value == nullSentinel then
		return nil
	end
	if type(value) ~= "table" then
		return value
	end
	local normalized = {}
	for key, item in pairs(value) do
		local converted = gxbNormalizeIncomingJSON(item)
		if converted ~= nil then
			normalized[key] = converted
		end
	end
	return normalized
end

local function gxbRealtimeURL()
	local origin = xyd.serverUrl
	if origin == nil and xyd.tables ~= nil and xyd.tables.misc ~= nil then
		origin = xyd.tables.misc.webAPIURL
	end
	if type(origin) ~= "string" then
		return nil
	end
	local scheme, authority = string.match(origin, "^(https?)://([^/]+)")
	if scheme == nil then
		return nil
	end
	return scheme .. "://" .. authority .. GXB_HTTP_POLL_PATH
end

local GXBHTTPPollAdapter = {}
GXBHTTPPollAdapter.__index = GXBHTTPPollAdapter

function GXBHTTPPollAdapter.new(transport)
	local adapter = setmetatable({}, GXBHTTPPollAdapter)
	adapter.transport = transport
	adapter.tag = transport:newSocketTag()
	adapter.state = GXB_SOCKET_IDLE
	adapter.pending = {}
	adapter.refCount = 0
	adapter.released = false
	adapter.disconnectNotified = false
	adapter.connectHandler = nil
	adapter.disconnectHandler = nil
	adapter.messageHandler = nil
	return adapter
end

function GXBHTTPPollAdapter:setConnectHandler(callback)
	self.connectHandler = callback
	return self
end

function GXBHTTPPollAdapter:setDisconnectHandler(callback)
	self.disconnectHandler = callback
	return self
end

function GXBHTTPPollAdapter:setMessageHandler(callback)
	self.messageHandler = callback
	return self
end

function GXBHTTPPollAdapter:retain()
	if not self.released then
		self.refCount = self.refCount + 1
	end
	return self
end

function GXBHTTPPollAdapter:release()
	if self.released then
		return
	end
	self.refCount = self.refCount - 1
	if self.refCount > 0 then
		return
	end
	self.released = true
	self.state = GXB_SOCKET_RELEASED
	self.transport:detach(self)
	self.pending = {}
	self.connectHandler = nil
	self.disconnectHandler = nil
	self.messageHandler = nil
end

function GXBHTTPPollAdapter:close()
	if self.released or self.state == GXB_SOCKET_CLOSED or self.state == GXB_SOCKET_RELEASED then
		return
	end
	self.state = GXB_SOCKET_CLOSED
	self.transport:detach(self)
	self.pending = {}
end

function GXBHTTPPollAdapter:connect()
	if self.released or self.state == GXB_SOCKET_CONNECTING or self.state == GXB_SOCKET_OPEN then
		return self.state ~= GXB_SOCKET_CLOSED and self.state ~= GXB_SOCKET_RELEASED
	end
	self.state = GXB_SOCKET_CONNECTING
	self.disconnectNotified = false
	self.transport:attach(self)
	return true
end

function GXBHTTPPollAdapter:sendMessage(mid, body)
	if self.released or self.state == GXB_SOCKET_CLOSED or self.state == GXB_SOCKET_RELEASED then
		return false, "closed"
	end
	if #self.pending >= GXB_HTTP_MAX_PENDING then
		self:fail()
		return false, "pending queue full"
	end
	self.pending[#self.pending + 1] = { mid = mid, data = body or {} }
	self.transport:send(self, mid, body)
	return true
end

function GXBHTTPPollAdapter:notifyOpen()
	if self.state ~= GXB_SOCKET_CONNECTING then
		return
	end
	self.state = GXB_SOCKET_OPEN
	if self.connectHandler ~= nil then
		self.connectHandler(self)
	end
end

function GXBHTTPPollAdapter:handleFrame(mid, data)
	if self.state ~= GXB_SOCKET_OPEN or self.released then
		return
	end
	if self.messageHandler == nil then
		return
	end
	local ok = pcall(self.messageHandler, self, mid, gxbNormalizeIncomingJSON(data))
	if not ok then
		self:fail()
	end
end

function GXBHTTPPollAdapter:fail()
	if self.released or self.state == GXB_SOCKET_CLOSED or self.state == GXB_SOCKET_RELEASED then
		return
	end
	self.state = GXB_SOCKET_CLOSED
	self.transport:detach(self)
	self.pending = {}
	self.transport.scheduler:after(0, function()
		if self.disconnectNotified then
			return
		end
		self.disconnectNotified = true
		if self.disconnectHandler ~= nil then
			self.disconnectHandler(self)
		end
	end)
end

local GXBHTTPPollTransport = {}
GXBHTTPPollTransport.__index = GXBHTTPPollTransport

function GXBHTTPPollTransport.new(url, scheduler)
	return setmetatable({
		url = url,
		scheduler = scheduler,
		state = "idle",
		sessionID = nil,
		ack = 0,
		receiveSequence = 0,
		adapters = {},
		nextTag = 0,
		clientSequence = 0,
		outgoing = {},
		pollRequest = nil,
		pollInFlight = false,
		pollFailures = 0,
		sendRequest = nil,
		sendInFlight = false,
		sendRetries = 0,
		sendSequence = nil,
		retryHandle = nil,
		generation = 0,
	}, GXBHTTPPollTransport)
end

function GXBHTTPPollTransport:newSocketTag()
	self.nextTag = self.nextTag + 1
	return "socket" .. self.nextTag
end

function GXBHTTPPollTransport:hasAdapters()
	for _, adapter in pairs(self.adapters) do
		if adapter.state == GXB_SOCKET_CONNECTING or adapter.state == GXB_SOCKET_OPEN then
			return true
		end
	end
	return false
end

function GXBHTTPPollTransport:attach(adapter)
	self.adapters[adapter.tag] = adapter
	if self.state == "open" then
		adapter:notifyOpen()
		self:pump()
		return
	end
	if self.state == "idle" then
		self:startCreate()
	end
end

function GXBHTTPPollTransport:detach(adapter)
	if self.adapters[adapter.tag] == adapter then
		self.adapters[adapter.tag] = nil
	end
end

function GXBHTTPPollTransport:cancelRetry()
	if self.retryHandle == nil then
		return
	end
	self.scheduler:cancel(self.retryHandle)
	self.retryHandle = nil
end

function GXBHTTPPollTransport:scheduleRetry(callback, milliseconds)
	self:cancelRetry()
	self.retryHandle = self.scheduler:after(milliseconds, function()
		self.retryHandle = nil
		callback()
	end)
end

function GXBHTTPPollTransport:request(payload, timeout, callback)
	if network == nil or type(network.createHTTPRequest) ~= "function" then
		callback(nil, "unavailable")
		return nil
	end
	local encodedOK, encoded = pcall(gxbCjson.encode, payload)
	if not encodedOK or type(encoded) ~= "string" then
		callback(nil, "encode")
		return nil
	end
	local request
	local created
	created, request = pcall(network.createHTTPRequest, function(event)
		if type(event) ~= "table" or (event.name ~= "completed" and event.name ~= "failed") then
			return
		end
		pcall(function()
			request:release()
		end)
		if event.name ~= "completed" or request:getResponseStatusCode() ~= 200 then
			callback(nil, "failed")
			return
		end
		callback(request:getResponseString(), nil)
	end, self.url, "POST")
	if not created or request == nil then
		callback(nil, "create")
		return nil
	end
	local prepared = pcall(function()
		request:retain()
		request:addPOSTValue("payload", string.urlencode(encoded))
		request:setTimeout(timeout)
		request:start()
	end)
	if not prepared then
		pcall(function()
			request:release()
		end)
		callback(nil, "prepare")
		return nil
	end
	return request
end

function GXBHTTPPollTransport:decodeReply(encoded)
	if type(encoded) ~= "string" then
		return nil
	end
	local decoded, reply = pcall(gxbCjson.decode, encoded)
	if not decoded or type(reply) ~= "table" or type(reply.session_id) ~= "string" or type(reply.frames) ~= "table" then
		return nil
	end
	if reply.session_id == "" then
		return nil
	end
	for _, frame in ipairs(reply.frames) do
		if type(frame) ~= "table" or type(frame.socket) ~= "string" or type(frame.sequence) ~= "number" then
			return nil
		end
		if frame.closed ~= true then
			if type(frame.frame) ~= "table" or type(frame.frame.mid) ~= "number" or frame.frame.mid < 0 or frame.frame.mid > 65535 or frame.frame.mid % 1 ~= 0 then
				return nil
			end
		end
	end
	return reply
end

function GXBHTTPPollTransport:applyReply(reply)
	if self.sessionID ~= nil and self.sessionID ~= reply.session_id then
		return false
	end
	self.sessionID = reply.session_id
	for _, frame in ipairs(reply.frames) do
		if frame.sequence > self.receiveSequence then
			self.receiveSequence = frame.sequence
			local adapter = self.adapters[frame.socket]
			if adapter ~= nil then
				if frame.closed == true then
					adapter:fail()
				else
					adapter:handleFrame(frame.frame.mid, frame.frame.data)
				end
			end
		end
	end
	self.ack = self.receiveSequence
	return true
end

function GXBHTTPPollTransport:startCreate()
	if self.state ~= "idle" then
		return
	end
	self.state = "creating"
	local generation = self.generation
	self:request({ hold = false }, GXB_HTTP_POLL_TIMEOUT_SECONDS, function(encoded, failure)
		if self.state ~= "creating" or self.generation ~= generation then
			return
		end
		if failure ~= nil then
			self.state = "idle"
			self:retryOrFail("create")
			return
		end
		local reply = self:decodeReply(encoded)
		if reply == nil then
			self.state = "idle"
			self:retryOrFail("create")
			return
		end
		self.state = "open"
		self.sessionID = reply.session_id
		self.pollFailures = 0
		self:notifyAdapters()
		self:startPoll()
	end)
end

function GXBHTTPPollTransport:notifyAdapters()
	local adapters = {}
	for _, adapter in pairs(self.adapters) do
		adapters[#adapters + 1] = adapter
	end
	for _, adapter in ipairs(adapters) do
		adapter:notifyOpen()
	end
end

function GXBHTTPPollTransport:backoffMilliseconds(failures)
	local delay = GXB_HTTP_POLL_BACKOFF_MS
	for _ = 2, failures do
		delay = delay * 2
		if delay >= GXB_HTTP_POLL_BACKOFF_MAX_MS then
			return GXB_HTTP_POLL_BACKOFF_MAX_MS
		end
	end
	return delay
end

function GXBHTTPPollTransport:retryOrFail(stage)
	self.pollFailures = self.pollFailures + 1
	if self.pollFailures > GXB_HTTP_POLL_MAX_FAILURES then
		self:fail()
		return
	end
	local delay = self:backoffMilliseconds(self.pollFailures)
	self:scheduleRetry(function()
		if stage == "poll" then
			self:startPoll()
		else
			self:startCreate()
		end
	end, delay)
end

function GXBHTTPPollTransport:startPoll()
	if self.state ~= "open" or self.pollInFlight or not self:hasAdapters() then
		return
	end
	self.pollInFlight = true
	local generation = self.generation
	local payload = { session_id = self.sessionID, ack = self.ack, hold = true }
	local request
	request = self:request(payload, GXB_HTTP_POLL_TIMEOUT_SECONDS, function(encoded, failure)
		if self.pollRequest ~= request or self.generation ~= generation then
			return
		end
		self.pollRequest = nil
		self.pollInFlight = false
		if failure ~= nil then
			self:retryOrFail("poll")
			return
		end
		local reply = self:decodeReply(encoded)
		if reply == nil or not self:applyReply(reply) then
			self:retryOrFail("poll")
			return
		end
		self.pollFailures = 0
		self:startPoll()
	end)
	if request == nil then
		self.pollRequest = nil
		self.pollInFlight = false
		return
	end
	self.pollRequest = request
end

function GXBHTTPPollTransport:beginSend(frames)
	self.clientSequence = self.clientSequence + 1
	self.sendSequence = self.clientSequence
	local encodedFrames = {}
	for _, frame in ipairs(frames) do
		encodedFrames[#encodedFrames + 1] = { socket = frame.adapter.tag, frame = { mid = frame.mid, data = frame.data } }
	end
	return {
		session_id = self.sessionID,
		client_sequence = self.sendSequence,
		ack = self.ack,
		hold = false,
		frames = encodedFrames,
	}
end

function GXBHTTPPollTransport:finishSend(frames)
	for _, frame in ipairs(frames) do
		if #frame.adapter.pending > 0 then
			table.remove(frame.adapter.pending, 1)
		end
	end
end

function GXBHTTPPollTransport:completeSend(frames)
	for _ = 1, #frames do
		table.remove(self.outgoing, 1)
	end
	self:finishSend(frames)
	self:pump()
end

function GXBHTTPPollTransport:pump()
	if self.state ~= "open" or self.sendInFlight or #self.outgoing == 0 then
		return
	end
	local frames = {}
	for index, frame in ipairs(self.outgoing) do
		frames[index] = frame
	end
	local payload = self:beginSend(frames)
	self.sendInFlight = true
	self.sendRetries = 0
	self:issueSend(payload, frames, self.generation)
end

function GXBHTTPPollTransport:issueSend(payload, frames, generation)
	local request
	request = self:request(payload, GXB_HTTP_REQUEST_TIMEOUT_SECONDS, function(encoded, failure)
		if self.sendRequest ~= request or self.generation ~= generation then
			return
		end
		self.sendRequest = nil
		self.sendInFlight = false
		if failure ~= nil then
			self:retrySend(payload, frames, generation)
			return
		end
		local reply = self:decodeReply(encoded)
		if reply ~= nil then
			self:applyReply(reply)
		end
		self:completeSend(frames)
	end)
	if request == nil then
		self.sendRequest = nil
		self.sendInFlight = false
		return
	end
	self.sendRequest = request
end

function GXBHTTPPollTransport:retrySend(payload, frames, generation)
	self.sendRetries = self.sendRetries + 1
	if self.sendRetries > GXB_HTTP_SEND_MAX_RETRIES then
		self:fail()
		return
	end
	local delay = self:backoffMilliseconds(self.sendRetries)
	self:scheduleRetry(function()
		if self.state ~= "open" or self.generation ~= generation then
			return
		end
		self.sendInFlight = true
		self:issueSend(payload, frames, generation)
	end, delay)
end

function GXBHTTPPollTransport:send(adapter, mid, data)
	self.outgoing[#self.outgoing + 1] = { adapter = adapter, mid = mid, data = data or {} }
	self:pump()
end

function GXBHTTPPollTransport:fail()
	self.generation = self.generation + 1
	self.state = "idle"
	self.sessionID = nil
	self.ack = 0
	self.receiveSequence = 0
	self.pollFailures = 0
	self.sendRetries = 0
	self.pollInFlight = false
	self.sendInFlight = false
	self.pollRequest = nil
	self.sendRequest = nil
	self.outgoing = {}
	self:cancelRetry()
	local adapters = {}
	for _, adapter in pairs(self.adapters) do
		adapters[#adapters + 1] = adapter
	end
	for _, adapter in ipairs(adapters) do
		adapter:fail()
	end
end

local gxbHTTPPollScheduler = {
	after = function(_, milliseconds, callback)
		return var_0_0.performWithDelayGlobal(callback, milliseconds / 1000)
	end,
	cancel = function(_, handle)
		var_0_0.unscheduleGlobal(handle)
	end,
}

local gxbHTTPPollTransports = {}

local function gxbHTTPPollTransportFor(url)
	local existing = gxbHTTPPollTransports[url]
	if existing ~= nil then
		return existing
	end
	local created = GXBHTTPPollTransport.new(url, gxbHTTPPollScheduler)
	gxbHTTPPollTransports[url] = created
	return created
end

local gxbStockCreateTCPSocket = var_0_1.createTCPSocket

function var_0_1.createTCPSocket(self, host, port)
	if not GXB_HTTP_POLL then
		return gxbStockCreateTCPSocket(self, host, port)
	end
	local url = gxbRealtimeURL()
	if type(url) ~= "string" then
		return GXBHTTPPollAdapter.new({
			newSocketTag = function()
				return "unavailable"
			end,
			attach = function(_, adapter)
				gxbHTTPPollScheduler:after(0, function()
					adapter:fail()
				end)
			end,
			detach = function() end,
			pump = function() end,
			scheduler = gxbHTTPPollScheduler,
		})
	end
	return GXBHTTPPollAdapter.new(gxbHTTPPollTransportFor(url))
end
