local var_0_0 = class("CommonInputBox", function()
	return display.newNode()
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.bg = arg_2_1.bg
	arg_2_0.width = arg_2_1.width
	arg_2_0.height = arg_2_1.height

	if not arg_2_0.bg or not arg_2_0.width or not arg_2_0.height then
		return
	end

	arg_2_0.fontColor = arg_2_1.fontColor or "#44454D"
	arg_2_0.fontSize = arg_2_1.fontSize or 24
	arg_2_0.holderTxt = arg_2_1.holderTxt or ""
	arg_2_0.holderColor = arg_2_1.holderColor or "#736755"
	arg_2_0.offsetX = arg_2_1.offsetX or -30
	arg_2_0.offsetY = arg_2_1.offsetY or 0
	arg_2_0.callback = arg_2_1.callback
	arg_2_0.defaultTxt = arg_2_1.defaultTxt or ""

	arg_2_0:layout()
	arg_2_0:onRegister()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setContentSize(arg_3_0.width, arg_3_0.height)
	arg_3_0:setAnchorPoint(0.5, 0.5)

	arg_3_0.inputBox = ccui.EditBox:create(arg_3_0:getContentSize(), arg_3_0.bg)

	if not arg_3_0.inputBox then
		return
	end

	arg_3_0.inputBox:addTo(arg_3_0)
	arg_3_0.inputBox:setAnchorPoint(0.5, 0.5)
	arg_3_0.inputBox:setPosition(arg_3_0.width / 2, arg_3_0.height / 2)
	arg_3_0.inputBox:setFont(xyd.AssetLoader.get().FONT_NAME, arg_3_0.fontSize)
	arg_3_0.inputBox:setPlaceholderFont(xyd.AssetLoader.get().FONT_NAME, arg_3_0.fontSize)
	arg_3_0.inputBox:setPlaceHolder(arg_3_0.holderTxt)
	arg_3_0.inputBox:setPlaceholderFontColor(xyd.convertHex2RGB(arg_3_0.holderColor))
	arg_3_0.inputBox:setFontColor(xyd.convertHex2RGB(arg_3_0.fontColor))
	arg_3_0.inputBox:setInputFlag(3)

	arg_3_0.inputLabel = xyd.createAutoFixLabel({
		fontSize = 24,
		txtColor = "#44454D",
		width = arg_3_0.width + arg_3_0.offsetX,
		height = arg_3_0.height + arg_3_0.offsetY,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_CENTER
	})

	arg_3_0.inputLabel:addTo(arg_3_0)
	arg_3_0.inputLabel:setAnchorPoint(0.5, 0.5)
	arg_3_0.inputLabel:setPosition(arg_3_0.width / 2, arg_3_0.height / 2)
	arg_3_0.inputLabel:setString(arg_3_0.defaultTxt)
end

function var_0_0.onRegister(arg_4_0)
	arg_4_0.inputBox:registerScriptEditBoxHandler(function(arg_5_0)
		if arg_5_0 == "began" then
			arg_4_0.inputLabel:setString("")
			arg_4_0.inputBox:setText(arg_4_0.inputLabel:getString())
		elseif arg_5_0 == "return" then
			if arg_4_0.inputBox:getText() == "" then
				arg_4_0.inputLabel:setString(arg_4_0.defaultTxt)
			else
				arg_4_0.inputLabel:setString(arg_4_0.inputBox:getText())
			end

			arg_4_0.inputBox:setText("")
		end

		if arg_4_0.callback then
			arg_4_0.callback(arg_5_0)
		end
	end)
end

function var_0_0.getText(arg_6_0)
	if not arg_6_0.inputLabel or tolua.isnull(arg_6_0.inputLabel) then
		return
	end

	return arg_6_0.inputLabel:getString()
end

return var_0_0
