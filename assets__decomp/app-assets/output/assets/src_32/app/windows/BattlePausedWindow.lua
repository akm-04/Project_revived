local var_0_0 = class("BattlePausedWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.WindowName.battlePausedWnd
local var_0_2 = xyd.tables.translation
local var_0_3 = {
	MUSIC = 1,
	SOUND = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
	arg_3_0:getResumeBtn()
	arg_3_0:getExitBtn()
end

function var_0_0.layout(arg_4_0)
	function switchOnShow(arg_5_0)
		if arg_5_0 == var_0_3.MUSIC then
			if xyd.db.settings:getBattleMusicOn() == 1 then
				arg_4_0:nodeByName("txt_music"):setString(var_0_2:translation("MUSIC_ON"))
				arg_4_0:nodeByName("icon_music_close"):setVisible(false)

				if xyd.db.settings:getBackgroudMusicOn() == 1 then
					audio.resumeMusic()
				end
			else
				arg_4_0:nodeByName("txt_music"):setString(var_0_2:translation("MUSIC_OFF"))
				arg_4_0:nodeByName("icon_music_close"):setVisible(true)

				if xyd.db.settings:getBackgroudMusicOn() == 1 then
					audio.pauseMusic()
				end
			end
		elseif xyd.db.settings:getBattleSoundOn() == 1 then
			arg_4_0:nodeByName("txt_sound"):setString(var_0_2:translation("VOICE_ON"))
			arg_4_0:nodeByName("icon_sound_close"):setVisible(false)

			if xyd.db.settings:getSoundEffect() == 1 then
				audio.setSoundsVolume(xyd.db.settings:getBattleSoundOn())
			end
		else
			arg_4_0:nodeByName("txt_sound"):setString(var_0_2:translation("VOICE_OFF"))
			arg_4_0:nodeByName("icon_sound_close"):setVisible(true)

			if xyd.db.settings:getSoundEffect() == 1 then
				audio.setSoundsVolume(xyd.db.settings:getBattleSoundOn())
			end
		end
	end

	switchOnShow(var_0_3.SOUND)
	switchOnShow(var_0_3.MUSIC)
	xyd.addTouchEvent(arg_4_0:nodeByName("btn_sound"), function()
		local var_6_0 = var_0_3.SOUND

		if xyd.db.settings:getBattleSoundOn() == 1 then
			xyd.db.settings:setBattleSound(false)
		else
			xyd.db.settings:setBattleSound(true)
		end

		switchOnShow(var_6_0)
	end)
	xyd.addTouchEvent(arg_4_0:nodeByName("btn_music"), function()
		local var_7_0 = var_0_3.MUSIC

		if xyd.db.settings:getBattleMusicOn() == 1 then
			xyd.db.settings:setBattleMusic(false)
		else
			xyd.db.settings:setBattleMusic(true)
		end

		switchOnShow(var_7_0)
	end)
	arg_4_0:nodeByName("txt_resume"):setString(var_0_2:translation("BATTLE_RESUME"))
	arg_4_0:nodeByName("txt_exit"):setString(var_0_2:translation("BATTLE_EXIT"))
end

function var_0_0.getResumeBtn(arg_8_0)
	if not arg_8_0.resumeBtn_ then
		arg_8_0.resumeBtn_ = arg_8_0:nodeByName("btn_resume")

		xyd.addTouchEvent(arg_8_0.resumeBtn_, function()
			arg_8_0:resumeClick()
		end)
	end

	return arg_8_0.resumeBtn_
end

function var_0_0.getExitBtn(arg_10_0)
	if not arg_10_0.exitBtn_ then
		arg_10_0.exitBtn_ = arg_10_0:nodeByName("btn_exit")

		xyd.addTouchEvent(arg_10_0.exitBtn_, function()
			arg_10_0:exitClick()
		end)
	end

	return arg_10_0.exitBtn_
end

function var_0_0.buttonHandler(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if arg_12_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_12_2)
		arg_12_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_12_1 then
			arg_12_1(arg_12_2, arg_12_3)
		end
	elseif arg_12_3 == ccui.TouchEventType.began then
		local var_12_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_12_1 = cc.RepeatForever:create(var_12_0)

		arg_12_2:runAction(var_12_1)

		return true
	elseif arg_12_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_12_2)
		arg_12_2:setScale(1)
	end
end

function var_0_0.resumeClick(arg_13_0)
	arg_13_0:dispatchEvent({
		name = xyd.event.BATTLE_RESUMED
	})
	xyd.WindowManager.get():closeWindow(xyd.WindowName.battlePausedWnd)
end

function var_0_0.exitClick(arg_14_0)
	arg_14_0:dispatchEvent({
		name = xyd.event.EXIT_BATTLE
	})
	xyd.WindowManager.get():closeWindow(xyd.WindowName.battlePausedWnd)
end

function var_0_0.willClose(arg_15_0, arg_15_1)
	var_0_0.super:willClose(arg_15_1)
	xyd.db.settings:persist()
end

return var_0_0
