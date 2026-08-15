local var_0_0 = class("UILoadingBar", function()
	return (cc.ClippingRegionNode:create())
end)

var_0_0.DIRECTION_LEFT_TO_RIGHT = 0
var_0_0.DIRECTION_RIGHT_TO_LEFT = 1

function var_0_0.ctor(arg_2_0, arg_2_1)
	if arg_2_1.scale9 then
		arg_2_0.scale9 = true

		local var_2_0 = ccui.Scale9Sprite or cc.Scale9Sprite

		if string.byte(arg_2_1.image) == 35 then
			arg_2_0.bar = var_2_0:createWithSpriteFrameName(string.sub(arg_2_1.image, 2), arg_2_1.capInsets)
		else
			arg_2_0.bar = var_2_0:create(arg_2_1.capInsets, arg_2_1.image)
		end

		arg_2_0:setClippingRegion(cc.rect(0, 0, arg_2_1.viewRect.width, arg_2_1.viewRect.height))
	else
		arg_2_0.bar = display.newSprite(arg_2_1.image)
	end

	arg_2_0.direction_ = arg_2_1.direction or var_0_0.DIRECTION_LEFT_TO_RIGHT

	arg_2_0:setViewRect(arg_2_1.viewRect)
	arg_2_0.bar:setAnchorPoint(cc.p(0, 0))
	arg_2_0.bar:setPosition(0, 0)
	arg_2_0:setPercent(arg_2_1.percent or 0)
	arg_2_0:addChild(arg_2_0.bar)
end

function var_0_0.setPercent(arg_3_0, arg_3_1)
	local var_3_0 = cc.rect(arg_3_0.viewRect_.x, arg_3_0.viewRect_.y, arg_3_0.viewRect_.width, arg_3_0.viewRect_.height)
	local var_3_1 = var_3_0.width * arg_3_1 / 100

	var_3_0.x = 0
	var_3_0.y = 0

	if arg_3_0.scale9 then
		arg_3_0.bar:setPreferredSize(cc.size(var_3_1, var_3_0.height))

		if var_0_0.DIRECTION_LEFT_TO_RIGHT ~= arg_3_0.direction_ then
			arg_3_0.bar:setPosition(var_3_0.width - var_3_1, 0)
		end
	elseif var_0_0.DIRECTION_LEFT_TO_RIGHT == arg_3_0.direction_ then
		var_3_0.width = var_3_1

		arg_3_0:setClippingRegion(cc.rect(var_3_0.x, var_3_0.y, var_3_0.width, var_3_0.height))
	else
		var_3_0.x = var_3_0.x + var_3_0.width - var_3_1
		var_3_0.width = var_3_1

		arg_3_0:setClippingRegion(cc.rect(var_3_0.x, var_3_0.y, var_3_0.width, var_3_0.height))
	end

	return arg_3_0
end

function var_0_0.setDirction(arg_4_0, arg_4_1)
	arg_4_0.direction_ = arg_4_1

	if var_0_0.DIRECTION_LEFT_TO_RIGHT ~= arg_4_0.direction_ and arg_4_0.bar.setFlippedX then
		arg_4_0.bar:setFlippedX(true)
	end

	return arg_4_0
end

function var_0_0.setViewRect(arg_5_0, arg_5_1)
	arg_5_0.viewRect_ = arg_5_1

	arg_5_0.bar:setContentSize(arg_5_1.width, arg_5_1.height)

	return arg_5_0
end

return var_0_0
