local var_0_0 = import(".UIBoxLayout")
local var_0_1 = import(".UIImage")
local var_0_2 = class("UIGroup", function()
	return display.newNode()
end)

function var_0_2.ctor(arg_2_0)
	makeUIControl_(arg_2_0)
	arg_2_0:setLayout(var_0_0.new(display.LEFT_TO_RIGHT))
	arg_2_0:setLayoutSizePolicy(display.AUTO_SIZE, display.AUTO_SIZE)
	arg_2_0:align(display.LEFT_BOTTOM)
end

function var_0_2.addWidget(arg_3_0, arg_3_1)
	arg_3_0:addChild(arg_3_1)
	arg_3_0:getLayout():addWidget(arg_3_1)

	return arg_3_0
end

function var_0_2.onTouch(arg_4_0, arg_4_1)
	arg_4_1 = arg_4_1 or function()
		return true
	end

	if USE_DEPRECATED_EVENT_ARGUMENTS then
		arg_4_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			return arg_4_1(arg_6_0.name, arg_6_0.x, arg_6_0.y, arg_6_0.prevX, arg_6_0.prevY)
		end)
	else
		arg_4_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, arg_4_1)
	end

	return arg_4_0
end

function var_0_2.enableTouch(arg_7_0, arg_7_1)
	arg_7_0:setTouchEnabled(arg_7_1)

	return arg_7_0
end

function var_0_2.setLayoutSize(arg_8_0, arg_8_1, arg_8_2)
	arg_8_0:getComponent("components.ui.LayoutProtocol"):setLayoutSize(arg_8_1, arg_8_2)

	if arg_8_0.backgroundSprite_ then
		arg_8_0.backgroundSprite_:setLayoutSize(arg_8_0:getLayoutSize())
	end

	return arg_8_0
end

function var_0_2.setBackgroundImage(arg_9_0, arg_9_1, arg_9_2)
	arg_9_0.backgroundSprite_ = var_0_1.new(arg_9_1, arg_9_2):setLayoutSize(arg_9_0:getLayoutSize())

	arg_9_0:addChild(arg_9_0.backgroundSprite_)

	return arg_9_0
end

return var_0_2
