-- x01: play a hero voice even when nothing preloaded its file.
--
-- Voices are only fetched by AssetDownload:preloadCharacterSound, which downloads the catalogue entries that share the
-- *directory* of the model's death sound (model.lua). A girl whose model row lists no such path (Gramin, Kenshin, the
-- event girls) never gets her voices queued, so audio.playSound finds no file and stays silent however many rows the
-- catalogue carries. This wrapper fetches the missing file through the normal lazy path and plays it when it arrives.
--
-- For a redirected legacy path it also mirrors the 1.164.0 client, where every voice file was inside the APK: if the
-- legacy fetch cannot produce the file, the stock line plays instead of leaving the tap silent.

local GXB_LEGACY_VOICE_ROOT = "sound/legacy2018/hero_sound/"
local GXB_STOCK_VOICE_ROOT = "sound/hero_sound/"

local gxbVoicePlayHeroSound = var_0_0.playHeroSound

local function gxbVoiceFileExists(path)
	return cc.FileUtils:getInstance():isFileExist(path)
end

local function gxbVoiceStockEquiv(path)
	if path:sub(1, #GXB_LEGACY_VOICE_ROOT) ~= GXB_LEGACY_VOICE_ROOT then
		return nil
	end

	return GXB_STOCK_VOICE_ROOT .. path:sub(#GXB_LEGACY_VOICE_ROOT + 1)
end

function var_0_0.playHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
	if type(gxbVoicePath) ~= "string" or gxbVoicePath == "" then
		return gxbVoicePlayHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
	end

	if gxbVoiceFileExists(gxbVoicePath) then
		return gxbVoicePlayHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
	end

	local download = xyd.AssetDownload and xyd.AssetDownload.get and xyd.AssetDownload.get()

	if not download or not download.downloadResByPath then
		return gxbVoicePlayHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
	end

	local played = false

	download:downloadResByPath(gxbVoicePath, function()
		if played then
			return
		end

		played = true

		if gxbVoiceFileExists(gxbVoicePath) then
			return gxbVoicePlayHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
		end

		local stock = gxbVoiceStockEquiv(gxbVoicePath)

		if stock and gxbVoiceFileExists(stock) then
			print("gxb-legacy-voice: stock fallback for " .. gxbVoicePath)

			return gxbVoicePlayHeroSound(gxbVoiceSelf, stock, gxbVoiceDuration, gxbVoiceArg)
		end

		print("gxb-legacy-voice: missing " .. gxbVoicePath)

		return gxbVoicePlayHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
	end)
end
