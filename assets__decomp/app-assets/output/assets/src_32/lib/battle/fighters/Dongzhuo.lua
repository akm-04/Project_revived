local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dongzhuo", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 40010979
local var_0_10 = 0.3
local var_0_11 = 0.8

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skinCureCount_ = 0
	arg_1_0.skinTargetHarm_ = {}
	arg_1_0.skinTarget_ = {}
	arg_1_0.skinMaxCureJudge_ = false
	arg_1_0.maxCureToHarm = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isSkinSkillOn_ and not arg_2_0.skinMaxCureJudge_ then
		arg_2_0.skinMaxCureJudge_ = true
		arg_2_0.maxCureToHarm = arg_2_0:getHpLimit() * var_0_11
	end

	if arg_2_0.skinCureCount_ > 0 and not arg_2_0:isHasBuffByID(var_0_9) then
		local var_2_0 = arg_2_0:newBuff({
			var_0_9
		}, arg_2_0, arg_2_0.skinSkillID_)

		arg_2_0:addBuffs(var_2_0)
	end
end

function var_0_3.getUnitData(arg_3_0, arg_3_1)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.getUnitData(arg_3_0, arg_3_1)

	if arg_3_0.isSkinSkillOn_ and var_3_3 > 0 and arg_3_0.skinCureCount_ < arg_3_0.maxCureToHarm then
		arg_3_0.skinCureCount_ = arg_3_0.skinCureCount_ + var_3_3 * var_0_10

		if arg_3_0.skinCureCount_ > arg_3_0.maxCureToHarm then
			arg_3_0.skinCureCount_ = arg_3_0.maxCureToHarm
		end
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.selectTargetByTypeD2(arg_4_0)
	local var_4_0
	local var_4_1

	for iter_4_0, iter_4_1 in pairs(var_0_1.ctx.battle.teamA) do
		if not iter_4_1:isDeath() and (not var_4_0 or var_4_1 > iter_4_1:getHp() / iter_4_1:getHpLimit() or var_4_1 == iter_4_1:getHp() / iter_4_1:getHpLimit() and var_4_0:getHp() > iter_4_1:getHp()) then
			var_4_0 = iter_4_1
			var_4_1 = var_4_0:getHp() / var_4_0:getHpLimit()
		end
	end

	for iter_4_2, iter_4_3 in pairs(var_0_1.ctx.battle.teamB) do
		if not iter_4_3:isDeath() and (not var_4_0 or var_4_1 > iter_4_3:getHp() / iter_4_3:getHpLimit() or var_4_1 == iter_4_3:getHp() / iter_4_3:getHpLimit() and var_4_0:getHp() > iter_4_3:getHp()) then
			var_4_0 = iter_4_3
			var_4_1 = var_4_0:getHp() / var_4_0:getHpLimit()
		end
	end

	if var_4_0 then
		return {
			var_4_0
		}
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD3(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}
	local var_5_1 = arg_5_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	for iter_5_0, iter_5_1 in ipairs(var_5_1) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and math.abs(iter_5_1:getX() - arg_5_2.target:getX()) < var_0_6:scope(arg_5_1) / 2 then
			table.insert(var_5_0, iter_5_1)
		end
	end

	return var_5_0
end

function var_0_3.createUnits(arg_6_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0.unitSkills_
		local var_6_1 = var_6_0.rootID_

		if var_6_1 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
			local var_6_2 = arg_6_0:selectTargetByTypeD2()
			local var_6_3 = var_0_6:selectChildren(var_6_1)

			if var_6_2[1] and var_6_2[1]:getTeamType() == arg_6_0:getTeamType() then
				local var_6_4 = var_6_3[1]

				var_6_0.idQueue_ = {
					var_6_4
				}
				var_6_0.pretimeQueue_ = {
					0
				}
			elseif var_6_2[1] and var_6_2[1]:getTeamType() ~= arg_6_0:getTeamType() then
				local var_6_5 = var_6_3[2]

				var_6_0.idQueue_ = {
					var_6_5
				}
				var_6_0.pretimeQueue_ = {
					0
				}
			else
				return
			end
		end
	end

	var_0_3.super.createUnits(arg_6_0)
end

function var_0_3.buffRemoveAction(arg_7_0, arg_7_1)
	if arg_7_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_7_0 = arg_7_1:getRemoveSkill()
	local var_7_1 = arg_7_0:selectTargetByTypeD3(var_7_0, arg_7_1)
	local var_7_2 = arg_7_0:createAttackUnits(var_7_1, var_7_0)

	for iter_7_0, iter_7_1 in ipairs(var_7_2) do
		table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
		table.insert(arg_7_0.records_.special_units, iter_7_1)
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_1.skillID == arg_8_0.skinSkillID_ and var_8_2 > 0 and next(arg_8_0.skinTargetHarm_) then
		var_8_2 = var_8_2 + arg_8_0.skinTargetHarm_[1]

		table.remove(arg_8_0.skinTargetHarm_, 1)
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.newBuff(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		local var_9_1 = var_0_5.new({
			tableID = iter_9_1,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(arg_9_3),
			skillID = arg_9_3,
			fighter = arg_9_0,
			target = arg_9_2
		})

		var_9_1:setIsHit(true)
		var_9_1:setDirection(arg_9_0:getFighterModel():getFlipX())
		table.insert(var_9_0, var_9_1)
	end

	return var_9_0
end

function var_0_3.deathFeedback(arg_10_0, arg_10_1)
	var_0_3.super.deathFeedback(arg_10_0, arg_10_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_10_0.isSkinSkillOn_ and arg_10_0.skinCureCount_ > 0 and arg_10_1:getTeamType() == arg_10_0:getTeamType() and arg_10_1:getSummonType() == var_0_2.summonMonsterType.None and arg_10_1.killer_ and not arg_10_1.killer_:isAffected() and arg_10_1.killer_:getTeamType() ~= arg_10_0:getTeamType() and not arg_10_0:isCreatingUnits() then
		table.insert(arg_10_0.skinTarget_, arg_10_1.killer_)
		table.insert(arg_10_0.skinTargetHarm_, arg_10_0.skinCureCount_)
		arg_10_0:removeBuffByID(var_0_9)

		arg_10_0.skinCureCount_ = 0

		local var_10_0 = arg_10_0.skinSkillID_
		local var_10_1 = var_0_6:sound(var_10_0)

		var_0_1.ctx.battle.pushSoundQueue(var_10_1)

		local var_10_2 = var_0_6:attackIndex(var_10_0)

		arg_10_0:playAttack(var_10_2)

		arg_10_0.unitSkills_ = var_0_4.new({
			fighter = arg_10_0,
			skillID = var_10_0
		})

		arg_10_0:beginAttackEnd(arg_10_0.unitSkills_)
	end
end

function var_0_3.selectTargetByTypeD1(arg_11_0)
	if next(arg_11_0.skinTarget_) then
		local var_11_0 = arg_11_0.skinTarget_[1]

		table.remove(arg_11_0.skinTarget_, 1)

		return {
			var_11_0
		}
	end

	return {}
end

return var_0_3
