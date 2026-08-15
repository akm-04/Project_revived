local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guojia", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = 10010161
local var_0_6 = 10010159
local var_0_7 = 10000367
local var_0_8 = 10000370
local var_0_9 = 10000371
local var_0_10 = 0
local var_0_11 = 0.05
local var_0_12 = 80010095
local var_0_13 = 80020095
local var_0_14 = 15
local var_0_15 = 200

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.ratio = 0
	arg_1_0.possessTarget = nil
	arg_1_0.judgeGreen_ = false
	arg_1_0.skinStoredEnergy = 0
	arg_1_0.skin2StoredEnergy = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_8 then
		arg_2_0.fighterModel:setVisible(false)

		arg_2_0.possessTarget = arg_2_1.target
	elseif arg_2_1.skillID == var_0_9 then
		arg_2_0.judgeGreen_ = false
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_2_1.target:isPugongOnly() then
		arg_2_0:cureSelf()
	end
end

function var_0_3.fliterBuffs(arg_3_0, arg_3_1)
	if arg_3_0:isBreakImmortal() and arg_3_1[1]:getTableID() == var_0_5 then
		return arg_3_1
	else
		return var_0_3.super.fliterBuffs(arg_3_0, arg_3_1)
	end
end

function var_0_3.isBreakImmortal(arg_4_0)
	if arg_4_0:isHasBuffByID(var_0_5) then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_4_0)
	end
end

function var_0_3.cureSelf(arg_5_0)
	local var_5_0 = {
		arg_5_0
	}
	local var_5_1 = arg_5_0:createAttackUnits(var_5_0, var_0_7)

	for iter_5_0, iter_5_1 in ipairs(var_5_1) do
		table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
		table.insert(arg_5_0.records_.special_units, iter_5_1)
	end
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}
	local var_6_1 = arg_6_0:getAP()

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_1 > iter_6_1:getAP() then
			table.insert(var_6_0, iter_6_1)
		end
	end

	return var_6_0
end

function var_0_3.getFrontSkill(arg_7_0)
	local var_7_0 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)

	if arg_7_0:isPugongOnly() then
		return arg_7_0:getPugongID()
	end

	if arg_7_0.isEnergySkill_ and arg_7_0:getEnergySkillID() > 0 then
		return arg_7_0:getEnergySkillID()
	end

	if next(arg_7_0.startSkillQueue_) then
		if arg_7_0.startSkillQueue_[1] == var_7_0 and arg_7_0:isPossessed() then
			return arg_7_0:getPugongID()
		else
			return arg_7_0.startSkillQueue_[1]
		end
	end

	if arg_7_0.skillQueue_[1] == var_7_0 and arg_7_0:isPossessed() then
		return arg_7_0:getPugongID()
	else
		return arg_7_0.skillQueue_[1]
	end
end

function var_0_3.toDoPerFrames(arg_8_0)
	if not arg_8_0.judgeGreen_ and arg_8_0:isHasBuffByID(var_0_5) then
		local function var_8_0()
			for iter_9_0, iter_9_1 in ipairs(arg_8_0.sideTeam_) do
				if not iter_9_1:isDeath() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None and iter_9_1 ~= arg_8_0.possessTarget then
					return false
				end
			end

			return true
		end

		if not arg_8_0.possessTarget or arg_8_0.possessTarget:isBoss() or var_8_0() then
			if arg_8_0.possessTarget then
				arg_8_0.possessTarget:removeBuffByID(var_0_6)
			end

			arg_8_0:removeBuffByID(var_0_5)

			arg_8_0.possessTarget = nil
		end

		arg_8_0.judgeGreen_ = true
	end

	if arg_8_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count > 0 and var_0_1.ctx.battle.count % 30 < 1 then
		if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			local var_8_1 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
			local var_8_2 = var_0_11 * var_8_1 + var_0_10

			arg_8_0.ratio = arg_8_0.ratio + var_8_2

			for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
				if not iter_8_1:isDeath() and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
					local var_8_3 = iter_8_1:getEnergyDecrease() + var_8_2

					iter_8_1:setEnergyDecrease(var_8_3)
				end
			end
		end

		if arg_8_0.skinSkillID_ == var_0_13 then
			for iter_8_2, iter_8_3 in ipairs(arg_8_0.sideTeam_) do
				if not iter_8_3:isDeath() and not iter_8_3:isAffected() and iter_8_3:isPugongOnly() then
					local var_8_4 = iter_8_3.pugongOnlyBuffs_

					for iter_8_4, iter_8_5 in ipairs(var_8_4) do
						if iter_8_5.fighter:getTeamType() == arg_8_0:getTeamType() then
							iter_8_3:updateEnergyBy(-var_0_14)

							arg_8_0.skin2StoredEnergy = arg_8_0.skin2StoredEnergy + var_0_14

							if arg_8_0.skin2StoredEnergy >= var_0_15 then
								arg_8_0.skin2StoredEnergy = 0

								local var_8_5
								local var_8_6

								for iter_8_6, iter_8_7 in ipairs(arg_8_0.selfTeam_) do
									if not iter_8_3:isDeath() and not iter_8_3:isAffected() and (not var_8_5 or var_8_6 > iter_8_7:getEnergy()) then
										var_8_5 = iter_8_7
										var_8_6 = iter_8_7:getEnergy()
									end
								end

								if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
									local var_8_7 = arg_8_0:createAttackUnits({
										var_8_5
									}, var_0_13)

									for iter_8_8, iter_8_9 in ipairs(var_8_7) do
										table.insert(arg_8_0.moveAttackUnits_, iter_8_9)
										table.insert(arg_8_0.records_.special_units, iter_8_9)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function var_0_3.deathFeedback(arg_10_0, arg_10_1)
	var_0_3.super.deathFeedback(arg_10_0, arg_10_1)

	if arg_10_0.possessTarget and arg_10_1 == arg_10_0.possessTarget then
		arg_10_0:removeBuffByID(var_0_5)
	end
end

function var_0_3.removeBuffs(arg_11_0, arg_11_1)
	if arg_11_1:getTableID() == var_0_5 then
		arg_11_0.possessTarget = nil

		arg_11_0.fighterModel:setVisible(true)
	end

	var_0_3.super.removeBuffs(arg_11_0, arg_11_1)
end

function var_0_3.die(arg_12_0)
	var_0_3.super.die(arg_12_0)

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.selfTeam_) do
		if not iter_12_1:isDeath() and iter_12_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_12_0 = iter_12_1:getEnergyDecrease() - arg_12_0.ratio

			iter_12_1:setEnergyDecrease(var_12_0)
		end
	end
end

function var_0_3.forceDie(arg_13_0)
	if arg_13_0.skinSkillID_ == var_0_12 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_13_0 = arg_13_0:createAttackUnits(var_0_4.A2(arg_13_0, var_0_12), var_0_12)

		for iter_13_0, iter_13_1 in ipairs(var_13_0) do
			table.insert(arg_13_0.moveAttackUnits_, iter_13_1)
			table.insert(arg_13_0.records_.special_units, iter_13_1)
		end
	end

	var_0_3.super.forceDie(arg_13_0)
end

function var_0_3.updateUnitDataByFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7 = var_0_3.super.updateUnitDataByFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)

	if arg_14_1.skillID == var_0_12 and #var_0_4.A2(arg_14_0, var_0_12) > 0 then
		arg_14_7 = arg_14_7 + arg_14_0.skinStoredEnergy / #var_0_4.A2(arg_14_0, var_0_12)
	end

	return arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7
end

function var_0_3.selectTargetByTypeD2(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {}
	local var_15_1
	local var_15_2 = -1

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.sideTeam_) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and not iter_15_1:isBreakImmortal() and iter_15_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_15_3 = iter_15_1:getAttrByType(var_0_2.AttributeType.WISE)

			if var_15_2 < var_15_3 then
				var_15_0 = {}
				var_15_2 = var_15_3

				table.insert(var_15_0, iter_15_1)
			elseif var_15_3 == var_15_2 then
				table.insert(var_15_0, iter_15_1)
			end
		end
	end

	if #var_15_0 > 1 then
		var_15_1 = var_15_0[math.random(1, #var_15_0)]
	else
		var_15_1 = var_15_0[1]
	end

	return {
		var_15_1
	}
end

function var_0_3.updateEnergyBy(arg_16_0, arg_16_1, arg_16_2)
	var_0_3.super.updateEnergyBy(arg_16_0, arg_16_1, arg_16_2)

	if arg_16_0.skinSkillID_ == var_0_12 and arg_16_0:isHasBuffByID(var_0_5) and arg_16_1 > 0 then
		arg_16_0.skinStoredEnergy = arg_16_0.skinStoredEnergy + arg_16_1
	end
end

return var_0_3
