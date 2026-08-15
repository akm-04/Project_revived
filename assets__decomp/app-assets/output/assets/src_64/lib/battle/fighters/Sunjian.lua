local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunjian", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 20010246
local var_0_7 = 20010247
local var_0_8 = {
	10000349,
	10000351,
	10000350
}
local var_0_9 = 300

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("born_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyBuffTarget_ = nil
	arg_2_0.eatSummonMonsters_ = {}
	arg_2_0.eatSummonMonsterInterval_ = 0
end

function var_0_3.die(arg_3_0)
	var_0_3.super.die(arg_3_0)
	arg_3_0:removeTargetBuff()
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("born_info")) do
		if iter_4_1:getTeamType() ~= arg_4_0:getTeamType() and (iter_4_1:getSummonType() == var_0_2.summonMonsterType.Monster or iter_4_1:getSummonType() == var_0_2.summonMonsterType.Copy) then
			table.insert(arg_4_0.eatSummonMonsters_, iter_4_1)
		end
	end

	arg_4_0.eatSummonMonsterInterval_ = arg_4_0.eatSummonMonsterInterval_ - 1

	if arg_4_0.eatSummonMonsterInterval_ < 1 then
		arg_4_0:specialAttack()
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_5_0:countAliveHeros() and var_5_2 > 0 then
		var_5_2 = var_5_2 * 2
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.countAliveHeros(arg_6_0)
	local var_6_0 = 0
	local var_6_1 = 0

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_6_0 = var_6_0 + 1
		end
	end

	for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_3:isDeath() and iter_6_3:getSummonType() == var_0_2.summonMonsterType.None then
			var_6_1 = var_6_1 + 1
		end
	end

	return var_6_1 <= var_6_0, var_6_0, var_6_1
end

function var_0_3.energyDecimalBase(arg_7_0)
	return var_0_2.ENERGY_DECIMAL_BASE * 0.5
end

function var_0_3.getDMP(arg_8_0)
	return arg_8_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE * var_0_2.PERCENT_BASE
end

function var_0_3.checkEnergySkill(arg_9_0)
	if arg_9_0.energyBuffTarget_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_9_0)
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)

	local var_10_0 = arg_10_1.target
	local var_10_1 = var_0_5:father(arg_10_1.skillID)

	if not var_10_0:isDeath() and var_10_1 == arg_10_0:getEnergySkillID() then
		arg_10_0.energyBuffTarget_ = var_10_0
	end

	if arg_10_1.skillID == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_10_0:purpleSkill(var_0_8[var_10_0.hero_:getHeroType()])
	end
end

function var_0_3.purpleSkill(arg_11_0, arg_11_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_11_0 = arg_11_0:createAttackUnits({
		arg_11_0
	}, arg_11_1)

	for iter_11_0, iter_11_1 in ipairs(var_11_0) do
		table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
		table.insert(arg_11_0.records_.special_units, iter_11_1)
	end
end

function var_0_3.checkUnitBuffs(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1.target
	local var_12_1
	local var_12_2
	local var_12_3
	local var_12_4
	local var_12_5

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_12_1, var_12_2, var_12_3, var_12_4, var_12_5 = arg_12_1:getReportBuffs()
	else
		var_12_1, var_12_2, var_12_3, var_12_4, var_12_5 = arg_12_1:getBuffs(arg_12_2)

		if var_12_0:isBoss() then
			for iter_12_0 = #var_12_1, 1, -1 do
				if var_12_1[iter_12_0]:getTableID() == var_0_6 then
					table.remove(var_12_1, iter_12_0)
				end
			end
		end

		arg_12_1:recordBuff(var_12_1, var_12_2, var_12_3, var_12_4, var_12_5)
	end

	return var_12_1, var_12_2, var_12_3, var_12_4, var_12_5
end

function var_0_3.getCountReMp(arg_13_0)
	if arg_13_0.energyBuffTarget_ then
		if arg_13_0.energyBuffTarget_:isDeath() or arg_13_0:getEnergy() <= 100 then
			arg_13_0:removeTargetBuff()

			return 0
		end

		return -100
	end

	return 0
end

function var_0_3.removeTargetBuff(arg_14_0)
	if arg_14_0.energyBuffTarget_ and not arg_14_0.energyBuffTarget_:isDeath() then
		arg_14_0.energyBuffTarget_:removeBuffByID(var_0_6)
		arg_14_0.energyBuffTarget_:removeBuffByID(var_0_7)
	end

	arg_14_0.energyBuffTarget_ = nil
end

function var_0_3.specialAttack(arg_15_0)
	if arg_15_0:isDeath() or arg_15_0:isInSkillRoll() or arg_15_0.isEnergySkill_ or arg_15_0:isBattleUnable() or arg_15_0:isCreatingUnits() or next(arg_15_0.eatSummonMonsters_) == nil then
		return
	end

	local var_15_0 = false

	for iter_15_0 = #arg_15_0.eatSummonMonsters_, 1, -1 do
		local var_15_1 = arg_15_0.eatSummonMonsters_[iter_15_0]

		if var_15_1:isDeath() then
			table.remove(arg_15_0.eatSummonMonsters_, iter_15_0)
		end

		if not var_15_1:isDeath() and not var_15_1:isAffected() then
			var_15_0 = true

			break
		end
	end

	if not var_15_0 then
		return
	end

	arg_15_0.eatSummonMonsterInterval_ = var_0_9

	local var_15_2 = arg_15_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_15_3 = var_0_5:sound(var_15_2)

	var_0_1.ctx.battle.pushSoundQueue(var_15_3)

	local var_15_4 = var_0_5:attackIndex(var_15_2)

	arg_15_0:playAttack(var_15_4)

	arg_15_0.unitSkills_ = var_0_4.new({
		fighter = arg_15_0,
		skillID = var_15_2
	})

	arg_15_0:beginAttackEnd(arg_15_0.unitSkills_)
end

function var_0_3.selectTargetByTypeD1(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0
	local var_16_1

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.targetTeam_) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() and (not var_16_0 or var_16_1 < iter_16_1:getEnergy()) then
			var_16_0 = iter_16_1
			var_16_1 = iter_16_1:getEnergy()
		end
	end

	return var_16_0 and {
		var_16_0
	} or {}
end

function var_0_3.selectTargetByTypeD2(arg_17_0, arg_17_1, arg_17_2)
	for iter_17_0 = #arg_17_0.eatSummonMonsters_, 1, -1 do
		local var_17_0 = arg_17_0.eatSummonMonsters_[iter_17_0]

		if not var_17_0:isDeath() and not var_17_0:isAffected() then
			return {
				var_17_0
			}
		end
	end

	return {}
end

return var_0_3
