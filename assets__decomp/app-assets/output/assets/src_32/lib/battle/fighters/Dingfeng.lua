local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_2.tables.skill
local var_0_4 = var_0_0.class("Dingfeng", var_0_1.ctx.battle.getRequire("BaseFighter"))

function var_0_4.selectTargetByTypeD1(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0
	local var_1_1 = {}
	local var_1_2
	local var_1_3 = arg_1_0:getTeamType() == var_0_2.TeamType.A and 1 or -1

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.sideTeam_) do
		if not iter_1_1:isDeath() and not iter_1_1:isAffected() and iter_1_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_1_4 = iter_1_1:getX() * var_1_3

			if not var_1_2 or var_1_2 <= var_1_4 then
				var_1_0 = iter_1_1
				var_1_2 = var_1_4
			end
		end
	end

	if var_1_0 then
		local var_1_5 = var_0_3:scope(arg_1_0:getEnergySkillID())

		for iter_1_2, iter_1_3 in ipairs(arg_1_0.sideTeam_) do
			if not iter_1_3:isDeath() and not iter_1_3:isAffected() and math.abs(iter_1_3:getX() - var_1_0:getX()) <= var_1_5 / 2 then
				table.insert(var_1_1, iter_1_3)
			end
		end
	end

	return var_1_1
end

return var_0_4
