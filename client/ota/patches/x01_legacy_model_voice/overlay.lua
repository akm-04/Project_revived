-- x01: the model's own voice files (idle, victory, attacks, death) follow the same legacy switch.
--
-- The hero page's 2.5D bust plays xyd.tables.model:getAttack4Sound(modelId), and the battle/stand-up animations read the
-- other model sound columns (model.lua sound_move/sound_victory/sound_skill0..4), so wrapping only the hero-table
-- accessors leaves those on the modern cast. This wraps every model accessor that returns a sound path with the same
-- rule: redirect to sound/legacy2018/... while the setting is on, and only when that file is on disk or in the catalogue.

local GXB_LEGACY_VOICE_KEY = "gxb_legacy_voice"
local GXB_VOICE_PREFIX = "sound/hero_sound/"
local GXB_VOICE_LEGACY_ROOT = "sound/legacy2018/hero_sound/"

local function gxbModelLegacyEnabled()
	return cc.UserDefault:getInstance():getBoolForKey(GXB_LEGACY_VOICE_KEY, false)
end

local function gxbModelLegacyAvailable(path)
	if cc.FileUtils:getInstance():isFileExist(path) then
		return true
	end
	local download = xyd.AssetDownload and xyd.AssetDownload.get and xyd.AssetDownload.get()
	if not download or not download.getDownloadVersionInfo then
		return false
	end
	local rows = download:getDownloadVersionInfo({ path })
	return rows ~= nil and #rows > 0
end

local function gxbModelLegacyMap(path)
	if type(path) ~= "string" or path == "" then
		return path
	end
	if not gxbModelLegacyEnabled() then
		return path
	end
	if path:sub(1, #GXB_VOICE_PREFIX) ~= GXB_VOICE_PREFIX then
		return path
	end
	local legacy = GXB_VOICE_LEGACY_ROOT .. path:sub(#GXB_VOICE_PREFIX + 1)
	if not gxbModelLegacyAvailable(legacy) then
		return path
	end
	return legacy
end

for _, gxbModelAccessor in ipairs({
	"getMoveSound",
	"getWinSound",
	"getNormalAttackSound",
	"getAttack1Sound",
	"getAttack2Sound",
	"getAttack3Sound",
	"getAttack4Sound",
	"deathSound",
}) do
	local gxbModelOriginal = var_0_2[gxbModelAccessor]
	if gxbModelOriginal then
		var_0_2[gxbModelAccessor] = function(gxbModelSelf, gxbModelId)
			return gxbModelLegacyMap(gxbModelOriginal(gxbModelSelf, gxbModelId))
		end
	end
end
