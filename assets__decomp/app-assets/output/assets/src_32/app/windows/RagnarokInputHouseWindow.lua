local var_0_0 = class("RagnarokInputHouseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_1_0.text = ""
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
	arg_3_0:initEditBox()
	arg_3_0:nodeByName("text_tips"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_1"))
	arg_3_0:nodeByName("txt_search"):setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_2"))
end

function var_0_0.setButtonClick(arg_4_0)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_search"), nil, function()
		xyd.playButtonSound()

		if not arg_4_0:checkStrInvalid(arg_4_0.text) then
			local var_5_0 = var_0_1:translation("RAGNAROK_BOSS_TEAM_3")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_5_0
			})

			return
		end

		if arg_4_0.ragnarok:checkCanJoinRoom(tonumber(arg_4_0.text)) then
			arg_4_0.ragnarok:enterRoom(tonumber(arg_4_0.text), 0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("ragnarok_prepare")
					xyd.WindowManager.get():closeWindow(arg_4_0)
				else
					local var_6_0 = var_0_1:translation("RAGNAROK_BOSS_TEAM_4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_0
					})
				end
			end)
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("RAGNAROK_BOSS_TEAM_5")
			})
		end
	end)
end

function var_0_0.initEditBox(arg_7_0)
	arg_7_0.textInput = arg_7_0:nodeByName("text_input")

	arg_7_0.textInput:setString("")

	local var_7_0 = arg_7_0:nodeByName("edit"):getContentSize()
	local var_7_1 = "windows/login/transparent.png"

	arg_7_0.editBox = ccui.EditBox:create(var_7_0, var_7_1)

	arg_7_0:nodeByName("edit"):addChild(arg_7_0.editBox)
	arg_7_0.editBox:setAnchorPoint(cc.p(0, 0))
	arg_7_0.editBox:setPosition(0, 0)
	arg_7_0.editBox:registerScriptEditBoxHandler(handler(arg_7_0, arg_7_0.inputContentbox))
	arg_7_0.editBox:setInputFlag(3)
	arg_7_0.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_PAD_NUMBER)
	arg_7_0.editBox:setMaxLength(10)

	if not arg_7_0.text or arg_7_0.text == "" then
		arg_7_0.textInput:setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_6"))
		arg_7_0.textInput:setColor(cc.c3b(170, 122, 207))
	else
		arg_7_0.textInput:setString(arg_7_0.text)
		arg_7_0.textInput:setColor(cc.c3b(68, 68, 85))
	end
end

function var_0_0.inputContentbox(arg_8_0, arg_8_1)
	if arg_8_1 == "began" then
		if not arg_8_0.text or arg_8_0.text == "" then
			arg_8_0.textInput:setString("")
		else
			arg_8_0.editBox:setText(arg_8_0.textInput:getString())
		end
	elseif arg_8_1 == "return" then
		local var_8_0 = arg_8_0.editBox:getText()

		if var_8_0 == "" then
			arg_8_0.text = ""

			arg_8_0.textInput:setString(var_0_1:translation("RAGNAROK_BOSS_TEAM_6"))
			arg_8_0.textInput:setColor(cc.c3b(170, 122, 207))
		else
			if xyd.utf8len(var_8_0) > 20 then
				var_8_0 = xyd.getTextstr(var_8_0, 1, 20)
			end

			arg_8_0.text = var_8_0

			arg_8_0.textInput:setString(var_8_0)
			arg_8_0.textInput:setColor(cc.c3b(68, 68, 85))
			arg_8_0.editBox:setText("")
		end
	end
end

function var_0_0.checkStrInvalid(arg_9_0, arg_9_1)
	if tonumber(arg_9_1) and #arg_9_1 < 10 then
		return true
	end

	return false
end

return var_0_0
