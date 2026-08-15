local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunwukonghuanxiang_Awaken", var_0_1.ctx.battle.requireFighter("Sunwukong"))

function var_0_3.deathFeedback(arg_1_0, arg_1_1)
	var_0_3.super.deathFeedback(arg_1_0, arg_1_1)

	local var_1_0 = arg_1_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	if arg_1_1:getTeamType() == arg_1_0:getTeamType() then
		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			if iter_1_1 ~= arg_1_0 and not iter_1_1:isDeath() and iter_1_1:getSummonType() == var_0_2.summonMonsterType.None then
				return
			end
		end

		arg_1_0:updateHp(0)
		arg_1_0:die()
	end
end

return var_0_3
