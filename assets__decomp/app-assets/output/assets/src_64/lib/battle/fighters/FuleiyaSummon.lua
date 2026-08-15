local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("FuleiyaSummon", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = 0.003
local var_0_7 = 1.5
local var_0_8 = 0.3
local var_0_9 = 0.005

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and (arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_1_1.skillID == arg_1_0:getPugongID()) then
		arg_1_7 = arg_1_7 - var_0_7 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

function var_0_3.updateUnitDataByTarget(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7 = var_0_3.super.updateUnitDataByTarget(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		local var_2_0 = var_0_6 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		if var_0_2.weightedChoise({
			var_2_0,
			1 - var_2_0
		}) == 1 then
			arg_2_2 = true
		end
	end

	return arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7
end

function var_0_3.getAttrByType(arg_3_0, arg_3_1)
	if arg_3_0.summoner then
		if arg_3_1 == var_0_2.AttributeType.HP or arg_3_1 == var_0_2.AttributeType.AD then
			local var_3_0 = arg_3_0.summoner.getAttrByType(arg_3_0.summoner, arg_3_1)
			local var_3_1

			return var_3_0 * (var_0_8 + var_0_9 * arg_3_0.summoner.getSkillLevelByColor(arg_3_0, var_0_2.SKILL_INDEX.Energy))
		else
			return arg_3_0.summoner.getAttrByType(arg_3_0.summoner, arg_3_1)
		end
	end

	return 10
end

return var_0_3
