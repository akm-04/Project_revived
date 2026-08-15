local var_0_0 = class("UIStretch")

function var_0_0.ctor(arg_1_0)
	cc(arg_1_0):addComponent("components.ui.LayoutProtocol"):exportMethods()
	arg_1_0:setLayoutSizePolicy(display.AUTO_SIZE, display.AUTO_SIZE)

	arg_1_0.position_ = {
		x = 0,
		y = 0
	}
	arg_1_0.anchorPoint_ = display.ANCHOR_POINTS[display.CENTER]
end

function var_0_0.getPosition(arg_2_0)
	return arg_2_0.position_.x, arg_2_0.position_.y
end

function var_0_0.getPositionX(arg_3_0)
	return arg_3_0.position_.x
end

function var_0_0.getPositionY(arg_4_0)
	return arg_4_0.position_.y
end

function var_0_0.setPosition(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0.position_.x, arg_5_0.position_.y = arg_5_1, arg_5_2
end

function var_0_0.setPositionX(arg_6_0, arg_6_1)
	arg_6_0.position_.x = arg_6_1
end

function var_0_0.setPositionY(arg_7_0, arg_7_1)
	arg_7_0.position_.y = arg_7_1
end

function var_0_0.getAnchorPoint(arg_8_0)
	return arg_8_0.anchorPoint_
end

function var_0_0.setAnchorPoint(arg_9_0, arg_9_1)
	arg_9_0.anchorPoint_ = arg_9_1
end

return var_0_0
