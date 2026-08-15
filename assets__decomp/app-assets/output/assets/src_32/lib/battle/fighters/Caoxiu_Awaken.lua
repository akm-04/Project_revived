local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caoxiu", var_0_1.ctx.battle.requireFighter("Caoxiu"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 0
local var_0_6 = 0.5
local var_0_7 = 0.2
local var_0_8 = 80

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if var_0_4:father(arg_1_1.skillID) == arg_1_0:getEnergySkillID() and arg_1_1.target:getTeamType() ~= arg_1_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_0 = arg_1_0:createAttackUnits({
			arg_1_1.target
		}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end

		if arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_1_1.target:getSummonType() ~= var_0_2.summonMonsterType.Copy then
			local var_1_1 = arg_1_0:createAttackUnits({
				arg_1_0
			}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_1_2, iter_1_3 in ipairs(var_1_1) do
				table.insert(arg_1_0.moveAttackUnits_, iter_1_3)
				table.insert(arg_1_0.records_.special_units, iter_1_3)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if var_2_2 > 0 and var_0_4:father(arg_2_1.skillID) == arg_2_0:getEnergySkillID() and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_2_1.target:isDHarm() then
		local var_2_6 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		var_2_2 = var_2_2 + arg_2_0:getAP() * var_0_7 + var_2_6 * var_0_8
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

return var_0_3
