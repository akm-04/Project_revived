local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_2.tables.skill
local var_0_4 = var_0_0.class("ElementSunshangxiang", var_0_1.ctx.battle.requireFighter("ElementBoss"))

function var_0_4.selectTargetByTypeD2(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = {}
	local var_1_1
	local var_1_2
	local var_1_3
	local var_1_4 = arg_1_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_1_5 = arg_1_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_1_6 = arg_1_0:isAttackFriend() and var_1_4 or var_1_5

	for iter_1_0, iter_1_1 in ipairs(var_1_6) do
		if not iter_1_1:isDeath() and not iter_1_1:isAffected() and math.abs(iter_1_1:getX() - arg_1_2.target:getX()) < var_0_3:scope(arg_1_1) / 2 then
			table.insert(var_1_0, iter_1_1)
		end
	end

	return var_1_0
end

function var_0_4.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_2_0 = arg_2_1:getRemoveSkill()
	local var_2_1 = arg_2_0:selectTargetByTypeD2(var_2_0, arg_2_1)
	local var_2_2 = arg_2_0:createAttackUnits(var_2_1, var_2_0)

	for iter_2_0, iter_2_1 in ipairs(var_2_2) do
		table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
		table.insert(arg_2_0.records_.special_units, iter_2_1)
	end
end

return var_0_4
