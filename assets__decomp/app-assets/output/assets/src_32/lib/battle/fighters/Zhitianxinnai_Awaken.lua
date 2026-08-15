local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhitianxinnai", var_0_1.ctx.battle.requireFighter("Zhitianxinnai"))
local var_0_4 = 40011032

function var_0_3.buffAddAction(arg_1_0, arg_1_1)
	var_0_3.super.buffAddAction(arg_1_0, arg_1_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_1_1:getTableID() == var_0_4 then
		local var_1_0 = arg_1_0:createAttackUnits({
			arg_1_0
		}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end
end

return var_0_3
