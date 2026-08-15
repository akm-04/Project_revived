local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Tutu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0

function var_0_3.toDoPerFrames(arg_1_0)
	var_0_3.super.toDoPerFrames(arg_1_0)
	arg_1_0:checkNeedAddBuff()
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)
	arg_2_0:checkNeedAddBuff()
end

function var_0_3.checkNeedAddBuff(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	elseif not arg_3_0.awakenBuffTargets_ or not next(arg_3_0.awakenBuffTargets_) then
		return
	end

	local var_3_0 = {}

	for iter_3_0 = #arg_3_0.awakenBuffTargets_, 1, -1 do
		local var_3_1 = arg_3_0.awakenBuffTargets_[iter_3_0]

		if not var_3_1:isDeath() and not var_3_1:isAffected() then
			table.insert(var_3_0, var_3_1)
		end

		table.remove(arg_3_0.awakenBuffTargets_, iter_3_0)
	end

	if not var_3_0 or not next(var_3_0) then
		return
	end

	local var_3_2 = arg_3_0:createAttackUnits(var_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

	for iter_3_1, iter_3_2 in ipairs(var_3_2) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_2)
		table.insert(arg_3_0.records_.special_units, iter_3_2)
	end
end

return var_0_3
