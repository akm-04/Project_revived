local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guojia", var_0_1.ctx.battle.requireFighter("Guojia"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10000369

function var_0_3.toDoPerFrames(arg_1_0)
	arg_1_0:updateAwakenSkill()
	var_0_3.super.toDoPerFrames(arg_1_0)
end

function var_0_3.updateAwakenSkill(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if var_0_1.ctx.battle.count % 30 > 0 or arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) < 1 then
		return
	end

	local var_2_0 = {}

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and iter_2_1:isPugongOnly() then
			local var_2_1 = iter_2_1.pugongOnlyBuffs_

			for iter_2_2, iter_2_3 in ipairs(var_2_1) do
				if iter_2_3.fighter:getTeamType() == arg_2_0:getTeamType() then
					table.insert(var_2_0, iter_2_1)
				end
			end
		end
	end

	if next(var_2_0) == nil then
		return
	end

	local var_2_2 = var_0_5
	local var_2_3 = arg_2_0:createAttackUnits(var_2_0, var_2_2)

	for iter_2_4, iter_2_5 in ipairs(var_2_3) do
		table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
		table.insert(arg_2_0.records_.special_units, iter_2_5)
	end
end

return var_0_3
