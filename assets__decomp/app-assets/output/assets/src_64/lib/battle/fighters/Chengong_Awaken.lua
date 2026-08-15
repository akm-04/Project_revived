local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chengong", var_0_1.ctx.battle.requireFighter("Chengong"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10001488
local var_0_7 = 10001489
local var_0_8 = 0
local var_0_9 = 6
local var_0_10 = 1.5
local var_0_11 = 1.5

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.extraHarmBlueSkillTime = 0
	arg_1_0.extraHarmGreenSkillTime = 0
end

function var_0_3.getOrbOfFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getOrbOfFrontSkill(arg_2_0)

	if var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		return 51010020
	elseif var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		return 21010020
	elseif var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		return 31010020
	elseif var_2_0 == arg_2_0:getPugongID() then
		return 11010020
	end

	return var_2_0
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	local var_3_0 = arg_3_1.target

	if var_0_5:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_1 = arg_3_0:createAttackUnits({
			var_3_0
		}, var_0_6)

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	elseif var_0_5:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_2 = arg_3_0:createAttackUnits({
			var_3_0
		}, var_0_7)

		for iter_3_2, iter_3_3 in ipairs(var_3_2) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end

	if arg_3_4 > 0 then
		for iter_3_4, iter_3_5 in ipairs(var_3_0:getBuffs()) do
			if iter_3_5:dBuffType() == var_0_2.DBuffType.ZHI_MANG then
				arg_3_4 = arg_3_4 + var_0_8 + var_0_9 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

				break
			end
		end
	end

	if var_0_5:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_4 > 0 then
		arg_3_4 = arg_3_4 + var_0_10 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * arg_3_0.extraHarmGreenSkillTime
		arg_3_0.extraHarmGreenSkillTime = arg_3_0.extraHarmGreenSkillTime + 1
	end

	if var_0_5:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_4 > 0 then
		arg_3_4 = arg_3_4 + var_0_11 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * arg_3_0.extraHarmBlueSkillTime
		arg_3_0.extraHarmBlueSkillTime = arg_3_0.extraHarmBlueSkillTime + 1
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
