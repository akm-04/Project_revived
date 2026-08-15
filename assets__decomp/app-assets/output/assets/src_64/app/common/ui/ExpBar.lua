local var_0_0 = class("ExpBar", function()
	return display.newNode()
end)
local var_0_1 = 0.5
local var_0_2 = 0

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.bg_ = arg_2_1.bg
	arg_2_0.bar_ = arg_2_1.bar
	arg_2_0.barEnd_ = arg_2_1.bar_end
	arg_2_0.size_ = arg_2_1.size
	arg_2_0.borderSize_ = arg_2_1.border_size

	arg_2_0:setContentSize(arg_2_0.size_)

	arg_2_0.originBarEndSize_ = arg_2_0.barEnd_:getContentSize()

	if not arg_2_0.borderSize_ then
		arg_2_0.borderSize_ = var_0_2
	end

	if arg_2_0.bg_ then
		arg_2_0.bg_:setContentSize(arg_2_0.size_)
		arg_2_0.bg_:setAnchorPoint(cc.p(0, 0.5))
		arg_2_0.bg_:setPosition(cc.p(0, arg_2_0.size_.height / 2))
		arg_2_0:addChild(arg_2_0.bg_)
	end

	arg_2_0.bar_:setContentSize(cc.size(arg_2_0.size_.width - arg_2_0.borderSize_ * 2, arg_2_0.size_.height - arg_2_0.borderSize_ * 2))
	arg_2_0.bar_:setAnchorPoint(cc.p(0, 0.5))
	arg_2_0.bar_:setPosition(cc.p(arg_2_0.borderSize_, arg_2_0.size_.height / 2))
	arg_2_0:addChild(arg_2_0.bar_)
	arg_2_0.barEnd_:setAnchorPoint(cc.p(1, 0.5))
	arg_2_0.barEnd_:setPosition(cc.p(arg_2_0.size_.width - arg_2_0.borderSize_, arg_2_0.size_.height / 2))
	arg_2_0:addChild(arg_2_0.barEnd_)
end

function var_0_0.setPercent(arg_3_0, arg_3_1)
	if arg_3_1 < var_0_1 then
		arg_3_1 = var_0_1
	elseif arg_3_1 > 100 then
		arg_3_1 = 100
	end

	local var_3_0 = (arg_3_0.size_.width - arg_3_0.borderSize_ * 2) * arg_3_1 / 100
	local var_3_1 = arg_3_0.bar_:getContentSize().height

	if tolua.type(arg_3_0.bar_) == "cc.Sprite" then
		arg_3_0.bar_:setTextureRect(cc.rect(0, 0, var_3_0, var_3_1))
	elseif tolua.type(arg_3_0.bar_) == "ccui.Scale9Sprite" then
		if var_3_0 < arg_3_0.bar_:getOriginalSize().width then
			arg_3_0.bar_:setScaleX(var_3_0 / arg_3_0.bar_:getContentSize().width)
		else
			arg_3_0.bar_:setScaleX(1)
			arg_3_0.bar_:setContentSize(cc.size(var_3_0, var_3_1))
		end
	end

	arg_3_0.barEnd_:setAnchorPoint(cc.p(1, 0.5))
	arg_3_0.barEnd_:setPosition(cc.p(arg_3_0.borderSize_ + var_3_0, arg_3_0.size_.height / 2))

	if var_3_0 < arg_3_0.originBarEndSize_.width then
		arg_3_0.barEnd_:setScaleX(var_3_0 / arg_3_0.originBarEndSize_.width)
	else
		arg_3_0.barEnd_:setScaleX(1)
	end
end

return var_0_0
