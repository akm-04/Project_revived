local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yutu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10000414
local var_0_6 = 40010143
local var_0_7 = 0
local var_0_8 = 60
local var_0_9 = 80010104
local var_0_10 = 80010104
local var_0_11 = 0.2

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

			if arg_4_0.skinSkillID_ == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_2 = arg_4_0:createAttackUnits({
					arg_4_0
				}, var_0_10)

				for iter_4_0, iter_4_1 in ipairs(var_4_2) do
					iter_4_1.basicHarm = var_0_11 * (arg_4_0:getHpLimit() - arg_4_0:getHp())

					table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
					table.insert(arg_4_0.records_.special_units, iter_4_1)
				end
			end

			arg_4_0.blinkTarget_ = nil
			arg_4_0.blinkCount_ = nil
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_0.skinSkillID_ == var_0_9 and arg_5_7 < 0 and arg_5_1.target:getEnergy() >= arg_5_1.fighter:getEnergy() then
		return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 * 2
	else
		return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
	end
end

function var_0_3.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	if arg_6_1.attackType == var_0_2.AttackType.AP and arg_6_0:isHasBuffByID(var_0_6) and arg_6_2 > 0 then
		arg_6_2 = math.max(0, arg_6_2 - var_0_7 - var_0_8 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
	end

	return var_0_3.super.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0
	local var_7_1 = -1

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_7_2 = iter_7_1.hero_:getMainAttr(var_0_2.AttributeType.WISE)

			if var_7_1 < var_7_2 then
				var_7_0 = iter_7_1
				var_7_1 = var_7_2
			end
		end
	end

	return {
		var_7_0
	}
end

return var_0_3
