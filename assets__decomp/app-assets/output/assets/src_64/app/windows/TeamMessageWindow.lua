local var_0_0 = class("TeamMessageWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc.teamMailTitleLimit
local var_0_5 = xyd.tables.misc.teamMailBodyLimit
local var_0_6 = var_0_3:translation("TEAM_MESSAGE_DEFAULT_TITLE")
local var_0_7 = var_0_3:translation("TEAM_MESSAGE_DEFAULT_CONTENT")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)

	arg_1_0:setTouchSwallowEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("cancel_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.layout(arg_5_0)
	arg_5_0.is_message_once = false
	arg_5_0.is_title_once = false

	arg_5_0:nodeByName("to_name_text"):setString(var_0_3:translation("GUILD_ALL_MEMBERS"))
	arg_5_0:nodeByName("send_to_text"):setString(var_0_3:translation("SEND_TO"))
	arg_5_0:nodeByName("title"):setString(var_0_3:translation("SHE_TUAN_TEXT_21"))
	arg_5_0:nodeByName("text_cancel"):setString(var_0_3:translation("SHE_TUAN_TEXT_16"))
	arg_5_0:nodeByName("text_ok"):setString(var_0_3:translation("SHE_TUAN_TEXT_15"))

	local var_5_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_5_0, cc.rect(28, 28, 1, 1))

	arg_5_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_5_0:nodeByName("title_container"):getWidth(), arg_5_0:nodeByName("title_container"):getHeight()), var_5_0):align(display.LEFT_BOTTOM, arg_5_0:nodeByName("title_container"):getX(), arg_5_0:nodeByName("title_container"):getY()):addTo(arg_5_0:nodeByName("container"))

	arg_5_0:nodeByName("title_text"):setString(var_0_6)

	arg_5_0.messageTitle = ""

	arg_5_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_5_0, arg_5_0.inputTitleEventHandler))
	arg_5_0.sidEditbox_:setInputFlag(3)

	arg_5_0.sidEditMessage_ = ccui.EditBox:create(cc.size(arg_5_0:nodeByName("message_container"):getWidth(), arg_5_0:nodeByName("message_container"):getHeight()), var_5_0):align(display.LEFT_BOTTOM, arg_5_0:nodeByName("message_container"):getX(), arg_5_0:nodeByName("message_container"):getY()):addTo(arg_5_0:nodeByName("container"))

	arg_5_0:nodeByName("neirong_text"):setString(var_0_7)

	arg_5_0.messageMessage = ""

	arg_5_0.sidEditMessage_:registerScriptEditBoxHandler(handler(arg_5_0, arg_5_0.inputMessageEventHandler))
	arg_5_0.sidEditMessage_:setInputFlag(3)
	arg_5_0.sidEditMessage_:setMaxLength(var_0_5 * 3 + 3)

	arg_5_0.defaultColor = arg_5_0:nodeByName("title_text"):getColor()

	local var_5_1 = var_0_2.new({
		size = 694
	})

	var_5_1:addTo(arg_5_0:nodeByName("line"))
	var_5_1:setAnchorPoint(0, 0.5)
	arg_5_0:nodeByName("right_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("right_btn"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_5_0.messageTitle == nil or arg_5_0.messageTitle == "" then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_MESSAGE_TITLE_EMPTY"), nil, nil, nil, arg_5_0.colorMode)
			elseif arg_5_0.messageMessage == nil or arg_5_0.messageMessage == "" then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("TEAM_MESSAGE_MESSAGE_EMPTY"), nil, nil, nil, arg_5_0.colorMode)
			else
				local var_6_0 = {
					title = arg_5_0.messageTitle,
					content = arg_5_0.messageMessage
				}

				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):sendMessage(var_6_0, function(arg_7_0)
					if arg_7_0 == xyd.error.OK then
						local var_7_0 = var_0_3:translation("SEND_OK")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_7_0
						})
						xyd.WindowManager.get():closeWindow(arg_5_0)

						return true
					end
				end)
			end
		end
	end)
end

function var_0_0.inputMessageEventHandler(arg_8_0, arg_8_1)
	if arg_8_1 == "began" then
		if arg_8_0.is_message_once == false then
			arg_8_0.sidEditMessage_:setText("")
		else
			local var_8_0 = arg_8_0.filterWord:warningStrGsub(arg_8_0:nodeByName("neirong_text"):getString())

			arg_8_0.sidEditMessage_:setText(var_8_0)
		end
	end

	if arg_8_1 == "return" then
		local var_8_1 = arg_8_0.filterWord:warningStrGsub(arg_8_0.sidEditMessage_:getText())
		local var_8_2 = xyd.getTextLen(var_8_1)

		if var_8_1 == "" then
			arg_8_0.is_message_once = false

			arg_8_0:nodeByName("neirong_text"):setString(var_0_7)
			arg_8_0:nodeByName("neirong_text"):setColor(arg_8_0.defaultColor)

			arg_8_0.messageMessage = ""
		elseif var_8_1 ~= nil and var_8_2 <= var_0_5 then
			arg_8_0:nodeByName("neirong_text"):setColor(cc.c4b(90, 90, 90, 255))

			arg_8_0.messageMessage = var_8_1

			arg_8_0:nodeByName("neirong_text"):setString(arg_8_0.messageMessage)

			arg_8_0.is_message_once = true
		else
			arg_8_0:nodeByName("neirong_text"):setColor(cc.c4b(90, 90, 90, 255))

			local var_8_3 = string.format(var_0_3:translation("TEAM_MESSAGE_MESSAGE_LIMMIT"), var_0_5)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_8_3, nil, nil, nil, arg_8_0.colorMode)

			arg_8_0.messageMessage = xyd.getTextstr(var_8_1, 0, var_0_5)

			arg_8_0:nodeByName("neirong_text"):setString(arg_8_0.messageMessage)

			arg_8_0.is_message_once = true
		end

		arg_8_0.sidEditMessage_:setText("")
		arg_8_0.sidEditMessage_:setVisible(true)
	end
end

function var_0_0.inputTitleEventHandler(arg_9_0, arg_9_1)
	if arg_9_1 == "began" then
		if arg_9_0.is_title_once == false then
			arg_9_0.sidEditbox_:setText("")
		else
			local var_9_0 = arg_9_0.filterWord:warningStrGsub(arg_9_0:nodeByName("title_text"):getString())

			arg_9_0.sidEditbox_:setText(var_9_0)
		end
	end

	if arg_9_1 == "return" then
		local var_9_1 = arg_9_0.filterWord:warningStrGsub(arg_9_0.sidEditbox_:getText())
		local var_9_2 = xyd.getTextLen(var_9_1)

		if var_9_1 == "" then
			arg_9_0.is_title_once = false

			arg_9_0:nodeByName("title_text"):setString(var_0_6)
			arg_9_0:nodeByName("title_text"):setColor(arg_9_0.defaultColor)

			arg_9_0.messageTitle = ""
		elseif var_9_1 ~= nil and var_9_2 <= var_0_4 then
			arg_9_0:nodeByName("title_text"):setColor(cc.c4b(90, 90, 90, 255))

			arg_9_0.messageTitle = var_9_1

			arg_9_0:nodeByName("title_text"):setString(arg_9_0.messageTitle)

			arg_9_0.is_title_once = true
		else
			arg_9_0:nodeByName("title_text"):setColor(cc.c4b(90, 90, 90, 255))

			local var_9_3 = string.format(var_0_3:translation("TEAM_MESSAGE_TITLE_LIMMIT"), var_0_4)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_9_3, nil, nil, nil, arg_9_0.colorMode)

			arg_9_0.messageTitle = xyd.getTextstr(var_9_1, 0, var_0_4)

			arg_9_0:nodeByName("title_text"):setString(arg_9_0.messageTitle)

			arg_9_0.is_title_once = true
		end

		arg_9_0.sidEditbox_:setText("")
		arg_9_0.sidEditbox_:setVisible(true)
	end
end

return var_0_0
