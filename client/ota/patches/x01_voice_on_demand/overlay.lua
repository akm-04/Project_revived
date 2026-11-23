-- x01: play a hero voice even when nothing preloaded its file.
--
-- Voices are only fetched by AssetDownload:preloadCharacterSound, which downloads the catalogue entries that share the
-- *directory* of the model's death sound (model.lua). A girl whose model row lists no such path (Gramin, Kenshin, the
-- event girls) never gets her voices queued, so audio.playSound finds no file and stays silent however many rows the
-- catalogue carries. This wrapper fetches the missing file through the normal lazy path and plays it when it arrives.

local gxbVoicePlayHeroSound = var_0_0.playHeroSound

function var_0_0.playHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
	if type(gxbVoicePath) ~= "string" or gxbVoicePath == "" then
		return gxbVoicePlayHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
	end

	if cc.FileUtils:getInstance():isFileExist(gxbVoicePath) then
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
		gxbVoicePlayHeroSound(gxbVoiceSelf, gxbVoicePath, gxbVoiceDuration, gxbVoiceArg)
	end)
end
