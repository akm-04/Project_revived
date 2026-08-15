local var_0_0 = import(".UIBoxLayout")
local var_0_1 = import(".UICheckBoxButton")
local var_0_2 = import(".UIGroup")
local var_0_3 = class("UICheckBoxButtonGroup", var_0_2)

var_0_3.BUTTON_SELECT_CHANGED = "BUTTON_SELECT_CHANGED"

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0)
	arg_1_0:setLayout(var_0_0.new(arg_1_1 or display.LEFT_TO_RIGHT))

	arg_1_0.buttons_ = {}
	arg_1_0.currentSelectedIndex_ = 0
end

function var_0_3.addButton(arg_2_0, arg_2_1)
	arg_2_0:addChild(arg_2_1)

	arg_2_0.buttons_[#arg_2_0.buttons_ + 1] = arg_2_1

	arg_2_0:getLayout():addWidget(arg_2_1):apply(arg_2_0)
	arg_2_1:onButtonClicked(handler(arg_2_0, arg_2_0.onButtonStateChanged_))
	arg_2_1:onButtonStateChanged(handler(arg_2_0, arg_2_0.onButtonStateChanged_))

	return arg_2_0
end

function var_0_3.removeButtonAtIndex(arg_3_0, arg_3_1)
	assert(arg_3_0.buttons_[arg_3_1] ~= nil, "UICheckBoxButtonGroup:removeButtonAtIndex() - invalid index")

	local var_3_0 = arg_3_0.buttons_[arg_3_1]
	local var_3_1 = arg_3_0:getLayout()

	var_3_1:removeWidget(var_3_0)
	var_3_1:apply(arg_3_0)
	var_3_0:removeFromParent()
	table.remove(arg_3_0.buttons_, arg_3_1)

	if arg_3_0.currentSelectedIndex_ == arg_3_1 then
		arg_3_0:updateButtonState_(nil)
	elseif arg_3_1 < arg_3_0.currentSelectedIndex_ then
		arg_3_0:updateButtonState_(arg_3_0.buttons_[arg_3_0.currentSelectedIndex_ - 1])
	end

	return arg_3_0
end

function var_0_3.getButtonAtIndex(arg_4_0, arg_4_1)
	return arg_4_0.buttons_[arg_4_1]
end

function var_0_3.getButtonsCount(arg_5_0)
	return #arg_5_0.buttons_
end

function var_0_3.setButtonsLayoutMargin(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	for iter_6_0, iter_6_1 in ipairs(arg_6_0.buttons_) do
		iter_6_1:setLayoutMargin(arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	end

	arg_6_0:getLayout():apply(arg_6_0)

	return arg_6_0
end

function var_0_3.addButtonSelectChangedEventListener(arg_7_0, arg_7_1)
	return arg_7_0:addEventListener(var_0_3.BUTTON_SELECT_CHANGED, arg_7_1)
end

function var_0_3.onButtonSelectChanged(arg_8_0, arg_8_1)
	arg_8_0:addButtonSelectChangedEventListener(arg_8_1)

	return arg_8_0
end

function var_0_3.onButtonStateChanged_(arg_9_0, arg_9_1)
	if arg_9_1.name == var_0_1.STATE_CHANGED_EVENT and arg_9_1.target:isButtonSelected() == false then
		return
	end

	arg_9_0:updateButtonState_(arg_9_1.target)
end

function var_0_3.updateButtonState_(arg_10_0, arg_10_1)
	local var_10_0 = 0

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.buttons_) do
		if iter_10_1 == arg_10_1 then
			var_10_0 = iter_10_0

			if not iter_10_1:isButtonSelected() then
				iter_10_1:setButtonSelected(true)
			end
		elseif iter_10_1:isButtonSelected() then
			iter_10_1:setButtonSelected(false)
		end
	end

	if arg_10_0.currentSelectedIndex_ ~= var_10_0 then
		local var_10_1 = arg_10_0.currentSelectedIndex_

		arg_10_0.currentSelectedIndex_ = var_10_0

		arg_10_0:dispatchEvent({
			name = var_0_3.BUTTON_SELECT_CHANGED,
			selected = var_10_0,
			last = var_10_1
		})
	end
end

return var_0_3
