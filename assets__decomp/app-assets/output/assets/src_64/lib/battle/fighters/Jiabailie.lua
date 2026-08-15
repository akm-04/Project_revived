local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiabailie", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 4
local var_0_8 = 40010714
local var_0_9 = 10000687
local var_0_10 = 10000682
local var_0_11 = 0.6
local var_0_12 = 10010152
local var_0_13 = 10000680
local var_0_14 = 10000681
local var_0_15 = 0.8
local var_0_16 = 10000686
local var_0_17 = 180
local var_0_18 = 60

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenHarmCount_ = 0
	arg_1_0.isGreenSkill_ = false
	arg_1_0.isEnergyType_ = false
	arg_1_0.greenSkillTarget_ = nil
	arg_1_0.energyDMpTimeCount_ = 0
	arg_1_0.energyReboundCd_ = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.energyDMpTimeCount_ > 0 then
		arg_2_0.energyDMpTimeCount_ = arg_2_0.energyDMpTimeCount_ - 1

		if arg_2_0.energyDMpTimeCount_ <= 0 then
			arg_2_0:setImmuneControl(false)
		end
	end

	if arg_2_0.isEnergyType_ and arg_2_0.energyDMpTimeCount_ <= 0 and arg_2_0:getNearestTarget() and var_0_1.ctx.battle.count % 30 < 1 then
		arg_2_0:updateEnergyTo(arg_2_0:getEnergy() - 100)

		if arg_2_0:getEnergy() < 1 then
			arg_2_0.isEnergyType_ = false

			local var_2_0 = var_0_6:buffs(arg_2_0:getEnergySkillID())

			for iter_2_0, iter_2_1 in ipairs(var_2_0) do
				arg_2_0:removeBuffByID(iter_2_1)
			end
		end
	end

	if arg_2_0.isGreenSkill_ and not arg_2_0:getBuffByID(var_0_8) then
		arg_2_0.isGreenSkill_ = false
		arg_2_0.greenHarmCount_ = 0

		arg_2_0:setImmuneControl(false)
	end

	if arg_2_0.isEnergyType_ then
		for iter_2_2, iter_2_3 in pairs(arg_2_0.energyReboundCd_) do
			if arg_2_0.energyReboundCd_[iter_2_2] and arg_2_0.energyReboundCd_[iter_2_2] <= 0 then
				arg_2_0.energyReboundCd_[iter_2_2] = nil
			elseif arg_2_0.energyReboundCd_[iter_2_2] > 0 then
				arg_2_0.energyReboundCd_[iter_2_2] = arg_2_0.energyReboundCd_[iter_2_2] - 1
			end
		end
	end
end

function var_0_3.getFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getFrontSkill(arg_3_0)

	if arg_3_0.isEnergyType_ and (var_3_0 == var_0_12 or var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) then
		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			var_3_0 = var_0_14
		else
			var_3_0 = var_0_13
		end
	end

	return var_3_0
end

function var_0_3.getDMP(arg_4_0)
	return arg_4_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE * var_0_2.PERCENT_BASE
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_5_0:setImmuneControl(true)

		arg_5_0.greenHarmCount_ = 0
		arg_5_0.isGreenSkill_ = true
	elseif arg_5_1.skillID == arg_5_0:getEnergySkillID() then
		arg_5_0.energyDMpTimeCount_ = var_0_17

		arg_5_0:setImmuneControl(true)

		arg_5_0.isEnergyType_ = true
	elseif arg_5_1.skillID == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:getGreenBeatTargets(arg_5_1.target)
		local var_5_1 = arg_5_0:createAttackUnits(var_5_0, var_0_10)

		for iter_5_0, iter_5_1 in ipairs(var_5_1) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.updateUnitDataByTarget(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if var_6_2 > 0 and arg_6_0.isGreenSkill_ and not arg_6_0:isCreatingUnits() and arg_6_1.fighter:getTeamType() ~= arg_6_0:getTeamType() then
		arg_6_0.greenHarmCount_ = arg_6_0.greenHarmCount_ + 1

		if arg_6_0.greenHarmCount_ >= var_0_7 then
			arg_6_0.greenSkillTarget_ = arg_6_1.fighter
			arg_6_0.greenHarmCount_ = 0

			if arg_6_1.fighter:getX() - arg_6_0:getX() < 0 then
				arg_6_0:flipX(true)
			else
				arg_6_0:flipX(false)
			end

			local var_6_6 = var_0_9
			local var_6_7 = var_0_6:sound(var_6_6)

			var_0_1.ctx.battle.pushSoundQueue(var_6_7)

			local var_6_8 = var_0_6:attackIndex(var_6_6)

			arg_6_0:playAttack(var_6_8)

			arg_6_0.unitSkills_ = var_0_5.new({
				fighter = arg_6_0,
				skillID = var_6_6
			})

			arg_6_0:beginAttackEnd(arg_6_0.unitSkills_)
		end
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	if arg_7_0:isDeath() then
		return var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	end

	if arg_7_2 > 0 and not arg_7_1.fighter:isAffected() and not arg_7_1.fighter:isDeath() and arg_7_0.isEnergyType_ and (not arg_7_0.energyReboundCd_[arg_7_1.target] or arg_7_0.energyReboundCd_[arg_7_1.target] <= 0) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = 1

		if arg_7_1.attackType == var_0_2.AttackType.AD then
			if arg_7_0:getADJianShang() > 1 then
				var_7_0 = 1
			else
				var_7_0 = arg_7_0:getADJianShang()
			end
		elseif arg_7_1.attackType == var_0_2.AttackType.AP then
			var_7_0 = arg_7_0:getAPJianShang() > 1 and 1 or arg_7_0:getAPJianShang()
		end

		arg_7_0.energyReboundCd_[arg_7_1.target] = var_0_18

		local var_7_1 = arg_7_2 / math.max(0.15, var_7_0) * var_0_11
		local var_7_2 = {
			arg_7_1.fighter
		}
		local var_7_3 = arg_7_0:createAttackUnits(var_7_2, var_0_16)

		for iter_7_0, iter_7_1 in ipairs(var_7_3) do
			iter_7_1.rebound_harm = var_7_1

			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	end

	return var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}

	if not arg_8_0.greenSkillTarget_ then
		return var_8_0
	end

	local var_8_1 = arg_8_0.greenSkillTarget_

	table.insert(var_8_0, var_8_1)

	return var_8_0
end

function var_0_3.getGreenBeatTargets(arg_9_0, arg_9_1)
	local var_9_0 = {}

	table.insert(var_9_0, arg_9_1)

	local var_9_1 = var_0_6:scope(var_0_10)

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if iter_9_1 ~= arg_9_1 and not iter_9_1:isDeath() and not iter_9_1:isAffected() and math.abs(iter_9_1:getX() - arg_9_1:getX()) <= var_9_1 * 0.5 then
			table.insert(var_9_0, iter_9_1)
		end
	end

	return var_9_0
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if var_10_2 > 0 and arg_10_1.skillID == var_0_16 and arg_10_1.rebound_harm and arg_10_1.rebound_harm > 0 then
		var_10_2 = arg_10_1.rebound_harm
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

function var_0_3.checkEnergySkill(arg_11_0)
	if arg_11_0.isEnergyType_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_11_0)
end

function var_0_3.energyDecimalBase(arg_12_0)
	return var_0_2.ENERGY_DECIMAL_BASE * var_0_15
end

return var_0_3
