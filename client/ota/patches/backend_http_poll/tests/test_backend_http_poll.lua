-- SIMULATED host test: loads stock Backend.lua with the HTTP polling overlay and
-- drives its room entry, login, heartbeat, messages, ack/resend and close
-- callbacks. One transport must serve every stock socket through one held poll.

local STOCK_PATH = assert(os.getenv("GXB_STOCK_BACKEND"), "GXB_STOCK_BACKEND required")
local OVERLAY_PATH = assert(os.getenv("GXB_HTTP_POLL_OVERLAY"), "GXB_HTTP_POLL_OVERLAY required")

local assertions = 0
local function ok(condition, message)
	if not condition then
		error("FAIL: " .. message, 2)
	end
	assertions = assertions + 1
	print("PASS " .. message)
end

local function readFile(path)
	local handle = assert(io.open(path, "rb"))
	local text = handle:read("*a")
	handle:close()
	if string.sub(text, 1, 3) == string.char(239, 187, 191) then
		text = string.sub(text, 4)
	end
	return text
end

local function newScheduler()
	local scheduler = { now = 0, nextId = 1, tasks = {} }
	local function add(delay, callback, repeating)
		local id = scheduler.nextId
		scheduler.nextId = id + 1
		scheduler.tasks[id] = { at = scheduler.now + delay, every = repeating and delay or nil, callback = callback, id = id }
		return id
	end
	function scheduler.performWithDelayGlobal(callback, delay)
		return add(delay, callback, false)
	end
	function scheduler.scheduleGlobal(callback, interval)
		return add(interval, callback, true)
	end
	function scheduler.unscheduleGlobal(id)
		scheduler.tasks[id] = nil
	end
	function scheduler.advance(seconds)
		local target = scheduler.now + seconds
		while true do
			local chosen = nil
			for id, task in pairs(scheduler.tasks) do
				if task.at <= target and (chosen == nil or task.at < chosen.at or (task.at == chosen.at and id < chosen.id)) then
					chosen = { id = id, at = task.at }
				end
			end
			if chosen == nil then
				break
			end
			local task = scheduler.tasks[chosen.id]
			scheduler.now = task.at
			if task.every ~= nil then
				task.at = task.at + task.every
			else
				scheduler.tasks[chosen.id] = nil
			end
			task.callback()
		end
		scheduler.now = target
	end
	function scheduler.fireRepeating(interval)
		for _, task in pairs(scheduler.tasks) do
			if task.every == interval then
				task.callback()
				return true
			end
		end
		return false
	end
	return scheduler
end

local scheduler = newScheduler()
import = function()
	return scheduler
end

class = function(name)
	local created = { __cname = name }
	created.__index = created
	function created.new(...)
		local instance = setmetatable({}, created)
		if instance.ctor then
			instance:ctor(...)
		end
		return instance
	end
	return created
end

handler = function(target, callback)
	return function(...)
		return callback(target, ...)
	end
end

local calledEvents = {}
local eventDispatcher = {
	dispatchEvent = function(_, event)
		calledEvents[#calledEvents + 1] = event
	end,
}

local midValues = { TCP_LOGIN = 32771, CHAT_ROOM_ENTERED = 32779, SOCKET_HEARTBEAT = 32797,
	CHAT_MESSAGE = 32783, SEND_CHAT_MESSAGE = 32782, CHAT_FROM_PLAYER = 514, CHAT_FROM_FRIEND = 516 }
local nextMid = 90000
xyd = {
	tables = { translation = {}, misc = { webAPIURL = "http://fallback.example:1234/engine" } },
	mid = setmetatable(midValues, { __index = function(table, key)
		nextMid = nextMid + 1
		rawset(table, key, nextMid)
		return nextMid
	end }),
	event = setmetatable({}, { __index = function(table, key)
		local value = "EVENT:" .. tostring(key)
		rawset(table, key, value)
		return value
	end }),
	error = { OK = 0 },
	EventDispatcher = { get = function() return eventDispatcher end },
	serverUrl = "https://engine.example/s/0000-000000-abcd/engine",
	getVersionName = function() return "1.631.0" end,
	version = function() return "1.631.0" end,
	isChatRoomMessage = function() return true end,
}
json = { encode = cjson.encode, decode = cjson.decode }
device = { platform = "android" }
string.urlencode = function(value)
	return value
end

local httpRequests = {}
local tcpCreated = {}
local function newRequest(callback, url, method)
	local request = { callback = callback, url = url, method = method, postValues = {}, retainCalls = 0, releaseCalls = 0, done = false }
	function request:retain()
		self.retainCalls = self.retainCalls + 1
	end
	function request:release()
		self.releaseCalls = self.releaseCalls + 1
	end
	function request:addPOSTValue(name, value)
		self.postValues[name] = value
	end
	function request:setTimeout(seconds)
		self.timeout = seconds
	end
	function request:start()
		self.started = true
	end
	function request:cancel()
		self.cancelled = true
	end
	function request:getResponseStatusCode()
		return self.status
	end
	function request:getResponseString()
		return self.response
	end
	function request:complete(response, status)
		self.response = response
		self.status = status or 200
		self.done = true
		self.callback({ name = "completed", request = self })
	end
	function request:fail()
		self.done = true
		self.callback({ name = "failed", request = self })
	end
	httpRequests[#httpRequests + 1] = request
	return request
end
network = {
	createHTTPRequest = function(callback, url, method)
		return newRequest(callback, url, method)
	end,
}
cc = {
	Application = { getInstance = function() return { getTargetPlatform = function() return 0 end } end },
}
xyd.TCPSocket = { create = function(_, ...)
	local socket = { args = { ... } }
	tcpCreated[#tcpCreated + 1] = socket
	return socket
end }

local stock = readFile(STOCK_PATH)
local overlay = readFile(OVERLAY_PATH)

local function buildChunk(httpPollMode)
	local mode = httpPollMode and "true" or "false"
	local injected = string.gsub(overlay, "__GXB_HTTP_POLL__", mode)
	local prefix, suffix = string.match(stock, "^(.*)\nreturn var_0_1(.-)$")
	assert(prefix, "stock Backend.lua final return anchor missing")
	local source = prefix .. "\n" .. injected .. "\n\nreturn var_0_1" .. suffix
	local chunk, loadError = loadstring(source, "@patched-Backend.lua")
	assert(chunk, tostring(loadError))
	local result, module = pcall(chunk)
	assert(result, tostring(module))
	assert(type(module) == "table", "Backend module did not return its class")
	return module
end

local function findEvent(name)
	for _, event in ipairs(calledEvents) do
		if event.name == name then
			return event
		end
	end
	return nil
end

local function requestPayload(request)
	return cjson.decode(request.postValues.payload)
end

local function reply(sessionID, frames)
	return cjson.encode({ session_id = sessionID or "opaque-session", frames = frames or {} })
end

local function complete(request, frames)
	request:complete(reply("opaque-session", frames))
end

local function createdSessionCount()
	local count = 0
	for _, request in ipairs(httpRequests) do
		local payload = requestPayload(request)
		if payload.session_id == nil and payload.frames == nil and payload.hold ~= true then
			count = count + 1
		end
	end
	return count
end

local function outstandingPolls()
	local count = 0
	for _, request in ipairs(httpRequests) do
		local payload = requestPayload(request)
		if payload.hold == true and not request.done then
			count = count + 1
		end
	end
	return count
end

local function lastRequest()
	return httpRequests[#httpRequests]
end

local function pendingPoll()
	for index = #httpRequests, 1, -1 do
		local request = httpRequests[index]
		if requestPayload(request).hold == true and not request.done then
			return request
		end
	end
	return nil
end

local Backend = buildChunk(true)
local backend = Backend.get()
backend.token_ = "session-token"
backend.region_ = 1
local roomRequests = 0
function backend:request(mid, parameters, callback)
	roomRequests = roomRequests + 1
	callback(xyd.error.OK, { host = "10.0.0.1", port = 18954, room_id = 7 })
end
local enterCalls = 0
local stockEnterRoom = Backend.enterChatRoom
Backend.enterChatRoom = function(self, ...)
	enterCalls = enterCalls + 1
	return stockEnterRoom(self, ...)
end

backend:enterChatRoom(7)
ok(roomRequests == 1, "stock enterChatRoom requested room info")
ok(#httpRequests == 1, "connect created one session request for the client")
local createRequest = httpRequests[1]
local createPayload = requestPayload(createRequest)
ok(createRequest.url == "https://engine.example/realtime/poll", "poll URL derived from stock server origin")
ok(createRequest.method == "POST" and createRequest.started, "session request used a started POST")
ok(createRequest.timeout == 30, "session request uses the long-poll timeout")
ok(createPayload.hold == false and createPayload.session_id == nil and createPayload.frames == nil, "session request holds no poll and carries no frames")

complete(createRequest)
ok(#httpRequests == 3, "session creation sent the stock login and opened the held poll")
local loginRequest = httpRequests[2]
local loginPayload = requestPayload(loginRequest)
ok(loginPayload.session_id == "opaque-session" and loginPayload.client_sequence == 1, "login send reuses the session and starts the client sequence")
ok(loginPayload.frames[1].socket == "socket1", "login frame is tagged with its socket")
ok(loginPayload.frames[1].frame.mid == 32771, "TCP_LOGIN mid")
ok(loginPayload.frames[1].frame.data.token == "session-token" and loginPayload.frames[1].frame.data.region == 1 and loginPayload.frames[1].frame.data.room_id == 7,
	"TCP_LOGIN token/region/room_id")
ok(loginRequest.timeout == 10, "send request keeps the short request timeout")
local pollRequest = httpRequests[3]
local pollPayload = requestPayload(pollRequest)
ok(pollPayload.session_id == "opaque-session" and pollPayload.hold == true and pollPayload.ack == 0, "held poll carries the session and ack")
ok(pollRequest.timeout == 30, "held poll uses a timeout above the hold")
ok(outstandingPolls() == 1, "exactly one held poll is open")

complete(loginRequest)
complete(pollRequest, { { socket = "socket1", sequence = 1, frame = { mid = 32779, data = { room_id = 7 } } } })
ok(findEvent("EVENT:CHAT_SESSION_OPENED") ~= nil, "CHAT_ROOM_ENTERED dispatched CHAT_SESSION_OPENED")
local nextPoll = lastRequest()
ok(requestPayload(nextPoll).hold == true and requestPayload(nextPoll).ack == 1, "next poll acknowledges the delivered sequence")
ok(outstandingPolls() == 1, "the next held poll replaced the completed one")

backend:sendChatMessage("hello")
local chatRequest = lastRequest()
local chatPayload = requestPayload(chatRequest)
ok(chatPayload.hold == false and chatPayload.frames[1].frame.mid == 32782 and chatPayload.frames[1].frame.data.message == "hello",
	"stock chat message starts a short tagged send")
ok(chatPayload.client_sequence == 2, "chat send advanced the client sequence")
complete(chatRequest)

complete(nextPoll, {
	{ socket = "socket1", sequence = 2, frame = { mid = 32783, data = { message = "hello", gone = cjson.null } } },
	{ socket = "socket1", sequence = 3, frame = { mid = 514, data = { friend_id = 7 } } },
})
local chatEvent = findEvent("EVENT:CHAT_ROOM_MESSAGE")
ok(chatEvent ~= nil and chatEvent.params.message == "hello", "CHAT_MESSAGE reached the stock callback")
ok(chatEvent.params.gone == nil, "JSON null reached Lua as nil")
ok(findEvent("EVENT:PERSONAL_CHAT_MESSAGE") ~= nil, "push frame reached the stock callback in order")
ok(requestPayload(lastRequest()).ack == 3, "ack advanced across all delivered sequences")

ok(scheduler.fireRepeating(600), "stock heartbeat timer installed after room entry")
local heartbeatRequest = lastRequest()
ok(requestPayload(heartbeatRequest).frames[1].frame.mid == 32797 and next(requestPayload(heartbeatRequest).frames[1].frame.data) == nil,
	"SOCKET_HEARTBEAT payload preserved")
complete(heartbeatRequest)

backend:sendChatMessage("retry")
local retrySend = lastRequest()
local retryPayload = requestPayload(retrySend)
local retrySequence = retryPayload.client_sequence
ok(type(retrySequence) == "number" and retrySequence > 2, "retry candidate carries an advanced client sequence")
local requestsBeforeRetry = #httpRequests
retrySend:fail()
ok(#httpRequests == requestsBeforeRetry, "failed send did not issue a request immediately")
scheduler.advance(0.5)
local retriedSend = lastRequest()
ok(retriedSend ~= retrySend and requestPayload(retriedSend).client_sequence == retrySequence
	and requestPayload(retriedSend).frames[1].frame.data.message == "retry", "failed send retried with the same client sequence")
complete(retriedSend)

local function countClosed()
	local count = 0
	for _, event in ipairs(calledEvents) do
		if event.name == "EVENT:CHAT_SESSION_CLOSED" then
			count = count + 1
		end
	end
	return count
end
local reconnectBefore = enterCalls
for _ = 1, 10 do
	if countClosed() > 0 then
		break
	end
	local failedPoll = pendingPoll()
	assert(failedPoll ~= nil, "expected an outstanding held poll")
	failedPoll:fail()
	scheduler.advance(8)
end
ok(countClosed() > 0, "repeated poll failures ran the stock disconnect path")
ok(enterCalls > reconnectBefore, "stock reconnect re-entered the chat room after disconnect")

local reconnectCreate = lastRequest()
ok(requestPayload(reconnectCreate).session_id == nil and requestPayload(reconnectCreate).frames == nil, "reconnect created a fresh session")
complete(reconnectCreate)
local reconnectLogin = httpRequests[#httpRequests - 1]
local reconnectPoll = lastRequest()
ok(requestPayload(reconnectLogin).frames ~= nil and requestPayload(reconnectPoll).hold == true, "reconnect logged in through a fresh held poll")
complete(reconnectLogin)
complete(reconnectPoll)

local sessionsBeforeSockets = createdSessionCount()
backend:enterLeagueRoom(7)
ok(createdSessionCount() == sessionsBeforeSockets, "the league socket reused the existing client session")
local leagueLogin = lastRequest()
local leaguePayload = requestPayload(leagueLogin)
ok(leaguePayload.frames ~= nil and leaguePayload.frames[1].socket ~= "socket1", "league login is tagged with its own socket")
complete(leagueLogin)
local leaguePoll = pendingPoll()
ok(leaguePoll ~= nil and requestPayload(leaguePoll).hold == true, "league socket shares the one held poll")
local leagueSequence = 1
complete(leaguePoll, { { socket = leaguePayload.frames[1].socket, sequence = leagueSequence, frame = { mid = 32779, data = { room_id = 7 } } } })
ok(findEvent("EVENT:LEAGUE_CHAT_SESSION_OPENED") ~= nil, "league frame reached the league stock callback")
ok(createdSessionCount() == sessionsBeforeSockets, "league socket logged in without another session")

backend:enterServiceChatRoom(99999)
ok(createdSessionCount() == sessionsBeforeSockets, "the service socket reused the existing client session")
local serviceLogin = lastRequest()
local servicePayload = requestPayload(serviceLogin)
ok(servicePayload.frames ~= nil and servicePayload.frames[1].socket ~= "socket1" and servicePayload.frames[1].socket ~= leaguePayload.frames[1].socket,
	"service login is tagged with its own socket")
complete(serviceLogin)
local servicePoll = pendingPoll()
ok(servicePoll ~= nil and requestPayload(servicePoll).hold == true, "service socket shares the one held poll")
complete(servicePoll, { { socket = servicePayload.frames[1].socket, sequence = leagueSequence + 1, frame = { mid = 32779, data = { room_id = 7 } } } })
ok(findEvent("EVENT:SERVICE_CHAT_SESSION_OPENED") ~= nil, "service frame reached the service stock callback")
ok(createdSessionCount() == sessionsBeforeSockets, "service socket logged in without another session")
ok(outstandingPolls() <= 1, "never more than one held poll is open")

local beforeClose = enterCalls
local closedBeforeClose = countClosed()
local adapter = backend.socket_
backend:closeChatRoom()
ok(adapter.state == "closed" and backend.socket_ == nil, "stock explicit close closed and cleared the adapter")
scheduler.advance(0)
ok(enterCalls == beforeClose and countClosed() == closedBeforeClose, "explicit close did not invoke the stock disconnect callback")

xyd.serverUrl = "http://10.0.2.2:18853/engine"
local plain = backend:createTCPSocket("10.0.0.1", 18954)
ok(plain.transport.url == "http://10.0.2.2:18853/realtime/poll", "http origin derives the polling URL")
xyd.serverUrl = "https://engine.example/engine"

local originalNetwork = network
local originalTCPCount = #tcpCreated
network = nil
xyd.serverUrl = nil
xyd.tables.misc.webAPIURL = nil
local missingHTTPDisconnect = false
local missingHTTPAdapter = buildChunk(true).get():createTCPSocket("10.0.0.1", 18954)
missingHTTPAdapter:setDisconnectHandler(function()
	missingHTTPDisconnect = true
end)
missingHTTPAdapter:retain()
missingHTTPAdapter:connect()
scheduler.advance(0)
ok(missingHTTPDisconnect and missingHTTPAdapter.state == "closed" and #tcpCreated == originalTCPCount,
	"HTTP mode disconnects rather than falling back to TCP when its origin is unavailable")
network = originalNetwork
xyd.serverUrl = "https://engine.example/engine"
xyd.tables.misc.webAPIURL = "http://fallback.example:1234/engine"

local TcpBackend = buildChunk(false)
local tcpBackend = TcpBackend.get()
local stockTcp = tcpBackend:createTCPSocket("10.0.0.1", 18954)
ok(stockTcp ~= nil and stockTcp.url == nil, "TCP mode returns the stock socket")
ok(#tcpCreated >= 1, "stock TCP socket creator was used in TCP mode")

print(string.format("SIMULATED HTTP_POLL_BACKEND PASS: %d assertions", assertions))
