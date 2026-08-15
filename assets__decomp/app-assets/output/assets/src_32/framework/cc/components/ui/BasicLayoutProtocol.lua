local var_0_0 = cc.Component
local var_0_1 = class("BasicLayoutProtocol", var_0_0)
local var_0_2 = 999999

function var_0_1.ctor(arg_1_0)
	var_0_1.super.ctor(arg_1_0, "BasicLayoutProtocol")
end

function var_0_1.getLayoutSize(arg_2_0)
	if arg_2_0.layoutSize_ then
		return arg_2_0.layoutSize_.width, arg_2_0.layoutSize_.height
	elseif arg_2_0.target_.getCascadeBoundingBox then
		local var_2_0 = arg_2_0.target_:getCascadeBoundingBox().size

		return var_2_0.width, var_2_0.height
	else
		return 0, 0
	end
end

function var_0_1.setLayoutSize(arg_3_0, arg_3_1, arg_3_2)
	if arg_3_1 == 0 and arg_3_2 == 0 then
		arg_3_0.layoutSize_ = nil
	else
		arg_3_0.layoutSize_ = {
			width = checknumber(arg_3_1),
			height = checknumber(arg_3_2)
		}
	end

	return arg_3_0.target_
end

function var_0_1.getLayoutMinSize(arg_4_0)
	return arg_4_0.minSize_.width, arg_4_0.minSize_.height
end

function var_0_1.setLayoutMinSize(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0.minSize_.width = checknumber(arg_5_1)
	arg_5_0.minSize_.height = checknumber(arg_5_2)

	return arg_5_0.target_
end

function var_0_1.getLayoutMaxSize(arg_6_0)
	return arg_6_0.maxSize_.width, arg_6_0.maxSize_.height
end

function var_0_1.setLayoutMaxSize(arg_7_0, arg_7_1, arg_7_2)
	arg_7_0.maxSize_.width = checknumber(arg_7_1)
	arg_7_0.maxSize_.height = checknumber(arg_7_2)

	return arg_7_0.target_
end

function var_0_1.getLayoutSizePolicy(arg_8_0)
	return arg_8_0.sizePolicy_.horizontal, arg_8_0.sizePolicy_.vertical
end

local function var_0_3(arg_9_0)
	if arg_9_0 ~= display.AUTO_SIZE and arg_9_0 ~= display.FIXED_SIZE then
		printError("BasicLayoutProtocol - invalid size policy")

		return display.AUTO_SIZE
	else
		return arg_9_0
	end
end

function var_0_1.setLayoutSizePolicy(arg_10_0, arg_10_1, arg_10_2)
	arg_10_0.sizePolicy_.horizontal = var_0_3(arg_10_1)
	arg_10_0.sizePolicy_.vertical = var_0_3(arg_10_2)

	return arg_10_0.target_
end

function var_0_1.getLayoutPadding(arg_11_0)
	return arg_11_0.padding_.top, arg_11_0.padding_.right, arg_11_0.padding_.bottom, arg_11_0.padding_.left
end

function var_0_1.setLayoutPadding(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	arg_12_0.padding_.top = checknumber(arg_12_1)
	arg_12_0.padding_.right = checknumber(arg_12_2)
	arg_12_0.padding_.bottom = checknumber(arg_12_3)
	arg_12_0.padding_.left = checknumber(arg_12_4)

	return arg_12_0.target_
end

function var_0_1.getLayoutMargin(arg_13_0)
	return arg_13_0.margin_.top, arg_13_0.margin_.right, arg_13_0.margin_.bottom, arg_13_0.margin_.left
end

function var_0_1.setLayoutMargin(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4)
	arg_14_0.margin_.top = checknumber(arg_14_1)
	arg_14_0.margin_.right = checknumber(arg_14_2)
	arg_14_0.margin_.bottom = checknumber(arg_14_3)
	arg_14_0.margin_.left = checknumber(arg_14_4)

	return arg_14_0.target_
end

function var_0_1.exportMethods(arg_15_0)
	arg_15_0:exportMethods_({
		"getLayoutSize",
		"setLayoutSize",
		"getLayoutMinSize",
		"setLayoutMinSize",
		"getLayoutMaxSize",
		"setLayoutMaxSize",
		"getLayoutSizePolicy",
		"setLayoutSizePolicy",
		"getLayoutPadding",
		"setLayoutPadding",
		"getLayoutMargin",
		"setLayoutMargin"
	})

	return arg_15_0.target_
end

function var_0_1.onBind_(arg_16_0)
	arg_16_0.layoutSize_ = nil
	arg_16_0.minSize_ = {
		width = 0,
		height = 0
	}
	arg_16_0.maxSize_ = {
		width = var_0_2,
		height = var_0_2
	}
	arg_16_0.sizePolicy_ = {
		h = display.PREFERRED_SIZE,
		v = display.PREFERRED_SIZE
	}
	arg_16_0.padding_ = {
		top = 0,
		left = 0,
		bottom = 0,
		right = 0
	}
	arg_16_0.margin_ = {
		top = 0,
		left = 0,
		bottom = 0,
		right = 0
	}
end

function var_0_1.onUnbind_(arg_17_0)
	return
end

return var_0_1
