local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yutu", var_0_1.ctx.battle.requireFighter("HideBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10000414
local var_0_6 = 40010143
local var_0_7 = 0
local var_0_8 = 60

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blinkTarget_ = nil
	arg_1_0.blinkCount_ = nil
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)
	arg_2_0:blinkTo(arg_2_1)
end

function var_0_3.blinkTo(arg_3_0, arg_3_1)
	if arg_3_0:isDeath() or not arg_3_0:getNearestTarget() then
		return
	end

	local var_3_0 = arg_3_1.rootID_

	if var_3_0 ~= arg_3_0:getEnergySkillID() and var_3_0 ~= arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		return
	end

	arg_3_0.blinkTarget_ = unpack(arg_3_0:selectTargetByTypeD1())
	arg_3_0.blinkCount_ = var_0_4:pretime(var_3_0)
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.blinkCount_ then
		arg_4_0.blinkCount_ = arg_4_0.blinkCount_ - 1

		if arg_4_0.blinkCount_ <= 0 then
			if not arg_4_0.blinkTarget_ then
				arg_4_0.blinkTarget_ = unpack(arg_4_0:selectTargetByTypeD1())
			end

			local var_4_0 = arg_4_0.blinkTarget_

			if not var_4_0 then
				var_4_0 = arg_4_0
			elseif arg_4_0.blinkTarget_:isDeath() then
				var_4_0 = unpack(arg_4_0:selectTargetByTypeD1())
				var_4_0 = var_4_0 or arg_4_0
			end

			local var_4_1 = var_4_0:getFlipX() == true and 1 or -1

			if var_4_0:avoidHeroMoveBehind() then
				var_4_1 = -var_4_1

				arg_4_0:x(var_4_0:getX() + var_4_1 * 200)
				arg_4_0:flipX(not var_4_0:getFlipX())
			else
				arg_4_0:x(var_4_0:getX() + var_4_1 * 100)
				arg_4_0:flipX(var_4_0:getFlipX())
			end

			arg_4_0:y(var_4_0:getY())

			arg_4_0.blinkTarget_ = nil
			arg_4_0.blinkCount_ = nil
		end
	end
end

function var_0_3.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	if arg_5_1.attackType == var_0_2.AttackType.AP and arg_5_0:isHasBuffByID(var_0_6) and arg_5_2 > 0 then
		arg_5_2 = math.max(0, arg_5_2 - var_0_7 - var_0_8 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
	end

	return var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1 = -1

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_6_2 = iter_6_1.hero_:getMainAttr(var_0_2.AttributeType.WISE)

			if var_6_1 < var_6_2 then
				var_6_0 = iter_6_1
				var_6_1 = var_6_2
			end
		end
	end

	return {
		var_6_0
	}
end

return var_0_3
