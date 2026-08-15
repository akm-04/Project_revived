local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Rihefang"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0.0015

function var_0_3.updateUnitDataBySpecialHero(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_5 > 0 and arg_1_1.target:getTeamType() == arg_1_0:getTeamType() then
		arg_1_5 = arg_1_5 * (1 + var_0_5 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

function var_0_3.addBuffBySpecialHero(arg_2_0, arg_2_1)
	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		local var_2_0 = var_0_5 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		for iter_2_0 = #arg_2_1, 1, -1 do
			local var_2_1 = arg_2_1[iter_2_0]

			if var_2_1:getType() == var_0_2.BuffType.REVIVIE then
				var_2_1.manualHarmRevise = var_2_1:getHarm() * var_2_0
			elseif var_2_1:isDHarmBuff() then
				var_2_1.manualDharm = var_2_1:totalDHarm() * var_2_0
			end
		end
	end
end

return var_0_3
