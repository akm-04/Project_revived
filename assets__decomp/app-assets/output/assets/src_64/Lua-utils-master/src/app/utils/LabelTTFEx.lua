local var_0_0 = class("LabelTTFEx", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
	local var_2_0 = arg_2_2 or display.DEFAULT_TTF_FONT
	local var_2_1 = arg_2_3 or display.DEFAULT_TTF_FONT_SIZE
	local var_2_2 = arg_2_4 or display.COLOR_WHITE

	arg_2_0.color = var_2_2

	local var_2_3

	if cc.FileUtils:getInstance():isFileExist(var_2_0) then
		var_2_3 = cc.Label:createWithTTF(arg_2_1, var_2_0, var_2_1)

		var_2_3:setColor(var_2_2)
	else
		var_2_3 = cc.Label:createWithSystemFont(arg_2_1, var_2_0, var_2_1)

		var_2_3:setTextColor(var_2_2)
	end

	local var_2_4 = var_2_3:getContentSize()

	var_2_3:pos(var_2_4.width / 2, var_2_4.height / 2):addTo(arg_2_0)

	arg_2_0.label = var_2_3

	arg_2_0:setContentSize(var_2_4)
	arg_2_0:setAnchorPoint(cc.p(0.5, 0.5))
end

function var_0_0.enableUnderLine(arg_3_0)
	if arg_3_0.line then
		return
	end

	local var_3_0 = arg_3_0:getContentSize()
	local var_3_1 = var_3_0.height / 18

	arg_3_0.line = display.newLine({
		{
			0,
			var_3_1 / 2
		},
		{
			var_3_0.width,
			var_3_1 / 2
		}
	}, {
		borderColor = cc.c4f(arg_3_0.color.r / 255, arg_3_0.color.g / 255, arg_3_0.color.b / 255, 1),
		borderWidth = var_3_1
	}):addTo(arg_3_0)

	return arg_3_0
end

function var_0_0.enableItalics(arg_4_0)
	arg_4_0.label:setRotationSkewX(12)

	local var_4_0 = arg_4_0:getContentSize()

	var_4_0.width = var_4_0.width * 1.02

	arg_4_0:setContentSize(var_4_0)

	return arg_4_0
end

function var_0_0.enableBold(arg_5_0)
	arg_5_0.label:enableShadow(cc.c4b(arg_5_0.color.r, arg_5_0.color.g, arg_5_0.color.b, 255), cc.size(0.9, 0), 0)

	return arg_5_0
end

return var_0_0
