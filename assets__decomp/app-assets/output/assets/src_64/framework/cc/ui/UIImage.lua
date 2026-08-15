local var_0_0 = class("UIImage", function(arg_1_0, arg_1_1)
	if arg_1_1 and arg_1_1.scale9 then
		return display.newScale9Sprite(arg_1_0, nil, nil, nil, arg_1_1.capInsets)
	else
		return display.newSprite(arg_1_0)
	end
end)

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	makeUIControl_(arg_2_0)
	arg_2_0:align(display.LEFT_BOTTOM)

	local var_2_0 = arg_2_0:getContentSize()

	arg_2_0:getComponent("components.ui.LayoutProtocol"):setLayoutSize(var_2_0.width, var_2_0.height)

	arg_2_0.isScale9_ = arg_2_2 and arg_2_2.scale9

	if arg_2_0.isScale9_ then
		arg_2_0:setLayoutSizePolicy(display.AUTO_SIZE, display.AUTO_SIZE)
	end
end

function var_0_0.setLayoutSize(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0:getComponent("components.ui.LayoutProtocol"):setLayoutSize(arg_3_1, arg_3_2)

	local var_3_0, var_3_1 = arg_3_0:getLayoutSize()
	local var_3_2, var_3_3, var_3_4, var_3_5 = arg_3_0:getLayoutPadding()
	local var_3_6 = var_3_0 - var_3_5 - var_3_3
	local var_3_7 = var_3_1 - var_3_2 - var_3_4

	if arg_3_0.isScale9_ then
		arg_3_0:setContentSize(cc.size(var_3_6, var_3_7))
	else
		local var_3_8 = arg_3_0:getBoundingBox()
		local var_3_9 = var_3_6 / (var_3_8.width / arg_3_0:getScaleX())
		local var_3_10 = var_3_7 / (var_3_8.height / arg_3_0:getScaleY())

		if var_3_9 > 0 and var_3_10 > 0 then
			arg_3_0:setScaleX(var_3_9)
			arg_3_0:setScaleY(var_3_10)
		end
	end

	if arg_3_0.layout_ then
		arg_3_0:setLayout(arg_3_0.layout_)
	end

	return arg_3_0
end

return var_0_0
