local var_0_0 = class("HunqiCombInputNameWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.data = arg_1_2.data
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("HUNQI_TEXT_72"))
	arg_4_0:nodeByName("txt_cancel"):setString(var_0_1:translation("HUNQI_TEXT_73"))
	arg_4_0:nodeByName("txt_sure"):setString(var_0_1:translation("HUNQI_TEXT_74"))
	arg_4_0:initEditBox()
	arg_4_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:close()
		end
	end)
	arg_4_0:nodeByName("btn_sure"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			if not arg_4_0.text or arg_4_0.text == "" then
				local var_6_0 = var_0_1:translation("HUNQI_TEXT_70")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_0
				})

				return
			end

			local var_6_1 = true

			for iter_6_0, iter_6_1 in ipairs(arg_4_0.data) do
				if iter_6_1.name and arg_4_0.text == iter_6_1.name then
					var_6_1 = false

					break
				end
			end

			if not var_6_1 then
				local var_6_2 = var_0_1:translation("HUNQI_TEXT_71")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_2
				})

				return
			end

			arg_4_0.callback(arg_4_0.text)
			arg_4_0:close()
		end
	end)
end

function var_0_0.initEditBox(arg_7_0)
	arg_7_0.textInput = arg_7_0:nodeByName("txt_input")

	arg_7_0.textInput:setString(var_0_1:translation("HUNQI_TEXT_75"))

	local var_7_0 = arg_7_0:nodeByName("bg_input"):getContentSize()
	local var_7_1 = "windows/login/transparent.png"

	arg_7_0.editBox = ccui.EditBox:create(cc.size(var_7_0.width - 16, var_7_0.height - 8), var_7_1)

	arg_7_0:nodeByName("bg_input"):addChild(arg_7_0.editBox)
	arg_7_0.editBox:setAnchorPoint(cc.p(0.5, 0.5))
	arg_7_0.editBox:setNormalizedPosition(cc.p(0.5, 0.5))
	arg_7_0.editBox:registerScriptEditBoxHandler(handler(arg_7_0, arg_7_0.inputContentbox))
	arg_7_0.editBox:setInputFlag(3)
	arg_7_0.editBox:setMaxLength(10)
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

			arg_8_0.textInput:setString(var_0_1:translation("HUNQI_TEXT_75"))
		else
			if xyd.utf8len(var_8_0) > 10 then
				var_8_0 = xyd.utf8str(var_8_0, 1, 10)
			end

			arg_8_0.text = var_8_0

			arg_8_0.textInput:setString(var_8_0)
			arg_8_0.editBox:setText("")
		end
	end
end

return var_0_0
