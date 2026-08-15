local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Xiaoao"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0
local var_0_6 = 0.005
local var_0_7 = 0
local var_0_8 = 0.003

function var_0_3.addBuffBySpecialHero(arg_1_0, arg_1_1)
	var_0_3.super.addBuffBySpecialHero(arg_1_0, arg_1_1)

	if arg_1_1 and next(arg_1_1) then
		for iter_1_0 = #arg_1_1, 1, -1 do
			local var_1_0 = arg_1_1[iter_1_0]

			if var_1_0:getType() == var_0_2.BuffType.CONTINUE_HARM and var_1_0.target:getTeamType() == arg_1_0:getTeamType() then
				local var_1_1 = var_1_0:getHarm()

				var_1_0.manualHarmRevise = -var_1_0:getHarm() * (var_0_5 + var_0_6 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

				local var_1_2 = var_1_0:getTime()

				var_1_0:setExtraTime(-var_1_0:getTime() * (var_0_7 + var_0_8 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)))
			end
		end
	end
end

return var_0_3
