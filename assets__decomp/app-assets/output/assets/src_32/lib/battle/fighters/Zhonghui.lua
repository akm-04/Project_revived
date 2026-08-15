local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhonghui", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 10000508
local var_0_7 = 1000
local var_0_8 = 200
local var_0_9 = 50
local var_0_10 = 1
local var_0_11 = 0.3
local var_0_12 = 60
local var_0_13 = 10000506
local var_0_14 = 10000507
local var_0_15 = 50
local var_0_16 = 0.5
local var_0_17 = 40010305
local var_0_18 = 40010306

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.count_ = false
	arg_1_0.accumulateHarm_ = 0
	arg_1_0.criticalHp_ = 0
	arg_1_0.energyTarget_ = nil
	arg_1_0.energySelfTarget_ = nil
	arg_1_0.energyHarmCount_ = 0
end

function var_0_3.isBreakImmortal(arg_2_0)
	if arg_2_0.unitSkills_ and arg_2_0.unitSkills_.rootID_ == arg_2_0:getEnergySkillID() then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_2_0)
	end
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getEnergySkillID() then
		arg_3_0:choseSelfTarget()
		arg_3_0:choseEnemyTarget()
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_0:getEnergySkillID() == arg_4_1.skillID and arg_4_0.energyTarget_ and not arg_4_0.energyTarget_:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = {
			arg_4_0.energyTarget_
		}
		local var_4_1 = arg_4_0:createAttackUnits(var_4_0, var_0_13)

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end
end

function var_0_3.choseEnemyTarget(arg_5_0)
	local var_5_0
	local var_5_1

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and (not iter_5_1:isAffected() or not not iter_5_1:isInvisible()) and not iter_5_1:isBoss() and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_5_2 = iter_5_1:getAD()

			if not var_5_0 or var_5_0 < var_5_2 then
				var_5_1 = iter_5_1
				var_5_0 = var_5_2
			end
		end
	end

	arg_5_0.energyTarget_ = var_5_1
end

function var_0_3.getEnergySkillPreTime(arg_6_0)
	return 15
end

function var_0_3.choseSelfTarget(arg_7_0)
	local var_7_0
	local var_7_1

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None and iter_7_1 ~= arg_7_0 then
			local var_7_2 = iter_7_1:getHp() / iter_7_1:getHpLimit()

			if var_7_2 <= var_0_11 and (not var_7_0 or var_7_2 < var_7_0) then
				var_7_1 = iter_7_1
				var_7_0 = var_7_2
			end
		end
	end

	arg_7_0.energySelfTarget_ = var_7_1

	if var_7_1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_3 = arg_7_0:createAttackUnits({
			var_7_1
		}, var_0_14)

		for iter_7_2, iter_7_3 in ipairs(var_7_3) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
			table.insert(arg_7_0.records_.special_units, iter_7_3)
		end
	end

	arg_7_0.energyHarmCount_ = var_0_12
end

function var_0_3.die(arg_8_0)
	var_0_3.super.die(arg_8_0)

	if arg_8_0.energyTarget_ and not arg_8_0.energyTarget_:isDeath() then
		arg_8_0.energyTarget_:removeBuffByID(var_0_17)

		arg_8_0.energyTarget_ = nil
	end

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		arg_8_0:blueAttack()
	end
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	if arg_9_0.energyTarget_ then
		if arg_9_0.energyTarget_:isHasBuffByID(var_0_17) and arg_9_1.killer_ == arg_9_0.energyTarget_ and arg_9_1:getSummonType() == var_0_2.summonMonsterType.None then
			arg_9_0.energyTarget_:removeBuffByID(var_0_17)

			arg_9_0.energyTarget_ = nil
		end

		if arg_9_1 == arg_9_0.energyTarget_ then
			arg_9_0.energyTarget_ = nil

			if arg_9_0.unitSkills_ and arg_9_0.unitSkills_.rootID_ == arg_9_0:getEnergySkillID() then
				arg_9_0:skillIsBreak()

				arg_9_0.energySelfTarget_ = nil
				arg_9_0.energyHarmCount_ = 0
			end
		end
	end

	if arg_9_0.energySelfTarget_ and arg_9_0.energySelfTarget_ == arg_9_1 and arg_9_0.energySelfTarget_.killer_ ~= arg_9_0 then
		arg_9_0:addEnergyBuff()
	end
end

function var_0_3.addEnergyBuff(arg_10_0)
	local var_10_0 = arg_10_0:getEnergySkillID()
	local var_10_1 = var_0_5.new({
		tableID = var_0_18,
		start = var_0_1.ctx.battle.count,
		level = arg_10_0:getSkillLevelByID(var_10_0),
		skillID = var_10_0,
		fighter = arg_10_0,
		target = arg_10_0
	})

	var_10_1:setIsHit(true)
	var_10_1:setDirection(arg_10_0:getFighterModel():getFlipX())

	var_10_1.manualDharm = arg_10_0.energySelfTarget_:getHpLimit() * (var_0_15 + var_0_16 * arg_10_0:getSkillLevelByID(var_10_0)) * 0.01 * var_0_11

	arg_10_0:addBuffs({
		var_10_1
	})

	arg_10_0.energySelfTarget_ = nil
end

function var_0_3.applyHurtFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5)
	if not arg_11_0:isDeath() and arg_11_1.attackType == var_0_2.AttackType.AD and arg_11_2 > 0 and arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		local var_11_0 = arg_11_0:getADJianShang()

		arg_11_0.accumulateHarm_ = math.min(arg_11_0.criticalHp_, arg_11_0.accumulateHarm_ + arg_11_2 / var_11_0 * 0.2)
	end

	return var_0_3.super.applyHurtFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5)
end

function var_0_3.toDoPerFrames(arg_12_0)
	if arg_12_0:isDeath() then
		return
	end

	if not arg_12_0.count_ then
		arg_12_0.count_ = true

		local var_12_0 = arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		if var_12_0 > 0 then
			arg_12_0.criticalHp_ = var_0_7 + var_0_8 * var_12_0
		end
	end

	if arg_12_0.energyHarmCount_ > 0 then
		arg_12_0.energyHarmCount_ = arg_12_0.energyHarmCount_ - 1

		if arg_12_0.energyHarmCount_ % 15 == 0 and arg_12_0.energySelfTarget_ and not arg_12_0.energySelfTarget_:isDeath() then
			if arg_12_0.energyHarmCount_ ~= 0 then
				arg_12_0.energySelfTarget_:updateHp(arg_12_0.energySelfTarget_:getHp() * 0.5)
				arg_12_0.energySelfTarget_:updateEnergyByHarm(arg_12_0.energySelfTarget_:getHp() * 0.5)
			else
				arg_12_0.energySelfTarget_.killer_ = arg_12_0

				arg_12_0.energySelfTarget_:updateHp(0)
				arg_12_0.energySelfTarget_:die()

				local var_12_1 = arg_12_0.energySelfTarget_:getHalfKillMp()

				if var_12_1 and var_0_2.weightedChoise({
					var_12_1,
					1 - var_12_1
				}) == 1 then
					arg_12_0.fighterModel:playFloatText({
						var_0_2.BattleFloatType.KILL_GIFT
					}, arg_12_0:getTeamType())
					arg_12_0:updateEnergyBy(arg_12_0:getKillingMp() / 2)
				else
					arg_12_0:updateEnergyBy(arg_12_0:getKillingMp())
					arg_12_0.fighterModel:playFloatText({
						var_0_2.BattleFloatType.KILLING
					}, arg_12_0:getTeamType())
				end

				arg_12_0:addEnergyBuff()
			end
		end

		if not arg_12_0.unitSkills_ or arg_12_0.unitSkills_.rootID_ ~= arg_12_0:getEnergySkillID() then
			arg_12_0.energySelfTarget_ = nil
			arg_12_0.energyHarmCount_ = 0
			arg_12_0.energyTarget_ = nil
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
	if arg_13_1.skillID == var_0_6 then
		local var_13_0 = arg_13_4

		arg_13_4 = arg_13_4 + arg_13_0.accumulateHarm_ * (var_0_9 + var_0_10 * arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)) * 0.01
	end

	return var_0_3.super.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
end

function var_0_3.blueAttack(arg_14_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_14_0 = {}
	local var_14_1 = var_0_4:scope(var_0_6)

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() and math.abs(iter_14_1:getX() - arg_14_0:getX()) <= var_14_1 * 0.5 then
			table.insert(var_14_0, iter_14_1)
		end
	end

	local var_14_2 = arg_14_0:createAttackUnits(var_14_0, var_0_6)

	for iter_14_2, iter_14_3 in ipairs(var_14_2) do
		table.insert(arg_14_0.moveAttackUnits_, iter_14_3)
		table.insert(arg_14_0.records_.special_units, iter_14_3)
	end
end

function var_0_3.canUseEnergy(arg_15_0)
	if arg_15_0.energyTarget_ and arg_15_0.energyTarget_:isHasBuffByID(var_0_17) then
		return false
	end

	local var_15_0 = false

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.selfTeam_) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and iter_15_1:getSummonType() == var_0_2.summonMonsterType.None and iter_15_1 ~= arg_15_0 and iter_15_1:getHp() / iter_15_1:getHpLimit() <= var_0_11 then
			var_15_0 = true

			break
		end
	end

	if var_15_0 then
		for iter_15_2, iter_15_3 in ipairs(arg_15_0.sideTeam_) do
			if not iter_15_3:isDeath() and not iter_15_3:isAffected() and not iter_15_3:isBoss() and iter_15_3:getSummonType() == var_0_2.summonMonsterType.None then
				return true
			end
		end

		return false
	else
		return false
	end
end

function var_0_3.checkEnergySkill(arg_16_0)
	if var_0_3.super.checkEnergySkill(arg_16_0) then
		if arg_16_0:canUseEnergy() then
			return true
		end
	else
		return false
	end
end

return var_0_3
