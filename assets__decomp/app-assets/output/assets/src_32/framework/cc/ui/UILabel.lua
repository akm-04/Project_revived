local var_0_0

var_0_0 = class("UILabel", function(arg_1_0)
	if not arg_1_0 then
		return
	end

	if arg_1_0.UILabelType == 1 then
		return var_0_0.newBMFontLabel_(arg_1_0)
	elseif not arg_1_0.UILabelType or arg_1_0.UILabelType == 2 then
		return var_0_0.newTTFLabel_(arg_1_0)
	else
		printInfo("UILabel unkonw UILabelType")
	end
end)
var_0_0.LABEL_TYPE_BM = 1
var_0_0.LABEL_TYPE_TTF = 2

function var_0_0.ctor(arg_2_0, arg_2_1)
	makeUIControl_(arg_2_0)
	arg_2_0:setLayoutSizePolicy(display.FIXED_SIZE, display.FIXED_SIZE)
	arg_2_0:align(display.LEFT_CENTER)
end

function var_0_0.setLayoutSize(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0:getComponent("components.ui.LayoutProtocol"):setLayoutSize(arg_3_1, arg_3_2)

	return arg_3_0
end

function var_0_0.newBMFontLabel_(arg_4_0)
	return display.newBMFontLabel(arg_4_0)
end

function var_0_0.newTTFLabel_(arg_5_0)
	return display.newTTFLabel(arg_5_0)
end

return var_0_0
