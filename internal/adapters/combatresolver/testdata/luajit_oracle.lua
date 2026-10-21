-- I8-2A fallback Lua 5.1 adapter run under `luajit -joff`. It rebuilds the
-- environment newMachine gives GopherLua and replays the GopherLua entropy tape,
-- so any engine divergence surfaces as a tape mismatch or a report difference.
-- Usage: luajit -joff luajit_oracle.lua <export dir> fight|load
local dir, mode = assert(arg[1]), assert(arg[2])
local open, exit, compile = io.open, os.exit, loadstring

local function read(path)
	local file = assert(open(path, "rb"))
	local data = file:read("*a")
	file:close()
	return data
end

local function write(path, data)
	local file = assert(open(path, "wb"))
	file:write(data)
	file:close()
end

-- Length-prefixed tokens "<bytes>:<data>" written by the Go exporter.
local function tokens(data)
	local position = 1
	return function()
		local colon = data:find(":", position, true)
		if not colon then
			return nil
		end
		local length = tonumber(data:sub(position, colon - 1))
		local value = data:sub(colon + 1, colon + length)
		position = colon + length + 1
		return value
	end
end

local function chunk(source, name)
	return assert(compile((source:gsub("^\239\187\191", "")), name))
end

local input = chunk(read(dir .. "/input.lua"), "input")()

for _, name in ipairs({ "io", "os", "debug", "jit", "bit", "ffi" }) do
	_G[name] = nil
	package.loaded[name] = nil
end
for i = #package.loaders, 2, -1 do
	package.loaders[i] = nil
end

local modules = {}
for name in tokens(read(dir .. "/modules.idx")) do
	modules[#modules + 1] = name
	package.preload[name] = function()
		return chunk(read(dir .. "/modules/" .. name .. ".lua"), name)()
	end
end

local parser = {
	parse = function(name, callback)
		name = name:gsub("%.lua$", "")
		local file = open(dir .. "/tables/" .. name .. ".tbl", "rb")
		if not file then
			error("combat corpus: table " .. name .. " is not in the pinned corpus")
		end
		local next_token = tokens(file:read("*a"))
		file:close()
		local kind = next_token()
		local keys = nil
		if kind == "INDEXED" then
			keys = {}
			for _ = 1, tonumber(next_token()) do
				local field = next_token()
				keys[field] = tonumber(next_token())
			end
		end
		for _ = 1, tonumber(next_token()) do
			local row, fields = {}, tonumber(next_token())
			for i = 1, fields do
				if kind == "INDEXED" then
					row[i] = next_token()
				else
					local field = next_token()
					row[field] = next_token()
				end
			end
			if kind == "INDEXED" then
				callback(row, keys)
			else
				callback(row)
			end
		end
	end,
}
package.preload["lib.battle.app.common.tables.TableParser"] = function() return parser end
package.preload["app.common.tables.TableParser"] = function() return parser end

local tape, used, divergence = {}, 0, nil
do
	local next_token = tokens(read(dir .. "/tape.tok"))
	for op in next_token do
		local entry = { op = op, args = {} }
		for i = 1, tonumber(next_token()) do
			entry.args[i] = tonumber(next_token())
		end
		entry.result = tonumber(next_token())
		tape[#tape + 1] = entry
	end
end
local function replay(op, ...)
	used = used + 1
	local entry, count = tape[used], select("#", ...)
	local matches = entry ~= nil and entry.op == op and #entry.args == count
	for i = 1, count do
		matches = matches and tonumber((select(i, ...))) == entry.args[i]
	end
	if not matches then
		divergence = divergence or string.format("tape entry %d: %s(%s)", used, op, table.concat({ ... }, ","))
		error("COMBAT_ORACLE_TAPE_DIVERGENCE " .. divergence)
	end
	return entry.result
end
math.random = function(...) return replay("random", ...) end
math.randomseed = function(...) replay("randomseed", ...) end

combat_os = {
	time = function(...)
		if select("#", ...) ~= 0 then
			error("COMBAT_ADAPTER_OS_TIME_ARGUMENTS_UNSUPPORTED")
		end
		return input.os_time
	end,
	clock = function() return 0 end,
}

local function quote(s)
	return '"' .. s:gsub('[%c"\\]', function(c)
		if c == '"' then return '\\"' end
		if c == "\\" then return "\\\\" end
		return string.format("\\u%04x", c:byte())
	end) .. '"'
end

-- Same shape rules as resolver.go toJSON.
local function encode(v, depth, out)
	if depth > 64 then
		error("report nesting too deep")
	end
	local kind = type(v)
	if kind == "nil" then
		out[#out + 1] = "null"
		return
	end
	if kind == "boolean" then
		out[#out + 1] = tostring(v)
		return
	end
	if kind == "string" then
		out[#out + 1] = quote(v)
		return
	end
	if kind == "number" then
		if v ~= v or v == math.huge or v == -math.huge then
			error("non-finite report number")
		end
		out[#out + 1] = string.format("%.17g", v)
		return
	end
	if kind ~= "table" then
		error("report value type " .. kind)
	end
	local count, max_index, sequence = 0, 0, true
	for k in pairs(v) do
		count = count + 1
		if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
			sequence = false
		elseif k > max_index then
			max_index = k
		end
	end
	if sequence and count > 0 and max_index == count then
		out[#out + 1] = "["
		for i = 1, count do
			if i > 1 then
				out[#out + 1] = ","
			end
			encode(v[i], depth + 1, out)
		end
		out[#out + 1] = "]"
		return
	end
	local seen, first = {}, true
	out[#out + 1] = "{"
	for k, item in pairs(v) do
		local key = tostring(k)
		if type(k) == "number" and k == math.floor(k) and math.abs(k) < 2 ^ 63 then
			key = string.format("%d", k)
		end
		if seen[key] then
			error("report key collision " .. key)
		end
		seen[key] = true
		if not first then
			out[#out + 1] = ","
		end
		first = false
		out[#out + 1] = quote(key) .. ":"
		encode(item, depth + 1, out)
	end
	out[#out + 1] = "}"
end
function combat_json_encode(v)
	local out = {}
	encode(v, 0, out)
	return table.concat(out)
end

combat_input = input
local ok, failure = pcall(function()
	chunk(read(dir .. "/bootstrap.lua"), "combat bootstrap")()
end)

if mode == "load" then
	local loaded = {}
	for _, name in ipairs(modules) do
		local loaded_ok = ok and pcall(require, name)
		loaded[#loaded + 1] = quote(name) .. ":" .. tostring(loaded_ok and true or false)
	end
	write(dir .. "/luajit_load.json", "{" .. table.concat(loaded, ",") .. "}")
	exit(ok and 0 or 1)
end

if ok then
	ok, failure = pcall(function()
		chunk(read(dir .. "/driver.lua"), "combat driver")()
	end)
end
local outcome = {
	error = (not ok) and tostring(failure) or nil,
	divergence = divergence,
	tape_used = used,
	tape_size = #tape,
}
if ok then
	outcome.star = combat_output.star
	outcome.frames = combat_output.frames
	outcome.timed_out = combat_output.timed_out
	outcome.report_error = combat_output.report_error
	write(dir .. "/luajit_report.json", combat_output.report)
end
write(dir .. "/luajit_outcome.json", combat_json_encode(outcome))
