local var_0_0 = class("SwitchItem", function()
	return cc.Node:create()
end)

var_0_0.VOICE_SWITCH = "btn_voice_switch"
var_0_0.MUSIC_SWITCH = "btn_music_switch"
var_0_0.CODE_SWITCH = "btn_redeem_code"
var_0_0.SWITCH_SWITCH = "btn_switch"
var_0_0.VOICE_SWITCH_TXT = "voice_switch_txt"
var_0_0.MUSIC_SWITCH_TXT = "music_switch_txt"
var_0_0.VOICE_ON_IMG = "voice_on_img"
var_0_0.MUSIC_ON_IMG = "music_on_img"
var_0_0.VOICE_OFF_IMG = "voice_off_img"
var_0_0.MUSIC_OFF_IMG = "music_off_img"

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.voiceSwitch = arg_3_1.voiceSwitch
	arg_3_0.musicSwitch = arg_3_1.musicSwitch
	arg_3_0.dialogSwitch = arg_3_1.dialogSwitch
	arg_3_0.standbySwitch = arg_3_1.standbySwitch
	arg_3_0.live2dSwitch = arg_3_1.live2dSwitch
	arg_3_0.soundBtn = arg_3_0.contentView_:nodeByName("btn_voice_switch")
	arg_3_0.musicBtn = arg_3_0.contentView_:nodeByName("btn_music_switch")
	arg_3_0.switchBtn = arg_3_0.contentView_:nodeByName("btn_switch")
	arg_3_0.codeBtn = arg_3_0.contentView_:nodeByName("btn_redeem_code")
	arg_3_0.autoStandbyBtn = arg_3_0.contentView_:nodeByName("btn_auto_standby")
	arg_3_0.live2dBtn = arg_3_0.contentView_:nodeByName("btn_live2d")
	arg_3_0.privacyBtn = arg_3_0.contentView_:nodeByName("btn_privacy")

	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.setCodeVisible(arg_4_0, arg_4_1)
	arg_4_0.codeBtn:setVisible(arg_4_1)
	arg_4_0.contentView_:nodeByName("txt_code"):setVisible(arg_4_1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	local var_5_0, var_5_1 = arg_5_0.live2dBtn:getPosition()

	arg_5_0.live2dBtn:setVisible(false)
	arg_5_0.switchBtn:setPosition(var_5_0, var_5_1)

	local var_5_2 = xyd.tables.translation

	arg_5_0:updateSwitchState()
	arg_5_0.switchBtn:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_5_0.switchBtn:setScale(0.9)
		end

		if arg_6_1 == ccui.TouchEventType.ended then
			arg_5_0.switchBtn:setScale(1)
			audio.stopAllSounds()
			audio.stopMusic()
			xyd.EventDispatcher.get():removeAllEventListeners()
			xyd.Backend.get():closeLeagueRoom()
			xyd.Backend.get():closeServiceRoom()
			xyd.Backend.get():closeChatRoom()
			xyd.StoryData.get():reset()
			xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER):clear()
			xyd.ModelManager.get():reset()
			xyd.ServerTime.get():reset()
			cc.Director:getInstance():replaceScene(xyd.LoadingScene.new())
		end
	end)
	arg_5_0.soundBtn:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_5_0.soundBtn:setScale(0.9)
		end

		if arg_7_1 == ccui.TouchEventType.ended then
			arg_5_0.soundBtn:setScale(1)

			if arg_5_0.voiceSwitch == 1 then
				audio.getSoundsVolume(1)
				audio.playSound("sound/button.ogg", false)
				xyd.db.settings:setSoundEffect(false)

				arg_5_0.voiceSwitch = 0
			else
				xyd.db.settings:setSoundEffect(true)
				audio.getSoundsVolume(1)
				audio.playSound("sound/button.ogg", false)

				arg_5_0.voiceSwitch = 1
			end

			arg_5_0:updateSwitchState()
			xyd.db.settings:persist()
		end
	end)
	arg_5_0.musicBtn:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_5_0.musicBtn:setScale(0.9)
		end

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_5_0.musicBtn:setScale(1)
			audio.getSoundsVolume(1)
			audio.playSound("sound/button.ogg", false)

			arg_5_0.musicSwitch = 1 - arg_5_0.musicSwitch

			arg_5_0.selfPlayer:setNatureVolume(arg_5_0.musicSwitch)
			arg_5_0:updateSwitchState()
			xyd.db.settings:persist()
		end
	end)
	arg_5_0.codeBtn:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_5_0.codeBtn:setScale(0.9)
		end

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_5_0.codeBtn:setScale(1)

			if arg_5_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_COUPON_CODE) ~= true then
				local var_9_0 = xyd.tables.functionOpen
				local var_9_1 = xyd.tables.translation
				local var_9_2 = string.format(var_9_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_9_0:level(xyd.FunctionID.ID_COUPON_CODE))

				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_2
				})

				return true
			end

			xyd.WindowManager.get():openWindow("exchange_code")
		end
	end)
	arg_5_0.autoStandbyBtn:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_5_0.autoStandbyBtn:setScale(0.9)
		end

		if arg_10_1 == ccui.TouchEventType.ended then
			arg_5_0.autoStandbyBtn:setScale(1)
			audio.getSoundsVolume(1)
			audio.playSound("sound/button.ogg", false)

			if arg_5_0.standbySwitch == 1 then
				xyd.db.settings:setAutoStandby(false)

				arg_5_0.standbySwitch = 0
			else
				xyd.db.settings:setAutoStandby(true)

				arg_5_0.standbySwitch = 1
			end

			arg_5_0:updateSwitchState()
			xyd.db.settings:persist()
		end
	end)
	arg_5_0.live2dBtn:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			arg_5_0.live2dBtn:setScale(0.9)
		end

		if arg_11_1 == ccui.TouchEventType.ended then
			arg_5_0.live2dBtn:setScale(1)
			audio.getSoundsVolume(1)
			audio.playSound("sound/button.ogg", false)

			if arg_5_0.live2dSwitch == 1 then
				xyd.db.settings:setLive2dOn(false)

				arg_5_0.live2dSwitch = 0
			else
				xyd.db.settings:setLive2dOn(true)

				arg_5_0.live2dSwitch = 1
			end

			arg_5_0:updateSwitchState()
			xyd.db.settings:persist()
		end
	end)
	arg_5_0.privacyBtn:addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.began then
			arg_5_0.privacyBtn:setScale(0.9)
		end

		if arg_12_1 == ccui.TouchEventType.ended then
			arg_5_0.privacyBtn:setScale(1)

			local var_12_0 = xyd.tables.misc:getValue("private_policy")

			cc.Application:getInstance():openURL(var_12_0)
		end
	end)
end

function var_0_0.updateSwitchState(arg_13_0)
	if arg_13_0.voiceSwitch == 1 then
		arg_13_0.contentView_:nodeByName("icon_voice_open"):setVisible(true)
		arg_13_0.contentView_:nodeByName("icon_voice_close"):setVisible(false)
		arg_13_0.contentView_:nodeByName("txt_voice_open"):setVisible(true)
		arg_13_0.contentView_:nodeByName("txt_voice_close"):setVisible(false)
	else
		arg_13_0.contentView_:nodeByName("icon_voice_open"):setVisible(false)
		arg_13_0.contentView_:nodeByName("icon_voice_close"):setVisible(true)
		arg_13_0.contentView_:nodeByName("txt_voice_open"):setVisible(false)
		arg_13_0.contentView_:nodeByName("txt_voice_close"):setVisible(true)
	end

	if arg_13_0.musicSwitch == 1 then
		arg_13_0.contentView_:nodeByName("icon_music_open"):setVisible(true)
		arg_13_0.contentView_:nodeByName("icon_music_close"):setVisible(false)
		arg_13_0.contentView_:nodeByName("txt_music_open"):setVisible(true)
		arg_13_0.contentView_:nodeByName("txt_music_close"):setVisible(false)
	else
		arg_13_0.contentView_:nodeByName("icon_music_open"):setVisible(false)
		arg_13_0.contentView_:nodeByName("icon_music_close"):setVisible(true)
		arg_13_0.contentView_:nodeByName("txt_music_open"):setVisible(false)
		arg_13_0.contentView_:nodeByName("txt_music_close"):setVisible(true)
	end

	local var_13_0 = arg_13_0.standbySwitch == 1 and true or false

	arg_13_0.contentView_:nodeByName("txt_standby_open"):setVisible(var_13_0)
	arg_13_0.contentView_:nodeByName("txt_standby_close"):setVisible(not var_13_0)

	local var_13_1 = arg_13_0.live2dSwitch == 1

	arg_13_0.contentView_:nodeByName("txt_lived_open"):setVisible(var_13_1)
	arg_13_0.contentView_:nodeByName("txt_lived_close"):setVisible(not var_13_1)
end

function var_0_0.contentView(arg_14_0)
	if arg_14_0.contentView_ == nil then
		arg_14_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_14_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/playerwindow/switchitem.csb"))
		arg_14_0.contentView_:addTo(arg_14_0)
		arg_14_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_14_0.contentView_
end

return var_0_0
