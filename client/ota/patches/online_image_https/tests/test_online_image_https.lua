-- SIMULATED host test: applies the online_image_https patch to stock
-- OnlineImageSprite.lua and drives ctor with http, https and bare URLs. The
-- downloader must receive http and https untouched, and a bare host gets the
-- http prefix it had before.

local STOCK_PATH = assert(os.getenv("GXB_STOCK_ONLINE_IMAGE"), "GXB_STOCK_ONLINE_IMAGE required")
local PATCH_DIR = assert(os.getenv("GXB_ONLINE_IMAGE_PATCH"), "GXB_ONLINE_IMAGE_PATCH required")

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

local definition = cjson.decode(readFile(PATCH_DIR .. "/patch.json"))
local stock = normalize(readFile(STOCK_PATH))
local anchor = normalize(definition.anchor)
local replacement = normalize(readFile(PATCH_DIR .. "/" .. definition.insert))
local first, last = string.find(stock, anchor, 1, true)
assert(first, "anchor missing in stock " .. STOCK_PATH)
assert(string.find(stock, anchor, last + 1, true) == nil, "anchor is not unique")

class = function(name, factory)
	local module = { __name = name, __factory = factory }
	return module
end
display = {
	newSprite = function()
		return {}
	end,
}

local patched = string.sub(stock, 1, first - 1) .. replacement .. string.sub(stock, last + 1)
local chunk = assert(loadstring(patched, "@patched-OnlineImageSprite.lua"))
local module = assert(chunk())

local function downloadArgument(url)
	local sprite = { url = url, baseInfo = {} }
	sprite.isExist = function()
		return false
	end
	local downloaded = nil
	sprite.downloadImage = function(_, target)
		downloaded = target
	end
	module.ctor(sprite, nil, url, nil, nil, sprite.baseInfo)
	return downloaded
end

ok(downloadArgument("http://example.test/p.png") == "http://example.test/p.png", "http URL stays unchanged")
ok(downloadArgument("https://example.test/p.png") == "https://example.test/p.png", "https URL stays unchanged")
ok(downloadArgument("example.test/p.png") == "http://example.test/p.png", "bare URL gets the http prefix")

print("OK " .. assertions .. " assertions")
