local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Hansui", var_0_1.ctx.battle.requireFighter("Hansui"))
local var_0_5 = 40010958
local var_0_6 = 60010168

function var_0_4.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	local var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5 = var_0_4.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if var_1_2 > 0 and arg_1_1.target:isHasBuffByID(var_0_5) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_6 = arg_1_0:createAttackUnits({
			arg_1_1.target
		}, var_0_6)

		for iter_1_0, iter_1_1 in ipairs(var_1_6) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end

	return var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5
end

return var_0_4
