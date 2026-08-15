local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dongzhuo", var_0_1.ctx.battle.requireFighter("HideBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = 40010979
local var_0_11 = 0.3
local var_0_12 = 0.8
local var_0_13 = 10001210
local var_0_14 = 40011304
local var_0_15 = 0.1
local var_0_16 = 80040003

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skinCureCount_ = 0
	arg_1_0.skinTargetHarm_ = {}
	arg_1_0.skinTarget_ = {}
	arg_1_0.skinMaxCureJudge_ = false
	arg_1_0.maxCureToHarm = 0
	arg_1_0.energyHarm = 0
	arg_1_0.energyTargets = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isSkinSkillOn_ and not arg_2_0.skinMaxCureJudge_ then
		arg_2_0.skinMaxCureJudge_ = true
		arg_2_0.maxCureToHarm = arg_2_0:getHpLimit() * var_0_12
	end

	if arg_2_0.skinCureCount_ > 0 and not arg_2_0:isHasBuffByID(var_0_10) then
		local var_2_0 = arg_2_0:newBuff({
			var_0_10
		}, arg_2_0, arg_2_0.skinSkillID_)

		arg_2_0:addBuffs(var_2_0)
	end
end

function var_0_3.applyHurtFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5)
	if arg_3_1.attackType == var_0_2.AttackType.AP and arg_3_0:isHasBuffByID(var_0_14) then
		arg_3_0.energyHarm = arg_3_0.energyHarm + arg_3_2
		arg_3_2 = 0
		arg_3_3 = 0
	end

	return var_0_3.super.applyHurtFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5)
end

function var_0_3.getUnitData(arg_4_0, arg_4_1)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.getUnitData(arg_4_0, arg_4_1)

	if arg_4_0.isSkinSkillOn_ and var_4_3 > 0 and arg_4_0.skinCureCount_ < arg_4_0.maxCureToHarm then
		arg_4_0.skinCureCount_ = arg_4_0.skinCureCount_ + var_4_3 * var_0_11

		if arg_4_0.skinCureCount_ > arg_4_0.maxCureToHarm then
			arg_4_0.skinCureCount_ = arg_4_0.maxCureToHarm
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.selectTargetByTypeD2(arg_5_0)
	local var_5_0
	local var_5_1

	for iter_5_0, iter_5_1 in pairs(var_0_1.ctx.battle.teamB) do
		if not iter_5_1:isDeath() and (not var_5_0 or var_5_1 > iter_5_1:getHp() / iter_5_1:getHpLimit() or var_5_1 == iter_5_1:getHp() / iter_5_1:getHpLimit() and var_5_0:getHp() > iter_5_1:getHp()) then
			var_5_0 = iter_5_1
			var_5_1 = var_5_0:getHp() / var_5_0:getHpLimit()
		end
	end

	if var_5_0 then
		return {
			var_5_0
		}
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD3(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}
	local var_6_1 = arg_6_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	for iter_6_0, iter_6_1 in ipairs(var_6_1) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and math.abs(iter_6_1:getX() - arg_6_2.target:getX()) < var_0_7:scope(arg_6_1) / 2 then
			table.insert(var_6_0, iter_6_1)
		end
	end

	return var_6_0
end

function var_0_3.createUnits(arg_7_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = arg_7_0.unitSkills_
		local var_7_1 = var_7_0.rootID_

		if var_7_1 == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
			local var_7_2 = arg_7_0:selectTargetByTypeD2()
			local var_7_3 = var_0_7:selectChildren(var_7_1)

			if var_7_2[1] and var_7_2[1]:getTeamType() == arg_7_0:getTeamType() then
				local var_7_4 = var_7_3[1]

				var_7_0.idQueue_ = {
					var_7_4
				}
				var_7_0.pretimeQueue_ = {
					0
				}
			elseif var_7_2[1] and var_7_2[1]:getTeamType() ~= arg_7_0:getTeamType() then
				local var_7_5 = var_7_3[2]

				var_7_0.idQueue_ = {
					var_7_5
				}
				var_7_0.pretimeQueue_ = {
					0
				}
			else
				return
			end
		end
	end

	var_0_3.super.createUnits(arg_7_0)
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_1:getTableID() == var_0_14 then
		arg_8_0.energyHarm = 0
	end
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	if arg_9_1:getTableID() == var_0_14 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_9_0.energyTargets = var_0_5.B2(arg_9_0, var_0_13)

		local var_9_0 = arg_9_0:createAttackUnits(arg_9_0.energyTargets, var_0_13)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end

	if arg_9_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_9_1 = arg_9_1:getRemoveSkill()
	local var_9_2 = arg_9_0:selectTargetByTypeD3(var_9_1, arg_9_1)
	local var_9_3 = arg_9_0:createAttackUnits(var_9_2, var_9_1)

	for iter_9_2, iter_9_3 in ipairs(var_9_3) do
		table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
		table.insert(arg_9_0.records_.special_units, iter_9_3)
	end
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_1.skillID == arg_10_0.skinSkillID_ and var_10_2 > 0 and next(arg_10_0.skinTargetHarm_) then
		var_10_2 = var_10_2 + arg_10_0.skinTargetHarm_[1]

		table.remove(arg_10_0.skinTargetHarm_, 1)
	elseif arg_10_1.skillID == var_0_13 and #arg_10_0.energyTargets ~= 0 then
		var_10_2 = arg_10_0.energyHarm * var_0_15 / #arg_10_0.energyTargets
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

function var_0_3.newBuff(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_1) do
		local var_11_1 = var_0_6.new({
			tableID = iter_11_1,
			start = var_0_1.ctx.battle.count,
			level = arg_11_0:getSkillLevelByID(arg_11_3),
			skillID = arg_11_3,
			fighter = arg_11_0,
			target = arg_11_2
		})

		var_11_1:setIsHit(true)
		var_11_1:setDirection(arg_11_0:getFighterModel():getFlipX())
		table.insert(var_11_0, var_11_1)
	end

	return var_11_0
end

function var_0_3.deathFeedback(arg_12_0, arg_12_1)
	var_0_3.super.deathFeedback(arg_12_0, arg_12_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_12_0.isSkinSkillOn_ and arg_12_0.skinCureCount_ > 0 and arg_12_1:getTeamType() == arg_12_0:getTeamType() and arg_12_1:getSummonType() == var_0_2.summonMonsterType.None and arg_12_1.killer_ and not arg_12_1.killer_:isAffected() and arg_12_1.killer_:getTeamType() ~= arg_12_0:getTeamType() and not arg_12_0:isCreatingUnits() then
		table.insert(arg_12_0.skinTarget_, arg_12_1.killer_)
		table.insert(arg_12_0.skinTargetHarm_, arg_12_0.skinCureCount_)
		arg_12_0:removeBuffByID(var_0_10)

		arg_12_0.skinCureCount_ = 0

		local var_12_0 = arg_12_0.skinSkillID_
		local var_12_1 = var_0_7:sound(var_12_0)

		var_0_1.ctx.battle.pushSoundQueue(var_12_1)

		local var_12_2 = var_0_7:attackIndex(var_12_0)

		arg_12_0:playAttack(var_12_2)

		arg_12_0.unitSkills_ = var_0_4.new({
			fighter = arg_12_0,
			skillID = var_12_0
		})

		arg_12_0:beginAttackEnd(arg_12_0.unitSkills_)
	end
end

function var_0_3.selectTargetByTypeD1(arg_13_0)
	if next(arg_13_0.skinTarget_) then
		local var_13_0 = arg_13_0.skinTarget_[1]

		table.remove(arg_13_0.skinTarget_, 1)

		return {
			var_13_0
		}
	end

	return {}
end

return var_0_3
