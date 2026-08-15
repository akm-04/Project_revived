local var_0_0 = {}
local var_0_1 = {
	BACKIN = {
		cc.EaseBackIn,
		1
	},
	BACKINOUT = {
		cc.EaseBackInOut,
		1
	},
	BACKOUT = {
		cc.EaseBackOut,
		1
	},
	BOUNCE = {
		cc.EaseBounce,
		1
	},
	BOUNCEIN = {
		cc.EaseBounceIn,
		1
	},
	BOUNCEINOUT = {
		cc.EaseBounceInOut,
		1
	},
	BOUNCEOUT = {
		cc.EaseBounceOut,
		1
	},
	ELASTIC = {
		cc.EaseElastic,
		2,
		0.3
	},
	ELASTICIN = {
		cc.EaseElasticIn,
		2,
		0.3
	},
	ELASTICINOUT = {
		cc.EaseElasticInOut,
		2,
		0.3
	},
	ELASTICOUT = {
		cc.EaseElasticOut,
		2,
		0.3
	},
	EXPONENTIALIN = {
		cc.EaseExponentialIn,
		1
	},
	EXPONENTIALINOUT = {
		cc.EaseExponentialInOut,
		1
	},
	EXPONENTIALOUT = {
		cc.EaseExponentialOut,
		1
	},
	IN = {
		cc.EaseIn,
		2,
		1
	},
	INOUT = {
		cc.EaseInOut,
		2,
		1
	},
	OUT = {
		cc.EaseOut,
		2,
		1
	},
	RATEACTION = {
		cc.EaseRateAction,
		2,
		1
	},
	SINEIN = {
		cc.EaseSineIn,
		1
	},
	SINEINOUT = {
		cc.EaseSineInOut,
		1
	},
	SINEOUT = {
		cc.EaseSineOut,
		1
	}
}
local var_0_2 = cc.Director:getInstance():getActionManager()

function var_0_0.newEasing(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = string.upper(tostring(arg_1_1))

	if string.sub(var_1_0, 1, 6) == "CCEASE" then
		var_1_0 = string.sub(var_1_0, 7)
	end

	local var_1_1

	if var_0_1[var_1_0] then
		local var_1_2, var_1_3, var_1_4 = unpack(var_0_1[var_1_0])

		if var_1_3 == 2 then
			var_1_1 = var_1_2:create(arg_1_0, arg_1_2 or var_1_4)
		else
			var_1_1 = var_1_2:create(arg_1_0)
		end
	end

	return var_1_1 or arg_1_0
end

function var_0_0.create(arg_2_0, arg_2_1)
	arg_2_1 = checktable(arg_2_1)

	if arg_2_1.easing then
		if type(arg_2_1.easing) == "table" then
			arg_2_0 = var_0_0.newEasing(arg_2_0, unpack(arg_2_1.easing))
		else
			arg_2_0 = var_0_0.newEasing(arg_2_0, arg_2_1.easing)
		end
	end

	local var_2_0 = {}
	local var_2_1 = checknumber(arg_2_1.delay)

	if var_2_1 > 0 then
		var_2_0[#var_2_0 + 1] = cc.DelayTime:create(var_2_1)
	end

	var_2_0[#var_2_0 + 1] = arg_2_0

	local var_2_2 = arg_2_1.onComplete

	if type(var_2_2) ~= "function" then
		var_2_2 = nil
	end

	if var_2_2 then
		var_2_0[#var_2_0 + 1] = cc.CallFunc:create(var_2_2)
	end

	if #var_2_0 > 1 then
		return var_0_0.sequence(var_2_0)
	else
		return var_2_0[1]
	end
end

function var_0_0.execute(arg_3_0, arg_3_1, arg_3_2)
	assert(not tolua.isnull(arg_3_0), "transition.execute() - target is not cc.Node")

	local var_3_0 = var_0_0.create(arg_3_1, arg_3_2)

	arg_3_0:runAction(var_3_0)

	return var_3_0
end

function var_0_0.rotateTo(arg_4_0, arg_4_1)
	assert(not tolua.isnull(arg_4_0), "transition.rotateTo() - target is not cc.Node")

	local var_4_0 = cc.RotateTo:create(arg_4_1.time, arg_4_1.rotate)

	return var_0_0.execute(arg_4_0, var_4_0, arg_4_1)
end

function var_0_0.moveTo(arg_5_0, arg_5_1)
	assert(not tolua.isnull(arg_5_0), "transition.moveTo() - target is not cc.Node")

	local var_5_0, var_5_1 = arg_5_0:getPosition()
	local var_5_2 = arg_5_1.x or var_5_0
	local var_5_3 = arg_5_1.y or var_5_1
	local var_5_4 = cc.MoveTo:create(arg_5_1.time, cc.p(var_5_2, var_5_3))

	return var_0_0.execute(arg_5_0, var_5_4, arg_5_1)
end

function var_0_0.moveBy(arg_6_0, arg_6_1)
	assert(not tolua.isnull(arg_6_0), "transition.moveBy() - target is not cc.Node")

	local var_6_0 = arg_6_1.x or 0
	local var_6_1 = arg_6_1.y or 0
	local var_6_2 = cc.MoveBy:create(arg_6_1.time, cc.p(var_6_0, var_6_1))

	return var_0_0.execute(arg_6_0, var_6_2, arg_6_1)
end

function var_0_0.fadeIn(arg_7_0, arg_7_1)
	assert(not tolua.isnull(arg_7_0), "transition.fadeIn() - target is not cc.Node")

	local var_7_0 = cc.FadeIn:create(arg_7_1.time)

	return var_0_0.execute(arg_7_0, var_7_0, arg_7_1)
end

function var_0_0.fadeOut(arg_8_0, arg_8_1)
	assert(not tolua.isnull(arg_8_0), "transition.fadeOut() - target is not cc.Node")

	local var_8_0 = cc.FadeOut:create(arg_8_1.time)

	return var_0_0.execute(arg_8_0, var_8_0, arg_8_1)
end

function var_0_0.fadeTo(arg_9_0, arg_9_1)
	assert(not tolua.isnull(arg_9_0), "transition.fadeTo() - target is not cc.Node")

	local var_9_0 = checkint(arg_9_1.opacity)

	if var_9_0 < 0 then
		var_9_0 = 0
	elseif var_9_0 > 255 then
		var_9_0 = 255
	end

	local var_9_1 = cc.FadeTo:create(arg_9_1.time, var_9_0)

	return var_0_0.execute(arg_9_0, var_9_1, arg_9_1)
end

function var_0_0.scaleTo(arg_10_0, arg_10_1)
	assert(not tolua.isnull(arg_10_0), "transition.scaleTo() - target is not cc.Node")

	local var_10_0

	if arg_10_1.scale then
		var_10_0 = cc.ScaleTo:create(checknumber(arg_10_1.time), checknumber(arg_10_1.scale))
	elseif arg_10_1.scaleX or arg_10_1.scaleY then
		local var_10_1
		local var_10_2

		if arg_10_1.scaleX then
			var_10_1 = checknumber(arg_10_1.scaleX)
		else
			var_10_1 = arg_10_0:getScaleX()
		end

		if arg_10_1.scaleY then
			var_10_2 = checknumber(arg_10_1.scaleY)
		else
			var_10_2 = arg_10_0:getScaleY()
		end

		var_10_0 = cc.ScaleTo:create(checknumber(arg_10_1.time), var_10_1, var_10_2)
	end

	return var_0_0.execute(arg_10_0, var_10_0, arg_10_1)
end

function var_0_0.sequence(arg_11_0)
	if #arg_11_0 < 1 then
		return
	end

	if #arg_11_0 < 2 then
		return arg_11_0[1]
	end

	local var_11_0 = arg_11_0[1]

	for iter_11_0 = 2, #arg_11_0 do
		var_11_0 = cc.Sequence:create(var_11_0, arg_11_0[iter_11_0])
	end

	return var_11_0
end

function var_0_0.playAnimationOnce(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0 = {}

	if type(arg_12_4) == "number" and arg_12_4 > 0 then
		arg_12_0:setVisible(false)

		var_12_0[#var_12_0 + 1] = cc.DelayTime:create(arg_12_4)
		var_12_0[#var_12_0 + 1] = cc.Show:create()
	end

	var_12_0[#var_12_0 + 1] = cc.Animate:create(arg_12_1)

	if arg_12_2 then
		var_12_0[#var_12_0 + 1] = cc.RemoveSelf:create()
	end

	if arg_12_3 then
		var_12_0[#var_12_0 + 1] = cc.CallFunc:create(arg_12_3)
	end

	local var_12_1

	if #var_12_0 > 1 then
		var_12_1 = var_0_0.sequence(var_12_0)
	else
		var_12_1 = var_12_0[1]
	end

	arg_12_0:runAction(var_12_1)

	return var_12_1
end

function var_0_0.playAnimationForever(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = cc.Animate:create(arg_13_1)
	local var_13_1

	if type(arg_13_2) == "number" and arg_13_2 > 0 then
		arg_13_0:setVisible(false)

		local var_13_2 = var_0_0.sequence({
			cc.DelayTime:create(arg_13_2),
			cc.Show:create(),
			var_13_0
		})

		var_13_1 = cc.RepeatForever:create(var_13_2)
	else
		var_13_1 = cc.RepeatForever:create(var_13_0)
	end

	arg_13_0:runAction(var_13_1)

	return var_13_1
end

function var_0_0.removeAction(arg_14_0)
	if not tolua.isnull(arg_14_0) then
		var_0_2:removeAction(arg_14_0)
	end
end

function var_0_0.stopTarget(arg_15_0)
	if not tolua.isnull(arg_15_0) then
		var_0_2:removeAllActionsFromTarget(arg_15_0)
	end
end

function var_0_0.pauseTarget(arg_16_0)
	if not tolua.isnull(arg_16_0) then
		var_0_2:pauseTarget(arg_16_0)
	end
end

function var_0_0.resumeTarget(arg_17_0)
	if not tolua.isnull(arg_17_0) then
		var_0_2:resumeTarget(arg_17_0)
	end
end

return var_0_0
