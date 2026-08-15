local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangxingcai", var_0_1.ctx.battle.requireFighter("Zhangxingcai"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40011451
local var_0_6 = 60010211

function var_0_3.buffAddAction(arg_1_0, arg_1_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_1_1.tableID_ == var_0_5 then
		local var_1_0 = arg_1_0:createAttackUnits({
			arg_1_1.target
		}, var_0_6)

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end

	var_0_3.super.buffAddAction(arg_1_0, arg_1_1)
end

return var_0_3
