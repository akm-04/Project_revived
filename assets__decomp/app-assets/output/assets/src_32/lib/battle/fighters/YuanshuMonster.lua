local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SummonMonster", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill

function var_0_3.die(arg_1_0)
	arg_1_0:specialAttack()
	var_0_3.super.die(arg_1_0)
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:updateBlueSkill()
end

function var_0_3.updateBlueSkill(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_3_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 30 > 0 or arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) < 1 then
		return
	end

	local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	local var_3_1 = var_0_5.B8(arg_3_0, var_3_0)

	if next(var_3_1) == nil then
		return
	end

	local var_3_2 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	local var_3_3 = arg_3_0:createAttackUnits(var_3_1, var_3_2)

	for iter_3_0, iter_3_1 in ipairs(var_3_3) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
		table.insert(arg_3_0.records_.special_units, iter_3_1)
	end
end

function var_0_3.specialAttack(arg_4_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_4_0.explode_ then
		return
	end

	local var_4_0 = arg_4_0:getEnergySkillID()
	local var_4_1 = var_0_5.B8(arg_4_0, var_4_0)

	if next(var_4_1) then
		local var_4_2 = arg_4_0:createAttackUnits(var_4_1, var_4_0)

		for iter_4_0, iter_4_1 in ipairs(var_4_2) do
			iter_4_1.arrived = false

			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end
end

function var_0_3.getAP(arg_5_0)
	if not arg_5_0.summoner then
		return var_0_3.super.getAP(arg_5_0)
	end

	return arg_5_0.summoner:getAP()
end

function var_0_3.updateNearestTarget(arg_6_0)
	if arg_6_0:getInitTarget() and not arg_6_0:getInitTarget():isDeath() and not arg_6_0:getInitTarget():isAffected() then
		arg_6_0.nearestTarget_ = arg_6_0:getInitTarget()

		return
	elseif arg_6_0:getInitTarget() then
		var_0_3.super.updateNearestTarget(arg_6_0)

		arg_6_0.initTarget_ = false

		return
	end

	var_0_3.super.updateNearestTarget(arg_6_0)
end

function var_0_3.beginAttack(arg_7_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_7_0 = arg_7_0.reportSkills_[1]

		if not var_7_0 or var_0_1.ctx.battle.count ~= var_7_0.startCount_ then
			if arg_7_0.reportSkills_[2] and arg_7_0.reportSkills_[2].startCount_ == var_0_1.ctx.battle.count then
				table.remove(arg_7_0.reportSkills_, 1)
			else
				return
			end
		end
	elseif not arg_7_0:canAttack() then
		return
	end

	arg_7_0:resetLeftInterval()

	local var_7_1 = arg_7_0:popSkillByType()
	local var_7_2 = var_0_6:type(var_7_1)

	if var_7_1 == 0 or var_7_2 == var_0_2.AttackType.AD and arg_7_0:isExcuteAdCircle() or var_7_2 == var_0_2.AttackType.AP and arg_7_0:isExcuteApCircle() then
		return
	end

	if arg_7_0.manualTargets_ and next(arg_7_0.manualTargets_) then
		arg_7_0:flipX(arg_7_0.manualTargets_[1]:getX() < arg_7_0:getX())
	elseif not arg_7_0.manualDirection_ and arg_7_0:getNearestTarget() then
		arg_7_0:flipX(arg_7_0:getNearestTarget():getX() < arg_7_0:getX())
	end

	arg_7_0:energyAction(var_7_1)

	local var_7_3 = var_0_6:sound(var_7_1)

	var_0_1.ctx.battle.pushSoundQueue(var_7_3)

	if var_7_1 == arg_7_0:getEnergySkillID() then
		arg_7_0:updateHp(0)

		arg_7_0.explode_ = true

		arg_7_0:die()
	else
		local var_7_4 = var_0_6:attackIndex(var_7_1)

		arg_7_0:playAttack(var_7_4)
	end

	arg_7_0:selfSkillEffect()

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		arg_7_0.unitSkills_ = arg_7_0.reportSkills_[1]
	else
		arg_7_0.unitSkills_ = var_0_4.new({
			fighter = arg_7_0,
			skillID = var_7_1
		})
	end

	arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)
end

function var_0_3.getInitTarget(arg_8_0)
	if arg_8_0.initTarget_ == nil then
		arg_8_0.initTarget_ = var_0_5.B3(arg_8_0)[1]
	end

	return arg_8_0.initTarget_
end

function var_0_3.isAutoFighter(arg_9_0)
	return true
end

function var_0_3.energyAction(arg_10_0)
	return
end

return var_0_3
