-- SIMULATED host test of x01_legacy_voice_warm/overlay.lua: with the 2018
-- switch on the warmer hands the generated legacy manifest to the downloader;
-- with it off it queues nothing. The downloader reports no version rows, so no
-- transfer is driven.

local OVERLAY_PATH = assert(arg[1], "overlay path required")

local queued = nil
local settingEnabled = true

local download = {
	getDownloadVersionInfo = function(_, paths)
		queued = paths
		return {}
	end,
	downloadFiles = function() end,
}

cc = {
	UserDefault = {
		getInstance = function()
			return {
				getBoolForKey = function()
					return settingEnabled
				end,
			}
		end,
	},
}
xyd = {}

local handle = assert(io.open(OVERLAY_PATH, "rb"))
local overlay = handle:read("*a")
handle:close()
local apply = assert(loadstring("local var_0_1 = ...\n" .. overlay))
apply({get = function() return download end})

queued = nil
settingEnabled = true
xyd.gxbLegacyVoiceWarm()
assert(type(queued) == "table", "the warmer did not ask the downloader for paths")
assert(#queued > 0, "the warmer queued no legacy voices with the switch on")
local seen = {}
for _, path in ipairs(queued) do
	seen[path] = true
end
for index = 1, 9 do
	local expected = "sound/legacy2018/hero_sound/aidehua/aidehua_voice" .. index .. ".ogg"
	assert(seen[expected], "expected legacy voice was not queued: " .. expected)
end
print("PASS legacy warming queued " .. #queued .. " paths with the switch on")

queued = nil
settingEnabled = false
xyd.gxbLegacyVoiceWarm()
assert(queued == nil, "the warmer queued paths with the switch off")
print("PASS legacy warming queued nothing with the switch off")
