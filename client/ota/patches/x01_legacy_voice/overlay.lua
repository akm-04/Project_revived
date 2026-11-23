-- x01 experimental: legacy (2018) voice lines behind a setting.
--
-- When the setting is on, hero voice paths are redirected from
--   sound/hero_sound/<girl>/<girl>_voiceN.ogg
-- to
--   sound/legacy2018/hero_sound/<girl>/<girl>_voiceN.ogg
-- The redirected path is used only when it can actually be played: the file is already on disk or the catalogue lists a
-- row for it. Otherwise the stock path is returned, so a girl with no 2018 recording keeps her modern voice instead of
-- going silent.
--
-- The flag lives in cc.UserDefault under "gxb_legacy_voice" (no settings-db schema change). Playback itself is unchanged:
-- SelfPlayer.playHeroSound already fetches a missing file on demand (patch x01_voice_on_demand).

local GXB_LEGACY_VOICE_KEY = "gxb_legacy_voice"
local GXB_VOICE_PREFIX = "sound/hero_sound/"
local GXB_VOICE_LEGACY_ROOT = "sound/legacy2018/hero_sound/"

local function gxbLegacyVoiceEnabled()
	return cc.UserDefault:getInstance():getBoolForKey(GXB_LEGACY_VOICE_KEY, false)
end

local function gxbLegacyVoiceAvailable(path)
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

local function gxbLegacyVoiceMap(path)
	if type(path) ~= "string" or path == "" then
		return path
	end
	if not gxbLegacyVoiceEnabled() then
		return path
	end
	if path:sub(1, #GXB_VOICE_PREFIX) ~= GXB_VOICE_PREFIX then
		return path
	end
	local legacy = GXB_VOICE_LEGACY_ROOT .. path:sub(#GXB_VOICE_PREFIX + 1)
	if not gxbLegacyVoiceAvailable(legacy) then
		return path
	end
	return legacy
end

xyd.gxbLegacyVoice = {
	enabled = gxbLegacyVoiceEnabled,
	map = gxbLegacyVoiceMap,
	settingKey = GXB_LEGACY_VOICE_KEY,
}

-- dialogSounds returns the cached click_sounds array; return a mapped copy instead of mutating it.
local gxbDialogSounds = var_0_2.dialogSounds

function var_0_2.dialogSounds(gxbVoiceSelf, gxbVoiceId)
	local sounds = gxbDialogSounds(gxbVoiceSelf, gxbVoiceId)
	if type(sounds) ~= "table" or not gxbLegacyVoiceEnabled() then
		return sounds
	end
	local mapped = {}
	for index, path in ipairs(sounds) do
		mapped[index] = gxbLegacyVoiceMap(path)
	end
	return mapped
end

-- getSingleVoiceInfo returns (sound, dialog, duration); only the path is redirected.
local gxbSingleVoiceInfo = var_0_2.getSingleVoiceInfo

function var_0_2.getSingleVoiceInfo(gxbVoiceSelf, gxbVoiceId, gxbVoiceIndex)
	local sound, dialog, duration = gxbSingleVoiceInfo(gxbVoiceSelf, gxbVoiceId, gxbVoiceIndex)
	return gxbLegacyVoiceMap(sound), dialog, duration
end
