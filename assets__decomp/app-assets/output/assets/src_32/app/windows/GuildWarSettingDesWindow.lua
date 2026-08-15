local var_0_0 = class("GuildWarSettingDesWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc.guildWarNoticeNum

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.notice = arg_1_2.notice

	arg_1_0:setTouchSwallowEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.notice == "" then
		arg_4_0.notice = var_0_1:translation("GUILD_WAR_NOTICE")
	end

	arg_4_0:nodeByName("title_words"):setString(var_0_1:translation("GUILD_WAR_DES_TITLE"))

	local var_4_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_0, cc.rect(28, 28, 1, 1))

	arg_4_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_4_0:nodeByName("kuang"):getWidth(), arg_4_0:nodeByName("kuang"):getHeight()), var_4_0):align(display.LEFT_BOTTOM, arg_4_0:nodeByName("kuang"):getX(), arg_4_0:nodeByName("kuang"):getY()):addTo(arg_4_0:nodeByName("container"))

	arg_4_0.sidEditbox_:setFontSize(24)
	arg_4_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.sidEditbox_:setInputFlag(3)

	arg_4_0.editY = arg_4_0:nodeByName("kuang"):getY()

	arg_4_0:nodeByName("data_text"):setString(arg_4_0.notice)
	arg_4_0:nodeByName("change_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			params1 = {}
			params1.notice = arg_4_0.notice

			arg_4_0.guild:guildWarSaveNotice(params1, function(arg_6_0)
				if arg_6_0 == xyd.error.OK then
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.REFRESH_GUILD_WAR_DES,
						params = params1.notice
					})

					return true
				end
			end)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_7_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.inputboxEventHandler(arg_8_0, arg_8_1)
	if arg_8_1 == "began" then
		arg_8_0.sidEditbox_:setText(arg_8_0:nodeByName("data_text"):getString())
		arg_8_0:nodeByName("data_text"):setString("")
	end

	if arg_8_1 == "return" then
		local var_8_0 = arg_8_0.sidEditbox_:getText()

		if xyd.getTextLen(var_8_0) <= var_0_2 then
			local var_8_1 = arg_8_0.sidEditbox_:getText()

			arg_8_0:nodeByName("data_text"):setString(var_8_1)

			arg_8_0.notice = var_8_1
		else
			local var_8_2 = string.format(var_0_1:translation("GUILD_WAR_NOTICE_LIMMIT_ALERT"), var_0_2)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_8_2, nil, nil, nil, arg_8_0.colorMode)
		end

		arg_8_0.sidEditbox_:setText("")
		arg_8_0.sidEditbox_:setVisible(true)
		arg_8_0.sidEditbox_:setPositionY(arg_8_0.editY)
	end
end

return var_0_0
