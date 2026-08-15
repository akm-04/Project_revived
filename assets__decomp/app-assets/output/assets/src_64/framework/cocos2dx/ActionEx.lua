local var_0_0 = {}

_G.cca = var_0_0

function cc.Action.addTo(arg_1_0, arg_1_1)
	arg_1_1:runAction(arg_1_0)

	return arg_1_0
end

function cc.Node.buildAction(arg_2_0, ...)
	local var_2_0 = var_0_0.builder(...)

	var_2_0.target = arg_2_0

	return var_2_0
end

function var_0_0.show()
	return cc.Show:create()
end

function var_0_0.hide()
	return cc.Hide:create()
end

function var_0_0.toggle()
	return cc.ToggleVisibility:create()
end

function var_0_0.removeSelf()
	return cc.RemoveSelf:create()
end

function var_0_0.flipX(arg_7_0)
	return cc.FlipX:create(arg_7_0)
end

function var_0_0.flipY(arg_8_0)
	return cc.FlipY:create(arg_8_0)
end

function var_0_0.place(arg_9_0, arg_9_1)
	return cc.Place:create(cc.p(arg_9_0, arg_9_1))
end

function var_0_0.callFunc(arg_10_0)
	if arg_10_0 then
		return cc.CallFunc:create(arg_10_0)
	end

	return false
end

function var_0_0.callFuncN(arg_11_0)
	if arg_11_0 then
		return cc.CallFuncN:create(arg_11_0)
	end

	return false
end

function var_0_0.rotateTo(arg_12_0, ...)
	return cc.RotateTo:create(arg_12_0, ...)
end

function var_0_0.rotateBy(arg_13_0, ...)
	return cc.RotateBy:create(arg_13_0, ...)
end

function var_0_0.moveTo(arg_14_0, arg_14_1, arg_14_2)
	if arg_14_2 then
		arg_14_1 = cc.p(arg_14_1, arg_14_2)
	end

	return cc.MoveTo:create(arg_14_0, arg_14_1)
end

function var_0_0.moveBy(arg_15_0, arg_15_1, arg_15_2)
	if arg_15_2 then
		arg_15_1 = cc.p(arg_15_1, arg_15_2)
	end

	return cc.MoveBy:create(arg_15_0, arg_15_1)
end

function var_0_0.skewTo(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_2 then
		arg_16_1 = cc.p(arg_16_1, arg_16_2)
	end

	return cc.SkewTo:create(arg_16_0, arg_16_1)
end

function var_0_0.skewBy(arg_17_0, arg_17_1, arg_17_2)
	if arg_17_2 then
		arg_17_1 = cc.p(arg_17_1, arg_17_2)
	end

	return cc.SkewBy:create(arg_17_0, arg_17_1)
end

function var_0_0.jumpTo(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4)
	if arg_18_2 then
		arg_18_1 = cc.p(arg_18_1, arg_18_2)
	end

	return cc.JumpTo:create(arg_18_0, arg_18_1, arg_18_3, arg_18_4)
end

function var_0_0.jumpBy(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4)
	if arg_19_2 then
		arg_19_1 = cc.p(arg_19_1, arg_19_2)
	end

	return cc.JumpBy:create(arg_19_0, arg_19_1, arg_19_3, arg_19_4)
end

function var_0_0.bezierTo(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	self[1] = arg_20_1
	self[2] = arg_20_2
	self[3] = arg_20_3

	return cc.BezierTo:create(arg_20_0, self)
end

function var_0_0.bezierBy(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	self[1] = arg_21_1
	self[2] = arg_21_2
	self[3] = arg_21_3

	return cc.BezierBy:create(arg_21_0, self)
end

function var_0_0.splineTo(arg_22_0, arg_22_1)
	return cc.CardinalSplineTo:create(arg_22_0, arg_22_1)
end

function var_0_0.splineBy(arg_23_0, arg_23_1)
	return cc.CardinalSplineBy:create(arg_23_0, arg_23_1)
end

function var_0_0.romTo(arg_24_0, arg_24_1)
	return cc.CardinalRomBy:create(arg_24_0, arg_24_1)
end

function var_0_0.romBy(arg_25_0, arg_25_1)
	return cc.CardinalRomBy:create(arg_25_0, arg_25_1)
end

function var_0_0.scaleTo(arg_26_0, ...)
	return cc.ScaleTo:create(arg_26_0, ...)
end

function var_0_0.scaleBy(arg_27_0, ...)
	return cc.ScaleBy:create(arg_27_0, ...)
end

function var_0_0.blink(arg_28_0, arg_28_1)
	return cc.Blink:create(arg_28_0, arg_28_1)
end

function var_0_0.fadeTo(arg_29_0, arg_29_1)
	return cc.FadeTo:create(arg_29_0, arg_29_1 * 255)
end

function var_0_0.fadeIn(arg_30_0)
	return cc.FadeIn:create(arg_30_0)
end

function var_0_0.fadeOut(arg_31_0)
	return cc.FadeOut:create(arg_31_0)
end

function var_0_0.tintTo(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	return cc.TintTo:create(arg_32_0, arg_32_1 * 255, arg_32_2 * 255, arg_32_3 * 255)
end

function var_0_0.tintBy(arg_33_0, arg_33_1, arg_33_2, arg_33_3)
	return cc.TintBy:create(arg_33_0, arg_33_1 * 255, arg_33_2 * 255, arg_33_3 * 255)
end

function var_0_0.delay(arg_34_0)
	return cc.DelayTime:create(arg_34_0)
end

function var_0_0.animate(arg_35_0)
	return cc.Animate:create(arg_35_0)
end

function var_0_0.progressTo(arg_36_0, arg_36_1)
	return cc.ProgressTo:create(arg_36_0, arg_36_1)
end

function var_0_0.progressFromTo(arg_37_0, arg_37_1, arg_37_2)
	return cc.ProgressFromTo:create(arg_37_0, arg_37_1, arg_37_2)
end

local function var_0_1(arg_38_0)
	if not arg_38_0 then
		error("action required!!!")
	end

	if arg_38_0.build then
		return arg_38_0:build()
	end

	return arg_38_0
end

function var_0_0.seq(arg_39_0)
	return cc.Sequence:create(arg_39_0)
end

function var_0_0.spawn(arg_40_0)
	return cc.Spawn:create(arg_40_0)
end

function var_0_0.repeatForever(arg_41_0)
	return cc.RepeatForever:create(var_0_1(arg_41_0))
end

function var_0_0.reverse(arg_42_0)
	return cc.ReverseTime:create(var_0_1(arg_42_0))
end

function var_0_0.speed(arg_43_0, arg_43_1)
	return cc.Speed:create(var_0_1(arg_43_0), arg_43_1)
end

function var_0_0.rep(arg_44_0, arg_44_1)
	return cc.Repeat:create(var_0_1(arg_44_0), arg_44_1)
end

function var_0_0.targeted(arg_45_0, arg_45_1)
	return cc.TargetedAction:create(arg_45_1, var_0_1(arg_45_0))
end

function var_0_0.follow(arg_46_0, arg_46_1)
	return cc.Follow:create(arg_46_0, arg_46_1)
end

local function var_0_2(arg_47_0, arg_47_1)
	local var_47_0 = "Ease" .. arg_47_0:gsub("^%w", string.upper)
	local var_47_1

	if arg_47_1 then
		function var_47_1(arg_48_0, arg_48_1)
			return cc[var_47_0]:create(var_0_1(arg_48_0), arg_48_1 or arg_47_1)
		end
	else
		function var_47_1(arg_49_0)
			return cc[var_47_0]:create(var_0_1(arg_49_0))
		end
	end

	var_0_0[arg_47_0] = var_47_1
	var_0_0[arg_47_0:upper()] = var_47_1
end

var_0_2("backIn")
var_0_2("backOut")
var_0_2("backinOut")
var_0_2("bounce")
var_0_2("bounceIn")
var_0_2("bounceInOut")
var_0_2("bounceOut")
var_0_2("elastic", 0.3)
var_0_2("elasticIn", 0.3)
var_0_2("elasticInOut", 0.3)
var_0_2("elasticOut", 0.3)
var_0_2("exponentialIn")
var_0_2("exponentialInOut")
var_0_2("exponentialOut")
var_0_2("in", 1)
var_0_2("inOut", 1)
var_0_2("out", 1)
var_0_2("rateAction", 1)
var_0_2("sineIn")
var_0_2("sineInOut")
var_0_2("sineOut")

var_0_0.cb = var_0_0.callFunc
var_0_0.ani = var_0_0.animate
var_0_0.loop = var_0_0.repeatForever
var_0_0.to = var_0_0.targeted

local var_0_3 = {}

var_0_3.__class = "ActionBuilder"
var_0_3.__index = var_0_3

function var_0_0.builder(arg_50_0, arg_50_1)
	local var_50_0 = setmetatable({}, var_0_3)

	var_50_0.cur = var_50_0
	var_50_0.cur.parent = arg_50_1 or var_50_0
	var_50_0.cur.cmd = arg_50_0 or "seq"
	var_50_0.target = nil

	if not var_0_0[var_50_0.cur.cmd] then
		error("cmd '" .. (arg_50_0 or "nil") .. "' not found")
	end

	return var_50_0
end

function var_0_3.clear(arg_51_0)
	for iter_51_0 = 1, #arg_51_0.cur do
		arg_51_0.cur[iter_51_0] = nil
	end

	return arg_51_0
end

function var_0_3.clone(arg_52_0, arg_52_1)
	arg_52_0:clear()

	for iter_52_0 = 1, #arg_52_1.cur do
		arg_52_0.cur[iter_52_0] = arg_52_1.cur[iter_52_0]
	end

	return arg_52_0
end

function var_0_3.begin(arg_53_0, arg_53_1, arg_53_2)
	arg_53_0.cur = var_0_0.builder(arg_53_1, arg_53_0.cur)
	arg_53_0.cur.args = arg_53_2
	arg_53_0.cur.target = arg_53_0.target

	return arg_53_0
end

function var_0_3.done(arg_54_0, arg_54_1, ...)
	local var_54_0 = arg_54_0.cur.parent
	local var_54_1 = arg_54_0.cur
	local var_54_2 = arg_54_0.cur.cmd
	local var_54_3 = arg_54_0.cur.args

	if var_54_2 ~= "seq" and var_54_2 ~= "spawn" then
		var_54_1 = var_0_0.seq(var_54_1)
	end

	local var_54_4 = var_0_0[var_54_2](var_54_1, var_54_3)

	if arg_54_1 and type(arg_54_1) == "string" then
		arg_54_1 = var_0_0[arg_54_1:upper()]

		if arg_54_1 then
			var_54_4 = arg_54_1(var_54_4, ...)
		end
	end

	arg_54_0.cur = var_54_0
	arg_54_0.cur[#arg_54_0.cur + 1] = var_54_4

	return arg_54_0, var_54_4
end

function var_0_3.action(arg_55_0)
	local var_55_0, var_55_1 = arg_55_0:done()

	return var_55_1
end

function var_0_3.add(arg_56_0, arg_56_1)
	arg_56_0.cur[#arg_56_0.cur + 1] = arg_56_1

	return arg_56_0
end

function var_0_3.addTo(arg_57_0, arg_57_1)
	arg_57_1 = arg_57_1 or arg_57_0.target

	assert(not tolua.isnull(arg_57_1), "ActionBuilder.addTo() - target is not cc.Node")

	local var_57_0, var_57_1 = arg_57_0:done()

	return var_57_1:addTo(arg_57_1)
end

var_0_3.run = var_0_3.addTo
var_0_3.build = var_0_3.done

for iter_0_0, iter_0_1 in pairs(var_0_0) do
	var_0_3[iter_0_0] = function(arg_58_0, ...)
		local var_58_0 = iter_0_1(...)

		if var_58_0 then
			arg_58_0.cur[#arg_58_0.cur + 1] = var_58_0
		end

		return arg_58_0
	end
end

local var_0_4 = var_0_3.moveTo

function var_0_3.moveTo(arg_59_0, arg_59_1, arg_59_2, arg_59_3)
	if arg_59_0.target then
		arg_59_2 = arg_59_2 or arg_59_0.target:getPositionX()

		if not arg_59_3 and type(arg_59_2) == "number" then
			arg_59_3 = arg_59_0.target:getPositionY()
		end
	end

	return var_0_4(arg_59_0, arg_59_1, arg_59_2, arg_59_3)
end

return var_0_0
