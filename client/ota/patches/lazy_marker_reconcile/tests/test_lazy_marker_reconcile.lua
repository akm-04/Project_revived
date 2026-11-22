-- SIMULATED host test: applies the lazy_marker_reconcile patch to stock
-- lazyFileManager.lua and drives its init with a fake marker map. A marker is
-- removed only when its file exists with the marker's md5; unrelated keys,
-- missing files and mismatched md5s stay, and the stamp gates the pass per
-- applied asset version.

local STOCK_PATH = assert(os.getenv("GXB_STOCK_LAZY_MANAGER"), "GXB_STOCK_LAZY_MANAGER required")
local PATCH_DIR = assert(os.getenv("GXB_LAZY_RECONCILE_PATCH"), "GXB_LAZY_RECONCILE_PATCH required")

local counters = { assertions = 0, flushes = 0 }
local function ok(condition, message)
	if not condition then
		error("FAIL: " .. message, 2)
	end
	counters.assertions = counters.assertions + 1
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

local definition = cjson.decode(readFile(PATCH_DIR .. "/patch.json"))
local stock = normalize(readFile(STOCK_PATH))
local anchor = normalize(definition.anchor)
local replacement = normalize(readFile(PATCH_DIR .. "/" .. definition.insert))
local first, last = string.find(stock, anchor, 1, true)
assert(first, "anchor missing in stock " .. STOCK_PATH)
assert(string.find(stock, anchor, last + 1, true) == nil, "anchor is not unique")

local chunk = assert(loadstring(string.sub(stock, 1, first - 1) .. replacement .. string.sub(stock, last + 1), "@patched-lazyFileManager.lua"))
local manager = assert(chunk())

local STEP_DIRECTORY = "/device/"
local STAMP_KEY = "__lazy_marker_reconcile__"
local VERSION_KEY = "__version__"

local files = {}
local digests = {}
local defaults = {}
local sourceDocument = "{}"

local fileUtils = {
	isFileExist = function(self, path)
		return files[path] == true
	end,
	isDirectoryExist = function(self, path)
		return true
	end,
	getStringFromFile = function(self, path)
		return sourceDocument
	end,
	createDirectory = function(self, path) end,
	renameFile = function(self, directory, from, to) end,
	removeFile = function(self, path)
		error("the reconcile must never delete a file: " .. path)
	end,
}

xyd = {
	versionUpdatePath = STEP_DIRECTORY,
	USER_DEFAULTS_VERSION_KEY = VERSION_KEY,
}

cc = {
	FileUtils = { getInstance = function()
		return fileUtils
	end },
	UserDefault = { getInstance = function()
		return {
			getStringForKey = function(self, key)
				return defaults[key]
			end,
			setStringForKey = function(self, key, value)
				defaults[key] = value
			end,
		}
	end },
	Crypto = { MD5File = function(self, path)
		return digests[path]
	end },
}

manager.flush = function(self)
	counters.flushes = counters.flushes + 1
end

local function marker(path, md5)
	return cjson.encode({ path = path, md5 = md5, version = "1.631.1", size = 1 })
end

local function staleMaps()
	return {
		["__lazy__res___web___a.png"] = marker("res/web/a.png", "md5-a"),
		["__lazy__res___web___b.png"] = marker("res/web/b.png", "md5-b-expected"),
		["__lazy__res___web___c.png"] = marker("res/web/c.png", "md5-c"),
		["__lazy__res___web___d.png"] = marker("res/web/d.png", "md5-d"),
		["plain_key"] = marker("res/web/d.png", "md5-d"),
		["__lazy__broken"] = "not json",
	}
end

local function run(maps, appliedVersion)
	sourceDocument = cjson.encode(maps)
	defaults[VERSION_KEY] = appliedVersion
	counters.flushes = 0
	manager:init()
end

files = {
	[STEP_DIRECTORY .. "lazyFile.json"] = true,
	[STEP_DIRECTORY .. "res/a.png"] = true,
	[STEP_DIRECTORY .. "res/b.png"] = true,
	[STEP_DIRECTORY .. "res/d.png"] = true,
}
digests = {
	[STEP_DIRECTORY .. "res/a.png"] = "md5-a",
	[STEP_DIRECTORY .. "res/b.png"] = "md5-b-actual",
	[STEP_DIRECTORY .. "res/d.png"] = "md5-d",
}

run(staleMaps(), "1.631.1")

ok(manager.maps["__lazy__res___web___a.png"] == nil, "a matching file and md5 removes the marker")
ok(manager.maps["__lazy__res___web___b.png"] ~= nil, "a mismatched md5 keeps the marker")
ok(manager.maps["__lazy__res___web___c.png"] ~= nil, "a missing file keeps the marker")
ok(manager.maps["plain_key"] ~= nil, "a non-__lazy__ key is untouched")
ok(manager.maps["__lazy__broken"] ~= nil, "a malformed marker value is kept")
ok(counters.flushes == 1, "one run flushes once")
ok(defaults[STAMP_KEY] == "1.631.1", "the applied asset version is the stamp")
ok(files[STEP_DIRECTORY .. "res/a.png"] == true, "the reconcile never deletes a file")

run(staleMaps(), "1.631.1")
ok(manager.maps["__lazy__res___web___a.png"] ~= nil, "the same stamp does not run again")
ok(counters.flushes == 0, "a skipped run does not flush")

run(staleMaps(), "1.632.0")
ok(manager.maps["__lazy__res___web___a.png"] == nil, "a new stamp runs the pass again")
ok(counters.flushes == 1, "the new run flushes once")
ok(defaults[STAMP_KEY] == "1.632.0", "the new applied asset version replaces the stamp")

print(string.format("%d assertions", counters.assertions))
