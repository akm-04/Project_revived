local var_0_0 = class("IllusionInputHouseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.text = ""
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setButtonClick()
	arg_4_0:initEditBox()
	arg_4_0:nodeByName("text_tips"):setString(var_0_1:translation("ILLUSION_TEAM_TIPS_1"))
	arg_4_0:nodeByName("txt_search"):setString(var_0_1:translation("HERO_LIST_BTN_SEARCH"))
end

function var_0_0.setButtonClick(arg_5_0)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_search"), nil, function()
		xyd.playButtonSound()

		if not arg_5_0:checkStrInvalid(arg_5_0.text) then
			local var_6_0 = var_0_1:translation("ILLUSION_TEAM_TIPS_3")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_6_0
			})

			return
		end

		if arg_5_0.illusion:checkCanJoinRoom(tonumber(arg_5_0.text)) then
			arg_5_0.illusion:enterRoom(tonumber(arg_5_0.text), function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("illusion_prepare")
					xyd.WindowManager.get():closeWindow(arg_5_0)
				end
			end)
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("ILLUSION_TEAM_TIPS_22")
			})
		end
	end)
end

function var_0_0.initEditBox(arg_8_0)
	arg_8_0.textInput = arg_8_0:nodeByName("text_input")

	arg_8_0.textInput:setString("")

	local var_8_0 = arg_8_0:nodeByName("edit"):getContentSize()
	local var_8_1 = "windows/login/transparent.png"

	arg_8_0.editBox = ccui.EditBox:create(var_8_0, var_8_1)

	arg_8_0:nodeByName("edit"):addChild(arg_8_0.editBox)
	arg_8_0.editBox:setAnchorPoint(cc.p(0, 0))
	arg_8_0.editBox:setPosition(0, 0)
	arg_8_0.editBox:registerScriptEditBoxHandler(handler(arg_8_0, arg_8_0.inputContentbox))
	arg_8_0.editBox:setInputFlag(3)
	arg_8_0.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_PAD_NUMBER)
	arg_8_0.editBox:setMaxLength(10)

	if not arg_8_0.text or arg_8_0.text == "" then
		arg_8_0.textInput:setString(var_0_1:translation("ILLUSION_TEAM_TIPS_2"))
		arg_8_0.textInput:setColor(cc.c3b(122, 162, 207))
	else
		arg_8_0.textInput:setString(arg_8_0.text)
		arg_8_0.textInput:setColor(cc.c3b(68, 68, 85))
	end
end

function var_0_0.inputContentbox(arg_9_0, arg_9_1)
	if arg_9_1 == "began" then
		if not arg_9_0.text or arg_9_0.text == "" then
			arg_9_0.textInput:setString("")
		else
			arg_9_0.editBox:setText(arg_9_0.textInput:getString())
		end
	elseif arg_9_1 == "return" then
		local var_9_0 = arg_9_0.editBox:getText()

		if var_9_0 == "" then
			arg_9_0.text = ""

			arg_9_0.textInput:setString(var_0_1:translation("ILLUSION_TEAM_TIPS_2"))
			arg_9_0.textInput:setColor(cc.c3b(122, 162, 207))
		else
			if xyd.utf8len(var_9_0) > 20 then
				var_9_0 = xyd.getTextstr(var_9_0, 1, 20)
			end

			arg_9_0.text = var_9_0

			arg_9_0.textInput:setString(var_9_0)
			arg_9_0.textInput:setColor(cc.c3b(68, 68, 85))
			arg_9_0.editBox:setText("")
			arg_9_0.editBox:setVisible(true)
		end
	end
end

function var_0_0.checkStrInvalid(arg_10_0, arg_10_1)
	if tonumber(arg_10_1) and #arg_10_1 < 10 then
		return true
	end

	return false
end

return var_0_0
