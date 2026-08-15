local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("KamilaBat", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 10001031

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_1_1.skillID == arg_1_0:getPugongID() and arg_1_4 > 0 then
		local var_1_0 = arg_1_0:selectTargetByTypeD1()
		local var_1_1 = arg_1_0:createAttackUnits(var_1_0, var_0_4)

		for iter_1_0, iter_1_1 in ipairs(var_1_1) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

function var_0_3.selectTargetByTypeD1(arg_2_0)
	local var_2_0
	local var_2_1

	for iter_2_0, iter_2_1 in pairs(arg_2_0.selfTeam_) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None and iter_2_1 ~= arg_2_0.summoner and (not var_2_0 or var_2_1 > iter_2_1:getHp() / iter_2_1:getHpLimit() or var_2_1 == iter_2_1:getHp() / iter_2_1:getHpLimit() and var_2_0:getHp() > iter_2_1:getHp()) then
			var_2_0 = iter_2_1
			var_2_1 = var_2_0:getHp() / var_2_0:getHpLimit()
		end
	end

	if var_2_0 then
		return {
			var_2_0
		}
	else
		return {}
	end
end

return var_0_3
