local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lingtongzhaohuanwu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 10000141

function var_0_3.die(arg_1_0)
	arg_1_0:specialAttack()
	var_0_3.super.die(arg_1_0)
end

function var_0_3.specialAttack(arg_2_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_2_0 = var_0_8
	local var_2_1 = var_0_4.B2(arg_2_0, var_2_0)

	if next(var_2_1) then
		local var_2_2 = arg_2_0:createAttackUnits(var_2_1, var_2_0)

		for iter_2_0, iter_2_1 in ipairs(var_2_2) do
			iter_2_1.arrived = true

			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

return var_0_3
