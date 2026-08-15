local var_0_0 = class("Settings")

function var_0_0.ctor(arg_1_0)
	cc(arg_1_0):addComponent("components.behavior.EventProtocol"):exportMethods()

	local var_1_0 = xyd.db.openUserDefaults()

	pcall(handler(var_1_0, var_1_0.exec), "        ALTER TABLE settings ADD COLUMN autoStandbyOn INT NOT NULL DEFAULT 1;\n        ALTER TABLE settings ADD COLUMN autoDialogOn INT NOT NULL DEFAULT 1;\n    ")
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0:load_()
end

function var_0_0.persist(arg_3_0)
	if not arg_3_0.loaded_ then
		return
	end

	local var_3_0 = xyd.db.openUserDefaults():prepare("        INSERT OR REPLACE INTO settings (id, battleSpeed, isAutoBattle, isAutoBoss, backgroundMusicOn, soundEffectOn, screenRotation, powerSavingMode, battleMusicOn, battleSoundOn, autoStandbyOn, autoDialogOn, live2dOn, bgCanLoad, showFAQ)\n        VALUES (0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)\n    ")

	var_3_0:bind_values(arg_3_0.battleSpeed, arg_3_0.isAutoBattle, arg_3_0.isAutoBoss, arg_3_0.backgroundMusicOn, arg_3_0.soundEffectOn, arg_3_0.screenRotation, arg_3_0.powerSavingMode, arg_3_0.battleMusicOn, arg_3_0.battleSoundOn, arg_3_0.autoStandbyOn, arg_3_0.autoDialogOn, arg_3_0.live2dOn, arg_3_0.bgCanLoad, arg_3_0.showFAQ)
	var_3_0:step()
	var_3_0:reset()
end

function var_0_0.setBattleSpeed(arg_4_0, arg_4_1)
	arg_4_0.battleSpeed = arg_4_1

	arg_4_0:persist()
	arg_4_0:dispatchEvent({
		name = xyd.event.BATTLE_SPEED_CHANGED,
		speed = arg_4_1
	})
end

function var_0_0.setAutoBattle(arg_5_0, arg_5_1)
	arg_5_0.isAutoBattle = arg_5_1

	arg_5_0:persist()
	arg_5_0:dispatchEvent({
		name = xyd.event.BATTLE_AUTO_CHANGED,
		auto = arg_5_1
	})
end

function var_0_0.setAutoBoss(arg_6_0, arg_6_1)
	arg_6_0.isAutoBoss = arg_6_1

	arg_6_0:persist()
	arg_6_0:dispatchEvent({
		name = xyd.event.BATTLE_AUTO_BOSS_CHANGED,
		auto = arg_6_1
	})
end

function var_0_0.setBakgroundMusic(arg_7_0, arg_7_1, arg_7_2)
	arg_7_1 = arg_7_1 and 1 or 0
	arg_7_0.backgroundMusicOn = arg_7_1

	if not arg_7_2 then
		audio.setMusicVolume(arg_7_0.backgroundMusicOn)
	end
end

function var_0_0.setSoundEffect(arg_8_0, arg_8_1)
	arg_8_1 = arg_8_1 and 1 or 0
	arg_8_0.soundEffectOn = arg_8_1

	audio.setSoundsVolume(arg_8_0.soundEffectOn)
end

function var_0_0.setBattleMusic(arg_9_0, arg_9_1)
	arg_9_1 = arg_9_1 and 1 or 0
	arg_9_0.battleMusicOn = arg_9_1
end

function var_0_0.setBattleSound(arg_10_0, arg_10_1)
	arg_10_1 = arg_10_1 and 1 or 0
	arg_10_0.battleSoundOn = arg_10_1
end

function var_0_0.setAutoDialog(arg_11_0, arg_11_1)
	arg_11_1 = arg_11_1 and 1 or 0
	arg_11_0.autoDialogOn = arg_11_1
end

function var_0_0.setAutoStandby(arg_12_0, arg_12_1)
	arg_12_1 = arg_12_1 and 1 or 0
	arg_12_0.autoStandbyOn = arg_12_1
end

function var_0_0.setLive2dOn(arg_13_0, arg_13_1)
	arg_13_1 = arg_13_1 and 1 or 0
	arg_13_0.live2dOn = arg_13_1
end

function var_0_0.setShowFAQ(arg_14_0, arg_14_1)
	arg_14_0.showFAQ = arg_14_1 or 0

	arg_14_0:persist()
end

function var_0_0.getSoundEffect(arg_15_0)
	return arg_15_0.soundEffectOn
end

function var_0_0.getBackgroudMusicOn(arg_16_0)
	return arg_16_0.backgroundMusicOn
end

function var_0_0.getAutoDialog(arg_17_0)
	return arg_17_0.autoDialogOn
end

function var_0_0.getAutoStandby(arg_18_0)
	return arg_18_0.autoStandbyOn
end

function var_0_0.getBattleMusicOn(arg_19_0)
	return arg_19_0.battleMusicOn
end

function var_0_0.getBattleSoundOn(arg_20_0)
	return arg_20_0.battleSoundOn
end

function var_0_0.getLive2dOn(arg_21_0)
	return arg_21_0.live2dOn
end

function var_0_0.getShowFAQ(arg_22_0)
	return arg_22_0.showFAQ
end

function var_0_0.getBGCanLoadTime(arg_23_0)
	return arg_23_0.bgCanLoad
end

function var_0_0.setBGCanLoadTime(arg_24_0, arg_24_1)
	arg_24_0.bgCanLoad = arg_24_1

	arg_24_0:persist()
end

function var_0_0.load_(arg_25_0)
	arg_25_0.battleSpeed = 1
	arg_25_0.isAutoBattle = false
	arg_25_0.isAutoBoss = false
	arg_25_0.backgroundMusicOn = 1
	arg_25_0.soundEffectOn = 1
	arg_25_0.screenRotation = true
	arg_25_0.powerSavingMode = false
	arg_25_0.battleMusicOn = 1
	arg_25_0.battleSoundOn = 1
	arg_25_0.autoStandbyOn = 1
	arg_25_0.autoDialogOn = 1
	arg_25_0.live2dOn = 0
	arg_25_0.bgCanLoad = 0
	arg_25_0.showFAQ = 1

	local var_25_0 = xyd.db.openUserDefaults()
	local var_25_1 = var_25_0:prepare("SELECT * FROM settings")
	local var_25_2 = true

	for iter_25_0 in var_25_1:nrows() do
		var_25_2 = false
		arg_25_0.battleSpeed = tonumber(iter_25_0.battleSpeed)
		arg_25_0.isAutoBattle = tonumber(iter_25_0.isAutoBattle) ~= 0
		arg_25_0.isAutoBoss = tonumber(iter_25_0.isAutoBoss) ~= 0
		arg_25_0.backgroundMusicOn = tonumber(iter_25_0.backgroundMusicOn)
		arg_25_0.soundEffectOn = tonumber(iter_25_0.soundEffectOn)
		arg_25_0.screenRotation = tonumber(iter_25_0.screenRotation) ~= 0
		arg_25_0.powerSavingMode = tonumber(iter_25_0.powerSavingMode) ~= 0
		arg_25_0.battleMusicOn = tonumber(iter_25_0.battleMusicOn)
		arg_25_0.battleSoundOn = tonumber(iter_25_0.battleSoundOn)
		arg_25_0.autoStandbyOn = tonumber(iter_25_0.autoStandbyOn)
		arg_25_0.autoDialogOn = tonumber(iter_25_0.autoDialogOn)
		arg_25_0.live2dOn = tonumber(iter_25_0.live2dOn)
		arg_25_0.bgCanLoad = tonumber(iter_25_0.bgCanLoad)
		arg_25_0.showFAQ = tonumber(iter_25_0.showFAQ)

		if iter_25_0.soundEffectOn == nil then
			assert(var_25_0:exec("                ALTER TABLE settings ADD COLUMN soundEffectOn INT NOT NULL DEFAULT 1;\n                ALTER TABLE settings ADD COLUMN screenRotation INT NOT NULL DEFAULT 1;\n                ALTER TABLE settings ADD COLUMN powerSavingMode INT NOT NULL DEFAULT 0;\n             ") == sqlite3.OK)
		end

		if iter_25_0.battleSoundOn == nil then
			pcall(handler(var_25_0, var_25_0.exec), "                ALTER TABLE settings ADD COLUMN battleMusicOn INT NOT NULL DEFAULT 1;\n                ALTER TABLE settings ADD COLUMN battleSoundOn INT NOT NULL DEFAULT 1;\n            ")

			arg_25_0.battleMusicOn = 1
			arg_25_0.battleSoundOn = 1
		end

		if iter_25_0.live2dOn == nil then
			pcall(handler(var_25_0, var_25_0.exec), "                ALTER TABLE settings ADD COLUMN live2dOn INT NOT NULL DEFAULT 0;\n            ")

			arg_25_0.live2dOn = 0
		end

		if iter_25_0.bgCanLoad == nil then
			pcall(handler(var_25_0, var_25_0.exec), "                ALTER TABLE settings ADD COLUMN bgCanLoad INT NOT NULL DEFAULT 0;\n            ")

			arg_25_0.bgCanLoad = 0
		end

		if iter_25_0.showFAQ == nil then
			pcall(handler(var_25_0, var_25_0.exec), "                ALTER TABLE settings ADD COLUMN showFAQ INT NOT NULL DEFAULT 1;\n            ")

			arg_25_0.showFAQ = 1
		end

		break
	end

	if var_25_2 == true then
		pcall(handler(var_25_0, var_25_0.exec), "            ALTER TABLE settings ADD COLUMN battleMusicOn INT NOT NULL DEFAULT 1;\n            ALTER TABLE settings ADD COLUMN battleSoundOn INT NOT NULL DEFAULT 1;\n        ")
		pcall(handler(var_25_0, var_25_0.exec), "            ALTER TABLE settings ADD COLUMN live2dOn INT NOT NULL DEFAULT 0;\n        ")
		pcall(handler(var_25_0, var_25_0.exec), "            ALTER TABLE settings ADD COLUMN bgCanLoad INT NOT NULL DEFAULT 0;\n        ")
		pcall(handler(var_25_0, var_25_0.exec), "            ALTER TABLE settings ADD COLUMN showFAQ INT NOT NULL DEFAULT 1;\n        ")

		arg_25_0.battleMusicOn = 1
		arg_25_0.battleSoundOn = 1
		arg_25_0.live2dOn = 0
		arg_25_0.bgCanLoad = 0
		arg_25_0.showFAQ = 1
	end

	audio.setMusicVolume(arg_25_0.backgroundMusicOn)
	audio.setSoundsVolume(arg_25_0.soundEffectOn)

	arg_25_0.loaded_ = true
end

return var_0_0
