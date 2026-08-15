local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahoudun", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_9 = 40010428
local var_0_10 = 10001064
local var_0_11 = 80110025
local var_0_12 = 40012087
local var_0_13 = 40012089
local var_0_14 = 40012088

function var_0_3.updateBaseInfo(arg_1_0)
	var_0_3.super.updateBaseInfo(arg_1_0)

	arg_1_0.specialInterval_ = (arg_1_0.specialInterval_ or 0) > 1 and arg_1_0.specialInterval_ - 1 or 0
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyExtraRate_ = 0
	arg_2_0.count_ = false
end

function var_0_3.toDoPerFrames(arg_3_0)
	if not arg_3_0.count_ then
		arg_3_0.count_ = true

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			arg_3_0.energyExtraRate_ = 0.1
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) and arg_4_1.target:isDeath() then
		arg_4_0.energyExtraRate_ = arg_4_0.energyExtraRate_ + 0.05

		local var_4_0 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)
		local var_4_1 = var_0_4.new({
			tableID = var_0_9,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(var_4_0),
			skillID = var_4_0,
			fighter = arg_4_0,
			target = arg_4_1.target
		})
		local var_4_2 = 350 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		var_4_1.manualDharm = math.min(arg_4_1.target:getHpLimit() * 0.3, var_4_2)

		arg_4_0:addBuffs({
			var_4_1
		})
	end

	if arg_4_0.skinSkillID_ == var_0_11 then
		local var_4_3 = arg_4_0:createNewBuffs({
			var_0_12
		}, arg_4_0, var_0_11)

		arg_4_0:addBuffs(var_4_3)

		local var_4_4 = arg_4_0:createNewBuffs({
			var_0_14
		}, arg_4_1.target, var_0_11)

		arg_4_1.target:addBuffs(var_4_4)
	end
end

function var_0_3.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	if arg_5_0:isDeath() then
		return var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	end

	if arg_5_1.attackType == var_0_2.AttackType.AD and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_5_0:isCreatingUnits() ~= true and var_0_2.weightedChoise({
		var_0_2.tables.battleConfig.helixRate,
		1 - var_0_2.tables.battleConfig.helixRate
	}) == 1 then
		arg_5_0:specialAttack()
	end

	if arg_5_0.skinSkillID_ == var_0_11 and arg_5_2 > 0 then
		local var_5_0 = arg_5_0:createNewBuffs({
			var_0_13
		}, arg_5_0, var_0_11)

		arg_5_0:addBuffs(var_5_0)
	end

	return var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	local var_6_0 = arg_6_1.target

	if (arg_6_1.skillID == arg_6_0:getEnergySkillID() or arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)) and var_6_0:getHp() / var_6_0:getHpLimit() <= var_0_2.tables.battleConfig.axeSkillHpLimit + arg_6_0.energyExtraRate_ then
		arg_6_4 = arg_6_4 * var_0_2.tables.battleConfig.axeSkillHarmRate
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.specialAttack(arg_7_0)
	if (arg_7_0.specialInterval_ or 0) > 0 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_7_0.specialInterval_ = var_0_2.tables.battleConfig.specialSkillInterval

	local var_7_0

	if arg_7_0.skinSkillID_ == var_0_10 then
		var_7_0 = var_0_10
	else
		var_7_0 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	end

	local var_7_1 = var_0_5:sound(var_7_0)

	var_0_1.ctx.battle.pushSoundQueue(var_7_1)

	local var_7_2 = var_0_5:attackIndex(var_7_0)

	arg_7_0:playAttack(var_7_2)

	arg_7_0.unitSkills_ = var_0_8.new({
		fighter = arg_7_0,
		skillID = var_7_0
	})

	arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)
end

function var_0_3.getOrbOfFrontSkill(arg_8_0)
	local var_8_0 = var_0_3.super.getOrbOfFrontSkill(arg_8_0)

	if var_8_0 == arg_8_0:getEnergySkillID() and arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		return arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	else
		return var_8_0
	end
end

function var_0_3.energyAction(arg_9_0, arg_9_1)
	if arg_9_1 == arg_9_0:getEnergySkillID() or arg_9_1 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		arg_9_0:getFighterModel():playEnergyEffect_()
		arg_9_0:updateEnergyTo(arg_9_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		if arg_9_0:getTeamType() == var_0_2.TeamType.A or arg_9_0.isInArena_ then
			arg_9_0:addBlackLayer()
		end
	end
end

return var_0_3
