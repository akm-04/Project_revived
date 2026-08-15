local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Maliang", var_0_1.ctx.battle.requireFighter("Maliang"))
local var_0_4 = 40010953
local var_0_5 = 10000877
local var_0_6 = 10001781

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if (arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) or arg_1_1.skillID == var_0_6) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_0 = arg_1_0:createAttackUnits({
			arg_1_0
		}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end
end

function var_0_3.dHarmBuffBreakFeedback(arg_2_0, arg_2_1, arg_2_2)
	var_0_3.super.dHarmBuffBreakFeedback(arg_2_0, arg_2_1, arg_2_2)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_2:getTableID() == var_0_4 then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_0
		}, var_0_5)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

return var_0_3
