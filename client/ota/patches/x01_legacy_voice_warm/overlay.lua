-- x01: warm the legacy voice set in the background, so the first tap on a girl is the old take.
--
-- The 1.164.0 client carried every voice file in the APK, so a line was playable the moment a table named it. Here the
-- files arrive lazily, and the team-select screens call audio.playSound directly: a girl whose legacy file has not
-- reached the device yet plays the stock line on that tap. Rather than fix that per screen, this queues the whole
-- legacy tree once per session through the normal lazy download, the same way the asset update delivers everything
-- else. It runs only while the 2018 toggle is on and stops as soon as the catalogue has nothing left to fetch.

local GXB_LEGACY_VOICE_KEY = "gxb_legacy_voice"
local GXB_LEGACY_VOICE_ROOT = "sound/legacy2018/hero_sound/"
local GXB_WARM_FIRST_DELAY = 12
local GXB_WARM_RETRY_DELAY = 60
local GXB_WARM_MAX_ATTEMPTS = 10

-- BEGIN GENERATED: legacy voice manifest (scratch/build_legacy_manifest.py)
local GXB_LEGACY_VOICES = {}
-- END GENERATED

local gxbWarmAttempts = 0
local gxbWarmRunning = false
local gxbWarmArmed = false

local function gxbWarmEnabled()
	return cc.UserDefault:getInstance():getBoolForKey(GXB_LEGACY_VOICE_KEY, false)
end

local function gxbWarmSchedule(delay)
	local director = cc.Director and cc.Director:getInstance()

	if not director or not director.getScheduler then
		return
	end

	director:getScheduler():scheduleScriptFunc(gxbWarmLegacyVoices, delay, false)
end

function gxbWarmLegacyVoices()
	if gxbWarmRunning or gxbWarmAttempts >= GXB_WARM_MAX_ATTEMPTS then
		return
	end

	if not gxbWarmEnabled() then
		return
	end

	local download = var_0_1.get()

	if not download or not download.getDownloadVersionInfo or not download.downloadFiles then
		return
	end

	local paths = {}

	for girl, slots in pairs(GXB_LEGACY_VOICES) do
		for index in slots:gmatch("%d") do
			table.insert(paths, GXB_LEGACY_VOICE_ROOT .. girl .. "/" .. girl .. "_voice" .. index .. ".ogg")
		end
	end

	local rows = download:getDownloadVersionInfo(paths)

	if type(rows) ~= "table" or #rows == 0 then
		return
	end

	gxbWarmAttempts = gxbWarmAttempts + 1
	gxbWarmRunning = true
	print("gxb-legacy-voice: warming " .. #rows .. " files (attempt " .. gxbWarmAttempts .. ")")

	download:downloadFiles(rows, function(gxbWarmPercent, gxbWarmDone)
		if not gxbWarmDone then
			return
		end

		gxbWarmRunning = false
		print("gxb-legacy-voice: warm pass done")

		if gxbWarmAttempts < GXB_WARM_MAX_ATTEMPTS then
			gxbWarmSchedule(GXB_WARM_RETRY_DELAY)
		end
	end)
end

xyd.gxbLegacyVoiceWarm = gxbWarmLegacyVoices

-- Arm once the singleton is first used (boot), not at module load, so the scheduler and the user setting exist.
local gxbWarmGet = var_0_1.get

function var_0_1.get()
	local instance = gxbWarmGet()

	if not gxbWarmArmed then
		gxbWarmArmed = true
		gxbWarmSchedule(GXB_WARM_FIRST_DELAY)
	end

	return instance
end
