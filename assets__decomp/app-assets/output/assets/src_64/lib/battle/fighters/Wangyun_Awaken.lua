local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wangyun", var_0_1.ctx.battle.requireFighter("Wangyun"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = 40010532
local var_0_9 = 30

function var_0_3.buffAddAction(arg_1_0, arg_1_1)
	if arg_1_1:getTableID() == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_0 = {
			arg_1_0
		}
		local var_1_1 = arg_1_0:createAttackUnits(var_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_1_0, iter_1_1 in ipairs(var_1_1) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7 = var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if (var_0_4:father(arg_2_1.skillID) == arg_2_0:getPugongID() or var_0_4:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_0_4:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) and arg_2_1.target:getTeamType() ~= arg_2_0:getTeamType() and arg_2_4 > 0 then
		arg_2_7 = -var_0_9

		arg_2_0:updateEnergyBy(var_0_9)
	end

	return arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7
end

return var_0_3
