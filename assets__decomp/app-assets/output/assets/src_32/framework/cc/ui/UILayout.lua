local var_0_0 = import(".UIStretch")
local var_0_1 = class("UILayout")
local var_0_2 = 1

function var_0_1.ctor(arg_1_0, arg_1_1)
	cc(arg_1_0):addComponent("components.ui.LayoutProtocol"):exportMethods()
	arg_1_0:setLayoutSizePolicy(display.AUTO_SIZE, display.AUTO_SIZE)

	if not arg_1_1 then
		arg_1_1 = string.format("layout-%d", var_0_2)
		var_0_2 = var_0_2 + 1
	end

	arg_1_0.name_ = arg_1_1
	arg_1_0.position_ = {
		x = 0,
		y = 0
	}
	arg_1_0.anchorPoint_ = display.ANCHOR_POINTS[display.CENTER]
	arg_1_0.order_ = 0
	arg_1_0.widgets_ = {}

	local var_1_0 = {
		__mode = "k"
	}

	setmetatable(arg_1_0.widgets_, var_1_0)

	arg_1_0.persistent_ = {}
end

function var_0_1.getName(arg_2_0)
	return arg_2_0.name_
end

function var_0_1.addLayout(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0:addWidget(arg_3_1, arg_3_2)

	arg_3_0.persistent_[#arg_3_0.persistent_ + 1] = arg_3_1

	return arg_3_0
end

function var_0_1.addWidget(arg_4_0, arg_4_1, arg_4_2)
	arg_4_0.order_ = arg_4_0.order_ + 1
	arg_4_0.widgets_[arg_4_1] = {
		weight = arg_4_2 or 1,
		order = arg_4_0.order_
	}

	return arg_4_0
end

function var_0_1.removeWidget(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.widgets_) do
		if iter_5_0 == arg_5_1 then
			arg_5_0.widgets_[iter_5_0] = nil

			break
		end
	end

	return arg_5_0
end

function var_0_1.addStretch(arg_6_0, arg_6_1)
	local var_6_0 = var_0_0.new()

	arg_6_0:addWidget(var_6_0, arg_6_1)

	arg_6_0.persistent_[#arg_6_0.persistent_ + 1] = var_6_0

	return arg_6_0
end

function var_0_1.getPosition(arg_7_0)
	return arg_7_0.position_.x, arg_7_0.position_.y
end

function var_0_1.getPositionX(arg_8_0)
	return arg_8_0.position_.x
end

function var_0_1.getPositionY(arg_9_0)
	return arg_9_0.position_.y
end

function var_0_1.setPosition(arg_10_0, arg_10_1, arg_10_2)
	arg_10_0.position_.x, arg_10_0.position_.y = arg_10_1, arg_10_2
end

function var_0_1.setPositionX(arg_11_0, arg_11_1)
	arg_11_0.position_.x = arg_11_1
end

function var_0_1.setPositionY(arg_12_0, arg_12_1)
	arg_12_0.position_.y = arg_12_1
end

function var_0_1.getAnchorPoint(arg_13_0)
	return arg_13_0.anchorPoint_
end

function var_0_1.setAnchorPoint(arg_14_0, arg_14_1)
	arg_14_0.anchorPoint_ = arg_14_1
end

function var_0_1.apply(arg_15_0, arg_15_1)
	return
end

return var_0_1
