local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wenchou", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 5
local var_0_10 = 20010099
local var_0_11 = 20010100
local var_0_12 = 10000354
local var_0_13 = 10000165
local var_0_14 = 10000164
local var_0_15 = 9
local var_0_16 = 1
local var_0_17 = 0
local var_0_18 = 1
local var_0_19 = 0
local var_0_20 = 0
local var_0_21 = 0.02

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energySkilled_ = nil
	arg_1_0.leftCount_ = nil
	arg_1_0.shanbiCount_ = 0
	arg_1_0.harmSkills_ = {}
	arg_1_0.harmBuffs_ = {}
	arg_1_0.extraAp_ = 0
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	if arg_2_0.leftCount_ and not arg_2_0:isDeath() then
		arg_2_0.leftCount_ = math.max(arg_2_0.leftCount_ - 1, 0)

		if arg_2_0.leftCount_ < 1 then
			arg_2_0:energySkillAttack()
		end
	end

	arg_2_0.shanbiCount_ = math.max(arg_2_0.shanbiCount_ - 1, 0)
end

function var_0_3.die(arg_3_0)
	var_0_3.super.die(arg_3_0)

	local var_3_0 = arg_3_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_3_0, iter_3_1 in ipairs(var_3_0) do
		if not iter_3_1:isDeath() or iter_3_1:canReborn() then
			iter_3_1:removeBuffByID(var_0_10)
			iter_3_1:removeBuffByID(var_0_11)
		end
	end
end

function var_0_3.addBuffs(arg_4_0, arg_4_1)
	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_4_0 = var_0_16 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_17

		for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
			if iter_4_1.fighter:getTeamType() ~= arg_4_0:getTeamType() and (iter_4_1:isApUnable() or iter_4_1:isAdUnable()) then
				if arg_4_0.harmBuffs_[tostring(iter_4_1:getTableID())] then
					iter_4_1.leftCount_ = var_4_0 * iter_4_1:getTime()
				end

				arg_4_0.harmBuffs_[tostring(iter_4_1:getTableID())] = true
			end
		end
	end

	var_0_3.super.addBuffs(arg_4_0, arg_4_1)
end

function var_0_3.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	if var_0_6:father(arg_5_1.skillID) == arg_5_0:getEnergySkillID() and arg_5_1.fighter == arg_5_0 then
		arg_5_0.energySkilled_ = true

		if not arg_5_0.leftCount_ then
			arg_5_0.leftCount_ = 0
		end
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_5_0.harmSkills_[tostring(arg_5_1.skillID)] then
			local var_5_0 = var_0_18 + arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_19

			if arg_5_1.fighter:isBoss() then
				var_5_0 = 1 - (1 - var_5_0) * 0.3
			end

			arg_5_2 = var_5_0 * arg_5_2
		end

		arg_5_0.harmSkills_[tostring(arg_5_1.skillID)] = true
	end

	return var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
end

function var_0_3.dodge(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_6_0.shanbiCount_ < 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

		if arg_6_4 <= var_0_6:init(var_6_0) + var_0_6:step(var_6_0) * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) and arg_6_4 > 0 then
			arg_6_0.shanbiCount_ = var_0_15 * var_0_1.ctx.battleConst.frames
			arg_6_0.harmSkills_[tostring(arg_6_1.skillID)] = true

			arg_6_0:specialAttack(arg_6_1.fighter)

			local var_6_1 = {
				arg_6_0
			}
			local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_0_14)

			for iter_6_0, iter_6_1 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end

			arg_6_1.records_.doge = true

			return true
		end
	end

	return false
end

function var_0_3.specialAttack(arg_7_0, arg_7_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_7_1:isDeath() or arg_7_1:isAffected() then
		return
	end

	if arg_7_0.isEnergySkill_ and arg_7_0:isCreatingUnits() then
		return
	end

	if arg_7_0.energySkilled_ ~= true then
		return
	end

	local var_7_0 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_7_1 = var_0_6:sound(var_7_0)

	var_0_1.ctx.battle.pushSoundQueue(var_7_1)

	local var_7_2 = var_0_6:attackIndex(var_7_0)

	arg_7_0:playAttack(var_7_2)

	arg_7_0.unitSkills_ = var_0_5.new({
		fighter = arg_7_0,
		skillID = var_7_0
	})

	arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)

	arg_7_0.manualTarget_ = {
		arg_7_1
	}
	arg_7_0.extraAp_ = arg_7_0.extraAp_ + arg_7_0:getEnergy() * (var_0_21 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_20)

	arg_7_0:updateEnergyTo(0)
end

function var_0_3.energySkillAttack(arg_8_0)
	if arg_8_0:isDeath() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_8_0.leftCount_ = var_0_9 * var_0_1.ctx.battleConst.frames

	local var_8_0 = var_0_12
	local var_8_1 = var_0_4.B2(arg_8_0, var_8_0)
	local var_8_2 = arg_8_0:createAttackUnits(var_8_1, var_8_0)

	for iter_8_0, iter_8_1 in ipairs(var_8_2) do
		table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
		table.insert(arg_8_0.records_.special_units, iter_8_1)
	end

	local var_8_3 = arg_8_0:createAttackUnits({
		arg_8_0
	}, var_0_13)

	for iter_8_2, iter_8_3 in ipairs(var_8_3) do
		table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
		table.insert(arg_8_0.records_.special_units, iter_8_3)
	end
end

function var_0_3.checkEnergySkill(arg_9_0)
	if arg_9_0.energySkilled_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_9_0)
end

function var_0_3.getAP(arg_10_0)
	return arg_10_0.extraAp_ + var_0_3.super.getAP(arg_10_0)
end

return var_0_3
