local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lafeier", var_0_1.ctx.battle.requireFighter("Lafeier"))
local var_0_4 = 10000872

function var_0_3.die(arg_1_0)
	arg_1_0:specialAttack()
	var_0_3.super.die(arg_1_0)
end

function var_0_3.specialAttack(arg_2_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if next(arg_2_0.energyTarget_) and arg_2_0.energyTarget_.target then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_0.energyTarget_.target
		}, var_0_4)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end

		return
	end

	local var_2_1 = false

	for iter_2_2, iter_2_3 in ipairs(arg_2_0.selfTeam_) do
		if (not iter_2_3:isDeath() or iter_2_3:canReborn()) and iter_2_3:getSummonType() == var_0_2.summonMonsterType.None then
			var_2_1 = true
		end
	end

	if not var_2_1 then
		return
	end

	local var_2_2 = arg_2_0:getTargets(arg_2_0:getEnergySkillID())

	if next(var_2_2) then
		local var_2_3 = arg_2_0:createAttackUnits(var_2_2, arg_2_0:getEnergySkillID())

		for iter_2_4, iter_2_5 in ipairs(var_2_3) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
			table.insert(arg_2_0.records_.special_units, iter_2_5)
		end
	end
end

return var_0_3
