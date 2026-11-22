-- SIMULATED host test: applies the league_room_stop patches to stock Backend.lua
-- and drives the MID 192 failure branch. A permanent refusal stops the loop and
-- clears the room id; 35033 or no reply keeps the 5 s retry; success is unchanged.

local STOCK_PATH = assert(os.getenv("GXB_STOCK_BACKEND"), "GXB_STOCK_BACKEND required")
local CLOSE_PATCH = assert(os.getenv("GXB_LEAGUE_CLOSE_PATCH"), "GXB_LEAGUE_CLOSE_PATCH required")
local RETRY_PATCH = assert(os.getenv("GXB_LEAGUE_RETRY_PATCH"), "GXB_LEAGUE_RETRY_PATCH required")

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

local function normalize(text)
	return (string.gsub(string.gsub(text, "\r\n", "\n"), "\r", "\n"))
end

local function applyExact(source, directory)
	local definition = cjson.decode(readFile(directory .. "/patch.json"))
	local anchor = normalize(definition.anchor)
	local replacement = normalize(readFile(directory .. "/" .. definition.insert))
	local first, last = string.find(source, anchor, 1, true)
	assert(first, "anchor missing in stock: " .. directory)
	assert(string.find(source, anchor, last + 1, true) == nil, "anchor not unique: " .. directory)
	return string.sub(source, 1, first - 1) .. replacement .. string.sub(source, last + 1)
end

local scheduler = { now = 0, nextId = 1, tasks = {} }
function scheduler.performWithDelayGlobal(callback, delay)
	local id = scheduler.nextId
	scheduler.nextId = id + 1
	scheduler.tasks[id] = { at = scheduler.now + delay, callback = callback }
	return id
end
function scheduler.unscheduleGlobal(id)
	scheduler.tasks[id] = nil
end
function scheduler.advance(seconds)
	local target = scheduler.now + seconds
	while true do
		local chosen = nil
		for id, task in pairs(scheduler.tasks) do
			if task.at <= target and (chosen == nil or task.at < chosen.at) then
				chosen = { id = id, at = task.at }
			end
		end
		if chosen == nil then
			break
		end
		local task = scheduler.tasks[chosen.id]
		scheduler.tasks[chosen.id] = nil
		scheduler.now = task.at
		task.callback()
	end
	scheduler.now = target
end
function scheduler.reset()
	scheduler.now = 0
	scheduler.nextId = 1
	scheduler.tasks = {}
end

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

local nextMid = 90000
xyd = {
	tables = { translation = {} },
	mid = setmetatable({}, { __index = function(table, key)
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
}

local source = applyExact(applyExact(normalize(readFile(STOCK_PATH)), CLOSE_PATCH), RETRY_PATCH)
local chunk, loadError = loadstring(source, "@patched-Backend.lua")
assert(chunk, tostring(loadError))
local loaded, Backend = pcall(chunk)
assert(loaded, tostring(Backend))
assert(type(Backend) == "table", "Backend module did not return its class")

local fakeSocket = {}
function fakeSocket:setConnectHandler() end
function fakeSocket:setDisconnectHandler() end
function fakeSocket:setMessageHandler() end
function fakeSocket:retain() end
function fakeSocket:connect() self.connected = true end
function fakeSocket:close() self.closed = true end

local function newBackend(code, body)
	scheduler.reset()
	local backend = Backend.new()
	backend.leagueChatRoomID_ = 7
	backend.leagueSocket_ = nil
	backend.createTCPSocket = function()
		return fakeSocket
	end
	local requests = 0
	function backend:request(mid, parameters, callback)
		requests = requests + 1
		callback(code, body)
	end
	return backend, function()
		return requests
	end
end

local backend, requests = newBackend(1, { error_code = 35028 })
backend:enterLeagueRoom()
ok(requests() == 1, "a permanent refusal sent one MID 192 request")
ok(backend.leagueChatRoomID_ == nil, "a permanent refusal cleared the room id")
scheduler.advance(5)
ok(requests() == 1, "a permanent refusal does not retry")

backend, requests = newBackend(1, { error_code = 35033 })
backend:enterLeagueRoom()
ok(requests() == 1, "the transient code sent one MID 192 request")
ok(backend.leagueChatRoomID_ == 7, "the transient code keeps the room id")
scheduler.advance(4.9)
ok(requests() == 1, "the transient code waits 5 s before retrying")
scheduler.advance(0.1)
ok(requests() == 2, "the transient code retries after 5 s")

backend, requests = newBackend(1, nil)
backend:enterLeagueRoom()
scheduler.advance(5)
ok(requests() == 2, "no reply keeps the 5 s retry")

backend, requests = newBackend(0, { host = "10.0.0.1", port = 18954, room_id = 7 })
backend:enterLeagueRoom()
ok(requests() == 1, "success sent one MID 192 request")
ok(backend.leagueSocket_ == fakeSocket and fakeSocket.connected, "success connects the league socket")
scheduler.advance(5)
ok(requests() == 1, "success does not retry")
backend:closeLeagueRoom()
ok(backend.leagueChatRoomID_ == nil, "closeLeagueRoom clears the room id")

print(string.format("%d assertions", assertions))
