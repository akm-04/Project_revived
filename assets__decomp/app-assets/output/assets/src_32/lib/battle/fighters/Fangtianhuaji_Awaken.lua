local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fangtianhuaji", var_0_1.ctx.battle.requireFighter("Fangtianhuaji"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40010188
local var_0_8 = 120
local var_0_9 = 10
local var_0_10 = 101
local var_0_11 = 0.2
local var_0_12 = 40011359

function var_0_3.applyHurtFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5)
	if arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_1_1.attackType == var_0_2.AttackType.AP and arg_1_2 > arg_1_0:getHpLimit() * var_0_11 and arg_1_1.fighter:isHasBuffByID(var_0_12) then
		arg_1_2 = 0

		arg_1_1.fighter:removeBuffByID(var_0_12)
		arg_1_0:createSkillByID(arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green), arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), var_0_6:attackIndex(arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)))
	end

	return var_0_3.super.applyHurtFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5)
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if var_0_6:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_2_2 > 0 and arg_2_1.target.hero_:getHeroType() == var_0_2.AttributeType.WISE and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		var_2_2 = var_2_2 + math.min(math.max(arg_2_0:getAttrByType(var_0_2.AttributeType.AGILE) - arg_2_1.target:getAttrByType(var_0_2.AttributeType.AGILE), 0) * var_0_9, var_0_10 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and not arg_2_1.target:isBoss() then
			local var_2_6 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_2_0, iter_2_1 in ipairs(var_2_6) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	var_0_3.super.buffAddAction(arg_3_0, arg_3_1)

	if arg_3_1:getTableID() == var_0_7 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_1.target.hero_:getHeroType() == var_0_2.AttributeType.WISE then
		arg_3_1:setExtraTime(var_0_8)
	end
end

return var_0_3
