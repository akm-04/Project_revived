local var_0_0

var_0_0 = class("UIInput", function(arg_1_0)
	local var_1_0

	if not arg_1_0 or not arg_1_0.UIInputType or arg_1_0.UIInputType == 1 then
		var_1_0 = var_0_0.newEditBox_(arg_1_0)
		var_1_0.UIInputType = 1
	elseif arg_1_0.UIInputType == 2 then
		var_1_0 = var_0_0.newTextField_(arg_1_0)
		var_1_0.UIInputType = 2
	end

	return var_1_0
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	if arg_2_1.UIInputType == 2 then
		arg_2_0.getText = arg_2_0.getStringValue
	end
end

function var_0_0.newEditBox_(arg_3_0)
	local var_3_0 = arg_3_0.image
	local var_3_1 = arg_3_0.imagePressed
	local var_3_2 = arg_3_0.imageDisabled

	if type(var_3_0) == "string" then
		var_3_0 = display.newScale9Sprite(var_3_0)
	end

	if type(var_3_1) == "string" then
		var_3_1 = display.newScale9Sprite(var_3_1)
	end

	if type(var_3_2) == "string" then
		var_3_2 = display.newScale9Sprite(var_3_2)
	end

	local var_3_3

	if cc.bPlugin_ then
		var_3_3 = ccui.EditBox
	else
		var_3_3 = cc.EditBox
	end

	local var_3_4 = var_3_3:create(arg_3_0.size, var_3_0, var_3_1, var_3_2)

	if var_3_4 then
		if arg_3_0.listener then
			var_3_4:registerScriptEditBoxHandler(arg_3_0.listener)
		end

		if arg_3_0.x and arg_3_0.y then
			var_3_4:setPosition(arg_3_0.x, arg_3_0.y)
		end
	end

	return var_3_4
end

function var_0_0.newTextField_(arg_4_0)
	local var_4_0

	if cc.bPlugin_ then
		var_4_0 = ccui.TextField
	else
		var_4_0 = cc.TextField
	end

	local var_4_1 = var_4_0:create()

	var_4_1:setPlaceHolder(arg_4_0.placeHolder)
	var_4_1:setPosition(arg_4_0.x, arg_4_0.y)

	if arg_4_0.listener then
		var_4_1:addEventListener(arg_4_0.listener)
	end

	if arg_4_0.size then
		var_4_1:setTextAreaSize(arg_4_0.size)
	end

	if arg_4_0.text then
		if var_4_1.setString then
			var_4_1:setString(arg_4_0.text)
		else
			var_4_1:setText(arg_4_0.text)
		end
	end

	if arg_4_0.font then
		var_4_1:setFontName(arg_4_0.font)
	end

	if arg_4_0.fontSize then
		var_4_1:setFontSize(arg_4_0.fontSize)
	end

	if arg_4_0.maxLength and arg_4_0.maxLength ~= 0 then
		var_4_1:setMaxLengthEnabled(true)
		var_4_1:setMaxLength(arg_4_0.maxLength)
	end

	if arg_4_0.passwordEnable then
		var_4_1:setPasswordEnabled(true)
	end

	if arg_4_0.passwordChar then
		var_4_1:setPasswordStyleText(arg_4_0.passwordChar)
	end

	return var_4_1
end

return var_0_0
