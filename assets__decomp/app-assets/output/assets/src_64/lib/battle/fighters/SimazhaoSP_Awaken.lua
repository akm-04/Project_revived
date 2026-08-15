local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SimazhaoSP", var_0_1.ctx.battle.requireFighter("SimazhaoSP"))

function var_0_3.updateUnitDataBySpecialHero(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_0:getTeamType() == arg_1_1.fighter:getTeamType() and arg_1_0:getTeamType() ~= arg_1_1.target:getTeamType() and arg_1_1.attackType == var_0_2.AttackType.AP and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_1_1.skillID ~= arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		local var_1_0 = arg_1_0:createAttackUnits({
			arg_1_1.target
		}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

return var_0_3
