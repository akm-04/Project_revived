local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Miheng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10
local var_0_8 = 150
local var_0_9 = 450
local var_0_10 = 0.5
local var_0_11 = 2
local var_0_12 = 1.5
local var_0_13 = 10000616
local var_0_14 = 300
local var_0_15 = 40010525
local var_0_16 = 0.1
local var_0_17 = 0.004
local var_0_18 = 40010526
local var_0_19 = {
	40010519,
	40010520
}
local var_0_20 = 5
local var_0_21 = 0.1
local var_0_22 = 0.005
local var_0_23 = 0.05
local var_0_24 = 80010137
local var_0_25 = 10001558
local var_0_26 = 40011615
local var_0_27 = 0.25
local var_0_28 = 0.5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isBerserker_ = false
	arg_1_0.berserkerCount_ = 0
	arg_1_0.purpleCount_ = 0
	arg_1_0.extraHp_ = 0
	arg_1_0.madBuffCount_ = 0
	arg_1_0.purpleReflectTarget_ = {}
	arg_1_0.purpleReflectTargetCD_ = {}
	arg_1_0.isPurpled_ = false
	arg_1_0.isPurpleImmortal_ = false
	arg_1_0.showMad_ = false
	arg_1_0.records_.stun_hit = {}
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_1:getTableID() == var_0_15 then
		if not arg_2_0.isBerserker_ then
			arg_2_0:updateMadBuff(1)
		else
			arg_2_0.berserkerCount_ = arg_2_0.berserkerCount_ + 30
		end
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.showMad_ then
		arg_3_0:updateStateNumber(arg_3_0.madBuffCount_)

		arg_3_0.showMad_ = true
		arg_3_0.extraHp_ = arg_3_0:getHpLimit() * var_0_10
	end

	for iter_3_0, iter_3_1 in pairs(arg_3_0.purpleReflectTargetCD_) do
		if iter_3_1 > 0 then
			arg_3_0.purpleReflectTargetCD_[iter_3_0] = arg_3_0.purpleReflectTargetCD_[iter_3_0] - 1
		end
	end

	if arg_3_0.berserkerCount_ > 0 then
		arg_3_0.berserkerCount_ = arg_3_0.berserkerCount_ - 1

		local var_3_0 = arg_3_0.skinSkillID_ == var_0_24 and var_0_26 or var_0_18

		if arg_3_0.berserkerCount_ == 0 or not arg_3_0:isHasBuffByID(var_3_0) then
			arg_3_0.berserkerCount_ = 0
			arg_3_0.isBerserker_ = false

			for iter_3_2, iter_3_3 in ipairs(var_0_19) do
				arg_3_0:removeBuffByID(iter_3_3)
			end

			arg_3_0:removeBuffByID(var_3_0)

			arg_3_0.hpLimit_ = arg_3_0:getHpLimit() - arg_3_0.extraHp_

			local var_3_1 = math.min(arg_3_0:getHp(), arg_3_0.hpLimit_)

			arg_3_0:updateHp(var_3_1)
		end
	end

	if arg_3_0.purpleCount_ > 0 then
		arg_3_0.purpleCount_ = arg_3_0.purpleCount_ - 1

		if arg_3_0.purpleCount_ == 0 then
			arg_3_0.isPurpleImmortal_ = false
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if arg_4_1.target:isDeath() then
			if not arg_4_0.isBerserker_ then
				arg_4_0:updateMadBuff(1)
			else
				local var_4_0 = arg_4_0:newBuff(var_0_19, arg_4_0, arg_4_1.skillID)

				arg_4_0:addBuffs(var_4_0)

				local var_4_1 = var_0_6:attackIndex(arg_4_1.skillID)

				arg_4_0:playAttack(var_4_1)

				arg_4_0.unitSkills_ = var_0_4.new({
					fighter = arg_4_0,
					skillID = arg_4_1.skillID
				})

				arg_4_0:beginAttackEnd(arg_4_0.unitSkills_)
			end
		end
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_4_2
		local var_4_3 = var_0_2.split(arg_4_1.target.fighterIndex, "|")
		local var_4_4 = tostring(var_4_3[2])

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_4_0.stunHit_[var_4_4] and arg_4_0.stunHit_[var_4_4][tostring(var_0_1.ctx.battle.count)] then
				var_4_2 = true
			end
		else
			local var_4_5 = var_0_16 + var_0_17 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

			if arg_4_0.isBerserker_ then
				var_4_5 = var_4_5 + 0.1
			end

			if arg_4_0.skinSkillID_ == var_0_24 then
				if arg_4_0.isBerserker_ then
					var_4_5 = var_4_5 + var_0_28
				else
					var_4_5 = var_4_5 + var_0_27
				end
			end

			var_4_2 = var_0_2.weightedChoise({
				var_4_5,
				1 - var_4_5
			}) == 1

			if var_4_2 then
				if not arg_4_0.records_.stun_hit[var_4_4] then
					arg_4_0.records_.stun_hit[var_4_4] = {}
				end

				arg_4_0.records_.stun_hit[var_4_4][tostring(var_0_1.ctx.battle.count)] = true
			end
		end

		if var_4_2 then
			local var_4_6 = arg_4_0:newBuff({
				var_0_15
			}, arg_4_1.target, arg_4_1.skillID)

			arg_4_1.target:addBuffs(var_4_6)
		else
			arg_4_1.target.fighterModel:playFloatText({
				var_0_2.BattleFloatType.BUFF_MISS
			}, arg_4_1.target:getTeamType())
		end
	elseif arg_4_1.skillID == arg_4_0:getEnergySkillID() or arg_4_1.skillID == var_0_25 then
		arg_4_0.isBerserker_ = true

		local var_4_7 = arg_4_0.skinSkillID_ == var_0_24 and var_0_26 or var_0_18
		local var_4_8 = arg_4_0:newBuff({
			var_4_7
		}, arg_4_0, arg_4_0:getEnergySkillID())

		arg_4_0:addBuffs(var_4_8)

		arg_4_0.hpLimit_ = arg_4_0:getHpLimit() + arg_4_0.extraHp_

		arg_4_0:updateHp(arg_4_0:getHp() + arg_4_0.extraHp_)

		arg_4_0.berserkerCount_ = var_0_9
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_0.isBerserker_ then
		arg_5_4 = arg_5_4 * var_0_11
	end

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_5_4 = arg_5_4 + (arg_5_0.purpleReflectTarget_[arg_5_1.target] or 0) * (var_0_21 + var_0_22 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.updateUnitDataByTarget(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	if arg_6_0.isBerserker_ then
		arg_6_4 = arg_6_4 * var_0_12
	end

	return var_0_3.super.updateUnitDataByTarget(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
end

function var_0_3.die(arg_7_0)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_7_0.isPurpled_ then
		arg_7_0:updateHp(1)

		arg_7_0.isPurpled_ = true
		arg_7_0.isPurpleImmortal_ = true
		arg_7_0.purpleCount_ = var_0_8

		return
	end

	var_0_3.super.die(arg_7_0)

	if arg_7_0:isDeath() and arg_7_0.isBerserker_ then
		arg_7_0:energyDieAttack()
	end
end

function var_0_3.updateMadBuff(arg_8_0, arg_8_1)
	if arg_8_0.isBerserker_ or arg_8_0:isDeath() then
		return
	end

	arg_8_0.madBuffCount_ = math.min(var_0_7, arg_8_0.madBuffCount_ + arg_8_1)

	arg_8_0:updateStateNumber(arg_8_0.madBuffCount_)
end

function var_0_3.applyBuffHarm(arg_9_0)
	local var_9_0 = 0
	local var_9_1 = 0
	local var_9_2 = 0
	local var_9_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_0, var_9_1, var_9_2 = unpack(arg_9_0.reportBuffHarms_[tostring(var_0_1.ctx.battle.count)] or {
			0,
			0,
			0
		})
	else
		for iter_9_0 = #arg_9_0.buffs_, 1, -1 do
			local var_9_4 = arg_9_0.buffs_[iter_9_0]

			if var_9_4:getType() == var_0_2.BuffType.CONTINUE_HARM and not arg_9_0.isPurpleImmortal_ then
				local var_9_5 = var_9_4:getHarm() * var_9_4.fighter:getBuffHarmRate()

				var_9_0 = var_9_0 + var_9_5
				var_9_3 = var_9_4.fighter

				if var_9_4:getHarm() > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					var_9_3:updateHarms(var_9_5)
				end

				var_9_2 = var_9_2 + var_9_4:getMana()
			elseif var_9_4:getType() == var_0_2.BuffType.GAIN or var_9_4:getType() == var_0_2.BuffType.REVIVIE then
				var_9_1 = var_9_1 + var_9_4:getHarm()
			end
		end

		var_9_1 = var_9_1 * arg_9_0:getDCureRate()

		if var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.GUILD and arg_9_0:getTeamType() == var_0_2.TeamType.B then
			var_9_1 = 0
		end

		arg_9_0.records_.buff_harms[tostring(var_0_1.ctx.battle.count)] = {
			var_9_0,
			var_9_1,
			var_9_2
		}
	end

	if var_9_1 == 0 and var_9_0 == 0 and var_9_2 == 0 then
		return
	end

	local var_9_6 = math.max(0, arg_9_0:getHp() - var_9_0 + var_9_1)

	if var_9_1 - var_9_0 > 0 then
		var_9_6 = math.min(arg_9_0:getHp() - var_9_0 + var_9_1, arg_9_0:getHpLimit())
	end

	if var_9_1 ~= 0 then
		arg_9_0.cureHp = arg_9_0.cureHp + var_9_1
	end

	if var_9_0 - var_9_1 > 0 and next(arg_9_0.shieldBuffs_) then
		local var_9_7 = arg_9_0.shieldBuffs_[1]
		local var_9_8 = arg_9_0.shieldBuffs_[1].fighter
		local var_9_9 = var_9_7:getShieldNum() - 1

		if var_9_0 - var_9_1 > var_9_7:getShieldMaxHarm() then
			var_9_6 = math.max(0, arg_9_0:getHp() - var_9_0 + var_9_1 + var_9_7:getShieldMaxHarm())

			arg_9_0:updateHp(var_9_6)
		end

		if var_9_9 <= 0 then
			arg_9_0:removeBuffByID(var_9_7:getTableID())
		else
			var_9_7:setShieldNum(var_9_9)
		end

		var_9_8:shieldFeedBack(arg_9_0, var_9_7)
	else
		arg_9_0:updateHp(var_9_6)
	end

	arg_9_0:updateEnergyTo(arg_9_0:getEnergy() + var_9_2)
	arg_9_0:setOriHurt(var_9_0)

	return var_9_3
end

function var_0_3.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
	if arg_10_2 > 0 and arg_10_1.attackType ~= var_0_2.AttackType.CURE and arg_10_0.isPurpleImmortal_ then
		local var_10_0 = arg_10_1.fighter

		if not arg_10_1.fighter:isAffected() and (not arg_10_0.purpleReflectTargetCD_[var_10_0] or arg_10_0.purpleReflectTargetCD_[var_10_0] <= 0) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_10_1 = arg_10_0:createAttackUnits({
				var_10_0
			}, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_10_0, iter_10_1 in ipairs(var_10_1) do
				table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
				table.insert(arg_10_0.records_.special_units, iter_10_1)
			end

			arg_10_0.purpleReflectTarget_[arg_10_1.fighter] = arg_10_2
			arg_10_0.purpleReflectTargetCD_[arg_10_1.fighter] = var_0_20
		end

		arg_10_2 = 0

		local var_10_2 = arg_10_1.attackType == var_0_2.AttackType.AD and var_0_2.BattleFloatType.AD_IMMORTAL or var_0_2.BattleFloatType.AP_IMMORTAL

		arg_10_0.fighterModel:playFloatText({
			var_10_2
		}, arg_10_0:getTeamType())
	end

	return var_0_3.super.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {}
	local var_11_1 = var_0_6:scope(arg_11_1)

	if arg_11_0.isBerserker_ then
		var_11_1 = var_11_1 + var_0_14
	end

	local var_11_2 = arg_11_0:getFlipX() == true and -1 or 1

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.targetTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
			local var_11_3 = (iter_11_1:getX() - arg_11_0:getX()) * var_11_2

			if var_11_3 <= var_11_1 and var_11_3 > 0 then
				table.insert(var_11_0, iter_11_1)
			end
		end
	end

	return var_11_0
end

function var_0_3.energyDieAttack(arg_12_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_12_0 = {}
		local var_12_1 = var_0_6:scope(var_0_13)

		for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
			if not iter_12_1:isDeath() and not iter_12_1:isAffected() and math.abs(iter_12_1:getX() - arg_12_0:getX()) <= 0.5 * var_12_1 then
				table.insert(var_12_0, iter_12_1)
			end
		end

		local var_12_2 = arg_12_0:createAttackUnits(var_12_0, var_0_13)

		for iter_12_2, iter_12_3 in ipairs(var_12_2) do
			table.insert(arg_12_0.moveAttackUnits_, iter_12_3)
			table.insert(arg_12_0.records_.special_units, iter_12_3)
		end
	end
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_1 = var_0_5.new({
			tableID = iter_13_1,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0:getSkillLevelByID(arg_13_3),
			skillID = arg_13_3,
			fighter = arg_13_0,
			target = arg_13_2
		})

		var_13_1:setIsHit(true)
		var_13_1:setDirection(arg_13_0:getFighterModel():getFlipX())
		table.insert(var_13_0, var_13_1)
	end

	return var_13_0
end

function var_0_3.setupReport(arg_14_0, arg_14_1)
	var_0_3.super.setupReport(arg_14_0, arg_14_1)

	arg_14_0.stunHit_ = arg_14_1.stun_hit
end

function var_0_3.writeReport(arg_15_0)
	local var_15_0 = var_0_3.super.writeReport(arg_15_0)

	var_15_0.stun_hit = arg_15_0.records_.stun_hit

	return var_15_0
end

function var_0_3.getAD(arg_16_0)
	return arg_16_0:getAttrByType(var_0_2.AttributeType.AD) * (1 + arg_16_0.madBuffCount_ * var_0_23)
end

function var_0_3.checkEnergySkill(arg_17_0)
	if arg_17_0.isBerserker_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_17_0)
	end
end

return var_0_3
