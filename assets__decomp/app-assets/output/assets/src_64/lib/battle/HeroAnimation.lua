local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("HeroAnimation", var_0_1.ctx.battle.getRequire("BattleBaseNode"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.modelPoints
local var_0_6 = var_0_2.tables.hero

function var_0_3.ctor(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4)
	var_0_3.super.ctor(arg_1_0)

	arg_1_0.tableID_ = arg_1_1
	arg_1_0.modelID_ = arg_1_2
	arg_1_0.scale_ = arg_1_3 or 1

	arg_1_0:setupPoints_()

	arg_1_0.currentAnimation_ = nil

	arg_1_0:idle()
end

function var_0_3.flipX(arg_2_0, arg_2_1)
	if arg_2_1 ~= arg_2_0:getFlipX() then
		arg_2_0:setFlipX(arg_2_1)

		arg_2_0.leftPoint, arg_2_0.rightPoint = arg_2_0:flipPoint_(arg_2_0.rightPoint), arg_2_0:flipPoint_(arg_2_0.leftPoint)
		arg_2_0.chestPoint = arg_2_0:flipPoint_(arg_2_0.chestPoint)
		arg_2_0.headPoint = arg_2_0:flipPoint_(arg_2_0.headPoint)
		arg_2_0.attackedPoint = arg_2_0:flipPoint_(arg_2_0.attackedPoint)

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.attackPoints) do
			arg_2_0.attackPoints[iter_2_0] = arg_2_0:flipPoint_(iter_2_1)
		end
	end

	return arg_2_0
end

function var_0_3.showHeaderView(arg_3_0, arg_3_1, arg_3_2)
	return
end

function var_0_3.hideHeaderView(arg_4_0, arg_4_1)
	return
end

function var_0_3.addBuffs(arg_5_0, arg_5_1, arg_5_2)
	return
end

function var_0_3.removeBuffs(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	return
end

function var_0_3.updateBuffEffects_(arg_7_0)
	return
end

function var_0_3.playAttribute(arg_8_0, arg_8_1)
	return
end

function var_0_3.playAttackResultTypes(arg_9_0, arg_9_1, arg_9_2)
	return
end

function var_0_3.setHPProgress(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	return
end

function var_0_3.setActionProgress(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	return
end

function var_0_3.setArrowVisible(arg_12_0, arg_12_1, arg_12_2)
	return
end

function var_0_3.stop(arg_13_0)
	return
end

function var_0_3.pause(arg_14_0)
	return
end

function var_0_3.resume(arg_15_0)
	return
end

function var_0_3.setTimeScale(arg_16_0, arg_16_1)
	return
end

function var_0_3.idle(arg_17_0)
	return arg_17_0:playAnimation_("idle", true, nil, nil, callback)
end

function var_0_3.walk(arg_18_0, arg_18_1, arg_18_2)
	return arg_18_0:playAnimation_("run", arg_18_1, nil, nil, arg_18_2)
end

function var_0_3.die(arg_19_0, arg_19_1)
	return arg_19_0:playAnimation_("dead", false, nil, nil, arg_19_1)
end

function var_0_3.rest(arg_20_0, arg_20_1, arg_20_2)
	return arg_20_0:playAnimation_("rest", arg_20_1, nil, nil, arg_20_2)
end

function var_0_3.attack(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4)
	arg_21_0.playingAttackAnimationIndex_ = arg_21_1

	return arg_21_0:playAnimation_(arg_21_0:attackAnimationName_(arg_21_1), false, arg_21_2, arg_21_3, arg_21_4, arg_21_1)
end

function var_0_3.attacked(arg_22_0, arg_22_1)
	return arg_22_0:playAnimation_("hurt", false, nil, nil, arg_22_1)
end

function var_0_3.win(arg_23_0, arg_23_1, arg_23_2)
	return arg_23_0:playAnimation_("win", arg_23_1, nil, nil, arg_23_2)
end

function var_0_3.look(arg_24_0, arg_24_1, arg_24_2)
	return arg_24_0:playAnimation_("look", arg_24_1, nil, nil, arg_24_2)
end

function var_0_3.summon(arg_25_0, arg_25_1)
	return arg_25_0:playAnimation_("summon", false, nil, nil, arg_25_1)
end

function var_0_3.change(arg_26_0, arg_26_1)
	return arg_26_0:playAnimation_("change", false, nil, nil, arg_26_1)
end

function var_0_3.getNumberOfAttackAnimations_(arg_27_0)
	return
end

function var_0_3.setupPoints_(arg_28_0)
	arg_28_0.leftPoint = arg_28_0:point_(var_0_5:PleftX(arg_28_0.modelID_), var_0_5:PleftY(arg_28_0.modelID_))
	arg_28_0.rightPoint = arg_28_0:point_(var_0_5:PrightX(arg_28_0.modelID_), var_0_5:PrightY(arg_28_0.modelID_))
	arg_28_0.headPoint = arg_28_0:point_(var_0_5:PheadX(arg_28_0.modelID_), var_0_5:PheadY(arg_28_0.modelID_))
	arg_28_0.chestPoint = arg_28_0:point_(var_0_5:PchestX(arg_28_0.modelID_), var_0_5:PchestY(arg_28_0.modelID_))
	arg_28_0.attackedPoint = arg_28_0:point_(var_0_5:PshoujiX(arg_28_0.modelID_), var_0_5:PshoujiY(arg_28_0.modelID_))
	arg_28_0.footPoint = arg_28_0:point_(var_0_5:PfootX(arg_28_0.modelID_), var_0_5:PfootY(arg_28_0.modelID_))
	arg_28_0.attackPoints = {}

	for iter_28_0 = 1, var_0_5:attackNum(arg_28_0.modelID_) do
		local var_28_0 = arg_28_0:point_(var_0_5:PattackXs(arg_28_0.modelID_)[iter_28_0], var_0_5:PattackYs(arg_28_0.modelID_)[iter_28_0])

		table.insert(arg_28_0.attackPoints, var_28_0)
	end

	arg_28_0:size(arg_28_0.rightPoint.x - arg_28_0.leftPoint.x, arg_28_0.headPoint.y)
end

function var_0_3.setupAttackEffects_(arg_29_0)
	return
end

function var_0_3.playFloatAnimations_(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	return
end

function var_0_3.playAnimation_(arg_31_0, arg_31_1, arg_31_2, arg_31_3, arg_31_4, arg_31_5, arg_31_6)
	arg_31_0.currentAnimation_ = arg_31_1
end

function var_0_3.playAttackEffectIfNecessary_(arg_32_0)
	return
end

function var_0_3.stopAttackEffect_(arg_33_0, arg_33_1)
	return
end

function var_0_3.attackAnimationName_(arg_34_0, arg_34_1)
	return string.format("gongji%02d", arg_34_1)
end

function var_0_3.attackPointName_(arg_35_0, arg_35_1)
	return string.format("Pattack%02d", arg_35_1)
end

function var_0_3.point_(arg_36_0, arg_36_1, arg_36_2)
	return {
		x = math.floor(arg_36_1 * arg_36_0.scale_),
		y = math.floor(arg_36_2 * arg_36_0.scale_)
	}
end

function var_0_3.flipPoint_(arg_37_0, arg_37_1)
	return {
		x = -arg_37_1.x,
		y = arg_37_1.y
	}
end

function var_0_3.playEnergyEffect_(arg_38_0)
	return
end

function var_0_3.setMaskColor(arg_39_0)
	return
end

function var_0_3.unsetMaskColor(arg_40_0)
	return
end

function var_0_3.hasAnimation(arg_41_0, arg_41_1)
	return true
end

return var_0_3
