local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yangxiu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0.1
local var_0_6 = 0.005
local var_0_7 = 5
local var_0_8 = 10000510
local var_0_9 = {
	40010322,
	40010323,
	{
		40010324,
		40010330
	},
	{
		40010325,
		40010331
	},
	40010326
}
local var_0_10 = {
	40010316,
	40010317,
	40010318,
	40010319,
	40010320,
	40010321
}
local var_0_11 = 40011140
local var_0_12 = 0.6
local var_0_13 = 0.15
local var_0_14 = 300
local var_0_15 = 80010117
local var_0_16 = 10001040
local var_0_17 = var_0_2.tables.elementEquip
local var_0_18 = 20001481
local var_0_19 = 40012498
local var_0_20 = 10

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.selfPurpleLight_ = 0
	arg_1_0.lightedChess_ = 0
	arg_1_0.purpleHalo_ = nil
	arg_1_0.purpleSideHalo_ = nil
	arg_1_0.greenCure_ = nil
	arg_1_0.purpleJudge_ = false
	arg_1_0.greenCure_ = 0
	arg_1_0.isGreenCure_ = false
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_2_0.isGreenCure_ = false
	end

	if arg_2_0:hasElementEquipByID(var_0_18) then
		arg_2_0:updateEnergyBy(var_0_20)
	end
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)
	arg_3_0:skinSkill()
end

function var_0_3.skinSkill(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if not arg_4_0.isSkinSkillOn_ then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_1.ctx.battle.count > 0 and var_0_1.ctx.battle.count % var_0_14 == 0 then
		local var_4_0 = arg_4_0:getTargets(var_0_15)
		local var_4_1 = arg_4_0:createAttackUnits(var_4_0, var_0_15)

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if var_5_2 > 0 and arg_5_0.isSkinSkillOn_ and arg_5_1.fighter:getTeamType() and arg_5_1.fighter:getTeamType() ~= arg_5_0:getTeamType() and arg_5_1.target:getTeamType() == arg_5_0:getTeamType() and not arg_5_1.target:isDeath() and not arg_5_1.target:isAffected() and arg_5_1.target:isHasBuffByID(var_0_11) and var_5_2 > arg_5_1.fighter:getHpLimit() * var_0_12 and not var_5_0 then
		var_5_2 = arg_5_1.fighter:getHpLimit() * var_0_13

		local var_5_6 = arg_5_0:createAttackUnits({
			arg_5_1.target
		}, var_0_16)

		for iter_5_0, iter_5_1 in ipairs(var_5_6) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.die(arg_6_0)
	if arg_6_0.isSkinSkillOn_ then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
			if not iter_6_1:isDeath() and iter_6_1:isHasBuffByID(var_0_11) then
				iter_6_1:removeBuffByID(var_0_11)
			end
		end
	end

	var_0_3.super.die(arg_6_0)
end

function var_0_3.toDoPerFrames(arg_7_0)
	if not arg_7_0.purpleJudge_ then
		if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_7_0:addLightBuff(0)
		end

		arg_7_0.purpleJudge_ = true
	end

	if arg_7_0.greenCure_ > 0 and not arg_7_0.unitSkills_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and not arg_7_0.isGreenCure_ then
		local var_7_0
		local var_7_1

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
				local var_7_2 = iter_7_1:getHp() / iter_7_1:getHpLimit()

				if not var_7_1 or var_7_2 < var_7_1 then
					var_7_0 = iter_7_1
					var_7_1 = var_7_2
				end
			end
		end

		local var_7_3 = arg_7_0:createAttackUnits({
			var_7_0
		}, var_0_8)

		for iter_7_2, iter_7_3 in ipairs(var_7_3) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
			table.insert(arg_7_0.records_.special_units, iter_7_3)
		end

		arg_7_0.isGreenCure_ = true
	end

	if arg_7_0:hasElementEquipByID(var_0_18) and not arg_7_0.hasAddElementBuff then
		local var_7_4 = arg_7_0:createNewBuffs({
			var_0_19
		}, arg_7_0, arg_7_0:getEnergySkillID())

		arg_7_0:addBuffs(var_7_4)

		arg_7_0.hasAddElementBuff = true
	end
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if arg_8_1.skillID == arg_8_0:getEnergySkillID() then
		arg_8_0:lightChess()
	elseif arg_8_1.skillID == var_0_16 and arg_8_1.target:isHasBuffByID(var_0_11) then
		arg_8_1.target:removeBuffByID(var_0_11)
	end
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	if arg_9_1.skillID == var_0_8 then
		arg_9_5 = arg_9_5 + arg_9_0.greenCure_ * (var_0_5 + var_0_6 * arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)) * arg_9_1.target:getDCureRate()
		arg_9_0.greenCure_ = 0
	end

	return var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
end

function var_0_3.lightChess(arg_10_0)
	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) <= 0 or arg_10_0.lightedChess_ >= var_0_7 then
		return
	end

	arg_10_0:removeBuffByID(var_0_10[arg_10_0.lightedChess_ + 1])

	arg_10_0.lightedChess_ = arg_10_0.lightedChess_ + 1

	arg_10_0:addLightBuff(arg_10_0.lightedChess_)

	if not arg_10_0.purpleHalo_ then
		local var_10_0 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_10_1 = {
			fighter = arg_10_0,
			effect_area = function()
				return true
			end,
			target_type = var_0_2.HaloEffect.selfTeam,
			buffs = {
				var_0_9[arg_10_0.lightedChess_]
			},
			level = arg_10_0:getSkillLevelByID(var_10_0),
			skillID = var_10_0
		}

		arg_10_0.purpleHalo_ = var_10_1

		arg_10_0:addBuffHalo(var_10_1)
	elseif arg_10_0.lightedChess_ ~= 5 then
		local var_10_2 = {}

		for iter_10_0 = 1, arg_10_0.lightedChess_ do
			if type(var_0_9[iter_10_0]) == "table" then
				for iter_10_1, iter_10_2 in ipairs(var_0_9[iter_10_0]) do
					table.insert(var_10_2, iter_10_2)
				end
			else
				table.insert(var_10_2, var_0_9[iter_10_0])
			end
		end

		arg_10_0.purpleHalo_.effect_hero = {}
		arg_10_0.purpleHalo_.buffs = var_10_2
	else
		local var_10_3 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_10_4 = {
			fighter = arg_10_0,
			effect_area = function()
				return true
			end,
			target_type = var_0_2.HaloEffect.sideTeam,
			buffs = {
				var_0_9[5]
			},
			level = arg_10_0:getSkillLevelByID(var_10_3),
			skillID = var_10_3
		}

		arg_10_0.purpleSideHalo_ = var_10_4

		arg_10_0:addBuffHalo(var_10_4)
	end
end

function var_0_3.deathFeedback(arg_13_0, arg_13_1)
	if arg_13_1:getSummonType() == var_0_2.summonMonsterType.None or arg_13_1:getSummonType() == var_0_2.summonMonsterType.Monster then
		if not arg_13_1.killer_ then
			return
		end

		if arg_13_1:getTeamType() ~= arg_13_0:getTeamType() then
			arg_13_0:lightChess()
		else
			arg_13_0.selfPurpleLight_ = arg_13_0.selfPurpleLight_ + 1

			if arg_13_0.selfPurpleLight_ >= 2 then
				arg_13_0.selfPurpleLight_ = 0

				arg_13_0:lightChess()
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {}
	local var_14_1
	local var_14_2

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() and iter_14_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_14_3 = iter_14_1:getHp() / iter_14_1:getHpLimit()

			if not var_14_1 or var_14_3 < var_14_1 then
				var_14_0 = {
					iter_14_1
				}
				var_14_1 = var_14_3
			elseif var_14_3 == var_14_1 then
				table.insert(var_14_0, iter_14_1)
			end
		end
	end

	if #var_14_0 > 1 then
		local var_14_4

		for iter_14_2, iter_14_3 in ipairs(var_14_0) do
			if not var_14_4 or var_14_4 < iter_14_3:getAD() then
				var_14_2 = iter_14_3
			end
		end
	else
		var_14_2 = unpack(var_14_0)
	end

	return {
		var_14_2
	}
end

function var_0_3.selectTargetByTypeD2(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0
	local var_15_1

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.sideTeam_) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and iter_15_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_15_2 = iter_15_1:getHp() / iter_15_1:getHpLimit()

			if not var_15_0 or var_15_0 < var_15_2 then
				var_15_1 = iter_15_1
				var_15_0 = var_15_2
			end
		end
	end

	return {
		var_15_1
	}
end

function var_0_3.addLightBuff(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_16_1 = var_0_4.new({
		tableID = var_0_10[arg_16_1 + 1],
		start = var_0_1.ctx.battle.count,
		level = arg_16_0:getSkillLevelByID(var_16_0),
		skillID = var_16_0,
		fighter = arg_16_0,
		target = arg_16_0
	})

	arg_16_0:addBuffs({
		var_16_1
	})
end

function var_0_3.afterDamageHarm(arg_17_0, arg_17_1, arg_17_2)
	var_0_3.super.afterDamageHarm(arg_17_0, arg_17_1, arg_17_2)

	if arg_17_2.skillID == arg_17_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_17_0.greenCure_ = arg_17_0.greenCure_ + arg_17_1
	end
end

function var_0_3.neverDieFeedBack(arg_18_0, arg_18_1)
	if arg_18_0:hasElementEquipByID(var_0_18) and not arg_18_0.hasSavedSelf then
		local var_18_0 = var_0_18
		local var_18_1 = var_0_17:battleAttr(var_18_0, arg_18_0:getElementEquipLevelByID(var_18_0)) * arg_18_0.hero_:getElementEquipActiveRate(var_18_0) * arg_18_0.lightedChess_

		arg_18_0:updateHp(arg_18_0:getHp() + var_18_1)

		arg_18_0.hasSavedSelf = true

		arg_18_0:clearBuffHalo()

		arg_18_0.purpleHalo_ = nil
		arg_18_0.purpleSideHalo_ = nil

		arg_18_0:removeBuffByID(var_0_10[arg_18_0.lightedChess_ + 1])

		arg_18_0.lightedChess_ = 0
		arg_18_0.purpleJudge_ = nil
	end
end

return var_0_3
