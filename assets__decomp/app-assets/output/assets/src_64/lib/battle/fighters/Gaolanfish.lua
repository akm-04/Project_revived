local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Gaolanfish", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 10001084

function var_0_3.die(arg_1_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_1_0 = false

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.selfTeam_) do
		if not iter_1_1:isDeath() or iter_1_1:canReborn() then
			var_1_0 = true
		end
	end

	if var_1_0 then
		local var_1_1 = arg_1_0:getTargets(var_0_4)
		local var_1_2 = arg_1_0:createAttackUnits(var_1_1, var_0_4)

		for iter_1_2, iter_1_3 in ipairs(var_1_2) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_3)
			table.insert(arg_1_0.records_.special_units, iter_1_3)
		end
	end

	var_0_3.super.die(arg_1_0)
end

return var_0_3
