local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Luxifa", var_0_1.ctx.battle.requireFighter("Luxifa"))
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10001066
local var_0_7 = 0.1
local var_0_8 = 0.002
local var_0_9 = 0.2
local var_0_10 = 0.004
local var_0_11 = 450
local var_0_12 = {
	40012227,
	40012228
}
local var_0_13 = 0.04

function var_0_4.init(arg_1_0)
	var_0_4.super.init(arg_1_0)

	arg_1_0.rageState = false
	arg_1_0.awakeTwiceCount = 0
	arg_1_0.deathCount = 0
	arg_1_0.isAddAwakeBuffs = false
end

function var_0_4.populateWithHero(arg_2_0, arg_2_1)
	var_0_4.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 2 then
		arg_2_0.AwakeBuffIDs = {
			40012232,
			40011174,
			40011175,
			40011176
		}
	else
		arg_2_0.AwakeBuffIDs = {
			40011173,
			40011174,
			40011175,
			40011176
		}
	end
end

function var_0_4.toDoPerFrames(arg_3_0)
	var_0_4.super.toDoPerFrames(arg_3_0)

	if arg_3_0.deathCount >= 2 and not arg_3_0.rageState then
		arg_3_0.rageState = true
	end

	if arg_3_0.awakeTwiceCount > 0 then
		arg_3_0.awakeTwiceCount = arg_3_0.awakeTwiceCount - 1

		if arg_3_0.awakeTwiceCount == 0 then
			arg_3_0:removeRageState()
		end
	end

	if arg_3_0.rageState and not arg_3_0.isAddAwakeBuffs then
		arg_3_0.isAddAwakeBuffs = true

		local var_3_0 = arg_3_0:createNewBuffs(arg_3_0.AwakeBuffIDs, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake), arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

		if arg_3_0.extraSkillLevel2 > 0 then
			for iter_3_0, iter_3_1 in ipairs(var_3_0) do
				if iter_3_1:getAttrType() == var_0_2.AttributeType.AD_JIANSHANG or iter_3_1:getAttrType() == var_0_2.AttributeType.AP_JIANSHANG then
					iter_3_1.manualRevise = -arg_3_0.extraSkillLevel2 * var_0_13
				end
			end
		end

		arg_3_0:addBuffs(var_3_0)

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			local var_3_1 = arg_3_0:createNewBuffs(var_0_12, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice), arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			arg_3_0:addBuffs(var_3_1)
		end
	end
end

function var_0_4.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_4.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if var_4_2 > 0 then
		var_4_2 = var_4_2 + var_4_2 * (var_0_7 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_8)
	end

	local var_4_6 = var_0_9 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_10

	if var_4_2 > 0 and arg_4_1.skillID ~= var_0_6 and var_0_2.weightedChoise({
		var_4_6,
		1 - var_4_6
	}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_7 = arg_4_0:createAttackUnits({
			arg_4_1.target
		}, var_0_6)

		for iter_4_0, iter_4_1 in ipairs(var_4_7) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_4.deathFeedback(arg_5_0, arg_5_1)
	if not arg_5_0.rageState and arg_5_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_5_0.deathCount = arg_5_0.deathCount + 1
	end

	if arg_5_1.killer_ and arg_5_1.killer_ == arg_5_0 and arg_5_1:getSummonType() == var_0_2.summonMonsterType.None and arg_5_0.rageState then
		if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			arg_5_0.awakeTwiceCount = arg_5_0.awakeTwiceCount + var_0_11
		else
			arg_5_0:removeRageState()
		end
	end
end

function var_0_4.removeRageState(arg_6_0)
	arg_6_0.rageState = false
	arg_6_0.deathCount = 0
	arg_6_0.isAddAwakeBuffs = false

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.AwakeBuffIDs) do
		arg_6_0:removeBuffByID(iter_6_1)
	end

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		for iter_6_2, iter_6_3 in ipairs(var_0_12) do
			arg_6_0:removeBuffByID(iter_6_3)
		end
	end
end

return var_0_4
