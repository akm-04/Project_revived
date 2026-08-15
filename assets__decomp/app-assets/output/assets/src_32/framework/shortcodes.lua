local var_0_0 = cc
local var_0_1 = var_0_0.Node

function var_0_1.add(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	arg_1_0:addChild(arg_1_1, arg_1_2 or arg_1_1:getLocalZOrder(), arg_1_3 or arg_1_1:getTag())

	return arg_1_0
end

function var_0_1.addTo(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_1:addChild(arg_2_0, arg_2_2 or arg_2_0:getLocalZOrder(), arg_2_3 or arg_2_0:getTag())

	return arg_2_0
end

function var_0_1.show(arg_3_0)
	arg_3_0:setVisible(true)

	return arg_3_0
end

function var_0_1.hide(arg_4_0)
	arg_4_0:setVisible(false)

	return arg_4_0
end

function var_0_1.pos(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0:setPosition(arg_5_1, arg_5_2)

	return arg_5_0
end

function var_0_1.center(arg_6_0)
	arg_6_0:setPosition(display.cx, display.cy)

	return arg_6_0
end

function var_0_1.scale(arg_7_0, arg_7_1)
	arg_7_0:setScale(arg_7_1)

	return arg_7_0
end

function var_0_1.rotation(arg_8_0, arg_8_1)
	arg_8_0:setRotation(arg_8_1)

	return arg_8_0
end

function var_0_1.size(arg_9_0, arg_9_1, arg_9_2)
	if type(arg_9_1) == "table" then
		arg_9_0:setContentSize(arg_9_1)
	else
		arg_9_0:setContentSize(cc.size(arg_9_1, arg_9_2))
	end

	return arg_9_0
end

function var_0_1.opacity(arg_10_0, arg_10_1)
	arg_10_0:setOpacity(arg_10_1)

	return arg_10_0
end

function var_0_1.zorder(arg_11_0, arg_11_1)
	arg_11_0:setLocalZOrder(arg_11_1)

	return arg_11_0
end

function var_0_1.stop(arg_12_0)
	arg_12_0:stopAllActions()

	return arg_12_0
end

function var_0_1.fadeIn(arg_13_0, arg_13_1)
	arg_13_0:runAction(cc.FadeIn:create(arg_13_1))

	return arg_13_0
end

function var_0_1.fadeOut(arg_14_0, arg_14_1)
	arg_14_0:runAction(cc.FadeOut:create(arg_14_1))

	return arg_14_0
end

function var_0_1.fadeTo(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0:runAction(cc.FadeTo:create(arg_15_1, arg_15_2))

	return arg_15_0
end

function var_0_1.moveTo(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	arg_16_0:runAction(cc.MoveTo:create(arg_16_1, cc.p(arg_16_2 or arg_16_0:getPositionX(), arg_16_3 or arg_16_0:getPositionY())))

	return arg_16_0
end

function var_0_1.moveBy(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	arg_17_0:runAction(cc.MoveBy:create(arg_17_1, cc.p(arg_17_2 or 0, arg_17_3 or 0)))

	return arg_17_0
end

function var_0_1.rotateTo(arg_18_0, arg_18_1, arg_18_2)
	arg_18_0:runAction(cc.RotateTo:create(arg_18_1, arg_18_2))

	return arg_18_0
end

function var_0_1.rotateBy(arg_19_0, arg_19_1, arg_19_2)
	arg_19_0:runAction(cc.RotateBy:create(arg_19_1, arg_19_2))

	return arg_19_0
end

function var_0_1.scaleTo(arg_20_0, arg_20_1, arg_20_2)
	arg_20_0:runAction(cc.ScaleTo:create(arg_20_1, arg_20_2))

	return arg_20_0
end

function var_0_1.scaleBy(arg_21_0, arg_21_1, arg_21_2)
	arg_21_0:runAction(cc.ScaleBy:create(arg_21_1, arg_21_2))

	return arg_21_0
end

function var_0_1.skewTo(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	arg_22_0:runAction(cc.SkewTo:create(arg_22_1, arg_22_2 or arg_22_0:getSkewX(), arg_22_3 or arg_22_0:getSkewY()))

	return arg_22_0
end

function var_0_1.skewBy(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	arg_23_0:runAction(cc.SkewBy:create(arg_23_1, arg_23_2 or 0, arg_23_3 or 0))

	return arg_23_0
end

function var_0_1.tintTo(arg_24_0, arg_24_1, arg_24_2, arg_24_3, arg_24_4)
	arg_24_0:runAction(cc.TintTo:create(arg_24_1, arg_24_2 or 0, arg_24_3 or 0, arg_24_4 or 0))

	return arg_24_0
end

function var_0_1.tintBy(arg_25_0, arg_25_1, arg_25_2, arg_25_3, arg_25_4)
	arg_25_0:runAction(cc.TintBy:create(arg_25_1, arg_25_2 or 0, arg_25_3 or 0, arg_25_4 or 0))

	return arg_25_0
end

local var_0_2 = var_0_0.Sprite

function var_0_2.displayFrame(arg_26_0, arg_26_1)
	arg_26_0:setSpriteFrame(arg_26_1)

	return arg_26_0
end

function var_0_2.flipX(arg_27_0, arg_27_1)
	arg_27_0:setFlippedX(arg_27_1)

	return arg_27_0
end

function var_0_2.flipY(arg_28_0, arg_28_1)
	arg_28_0:setFlippedY(arg_28_1)

	return arg_28_0
end

function var_0_1.x(arg_29_0, arg_29_1)
	local var_29_0 = cc.p(arg_29_0:getPosition())

	return arg_29_0:pos(arg_29_1, var_29_0.y)
end

function var_0_1.y(arg_30_0, arg_30_1)
	local var_30_0 = cc.p(arg_30_0:getPosition())

	return arg_30_0:pos(var_30_0.x, arg_30_1)
end

function var_0_1.getX(arg_31_0)
	return cc.p(arg_31_0:getPosition()).x
end

function var_0_1.getY(arg_32_0)
	return cc.p(arg_32_0:getPosition()).y
end

function var_0_1.width(arg_33_0, arg_33_1)
	return arg_33_0:size(arg_33_1, arg_33_0:getContentSize().height)
end

function var_0_1.height(arg_34_0, arg_34_1)
	return arg_34_0:size(arg_34_0:getContentSize().width, arg_34_1)
end

function var_0_1.getHeight(arg_35_0)
	return arg_35_0:getContentSize().height
end

function var_0_1.getWidth(arg_36_0)
	return arg_36_0:getContentSize().width
end
