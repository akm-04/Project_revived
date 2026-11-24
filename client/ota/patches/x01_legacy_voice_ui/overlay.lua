-- x01 experimental: a "2018 voice" switch in Settings, cloned from the existing auto-standby switch.
--
-- The window's csb (windows/person_display/playerwindow/switchitem.csb, decoded 2026-11-23) lays its buttons in two
-- columns: voice 278, music 277, auto-standby 200, redeem 200, live2d 125, privacy 124, switch 124, then the message
-- block at -21. layout() hides live2d, so one row is free at y ~= 125; this overlay puts the clone in the free spot
-- below it (GXB_LEGACY_TOGGLE_Y) to avoid disturbing the stock placement.
--
-- State lives in cc.UserDefault ("gxb_legacy_voice"), which the voice overlays read. Tuning: change
-- GXB_LEGACY_TOGGLE_Y (row height) or GXB_LEGACY_TOGGLE_LABEL.

local GXB_LEGACY_VOICE_KEY = "gxb_legacy_voice"
local GXB_LEGACY_TOGGLE_Y = 60
local GXB_LEGACY_TOGGLE_ON = "2018 VOICE ON"
local GXB_LEGACY_TOGGLE_OFF = "2018 VOICE OFF"

local function gxbLegacyToggleState()
	return cc.UserDefault:getInstance():getBoolForKey(GXB_LEGACY_VOICE_KEY, false)
end

local function gxbLegacyToggleTexts(button, enabled)
	local onLabel = button:getChildByName("gxb_legacy_on")
	local offLabel = button:getChildByName("gxb_legacy_off")
	if onLabel then
		onLabel:setVisible(enabled)
	end
	if offLabel then
		offLabel:setVisible(not enabled)
	end
end

local gxbSwitchLayout = var_0_0.layout

function var_0_0.layout(gxbSwitchSelf)
	local switchX, switchY = gxbSwitchSelf.switchBtn:getPosition()
	gxbSwitchLayout(gxbSwitchSelf)

	if gxbSwitchSelf.gxbLegacyButton then
		gxbLegacyToggleTexts(gxbSwitchSelf.gxbLegacyButton, gxbLegacyToggleState())
		return
	end

	local template = gxbSwitchSelf.autoStandbyBtn
	if not template then
		return
	end

	local button = template:clone()
	button:setName("gxb_btn_legacy_voice")
	button:setVisible(true)
	button:setPosition(switchX, GXB_LEGACY_TOGGLE_Y)
	template:getParent():addChild(button)

	for _, name in ipairs({ "txt_standby_open", "txt_standby_close" }) do
		local label = button:getChildByName(name)
		if label then
			local isOn = name == "txt_standby_open"
			label:setString(isOn and GXB_LEGACY_TOGGLE_ON or GXB_LEGACY_TOGGLE_OFF)
			label:setVisible(true)
			label:setName(isOn and "gxb_legacy_on" or "gxb_legacy_off")
		end
	end

	button:addTouchEventListener(function(gxbLegacyTouch, gxbLegacyEvent)
		if gxbLegacyEvent == ccui.TouchEventType.began then
			button:setScale(0.9)
			return true
		end
		if gxbLegacyEvent == ccui.TouchEventType.canceled then
			button:setScale(1)
			return
		end
		if gxbLegacyEvent ~= ccui.TouchEventType.ended then
			return
		end
		button:setScale(1)
		local nextState = not gxbLegacyToggleState()
		cc.UserDefault:getInstance():setBoolForKey(GXB_LEGACY_VOICE_KEY, nextState)
		cc.UserDefault:getInstance():flush()
		gxbLegacyToggleTexts(button, nextState)

		if nextState and xyd.gxbLegacyVoiceWarm then
			xyd.gxbLegacyVoiceWarm()
		end

		audio.playSound("sound/button.ogg", false)
	end)

	gxbSwitchSelf.gxbLegacyButton = button
	gxbLegacyToggleTexts(button, gxbLegacyToggleState())
end
