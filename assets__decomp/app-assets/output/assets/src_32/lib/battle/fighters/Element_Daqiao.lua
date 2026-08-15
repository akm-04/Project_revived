local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementDaqiao", var_0_1.ctx.battle.requireFighter("ElementBoss"))

function var_0_3.selectTargetByTypeD1(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = arg_1_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA
	local var_1_1, var_1_2 = arg_1_0.fighterModel:getPosition()
	local var_1_3
	local var_1_4

	for iter_1_0, iter_1_1 in ipairs(var_1_0) do
		if not iter_1_1:isDeath() and not iter_1_1:isAffected() and iter_1_1 ~= arg_1_0 and iter_1_1:getSummonType() == 0 then
			local var_1_5, var_1_6 = iter_1_1.fighterModel:getPosition()
			local var_1_7 = math.abs(var_1_1 - var_1_5)

			if not var_1_3 or var_1_7 < var_1_3 then
				var_1_3 = var_1_7
				var_1_4 = iter_1_1
			end
		end
	end

	return {
		var_1_4
	}
end

return var_0_3
