local var_0_0 = {
	_buffers = {},
	_sources = {}
}

var_0_0._scheduler = nil
var_0_0._handles = {}
var_0_0._sources[1] = Rapid2D_CAudio.newSource()

if not var_0_0._sources[1] then
	print("Error: init BGM source fail, check if have OpenAL init error above!")

	function var_0_0.loadFile(arg_1_0, arg_1_1)
		arg_1_1(arg_1_0, true)
	end

	function var_0_0.unloadFile(arg_2_0)
		return
	end

	function var_0_0.unloadAllFile()
		return
	end

	function var_0_0.playBGM(arg_4_0, arg_4_1)
		return
	end

	function var_0_0.playBGMSync(arg_5_0, arg_5_1)
		return
	end

	function var_0_0.stopBGM()
		return
	end

	function var_0_0.setBGMVolume(arg_7_0)
		return
	end

	function var_0_0.playEffect(arg_8_0, arg_8_1)
		return
	end

	function var_0_0.setEffectVolume(arg_9_0)
		return
	end

	function var_0_0.stopEffect()
		return
	end

	function var_0_0.stopAll()
		return
	end

	function var_0_0.pauseAll()
		return
	end

	function var_0_0.resumeAll()
		return
	end

	function var_0_0.playSound(arg_14_0, arg_14_1)
		return
	end

	return var_0_0
end

var_0_0._BGMVolume = 1
var_0_0._effectVolume = 1

local var_0_1 = require("framework.scheduler")

local function var_0_2(arg_15_0)
	local var_15_0 = var_0_0._sources
	local var_15_1 = var_0_0._handles
	local var_15_2 = #var_15_0
	local var_15_3 = 2

	while var_15_3 <= var_15_2 do
		if var_15_0[var_15_3]:getStat() == 4 then
			var_15_0[var_15_3]:__gc()
			table.remove(var_15_0, var_15_3)
			table.remove(var_15_1, var_15_3)

			var_15_2 = var_15_2 - 1
		else
			var_15_3 = var_15_3 + 1
		end
	end

	if var_15_2 == 1 then
		var_0_1.unscheduleGlobal(var_0_0._scheduler)

		var_0_0._scheduler = nil
	end
end

function var_0_0.loadFile(arg_16_0, arg_16_1)
	if var_0_0._buffers[arg_16_0] then
		arg_16_1(arg_16_0, true)
	else
		assert(arg_16_1, "ONLY support asyn load file, please set callback!")
		Rapid2D_CAudio.newBuffer(arg_16_0, function(arg_17_0)
			if arg_17_0 then
				var_0_0._buffers[arg_16_0] = arg_17_0

				arg_16_1(arg_16_0, true)
			else
				arg_16_1(arg_16_0, false)
			end
		end)
	end
end

function var_0_0.unloadFile(arg_18_0)
	local var_18_0 = var_0_0._buffers[arg_18_0]

	if var_18_0 then
		var_18_0:__gc()
	end

	var_0_0._buffers[arg_18_0] = nil
end

function var_0_0.unloadAllFile()
	for iter_19_0, iter_19_1 in pairs(var_0_0._buffers) do
		iter_19_1:__gc()
	end

	var_0_0._buffers = {}
end

function var_0_0.playBGMSync(arg_20_0, arg_20_1)
	var_0_0.loadFile(arg_20_0, function(arg_21_0, arg_21_1)
		if arg_21_1 then
			var_0_0.playBGM(arg_21_0, arg_20_1)
		end
	end)
end

function var_0_0.playBGM(arg_22_0, arg_22_1)
	local var_22_0 = var_0_0._buffers[arg_22_0]

	if not var_22_0 then
		print(arg_22_0 .. " have not loaded!!")

		return
	end

	arg_22_1 = arg_22_1 ~= false and true or false

	var_0_0._sources[1]:stop()
	var_0_0._sources[1]:play2d(var_22_0, arg_22_1)
	var_0_0._sources[1]:setVolume(var_0_0._BGMVolume)
end

function var_0_0.stopBGM()
	var_0_0._sources[1]:stop()
end

function var_0_0.pauseBGM()
	var_0_0._sources[1]:pause()
end

function var_0_0.resumeBGM()
	var_0_0._sources[1]:resume()
end

function var_0_0.setBGMVolume(arg_26_0)
	if arg_26_0 > 1 then
		arg_26_0 = 1
	end

	if arg_26_0 < 0 then
		arg_26_0 = 0
	end

	var_0_0._sources[1]:setVolume(arg_26_0)

	var_0_0._BGMVolume = arg_26_0
end

function var_0_0.getBGMVolume()
	return var_0_0._BGMVolume
end

function var_0_0.playEffectSync(arg_28_0, arg_28_1)
	var_0_0.loadFile(arg_28_0, function(arg_29_0, arg_29_1)
		if arg_29_1 then
			var_0_0.playEffect(arg_29_0, arg_28_1)
		end
	end)
end

function var_0_0.playEffect(arg_30_0, arg_30_1)
	local var_30_0 = var_0_0._buffers[arg_30_0]

	if not var_30_0 then
		print(arg_30_0 .. " have not loaded!!")

		return
	end

	local var_30_1 = Rapid2D_CAudio.newSource()

	if var_30_1 then
		arg_30_1 = arg_30_1 == true and true or false

		table.insert(var_0_0._sources, var_30_1)
		table.insert(var_0_0._handles, arg_30_0)
		var_30_1:setVolume(var_0_0._effectVolume)
		var_30_1:play2d(var_30_0, arg_30_1)

		if not var_0_0._scheduler then
			var_0_0._scheduler = var_0_1.scheduleGlobal(var_0_2, 0.1)
		end
	end

	return var_30_1
end

function var_0_0.setEffectVolume(arg_31_0)
	if arg_31_0 > 1 then
		arg_31_0 = 1
	end

	if arg_31_0 < 0 then
		arg_31_0 = 0
	end

	var_0_0._effectVolume = arg_31_0

	for iter_31_0 = 2, #var_0_0._sources do
		var_0_0._sources[iter_31_0]:setVolume(arg_31_0)
	end
end

function var_0_0.getEffectVolume()
	return var_0_0._effectVolume
end

function var_0_0.stopEffect()
	for iter_33_0 = 2, #var_0_0._sources do
		var_0_0._sources[iter_33_0]:stop()
	end
end

function var_0_0.stopAll()
	for iter_34_0 = 1, #var_0_0._sources do
		var_0_0._sources[iter_34_0]:stop()
	end
end

function var_0_0.pauseAll()
	for iter_35_0 = 1, #var_0_0._sources do
		var_0_0._sources[iter_35_0]:pause()
	end
end

function var_0_0.resumeAll()
	for iter_36_0 = 1, #var_0_0._sources do
		var_0_0._sources[iter_36_0]:resume()
	end
end

function var_0_0.playSound(arg_37_0, arg_37_1)
	if arg_37_0 == "" then
		return
	end

	var_0_0.playEffectSync(arg_37_0, arg_37_1)

	return arg_37_0
end

function var_0_0.setSoundsVolume(arg_38_0)
	var_0_0.setEffectVolume(arg_38_0)
end

function var_0_0.getSoundsVolume()
	return var_0_0.getEffectVolume()
end

function var_0_0.setMusicVolume(arg_40_0)
	var_0_0.setBGMVolume(arg_40_0)
end

function var_0_0.getMusicVolume()
	return var_0_0.getBGMVolume()
end

function var_0_0.isMusicPlaying()
	return var_0_0._sources[1]:getStat() == 2
end

function var_0_0.playMusic(arg_43_0, arg_43_1)
	var_0_0.playBGMSync(arg_43_0, arg_43_1)
end

function var_0_0.stopMusic()
	var_0_0.stopBGM()
end

function var_0_0.stopAllSounds()
	var_0_0.stopEffect()
end

function var_0_0.pauseMusic()
	var_0_0.pauseBGM()
end

function var_0_0.resumeMusic()
	var_0_0.resumeBGM()
end

function var_0_0.preloadMusic(arg_48_0)
	if not arg_48_0 then
		printError("audio.preloadMusic() - invalid filename")

		return
	end

	if DEBUG > 1 then
		printInfo("audio.preloadMusic() - filename: %s", tostring(arg_48_0))
	end

	var_0_0.loadFile(arg_48_0, function()
		return
	end)
end

function var_0_0.stopSound(arg_50_0)
	for iter_50_0 = 2, #var_0_0._sources do
		local var_50_0 = var_0_0._sources[iter_50_0]

		if var_50_0 and arg_50_0 == var_0_0._handles[iter_50_0] then
			var_50_0:stop()
		end
	end
end

return var_0_0
